# nostromo-traffic

A SvelteKit app that draws the network traffic of the nostromo cluster as a Sankey
diagram, from the **existing Prometheus metrics** via the Thanos querier. No NetObserv,
no extra operator. Source: `apps/nostromo-traffic/`.

> ⚠️ Sign-in is required (bead `op1st-emea-b4mad-2pv.7`; it was public before,
> `.3`). An oauth2-proxy sidecar authenticates against Zitadel
> (`id.b4mad.industries`, project/app `traffic-app` in org erdgeschoss). Allowed:
> every user of org erdgeschoss plus goern (org b4mad); nobody else. The app binds
> `127.0.0.1`, so the proxy (Service port 4180) is the only way in. Further guards:
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

## Sign-in (Zitadel)

- Zitadel side is declared in `manifests/applications/b4mad-zitadel/config/main.tf`
  (`traffic_eg`) and applied by the `zitadel-config` Job. That Job writes Secret
  `traffic-oidc-zitadel` (client id/secret plus a generated cookie secret, none in git);
  reflector copies it into this namespace.
- ⚠️ **Order matters:** this app is not in Argo. After merging, wait for Argo to sync
  b4mad-zitadel and the Job to finish, check
  `oc -n nostromo-traffic get secret traffic-oidc-zitadel`, **then** `oc apply -k`.
  Until the Secret exists the pod stays in `CreateContainerConfigError`.
- A new erdgeschoss user gets access on the next `zitadel-config` Job run.
- The redirect URI is derived from the Route host; if the host changes, update
  `traffic_url` in `main.tf` and the `--redirect-url` arg in `deployment.yaml`.

## Security model

- ServiceAccount `nostromo-traffic`, bound **only** to `cluster-monitoring-view`; the app reads its
  projected token on every query. No other permissions.
- Restricted-v2 SCC: non-root arbitrary UID, read-only root FS, all capabilities dropped.
- Two read-only endpoints, each with a strict allow-list (`src/lib/params.ts`); unknown, repeated or odd-valued params are a 400:
  - `GET /api/traffic?range=&own=1&nonodes=1`: `range` is one of `1h|6h|24h|7d`; `own=1` hides platform namespaces (only those starting with `b4mad-`, `feeldata-`, `machdenstaat-`, `op1st-` stay; list: `OWN_NS_PREFIXES` in `src/lib/model.ts`); `nonodes=1` collapses the `node:*` hubs (class → namespace directly, bytes conserved). Flags are opt-in at the API; the UI sends `nonodes=1` by default ("hide node traffic" is checked on load).
  - `GET /api/pods?range=&namespace=`: per-pod rx/tx table. `namespace` is required and must match `^[a-z0-9]([-a-z0-9]{0,61}[a-z0-9])?$` (k8s namespace name; no quotes, braces or backslashes can pass), otherwise 400. It is the only client string that reaches PromQL, and it is re-checked server-side before interpolation.
  PromQL is defined in `apps/nostromo-traffic/src/lib/server/traffic.ts`, never taken from the client.
- Results are cached 60 s per range (concurrent requests share one in-flight query; failures are not cached). The pod table is cached 60 s per (range, namespace), bounded to 200 entries.
- Host-network pods are not in the pod table: cAdvisor reports them on the node's own interfaces, never `eth0`, and the query selects `interface="eth0"` only (same rule as the Sankey).

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
