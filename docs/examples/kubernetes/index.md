---
title: Kubernetes Samples
layout: default
nav_order: 2
parent: Examples
has_children: true
---

# Kubernetes Samples

Kubernetes manifests for common EKS workloads, networking, and storage patterns.

| Sample | Description |
|---|---|
| [DR Multi-Account](how-to-dr-multi-account/) | Disaster recovery across AWS accounts |
| [Troubleshoot Network Issues](how-to-tshoot-eks-intermittent-network-issues/) | Diagnose intermittent networking problems |
| [Fargate + OpenSearch Logging](how-to-logging-eks-fargate-opensearch/) | Ship Fargate pod logs to OpenSearch |
| [Snapshot / Restore / Resize STS](how-to-snapshot-restore-resize-sts/) | EBS volume operations for StatefulSets |
| [NFS CSI Driver](how-to-setup-nfs-csi-eks/) | Mount NFS shares as persistent volumes |
| [Topology Awareness Hints](how-to-topology-awareness-hints/) | Route traffic within the same AZ |
| [Backup & Restore EBS PVC](how-to-backup-restore-ebs-pvc/) | Back up and restore EBS-backed PVCs |
| [Network Policies](network-policies/) | Control pod-to-pod traffic with VPC CNI |
| [Proxy Protocol CLB](how-to-enable-proxy-procotcol-clb/) | Enable Proxy Protocol on Classic Load Balancer |
| [Python SDK in Containers](how-to-python-sdk-containers/) | Use the AWS SDK for Python inside pods |
| [vLLM LLM Serving on Graviton5](how-to-vllm-serving-graviton-eks-auto-mode/) | Serve an LLM on Graviton5 CPUs with vLLM on EKS Auto Mode |
