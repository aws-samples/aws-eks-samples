---
title: Home
layout: home
nav_order: 1
---

# Amazon EKS Samples

> **Status:** Work-in-progress. Please [create issues or pull requests](https://github.com/aws-samples/aws-eks-samples/issues) if you have ideas for improvement.

Example manifests for different workloads you can deploy in an Amazon EKS cluster.

## What's included

This project provides ready-to-use examples across three categories:

| Category | Description |
|---|---|
| [Eksctl Samples](examples/eksctl/) | Cluster config files for common EKS setups |
| [Kubernetes manifests](examples/kubernetes/) | Workload samples, networking, storage |
| [Helm charts](examples/helm/) | Helm-based deployments |

## Getting started

1. Clone the repository:
   ```bash
   git clone https://github.com/aws-samples/aws-eks-samples.git
   cd aws-eks-samples
   ```

2. Browse the examples in each subdirectory and apply using `kubectl apply -f` or `eksctl create cluster -f`.

## Disclaimer

{: .warning }
These examples are for **testing and learning purposes only**. Do not use in a production environment. Always refer to [Amazon EKS Security Best Practices](https://aws.github.io/aws-eks-best-practices/security/docs/) when using Amazon EKS.

## License

This library is licensed under the MIT-0 License. See the [LICENSE](https://github.com/aws-samples/aws-eks-samples/blob/main/LICENSE) file.
