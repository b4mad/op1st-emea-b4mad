import { test } from 'node:test';
import assert from 'node:assert/strict';
import { buildPodTable, buildSankey, isNamespaceName, isOwnNamespace, type RawInputs } from './model.ts';

const raw: RawInputs = {
  nic: { rx: { a: 300 }, tx: { a: 0 } },
  geneve: { rx: { a: 100 }, tx: { a: 0 } },
  pods: {
    rx: [
      { node: 'a', namespace: 'x', value: 400 },
      { node: 'a', namespace: 'y', value: 100 }
    ],
    tx: []
  }
};

test('rx splits node inflow into external/overlay/local and conserves bytes', () => {
  const s = buildSankey(raw, 'rx');
  const into = (id: string) => s.links.filter((l) => l.target === id).reduce((a, l) => a + l.value, 0);
  const out = (id: string) => s.links.filter((l) => l.source === id).reduce((a, l) => a + l.value, 0);
  assert.equal(into('node:a'), 500);
  assert.equal(out('node:a'), 500);
  assert.equal(s.links.find((l) => l.source === 'cls:overlay')?.value, 100);
  assert.equal(s.links.find((l) => l.source === 'cls:external')?.value, 200);
  assert.equal(s.links.find((l) => l.source === 'cls:local')?.value, 200);
});

test('NIC smaller than geneve clamps external to 0', () => {
  const s = buildSankey({ ...raw, nic: { rx: { a: 10 }, tx: {} } }, 'rx');
  assert.equal(s.links.find((l) => l.source === 'cls:external'), undefined);
});

test('empty input gives empty graph', () => {
  const s = buildSankey({ ...raw, pods: { rx: [], tx: [] } }, 'tx');
  assert.deepEqual(s, { nodes: [], links: [] });
});

test('own-namespace filter matches only the known prefixes', () => {
  for (const ns of ['b4mad-x', 'feeldata-prod', 'machdenstaat-a', 'op1st-b']) assert.ok(isOwnNamespace(ns), ns);
  for (const ns of ['openshift-monitoring', 'kube-system', 'b4mad', 'xop1st-a']) assert.ok(!isOwnNamespace(ns), ns);
});

test('ownOnly drops platform namespaces from nodes and links; default keeps them', () => {
  const r: RawInputs = {
    ...raw,
    pods: { rx: [{ node: 'a', namespace: 'op1st-x', value: 400 }, { node: 'a', namespace: 'openshift-y', value: 100 }], tx: [] }
  };
  const all = buildSankey(r, 'rx');
  assert.ok(all.nodes.some((n) => n.id === 'ns:openshift-y'));
  const own = buildSankey(r, 'rx', { ownOnly: true });
  assert.ok(!own.nodes.some((n) => n.id === 'ns:openshift-y'));
  assert.ok(own.nodes.some((n) => n.id === 'ns:op1st-x'));
  assert.equal(own.links.filter((l) => l.source === 'node:a' || l.target === 'node:a').length, own.links.length);
  assert.equal(own.links.filter((l) => l.target === 'node:a').reduce((a, l) => a + l.value, 0), 400);
});

test('hideNodes drops node:* hubs, keeps namespaces and conserves bytes per namespace', () => {
  const s = buildSankey(raw, 'rx', { hideNodes: true });
  assert.ok(!s.nodes.some((n) => n.id.startsWith('node:')));
  assert.ok(!s.links.some((l) => l.source.startsWith('node:') || l.target.startsWith('node:')));
  const into = (id: string) => s.links.filter((l) => l.target === id).reduce((a, l) => a + l.value, 0);
  assert.equal(into('ns:x'), 400);
  assert.equal(into('ns:y'), 100);
  // class split is pro rata: overlay 100 of 500 total -> x gets 80
  assert.ok(Math.abs((s.links.find((l) => l.source === 'cls:overlay' && l.target === 'ns:x')?.value ?? 0) - 80) < 1e-9);
  // default still shows the hubs
  assert.ok(buildSankey(raw, 'rx').nodes.some((n) => n.id === 'node:a'));
});

test('hideNodes in tx mirrors direction (ns -> class)', () => {
  const r: RawInputs = { ...raw, nic: { rx: {}, tx: { a: 500 } }, geneve: { rx: {}, tx: {} }, pods: { rx: [], tx: [{ node: 'a', namespace: 'x', value: 500 }] } };
  const s = buildSankey(r, 'tx', { hideNodes: true });
  assert.deepEqual(s.links, [{ source: 'ns:x', target: 'cls:external', value: 500 }]);
});

test('hideNodes combines with ownOnly and folds top-N before collapsing', () => {
  const r: RawInputs = {
    ...raw,
    pods: { rx: [{ node: 'a', namespace: 'op1st-x', value: 400 }, { node: 'a', namespace: 'openshift-y', value: 100 }], tx: [] }
  };
  const s = buildSankey(r, 'rx', { ownOnly: true, hideNodes: true });
  assert.deepEqual(s.nodes.filter((n) => n.kind === 'namespace').map((n) => n.id), ['ns:op1st-x']);
  assert.ok(!s.nodes.some((n) => n.kind === 'node'));
  const many: RawInputs = { ...raw, pods: { rx: Array.from({ length: 17 }, (_, i) => ({ node: 'a', namespace: `n${i}`, value: 10 + i })), tx: [] } };
  const f = buildSankey(many, 'rx', { hideNodes: true });
  assert.equal(f.nodes.filter((n) => n.kind === 'namespace').length, 16); // 15 + "other (2)"
});

test('isNamespaceName accepts k8s names and rejects anything PromQL-shaped', () => {
  for (const ok of ['a', 'op1st-x', 'openshift-monitoring', 'a'.repeat(63)]) assert.ok(isNamespaceName(ok), ok);
  for (const bad of [null, '', 'A', '-a', 'a-', 'a_b', 'a.b', 'a'.repeat(64), 'x"}', 'x" or 1', 'a\nb', 'a b', '.*', 'x\n'])
    assert.ok(!isNamespaceName(bad), String(bad));
  assert.ok(!isNamespaceName('abc\n')); // $ must not match before a trailing newline
});

test('buildPodTable joins rx/tx, fills gaps with 0 and sorts by rx', () => {
  assert.deepEqual(buildPodTable({ a: 5, b: 9 }, { a: 1, c: 7 }), [
    { pod: 'b', rx: 9, tx: 0 },
    { pod: 'a', rx: 5, tx: 1 },
    { pod: 'c', rx: 0, tx: 7 }
  ]);
});
