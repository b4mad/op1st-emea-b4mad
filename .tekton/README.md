# Pipelines as Code pipelines

| Pipeline | What it does |
|---|---|
| `code-scans.yaml` | gitleaks over the git history (`--verbose --redact`) |
| `kustomize-validate.yaml` | `kustomize build` of `manifests/environments/{nostromo,phobos}` and `manifests/applications` |

## A failed run opens a forge issue

Every pipeline has a `finally` task `report-failure`
(`tasks/report-failure.yaml` runs `scripts/ci-report-failure.py`). When the
run's `$(tasks.status)` is `Failed` it opens an issue on
git.b4mad.industries/operate-first/op1st-emea-b4mad, labelled `bug` + `intake`,
assigned to `b4mad-castra`, with each failed step's redacted log as a comment
(over 50k characters: the tail inline, the full log attached). A repeat failure
of the same pipeline on the same branch comments on the open issue instead
(title: `CI failed: <pipeline> on <branch>`). Cancelled runs never open an issue.

### Prerequisites

- Secret `forgejo-b4mad`, key `provider.token`, in namespace `op1st-pipelines`
  (the forge agent `b4mad-gitops`, scope `write:issue`). Without it the step logs
  "no FORGEJO_TOKEN" and exits 0: shipping this cannot break a pipeline.
- `b4mad-gitops` needs write access to the repo.
- Labels `bug` and `intake` must exist in the repo; a missing one is skipped with a warning.
- `b4mad-castra` must be assignable; if not, the issue is opened unassigned and says so.
- The `pipeline` ServiceAccount reads TaskRuns and pod logs (the `edit` ClusterRole).

### ⚠️ Logs are public

The repo, and so the issues, are public. The script redacts private keys,
bearer/basic tokens, `*token|secret|password|key=...` assignments and URL
credentials. That is best-effort. Two rules follow:

- Never print a secret in a CI step.
- `gitleaks` must keep `--redact`, or a finding's matched secret goes into a public issue.

The script reads from the clone, so a failing `clone-source` produces no report.

### Adding a pipeline

Copy the `finally:` block and the `.tekton/tasks/report-failure.yaml` entry in
the `pipelinesascode.tekton.dev/task` annotation from an existing pipeline.
`scripts/check-tekton-report-failure.py` (pre-commit hook `tekton-report-failure`)
fails if a `.tekton/*.yaml` PipelineRun lacks them.

### Tests

`python3 -m unittest discover -s tests` (stdlib; the guard test needs PyYAML).
