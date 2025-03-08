# op1st DevSecOps by #B4mad

![op1st by #B4mad][op1stb4mad]

This repository implements [Operate First SIG/SRE Infrastructure Services](https://github.com/operate-first/community/issues/251)

and partialy [Hybride Cloud Patterns: Multicluster DevSecOps](https://hybrid-cloud-patterns.io/patterns/devsecops/)

It is also available via [radicle](https://radicle.xyz/guides/user) as [rad:z2y94Zx8RUfQBNQD2nSpPLN5CW7NQ](https://app.radicle.xyz/nodes/radicle.b4mad.net/rad:z2y94Zx8RUfQBNQD2nSpPLN5CW7NQ).

## Service Status

### Operate First Infrastructure Services

On the nostromo environment we have deployed and configured the following infrastructure services:

- Operate First GitOps [![CD/GitOps](https://openshift-gitops-server-openshift-gitops.apps.nostromo.erdgeschoss.b4mad.emea.operate-first.cloud/api/badge?name=op1st-gitops&revision=true)](https://openshift-gitops-server-openshift-gitops.apps.nostromo.erdgeschoss.b4mad.emea.operate-first.cloud/applications/op1st-gitops)
- Operate First Pipelines [![CI/Pipelines](https://openshift-gitops-server-openshift-gitops.apps.nostromo.erdgeschoss.b4mad.emea.operate-first.cloud/api/badge?name=op1st-pipelines&revision=true)](https://openshift-gitops-server-openshift-gitops.apps.nostromo.erdgeschoss.b4mad.emea.operate-first.cloud/applications/op1st-pipelines)
- Open Policy Agent Gatekeeper [![App Status](https://openshift-gitops-server-openshift-gitops.apps.nostromo.erdgeschoss.b4mad.emea.operate-first.cloud/api/badge?name=gatekeeper&revision=true&showAppName=true)](https://openshift-gitops-server-openshift-gitops.apps.nostromo.erdgeschoss.b4mad.emea.operate-first.cloud/applications/gatekeeper)

These services are deployed on the nostromo environment.

### Hosted community services

- [#B4mad Racing](https://b4mad.racing/) [![#B4mad Racing](https://argocd.b4mad.emea.operate-first.cloud/api/badge?name=b4mad-racing&revision=true)](https://argocd.b4mad.emea.operate-first.cloud/applications/b4mad-racing)

We follow an app-of-apps pattern, where we have a single `kustomization.yaml` file that references all other manifests,
it can be found in the `manifests/applications/app-of-apps.yaml` file.

## Directory Structure

All kustomize manifests are located below the `manifests/` directory.

### Component manifests

Manifests that are generally useful or applicable are located in the `component/` directory. These are not intended
to be deployed directly, but rather used as a reusable component for other (environment specific) manifests.

### Organizational Unit scoped manifests

These manifests are valid and applicaple to the whole #B4mad organizational unit of Operate First, they should be
deployed to each of our clusters.

### Cluster scoped manifests

These manifests are valid and applicable to a single cluster, they should be deployed to a cluster. They are agnostic
to any organizational unit and implement a specific functionality/configuration that is generally applicable.

### Environment scoped manifests

These manifests are valid and applicable to a single environment, they should be deployed to a cluster and may reference
ou or cluster scoped manifests. They implement a specific functionality/configuration that is specific to a single
environment.

A few of the configurations [recommended for Single-Node OpenShift](https://docs.openshift.com/container-platform/4.12/scalability_and_performance/ztp_far_edge/ztp-reference-cluster-configuration-for-vdu.html) have been implemented as well.

## Usage

To configure a specific environment, run `kustomize build manifests/environments/nostromo | oc apply -f -`

[op1stb4mad]: images/op1stb4mad.svg "Op1st by #B4mad"

## Funding

If you like this project, or depend on it, feel free to support it via the [drips.network](https://www.drips.network) and check out <https://www.drips.network/app/projects/github/b4mad/op1st-emea-b4mad>
