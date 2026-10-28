# Amazon EKS Samples

[![Checkov](https://github.com/aws-samples/aws-eks-samples/actions/workflows/checkov.yml/badge.svg?branch=main)](https://github.com/aws-samples/aws-eks-samples/actions/workflows/checkov.yml)
[![CodeQL](https://github.com/aws-samples/aws-eks-samples/actions/workflows/github-code-scanning/codeql/badge.svg?branch=main)](https://github.com/aws-samples/aws-eks-samples/actions/workflows/github-code-scanning/codeql)
[![GitHub Pages](https://github.com/aws-samples/aws-eks-samples/actions/workflows/pages/pages-build-deployment/badge.svg?branch=main)](https://github.com/aws-samples/aws-eks-samples/actions/workflows/pages/pages-build-deployment)
[![License: MIT-0](https://img.shields.io/badge/license-MIT--0-blue)](LICENSE)

Ready-to-use `eksctl` cluster configs, Kubernetes manifests, and Helm-based stacks for
learning and experimenting with [Amazon EKS](https://aws.amazon.com/eks/). Each sample is
self-contained, with its own README covering prerequisites, steps, and cleanup.

Browse the samples on the project site: **https://aws-samples.github.io/aws-eks-samples/**

> [!WARNING]
> These samples are for testing and learning only. Do not use them in production as is.
> Always follow the [Amazon EKS security best practices](https://docs.aws.amazon.com/eks/latest/best-practices/security.html).

## Samples

### eksctl

Cluster configuration files for creating and managing EKS clusters with [eksctl](https://eksctl.io/).

| Sample | Description |
|---|---|
| [Get started](examples/eksctl/how-to-get-started/) | Basic cluster with one managed and one self-managed node group |
| [EKS Auto Mode](examples/eksctl/how-to-eks-auto-mode/) | Cluster with EKS Auto Mode managing node provisioning, patching, and scaling |
| [Reuse an existing IAM role](examples/eksctl/how-to-existing-iamrole/) | Managed and unmanaged node groups that attach to a pre-existing IAM role |
| [Ubuntu node groups](examples/eksctl/how-to-ubuntu-nodegroups/) | Self-managed and managed node groups running Ubuntu |
| [EKS with Fargate](examples/eksctl/how-to-eks-fargate/) | Cluster with a Fargate profile for serverless pods |

### Kubernetes

Manifests for EKS workloads across storage, networking, security, observability, and disaster recovery.

| Sample | Description |
|---|---|
| [Backup and restore an EBS PVC](examples/kubernetes/how-to-backup-restore-ebs-pvc/) | Snapshot a PVC, restore it to a new PVC, and resize the restored volume |
| [Cross-account disaster recovery](examples/kubernetes/how-to-dr-multi-account/) | Restore an EBS snapshot into a cluster in another AWS account, including KMS-encrypted volumes |
| [Proxy Protocol on a Classic Load Balancer](examples/kubernetes/how-to-enable-proxy-procotcol-clb/) | Preserve client IP addresses through a CLB in front of NGINX Ingress |
| [Fargate logging to OpenSearch](examples/kubernetes/how-to-logging-eks-fargate-opensearch/) | Ship Fargate pod logs to Amazon OpenSearch Service with Fluent Bit |
| [AWS SDK for Python with IRSA](examples/kubernetes/how-to-python-sdk-containers/) | Call AWS APIs from a pod using IAM roles for service accounts |
| [NFS CSI driver with Amazon EFS](examples/kubernetes/how-to-setup-nfs-csi-eks/) | Dynamic EFS provisioning by subdirectory, without the EFS access point limit |
| [Snapshot, restore, and resize StatefulSet PVCs](examples/kubernetes/how-to-snapshot-restore-resize-sts/) | Back a Cassandra StatefulSet up to EBS snapshots, restore it, and resize its volumes |
| [Topology Aware Routing](examples/kubernetes/how-to-topology-awareness-hints/) | Keep Service traffic in the same Availability Zone to cut cross-AZ cost and latency |
| [Troubleshoot intermittent network issues](examples/kubernetes/how-to-tshoot-eks-intermittent-network-issues/) | `tcpdump` DaemonSet that streams node packet captures to Amazon S3 |
| [Network policies](examples/kubernetes/network-policies/) | Default-deny and allow-all `NetworkPolicy` building blocks for the Amazon VPC CNI |
| [vLLM on Graviton5](examples/kubernetes/how-to-vllm-serving-graviton-eks-auto-mode/) | Serve an LLM on Arm64 CPUs with EKS Auto Mode and a Karpenter `NodePool` |

### Helm

Stacks installed from community Helm charts with tuned `values.yaml` files.

| Sample | Description |
|---|---|
| [Karpenter observability on EKS Auto Mode](examples/helm/how-to-eks-auto-mode-karpenter-observability/) | Prometheus and Grafana with a 35-panel Karpenter Impact dashboard |

## Getting started

You need an AWS account and the tools your chosen sample lists, usually some of:
[AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html),
[kubectl](https://docs.aws.amazon.com/eks/latest/userguide/install-kubectl.html),
[eksctl](https://eksctl.io/installation/), and [Helm](https://helm.sh/docs/intro/install/).

```sh
git clone https://github.com/aws-samples/aws-eks-samples.git
cd aws-eks-samples

# Create an EKS Auto Mode cluster (us-west-2 by default; edit the file to change it)
eksctl create cluster -f examples/eksctl/how-to-eks-auto-mode/eks-auto.yaml

# Then pick a sample and follow its README
ls examples/kubernetes/
```

Samples create billable AWS resources. Run each sample's cleanup steps when you're done.

## Repository layout

```
examples/
├── eksctl/       # eksctl ClusterConfig files
├── kubernetes/   # Kubernetes manifests
└── helm/         # Helm-based stacks
docs/             # Static GitHub Pages site (served as is, no Jekyll build)
knowledge-center/ # Copy of the StatefulSet snapshot sample, kept for an AWS Knowledge Center article
```

`knowledge-center/how-to-snapshot-restore-resize-sts` is an exact copy of
[`examples/kubernetes/how-to-snapshot-restore-resize-sts`](examples/kubernetes/how-to-snapshot-restore-resize-sts/).
It stays at this path because the AWS Knowledge Center article
[EKS persistent storage snapshot](https://repost.aws/knowledge-center/eks-modify-persistent-storage-snapshot)
links to it. Change both copies together.

## Continuous integration

| Workflow | What it does |
|---|---|
| [Checkov](.github/workflows/checkov.yml) | Scans the manifests in `examples/kubernetes` with [Checkov](https://www.checkov.io/) and uploads the results to GitHub code scanning |
| [Knowledge Center](.github/workflows/knowledgecenter.yml) | Runs the same Checkov scan on `knowledge-center/` |
| CodeQL | GitHub default code scanning setup |
| pages-build-deployment | Publishes `docs/` to GitHub Pages |

<details>
<summary>Checkov checks skipped in this project, and why</summary>

The samples favor easy experimentation over production hardening, so these checks are skipped.
Apply them in your own clusters.

| Check | Description | Reason |
|---|---|---|
| CKV2_K8S_6 | Minimize the admission of pods that lack an associated NetworkPolicy | Pod-to-pod traffic is allowed by default to keep samples simple. The Amazon VPC CNI [supports Kubernetes network policies](https://aws.amazon.com/blogs/containers/amazon-vpc-cni-now-supports-kubernetes-network-policies/), and the [network policies sample](examples/kubernetes/network-policies/) shows how to use them. |
| CKV_K8S_8 | Liveness probe should be configured | Samples omit health checks. Configure [liveness probes](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/) in production. |
| CKV_K8S_9 | Readiness probe should be configured | Samples omit health checks. Configure readiness probes in production. |
| CKV_K8S_14 | Image tag should be fixed, not `latest` or blank | Some samples pull the latest public images so they run current versions. See the Kubernetes [security checklist for images](https://kubernetes.io/docs/concepts/security/security-checklist/). |
| CKV_K8S_21 | The default namespace should not be used | Short-lived samples use the `default` namespace and should be deleted after testing. Use dedicated [namespaces](https://kubernetes.io/docs/concepts/overview/working-with-objects/namespaces/) in production. |
| CKV_K8S_22 | Use a read-only root filesystem where possible | The Cassandra sample needs a writable filesystem. See [configure images with a read-only root filesystem](https://docs.aws.amazon.com/eks/latest/best-practices/pod-security.html). |
| CKV_K8S_23 | Minimize the admission of root containers | Samples use public images with their default user ID. Set a non-root [`USER`](https://docs.docker.com/reference/dockerfile/#user) in your own images. |
| CKV_K8S_25 | Minimize the admission of containers with added capabilities | The Cassandra sample adds `IPC_LOCK`. See [container capabilities](https://kubernetes.io/docs/tasks/configure-pod-container/security-context/). |
| CKV_K8S_28 | Minimize the admission of containers with the `NET_RAW` capability | Some workloads, such as NGINX and Cassandra, don't drop all capabilities. Enforce this in production with [Pod Security Admission](https://kubernetes.io/docs/concepts/security/pod-security-admission/). |
| CKV_K8S_35 | Prefer secrets as files over secrets as environment variables | The vLLM sample passes its API key as an environment variable for simplicity. In production, mount [secrets from AWS Secrets Manager and Parameter Store as files](https://docs.aws.amazon.com/eks/latest/userguide/manage-secrets.html). |
| CKV_K8S_37 | Minimize the admission of containers with assigned capabilities | Some workloads keep default or added capabilities. Grant only the [Linux capabilities](https://docs.aws.amazon.com/eks/latest/best-practices/pod-security.html) a process needs. |
| CKV_K8S_40 | Containers should run as a high UID to avoid host conflict | Samples use public images with their default user ID. [Set `runAsUser`](https://kubernetes.io/docs/tasks/configure-pod-container/security-context/) in production. |
| CKV_K8S_43 | Image should use a digest | Some samples pull the latest public images. In production, consider [pinning images by digest](https://kubernetes.io/docs/concepts/containers/images/). |

</details>

## Contributing

Issues and pull requests are welcome. See [CONTRIBUTING](CONTRIBUTING.md).

When you add, rename, or remove a sample, update the project site in `docs/` and the
samples tables in this README in the same pull request.
[`.kiro/steering/creating-samples.md`](.kiro/steering/creating-samples.md) has the checklist
and a script that checks the counts.

## Security

See [CONTRIBUTING](CONTRIBUTING.md#security-issue-notifications) for how to report a security issue.

## License

This library is licensed under the MIT-0 License. See the [LICENSE](LICENSE) file.
