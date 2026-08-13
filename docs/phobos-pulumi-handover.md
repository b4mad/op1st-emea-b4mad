# phobos handover to Pulumi

This change removes only the central `environment-phobos` Application and its
cluster credential from the `openshift-gitops` ArgoCD instance on nostromo.
The separate `op1st-gitops` instance and its `b4mad-racing` Application and
phobos credential remain unchanged; application desired state stays in
`racing-manifests`.

`environment-phobos` has no ArgoCD resource finalizer. Removing the Application
therefore leaves its 80 live resources in place and stops reconciliation; it
does not delete them. The manifests under `manifests/environments/phobos` stay
temporarily as migration evidence and can be removed in a later cleanup after
the handover has proved stable.

## Do not merge until

- every resource in `environment-phobos.status.resources` has been classified;
- every shared, project-independent resource has been described and imported
  into `durandom/orrery-phobos/prod` with its existing Kubernetes identity;
- application-owned and OLM/controller-generated resources are explicitly
  excluded from Pulumi ownership;
- `pulumi preview --cwd hosts/phobos` is empty;
- the orrery snapshot contains the migrated resources;
- a current backup or recovery procedure exists for every persistent resource;
- both ArgoCD APIs confirm that no object being handed over is also claimed by
  another Application.

## Apply and verify

Merge this PR only after the orrery apply for the final collection. Then verify:

1. `environment-phobos` disappears from the central ArgoCD instance.
2. The `phobos` cluster Secret disappears only from `openshift-gitops`.
3. `b4mad-racing` and the `phobos` Secret in `op1st-gitops` remain present.
4. `pulumi preview --cwd hosts/phobos` remains empty.
5. Cluster operators, OLM Subscriptions and shared services remain healthy.

Rollback is to revert this PR. That restores the central cluster credential and
Application; review its diff before syncing so Pulumi and ArgoCD never resume
ownership of the same fields concurrently.
