import { test } from 'node:test';
import assert from 'node:assert/strict';
import { buildSankey, isOwnNamespace, type RawInputs } from './model.ts';

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
  const own = buildSankey(r, 'rx', true);
  assert.ok(!own.nodes.some((n) => n.id === 'ns:openshift-y'));
  assert.ok(own.nodes.some((n) => n.id === 'ns:op1st-x'));
  assert.equal(own.links.filter((l) => l.source === 'node:a' || l.target === 'node:a').length, own.links.length);
  assert.equal(own.links.filter((l) => l.target === 'node:a').reduce((a, l) => a + l.value, 0), 400);
});
