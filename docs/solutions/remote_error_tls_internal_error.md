# Cannot communicate with resources (`oc logs`, `oc debug`), tls internal server error

## Issue

When trying to communicate with resources using `oc logs`, `oc debug`, or other commands, you receive a TLS internal server error.

```bash
$ oc logs console-abc-123

Error from server: Get https://node-0.example.com:10250/containerLogs/openshift-console/console-abc-123/console: remote error: tls: internal error
```

## Environment

- Red Hat OpenShift Container Platform 4.15
- Red Hat OpenShift Container Platform 4.16
- Red Hat OpenShift Container Platform 4.17

## Resolution

Approve all the pending CSRs (Certificate Signing Requests) in the cluster.

```bash
oc get csr -o go-template='{{range .items}}{{if not .status}}{{.metadata.name}}{{"\n"}}{{end}}{{end}}' | xargs --no-run-if-empty oc adm certificate approve

```

## Root Cause

This has been noted in related Bugzilla: [BZ-1733331](https://bugzilla.redhat.com/show_bug.cgi?id=1733331)

## Product Documentation

- [Approving the certificate signing requests for your machines](https://docs.openshift.com/container-platform/4.17/installing/installing_bare_metal/installing-bare-metal.html#installation-approve-csrs_installing-bare-metal)
- [Cannot see logs in console and oc logs, oc exec, etc give tls internal server error](https://access.redhat.com/solutions/4307511)
- [MachineApproverMaxPendingCSRsReached alert firing in OpenShift Container Platform 4](https://access.redhat.com/solutions/5658021)
