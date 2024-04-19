# What is ztp-prevalidate?

This repository contains an script that would help you te pre-validate the Manifests used by [Red Hat ZTP Gitops tools](), actually [Siteconfigs](https://docs.openshift.com/container-platform/4.10/scalability_and_performance/ztp-deploying-disconnected.html#ztp-deploying-a-site_ztp-deploying-disconnected) and [PolicyGenTemplates](https://docs.openshift.com/container-platform/4.10/scalability_and_performance/ztp-deploying-disconnected.html#ztp-the-policygentemplate_ztp-deploying-disconnected).

These two manifests can be pretty long/complex and potentially containing different errors about syntax or wrong usage. It wold be nice to pre-validate them before going to the usual Gitops workflow.

## How to install

You can just download the script (there is also a hook script that can be used together with Git) and execute it.

### Requirements

It is just a bash script but you will need:

- [Optional] ['yamllint' tool](https://github.com/adrienverge/yamllint)

- [Optional] [yq](https://github.com/mikefarah/yq)

If you dont have (or you cannot install) neither `yq` nor `yamllint` you will have to use the param `--disable-yaml-lint`. Both are used/combined for the yamllint validation feature.

- podman

- Connectivity to Openshift cluster (export KUBECONFIG=kubeconfig). You need this, because it will validate the generated Openshift/Kubernetes resources with the Openshift/Kubernetes API. Dont worry, it is just testing and it dont not persist anything in your cluster.

### Executing the script

You can just run the script on a directory containing a 'kustomization.yaml' file, which points to other yamls files. These files will be Manifests with Siteconfig or PolicyGenTemplate resources.

Optional parameters:
 * `--disable-yaml-lint`: this disable the usage of the tool yamllint. Maybe you dont have this tool. Disabling lint makes you to miss some errors you would be having. So, it should be disabled in case you cannot get the yamllint binary
 * `--disable-remote-check`: this disable the usage of a remote Openshift/Kubernetes API. In this case, you have to export the ZTP_SITE_GENERATOR_IMG env variable to point where to download ZTP Plugins. Useful, when you dont have access to the Openshift/Kubernetes API
 * `-local-generator-plugins`: in this case the generator plugins are not downloaded, export a env variable KUSTOMIZE_PLUGIN_HOME with a path to the

> disable-remote-check will detect less potential errors, and make the check less similar to what it is going to happen later on ArgoCD. In this case, the generated resources by the ZTP Plugins cannot be tested against a Openshift/Kubernetes API. So, the generator is invoked and captured any generation error.


```bash
$> <PATH_TO_SCRIPT>/pre-validate-manifests.sh .
Validating with ztp-site-generator: registry.redhat.io/openshift4/ztp-site-generate-rhel8:v4.10.0
=======================================================
| Cheking yaml syntax for files in kustomization.yaml |
=======================================================
     common-ranGen-4.10.yaml
     - yamllint validation: OK
     common-ranGen-4.9.yaml
     - yamllint validation: OK
     group-du-sno-ranGen.yaml
     - yamllint validation: OK
     site-specific-policies/sno-lenovo.yaml
     - yamllint validation: OK
     site-specific-policies/intel-1-sno-1.yaml
     - yamllint validation: OK
     site-specific-policies/intel-1-sno-1-test-dpdk.yaml
     - yamllint validation: OK
=======================================================
| Cheking ZTP Manifests in kustomization.yaml         |
=======================================================
     * Checking Siteconfig/PGT Manifests in kustomization.yaml: OK
Log details in: /tmp/pre-validate-error-5879.log
```

In this case yaml syntax validation and the manifests were correct, you can proceed with the usual Gitops workflow, to upload the changes to your cluster.

```bash
$> <PATH_TO_SCRIPT>/pre-validate-manifests.sh .
Validating with ztp-site-generator: registry.redhat.io/openshift4/ztp-site-generate-rhel8:v4.10.0
=======================================================
| Cheking yaml syntax for files in kustomization.yaml |
=======================================================
	 common-ranGen-4.10.yaml
	 - yamllint validation: OK
	 common-ranGen-4.9.yaml
	 - yamllint validation: OK
	 group-du-sno-ranGen.yaml
	 - yamllint validation: OK
	 site-specific-policies/sno-lenovo.yaml
	 - yamllint validation: OK
	 site-specific-policies/intel-1-sno-1.yaml
	 - yamllint validation: OK
	 site-specific-policies/intel-1-sno-1-test-dpdk.yaml
	 - yamllint validation: OK
	 common-error-check.yaml
	 - yamllint validation: Error
=======================================================
| Cheking ZTP Manifests in kustomization.yaml         |
=======================================================
	 * Checking Siteconfig/PGT Manifests in kustomization.yaml: Error
Log details in: /tmp/pre-validate-error-6339.log
```

Here we find some errors about syntax and the manifests:

```bash
> cat /tmp/pre-validate-error-16700.log
.//common-error-check.yaml
  69:39     error    trailing spaces  (trailing-spaces)
...
Error from server (Invalid): error when creating "STDIN": PlacementRule.apps.open-cluster-management.io "common-RanGen-4.10-placementrules" is invalid: metadata.name: Invalid value: "common-RanGen-4.10-placementrules": a lowercase RFC 1123 subdomain must consist of lower case alphanumeric characters, '-' or '.', and must start and end with an alphanumeric character (e.g. 'example.com', regex used for validation is '[a-z0-9]([-a-z0-9]*[a-z0-9])?(\.[a-z0-9]([-a-z0-9]*[a-z0-9])?)*')
Error from server (Invalid): error when creating "STDIN": PlacementBinding.policy.open-cluster-management.io "common-RanGen-4.10-placementbinding" is invalid: metadata.name: Invalid value: "common-RanGen-4.10-placementbinding": a lowercase RFC 1123 subdomain must consist of lower case alphanumeric characters, '-' or '.', and must start and end with an alphanumeric character (e.g. 'example.com', regex used for validation is '[a-z0-9]([-a-z0-9]*[a-z0-9])?(\.[a-z0-9]([-a-z0-9]*[a-z0-9])?)*')
Error from server (Invalid): error when creating "STDIN": Policy.policy.open-cluster-management.io "common-RanGen-4.10-config-policy" is invalid: metadata.name: Invalid value: "common-RanGen-4.10-config-policy": a lowercase RFC 1123 subdomain must consist of lower case alphanumeric characters, '-' or '.', and must start and end with an alphanumeric character (e.g. 'example.com', regex used for validation is '[a-z0-9]([-a-z0-9]*[a-z0-9])?(\.[a-z0-9]([-a-z0-9]*[a-z0-9])?)*')
Error from server (Invalid): error when creating "STDIN": Policy.policy.open-cluster-management.io "common-RanGen-4.10-subscriptions-policy" is invalid: metadata.name: Invalid value: "common-RanGen-4.10-subscriptions-policy": a lowercase RFC 1123 subdomain must consist of lower case alphanumeric characters, '-' or '.', and must start and end with an alphanumeric character (e.g. 'example.com', regex used for validation is '[a-z0-9]([-a-z0-9]*[a-z0-9])?(\.[a-z0-9]([-a-z0-9]*[a-z0-9])?)*')


```

Here we find some errors about syntax and also about the wrong usage of CRs (in this case PolicyGenTemplate).

There are more examples of errors below.

# More context about why this kind of validation is needed

*This section tries to give some feedback and experience, about, how this tool would be useful. It also, gives context about how the ZTP tools work, and it presents the script details. The script is just an idea that would be implemented in many different ways*

### How ZTP GitOps works

[Red Hat ZTP (Zero Touch Provisioning) GitOps](https://docs.openshift.com/container-platform/4.10/scalability_and_performance/ztp-deploying-disconnected.html) is a methodology that allows you to manage your cluster deployments/upgrading/monitoring using a GitOps workflow. Main components involved:

* ACM (Advanced Cluster Management): an Openshift/Kubernetes cluster which manages other Openshift/Kubernetes clusters.

* HIVE/AI: which allows ACM to deploy Openshift clusters.

  There exists other installers to deploy other kind of clusters. Or, to deploy clusters on specific cloud providers.

* ZTP tooling: basically a set of two Kustomize plugins, that allows you to manage two different CustomResources (Siteconfig/PolicyGentTemplate) to define your clusters and policies.

* ArgoCD: which manages the GitOps and syncs you resources with you management cluster. The two ZTP Kustomize plugins are installed inside.

As a summary:  a Git repository with sites and policies definitions. The repo is sync with ArgoCD, and the Kustomize plugins transform sites and policies into ACM resources to start the installation and upgrade.

This document presents an initial idea to validate these resources before going to Git. It would help you to make some pre-validations. but it is not something wide used or tested.

This document does not cover how to use and install ZTP. You can get more info [here](https://github.com/RHsyseng/telco-operations/tree/main/ztp/remote-worker-day0/ztp-policygentool) and with the official [Red Hat documentation](https://access.redhat.com/documentation/en-us/openshift_container_platform/4.9/html/scalability_and_performance/ztp-deploying-disconnected). This other article shows an example of [why to use ZTP](https://www.redhat.com/en/blog/absolute-zero-touch-because-you-cant-reach-all-way-edge)

## Why validating before going to GitOps is needed

ZTP with GitOps methodology implies these steps in your (daily) activities:

1) Design your sites and the policies to be applied to your clusters (versions, networking, dns, dhcp, etc)

2) Translate this into Siteconfig and PolicyGenTemplate resources. Stored on a Git Repository

3) Push your changes.

4) Maybe (good practice) your changes cannot be pushed to the branch synced with ArgoCD.

   1) You make a PR to that branch

   2) Some else will validate the PR

