<script lang="ts">
  import { sankey, sankeyLinkHorizontal } from 'd3-sankey';
  import { isNamespaceName, type PodRow, type SankeyData } from '$lib/model';

  const RANGES = ['1h', '6h', '24h', '7d'];
  let range = $state('1h');
  let ownOnly = $state(false);
  let hideNodes = $state(true); // default: node hubs collapsed
  let dir = $state<'rx' | 'tx'>('rx');
  let result = $state<{ generatedAt: string; rx: SankeyData; tx: SankeyData } | null>(null);
  let err = $state('');
  let loading = $state(false);

  $effect(() => {
    const r = range;
    const own = ownOnly;
    const hn = hideNodes;
    loading = true;
    err = '';
    fetch(`/api/traffic?range=${r}${own ? '&own=1' : ''}${hn ? '&nonodes=1' : ''}`)
      .then((res) => (res.ok ? res.json() : Promise.reject(new Error(`HTTP ${res.status}`))))
      .then((j) => r === range && own === ownOnly && hn === hideNodes && (result = j))
      .catch((e) => (err = String(e.message ?? e)))
      .finally(() => (loading = false));
  });

  // Selected namespace -> per-pod table. The server validates the name again.
  let selected = $state<string | null>(null);
  let podRows = $state<PodRow[] | null>(null);
  let podErr = $state('');
  let podLoading = $state(false);

  $effect(() => {
    const ns = selected;
    const r = range;
    podRows = null;
    podErr = '';
    if (!ns) return;
    podLoading = true;
    fetch(`/api/pods?range=${r}&namespace=${encodeURIComponent(ns)}`)
      .then((res) => (res.ok ? res.json() : Promise.reject(new Error(`HTTP ${res.status}`))))
      .then((j) => ns === selected && r === range && (podRows = j.pods))
      .catch((e) => (podErr = String(e.message ?? e)))
      .finally(() => (podLoading = false));
  });

  // Only real namespaces are clickable; the "other (N)" fold node is not one.
  const clickable = (n: { kind: string; label: string }) => n.kind === 'namespace' && isNamespaceName(n.label);
  const pick = (n: { kind: string; label: string }) => {
    if (clickable(n)) selected = selected === n.label ? null : n.label;
  };

  const W = 1100;
  const H = 640;
  const COLORS: Record<string, string> = { class: '#8a8f98', node: '#2f6fed', namespace: '#1f9d6b' };

  const graph = $derived.by(() => {
    const d = result?.[dir];
    if (!d || !d.links.length) return null;
    const layout = sankey<any, any>()
      .nodeId((n: any) => n.id)
      .nodeWidth(14)
      .nodePadding(10)
      .extent([[1, 6], [W - 1, H - 6]]);
    return layout({
      nodes: d.nodes.map((n) => ({ ...n })),
      links: d.links.map((l) => ({ ...l }))
    });
  });

  const fmt = (v: number) => {
    const u = ['B/s', 'KB/s', 'MB/s', 'GB/s'];
    let i = 0;
    while (v >= 1000 && i < u.length - 1) (v /= 1000), i++;
    return `${v.toFixed(v < 10 ? 2 : 1)} ${u[i]}`;
  };
  const link = sankeyLinkHorizontal();
</script>

