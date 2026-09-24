# b4mad-openobserve

Standalone [OpenObserve](https://openobserve.ai) (OSS, single binary) for the
#B4mad Network, at <https://observe.b4mad.industries>.

Cloned from castra's in-cluster instance
(`agentic-forges/castra`, `manifests/telemetry/`), which keeps running
unchanged in `b4mad-castra`. The two instances share nothing.

## Placement and sizing

| | Value | Why |
| --- | --- | --- |
| Node | prefers `river` | Lots of free CPU, little free memory. |
| CPU | 250m request, 4 limit | CPU is cheap on river; queries and compaction burst. |
| Memory | 1Gi request = limit | River's memory limits are overcommitted; staying within the request keeps the pod off the OOM-kill shortlist. |
| Storage | 25Gi, `lvms-vg1` | Node-local LVMS. |

⚠️ The volume is node-local. Wherever the pod is **first** scheduled, the PVC
binds there and pins the pod to that node for good. If it lands on `bridge`
(river unavailable at first sync), moving it later means deleting the PVC and
its data.

⚠️ OpenObserve sizes its memtable and memory cache as a percentage of total
memory. `ZO_MEM_TABLE_MAX_SIZE` and `ZO_MEMORY_CACHE_MAX_SIZE` are pinned to
256 MB so they fit inside the 1Gi limit, whatever memory figure it reads.

Retention is OpenObserve's default (`ZO_COMPACT_DATA_RETENTION_DAYS`, 3650
days). Nothing expires data before the 25Gi volume fills.

## Credentials

The root account lives in `openobserve-credentials`: SOPS source in
`openobserve-credentials.enc.yaml`, applied as the SealedSecret in
`openobserve-credentials.yaml`. To reseal after changing it:

```bash
scripts/sops2sealedsecret --force \
  --context default/api-nostromo-erdgeschoss-b4mad-emea-operate-first-cloud:6443/goern \
  --namespace b4mad-openobserve \
  manifests/applications/b4mad-openobserve/openobserve-credentials.enc.yaml \
  manifests/applications/b4mad-openobserve/openobserve-credentials.yaml
```

## Sending telemetry

OTLP ingest is cluster-internal (headless Service, ports 5080 HTTP and 5081
gRPC). The organization is a path segment:

```
OTEL_EXPORTER_OTLP_ENDPOINT: http://openobserve.b4mad-openobserve.svc:5080/api/<org>
OTEL_EXPORTER_OTLP_PROTOCOL: http/protobuf
OTEL_EXPORTER_OTLP_HEADERS:  Authorization=Basic <base64(email:password)>
```

## Not included

- **SSO.** OSS has none. The UI is public behind OpenObserve's own login only.
