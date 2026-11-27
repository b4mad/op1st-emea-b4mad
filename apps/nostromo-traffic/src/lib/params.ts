// Request-parameter allow-lists, shared by the API routes. Pure (no $env), so node:test can import it.
// Anything not listed here is a 400: unknown params, repeated params, odd values.
import { isNamespaceName } from './model.ts';

export const RANGES = { '1h': '1h', '6h': '6h', '24h': '24h', '7d': '7d' } as const;
export type RangeKey = keyof typeof RANGES;
export const isRange = (r: string | null): r is RangeKey => r !== null && Object.hasOwn(RANGES, r);

export type Parsed<T> = { ok: true; value: T } | { ok: false; message: string };

function check(sp: URLSearchParams, allowed: string[]): string | null {
  for (const k of new Set(sp.keys())) {
    if (!allowed.includes(k)) return `unknown parameter ${k}`;
    if (sp.getAll(k).length > 1) return `parameter ${k} given more than once`;
  }
  return null;
}

const RANGE_MSG = 'range must be one of 1h, 6h, 24h, 7d';

// GET /api/traffic?range=&own=1&nonodes=1   (flags are opt-in: presence with value 1 turns the filter on)
export function parseTrafficParams(sp: URLSearchParams): Parsed<{ range: RangeKey; own: boolean; hideNodes: boolean }> {
  const bad = check(sp, ['range', 'own', 'nonodes']);
  if (bad) return { ok: false, message: bad };
  const range = sp.get('range') ?? '1h';
  if (!isRange(range)) return { ok: false, message: RANGE_MSG };
  const own = sp.get('own');
  if (own !== null && own !== '1') return { ok: false, message: 'own must be 1 when present' };
  const nonodes = sp.get('nonodes');
  if (nonodes !== null && nonodes !== '1') return { ok: false, message: 'nonodes must be 1 when present' };
  return { ok: true, value: { range, own: own === '1', hideNodes: nonodes === '1' } };
}

// GET /api/pods?range=&namespace=   (namespace is required and must be a k8s namespace name)
export function parsePodsParams(sp: URLSearchParams): Parsed<{ range: RangeKey; namespace: string }> {
  const bad = check(sp, ['range', 'namespace']);
  if (bad) return { ok: false, message: bad };
  const range = sp.get('range') ?? '1h';
  if (!isRange(range)) return { ok: false, message: RANGE_MSG };
  const namespace = sp.get('namespace');
  if (!isNamespaceName(namespace)) return { ok: false, message: 'namespace must be a valid Kubernetes namespace name' };
  return { ok: true, value: { range, namespace } };
}
