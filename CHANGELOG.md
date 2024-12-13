# CHANGELOG


## v0.2.3 (2024-12-13)

### Chores

- **nostromo**: Reencrypt github oauth authentication app secret
  ([`c681c16`](https://github.com/goern/op1st-emea-b4mad/commit/c681c16f56421356777d02cc5ff4a8946f2c450f))

Signed-off-by: Christoph Görn <goern@b4mad.net>

### Features

- **pipelines**: Be specific about the namespaces in gatekeepers constraints
  ([`fa274a9`](https://github.com/goern/op1st-emea-b4mad/commit/fa274a90ab0b06f052e553c81623647722da8915))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- **pipelines**: Allow more image repositories for op1st-pipelines
  ([`4fa840b`](https://github.com/goern/op1st-emea-b4mad/commit/4fa840b09938c06463e54104370657ab01b09d34))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- **pipelines**: Allow quay.io/skopeo/stable:v1 for op1st-pipelines
  ([`b2d9d03`](https://github.com/goern/op1st-emea-b4mad/commit/b2d9d03ba13fb73ffa4458986283d82042816f7e))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- **pipelines**: Configure cluster resolver
  ([`f0b7992`](https://github.com/goern/op1st-emea-b4mad/commit/f0b7992b2ae38e0a24286572d43fa9c66f3f3e7d))

Signed-off-by: Christoph Görn <goern@b4mad.net>


## v0.2.2 (2024-12-13)

### Bug Fixes

- **openshift-pipelines**: Manually create tekton-results-tls secret, as ACME is not able to do so
  (SAN issue)
  ([`1876e44`](https://github.com/goern/op1st-emea-b4mad/commit/1876e4439d1bf0620c2fe45fe03975420e86a2a9))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- **nostromo**: Add SAN to tekton-results tls cert
  ([`c7dcbbb`](https://github.com/goern/op1st-emea-b4mad/commit/c7dcbbb08aadb74afb1c31a72a2c5971348b65a1))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- **nostromo**: Add SAN to tekton-results tls cert
  ([`bc6dbd1`](https://github.com/goern/op1st-emea-b4mad/commit/bc6dbd17b26c36b8278ef35b0253d9f5b1baaa66))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- **nostromo**: Add SAN to tekton-results tls cert
  ([`7bf0bd4`](https://github.com/goern/op1st-emea-b4mad/commit/7bf0bd409f9d9a9c7f677d1f8158be445d879166))

Signed-off-by: Christoph Görn <goern@b4mad.net>

### Build System

- Remove cz config
  ([`9e82c80`](https://github.com/goern/op1st-emea-b4mad/commit/9e82c8052dc999894a069cf227d0fcc85d4c0e72))

Signed-off-by: Christoph Görn <goern@b4mad.net>

### Features

- **nostromo**: Update OpenShift Pipelines to v1.17
  ([`2655d33`](https://github.com/goern/op1st-emea-b4mad/commit/2655d330b5ba04e125c46f1c370d8fd080e361cc))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- Add codeberg.org/toolbxs/bxbdbt, so that it can be used in op1st-pipelines
  ([`c09c287`](https://github.com/goern/op1st-emea-b4mad/commit/c09c28729c1742a054fdb76a7a2d48eda2c3a8e0))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- **nostromo**: Remove NFD deployment
  ([`d6e897a`](https://github.com/goern/op1st-emea-b4mad/commit/d6e897a58f0fb80536db1491264ce612d20ed373))

Signed-off-by: Christoph Görn <goern@b4mad.net>


## v0.2.1 (2024-12-08)

### Bug Fixes

- **nostromo**: Name of the postgresql secret
  ([`0e8d963`](https://github.com/goern/op1st-emea-b4mad/commit/0e8d963edcd6cd8176d238ac091eed8b34864531))

Signed-off-by: Christoph Görn <goern@b4mad.net>

### Features

- **nostromo**: Use fast-4.17 as an update channel
  ([`6944472`](https://github.com/goern/op1st-emea-b4mad/commit/6944472c62e30090e3f35c1788a6b5dd7cb45024))

Signed-off-by: Christoph Görn <goern@b4mad.net>


## v0.2.0 (2024-12-08)

### Build System

- Add release management config
  ([`139327d`](https://github.com/goern/op1st-emea-b4mad/commit/139327d5c56e481d9ad7446f17411492f9d800b6))

Signed-off-by: Christoph Görn <goern@b4mad.net>


## v0.1.0-rc.1 (2024-12-08)

### Bug Fixes

- **phobos**: Github identify provider config
  ([`1ce47f3`](https://github.com/goern/op1st-emea-b4mad/commit/1ce47f3cfd969d9004ce6986395a876fa1a74f60))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- Remove nonexisting users from groups
  ([`df57cc6`](https://github.com/goern/op1st-emea-b4mad/commit/df57cc6d34f161a1db7529cfcd80f1d1fcb7d389))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- **op1st-pipelines**: Tls secret name
  ([`0b2dff6`](https://github.com/goern/op1st-emea-b4mad/commit/0b2dff6f250365fa7e7ffe7384297b253745ac06))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- **op1st-pipelines**: Tls secret name
  ([`7d007eb`](https://github.com/goern/op1st-emea-b4mad/commit/7d007ebc1c7c37808527db6749d1ee1cdbd6eae1))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- **nostromo**: Fix openshift-pipelines missing secrets
  ([`2286b90`](https://github.com/goern/op1st-emea-b4mad/commit/2286b90fde6861aa9076396ef084c72a8b1c4657))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- **gitleaks**: Ignore old commits
  ([`7e0252e`](https://github.com/goern/op1st-emea-b4mad/commit/7e0252ebc143eefad5a0e9ebfc58290465ea821e))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- **gitleaks**: Ignore old commits
  ([`4078e28`](https://github.com/goern/op1st-emea-b4mad/commit/4078e28a6d1924c35dd45261ade05880c3f20af6))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- Allow more resources on op1st project
  ([`e395bd7`](https://github.com/goern/op1st-emea-b4mad/commit/e395bd7819e54af1f7c7eee98ebe148662824c5c))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- Allow more resources on op1st project
  ([`a3c5233`](https://github.com/goern/op1st-emea-b4mad/commit/a3c52337e35b6cd3498cce339e0069b204a196ff))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- Kustomize edit fix kustomization.yaml
  ([`d76658d`](https://github.com/goern/op1st-emea-b4mad/commit/d76658d9ab8777110040d9002ec7a770f4a9ad4f))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- **openshift-gitops**: Dex resources
  ([`831e67c`](https://github.com/goern/op1st-emea-b4mad/commit/831e67c927181a2052039f9a90e659feff930f48))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- **keycloak**: Increase postgresql storage to 8Gi
  ([`0c33e00`](https://github.com/goern/op1st-emea-b4mad/commit/0c33e007112a14f1b6927eb619a91a4aa29d5dac))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- **keycloak-operator**: Check if https://access.redhat.com/solutions/6603001 helps
  ([`0aa3702`](https://github.com/goern/op1st-emea-b4mad/commit/0aa370239d63d492a37e1fd595dfce61045f2d92))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- **nostromo**: Re-add keycloak oauth
  ([`8b3d502`](https://github.com/goern/op1st-emea-b4mad/commit/8b3d5025c2f0297da42487c64e571d9cbf81f5d1))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- **nostromo**: Remove login template and keycloak oauth
  ([`d9bfc2d`](https://github.com/goern/op1st-emea-b4mad/commit/d9bfc2d668b359e1ecce9457605748bfd9516541))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- **cnpg**: Add missing namespace
  ([`8173bf8`](https://github.com/goern/op1st-emea-b4mad/commit/8173bf8cb9f565f67d4e2771684b0bfdd8239441))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- **gatekeeper**: Add missing repos
  ([`f506b2c`](https://github.com/goern/op1st-emea-b4mad/commit/f506b2cad2340ea7f7b08e1a7d7fa962dcfeef13))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- Add keycloak operator repository to allowed repos
  ([`2bd83fb`](https://github.com/goern/op1st-emea-b4mad/commit/2bd83fb4b974095106b1658b7ebd759fc3970ac9))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- Keycloak namespace
  ([`31e0924`](https://github.com/goern/op1st-emea-b4mad/commit/31e0924deb46fe5af31045baa3db9ef3e5809050))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- Add required labels to namespaces
  ([`5f6d2f8`](https://github.com/goern/op1st-emea-b4mad/commit/5f6d2f81e36162b0f2cbfa8ccd25aa818801ac65))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- **ingress**: Need allow-http=false annotation
  ([`437ad8e`](https://github.com/goern/op1st-emea-b4mad/commit/437ad8ea611e957023fd04647a5cfd91faf93d96))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- **keycloak**: Working 1...
  ([`246e88f`](https://github.com/goern/op1st-emea-b4mad/commit/246e88f6ce6c3c525d45ceb52a10aaecae5440b4))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- **keycloak**: Make the backend path type ImplementationSpecific
  ([`a5fdc50`](https://github.com/goern/op1st-emea-b4mad/commit/a5fdc50fd2835c0991918a6817b325ee46c06710))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- Yaml parse error :/
  ([`decec4b`](https://github.com/goern/op1st-emea-b4mad/commit/decec4be3edaaa84a0db51ac595cb62c985a0df4))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- Yaml parse error :/
  ([`588134d`](https://github.com/goern/op1st-emea-b4mad/commit/588134d35c5da5de6a0cfdb7175ac7e34f152cd9))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- Yaml parse error :/
  ([`a460428`](https://github.com/goern/op1st-emea-b4mad/commit/a4604283b9f93043de9de187b8b846e82c1c71b9))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- **keycloak**: Add kubernetes.io/ingress.allow-http: 'false' annotation to ingresses
  ([`97c7f1a`](https://github.com/goern/op1st-emea-b4mad/commit/97c7f1a93ca46d4664aea32ae3e4d84bc4be1e08))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- **keycloak**: Add namespace to allow-http annotation
  ([`9fbb93e`](https://github.com/goern/op1st-emea-b4mad/commit/9fbb93eb25043ee2312002e6f82386322a3f83b4))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- **keycloak**: Ingress name
  ([`122747f`](https://github.com/goern/op1st-emea-b4mad/commit/122747f26f7a8248080f3f27ca7fcf37b0beff9c))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- **nostromo**: Oauth client url
  ([`6243213`](https://github.com/goern/op1st-emea-b4mad/commit/6243213d94c7ed658412adb751afb7a86b7e0124))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- **op1st-gitops**: B4mad-keycloak project
  ([`7c231b2`](https://github.com/goern/op1st-emea-b4mad/commit/7c231b29f91e5302052c7031024698f9dc04b305))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- **lvm-cluster**: Add chunkSizeCalculationPolicy and set it to static
  ([`235e32f`](https://github.com/goern/op1st-emea-b4mad/commit/235e32f4fbb6692eccb6a9d86034d2ca10cae488))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- **lvm-cluster**: Add chunkSizeCalculationPolicy and set it to static
  ([`e659de6`](https://github.com/goern/op1st-emea-b4mad/commit/e659de6d9dcc3dcb0c7c0274c29112cac07e7e8c))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- **nostromo**: Upper-lower case error
  ([`de41f02`](https://github.com/goern/op1st-emea-b4mad/commit/de41f029cebdd672a528cbe2d35b48aaa767048a))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- Repo secret
  ([`54402b9`](https://github.com/goern/op1st-emea-b4mad/commit/54402b9e5a38d73a033c962523ebf64b1f7e135e))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- Add RBAC for argocd-image-updater
  ([`97e72a5`](https://github.com/goern/op1st-emea-b4mad/commit/97e72a52c9cfa30c4a39104b05af0fe3d739cc34))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- Add RBAC for argocd-image-updater
  ([`76575a2`](https://github.com/goern/op1st-emea-b4mad/commit/76575a24b641d6d62319ad25062ab9108745c2c9))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- Namespace of argocd-image-updater application
  ([`3f6a56e`](https://github.com/goern/op1st-emea-b4mad/commit/3f6a56e966eb0b90b0a766fa08b34a45bb163fda))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- Add RBAC for argocd-image-updater
  ([`a3b58ec`](https://github.com/goern/op1st-emea-b4mad/commit/a3b58ecd29e37ecd9eff5968ffdc17878ac7db96))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- Increase number of open file descriptors
  ([`4ebab02`](https://github.com/goern/op1st-emea-b4mad/commit/4ebab0291a84f27f7621053353b278c2b36267ff))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- Increase number of open file descriptors
  ([`f70adc3`](https://github.com/goern/op1st-emea-b4mad/commit/f70adc3131d953e7d13dbe59b1806ca2780e23b9))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- That disablement was unintentionally
  ([`7bfd910`](https://github.com/goern/op1st-emea-b4mad/commit/7bfd91087351d6fdee74f6011d192e5584395c21))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- Apply network-management resources
  ([`65d19d9`](https://github.com/goern/op1st-emea-b4mad/commit/65d19d99a45378812966b68d68a6bbfb616fdb16))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- Update lvmcluster config on phobos too
  ([`0ec102b`](https://github.com/goern/op1st-emea-b4mad/commit/0ec102b8cc649d482b4bc80a64c571a98a4df204))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- Update lvmcluster config
  ([`3b91e45`](https://github.com/goern/op1st-emea-b4mad/commit/3b91e456419a60d4c2699484ce4304856c850a4a))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- Gitops app-of-apps
  ([`426a85d`](https://github.com/goern/op1st-emea-b4mad/commit/426a85db3da146479733f664414bdf6aad0fc139))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- Argh, typo and copynpasta problem, need coffee
  ([`b2fc08a`](https://github.com/goern/op1st-emea-b4mad/commit/b2fc08a1110bb6d9bb191ca449a2ffd8bdc12cf9))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- Argh, typo, we need openshift-lightspeed ;)
  ([`45675c3`](https://github.com/goern/op1st-emea-b4mad/commit/45675c34b9a0f7fe7bcb66869ca101aca7f9bbc3))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- Tide resource
  ([`81b8a74`](https://github.com/goern/op1st-emea-b4mad/commit/81b8a7447ee737165a2a1178d2ccd1733292e76d))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- Operators
  ([`4aabcd3`](https://github.com/goern/op1st-emea-b4mad/commit/4aabcd31cf2c5dfd2ddf0d28b29ccdbf385d101c))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- Operators
  ([`98e566c`](https://github.com/goern/op1st-emea-b4mad/commit/98e566c289b6b869bf595664ebfcfd692fd85181))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- Openshift-gitops-operator no -rh at the end
  ([`f48ef72`](https://github.com/goern/op1st-emea-b4mad/commit/f48ef7212c864942707a08a675770220b7be8be7))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- **alertmanager**: Fix/add missing protocol, this is the root cause for
  https://github.com/operate-first/alerts/issues/29276
  ([`29eeac9`](https://github.com/goern/op1st-emea-b4mad/commit/29eeac9ca46f7f7acd2a20a2bfe1324035dd5f64))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- **phobos**: Reconfigured the url of the upstream crunchy manifests
  ([`fde297e`](https://github.com/goern/op1st-emea-b4mad/commit/fde297e59ec816b192a5c9c36d51e03216adf6ff))

Signed-off-by: Christoph Görn <goern@b4mad.net>

### Build System

- Add release management config
  ([`c372274`](https://github.com/goern/op1st-emea-b4mad/commit/c37227457088c7639a73e8a61c12f2520a29fd09))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- Update argocd-image-update version
  ([`3a3b0f5`](https://github.com/goern/op1st-emea-b4mad/commit/3a3b0f5b7933dbf680218f593d12cae41fa51a26))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- Automatic update of prow
  ([`5ab8512`](https://github.com/goern/op1st-emea-b4mad/commit/5ab8512385d0322c613e659190909bf9208c1d4e))

updates image k8s-prow/branchprotector tag 'v20240204-5365b6c1fa' to 'v20240430-4359601d0' updates
  image k8s-prow/crier tag 'v20240424-a88484dfb' to 'v20240430-4359601d0' updates image
  k8s-prow/deck tag 'v20240424-a88484dfb' to 'v20240430-4359601d0' updates image k8s-prow/ghproxy
  tag 'v20240424-a88484dfb' to 'v20240430-4359601d0' updates image k8s-prow/hook tag
  'v20240424-a88484dfb' to 'v20240430-4359601d0' updates image k8s-prow/horologium tag
  'v20240424-a88484dfb' to 'v20240430-4359601d0' updates image k8s-prow/needs-rebase tag
  'v20240424-a88484dfb' to 'v20240430-4359601d0' updates image k8s-prow/prow-controller-manager tag
  'v20240424-a88484dfb' to 'v20240430-4359601d0' updates image k8s-prow/sinker tag
  'v20240424-a88484dfb' to 'v20240430-4359601d0' updates image k8s-prow/status-reconciler tag
  'v20240424-a88484dfb' to 'v20240430-4359601d0' updates image k8s-prow/tide tag
  'v20240424-a88484dfb' to 'v20240430-4359601d0'

- Automatic update of prow
  ([`94a870d`](https://github.com/goern/op1st-emea-b4mad/commit/94a870d9afece7b115cd15aca757c3a6e6e133e0))

updates image k8s-prow/branchprotector tag 'v20240204-5365b6c1fa' to 'v20240424-a88484dfb' updates
  image k8s-prow/crier tag 'v20240204-5365b6c1fa' to 'v20240424-a88484dfb' updates image
  k8s-prow/deck tag 'v20240204-5365b6c1fa' to 'v20240424-a88484dfb' updates image k8s-prow/ghproxy
  tag 'v20240204-5365b6c1fa' to 'v20240424-a88484dfb' updates image k8s-prow/hook tag
  'v20240204-5365b6c1fa' to 'v20240424-a88484dfb' updates image k8s-prow/horologium tag
  'v20240204-5365b6c1fa' to 'v20240424-a88484dfb' updates image k8s-prow/needs-rebase tag
  'v20240204-5365b6c1fa' to 'v20240424-a88484dfb' updates image k8s-prow/prow-controller-manager tag
  'v20240204-5365b6c1fa' to 'v20240424-a88484dfb' updates image k8s-prow/sinker tag
  'v20240204-5365b6c1fa' to 'v20240424-a88484dfb' updates image k8s-prow/status-reconciler tag
  'v20240204-5365b6c1fa' to 'v20240424-a88484dfb' updates image k8s-prow/tide tag
  'v20240204-5365b6c1fa' to 'v20240424-a88484dfb'

- Automatic update of prow
  ([`bb7fc37`](https://github.com/goern/op1st-emea-b4mad/commit/bb7fc37a910b70452ffde3a58ff6b30568ce89c7))

updates image k8s-prow/branchprotector tag 'v20240122-814391aa21' to 'v20240204-5365b6c1fa' updates
  image k8s-prow/crier tag 'v20240122-814391aa21' to 'v20240204-5365b6c1fa' updates image
  k8s-prow/deck tag 'v20240122-814391aa21' to 'v20240204-5365b6c1fa' updates image k8s-prow/ghproxy
  tag 'v20240122-814391aa21' to 'v20240204-5365b6c1fa' updates image k8s-prow/hook tag
  'v20240109-ae9036acf5' to 'v20240204-5365b6c1fa' updates image k8s-prow/horologium tag
  'v20240122-814391aa21' to 'v20240204-5365b6c1fa' updates image k8s-prow/needs-rebase tag
  'v20240122-814391aa21' to 'v20240204-5365b6c1fa' updates image k8s-prow/prow-controller-manager
  tag 'v20240122-814391aa21' to 'v20240204-5365b6c1fa' updates image k8s-prow/sinker tag
  'v20240122-814391aa21' to 'v20240204-5365b6c1fa' updates image k8s-prow/status-reconciler tag
  'v20240122-814391aa21' to 'v20240204-5365b6c1fa' updates image k8s-prow/tide tag
  'v20240122-814391aa21' to 'v20240204-5365b6c1fa'

- Automatic update of prow
  ([`22c995f`](https://github.com/goern/op1st-emea-b4mad/commit/22c995f1a88d52b704e8fe98a18dd9c60261082f))

updates image k8s-prow/branchprotector tag 'v20240109-ae9036acf5' to 'v20240122-814391aa21' updates
  image k8s-prow/crier tag 'v20240109-ae9036acf5' to 'v20240122-814391aa21' updates image
  k8s-prow/deck tag 'v20240109-ae9036acf5' to 'v20240122-814391aa21' updates image k8s-prow/ghproxy
  tag 'v20240109-ae9036acf5' to 'v20240122-814391aa21' updates image k8s-prow/horologium tag
  'v20240109-ae9036acf5' to 'v20240122-814391aa21' updates image k8s-prow/needs-rebase tag
  'v20240109-ae9036acf5' to 'v20240122-814391aa21' updates image k8s-prow/prow-controller-manager
  tag 'v20240109-ae9036acf5' to 'v20240122-814391aa21' updates image k8s-prow/sinker tag
  'v20240109-ae9036acf5' to 'v20240122-814391aa21' updates image k8s-prow/status-reconciler tag
  'v20240109-ae9036acf5' to 'v20240122-814391aa21' updates image k8s-prow/tide tag
  'v20240109-ae9036acf5' to 'v20240122-814391aa21'

- Update cert-manager to v1.13
  ([`a4ecd77`](https://github.com/goern/op1st-emea-b4mad/commit/a4ecd775ef536049611b1b758daee661df037c96))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- Automatic update of prow
  ([`12a7ccb`](https://github.com/goern/op1st-emea-b4mad/commit/12a7ccb86bc0cf86d6178cd17a31e8a6c8afc498))

updates image k8s-prow/branchprotector tag 'v20231219-d8851a0c8e' to 'v20240109-ae9036acf5' updates
  image k8s-prow/crier tag 'v20231219-d8851a0c8e' to 'v20240109-ae9036acf5' updates image
  k8s-prow/deck tag 'v20231219-d8851a0c8e' to 'v20240109-ae9036acf5' updates image k8s-prow/ghproxy
  tag 'v20231219-d8851a0c8e' to 'v20240109-ae9036acf5' updates image k8s-prow/hook tag
  'v20231219-d8851a0c8e' to 'v20240109-ae9036acf5' updates image k8s-prow/horologium tag
  'v20231219-d8851a0c8e' to 'v20240109-ae9036acf5' updates image k8s-prow/needs-rebase tag
  'v20231219-d8851a0c8e' to 'v20240109-ae9036acf5' updates image k8s-prow/prow-controller-manager
  tag 'v20231219-d8851a0c8e' to 'v20240109-ae9036acf5' updates image k8s-prow/sinker tag
  'v20231219-d8851a0c8e' to 'v20240109-ae9036acf5' updates image k8s-prow/status-reconciler tag
  'v20231219-d8851a0c8e' to 'v20240109-ae9036acf5' updates image k8s-prow/tide tag
  'v20231219-d8851a0c8e' to 'v20240109-ae9036acf5'

- Automatic update of prow
  ([`0f75849`](https://github.com/goern/op1st-emea-b4mad/commit/0f7584963a1b88789f49143122b5c18ed2166e19))

updates image k8s-prow/branchprotector tag 'v20231127-6bd5ce71de' to 'v20231219-d8851a0c8e' updates
  image k8s-prow/crier tag 'v20231127-6bd5ce71de' to 'v20231219-d8851a0c8e' updates image
  k8s-prow/deck tag 'v20231127-6bd5ce71de' to 'v20231219-d8851a0c8e' updates image k8s-prow/ghproxy
  tag 'v20231127-6bd5ce71de' to 'v20231219-d8851a0c8e' updates image k8s-prow/hook tag
  'v20231127-6bd5ce71de' to 'v20231219-d8851a0c8e' updates image k8s-prow/horologium tag
  'v20231127-6bd5ce71de' to 'v20231219-d8851a0c8e' updates image k8s-prow/needs-rebase tag
  'v20231127-6bd5ce71de' to 'v20231219-d8851a0c8e' updates image k8s-prow/prow-controller-manager
  tag 'v20231127-6bd5ce71de' to 'v20231219-d8851a0c8e' updates image k8s-prow/sinker tag
  'v20231127-6bd5ce71de' to 'v20231219-d8851a0c8e' updates image k8s-prow/status-reconciler tag
  'v20231127-6bd5ce71de' to 'v20231219-d8851a0c8e' updates image k8s-prow/tide tag
  'v20231127-6bd5ce71de' to 'v20231219-d8851a0c8e'

- Update commitizen pre-commit hook
  ([`fe629c1`](https://github.com/goern/op1st-emea-b4mad/commit/fe629c11e7b77341cbf4558104855568c1ba371f))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- Automatic update of prow
  ([`2510367`](https://github.com/goern/op1st-emea-b4mad/commit/2510367a5cc64411dc62a1bdd3a32359a9a1419a))

updates image k8s-prow/branchprotector tag 'v20231103-74dcf8db5c' to 'v20231127-6bd5ce71de' updates
  image k8s-prow/crier tag 'v20231114-9e6076d23d' to 'v20231127-6bd5ce71de' updates image
  k8s-prow/deck tag 'v20231114-9e6076d23d' to 'v20231127-6bd5ce71de' updates image k8s-prow/ghproxy
  tag 'v20231114-9e6076d23d' to 'v20231127-6bd5ce71de' updates image k8s-prow/hook tag
  'v20231114-9e6076d23d' to 'v20231127-6bd5ce71de' updates image k8s-prow/horologium tag
  'v20231114-9e6076d23d' to 'v20231127-6bd5ce71de' updates image k8s-prow/needs-rebase tag
  'v20231114-9e6076d23d' to 'v20231127-6bd5ce71de' updates image k8s-prow/prow-controller-manager
  tag 'v20231114-9e6076d23d' to 'v20231127-6bd5ce71de' updates image k8s-prow/sinker tag
  'v20231114-9e6076d23d' to 'v20231127-6bd5ce71de' updates image k8s-prow/status-reconciler tag
  'v20231114-9e6076d23d' to 'v20231127-6bd5ce71de' updates image k8s-prow/tide tag
  'v20231114-9e6076d23d' to 'v20231127-6bd5ce71de'

- Automatic update of prow
  ([`aee775d`](https://github.com/goern/op1st-emea-b4mad/commit/aee775d6ae99739334a1063deebc0f4ae963d0b7))

updates image k8s-prow/crier tag 'v20231103-74dcf8db5c' to 'v20231114-9e6076d23d' updates image
  k8s-prow/deck tag 'v20231103-74dcf8db5c' to 'v20231114-9e6076d23d' updates image k8s-prow/ghproxy
  tag 'v20231103-74dcf8db5c' to 'v20231114-9e6076d23d' updates image k8s-prow/hook tag
  'v20231103-74dcf8db5c' to 'v20231114-9e6076d23d' updates image k8s-prow/horologium tag
  'v20231103-74dcf8db5c' to 'v20231114-9e6076d23d' updates image k8s-prow/needs-rebase tag
  'v20231103-74dcf8db5c' to 'v20231114-9e6076d23d' updates image k8s-prow/prow-controller-manager
  tag 'v20231103-74dcf8db5c' to 'v20231114-9e6076d23d' updates image k8s-prow/sinker tag
  'v20231103-74dcf8db5c' to 'v20231114-9e6076d23d' updates image k8s-prow/status-reconciler tag
  'v20231103-74dcf8db5c' to 'v20231114-9e6076d23d' updates image k8s-prow/tide tag
  'v20231103-74dcf8db5c' to 'v20231114-9e6076d23d'

- Automatic update of prow
  ([`541f73b`](https://github.com/goern/op1st-emea-b4mad/commit/541f73bb0c3d134a30396b618036f33126ddd450))

updates image k8s-prow/branchprotector tag 'v20231101-174189c793' to 'v20231103-74dcf8db5c' updates
  image k8s-prow/crier tag 'v20231101-174189c793' to 'v20231103-74dcf8db5c' updates image
  k8s-prow/deck tag 'v20231027-9cda73bb73' to 'v20231103-74dcf8db5c' updates image k8s-prow/ghproxy
  tag 'v20231101-174189c793' to 'v20231103-74dcf8db5c' updates image k8s-prow/hook tag
  'v20231101-174189c793' to 'v20231103-74dcf8db5c' updates image k8s-prow/horologium tag
  'v20231101-174189c793' to 'v20231103-74dcf8db5c' updates image k8s-prow/needs-rebase tag
  'v20231101-174189c793' to 'v20231103-74dcf8db5c' updates image k8s-prow/prow-controller-manager
  tag 'v20231101-174189c793' to 'v20231103-74dcf8db5c' updates image k8s-prow/sinker tag
  'v20231101-174189c793' to 'v20231103-74dcf8db5c' updates image k8s-prow/status-reconciler tag
  'v20231101-174189c793' to 'v20231103-74dcf8db5c' updates image k8s-prow/tide tag
  'v20231101-174189c793' to 'v20231103-74dcf8db5c'

### Chores

- Add cgr.dev/chainguard/git to allowed repositories for op1st projects
  ([`1ee5488`](https://github.com/goern/op1st-emea-b4mad/commit/1ee54889c372eb71c9a11d1e6b829194f5a053cf))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- Add new manifest to gitleaks ignore list
  ([`e90358b`](https://github.com/goern/op1st-emea-b4mad/commit/e90358bee0f17b8908cf3d077c76ef2d11d25f29))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- Add schwesig
  ([`6da3d17`](https://github.com/goern/op1st-emea-b4mad/commit/6da3d17abdd95e787588bd36a423fc4cf793f4d1))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- Unify identity provider names
  ([`ae98831`](https://github.com/goern/op1st-emea-b4mad/commit/ae9883163485badd8a37025905c4526500e24efb))

- Update gitleaks config
  ([`b39ecdc`](https://github.com/goern/op1st-emea-b4mad/commit/b39ecdceb19f235ab3da4e420784c40e5577b603))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- **nostromo**: Allow gcr.io/k8s-staging-kustomize/kustomize repository
  ([`bf32f31`](https://github.com/goern/op1st-emea-b4mad/commit/bf32f311c8ee5457dfc446e9d8807c9976056edf))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- **nostromo**: Cycle openshift-pipelines pipeline as code secrets
  ([`cf8ed67`](https://github.com/goern/op1st-emea-b4mad/commit/cf8ed6742d23a49e5ef405a595ed64b68c6d046b))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- **b4mad-matrix**: Reconfigured the schedule of the backups
  ([`532ece2`](https://github.com/goern/op1st-emea-b4mad/commit/532ece25647b833682f4762810a7c6641111778f))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- Cleanup cnpg images
  ([`2313e04`](https://github.com/goern/op1st-emea-b4mad/commit/2313e047ca0e7df154a069976437166b8059f5a8))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- Cleanup cnpg images
  ([`6bc41bb`](https://github.com/goern/op1st-emea-b4mad/commit/6bc41bbf26852754ce41596ff0e5bf10462e6984))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- Cleanup cnpg images
  ([`d1df1c4`](https://github.com/goern/op1st-emea-b4mad/commit/d1df1c4ac02328a083000ada187280cd3d6b25c8))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- **op1st-prow**: Update container image tags
  ([`00a1458`](https://github.com/goern/op1st-emea-b4mad/commit/00a1458346409db4fc034f01f0bbb53e08645398))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- **op1st-prow**: Cycle s3 credentials
  ([`fcd7346`](https://github.com/goern/op1st-emea-b4mad/commit/fcd73467864437dba4ca43d58e7cd1e91ebcb46f))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- **op1st-gitops**: Reduce resource consumption of argocd deployment
  ([`8b4e836`](https://github.com/goern/op1st-emea-b4mad/commit/8b4e836b0380400a4e8416ba276742a80ab12da4))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- **openshift-gitops**: Reduce resource consumption of argocd deployment
  ([`f903a3c`](https://github.com/goern/op1st-emea-b4mad/commit/f903a3c21e3027aa09d995d6a114da79cd9f31c0))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- **op1st-gitops**: Reduce resource consumption of argocd deployment
  ([`e8e4a40`](https://github.com/goern/op1st-emea-b4mad/commit/e8e4a40f000a7a34badfd27df518329875192e9b))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- **op1st-gitops**: Reduce resource consumption of argocd deployment
  ([`4a14459`](https://github.com/goern/op1st-emea-b4mad/commit/4a14459892a0be89239bfa2d023eef36aaf437f6))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- **openshift-gitops**: Reduce resource consumption of argocd deployment
  ([`a049e60`](https://github.com/goern/op1st-emea-b4mad/commit/a049e603f644954b42a510b1424797daab22c024))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- **op1st-gitops**: Reduce resource consumption of argocd deployment
  ([`163871a`](https://github.com/goern/op1st-emea-b4mad/commit/163871a0d09f9342e7addb600ac9e06106af088d))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- Add required namespace annotations and labels
  ([`ac7a491`](https://github.com/goern/op1st-emea-b4mad/commit/ac7a4915afa0c269eebce262451d99b0aae41930))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- Clean up unused crunchy manifest
  ([`a8e52d8`](https://github.com/goern/op1st-emea-b4mad/commit/a8e52d8ddc47af3d413367d75e71dfdb98ddd4ee))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- **nostromo**: Update keycloak operator
  ([`92ae5be`](https://github.com/goern/op1st-emea-b4mad/commit/92ae5bea8b3ef814d1be38a6b78d633e7171c631))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- **nostromo**: Re-encrypt
  ([`34528fa`](https://github.com/goern/op1st-emea-b4mad/commit/34528fa99f1121504ade0822404cffb17372b156))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- **nostromo**: Re-encrypt
  ([`cb985e8`](https://github.com/goern/op1st-emea-b4mad/commit/cb985e8b594431f3725982d765b5380837b99b02))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- **prow**: Update container images
  ([`02d54ab`](https://github.com/goern/op1st-emea-b4mad/commit/02d54abb2610cc5f2829b5167e1bfcdf909c2078))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- **sealed-secrets**: Update to 0.27
  ([`364a262`](https://github.com/goern/op1st-emea-b4mad/commit/364a2621f98c18f74884577807365a654a58c63b))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- **strimzi**: Update to 0.43
  ([`073b888`](https://github.com/goern/op1st-emea-b4mad/commit/073b8880577ab1beaf981a967673d317297a60a1))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- **prow**: Increased memory limit
  ([`5d14f42`](https://github.com/goern/op1st-emea-b4mad/commit/5d14f424896ba9000c446cdc8469e9a7d1268021))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- **gatekeeper**: Add prow container images repositories to the allow list
  ([`dff652b`](https://github.com/goern/op1st-emea-b4mad/commit/dff652bdaf3a3c4342323a155efc379728c1afb5))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- **prow**: Update container images
  ([`1428701`](https://github.com/goern/op1st-emea-b4mad/commit/142870168a5f7be9a2911197347c34b8f2450b74))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- Add quay.io/thoth-station to allowed repos of op1st
  ([`d1e2afd`](https://github.com/goern/op1st-emea-b4mad/commit/d1e2afd47fa89028366e0c8b30f4eb76ae2328c5))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- **nostromo**: Cycle cluster token secret
  ([`b8dc873`](https://github.com/goern/op1st-emea-b4mad/commit/b8dc873b072fb9abb2956be5ca138859da47548f))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- **nostromo**: Cycle cluster token secret
  ([`6f9b390`](https://github.com/goern/op1st-emea-b4mad/commit/6f9b3901b19aa359e25d18d3643c71c058a97e48))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- Cycle keycloak client secrets
  ([`b64b32b`](https://github.com/goern/op1st-emea-b4mad/commit/b64b32bad044af8b39a791958438087e60087795))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- **pgo**: Cycle cpk registration secret
  ([`25a8320`](https://github.com/goern/op1st-emea-b4mad/commit/25a83209fe6bb824a14aa63044ce99c85a11f6ec))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- Update all the prow images
  ([`6fcfe1d`](https://github.com/goern/op1st-emea-b4mad/commit/6fcfe1d9caecd943abc3edc390fdf40c631e411a))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- Update readme to have to correct radicle url
  ([`680d9e1`](https://github.com/goern/op1st-emea-b4mad/commit/680d9e1a616ab795912057ee769b2a3a8fd003f8))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- Oauth client secret rotation
  ([`542a6cd`](https://github.com/goern/op1st-emea-b4mad/commit/542a6cdbcccd0b1cabd9606767f04392608d7f76))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- **lvms**: Update to 0.16
  ([`0bb85a8`](https://github.com/goern/op1st-emea-b4mad/commit/0bb85a89cd187a73ef660b9a967ee64f53084072))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- **strimzi**: Update to 0.42
  ([`8dc76c5`](https://github.com/goern/op1st-emea-b4mad/commit/8dc76c55b03dd6f1faecce7c8a14e51427f16629))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- Re-encrypted codeberg op1st-gitops user secrets
  ([`29d7975`](https://github.com/goern/op1st-emea-b4mad/commit/29d79754d8164946a875dd11fc119ae489f5d731))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- Re-encrypted codeberg op1st-gitops user secrets
  ([`742d99b`](https://github.com/goern/op1st-emea-b4mad/commit/742d99be4da5f584c4a7e549d407e34d708c8d00))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- **alertmanager**: Update PAT for github receiver
  ([`e5d934d`](https://github.com/goern/op1st-emea-b4mad/commit/e5d934da9f91d0aea1ea3bc79829be4c01a134b6))

Signed-off-by: Christoph Görn <goern@b4mad.net>

### Continuous Integration

- Pipeline trigger
  ([`d202078`](https://github.com/goern/op1st-emea-b4mad/commit/d2020780ac5941b7d98fd7a6f591e6abaa6f7cb1))

- Pipeline trigger
  ([`ad4311f`](https://github.com/goern/op1st-emea-b4mad/commit/ad4311f5ad2b5f9d33c8346ce188a7eb1a9d28d3))

- Pipeline trigger
  ([`8f2cf85`](https://github.com/goern/op1st-emea-b4mad/commit/8f2cf855fda8acde83b6dc9d980c535a1e8ee32e))

- Pipeline trigger
  ([`f3e6fd6`](https://github.com/goern/op1st-emea-b4mad/commit/f3e6fd63e443d5e90f8247933952b5891adacc6d))

- Pipeline trigger
  ([`17a47a0`](https://github.com/goern/op1st-emea-b4mad/commit/17a47a0ee4619104e4f903680e1c2c78f204d203))

### Features

- **nostromo**: Add tekton-results deployment to openshift-pipelines
  ([`2eb06f7`](https://github.com/goern/op1st-emea-b4mad/commit/2eb06f746941dea7eba5e7bb4b5c54d3650af131))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- **nostromo**: Add tekton-results deployment to openshift-pipelines
  ([`2087fb8`](https://github.com/goern/op1st-emea-b4mad/commit/2087fb8f8128aba42973f4001a2f19ad88d8098b))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- **nostromo**: Add tekton-results deployment to openshift-pipelines
  ([`63d656d`](https://github.com/goern/op1st-emea-b4mad/commit/63d656d377c7cf18a22809b0614811d5ccbfd897))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- **nostromo**: Add tekton-results deployment to openshift-pipelines
  ([`40d7ab4`](https://github.com/goern/op1st-emea-b4mad/commit/40d7ab4f4c8f9363112a4999eae940cc47048fef))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- **nostromo**: Add tekton-results deployment to openshift-pipelines
  ([`bf49233`](https://github.com/goern/op1st-emea-b4mad/commit/bf49233f14826f935459a1f83b3024e9d52bf33a))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- Update keycloak to 26.0.6, update keycloak to use digest rather than tag, update keycloak to use
  image from codeberg.org registry
  ([`d7cdefb`](https://github.com/goern/op1st-emea-b4mad/commit/d7cdefb3489eea7f0dcdccf66c178031cb612ec1))

- **org**: Update b4mad organizational stuff
  ([`f87fadb`](https://github.com/goern/op1st-emea-b4mad/commit/f87fadb6246b8694a4eff94e7f55c7a4860c6968))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- **sealed-secrets**: Update Bitname Sealed Secret Controller to 0.27.2
  ([`cb2561c`](https://github.com/goern/op1st-emea-b4mad/commit/cb2561c1075802cc930405263361f61fcc81976c))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- **op1st-gitops**: Disable feeldata-stage
  ([`9d8434f`](https://github.com/goern/op1st-emea-b4mad/commit/9d8434f0f0d6391a0b8864f79ea03a2557d3bef8))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- **op1st-gitops**: Enable feeldata-stage deployment
  ([`def4782`](https://github.com/goern/op1st-emea-b4mad/commit/def478264fe127cd9d85ef836c910c65ea108380))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- **op1st-pipelines**: Enable chains
  ([`fc37182`](https://github.com/goern/op1st-emea-b4mad/commit/fc3718255eaad452eac7a9086b8415102a5a097b))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- **op1st-pipelines**: Enable chains
  ([`2f43c46`](https://github.com/goern/op1st-emea-b4mad/commit/2f43c465d9881146d638c9ba5839359e5ab607d2))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- **op1st-pipelines**: Enable tekton repository creation via op1st-gitops
  ([`40a1b3a`](https://github.com/goern/op1st-emea-b4mad/commit/40a1b3af229cade8515278b4639d245cbcc5eda8))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- Add a 'kustomize build' validation pipeline
  ([`1d679f0`](https://github.com/goern/op1st-emea-b4mad/commit/1d679f08c5a0e522cb11cdf5ebfbf3dd070959fc))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- **nostromo**: Remove old and unused minio manifests
  ([`055ae2b`](https://github.com/goern/op1st-emea-b4mad/commit/055ae2b3121351732af6ac9f9b6a2019022b5bbf))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- **nostromo**: Allow ghcr.io/gitleaks/gitleaks container images for op1st projects
  ([`2958e18`](https://github.com/goern/op1st-emea-b4mad/commit/2958e183ff943d681681476f7e1233a73afaccfd))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- **nostromo**: Allow samples.operator.openshift.io to manage 'samples.operator.openshift.io'
  resources
  ([`40d59ee`](https://github.com/goern/op1st-emea-b4mad/commit/40d59eee9838aa4bf17977e52f938005cee80b19))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- **nostromo**: Remove the samples operator
  ([`b11089e`](https://github.com/goern/op1st-emea-b4mad/commit/b11089e7267bfac2faaa854dedeb7f8f7f26ca9c))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- Add tekton result service
  ([`4d9643c`](https://github.com/goern/op1st-emea-b4mad/commit/4d9643c87bae721a75847a6599d1967405a79bed))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- Add tekton result service
  ([`4f13bc0`](https://github.com/goern/op1st-emea-b4mad/commit/4f13bc0f157b9a46fefc49df4d42aeb11ef92aeb))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- Add tekton result service
  ([`4d4ea82`](https://github.com/goern/op1st-emea-b4mad/commit/4d4ea82d5c1a71e4efdee113567c1bebbf2e1dbf))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- Add tekton result service
  ([`e5f2550`](https://github.com/goern/op1st-emea-b4mad/commit/e5f255058e54ccd777909fee7f9e780d858ccfcc))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- **nostromo**: Tiny performance tweeks
  ([`1461edb`](https://github.com/goern/op1st-emea-b4mad/commit/1461edb2e64c8fe8c1141ee952fe37a2c0e495fa))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- **b4mad-keycloak**: Update to 26.0.5
  ([`5c8f8a5`](https://github.com/goern/op1st-emea-b4mad/commit/5c8f8a56302ad1e6751176fe4f9822111192c177))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- **gatekeeper**: Add quay.io/sclorg/python-311-c9s to the allow list of images repos for op1st-*
  projects
  ([`b972357`](https://github.com/goern/op1st-emea-b4mad/commit/b97235751f63736db14d1a84a1406cc8d4ec656a))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- Enabling b4mad-racing applications
  ([`63bdb88`](https://github.com/goern/op1st-emea-b4mad/commit/63bdb88b8c442a236587e5e3712bbe3317e6511b))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- Disable feeldata-stage and b4mad-racing applications
  ([`7fd4c05`](https://github.com/goern/op1st-emea-b4mad/commit/7fd4c051a34954fdfc7b39c514835e32722e9ec1))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- **nostromo**: Remove cluster-resource-override from cluster
  ([`c66f239`](https://github.com/goern/op1st-emea-b4mad/commit/c66f239ed5291729609027b2f966828c7ee5abf2))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- Limit keycloak resources
  ([`c40a87b`](https://github.com/goern/op1st-emea-b4mad/commit/c40a87b2f28996050ac75e4805f1b5319051891f))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- Limit keycloak resources
  ([`bc98c8b`](https://github.com/goern/op1st-emea-b4mad/commit/bc98c8b63089c744b763335268d5e8ac888bb746))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- Limit keycloak resources
  ([`9f010d3`](https://github.com/goern/op1st-emea-b4mad/commit/9f010d3193d335878853d09da1cfb7bc3bc1e39e))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- Limit keycloak resources
  ([`2ed5865`](https://github.com/goern/op1st-emea-b4mad/commit/2ed586560e606d2817b2a98be95783afbb4c04e6))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- Update to Red Hat OpenShift Pipelines 1.16
  ([`d36c377`](https://github.com/goern/op1st-emea-b4mad/commit/d36c3772f3b509a32b4971fb3d0a736123d79522))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- **cert-manager**: Enable b4mad.industries
  ([`c4c89e9`](https://github.com/goern/op1st-emea-b4mad/commit/c4c89e90a06088fe29e5e8430bf5538b50993291))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- Add dendrite and syncv3 applications, to implement b4mad-matrix service
  ([`a99d45b`](https://github.com/goern/op1st-emea-b4mad/commit/a99d45b3003fdd87e5cf1a3ccd4d841ee381e49b))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- Add dendrite application
  ([`c75201a`](https://github.com/goern/op1st-emea-b4mad/commit/c75201ac62b582c76d55a9a1b57e70ac049ce477))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- Add dendrite application
  ([`d41b0b6`](https://github.com/goern/op1st-emea-b4mad/commit/d41b0b6181cd222bef4ab45f78aea5ba5857abd0))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- Add dendrite application
  ([`77eb05d`](https://github.com/goern/op1st-emea-b4mad/commit/77eb05d5985147d1a122e6d3080637beabfa844b))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- **nostromo**: Remove crunchy-postgresql oprator
  ([`0d1f365`](https://github.com/goern/op1st-emea-b4mad/commit/0d1f365c3b134e70b9782d072cde6938819b63c8))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- **keycloak**: Cleanup of postgres
  ([`e6cb993`](https://github.com/goern/op1st-emea-b4mad/commit/e6cb9935a363ce74425157e1603070d5525d567f))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- **keycloak**: Use a custom image including the hash-B4mad-op1st Keycloak theme
  ([`585acae`](https://github.com/goern/op1st-emea-b4mad/commit/585acae457b9b79f27d09aef054d21dee857fc09))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- **keycloak**: Use a custom image including the hash-B4mad-op1st Keycloak theme
  ([`12dcdf8`](https://github.com/goern/op1st-emea-b4mad/commit/12dcdf824759646eb8d27f7e553314e9fc0618a8))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- **nostromo**: Enable over commitment for -gitops projects
  ([`03a3582`](https://github.com/goern/op1st-emea-b4mad/commit/03a3582a7dc9b2432cb2466faf26a0a67c7a7ad3))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- **nostromo**: Enable cgroups v2
  ([`c8c9f25`](https://github.com/goern/op1st-emea-b4mad/commit/c8c9f2514b0ebf212311e639f61a8dcb554e1b06))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- **nostromo**: Configure the Cluster Resource Override Operator
  ([`8fe96d7`](https://github.com/goern/op1st-emea-b4mad/commit/8fe96d79f9270f27ac3e22b7dfb36c704162e670))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- **nostromo**: Add Cluster Resource Override Operator
  ([`c817138`](https://github.com/goern/op1st-emea-b4mad/commit/c817138f0e4a932d38e6efe32860a1406042b53f))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- **nostromo**: Add admin kubeconfig
  ([`2f309f3`](https://github.com/goern/op1st-emea-b4mad/commit/2f309f345a5ac3f015ed46ace0718ed73fabe53f))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- **nostromo**: Remove Strimzi Operator
  ([`8a19370`](https://github.com/goern/op1st-emea-b4mad/commit/8a19370ff022ff35deab20922380ef1aea1ddf0d))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- **prow**: Add resource quota and limit ranges
  ([`ccef9aa`](https://github.com/goern/op1st-emea-b4mad/commit/ccef9aa65afcb07719cb8912e4fae374f9237bfe))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- **nostromo**: Add Popeye scans to be run on nostromo, output to pod stdout
  ([`af18fc8`](https://github.com/goern/op1st-emea-b4mad/commit/af18fc8bfb10213cfa5f1a703b5345afe16dfc53))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- **nostromo**: Add Popeye scans to be run on nostromo, output to pod stdout
  ([`b0b75db`](https://github.com/goern/op1st-emea-b4mad/commit/b0b75db0a3ee9d01047f1aa2885eacc891c69dc1))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- Customizing the login page, NOOO ;)
  ([`03673e1`](https://github.com/goern/op1st-emea-b4mad/commit/03673e12132fb09af14e572dcfabe71f97278d16))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- Customizing the login page ;)
  ([`6f5caf2`](https://github.com/goern/op1st-emea-b4mad/commit/6f5caf2120ab7ea5126750018947989bf0809652))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- Customizing the login page ;)
  ([`0fd2918`](https://github.com/goern/op1st-emea-b4mad/commit/0fd29181f9a827245b737c16f8ee666ab99c970c))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- Customizing the login page ;)
  ([`b449c38`](https://github.com/goern/op1st-emea-b4mad/commit/b449c38aa1ea790d2bcc682adf82b48e21fa6038))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- **gatekeeper**: Add quay.io/community-operator-pipeline-prod/authorino-operator to the allow list
  of images repos
  ([`ccce1ae`](https://github.com/goern/op1st-emea-b4mad/commit/ccce1ae078e97a8936eb8f44aac83c99fb050f54))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- **gatekeeper**: Add quay.io/buildah/stable to allowed repositories for op1st-pipelines
  ([`741e1a5`](https://github.com/goern/op1st-emea-b4mad/commit/741e1a53be6bca1c0bdfeffa344d03921b1b643c))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- **gatekeeper**: Add gcr.io/tekton-releases to allowed repositories for op1st-pipelines
  ([`aa8a7de`](https://github.com/goern/op1st-emea-b4mad/commit/aa8a7de2f797d657fb0c8be1abb9fbd48a871456))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- **feeldata**: Add a production-level deployment
  ([`cd5ce99`](https://github.com/goern/op1st-emea-b4mad/commit/cd5ce99e37f99e762e4448c379cc473402ebf023))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- **nostromo**: Add a podmonitor to the cnpg operator
  ([`28094fc`](https://github.com/goern/op1st-emea-b4mad/commit/28094fcf95be23ee1835155c8674bebb4844c55c))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- **nostromo**: Add more gatekeeper constraints
  ([`b1ef1b4`](https://github.com/goern/op1st-emea-b4mad/commit/b1ef1b4617535665247bb1d5756f646c5c4eed28))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- **nostromo**: Add more gatekeeper constraints
  ([`f87556d`](https://github.com/goern/op1st-emea-b4mad/commit/f87556d2bd970a0d9c9af0993fed5796eb9b9fcb))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- **nostromo**: Add cloudnative-pg operator
  ([`935b636`](https://github.com/goern/op1st-emea-b4mad/commit/935b636671ea44dca7f4bb1e4da9000c2dd1723b))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- **nostromo**: Add opa-gatekeeper application to openshift-gitops
  ([`9e8823d`](https://github.com/goern/op1st-emea-b4mad/commit/9e8823d9361db7bab773bd8763e6072314f8e2f3))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- **nostromo**: Add open-policy-agent gatekeeper
  ([`d00cdfb`](https://github.com/goern/op1st-emea-b4mad/commit/d00cdfb6ac7975cda30afaf8d01e912add1e9db7))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- Grant more cluster admin permissions to
  system:serviceaccount:openshift-gitops:openshift-gitops-argocd-application-controller
  ([`93498dc`](https://github.com/goern/op1st-emea-b4mad/commit/93498dc213b8f06cf66b37e4e451f618b5669ebf))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- Add b4mad-radicle as a hosted application
  ([`26e1b20`](https://github.com/goern/op1st-emea-b4mad/commit/26e1b20e5cf4b5fc35cbc5cc0ca94f6e4a0c0fef))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- **keycloak**: Enable metrics and health
  ([`0e2dd73`](https://github.com/goern/op1st-emea-b4mad/commit/0e2dd739bfaf25267951eb9c7b30a4c87fe64a52))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- **b4mad**: Add erdgeschoss keycloak deployment
  ([`9b3242f`](https://github.com/goern/op1st-emea-b4mad/commit/9b3242f6537cf910abac6992aa63265e6f50cc78))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- **b4mad**: Add keycloak operator to nostromo environment
  ([`288dd27`](https://github.com/goern/op1st-emea-b4mad/commit/288dd2721378332b44cebdecfd8b0cf1d5018d12))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- **nostromo**: Reconfigure idp/oauth to use keycloak
  ([`d4132ec`](https://github.com/goern/op1st-emea-b4mad/commit/d4132ecd936fd9b58853b9ea76bd7990e28f94d2))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- **b4mad**: Add keycloak operator to nostromo environment
  ([`ad623da`](https://github.com/goern/op1st-emea-b4mad/commit/ad623da6b2f03c67e640142dd8306ca9734252aa))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- Add gitleaks as a pre-commit hook
  ([`3657da5`](https://github.com/goern/op1st-emea-b4mad/commit/3657da5acbc95c47bf7ae9c02858d8ab1ba759ca))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- **pgo**: Add cpk registration secret
  ([`5c5cd05`](https://github.com/goern/op1st-emea-b4mad/commit/5c5cd05ee0fdcf34a9fe2aba7370264dd5dc65a9))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- **pipelines**: Upgrade to 1.15
  ([`95319cd`](https://github.com/goern/op1st-emea-b4mad/commit/95319cd19026755f6ec3a68d97f451e7b0f498c0))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- **gitops**: Upgrade to 1.13
  ([`09ebb53`](https://github.com/goern/op1st-emea-b4mad/commit/09ebb5304aa67eb9296b7bde031ae6021d1435c6))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- Upgrade to 4.16
  ([`d4f0111`](https://github.com/goern/op1st-emea-b4mad/commit/d4f0111ec3e110e602201fa07bffa8c0033a4030))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- Resized registry and alertmanager PVC
  ([`d7d08b7`](https://github.com/goern/op1st-emea-b4mad/commit/d7d08b7c0cfd82a048fa8d0506603729aad6d61f))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- Ack upgrade to 4.16
  ([`71d5bff`](https://github.com/goern/op1st-emea-b4mad/commit/71d5bff52bb34bc3ec260c690c62fd520e7d2f29))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- Add cloudnative postgresql operator
  ([`1dee672`](https://github.com/goern/op1st-emea-b4mad/commit/1dee67219e32891d2ca8a3feb4fd9eb5218aab66))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- Add repo to radicle
  ([`bc6832d`](https://github.com/goern/op1st-emea-b4mad/commit/bc6832ddc43db55a1b1448277fd97351aa0846ec))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- Add Op1st GitOps service to ApplicationMenu
  ([`5b01427`](https://github.com/goern/op1st-emea-b4mad/commit/5b01427f6c1a48afa92efb3d257f159665f09d31))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- Add gpg key verification to feeldata project
  ([`02ee73a`](https://github.com/goern/op1st-emea-b4mad/commit/02ee73a05fe675a50d44959157e952afceaec8ed))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- Add gpg key to op1st-gitops
  ([`aaf952c`](https://github.com/goern/op1st-emea-b4mad/commit/aaf952c1099b5eb0f05dffc89190b8c0ea53d40f))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- Custom certs for api-server
  ([`800e547`](https://github.com/goern/op1st-emea-b4mad/commit/800e547e9281798bb56c92c2cdfb57de41e2c342))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- Update SNO optimized configuration
  ([`f86520d`](https://github.com/goern/op1st-emea-b4mad/commit/f86520dfca549a4db13be49ce0b1bae1155515d8))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- Update sealed-secrets to v0.26.2
  ([`86f50a0`](https://github.com/goern/op1st-emea-b4mad/commit/86f50a040c1f364437be210d50dae5f2f90e9b84))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- Adding Authorino Operator component
  ([`ac25275`](https://github.com/goern/op1st-emea-b4mad/commit/ac252756239f51e74bd7c66420f1221265ac37d5))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- Update strimzi and gitops operators
  ([`ca1d12a`](https://github.com/goern/op1st-emea-b4mad/commit/ca1d12a86506acab2874d452dee2369fbbc65e46))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- Update openshift pipelines to v1.14
  ([`b299773`](https://github.com/goern/op1st-emea-b4mad/commit/b2997737cc1e4784e1256420089bac685a1a0e95))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- Update cluster channel v4.15
  ([`7f7e277`](https://github.com/goern/op1st-emea-b4mad/commit/7f7e277024ae118ff23163a792929065e9ab3de6))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- Update lvms-operator subscription to v4.15
  ([`533d93c`](https://github.com/goern/op1st-emea-b4mad/commit/533d93c1b2b7151170d13157a4681a65dc0f4add))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- Increase number of open file descriptors, see https://access.redhat.com/solutions/6974793 again ;)
  ([`c8db8b3`](https://github.com/goern/op1st-emea-b4mad/commit/c8db8b3586c59d761635065ac890474c4f67686a))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- Do not set ulimit via MCO
  ([`f92d8b9`](https://github.com/goern/op1st-emea-b4mad/commit/f92d8b9902a6f5127474d12b8e142c3398a61ca0))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- Increase number of open file descriptors, see https://access.redhat.com/solutions/6974793
  ([`9115fc0`](https://github.com/goern/op1st-emea-b4mad/commit/9115fc072196078ced0e34e297b6a1aca7f5699a))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- Remove all the resource requests of prow components
  ([`d3d8f38`](https://github.com/goern/op1st-emea-b4mad/commit/d3d8f3828df6078913bc7b15cf64aac110f3eb03))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- Some SNO optimizations
  ([`884ff72`](https://github.com/goern/op1st-emea-b4mad/commit/884ff7201b05bf4fccb9f9dcd6b350d6f3307f58))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- Add some goern project to argocd
  ([`3f5ccc2`](https://github.com/goern/op1st-emea-b4mad/commit/3f5ccc24a21311067ccf52d30fe2abbc2d10e535))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- Subscript to cert-manager v1
  ([`f64344f`](https://github.com/goern/op1st-emea-b4mad/commit/f64344f5788f98d67cf96c9d38138e448f061c43))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- Decoupled local-storage from redhat-cop/gitops-catalog, cleanup of nmstate argocd app (now its a
  component)
  ([`168ca2d`](https://github.com/goern/op1st-emea-b4mad/commit/168ca2d764946535bc13029955b96f6c70fd0fe0))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- Decoupled local-storage from redhat-cop/gitops-catalog
  ([`c91ef93`](https://github.com/goern/op1st-emea-b4mad/commit/c91ef93d40c52cf0da65a72a05a81fe01ef60c73))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- Decoupled NFD from redhat-cop/gitops-catalog
  ([`87065cf`](https://github.com/goern/op1st-emea-b4mad/commit/87065cf92ee4a6fbda433c4566d9ad5c0f9803a1))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- Add feeldata.app to cert-manager
  ([`2271bd5`](https://github.com/goern/op1st-emea-b4mad/commit/2271bd59baec7cbfab70c8e2dcaf5f77dc206a53))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- Update lvms-operator subscription to v4.14
  ([`b30419e`](https://github.com/goern/op1st-emea-b4mad/commit/b30419e2dbdb7a5f949358fe77c1d93e589794c3))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- Update cert-manager subscription to v1.12
  ([`019301e`](https://github.com/goern/op1st-emea-b4mad/commit/019301ef108b548a487ec80898ffc5175ec1fda7))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- Add autoSizingReserved: true to nostromo's kubelet config
  ([`32412bd`](https://github.com/goern/op1st-emea-b4mad/commit/32412bd976338b51678649e56e629946d2b64d74))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- Disable b4mad-racing* projects
  ([`9d8bbc4`](https://github.com/goern/op1st-emea-b4mad/commit/9d8bbc4f6006571a5784ccac6292802a6d8078f4))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- Disable bn-bruecken-den, project is hibernated
  ([`8c7b3c4`](https://github.com/goern/op1st-emea-b4mad/commit/8c7b3c4536b95783241b690f5ce66644dcf76924))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- Remove thoth related configs
  ([`69aa1ac`](https://github.com/goern/op1st-emea-b4mad/commit/69aa1acc97cbdb31afd95e72e229aab52d687286))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- Remove okd cluster
  ([`537992a`](https://github.com/goern/op1st-emea-b4mad/commit/537992a9742e108efc5610a67fb9b36f46ca88f8))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- Limit ranges for prow
  ([`28f9270`](https://github.com/goern/op1st-emea-b4mad/commit/28f92705d5b9d1852c6b2665e30fe9e3be3647f5))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- Refactore cert-manager-operator out of https://github.com/redhat-cop/gitops-catalog into this repo
  ([`ee44663`](https://github.com/goern/op1st-emea-b4mad/commit/ee446633bf77d639f143bccaa1bbbd59ba63a2cd))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- Update OpenShift GitOps to 1.11
  ([`e357208`](https://github.com/goern/op1st-emea-b4mad/commit/e357208a61b01ed35de3b1dc6c018f28ac5102ed))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- **ocp**: Reduce system reserved memory of env:nostromo
  ([`e962acb`](https://github.com/goern/op1st-emea-b4mad/commit/e962acb707d82e4d725e5969caae9b184c6aea28))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- **pipelines**: Upgrade to OpenShift Pipeline 1.13, as this is required minimum version when
  running on OpenShift 4.14
  ([`8210487`](https://github.com/goern/op1st-emea-b4mad/commit/8210487c0692051f45e5efde98926ae73e75f23d))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- **nostromo**: Upgrade openshift cluster to 4.14
  ([`1e5c7ca`](https://github.com/goern/op1st-emea-b4mad/commit/1e5c7ca7a963e59f3375d88e5ff544ac2b29b9f4))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- Add b4mad-racing-website-dev
  ([`a162b31`](https://github.com/goern/op1st-emea-b4mad/commit/a162b311fedbb3bd2456fdc83861394f76e8ebf4))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- **nostromo**: Add production environment of bn-bruecken
  ([`fe7eaaa`](https://github.com/goern/op1st-emea-b4mad/commit/fe7eaaa2f6794a109f83d6fb474de3ae9372eb26))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- **devops**: Deploy bn-bruecken env:nostromo-dev
  ([`e4e37f6`](https://github.com/goern/op1st-emea-b4mad/commit/e4e37f6571b4c9ff6c6d88c28bc94cffa8250976))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- **strimzi**: Update to strimzi operator v0.38
  ([`0039d9b`](https://github.com/goern/op1st-emea-b4mad/commit/0039d9b45a2b4a0f0300e5ee3cbd6f51007f96d5))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- **strimzi**: Add strimzi operator to env:nostromo
  ([`949d175`](https://github.com/goern/op1st-emea-b4mad/commit/949d175c60d427a48dc63a4e304682e22fc0de73))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- Enable cluster monitoring for openshift-storage namespace
  ([`ec1e4ff`](https://github.com/goern/op1st-emea-b4mad/commit/ec1e4ffc4be8c7fc04d5ac7e0be69f2703ac94f0))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- **console-links**: Add link to github alert issues to console menue
  ([`951fcbd`](https://github.com/goern/op1st-emea-b4mad/commit/951fcbd72d71c9a7124e815a2759dbefba849a4c))

Signed-off-by: Christoph Görn <goern@b4mad.net>

### Refactoring

- **op1st-pipelines**: Just some renaming
  ([`21ffc55`](https://github.com/goern/op1st-emea-b4mad/commit/21ffc557cfd9fd107b12a54811b21efc28cb6946))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- **op1st-pipelines**: Just some renaming
  ([`d6ca260`](https://github.com/goern/op1st-emea-b4mad/commit/d6ca2605db4adb677c9c3ced0648d0c889d2a36d))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- **b4mad-matrix**: Incr pgsql disk size
  ([`3495dcb`](https://github.com/goern/op1st-emea-b4mad/commit/3495dcb1cc37d31253d22dca1f49283807f5b465))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- **op1st-gitops**: Increase quotas for op1st-ops deployment
  ([`3413a05`](https://github.com/goern/op1st-emea-b4mad/commit/3413a05b1594bae13117a3b6fcdbffb4be7392f8))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- **op1st-gitops**: Increase quotas for op1st-ops deployment
  ([`7bdfe0d`](https://github.com/goern/op1st-emea-b4mad/commit/7bdfe0d86708f124b44cda40f5fdf92caaa098f7))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- **op1st-gitops**: Increase quotas for op1st-ops deployment
  ([`6bb3da9`](https://github.com/goern/op1st-emea-b4mad/commit/6bb3da91a332c87e55cd91ad2d2fced59993faba))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- **op1st-gitops**: Increase quotas for op1st-ops deployment
  ([`bde0d54`](https://github.com/goern/op1st-emea-b4mad/commit/bde0d548071d66074a6575f75d2db046038f90bb))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- **b4mad-matrix**: Incr pgsql disk size
  ([`fff7dd4`](https://github.com/goern/op1st-emea-b4mad/commit/fff7dd4abe0fe4f1b10572c8b263dda4fd7e9c84))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- **b4mad-keycloak**: Incr pgsql disk size
  ([`22fc85c`](https://github.com/goern/op1st-emea-b4mad/commit/22fc85c711d67c3ba65480d172cd7bde6bf5dae4))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- **op1st-monitoring**: Add keycloak oauth config to grafana
  ([`c64d5c4`](https://github.com/goern/op1st-emea-b4mad/commit/c64d5c4d3ebae772a17de56716d2f3dbd88ad1e8))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- **op1st-monitoring**: Update grafana-operator to 5.4.2
  ([`3b2dd25`](https://github.com/goern/op1st-emea-b4mad/commit/3b2dd253d22ffaad1d820f2f3d68f10c6e95590d))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- **op1st-monitoring**: Add keycloak oauth config to grafana
  ([`c3b8f0d`](https://github.com/goern/op1st-emea-b4mad/commit/c3b8f0d866c74f8f44aeea095eaa08bb1a25aa31))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- **op1st-monitoring**: Add keycloak oauth config to grafana
  ([`b064c3a`](https://github.com/goern/op1st-emea-b4mad/commit/b064c3a301043fbcdc811bea5dcf3d4f238e3278))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- **op1st-monitoring**: Add keycloak oauth config to grafana
  ([`db2ffb0`](https://github.com/goern/op1st-emea-b4mad/commit/db2ffb0d370baaf5ae0f01724d0e1d26c2b729f9))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- **op1st-monitoring**: Add keycloak oauth config to grafana
  ([`936d3d1`](https://github.com/goern/op1st-emea-b4mad/commit/936d3d13dec9964e14f574dde823a8aea260fcba))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- **op1st-monitoring**: Add keycloak oauth config to grafana
  ([`d52e094`](https://github.com/goern/op1st-emea-b4mad/commit/d52e09441475ba3650851cd55bb39bd8a43bca65))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- **nostromo**: Increase popeye memory limit
  ([`fb46e79`](https://github.com/goern/op1st-emea-b4mad/commit/fb46e799e55d7e42d6ea88745fe36bf32ece44cd))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- **keycloak**: Reduce postgresql audit log
  ([`92a3ce2`](https://github.com/goern/op1st-emea-b4mad/commit/92a3ce2863c473d4d4d2909638d7a8f14eccce40))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- Migration to cloudnative-pg
  ([`fdc8fe0`](https://github.com/goern/op1st-emea-b4mad/commit/fdc8fe09d1ca50b58b666bb46cb9cf45252507a4))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- Start migration to cloudnative-pg
  ([`4313bbd`](https://github.com/goern/op1st-emea-b4mad/commit/4313bbd52f2f0942777335ac190e18cb31200501))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- Start migration to cloudnative-pg
  ([`dc273bd`](https://github.com/goern/op1st-emea-b4mad/commit/dc273bd14ec28b068eb38a38e190a6afe1247e1b))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- Some minor changes to namespaces
  ([`3269b15`](https://github.com/goern/op1st-emea-b4mad/commit/3269b157ad9db868b0cf3ea7ae70072c262ac09f))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- Gatekeeper cleanup
  ([`445c7a5`](https://github.com/goern/op1st-emea-b4mad/commit/445c7a5e90768d5115480fac29468f882f927d02))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- **keycloak**: Ingress configured explicitely, not by keycloak operator
  ([`7a6765c`](https://github.com/goern/op1st-emea-b4mad/commit/7a6765cdd94e22ff015db889b617614607b90e22))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- Decoupled pgo from redhat-cop/gitops-catalog repo
  ([`f55666f`](https://github.com/goern/op1st-emea-b4mad/commit/f55666fa246a25e047f1a03f83818ab771fd4316))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- Rename
  ([`c3ce6a1`](https://github.com/goern/op1st-emea-b4mad/commit/c3ce6a1a839b9a6393267fdf4c86358ad0cf779f))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- Cleanup and decoupling of openshift-gitops and op1st-gitops
  ([`ab87858`](https://github.com/goern/op1st-emea-b4mad/commit/ab878580d47b17d3f39d8616c58e90b69ce391b8))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- Cleanup and decoupling of openshift-gitops and op1st-gitops
  ([`078d517`](https://github.com/goern/op1st-emea-b4mad/commit/078d517cc24a910cb19e364b6c48df23ac945fc0))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- Cleanup and decoupling of openshift-gitops and op1st-gitops
  ([`a7b6274`](https://github.com/goern/op1st-emea-b4mad/commit/a7b6274b9a25b8b52ed3cd1cd9d63ac93ddf51cd))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- Cleanup and decoupling of openshift-gitops and op1st-gitops
  ([`5c03977`](https://github.com/goern/op1st-emea-b4mad/commit/5c039773bb949363cd0f410acb41f129c71ef455))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- Cleanup and decoupling of openshift-gitops and op1st-gitops
  ([`4788448`](https://github.com/goern/op1st-emea-b4mad/commit/4788448d05ca7bb5269c33606ac0b580468cfaf9))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- Cleanup and decoupling of openshift-gitops and op1st-gitops
  ([`9254f74`](https://github.com/goern/op1st-emea-b4mad/commit/9254f740502efe1edbd63bd4dfaa83645fdf2494))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- Cleanup and decoupling of openshift-gitops and op1st-gitops
  ([`47f33af`](https://github.com/goern/op1st-emea-b4mad/commit/47f33afa7f8ca5f2f7af5cad5790307000d14aec))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- Remove okd environment from gitops
  ([`03dce7f`](https://github.com/goern/op1st-emea-b4mad/commit/03dce7f6ca27c0c6d1206d3b2c137c592fca5f90))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- Cleanup and decoupling of openshift-gitops and op1st-gitops
  ([`2193361`](https://github.com/goern/op1st-emea-b4mad/commit/2193361bad18ff3770c1fe9b1df134bca5b0438b))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- Cleanup and decoupling of openshift-gitops and op1st-gitops
  ([`9bc883f`](https://github.com/goern/op1st-emea-b4mad/commit/9bc883fff8e55cf36ea05ef3eea9c616f5b71cd0))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- Cleanup and decoupling of openshift-gitops and op1st-gitops
  ([`f0e9d65`](https://github.com/goern/op1st-emea-b4mad/commit/f0e9d65fbb13d808784af526c11394303753a69d))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- Cleanup and decoupling of openshift-gitops and op1st-gitops
  ([`aefe90e`](https://github.com/goern/op1st-emea-b4mad/commit/aefe90e96c12fdfca43e663a75d01a5611aa5d89))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- Cleanup and decoupling of openshift-gitops and op1st-gitops
  ([`27facce`](https://github.com/goern/op1st-emea-b4mad/commit/27facced6cc9a75cd69a5fc24f7e524c2e04d41e))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- Cleanup and decoupling of openshift-gitops and op1st-gitops
  ([`dd2dac9`](https://github.com/goern/op1st-emea-b4mad/commit/dd2dac9e75d63b06e4511adce5ec9f84252c1740))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- Cleanup and decoupling of openshift-gitops and op1st-gitops
  ([`c9bb5f1`](https://github.com/goern/op1st-emea-b4mad/commit/c9bb5f15fe90e3c5d3c76926037264da3f6f0968))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- Cleanup and decoupling of openshift-gitops and op1st-gitops
  ([`f4489ea`](https://github.com/goern/op1st-emea-b4mad/commit/f4489ea6b0ec6325f8f1cd8b9e80bcd77124ae4f))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- Cleanup and decoupling of openshift-gitops and op1st-gitops
  ([`1b4ae24`](https://github.com/goern/op1st-emea-b4mad/commit/1b4ae24de8c4d56ac78eda1b19f1a84e91725c2c))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- Cleanup and decoupling of openshift-gitops and op1st-gitops
  ([`8e38dd6`](https://github.com/goern/op1st-emea-b4mad/commit/8e38dd6bda38653991acafe6e938106eba2c96e9))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- Cleanup and decoupling of openshift-gitops and op1st-gitops
  ([`ed250ef`](https://github.com/goern/op1st-emea-b4mad/commit/ed250efa421aef87c4522e92feaf443507bd8214))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- Cleanup and decoupling of openshift-gitops and op1st-gitops
  ([`b7e6637`](https://github.com/goern/op1st-emea-b4mad/commit/b7e663708a25ced48d2dbb74b77ad6c9bc4b144e))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- Cleanup and decoupling of openshift-gitops and op1st-gitops
  ([`c6db45d`](https://github.com/goern/op1st-emea-b4mad/commit/c6db45d6618eb8c1b32bff2e70703e86e7ae3753))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- Cleanup and decoupling of openshift-gitops and op1st-gitops
  ([`b45207f`](https://github.com/goern/op1st-emea-b4mad/commit/b45207f8076062bfcdbed5095a107ad46914975c))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- Cleanup and decoupling of openshift-gitops and op1st-gitops
  ([`51e650a`](https://github.com/goern/op1st-emea-b4mad/commit/51e650a71d285de3ff9ba84ffa4faf800a3e8e24))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- Cleanup and decoupling of openshift-gitops and op1st-gitops
  ([`bfe119d`](https://github.com/goern/op1st-emea-b4mad/commit/bfe119da2b35cc18278570237b28549616c68172))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- Cleanup and decoupling of openshift-gitops and op1st-gitops
  ([`9ebcf1e`](https://github.com/goern/op1st-emea-b4mad/commit/9ebcf1e75c3a31bb75327486f242984b7bce8340))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- Cleanup and decoupling of openshift-gitops and op1st-gitops
  ([`f582bb8`](https://github.com/goern/op1st-emea-b4mad/commit/f582bb81700bd89b243d79a12b53e9b212309b3d))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- Cleanup and decoupling of openshift-gitops and op1st-gitops
  ([`179a482`](https://github.com/goern/op1st-emea-b4mad/commit/179a4829e2441339d0ed5dea8b0cb2b2ed96279b))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- Cleanup and decoupling of openshift-gitops and op1st-gitops
  ([`4500db6`](https://github.com/goern/op1st-emea-b4mad/commit/4500db6cbf67305e7ce121c761a2136295c98a7b))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- Cleanup and decoupling of openshift-gitops and op1st-gitops
  ([`3509d76`](https://github.com/goern/op1st-emea-b4mad/commit/3509d76c7aae3b14e9ea4d0dbec3989e10e6845c))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- Cleanup and decoupling of openshift-gitops and op1st-gitops
  ([`9d099c8`](https://github.com/goern/op1st-emea-b4mad/commit/9d099c88a6e4273253b05c3022b225bb747071d8))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- Cleanup and decoupling of openshift-gitops and op1st-gitops
  ([`c79bc92`](https://github.com/goern/op1st-emea-b4mad/commit/c79bc92875efcee731abf9698b1d3e3ca8d9e7fb))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- Cleanup and decoupling of openshift-gitops and op1st-gitops
  ([`42e9c8a`](https://github.com/goern/op1st-emea-b4mad/commit/42e9c8a2ca63983aa19fdd8186c8d9520cb0f973))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- Cleanup and decoupling of openshift-gitops and op1st-gitops
  ([`756684d`](https://github.com/goern/op1st-emea-b4mad/commit/756684d87edf7ac59ed808d05f015afe449e5fc7))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- Cleanup and decoupling of openshift-gitops and op1st-gitops
  ([`48e9a5c`](https://github.com/goern/op1st-emea-b4mad/commit/48e9a5cd47ef5d7d08fe1a8081e24fd9b62176ee))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- Cleanup and decoupling of openshift-gitops and op1st-gitops
  ([`e0b697d`](https://github.com/goern/op1st-emea-b4mad/commit/e0b697d459ba87994fef65b6b35c5c80962b9b43))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- Cleanup and decoupling of openshift-gitops and op1st-gitops
  ([`8cb75f3`](https://github.com/goern/op1st-emea-b4mad/commit/8cb75f3bc52c1c12c7c5e2910f539352cc039485))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- Cleanup and decoupling of openshift-gitops and op1st-gitops
  ([`a03feb0`](https://github.com/goern/op1st-emea-b4mad/commit/a03feb047e367646cb06604762891a1860045796))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- Cleanup and decoupling of openshift-gitops and op1st-gitops
  ([`e091b41`](https://github.com/goern/op1st-emea-b4mad/commit/e091b41a52425be51a0b39865a444ab8fe1f3ab4))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- Cleanup and decoupling of openshift-gitops and op1st-gitops
  ([`c200481`](https://github.com/goern/op1st-emea-b4mad/commit/c2004810399ec11ef34cc40e2bb64d2fb81b24e4))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- Cleanup and decoupling of openshift-gitops and op1st-gitops
  ([`1bdd449`](https://github.com/goern/op1st-emea-b4mad/commit/1bdd4499729ae3a9920a5080a504bff92e1eaf26))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- Cleanup and decoupling of openshift-gitops and op1st-gitops
  ([`7f142e1`](https://github.com/goern/op1st-emea-b4mad/commit/7f142e14fdf0d4d0c82f37a963308cc85ed404b1))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- Cleanup and decoupling of openshift-gitops and op1st-gitops
  ([`6188c6c`](https://github.com/goern/op1st-emea-b4mad/commit/6188c6cd1e12306a547237bfb7c8cbf99988d5f0))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- Reduce number of hook replicas
  ([`fce8702`](https://github.com/goern/op1st-emea-b4mad/commit/fce8702d261159cb0bdcb2d76413968b4b169687))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- Reconfigured a few resources
  ([`78f5724`](https://github.com/goern/op1st-emea-b4mad/commit/78f57244dac834378066c0c2efbfdecbdacfe033))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- Reorganize directory structure of components
  ([`d357b04`](https://github.com/goern/op1st-emea-b4mad/commit/d357b0418ac5f4398bd0cfdd2b867543a82a1f90))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- More cleanup
  ([`4651501`](https://github.com/goern/op1st-emea-b4mad/commit/46515014337194789e3f97078449685bc417980b))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- Move some more stuff into components
  ([`188cd18`](https://github.com/goern/op1st-emea-b4mad/commit/188cd18136893c43afdddd2109bf4857c0071699))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- Same as last commit
  ([`3729f10`](https://github.com/goern/op1st-emea-b4mad/commit/3729f106a9e8b378f9853fa58a6eb03b1816177e))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- **monitoring**: Re-encrypt the PAT for github-alertmanager-receiver on env:nostromo
  ([`4805d49`](https://github.com/goern/op1st-emea-b4mad/commit/4805d49cd5cc9891d16b60759b3f48ec74d1ba9e))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- **nncp**: Stil trying to get a grip on https://github.com/okd-project/okd/discussions/1634
  ([`b8d19c0`](https://github.com/goern/op1st-emea-b4mad/commit/b8d19c0d0d6d4afcceff256a76d5dc3b701f8129))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- Migrate app to its own repo
  ([`2e6b76f`](https://github.com/goern/op1st-emea-b4mad/commit/2e6b76fb86e4e10d9002118e37975fa28429e55c))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- Do NOT set url for argocd deployment on env:nostromo
  ([`25c7afd`](https://github.com/goern/op1st-emea-b4mad/commit/25c7afd291488294e10f256ff8451289306a4c43))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- Set url for argocd deployment on env:nostromo
  ([`bda978b`](https://github.com/goern/op1st-emea-b4mad/commit/bda978be65478fc3cf25d1e201bc79019f75d84d))

Signed-off-by: Christoph Görn <goern@b4mad.net>


## v0.1.0 (2023-11-03)

### Bug Fixes

- **sig-sre**: Fix wrong configmap name in alertmanager-github-receiver deployment
  ([`04e4619`](https://github.com/goern/op1st-emea-b4mad/commit/04e461975428f9f11e7187f950806df122b7e233))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- **op1st-pipelines**: Fix a typo
  ([`322ec1e`](https://github.com/goern/op1st-emea-b4mad/commit/322ec1e0b185a9c94ccc0fe692f04b399065df4e))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- Annotate op1st-pipelines-coderberg-org to be used for github.com too
  ([`657f210`](https://github.com/goern/op1st-emea-b4mad/commit/657f210ce1aa3284958c9ab3462e3ae8c02d446f))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- Annotate op1st-pipelines-coderberg-org to be used for github.com too
  ([`8d37cd9`](https://github.com/goern/op1st-emea-b4mad/commit/8d37cd958f1da67a5d4e5eac7bf885b52ac29ea0))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- **op1st-pipelines**: Add github.com to the known host config of ssh
  ([`cb532c8`](https://github.com/goern/op1st-emea-b4mad/commit/cb532c817626614bd420b735291ae0c08c6159ab))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- **argocd**: Allow argocd to patch podmonitors
  ([`e7f8bba`](https://github.com/goern/op1st-emea-b4mad/commit/e7f8bbacb4835cbdf5e9df945f3beb5db8cf5aca))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- **prow**: Some more prow config fixes
  ([`614fb84`](https://github.com/goern/op1st-emea-b4mad/commit/614fb84b5b4294143588e2b2e1d1b719fd1ef3ab))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- **prow**: Fix some errors found by `checkconfig`
  ([`b123c1d`](https://github.com/goern/op1st-emea-b4mad/commit/b123c1d4a730421ba1e01b8c6ab79debd0c6ee3a))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- **sealed-secrets**: Put the resources into the correct namespace
  ([`dacf088`](https://github.com/goern/op1st-emea-b4mad/commit/dacf08839940f018578207c10b1e3f688d9b96e2))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- Cycle miniso secrets
  ([`e8b53c6`](https://github.com/goern/op1st-emea-b4mad/commit/e8b53c654b2a426fd5899a38b7b36a9b28da85d1))

Signed-off-by: Christoph Görn <goern@b4mad.net>

### Build System

- Automatic update of prow
  ([`5d7e3a0`](https://github.com/goern/op1st-emea-b4mad/commit/5d7e3a0b2fdbb371cb8a5ffc046113f047f59f01))

updates image k8s-prow/branchprotector tag 'v20231027-9cda73bb73' to 'v20231101-174189c793' updates
  image k8s-prow/crier tag 'v20231027-9cda73bb73' to 'v20231101-174189c793' updates image
  k8s-prow/ghproxy tag 'v20231027-9cda73bb73' to 'v20231101-174189c793' updates image k8s-prow/hook
  tag 'v20231027-9cda73bb73' to 'v20231101-174189c793' updates image k8s-prow/horologium tag
  'v20231027-9cda73bb73' to 'v20231101-174189c793' updates image k8s-prow/needs-rebase tag
  'v20231027-9cda73bb73' to 'v20231101-174189c793' updates image k8s-prow/prow-controller-manager
  tag 'v20231027-9cda73bb73' to 'v20231101-174189c793' updates image k8s-prow/sinker tag
  'v20231027-9cda73bb73' to 'v20231101-174189c793' updates image k8s-prow/status-reconciler tag
  'v20231027-9cda73bb73' to 'v20231101-174189c793' updates image k8s-prow/tide tag
  'v20231027-9cda73bb73' to 'v20231101-174189c793'

- Automatic update of prow
  ([`1de34d1`](https://github.com/goern/op1st-emea-b4mad/commit/1de34d1c0c04fe2d87fada14fc9df30fff046fcb))

updates image k8s-prow/branchprotector tag 'v20231019-811baf28f3' to 'v20231027-9cda73bb73' updates
  image k8s-prow/crier tag 'v20231019-811baf28f3' to 'v20231027-9cda73bb73' updates image
  k8s-prow/deck tag 'v20231019-811baf28f3' to 'v20231027-9cda73bb73' updates image k8s-prow/ghproxy
  tag 'v20231019-811baf28f3' to 'v20231027-9cda73bb73' updates image k8s-prow/hook tag
  'v20231019-811baf28f3' to 'v20231027-9cda73bb73' updates image k8s-prow/horologium tag
  'v20231019-811baf28f3' to 'v20231027-9cda73bb73' updates image k8s-prow/needs-rebase tag
  'v20231019-811baf28f3' to 'v20231027-9cda73bb73' updates image k8s-prow/prow-controller-manager
  tag 'v20231019-811baf28f3' to 'v20231027-9cda73bb73' updates image k8s-prow/sinker tag
  'v20231019-811baf28f3' to 'v20231027-9cda73bb73' updates image k8s-prow/status-reconciler tag
  'v20231019-811baf28f3' to 'v20231027-9cda73bb73' updates image k8s-prow/tide tag
  'v20231019-811baf28f3' to 'v20231027-9cda73bb73'

- Automatic update of prow
  ([`5cb66a9`](https://github.com/goern/op1st-emea-b4mad/commit/5cb66a9c7fe8b80efc175804b6ddf198ed6e21d2))

updates image k8s-prow/branchprotector tag 'v20231011-acf4a2e26b' to 'v20231019-811baf28f3' updates
  image k8s-prow/crier tag 'v20231011-acf4a2e26b' to 'v20231019-811baf28f3' updates image
  k8s-prow/deck tag 'v20231011-acf4a2e26b' to 'v20231019-811baf28f3' updates image k8s-prow/ghproxy
  tag 'v20231011-acf4a2e26b' to 'v20231019-811baf28f3' updates image k8s-prow/hook tag
  'v20231011-acf4a2e26b' to 'v20231019-811baf28f3' updates image k8s-prow/horologium tag
  'v20231011-acf4a2e26b' to 'v20231019-811baf28f3' updates image k8s-prow/needs-rebase tag
  'v20231011-acf4a2e26b' to 'v20231019-811baf28f3' updates image k8s-prow/prow-controller-manager
  tag 'v20231011-acf4a2e26b' to 'v20231019-811baf28f3' updates image k8s-prow/sinker tag
  'v20231011-acf4a2e26b' to 'v20231019-811baf28f3' updates image k8s-prow/status-reconciler tag
  'v20231011-acf4a2e26b' to 'v20231019-811baf28f3' updates image k8s-prow/tide tag
  'v20231011-acf4a2e26b' to 'v20231019-811baf28f3'

- Update prow container images
  ([`f7766f7`](https://github.com/goern/op1st-emea-b4mad/commit/f7766f72b3938c09dc4d6b4fdfecb09c14d1f3e6))

- Automatic update of prow
  ([`e40b916`](https://github.com/goern/op1st-emea-b4mad/commit/e40b9164dfd91e83efd9bafeb9ad173e86adaa27))

updates image k8s-prow/branchprotector tag 'v20231003-e23b6604b5' to 'v20231004-f64f17f7bb' updates
  image k8s-prow/crier tag 'v20231003-e23b6604b5' to 'v20231004-f64f17f7bb' updates image
  k8s-prow/deck tag 'v20231003-e23b6604b5' to 'v20231004-f64f17f7bb' updates image k8s-prow/ghproxy
  tag 'v20231003-e23b6604b5' to 'v20231004-f64f17f7bb' updates image k8s-prow/hook tag
  'v20231003-e23b6604b5' to 'v20231004-f64f17f7bb' updates image k8s-prow/horologium tag
  'v20231003-e23b6604b5' to 'v20231004-f64f17f7bb' updates image k8s-prow/needs-rebase tag
  'v20231003-e23b6604b5' to 'v20231004-f64f17f7bb' updates image k8s-prow/prow-controller-manager
  tag 'v20231003-e23b6604b5' to 'v20231004-f64f17f7bb' updates image k8s-prow/sinker tag
  'v20231003-e23b6604b5' to 'v20231004-f64f17f7bb' updates image k8s-prow/status-reconciler tag
  'v20231003-e23b6604b5' to 'v20231004-f64f17f7bb' updates image k8s-prow/tide tag
  'v20231003-e23b6604b5' to 'v20231004-f64f17f7bb'

- Automatic update of prow
  ([`3ca23b4`](https://github.com/goern/op1st-emea-b4mad/commit/3ca23b45f0203c4f77693914d68fbbacf6fe18b3))

updates image k8s-prow/branchprotector tag 'v20230930-5a0076ef61' to 'v20231003-e23b6604b5' updates
  image k8s-prow/crier tag 'v20230930-5a0076ef61' to 'v20231003-e23b6604b5' updates image
  k8s-prow/deck tag 'v20230930-5a0076ef61' to 'v20231003-e23b6604b5' updates image k8s-prow/ghproxy
  tag 'v20230930-5a0076ef61' to 'v20231003-e23b6604b5' updates image k8s-prow/hook tag
  'v20230930-5a0076ef61' to 'v20231003-e23b6604b5' updates image k8s-prow/horologium tag
  'v20230930-5a0076ef61' to 'v20231003-e23b6604b5' updates image k8s-prow/needs-rebase tag
  'v20230930-5a0076ef61' to 'v20231003-e23b6604b5' updates image k8s-prow/prow-controller-manager
  tag 'v20230930-5a0076ef61' to 'v20231003-e23b6604b5' updates image k8s-prow/sinker tag
  'v20230930-5a0076ef61' to 'v20231003-e23b6604b5' updates image k8s-prow/status-reconciler tag
  'v20230930-5a0076ef61' to 'v20231003-e23b6604b5' updates image k8s-prow/tide tag
  'v20230930-5a0076ef61' to 'v20231003-e23b6604b5'

- Automatic update of prow
  ([`a97878b`](https://github.com/goern/op1st-emea-b4mad/commit/a97878b77c28e91350311a6512ee87b4bd690f61))

updates image k8s-prow/crier tag 'v20230930-5a0076ef61' to 'v20231003-e23b6604b5' updates image
  k8s-prow/deck tag 'v20230930-5a0076ef61' to 'v20231003-e23b6604b5' updates image k8s-prow/ghproxy
  tag 'v20230930-5a0076ef61' to 'v20231003-e23b6604b5' updates image k8s-prow/hook tag
  'v20230930-5a0076ef61' to 'v20231003-e23b6604b5' updates image k8s-prow/horologium tag
  'v20230930-5a0076ef61' to 'v20231003-e23b6604b5' updates image k8s-prow/needs-rebase tag
  'v20230930-5a0076ef61' to 'v20231003-e23b6604b5' updates image k8s-prow/prow-controller-manager
  tag 'v20230930-5a0076ef61' to 'v20231003-e23b6604b5' updates image k8s-prow/sinker tag
  'v20230930-5a0076ef61' to 'v20231003-e23b6604b5' updates image k8s-prow/status-reconciler tag
  'v20230930-5a0076ef61' to 'v20231003-e23b6604b5' updates image k8s-prow/tide tag
  'v20230930-5a0076ef61' to 'v20231003-e23b6604b5'

- Automatic update of prow
  ([`b5ec1c2`](https://github.com/goern/op1st-emea-b4mad/commit/b5ec1c280646e7b923d0d37efadf7724f450579c))

updates image k8s-prow/branchprotector tag 'v20230901-e9e5d470a5' to 'v20230930-5a0076ef61' updates
  image k8s-prow/crier tag 'v20230927-f8b8856dbc' to 'v20230930-5a0076ef61'

- Automatic update of prow
  ([`96f2ba8`](https://github.com/goern/op1st-emea-b4mad/commit/96f2ba8718e9faf4dc7818f96d3e0e15727ab063))

updates image k8s-prow/branchprotector tag 'v20230901-e9e5d470a5' to 'v20230930-5a0076ef61' updates
  image k8s-prow/deck tag 'v20230927-f8b8856dbc' to 'v20230930-5a0076ef61' updates image
  k8s-prow/ghproxy tag 'v20230927-f8b8856dbc' to 'v20230930-5a0076ef61' updates image k8s-prow/hook
  tag 'v20230927-f8b8856dbc' to 'v20230930-5a0076ef61' updates image k8s-prow/horologium tag
  'v20230927-f8b8856dbc' to 'v20230930-5a0076ef61' updates image k8s-prow/needs-rebase tag
  'v20230927-f8b8856dbc' to 'v20230930-5a0076ef61' updates image k8s-prow/prow-controller-manager
  tag 'v20230927-f8b8856dbc' to 'v20230930-5a0076ef61' updates image k8s-prow/sinker tag
  'v20230927-f8b8856dbc' to 'v20230930-5a0076ef61' updates image k8s-prow/status-reconciler tag
  'v20230927-f8b8856dbc' to 'v20230930-5a0076ef61' updates image k8s-prow/tide tag
  'v20230927-f8b8856dbc' to 'v20230930-5a0076ef61'

- Automatic update of prow
  ([`fecf76a`](https://github.com/goern/op1st-emea-b4mad/commit/fecf76a7aca777f08e6dacc48d9f493500422c03))

updates image k8s-prow/branchprotector tag 'v20230901-e9e5d470a5' to 'v20230927-f8b8856dbc' updates
  image k8s-prow/crier tag 'v20230901-e9e5d470a5' to 'v20230927-f8b8856dbc' updates image
  k8s-prow/deck tag 'v20230901-e9e5d470a5' to 'v20230927-f8b8856dbc' updates image k8s-prow/ghproxy
  tag 'v20230901-e9e5d470a5' to 'v20230927-f8b8856dbc' updates image k8s-prow/hook tag
  'v20230901-e9e5d470a5' to 'v20230927-f8b8856dbc' updates image k8s-prow/horologium tag
  'v20230901-e9e5d470a5' to 'v20230927-f8b8856dbc' updates image k8s-prow/needs-rebase tag
  'v20230901-e9e5d470a5' to 'v20230927-f8b8856dbc' updates image k8s-prow/prow-controller-manager
  tag 'v20230901-e9e5d470a5' to 'v20230927-f8b8856dbc' updates image k8s-prow/sinker tag
  'v20230901-e9e5d470a5' to 'v20230927-f8b8856dbc' updates image k8s-prow/status-reconciler tag
  'v20230901-e9e5d470a5' to 'v20230927-f8b8856dbc' updates image k8s-prow/tide tag
  'v20230901-e9e5d470a5' to 'v20230927-f8b8856dbc'

- Automatic update of prow
  ([`6febf25`](https://github.com/goern/op1st-emea-b4mad/commit/6febf250f10a4f58d5061a226767dba02cd82e6f))

updates image k8s-prow/crier tag 'v20230829-df0ee1785b' to 'v20230901-e9e5d470a5' updates image
  k8s-prow/deck tag 'v20230829-df0ee1785b' to 'v20230901-e9e5d470a5' updates image k8s-prow/ghproxy
  tag 'v20230829-df0ee1785b' to 'v20230901-e9e5d470a5' updates image k8s-prow/hook tag
  'v20230829-df0ee1785b' to 'v20230901-e9e5d470a5' updates image k8s-prow/horologium tag
  'v20230829-df0ee1785b' to 'v20230901-e9e5d470a5' updates image k8s-prow/needs-rebase tag
  'v20230829-df0ee1785b' to 'v20230901-e9e5d470a5' updates image k8s-prow/prow-controller-manager
  tag 'v20230829-df0ee1785b' to 'v20230901-e9e5d470a5' updates image k8s-prow/sinker tag
  'v20230829-df0ee1785b' to 'v20230901-e9e5d470a5' updates image k8s-prow/status-reconciler tag
  'v20230829-df0ee1785b' to 'v20230901-e9e5d470a5' updates image k8s-prow/tide tag
  'v20230829-df0ee1785b' to 'v20230901-e9e5d470a5'

- Automatic update of prow
  ([`8f77bb5`](https://github.com/goern/op1st-emea-b4mad/commit/8f77bb5d8990ca200b261a4eb9a5ac0e9c6fdc53))

updates image k8s-prow/branchprotector tag 'v20230829-df0ee1785b' to 'v20230901-e9e5d470a5' updates
  image k8s-prow/crier tag 'v20230829-df0ee1785b' to 'v20230901-e9e5d470a5' updates image
  k8s-prow/deck tag 'v20230829-df0ee1785b' to 'v20230901-e9e5d470a5' updates image k8s-prow/ghproxy
  tag 'v20230829-df0ee1785b' to 'v20230901-e9e5d470a5' updates image k8s-prow/hook tag
  'v20230829-df0ee1785b' to 'v20230901-e9e5d470a5' updates image k8s-prow/horologium tag
  'v20230829-df0ee1785b' to 'v20230901-e9e5d470a5' updates image k8s-prow/needs-rebase tag
  'v20230829-df0ee1785b' to 'v20230901-e9e5d470a5' updates image k8s-prow/prow-controller-manager
  tag 'v20230829-df0ee1785b' to 'v20230901-e9e5d470a5' updates image k8s-prow/sinker tag
  'v20230829-df0ee1785b' to 'v20230901-e9e5d470a5' updates image k8s-prow/status-reconciler tag
  'v20230829-df0ee1785b' to 'v20230901-e9e5d470a5' updates image k8s-prow/tide tag
  'v20230829-df0ee1785b' to 'v20230901-e9e5d470a5'

- Automatic update of prow
  ([`b7c692e`](https://github.com/goern/op1st-emea-b4mad/commit/b7c692ef0fc6fc408633aca9f27c9ee79cb090db))

updates image k8s-prow/branchprotector tag 'v20230801-526a7e0f2c' to 'v20230829-df0ee1785b' updates
  image k8s-prow/crier tag 'v20230801-526a7e0f2c' to 'v20230829-df0ee1785b' updates image
  k8s-prow/deck tag 'v20230801-526a7e0f2c' to 'v20230829-df0ee1785b' updates image k8s-prow/ghproxy
  tag 'v20230801-526a7e0f2c' to 'v20230829-df0ee1785b' updates image k8s-prow/hook tag
  'v20230801-526a7e0f2c' to 'v20230829-df0ee1785b' updates image k8s-prow/horologium tag
  'v20230801-526a7e0f2c' to 'v20230829-df0ee1785b' updates image k8s-prow/needs-rebase tag
  'v20230801-526a7e0f2c' to 'v20230829-df0ee1785b' updates image k8s-prow/prow-controller-manager
  tag 'v20230801-526a7e0f2c' to 'v20230829-df0ee1785b' updates image k8s-prow/sinker tag
  'v20230801-526a7e0f2c' to 'v20230829-df0ee1785b' updates image k8s-prow/status-reconciler tag
  'v20230801-526a7e0f2c' to 'v20230829-df0ee1785b' updates image k8s-prow/tide tag
  'v20230801-526a7e0f2c' to 'v20230829-df0ee1785b'

### Chores

- Update lvm-storage operator to stable-4.13 channel
  ([`4357f19`](https://github.com/goern/op1st-emea-b4mad/commit/4357f199c888eee1d57b79ace8a475ca60da9491))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- Update alertmanager-receiver config
  ([`18e37a4`](https://github.com/goern/op1st-emea-b4mad/commit/18e37a4654234dc85fc9430199744b1ed0e20b67))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- Update source path in racing.yaml manifest
  ([`24f8005`](https://github.com/goern/op1st-emea-b4mad/commit/24f8005476deed370f6bffa2a78c4bde7ad2af23))

- Update source path in `b4mad/racing.yaml` from `"manifests/env/smaug"` to `"manifests/env/phobos"`

### Code Style

- Fix the kustomize file
  ([`f7f9944`](https://github.com/goern/op1st-emea-b4mad/commit/f7f99441846ae835b978574936aa8d4f96c53ce4))

Signed-off-by: Christoph Görn <goern@b4mad.net>

### Continuous Integration

- Update pre-commit in prow job
  ([`b64dba8`](https://github.com/goern/op1st-emea-b4mad/commit/b64dba84c044c30c2ebd191e23badf9ea5f793cf))

### Features

- Add more secrets, add cluster-monitoring to some namespaces, refined which prow jobs are required
  for b4mad/.github repo
  ([`086cd37`](https://github.com/goern/op1st-emea-b4mad/commit/086cd37afc84cc62f9c29a8422cf345e9f8082da))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- **alertmanager**: Add more group_by keys
  ([`ff57dba`](https://github.com/goern/op1st-emea-b4mad/commit/ff57dba4d7a8d1fb447f7a54a6c22075dc02cc40))

this was a regression, seeAlso https://github.com/m-lab/alertmanager-github-receiver/issues/50

Signed-off-by: Christoph Görn <goern@b4mad.net>

- **alertmanager**: Add github-receiver to alertmanager-main.yaml config
  ([`2e9e866`](https://github.com/goern/op1st-emea-b4mad/commit/2e9e866397e6fce948776ce0bde9dd893c6e3f48))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- Add nostromos's sealed secrets master key
  ([`4e9a2e2`](https://github.com/goern/op1st-emea-b4mad/commit/4e9a2e28c36fbe47608991fc7653d35381e22e50))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- **sig-sre**: Add a github alert receiver, so that alertmanager will open and close issues on
  operate-first/alers repo
  ([`df37066`](https://github.com/goern/op1st-emea-b4mad/commit/df3706695ea9a46f3d1bc115f611a0c6662bf068))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- **op1st-pipelines**: Enable pruner of (Task|Pipeline)Runs
  ([`cfdb29c`](https://github.com/goern/op1st-emea-b4mad/commit/cfdb29c3d97d0892fb6294fee574975ddb32f9ea))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- **gitops**: Bounce apiVersion of cluster-wide ArgoCD resource
  ([`999b95f`](https://github.com/goern/op1st-emea-b4mad/commit/999b95fa5bb810657f2cb2f1548056491a832f8b))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- **gitops**: Enable Argo Rollouts for b4mad project
  ([`19cf768`](https://github.com/goern/op1st-emea-b4mad/commit/19cf7685d7bcf72952c578ab72cd59ff57d79891))

argocd

Signed-off-by: Christoph Görn <goern@b4mad.net>

- **monitoring**: Add argocd dashboard
  ([`d9c8068`](https://github.com/goern/op1st-emea-b4mad/commit/d9c8068c5b04e3e6ffee5edbe5fa09965e386eb1))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- **monitoring**: Add op1st monitoring dashboards
  ([`a57f795`](https://github.com/goern/op1st-emea-b4mad/commit/a57f7959babc727c40686f3a92fd02a3d3f3c357))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- **monitoring**: Enable grafana of openshift-monitoring
  ([`9e5f383`](https://github.com/goern/op1st-emea-b4mad/commit/9e5f38379dfe59f1f8f97f23a92205137dcbbeaa))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- **sealed-secrets**: Add monitoring and alerting
  ([`1b1ce0d`](https://github.com/goern/op1st-emea-b4mad/commit/1b1ce0dcdda981df51969ae215efafaf4b7c55f4))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- **pipelines**: Update to OpenShift Pipelines v1.12
  ([`1720c9e`](https://github.com/goern/op1st-emea-b4mad/commit/1720c9e6c9e1abfe34600d968483badafe3deeda))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- **prow**: Add prow config validation presubmit job
  ([`924f3b9`](https://github.com/goern/op1st-emea-b4mad/commit/924f3b9f41c3aeb80b3b63b879f0447df8383e1c))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- **sealed-secrets**: Update the sealed-secrets operator, and vendored it in (thus removing
  dependency on external gitops-catalog)
  ([`5d877ee`](https://github.com/goern/op1st-emea-b4mad/commit/5d877eebf4c558b10006fb10857e3a1aa45e0218))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- **argocd-image-updater**: Add the argocd-image-updater app
  ([`cf55307`](https://github.com/goern/op1st-emea-b4mad/commit/cf55307f0085923bf73abd8451ea94b16f0320cc))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- **argocd-image-updater**: Use sha for branch name
  ([`69d635e`](https://github.com/goern/op1st-emea-b4mad/commit/69d635e63c02844b11e5011d6509509a91ca8c08))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- **argocd-image-updater**: Use a new branch for the write-back of new image tags
  ([`3fc6743`](https://github.com/goern/op1st-emea-b4mad/commit/3fc67438794520c041cb91af241e7c25082e7b19))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- **secrets**: Add peribolos secrets
  ([`d5e9488`](https://github.com/goern/op1st-emea-b4mad/commit/d5e948831c897ffac023c8c509dd7d259406b283))

nostromo

Signed-off-by: Christoph Görn <goern@b4mad.net>

- **secrets**: Start adding sops-encoded secrets
  ([`edaefce`](https://github.com/goern/op1st-emea-b4mad/commit/edaefce09eb067c25f2d5e806c32a6be0f8bdea7))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- ✨ configure alertmanager receivers on env:phobos
  ([`44d35cd`](https://github.com/goern/op1st-emea-b4mad/commit/44d35cd42749bf7952b2e9eba170fd56857712da))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- ✨ alert on disk <20% available bytes
  ([`fb968e7`](https://github.com/goern/op1st-emea-b4mad/commit/fb968e75626d7d2f80b5a4487f856a148fa03a35))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- ✨ use alertmanager discord plugin for Critical and Default
  ([`75e76bb`](https://github.com/goern/op1st-emea-b4mad/commit/75e76bb22c8fd83d8a3ca74e7d8af63bbfb4d013))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- ✨ use alertmanager discord plugin
  ([`1ce15e6`](https://github.com/goern/op1st-emea-b4mad/commit/1ce15e68452924fc51fbf1a49768f052fdde308e))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- ✨ use alertmanager discord plugin
  ([`cb4e82c`](https://github.com/goern/op1st-emea-b4mad/commit/cb4e82c32fb115f941124eb0182ab7570f77b14c))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- Add admin-acks, based on https://access.redhat.com/articles/6958395
  ([`59aff10`](https://github.com/goern/op1st-emea-b4mad/commit/59aff108715dc845136215a22b6f3f638835d1c6))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- Enable grafana of cluster-monitoring on env:nostromo
  ([`185192e`](https://github.com/goern/op1st-emea-b4mad/commit/185192e50c32be78e36bf0b091789709c4f1e1f4))

Signed-off-by: Christoph Görn <goern@b4mad.net>

### Refactoring

- Add some more secrets we have
  ([`758d33a`](https://github.com/goern/op1st-emea-b4mad/commit/758d33a515b0505a1fd8c95c15ce44e6d68f7c69))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- **prow**: Rename status reconciler status file on s3
  ([`eadd09d`](https://github.com/goern/op1st-emea-b4mad/commit/eadd09dd5f9077eaa6570675502be1b256c95855))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- **argocd**: Remove argocd-commenter annotations from ArgoCD Applications
  ([`2ba1b59`](https://github.com/goern/op1st-emea-b4mad/commit/2ba1b591c992521fdfec2838f859d2ac2d6fd7bd))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- **commitizen**: Add commitizen config
  ([`3c483d3`](https://github.com/goern/op1st-emea-b4mad/commit/3c483d35289bb0c15f86706fb949177a291f1090))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- **grafana-operator**: Remove grafana-operator from nostromo
  ([`d76a787`](https://github.com/goern/op1st-emea-b4mad/commit/d76a7872acf3a9693a34442e36849dd26115d816))

env:nostromo

BREAKING CHANGE:

Signed-off-by: Christoph Görn <goern@b4mad.net>

- **openshift-gitops**: Decoupled form gitops-catalog
  ([`7b3a08b`](https://github.com/goern/op1st-emea-b4mad/commit/7b3a08b8b5d7fb8c6ddf8a2f4098973b2b43df6f))

env:nostromo Signed-off-by: Christoph Görn <goern@b4mad.net>

- Update kustomization files to new format
  ([`2bc3128`](https://github.com/goern/op1st-emea-b4mad/commit/2bc31286d022dfb36f31d7ee9db1381d37b53511))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- **op1st-pipelines**: Add codeberg secret to repo
  ([`a7571fe`](https://github.com/goern/op1st-emea-b4mad/commit/a7571fe3db6ca4a27414ac52f19722ebaad2b48f))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- **openshift**: Using the 'fast' channel now
  ([`4f0dc49`](https://github.com/goern/op1st-emea-b4mad/commit/4f0dc491d125330bc6dc682996cb0a60e777677f))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- **prow**: Update utility image versions, remove phobos from inrepo-clusters
  ([`56e5792`](https://github.com/goern/op1st-emea-b4mad/commit/56e579202b26dfcd7a899a8226ebb72a2b4c68b2))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- **argocd**: Move argocd-image-updater app to cluster-management project, as we need to modify the
  openshift-gitops namespace
  ([`828fe2a`](https://github.com/goern/op1st-emea-b4mad/commit/828fe2a5f9558fd757e019e2aa5f203f274fb676))

Signed-off-by: Christoph Görn <goern@b4mad.net>

- Add some more to the git ignore list
  ([`fe2bcc4`](https://github.com/goern/op1st-emea-b4mad/commit/fe2bcc4f58af3222bb753e73c40deb56d26e78f4))

Signed-off-by: Christoph Görn <goern@b4mad.net>
