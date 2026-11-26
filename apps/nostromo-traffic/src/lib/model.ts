// Pure model: turns raw Prometheus rates into Sankey nodes/links.
// No I/O here, so it is unit-testable (model.test.ts).

export type Dir = 'rx' | 'tx';
export type NodeRate = Record<string, number>; // node -> bytes/s
export type PodRates = { node: string; namespace: string; value: number }[];

export interface RawInputs {
  nic: Record<Dir, NodeRate>; // physical NIC per node
  geneve: Record<Dir, NodeRate>; // genev_sys_6081 per node
  pods: Record<Dir, PodRates>; // pod-network eth0 per node+namespace
}

export const CLASSES = ['external', 'local', 'overlay'] as const;
export type TrafficClass = (typeof CLASSES)[number];

export interface SankeyData {
  nodes: { id: string; label: string; kind: 'class' | 'node' | 'namespace' }[];
  // est: value was scaled because a traffic class is hidden (see buildSankey)
  links: { source: string; target: string; value: number; est?: boolean }[];
}

/** Parse ?hide=a,b into a set of known classes; unknown values are ignored. */
export function parseHide(param: string | null): Set<TrafficClass> {
  const known = new Set<string>(CLASSES);
  return new Set((param ?? '').split(',').filter((c): c is TrafficClass => known.has(c)));
}

export const TOP_NAMESPACES = 15;

export const CLASS_LABEL: Record<TrafficClass, string> = {
  external: 'external / host-network (est.)',
  overlay: 'other node (overlay)',
  local: 'same node (pod↔pod)'
};

/**
 * Hidden classes: a node's namespace links carry its full total, but the metrics
 * cannot say which namespace's bytes belong to which class. So each node's
 * namespace links are scaled by (kept classes / node total) and flagged `est`.
 * Nodes/namespaces/links that end up at zero are dropped.
 */
export function buildSankey(raw: RawInputs, dir: Dir, hidden: ReadonlySet<TrafficClass> = new Set()): SankeyData {
  const pods = raw.pods[dir].filter((p) => p.value > 0);

  // Top-N namespaces by total traffic; the rest are folded into "other".
  const perNs = new Map<string, number>();
  for (const p of pods) perNs.set(p.namespace, (perNs.get(p.namespace) ?? 0) + p.value);
  const ranked = [...perNs.entries()].sort((a, b) => b[1] - a[1]);
  const keep = new Set(ranked.slice(0, TOP_NAMESPACES).map(([n]) => n));
  const other = ranked.length > TOP_NAMESPACES ? `other (${ranked.length - TOP_NAMESPACES})` : null;

  const nodes = new Map<string, SankeyData['nodes'][number]>();
  const links = new Map<string, number>();
  const addNode = (id: string, label: string, kind: 'class' | 'node' | 'namespace') =>
    nodes.set(id, { id, label, kind });
  const est = new Set<string>();
  const addLink = (s: string, t: string, v: number, isEst = false) => {
    if (v <= 0) return;
    const k = `${s}\u0000${t}`;
    links.set(k, (links.get(k) ?? 0) + v);
    if (isEst) est.add(k);
  };

  const clusterNodes = [...new Set(pods.map((p) => p.node))].sort();
  for (const node of clusterNodes) {
    const nsRates = new Map<string, number>();
    for (const p of pods.filter((x) => x.node === node)) {
      const ns = keep.has(p.namespace) ? p.namespace : other!;
      nsRates.set(ns, (nsRates.get(ns) ?? 0) + p.value);
    }
    const total = [...nsRates.values()].reduce((a, b) => a + b, 0);

    // Inference (see README): overlay = geneve share, external = NIC minus
    // geneve, local = remainder. Each is clamped so the three sum to `total`.
    const gen = raw.geneve[dir][node] ?? 0;
    const nic = raw.nic[dir][node] ?? 0;
    const overlay = Math.min(gen, total);
    const external = Math.min(Math.max(nic - gen, 0), total - overlay);
    const local = total - overlay - external;
    const parts: [TrafficClass, number][] = [
      ['external', external],
      ['overlay', overlay],
      ['local', local]
    ];
    const kept = parts.filter(([c]) => !hidden.has(c)).reduce((a, [, v]) => a + v, 0);
    if (kept <= 0) continue; // nothing left on this node
    const scale = kept / total;

    const nodeId = `node:${node}`;
    addNode(nodeId, node, 'node');
    for (const [cls, v] of parts) {
      if (hidden.has(cls)) continue;
      addNode(`cls:${cls}`, CLASS_LABEL[cls], 'class');
      // rx: class -> node -> namespace; tx: namespace -> node -> class
      if (dir === 'rx') addLink(`cls:${cls}`, nodeId, v);
      else addLink(nodeId, `cls:${cls}`, v);
    }
    for (const [ns, v] of nsRates) {
      const sv = v * scale;
      const isEst = scale < 1;
      if (sv <= 0) continue;
      addNode(`ns:${ns}`, ns, 'namespace');
      if (dir === 'rx') addLink(nodeId, `ns:${ns}`, sv, isEst);
      else addLink(`ns:${ns}`, nodeId, sv, isEst);
    }
  }

  const usedIds = new Set<string>();
  const outLinks = [...links].map(([k, value]) => {
    const [source, target] = k.split('\u0000');
    usedIds.add(source);
    usedIds.add(target);
    return est.has(k) ? { source, target, value, est: true } : { source, target, value };
  });
  return { nodes: [...nodes.values()].filter((n) => usedIds.has(n.id)), links: outLinks };
}
