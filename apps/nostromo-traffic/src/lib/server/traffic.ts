// Server-only. ALL PromQL lives here as fixed templates; the only variable is
// the range window, taken from the RANGES allowlist. Nothing from the client
// is ever forwarded to Prometheus.
import { readFileSync } from 'node:fs';
import { env } from '$env/dynamic/private';
import {
  buildPodTable,
  buildSankey,
  isNamespaceName,
  type Dir,
  type PodRates,
  type PodRow,
  type RawInputs,
  type SankeyData
} from '$lib/model';
import { RANGES, type RangeKey } from '$lib/params';

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

// Per-pod rates for ONE namespace. `ns` is interpolated, so it must already have passed
// isNamespaceName (re-checked in getPods); the strict regex excludes quotes/braces/backslashes.
// interface="eth0" is the pod-network interface only: hostNetwork pods are reported by cAdvisor
// on the node's own interfaces (eno1, br-ex, veth*, ...), never eth0, so they are excluded
// (checked against Thanos: the hostNetwork router-default pod has no eth0 series).
const POD_QUERIES = (w: string, ns: string) => ({
  rx: `sum by (pod) (rate(container_network_receive_bytes_total{interface="eth0",pod!="",namespace="${ns}"}[${w}]))`,
  tx: `sum by (pod) (rate(container_network_transmit_bytes_total{interface="eth0",pod!="",namespace="${ns}"}[${w}]))`
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
  rx: SankeyData;
  tx: SankeyData;
}

async function compute(range: RangeKey): Promise<RawInputs> {
  const q = QUERIES(RANGES[range]);
  const [nicRx, nicTx, genRx, genTx, podRx, podTx] = await Promise.all([
    instant(q.nicRx), instant(q.nicTx), instant(q.genRx), instant(q.genTx), instant(q.podRx), instant(q.podTx)
  ]);
  return {
    nic: { rx: byNode(nicRx, 'instance'), tx: byNode(nicTx, 'instance') },
    geneve: { rx: byNode(genRx, 'instance'), tx: byNode(genTx, 'instance') },
    pods: { rx: byPod(podRx), tx: byPod(podTx) }
  };
}

// 60 s cache of the raw rates per range; concurrent requests share one in-flight computation.
// The namespace filter is applied after the cache, so both views share one Prometheus query.
const cache = new Map<RangeKey, { at: number; p: Promise<RawInputs> }>();

function getRaw(range: RangeKey): Promise<RawInputs> {
  const hit = cache.get(range);
  if (hit && Date.now() - hit.at < CACHE_TTL_MS) return hit.p;
  const p = compute(range);
  cache.set(range, { at: Date.now(), p });
  p.catch(() => cache.get(range)?.p === p && cache.delete(range)); // never cache failures
  return p;
}

export async function getTraffic(
  range: RangeKey,
  opts: { ownOnly?: boolean; hideNodes?: boolean } = {}
): Promise<TrafficResult> {
  const raw = await getRaw(range);
  const dirs: Dir[] = ['rx', 'tx'];
  const [rx, tx] = dirs.map((d) => buildSankey(raw, d, opts));
  return { range, generatedAt: new Date().toISOString(), rx, tx };
}

export interface PodsResult {
  range: RangeKey;
  namespace: string;
  generatedAt: string;
  pods: PodRow[];
}

// Same 60 s cache, keyed per (range, namespace). Keys are client-chosen, so the map is bounded:
// expired entries are swept on insert and the oldest is evicted past MAX_POD_CACHE.
const MAX_POD_CACHE = 200;
const podCache = new Map<string, { at: number; p: Promise<PodRow[]> }>();

async function computePods(range: RangeKey, ns: string): Promise<PodRow[]> {
  const q = POD_QUERIES(RANGES[range], ns);
  const [rx, tx] = await Promise.all([instant(q.rx), instant(q.tx)]);
  const rate = (s: Sample[]) => Object.fromEntries(s.map((x) => [x.metric.pod, Number(x.value[1])]));
  return buildPodTable(rate(rx), rate(tx));
}

export async function getPods(range: RangeKey, namespace: string): Promise<PodsResult> {
  if (!isNamespaceName(namespace)) throw new Error('invalid namespace'); // defence in depth
  const key = `${range}\u0000${namespace}`;
  const now = Date.now();
  let hit = podCache.get(key);
  if (!hit || now - hit.at >= CACHE_TTL_MS) {
    for (const [k, v] of podCache) if (now - v.at >= CACHE_TTL_MS) podCache.delete(k);
    while (podCache.size >= MAX_POD_CACHE) podCache.delete(podCache.keys().next().value!);
    const p = computePods(range, namespace);
    hit = { at: now, p };
    podCache.set(key, hit);
    p.catch(() => podCache.get(key)?.p === p && podCache.delete(key)); // never cache failures
  }
  return { range, namespace, generatedAt: new Date().toISOString(), pods: await hit.p };
}
