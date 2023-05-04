# Op1st DevSecOps by #B4mad

![Op1st by #B4mad][op1stb4mad]

This repository implements [Operate First SIG/SRE Infrastructure Services](https://github.com/operate-first/community/issues/251)
and partialy [Hybride Cloud Patterns: Multicluster DevSecOps](https://hybrid-cloud-patterns.io/patterns/devsecops/)

## Directory Structure

All kustomize manifests are located below the `manifests/` directory.

### Resources

Manifests that are generally useful or applicable are located in the `resources/` directory. These are not intended
to be deployed directly, but rather used as a base for other (environment specific) manifests.

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

## Infrastructure Services

On the nostromo environment we have deployed and configured the following infrastructure services:

* Red Hat OpenShift Pipelines
* Red Hat OpenShift GitOps

## Usage

To configure a specific environment, run `kustomize build manifests/environments/nostromo | oc apply -f -`

[op1stb4mad]: https://raw.githubusercontent.com/b4mad/op1st-emea-b4mad/main/images/op1stb4mad.png "Op1st by #B4mad"
