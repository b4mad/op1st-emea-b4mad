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

export interface SankeyData {
  nodes: { id: string; label: string; kind: 'class' | 'node' | 'namespace' }[];
  links: { source: string; target: string; value: number }[];
}

export const TOP_NAMESPACES = 15;

// The single definition of "our" namespaces; everything else (openshift-*, kube-*, ...)
// is platform-internal and hidden when the UI's "hide platform namespaces" box is ticked.
export const OWN_NS_PREFIXES = ['b4mad-', 'feeldata-', 'machdenstaat-', 'op1st-'] as const;
export const isOwnNamespace = (ns: string) => OWN_NS_PREFIXES.some((p) => ns.startsWith(p));

const CLASS_LABEL: Record<string, string> = {
  external: 'external / host-network (est.)',
  overlay: 'other node via overlay',
  local: 'same-node pods'
};

export function buildSankey(raw: RawInputs, dir: Dir, ownOnly = false): SankeyData {
  const pods = raw.pods[dir].filter((p) => p.value > 0 && (!ownOnly || isOwnNamespace(p.namespace)));

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
  const addLink = (s: string, t: string, v: number) => {
    if (v > 0) links.set(`${s}\u0000${t}`, (links.get(`${s}\u0000${t}`) ?? 0) + v);
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
    const parts: [string, number][] = [
      ['external', external],
      ['overlay', overlay],
      ['local', local]
    ];

    const nodeId = `node:${node}`;
    addNode(nodeId, node, 'node');
    for (const [cls, v] of parts) {
      addNode(`cls:${cls}`, CLASS_LABEL[cls], 'class');
      // rx: class -> node -> namespace; tx: namespace -> node -> class
      if (dir === 'rx') addLink(`cls:${cls}`, nodeId, v);
      else addLink(nodeId, `cls:${cls}`, v);
    }
    for (const [ns, v] of nsRates) {
      addNode(`ns:${ns}`, ns, 'namespace');
      if (dir === 'rx') addLink(nodeId, `ns:${ns}`, v);
      else addLink(`ns:${ns}`, nodeId, v);
    }
  }

  const usedIds = new Set<string>();
  const outLinks = [...links].map(([k, value]) => {
    const [source, target] = k.split('\u0000');
    usedIds.add(source);
    usedIds.add(target);
    return { source, target, value };
  });
  return { nodes: [...nodes.values()].filter((n) => usedIds.has(n.id)), links: outLinks };
}
