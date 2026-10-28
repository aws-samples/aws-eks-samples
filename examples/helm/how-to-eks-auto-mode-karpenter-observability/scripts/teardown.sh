#!/bin/bash
# EKS Auto Mode Observability: Karpenter Impact Dashboard - teardown
# Removes everything setup.sh created, including the cluster-scoped RBAC.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
NAMESPACE="monitoring"

echo "Removing observability stack from namespace: $NAMESPACE"

helm uninstall grafana -n "$NAMESPACE" 2>/dev/null || true
helm uninstall prometheus -n "$NAMESPACE" 2>/dev/null || true
kubectl delete configmap grafana-dashboards -n "$NAMESPACE" --ignore-not-found
kubectl delete -f "$ROOT_DIR/manifests/rbac-eks-control-plane-metrics.yaml" --ignore-not-found
kubectl delete namespace "$NAMESPACE" --ignore-not-found

echo "Cleanup complete."
