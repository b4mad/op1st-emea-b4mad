// Server-only. ALL PromQL lives here as fixed templates; the only variable is
// the range window, taken from the RANGES allowlist. Nothing from the client
// is ever forwarded to Prometheus.
import { readFileSync } from 'node:fs';
import { env } from '$env/dynamic/private';
import type { PodRates, RawInputs } from '$lib/model';

export const RANGES = { '1h': '1h', '6h': '6h', '24h': '24h', '7d': '7d' } as const;
export type RangeKey = keyof typeof RANGES;
export const isRange = (r: string | null): r is RangeKey => r !== null && Object.hasOwn(RANGES, r);

const CACHE_TTL_MS = 60_000;
const SA_DIR = '/var/run/secrets/kubernetes.io/serviceaccount';
const THANOS = env.THANOS_URL ?? 'https://thanos-querier.openshift-monitoring.svc:9091';

// Physical NIC = everything node-exporter exposes except virtual devices.
const NIC = 'device!~"lo|genev_sys.*|ovs-system|veth.*|br-.*|ovn.*|docker.*"';
const QUERIES = (w: string) => ({
  nicRx: `sum by (instance) (rate(node_network_receive_bytes_total{${NIC}}[${w}]))`,
  nicTx: `sum by (instance) (rate(node_network_transmit_bytes_total{${NIC}}[${w}]))`,
  genRx: `sum by (instance) (rate(node_network_receive_bytes_total{device=~"genev_sys.*"}[${w}]))`,
  genTx: `sum by (instance) (rate(node_network_transmit_bytes_total{device=~"genev_sys.*"}[${w}]))`,
  podRx: `sum by (node, namespace) (rate(container_network_receive_bytes_total{interface="eth0",pod!=""}[${w}]))`,
  podTx: `sum by (node, namespace) (rate(container_network_transmit_bytes_total{interface="eth0",pod!=""}[${w}]))`
});

type Sample = { metric: Record<string, string>; value: [number, string] };

function token(): string {
  if (env.THANOS_TOKEN) return env.THANOS_TOKEN;
  return readFileSync(`${SA_DIR}/token`, 'utf8').trim(); // projected, rotates: re-read every call
}

async function instant(promql: string): Promise<Sample[]> {
  const res = await fetch(`${THANOS}/api/v1/query`, {
    method: 'POST',
    headers: { authorization: `Bearer ${token()}`, 'content-type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({ query: promql }),
    signal: AbortSignal.timeout(20_000)
  });
  if (!res.ok) throw new Error(`thanos ${res.status}`);
  const body = await res.json();
  if (body.status !== 'success') throw new Error('thanos query failed');
  return body.data.result;
}

const byNode = (s: Sample[], label: string) =>
  Object.fromEntries(s.map((x) => [x.metric[label], Number(x.value[1])]));
const byPod = (s: Sample[]): PodRates =>
  s.map((x) => ({ node: x.metric.node, namespace: x.metric.namespace, value: Number(x.value[1]) }));

export interface TrafficResult {
  range: RangeKey;
  generatedAt: string;
  // Raw rates; the client builds/filters the Sankey (no extra queries needed).
  raw: RawInputs;
}

async function compute(range: RangeKey): Promise<TrafficResult> {
  const q = QUERIES(RANGES[range]);
  const [nicRx, nicTx, genRx, genTx, podRx, podTx] = await Promise.all([
    instant(q.nicRx), instant(q.nicTx), instant(q.genRx), instant(q.genTx), instant(q.podRx), instant(q.podTx)
  ]);
  const raw: RawInputs = {
    nic: { rx: byNode(nicRx, 'instance'), tx: byNode(nicTx, 'instance') },
    geneve: { rx: byNode(genRx, 'instance'), tx: byNode(genTx, 'instance') },
    pods: { rx: byPod(podRx), tx: byPod(podTx) }
  };
  return { range, generatedAt: new Date().toISOString(), raw };
}

// 60 s cache per range; concurrent requests share one in-flight computation.
const cache = new Map<RangeKey, { at: number; p: Promise<TrafficResult> }>();

export function getTraffic(range: RangeKey): Promise<TrafficResult> {
  const hit = cache.get(range);
  if (hit && Date.now() - hit.at < CACHE_TTL_MS) return hit.p;
  const p = compute(range);
  cache.set(range, { at: Date.now(), p });
  p.catch(() => cache.get(range)?.p === p && cache.delete(range)); // never cache failures
  return p;
}
