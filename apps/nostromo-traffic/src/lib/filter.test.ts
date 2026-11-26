import { test } from 'node:test';
import assert from 'node:assert/strict';
import { buildSankey, parseHide, CLASSES, type RawInputs, type TrafficClass } from './model.ts';

const sum = (ls: { value: number }[]) => ls.reduce((a, l) => a + l.value, 0);

// Node a: pods 500 (x 400, y 100); NIC 300, geneve 100 => external 200, overlay 100, local 200.
const raw: RawInputs = {
  nic: { rx: { a: 300 }, tx: { a: 300 } },
  geneve: { rx: { a: 100 }, tx: { a: 100 } },
  pods: {
    rx: [
      { node: 'a', namespace: 'x', value: 400 },
      { node: 'a', namespace: 'y', value: 100 }
    ],
    tx: [
      { node: 'a', namespace: 'x', value: 400 },
      { node: 'a', namespace: 'y', value: 100 }
    ]
  }
};
const classVal: Record<TrafficClass, number> = { external: 200, overlay: 100, local: 200 };

// all 2^3 combinations of hidden classes
const subsets: TrafficClass[][] = Array.from({ length: 8 }, (_, m) => CLASSES.filter((_c, i) => m & (1 << i)));

for (const hide of subsets) {
  for (const dir of ['rx', 'tx'] as const) {
    test(`hide [${hide}] ${dir}: balances, scales namespaces, marks estimates`, () => {
      const s = buildSankey(raw, dir, new Set(hide));
      const kept = CLASSES.filter((c) => !hide.includes(c)).reduce((a, c) => a + classVal[c], 0);
      if (kept === 0) {
        assert.deepEqual(s, { nodes: [], links: [] });
        return;
      }
      const cls = s.links.filter((l) => (dir === 'rx' ? l.source : l.target).startsWith('cls:'));
      const ns = s.links.filter((l) => (dir === 'rx' ? l.target : l.source).startsWith('ns:'));
      assert.equal(sum(cls), kept);
      assert.ok(Math.abs(sum(ns) - kept) < 1e-9, 'node in == node out');
      const x = ns.find((l) => l.source === 'ns:x' || l.target === 'ns:x')!;
      assert.ok(Math.abs(x.value - 400 * (kept / 500)) < 1e-9, 'x scaled by kept/total');
      assert.equal(x.est, kept < 500 ? true : undefined);
      for (const h of hide) assert.equal(s.nodes.some((n) => n.id === `cls:${h}`), false);
    });
  }
}

test('a node with nothing left is dropped with its namespaces; other nodes stay', () => {
  const r: RawInputs = {
    nic: { rx: { a: 0, b: 50 }, tx: {} },
    geneve: { rx: { a: 0, b: 0 }, tx: {} },
    pods: {
      rx: [
        { node: 'a', namespace: 'x', value: 10 },
        { node: 'b', namespace: 'y', value: 100 }
      ],
      tx: []
    }
  };
  // a is all same-node (10); b is external 50 + same-node 50. Hiding local removes a entirely.
  const s = buildSankey(r, 'rx', new Set<TrafficClass>(['local']));
  assert.deepEqual(s.nodes.map((n) => n.id).filter((i) => i.startsWith('node:')), ['node:b']);
  assert.equal(s.nodes.some((n) => n.id === 'ns:x'), false);
});

test('parseHide keeps only the three known classes', () => {
  assert.deepEqual([...parseHide('external,bogus,local,')].sort(), ['external', 'local']);
  assert.equal(parseHide(null).size, 0);
});
