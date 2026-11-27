import { json, error } from '@sveltejs/kit';
import { getTraffic } from '$lib/server/traffic';
import { parseTrafficParams } from '$lib/params';
import type { RequestHandler } from './$types';

export const GET: RequestHandler = async ({ url }) => {
  const p = parseTrafficParams(url.searchParams);
  if (!p.ok) error(400, p.message);
  try {
    const { range, own, hideNodes } = p.value;
    return json(await getTraffic(range, { ownOnly: own, hideNodes }), { headers: { 'cache-control': 'public, max-age=30' } });
  } catch (e) {
    console.error('traffic query failed:', e instanceof Error ? e.message : e);
    error(502, 'metrics backend unavailable');
  }
};