<main>
  <h1>nostromo traffic</h1>
  <div class="bar">
    <span>
      {#each RANGES as r}
        <button class:on={r === range} onclick={() => (range = r)}>{r}</button>
      {/each}
    </span>
    <span>
      <button class:on={dir === 'rx'} onclick={() => (dir = 'rx')}>received</button>
      <button class:on={dir === 'tx'} onclick={() => (dir = 'tx')}>sent</button>
    </span>
    <label><input type="checkbox" bind:checked={ownOnly} /> hide platform namespaces</label>
    <label><input type="checkbox" bind:checked={hideNodes} /> hide node traffic</label>
    <small>{loading ? 'loading…' : result ? `avg over ${range}, as of ${new Date(result.generatedAt).toLocaleTimeString()}` : ''}</small>
  </div>

  {#if err}<p class="err">Error: {err}</p>{/if}

  {#if graph}
    <svg viewBox="0 0 {W} {H}" role="img" aria-label="Sankey diagram of cluster network traffic">
      {#each graph.links as l}
        <path d={link(l)} fill="none" stroke={COLORS[(dir === 'rx' ? l.source : l.target).kind]} stroke-opacity="0.3" stroke-width={Math.max(1, l.width)}>
          <title>{l.source.label} → {l.target.label}: {fmt(l.value)}</title>
        </path>
      {/each}
      {#each graph.nodes as n}
        <!-- svelte-ignore a11y_no_noninteractive_tabindex -->
        <rect x={n.x0} y={n.y0} width={n.x1 - n.x0} height={Math.max(1, n.y1 - n.y0)} fill={COLORS[n.kind]}
          class:pick={clickable(n)} class:sel={clickable(n) && selected === n.label}
          role={clickable(n) ? 'button' : undefined} tabindex={clickable(n) ? 0 : undefined}
          onclick={() => pick(n)}
          onkeydown={(e) => (e.key === 'Enter' || e.key === ' ') && clickable(n) && (e.preventDefault(), pick(n))}>
          <title>{n.label}: {fmt(n.value)}{clickable(n) ? ' (click for pods)' : ''}</title>
        </rect>
        <text x={n.x0 < W / 2 ? n.x1 + 6 : n.x0 - 6} y={(n.y0 + n.y1) / 2} dy="0.35em" text-anchor={n.x0 < W / 2 ? 'start' : 'end'}>
          {n.label} · {fmt(n.value)}
        </text>
      {/each}
    </svg>
  {:else if !loading && !err}
    <p>No traffic data.</p>
  {/if}

  {#if selected}
    <section class="pods">
      <h2>
        Pods in <code>{selected}</code>
        <button onclick={() => (selected = null)}>close</button>
      </h2>
      {#if podLoading}<p>loading…</p>{/if}
      {#if podErr}<p class="err">Error: {podErr}</p>{/if}
      {#if podRows && podRows.length}
        <table>
          <thead><tr><th>pod</th><th class="num">received</th><th class="num">sent</th></tr></thead>
          <tbody>
            {#each podRows as p}
              <tr><td>{p.pod}</td><td class="num">{fmt(p.rx)}</td><td class="num">{fmt(p.tx)}</td></tr>
            {/each}
          </tbody>
        </table>
        <p class="note">Average over {range}, sorted by received. Pod-network pods only; host-network pods are not listed.</p>
      {:else if podRows}
        <p>No pod-network traffic in this namespace.</p>
      {/if}
    </section>
  {/if}

  <p class="note">
    Prometheus byte counters, not flows. Namespace widths are exact (pod <code>eth0</code>); the
    source/destination class is inferred per node (NIC vs geneve overlay) and is an estimate.
    See the README.
  </p>
</main>

<style>
  :global(body) { font: 14px system-ui, sans-serif; margin: 0; background: #fff; color: #1b1f24; }
  @media (prefers-color-scheme: dark) { :global(body) { background: #14171b; color: #e6e8eb; } }
  main { max-width: 1200px; margin: 0 auto; padding: 1rem; }
  .bar { display: flex; gap: 1.5rem; align-items: center; flex-wrap: wrap; margin-bottom: .5rem; }
  button { padding: .3rem .8rem; border: 1px solid #8a8f98; background: transparent; color: inherit; cursor: pointer; }
  button.on { background: #2f6fed; border-color: #2f6fed; color: #fff; }
  svg { width: 100%; height: auto; }
  rect.pick { cursor: pointer; }
  rect.sel { stroke: currentColor; stroke-width: 2; }
  .pods h2 { font-size: 1rem; display: flex; gap: 1rem; align-items: center; }
  table { border-collapse: collapse; }
  th, td { padding: .25rem .8rem; text-align: left; border-bottom: 1px solid #8a8f9855; }
  .num { text-align: right; font-variant-numeric: tabular-nums; }
  text { font-size: 12px; fill: currentColor; }
  .err { color: #d1242f; }
  .note { opacity: .7; max-width: 70ch; }
</style>
