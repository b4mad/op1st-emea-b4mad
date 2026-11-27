import { json, error } from '@sveltejs/kit';
import { getTraffic, isRange } from '$lib/server/traffic';
import type { RequestHandler } from './$types';

export const GET: RequestHandler = async ({ url }) => {
  const range = url.searchParams.get('range') ?? '1h';
  if (!isRange(range)) error(400, 'range must be one of 1h, 6h, 24h, 7d');
  const own = url.searchParams.get('own');
  if (own !== null && own !== '1') error(400, 'own must be 1 when present');
  try {
    return json(await getTraffic(range, own === '1'), { headers: { 'cache-control': 'public, max-age=30' } });
  } catch (e) {
    console.error('traffic query failed:', e instanceof Error ? e.message : e);
    error(502, 'metrics backend unavailable');
  }
};