5) ArgoCD syncs the changes and here happens a real validation:

   1) Kustomize plugins will split SiteConfig/PolicyGenTemplate into ACM Resources. Some errors can be detected here if the Manifests are not correct.

   2) The generated ACM resources are applied to the Openshift cluster. More errors could happen here more related to Kubernetes.

6) If something was wrong the error stops all the process, and you have to go back to step 1) or 2). If everything is ok, the sync is done, ACM/Hive will make all the work for you.

The main validation happens on step 5, when a "machine" is trying to apply your resources. If it fails, you have to get back to your Manifests, check everything, make the push, make the PR and get the merge approved. All these steps, to try and validate again.

To create a SiteConfig/PolicyGenTemplate is not an easy task. These contains many fields and many fields potentially creates many point's of error. You can have a look on the CRD of [SiteConfig](https://github.com/openshift-kni/cnf-features-deploy/blob/master/ztp/ran-crd/site-config-crd.yaml) and [PGT](https://github.com/openshift-kni/cnf-features-deploy/blob/master/ztp/ran-crd/policy-gen-template-crd.yaml)

Therefore, you create your Manifests and push everything not been sure 100% is right until step 6). Sometimes you fail for very simple things: a typo, bad format in your yaml,  incorrect naming, a forgotten NS, etc. And of course, more advanced errors with Manifests not compliant with the CRD.

