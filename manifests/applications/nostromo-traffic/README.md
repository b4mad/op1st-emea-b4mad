# nostromo-traffic

A SvelteKit app that draws the network traffic of the nostromo cluster as a Sankey
diagram, from the **existing Prometheus metrics** via the Thanos querier. No NetObserv,
no extra operator. Source: `apps/nostromo-traffic/`.

> ⚠️ The Route is **public and unauthenticated** — an explicit decision (bead
> `op1st-emea-b4mad-2pv.3`). It exposes namespace names and traffic volumes. Guards:
> fixed server-side PromQL, allowlisted time range, 60 s server-side cache, read-only SA.

## Deploy

```bash
oc apply -k manifests/applications/nostromo-traffic   # namespace, SA+CRB, ImageStream, Pipeline, Deployment, Service, Route
oc create -f manifests/applications/nostromo-traffic/pipelinerun.yaml   # first build
tkn -n nostromo-traffic pipelinerun logs -f --last
oc -n nostromo-traffic get route nostromo-traffic -o jsonpath='{.spec.host}'
```

The Deployment has an ImageStream trigger: it starts (and rolls out) when the build pushes
`:latest`. Until the first build succeeds the pod shows `ImagePullBackOff` — that is expected.

**The build clones `github.com/b4mad/op1st-emea-b4mad` `main`** (like the borg build), so
`apps/nostromo-traffic/` must exist there first. To build another revision:
copy `pipelinerun.yaml` and add `params: [{name: git-revision, value: <branch>}]` under `spec`.
Not in the Argo app-of-apps; `pipelinerun.yaml` is not in the kustomization (generateName).

## Security model

- ServiceAccount `nostromo-traffic`, bound **only** to `cluster-monitoring-view`; the app reads its
  projected token on every query. No other permissions.
- Restricted-v2 SCC: non-root arbitrary UID, read-only root FS, all capabilities dropped.
- The client sends only `?range=` (one of `1h|6h|24h|7d`) and optionally `?own=1`; anything else is a 400. `own=1` hides platform namespaces: only those starting with `b4mad-`, `feeldata-`, `machdenstaat-`, `op1st-` stay (list: `OWN_NS_PREFIXES` in `src/lib/model.ts`).
  PromQL is defined in `apps/nostromo-traffic/src/lib/server/traffic.ts`, never taken from the client.
- Results are cached 60 s per range (concurrent requests share one in-flight query; failures are not cached).

## What Prometheus can and cannot show

It has **byte counters per interface or pod, not per-connection flows**. Hence:

- Namespace widths are **exact**: sum of pod `eth0` rates.
- "external / internal" can only be inferred **per node**, not per namespace. It is an estimate.
- Host-network pods (kubelet, etcd, the ingress router, …) are not attributed to namespaces
  (cAdvisor reports them on the node NIC, which would double-count), so they land in the
  *external / host-network* bucket. Ingress arrives through the hostNetwork router and is DNAT'd, so
  it also appears there, not per pod.
- node-exporter does not expose `br-ex`, `ovn-k8s-mp0` or `veth*` on nostromo, so egress cannot be read at `br-ex`.
- `ovnkube_*` metrics are control-plane only (no byte counters), so they are unused.

## Queries (`W` = the selected range; values are average bytes/s over `W`)

| Name | PromQL | Meaning |
|---|---|---|
| nicRx / nicTx | `sum by (instance)(rate(node_network_{receive,transmit}_bytes_total{device!~"lo\|genev_sys.*\|ovs-system\|veth.*\|br-.*\|ovn.*\|docker.*"}[W]))` | Physical NIC per node (`eno1` on bridge, `enp2s0` on river). Everything entering/leaving the node, including geneve-encapsulated overlay packets. |
| genRx / genTx | `sum by (instance)(rate(node_network_{receive,transmit}_bytes_total{device=~"genev_sys.*"}[W]))` | Decapsulated overlay traffic = pod traffic to/from the **other node**. |
| podRx / podTx | `sum by (node, namespace)(rate(container_network_{receive,transmit}_bytes_total{interface="eth0",pod!=""}[W]))` | Pod-network traffic per namespace and node (host-network pods excluded). Includes pod↔pod on the same node. |

## Inference per node (`total` = Σ pod rate on that node)

```
overlay  = min(geneve, total)
external = min(max(NIC − geneve, 0), total − overlay)
local    = total − overlay − external
```

Clamped, so the three always sum to `total`. Because NIC also carries host-network traffic,
`external` is an **upper bound** for pod-external traffic.

## Sankey edges

Received view: `source class → node → namespace`. Sent view is the mirror: `namespace → node → destination class`.

| Edge | Represents |
|---|---|
| `external / host-network (est.)` ↔ node | NIC traffic not explained by the overlay, capped at what pods handled. |
| `other node via overlay` ↔ node | Pod traffic crossing the geneve tunnel to/from the other node. |
| `same-node pods` ↔ node | Remainder of pod traffic: pods talking to pods on the same node (never leaves the node, invisible on any NIC). |
| node ↔ namespace | Exact pod `eth0` rate of that namespace on that node. Top 15 namespaces; the rest is grouped as `other (N)`. |

## Local development

```bash
cd apps/nostromo-traffic && npm ci
THANOS_URL=https://thanos-querier-openshift-monitoring.apps.<domain> THANOS_TOKEN=$(oc whoami -t) npm run dev
npm run check && npm test && npm run build
```
