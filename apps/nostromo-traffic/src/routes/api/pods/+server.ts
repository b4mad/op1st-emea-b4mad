import { json, error } from '@sveltejs/kit';
import { getPods } from '$lib/server/traffic';
import { parsePodsParams } from '$lib/params';
import type { RequestHandler } from './$types';

export const GET: RequestHandler = async ({ url }) => {
  const p = parsePodsParams(url.searchParams);
  if (!p.ok) error(400, p.message);
  try {
    return json(await getPods(p.value.range, p.value.namespace), { headers: { 'cache-control': 'public, max-age=30' } });
  } catch (e) {
    console.error('pods query failed:', e instanceof Error ? e.message : e);
    error(502, 'metrics backend unavailable');
  }
};
