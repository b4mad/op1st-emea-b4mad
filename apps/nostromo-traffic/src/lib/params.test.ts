import { test } from 'node:test';
import assert from 'node:assert/strict';
import { parsePodsParams, parseTrafficParams } from './params.ts';

const sp = (q: string) => new URLSearchParams(q);

test('traffic: defaults, flags are opt-in', () => {
  assert.deepEqual(parseTrafficParams(sp('')), { ok: true, value: { range: '1h', own: false, hideNodes: false } });
  assert.deepEqual(parseTrafficParams(sp('range=7d&own=1&nonodes=1')), { ok: true, value: { range: '7d', own: true, hideNodes: true } });
});

test('traffic: rejects unknown, repeated and odd-valued params', () => {
  for (const q of ['x=1', 'range=2h', 'own=0', 'own=', 'nonodes=true', 'nonodes=0', 'nonodes=1&nonodes=1', 'namespace=a', 'range=1h&range=6h'])
    assert.equal(parseTrafficParams(sp(q)).ok, false, q);
});

test('pods: valid namespace + default range', () => {
  assert.deepEqual(parsePodsParams(sp('namespace=op1st-x')), { ok: true, value: { range: '1h', namespace: 'op1st-x' } });
  assert.deepEqual(parsePodsParams(sp('namespace=a&range=24h')), { ok: true, value: { range: '24h', namespace: 'a' } });
});

test('pods: namespace is required and strictly validated; PromQL-ish input is a 400', () => {
  const bad = [
    '', 'namespace=', 'namespace=A', 'namespace=a_b', 'namespace=a.b', 'namespace=-a', `namespace=${'a'.repeat(64)}`,
    'namespace=x%22%7D', 'namespace=x%22%20or%20%22', 'namespace=a%0A', 'namespace=.%2A', 'namespace=a&namespace=b',
    'namespace=a&query=up', 'namespace=a&own=1', 'namespace=a&range=2h', 'range=1h'
  ];
  for (const q of bad) assert.equal(parsePodsParams(sp(q)).ok, false, q);
});