If you fail, you try to fix and you end up messing your git history with many unnecessary commits and wasting your time.

## Pre-validating before pushing

So, according the previous flow we could make a pre-validation during following steps:

* Step 3) Before pushing you changes an script would make a pre-validation.

* Step 4) Maybe you already have a kind of CI flow. So here it would be a good place.

* Step 4.2) maybe the PR is done manually by a person, ideally here there is a kind of CI that could make the validation

In this tutorial, a first try with a pretty simple [script](./pre-validate-manifests.sh) has been implemented.

# Pre-Validation script

This first implementation try includes a simple script that will make the validation. How does it works:

* It uses ['yamllint' tool](https://github.com/adrienverge/yamllint) to make a first yaml verification. It there are errors stops here.

  * Improvement: to verify only the files included in the kustomization

* It extracts the Kustomization plugins (for Siteconfig/PolicyGenTemplate) directly from [ZTP tools](https://github.com/openshift-kni/cnf-features-deploy/tree/master/ztp/ran-crd). These are directly extracted from the ZTP-site-generator Container Image.

  * Improvement: to dig into ArgoCD to check which Container Image is going to be used later. So you ensure, you make the pre-validation with the same tools than later will be used.

* Kustomization plugins are executed over an specific directory. These validates your Manifests are compliant with ZTP tooling

* The output from previous step has transformed int Siteconfig/PolicyGenTemplate CRs. These new Manifests are applied to the Openshift cluster with a [--dri-run=server](https://kubernetes.io/blog/2019/01/14/apiserver-dry-run-and-kubectl-diff/#apiserver-dry-run). In this way, the generated Manifests are passed to your cluster API-Server, but not applied. More errors are detected here.



## NameSpaces limitation and --dry-run

It is very well explained [here](https://github.com/kubernetes/kubernetes/issues/83562). Not a but, but a feature (or limitation)

The --dri-run=server will pass all the manifests to the API-Server but the resources are not persisted.

Resources depending on other resources (for example a NameSpace) will fail. The NameSpace problem: during the --dry-run the needed NameSpaces are created, but not persisted. Next objects that will be stored on that NS will fail.

* Workaround, the script will substitute the NameSpaces destinations to default one (that will always exists). Anyway, nothing will be created there, because during --dry-run nothing is persisted.

## Some errors detected by the script

Following some detected errors. The directory I am using it contains lots of Manifests:

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

generators:
  - sno3-e.yaml
  - sno4.yaml
  - sno3-e-4-10.yaml
  - sno4-e-4-10.yaml
  - sno5-e-4-9.yaml
  - el8k-ztp-1-3node.yaml
  - el8k-ztp-1-3node-ipv6.yaml
  - el8k-ztp-1-standard-ipv6.yaml
  - el8k-ztp-1-standard-ipv6-4-8.yaml
  - el8k-ztp-1-standard-4-8.yaml
  - el8k-ztp-1-standard.yaml
  - sno4-e-4-10-no-sctp.yaml
  - sno5-e-4-9-only-sctp.yaml
  - sno-b7-e-4-10-ipv4.yaml
  - sno-b8-e-4-10-ipv4.yaml
```

### Error lint: yaml linting

This directory contains many SiteConfigs, so I have summarized the output

```bash
./validate-manifests.sh ~/Projects-src/rh-gitlab/cnf-workload-certification/ztp-deployments/ZTP/HubClusters/el8k/SpokeClusters/ztp-gitops/gitop-repo/siteconfig/
Cheking yaml syntax
/home/jgato/Projects-src/rh-gitlab/cnf-workload-certification/ztp-deployments/ZTP/HubClusters/el8k/SpokeClusters/ztp-gitops/gitop-repo/siteconfig/el8k-ztp-1-3node-ipv6.yaml
  11:81     warning  line too long (606 > 80 characters)  (line-length)
  16:81     warning  line too long (127 > 80 characters)  (line-length)
  17:81     warning  line too long (95 > 80 characters)  (line-length)
  19:81     warning  line too long (109 > 80 characters)  (line-length)
  21:81     warning  line too long (118 > 80 characters)  (line-length)
  22:81     warning  line too long (101 > 80 characters)  (line-length)
  25:12     warning  too many spaces before colon  (colons)
  26:81     warning  line too long (103 > 80 characters)  (line-length)
  30:7      warning  wrong indentation: expected 4 but found 6  (indentation)
  33:7      warning  wrong indentation: expected 4 but found 6  (indentation)
  41:7      warning  wrong indentation: expected 4 but found 6  (indentation)
  52:13     warning  wrong indentation: expected 10 but found 12  (indentation)
  56:15     warning  wrong indentation: expected 12 but found 14  (indentation)
  64:21     warning  wrong indentation: expected 18 but found 20  (indentation)
  73:17     warning  wrong indentation: expected 14 but found 16  (indentation)
  87:13     warning  wrong indentation: expected 10 but found 12  (indentation)
  91:15     warning  wrong indentation: expected 12 but found 14  (indentation)
  99:21     warning  wrong indentation: expected 18 but found 20  (indentation)
  108:17    warning  wrong indentation: expected 14 but found 16  (indentation)
  122:13    warning  wrong indentation: expected 10 but found 12  (indentation)
  126:15    warning  wrong indentation: expected 12 but found 14  (indentation)
  134:21    warning  wrong indentation: expected 18 but found 20  (indentation)
  143:17    warning  wrong indentation: expected 14 but found 16  (indentation)
...
...

/home/jgato/Projects-src/rh-gitlab/cnf-workload-certification/ztp-deployments/ZTP/HubClusters/el8k/SpokeClusters/ztp-gitops/gitop-repo/siteconfig/temp/out2/ztp/gitops-subscriptions/argocd/deployment/hook-cluster-sub-binding.yaml
  5:26      error    trailing spaces  (trailing-spaces)

/home/jgato/Projects-src/rh-gitlab/cnf-workload-certification/ztp-deployments/ZTP/HubClusters/el8k/SpokeClusters/ztp-gitops/gitop-repo/siteconfig/temp/out2/ztp/gitops-subscriptions/argocd/deployment/hook-policies-sub-acm-binding.yaml
  11:62     error    trailing spaces  (trailing-spaces)

...
...
/home/jgato/Projects-src/rh-gitlab/cnf-workload-certification/ztp-deployments/ZTP/HubClusters/el8k/SpokeClusters/ztp-gitops/gitop-repo/siteconfig/temp/out2/ztp/ztp-policy-generator/kustomize/plugin/policyGenerator/v1/policygenerator/testData/TestSriovNetwork/templates/TestSriovNetwork.yaml
  5:81      warning  line too long (134 > 80 characters)  (line-length)
  22:8      warning  wrong indentation: expected 8 but found 7  (indentation)
  24:8      warning  wrong indentation: expected 8 but found 7  (indentation)
  25:17     error    no new line character at the end of file  (new-line-at-end-of-file)
```

This first try it points to some errors about trailing spaces or newlines. This is not critical, and ZTP will not fail, but why not to fix this?

### Error in CRs: not existing Manifests

After some linting my Manifests, the process continues the Kustomize plugins detect some errors:

```yaml
Checking Management cluster connectivity
Checking Siteconfig/PGT Manifests with Kustomize plugins
2db2b69f422b00526bfd5f9852829797e2a22f2a751e9eea4976f5e680e2b849
Error: loading generator plugins: accumulation err='accumulating resources from 'sno3-e.yaml': evalsymlink failure on '/home/jgato/Projects-src/rh-gitlab/cnf-workload-certification/ztp-deployments/ZTP/HubClusters/el8k/SpokeClusters/ztp-gitops/gitop-repo/siteconfig/sno3-e.yaml' : lstat /home/jgato/Projects-src/rh-gitlab/cnf-workload-certification/ztp-deployments/ZTP/HubClusters/el8k/SpokeClusters/ztp-gitops/gitop-repo/siteconfig/sno3-e.yaml: no such file or directory': evalsymlink failure on '/home/jgato/Projects-src/rh-gitlab/cnf-workload-certification/ztp-deployments/ZTP/HubClusters/el8k/SpokeClusters/ztp-gitops/gitop-repo/siteconfig/sno3-e.yaml' : lstat /home/jgato/Projects-src/rh-gitlab/cnf-workload-certification/ztp-deployments/ZTP/HubClusters/el8k/SpokeClusters/ztp-gitops/gitop-repo/siteconfig/sno3-e.yaml: no such file or directory
error: no objects passed to apply
Error processing manifests
```

It seems the Kustomization file include Manifests not existing:

```bash
> ls /home/jgato/Projects-src/rh-gitlab/cnf-workload-certification/ztp-deployments/ZTP/HubClusters/el8k/SpokeClusters/ztp-gitops/gitop-repo/siteconfig/sno3-e.yaml
ls: cannot access '/home/jgato/Projects-src/rh-gitlab/cnf-workload-certification/ztp-deployments/ZTP/HubClusters/el8k/SpokeClusters/ztp-gitops/gitop-repo/siteconfig/sno3-e.yaml': No such file or directory
```

This file does not exists, so, we can delete it from the Kustomization file:

```yaml
> cat ~/Projects-src/rh-gitlab/cnf-workload-certification/ztp-deployments/ZTP/HubClusters/el8k/SpokeClusters/ztp-gitops/gitop-repo/siteconfig/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

generators:
  #- sno3-e.yaml
  - sno4.yaml
  - sno3-e-4-10.yaml
  - sno4-e-4-10.yaml
  - sno5-e-4-9.yaml
  - el8k-ztp-1-3node.yaml
  - el8k-ztp-1-3node-ipv6.yaml
  - el8k-ztp-1-standard-ipv6.yaml
  - el8k-ztp-1-standard-ipv6-4-8.yaml
  - el8k-ztp-1-standard-4-8.yaml
  - el8k-ztp-1-standard.yaml
  - sno4-e-4-10-no-sctp.yaml
  - sno5-e-4-9-only-sctp.yaml
  - sno-b7-e-4-10-ipv4.yaml
  - sno-b8-e-4-10-ipv4.yaml
```

### Error in CRs: Duplicated resources

Different yaml with Siteconfig pointing to the same resource:

```bash
Checking Management cluster connectivity
Checking Siteconfig/PGT Manifests with Kustomize plugins
a2cbaf1f151ae7d490a9987511e35522813004c4a76e5f87d4372606d907dd57
Error: loading generator plugins: accumulation err='merging resources from 'el8k-ztp-1-standard-ipv6.yaml': may not add resource with an already registered id: ran.openshift.io_v1_SiteConfig|el8k-ztp-1|el8k-ztp-1': got file 'el8k-ztp-1-standard-ipv6.yaml', but '/home/jgato/Projects-src/rh-gitlab/cnf-workload-certification/ztp-deployments/ZTP/HubClusters/el8k/SpokeClusters/ztp-gitops/gitop-repo/siteconfig/el8k-ztp-1-standard-ipv6.yaml' must be a directory to be a root
error: no objects passed to apply
Error processing manifests
```

The name 'el8k-ztp-1' is used in more than one Manifest that you are trying to apply:

```bash
> grep 'name: "el8k-ztp-1"'  ~/Projects-src/rh-gitlab/cnf-workload-certification/ztp-deployments/ZTP/HubClusters/el8k/SpokeClusters/ztp-gitops/gitop-repo/siteconfig/*
/home/jgato/Projects-src/rh-gitlab/cnf-workload-certification/ztp-deployments/ZTP/HubClusters/el8k/SpokeClusters/ztp-gitops/gitop-repo/siteconfig/el8k-ztp-1-3node-ipv6.yaml:  name: "el8k-ztp-1"
/home/jgato/Projects-src/rh-gitlab/cnf-workload-certification/ztp-deployments/ZTP/HubClusters/el8k/SpokeClusters/ztp-gitops/gitop-repo/siteconfig/el8k-ztp-1-3node.yaml:  name: "el8k-ztp-1"
/home/jgato/Projects-src/rh-gitlab/cnf-workload-certification/ztp-deployments/ZTP/HubClusters/el8k/SpokeClusters/ztp-gitops/gitop-repo/siteconfig/el8k-ztp-1-standard-4-8.yaml:  name: "el8k-ztp-1"
/home/jgato/Projects-src/rh-gitlab/cnf-workload-certification/ztp-deployments/ZTP/HubClusters/el8k/SpokeClusters/ztp-gitops/gitop-repo/siteconfig/el8k-ztp-1-standard-ipv6-4-8.yaml:  name: "el8k-ztp-1"
/home/jgato/Projects-src/rh-gitlab/cnf-workload-certification/ztp-deployments/ZTP/HubClusters/el8k/SpokeClusters/ztp-gitops/gitop-repo/siteconfig/el8k-ztp-1-standard-ipv6.yaml:  name: "el8k-ztp-1"
/home/jgato/Projects-src/rh-gitlab/cnf-workload-certification/ztp-deployments/ZTP/HubClusters/el8k/SpokeClusters/ztp-gitops/gitop-repo/siteconfig/el8k-ztp-1-standard.yaml:  name: "el8k-ztp-1"
```

This is because I have different yamls, to install the same site with different configurations. Of course, I install only one at the same time. I have to fix my Kustomization file to include only one:

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

generators:
  #- sno3-e.yaml
  - sno4.yaml
  - sno3-e-4-10.yaml
  - sno4-e-4-10.yaml
  - sno5-e-4-9.yaml
  - el8k-ztp-1-3node.yaml
  #- el8k-ztp-1-3node-ipv6.yaml
  #- el8k-ztp-1-standard-ipv6.yaml
  #- el8k-ztp-1-standard-ipv6-4-8.yaml
  #- el8k-ztp-1-standard-4-8.yaml
  #- el8k-ztp-1-standard.yaml
  #- sno4-e-4-10-no-sctp.yaml
  #- sno5-e-4-9-only-sctp.yaml
  - sno-b7-e-4-10-ipv4.yaml
  - sno-b8-e-4-10-ipv4.yaml
```

### Error in Kubernetes: naming sintax

How you name your resources:

```yaml
Checking Management cluster connectivity
Checking Siteconfig/PGT Manifests with Kustomize plugins
99936ac9e4c4386c29cfafc3ef2a2dce2b3064c1e0c4e22faa352b20df0d3689
namespace/el8k-ztp-1 configured (server dry run)
namespace/sno-b7 configured (server dry run)
namespace/sno-b8 configured (server dry run)
...
...
baremetalhost.metal3.io/sno-b8.el8k-1.hpecloud.org created (server dry run)
baremetalhost.metal3.io/sno3.el8k-1.hpecloud.org created (server dry run)
baremetalhost.metal3.io/sno5.el8k-1.hpecloud.org created (server dry run)
Error from server (Invalid): error when creating "STDIN": Namespace "SNO4" is invalid: metadata.name: Invalid value: "SNO4": a lowercase RFC 1123 label must consist of lower case alphanumeric characters or '-', and must start and end with an alphanumeric character (e.g. 'my-name',  or '123-abc', regex used for validation is '[a-z0-9]([-a-z0-9]*[a-z0-9])?')
Error from server (Invalid): error when creating "STDIN": ConfigMap "SNO4" is invalid: metadata.name: Invalid value: "SNO4": a lowercase RFC 1123 subdomain must consist of lower case alphanumeric characters, '-' or '.', and must start and end with an alphanumeric character (e.g. 'example.com', regex used for validation is '[a-z0-9]([-a-z0-9]*[a-z0-9])?(\.[a-z0-9]([-a-z0-9]*[a-z0-9])?)*')
Error from server (Invalid): error when creating "STDIN": InfraEnv.agent-install.openshift.io "SNO4" is invalid: metadata.name: Invalid value: "SNO4": a lowercase RFC 1123 subdomain must consist of lower case alphanumeric characters, '-' or '.', and must start and end with an alphanumeric character (e.g. 'example.com', regex used for validation is '[a-z0-9]([-a-z0-9]*[a-z0-9])?(\.[a-z0-9]([-a-z0-9]*[a-z0-9])?)*')
Error from server (Invalid): error when creating "STDIN": KlusterletAddonConfig.agent.open-cluster-management.io "SNO4" is invalid: metadata.name: Invalid value: "SNO4": a lowercase RFC 1123 subdomain must consist of lower case alphanumeric characters, '-' or '.', and must start and end with an alphanumeric character (e.g. 'example.com', regex used for validation is '[a-z0-9]([-a-z0-9]*[a-z0-9])?(\.[a-z0-9]([-a-z0-9]*[a-z0-9])?)*')
Error from server (Invalid): error when creating "STDIN": ManagedCluster.cluster.open-cluster-management.io "SNO4" is invalid: metadata.name: Invalid value: "SNO4": a lowercase RFC 1123 subdomain must consist of lower case alphanumeric characters, '-' or '.', and must start and end with an alphanumeric character (e.g. 'example.com', regex used for validation is '[a-z0-9]([-a-z0-9]*[a-z0-9])?(\.[a-z0-9]([-a-z0-9]*[a-z0-9])?)*')
Error from server (Invalid): error when creating "STDIN": AgentClusterInstall.extensions.hive.openshift.io "SNO4" is invalid: metadata.name: Invalid value: "SNO4": a lowercase RFC 1123 subdomain must consist of lower case alphanumeric characters, '-' or '.', and must start and end with an alphanumeric character (e.g. 'example.com', regex used for validation is '[a-z0-9]([-a-z0-9]*[a-z0-9])?(\.[a-z0-9]([-a-z0-9]*[a-z0-9])?)*')
Error from server (Invalid): error when creating "STDIN": ClusterDeployment.hive.openshift.io "SNO4" is invalid: metadata.name: Invalid value: "SNO4": a lowercase RFC 1123 subdomain must consist of lower case alphanumeric characters, '-' or '.', and must start and end with an alphanumeric character (e.g. 'example.com', regex used for validation is '[a-z0-9]([-a-z0-9]*[a-z0-9])?(\.[a-z0-9]([-a-z0-9]*[a-z0-9])?)*')
Error processing manifests
```

So 'clustername' in the SiteConfig needs to be lowercased:

```yaml
...
    clusters:
  - clusterName: "sno4"
    networkType: "OVNKubernetes"
    clusterLabels:
...
```

### Error in Kuberentes: type errors

There are type validations that can be detected:

```yaml
The PlacementRule "extra-intel-1-sno-1-placementrules" is invalid: spec.clusterSelector.matchExpressions.values: Invalid value: "boolean": spec.clusterSelector.matchExpressions.values in body must be of type string: "boolean"
```
Because there are no booleans, instead use an string.


# Using the script with Git hooks

For this initial idea, we can create a Git hook for 'pre-commit' that executes our validation script.  Maybe with commits it will be executed to often, and you can use the pre-push hook.

The hook is not too complex, but it test if the commit you are doing makes changes on Siteconfig and/or PolicyGenTemplates.

```bash
#!/usr/bin/sh
#
# hook to verify if ZTP CRs are valid
#exit 0
#set -e
SITECONFIGS=ZTP/HubClusters/el8k/SpokeClusters/ztp-gitops/gitop-repo/siteconfig
PGTS=ZTP/HubClusters/el8k/SpokeClusters/ztp-gitops/gitop-repo/policygentemplates
VERIFY_SCRIPT=/home/jgato/Projects-src/my_github/ztp-prevalidate/pre-validate-manifests.sh
ERROR=0

# just check if it is the first commit
if git rev-parse --verify HEAD >/dev/null 2>&1
then
    against=HEAD
else
    # Initial commit: diff against an empty tree object
    against=$(git hash-object -t tree /dev/null)
fi

# lets do the pre-validation but only on the proper directory

if git diff --name-only --cached | grep "${SITECONFIGS}"
then
    echo "Pre validation of Siteconfigs directory"
    (${VERIFY_SCRIPT} ${SITECONFIGS}) 1>/dev/null
fi
if [[ $? != 0  ]]; then
    echo "Error processing Siteconfig"
    ERROR=1
fi

if git diff --name-only --cached | grep "${PGTS}"
then
    echo "Pre validation of PolicyGenTemplates directory"
    (${VERIFY_SCRIPT} ${PGTS}) 1>/dev/null
fi
if [[ $? != 0  ]]; then
    echo "Error processing PolicyGenTemplates"
    ERROR=1
fi

exit $ERROR
```

You can find the hook also [here](./pre-commit.sample)

It only needs to configure the directories for the CRs and the script. It has to be placed on  '.git/hooks/pre-commit'

Lets modify our Manifests to include some of the previous errors.

First of all our git status is "clean". It does not contain any staged changed affecting to our two objective directories:

```bash
> git status
On branch main
Your branch is up to date with 'origin/main'.

Changes not staged for commit:
  (use "git add <file>..." to update what will be committed)
  (use "git restore <file>..." to discard changes in working directory)
    modified:   ../../../resources-scripts/prepare-ztp-cluster.sh
    modified:   ../../../../../Profiles/KDump/README.md
```

Some modified files, but not under the control of the hook.

Lets change one siteconfig cluster name to something wrong:

Wrong name on one of our clusters:

```yaml
> cat siteconfig/sno-b7-e-4-10-ipv4.yaml
apiVersion: ran.openshift.io/v1
kind: SiteConfig
metadata:
  name: "sno-b7"
  namespace: "sno-b7"
spec:
  baseDomain: "el8k-1.hpecloud.org"
  pullSecretRef:
    name: "assisted-deployment-pull-secret"
  clusterImageSetNameRef: "img4.10.5-x86-64-appsub"
  sshPublicKey: "ssh-rsa AA...hpecloud.org"
  clusters:
  - clusterName: "SNO-b7"
    networkType: "OVNKubernetes"
    clusterLabels:
```

Notice the error in 'clusterName: "SNO-b7'

The script will try to find as much errors as possible by commit. So lets include also an error on the PolicyGenTemplates. For example: adding to kustomization file, a PolicyGenTemplate that does not exists:

```yaml
> cat policygentemplates/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

generators:
  - group-du-sno.yaml
...
...
  - not-existing.yaml
resources:
- ns.yaml
```

Notice the not existing file called 'not-existing.yaml'

We add both modified files and commit:

```bash
$> git add siteconfig/sno-b7-e-4-10-ipv4.yaml policygentemplates/kustomization.yaml

$> git commit
ZTP/HubClusters/el8k/SpokeClusters/ztp-gitops/gitop-repo/siteconfig/sno-b7-e-4-10-ipv4.yaml
Pre validation of Siteconfigs directory
Error from server (Invalid): error when creating "STDIN": Namespace "SNO-b7" is invalid: metadata.name: Invalid value: "SNO-b7": a lowercase RFC 1123 label must consist of lower case alphanumeric characters or '-', and must start and end with an alphanumeric character (e.g. 'my-name',  or '123-abc', regex used for validation is '[a-z0-9]([-a-z0-9]*[a-z0-9])?')
Error from server (Invalid): error when creating "STDIN": ConfigMap "SNO-b7" is invalid: metadata.name: Invalid value: "SNO-b7": a lowercase RFC 1123 subdomain must consist of lower case alphanumeric characters, '-' or '.', and must start and end with an alphanumeric character (e.g. 'example.com', regex used for validation is '[a-z0-9]([-a-z0-9]*[a-z0-9])?(\.[a-z0-9]([-a-z0-9]*[a-z0-9])?)*')
Error from server (Invalid): error when creating "STDIN": InfraEnv.agent-install.openshift.io "SNO-b7" is invalid: metadata.name: Invalid value: "SNO-b7": a lowercase RFC 1123 subdomain must consist of lower case alphanumeric characters, '-' or '.', and must start and end with an alphanumeric character (e.g. 'example.com', regex used for validation is '[a-z0-9]([-a-z0-9]*[a-z0-9])?(\.[a-z0-9]([-a-z0-9]*[a-z0-9])?)*')
Error from server (Invalid): error when creating "STDIN": KlusterletAddonConfig.agent.open-cluster-management.io "SNO-b7" is invalid: metadata.name: Invalid value: "SNO-b7": a lowercase RFC 1123 subdomain must consist of lower case alphanumeric characters, '-' or '.', and must start and end with an alphanumeric character (e.g. 'example.com', regex used for validation is '[a-z0-9]([-a-z0-9]*[a-z0-9])?(\.[a-z0-9]([-a-z0-9]*[a-z0-9])?)*')
Error from server (Invalid): error when creating "STDIN": ManagedCluster.cluster.open-cluster-management.io "SNO-b7" is invalid: metadata.name: Invalid value: "SNO-b7": a lowercase RFC 1123 subdomain must consist of lower case alphanumeric characters, '-' or '.', and must start and end with an alphanumeric character (e.g. 'example.com', regex used for validation is '[a-z0-9]([-a-z0-9]*[a-z0-9])?(\.[a-z0-9]([-a-z0-9]*[a-z0-9])?)*')
Error from server (Invalid): error when creating "STDIN": AgentClusterInstall.extensions.hive.openshift.io "SNO-b7" is invalid: metadata.name: Invalid value: "SNO-b7": a lowercase RFC 1123 subdomain must consist of lower case alphanumeric characters, '-' or '.', and must start and end with an alphanumeric character (e.g. 'example.com', regex used for validation is '[a-z0-9]([-a-z0-9]*[a-z0-9])?(\.[a-z0-9]([-a-z0-9]*[a-z0-9])?)*')
Error from server (Invalid): error when creating "STDIN": ClusterDeployment.hive.openshift.io "SNO-b7" is invalid: metadata.name: Invalid value: "SNO-b7": a lowercase RFC 1123 subdomain must consist of lower case alphanumeric characters, '-' or '.', and must start and end with an alphanumeric character (e.g. 'example.com', regex used for validation is '[a-z0-9]([-a-z0-9]*[a-z0-9])?(\.[a-z0-9]([-a-z0-9]*[a-z0-9])?)*')
Error processing Siteconfig
ZTP/HubClusters/el8k/SpokeClusters/ztp-gitops/gitop-repo/policygentemplates/kustomization.yaml
Pre validation of PolicyGenTemplates directory
Error: loading generator plugins: accumulation err='accumulating resources from 'not-existing.yaml': evalsymlink failure on '/home/jgato/Projects-src/rh-gitlab/cnf-workload-certification/ztp-deployments/ZTP/HubClusters/el8k/SpokeClusters/ztp-gitops/gitop-repo/policygentemplates/not-existing.yaml' : lstat /home/jgato/Projects-src/rh-gitlab/cnf-workload-certification/ztp-deployments/ZTP/HubClusters/el8k/SpokeClusters/ztp-gitops/gitop-repo/policygentemplates/not-existing.yaml: no such file or directory': evalsymlink failure on '/home/jgato/Projects-src/rh-gitlab/cnf-workload-certification/ztp-deployments/ZTP/HubClusters/el8k/SpokeClusters/ztp-gitops/gitop-repo/policygentemplates/not-existing.yaml' : lstat /home/jgato/Projects-src/rh-gitlab/cnf-workload-certification/ztp-deployments/ZTP/HubClusters/el8k/SpokeClusters/ztp-gitops/gitop-repo/policygentemplates/not-existing.yaml: no such file or directory
error: no objects passed to apply
Error processing PolicyGenTemplates
```

The two errors are captured and the commit is aborted :)
