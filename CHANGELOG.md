## v0.1.0-dev1 (2023-10-04)

### Feat

- **monitoring**: enable grafana of openshift-monitoring
- **sealed-secrets**: add monitoring and alerting
- **pipelines**: update to OpenShift Pipelines v1.12
- **prow**: add prow config validation presubmit job
- **sealed-secrets**: update the sealed-secrets operator, and vendored it in (thus removing dependency on external gitops-catalog)
- **argocd-image-updater**: add the argocd-image-updater app
- **argocd-image-updater**: use sha for branch name
- **argocd-image-updater**: use a new branch for the write-back of new image tags
- **secrets**: add peribolos secrets
- **secrets**: start adding sops-encoded secrets
- ✨ configure alertmanager receivers on env:phobos
- ✨ alert on disk <20% available bytes
- ✨ use alertmanager discord plugin for Critical and Default
- ✨ use alertmanager discord plugin
- ✨ use alertmanager discord plugin
- add admin-acks, based on https://access.redhat.com/articles/6958395
- enable grafana of cluster-monitoring on env:nostromo

### Fix

- **argocd**: allow argocd to patch podmonitors
- **prow**: some more prow config fixes
- **prow**: fix some errors found by `checkconfig`
- **sealed-secrets**: put the resources into the correct namespace
- cycle miniso secrets

### Refactor

- **commitizen**: add commitizen config
- **grafana-operator**: remove grafana-operator from nostromo
- **openshift-gitops**: decoupled form gitops-catalog
- update kustomization files to new format
- **op1st-pipelines**: add codeberg secret to repo
- **openshift**: using the 'fast' channel now
- **prow**: update utility image versions, remove phobos from inrepo-clusters
- **argocd**: move argocd-image-updater app to cluster-management project, as we need to modify the openshift-gitops namespace
- add some more to the git ignore list
