#!/bin/bash
# EKS Auto Mode Observability: Karpenter Impact Dashboard - setup
# Deploys Prometheus and Grafana with EKS control plane metrics and the
# Karpenter Impact dashboard into the "monitoring" namespace.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
# manifests/rbac-eks-control-plane-metrics.yaml binds to this namespace.
NAMESPACE="monitoring"

# Pinned chart versions. Override with environment variables to try newer releases.
PROMETHEUS_CHART_REPO="https://prometheus-community.github.io/helm-charts"
PROMETHEUS_CHART_VERSION="${PROMETHEUS_CHART_VERSION:-29.39.0}"
GRAFANA_CHART_REPO="https://grafana-community.github.io/helm-charts"
GRAFANA_CHART_VERSION="${GRAFANA_CHART_VERSION:-14.2.0}"

echo "============================================"
echo " EKS Auto Mode Observability Stack Setup"
echo "============================================"

# --- Pre-flight checks ---
echo ""
echo "[1/6] Pre-flight checks..."
for cmd in kubectl helm; do
  if ! command -v "$cmd" &>/dev/null; then
    echo "ERROR: $cmd is required but not found in PATH"
    exit 1
  fi
done

CONTEXT=$(kubectl config current-context 2>/dev/null || true)
echo "  Cluster context: ${CONTEXT:-<none>}"
kubectl cluster-info --request-timeout=5s &>/dev/null || { echo "ERROR: Cannot connect to cluster"; exit 1; }

# EKS exposes control plane metrics under metrics.eks.amazonaws.com on Kubernetes 1.28+
if ! kubectl get --raw /apis/metrics.eks.amazonaws.com/v1 &>/dev/null; then
  echo "WARNING: metrics.eks.amazonaws.com API not found. Scheduler and controller-manager panels will be empty."
  echo "  This is expected for clusters running Kubernetes < 1.28 or non-EKS clusters."
fi

# --- Namespace ---
echo ""
echo "[2/6] Creating namespace..."
kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -

# --- RBAC for EKS control plane metrics ---
# RBAC is evaluated per request, so applying it before Prometheus starts means
# the first scrape already succeeds and no restart is needed.
echo ""
echo "[3/6] Granting Prometheus access to EKS control plane metrics..."
kubectl apply -f "$ROOT_DIR/manifests/rbac-eks-control-plane-metrics.yaml"

# --- Prometheus ---
echo ""
echo "[4/6] Deploying Prometheus (chart ${PROMETHEUS_CHART_VERSION})..."
helm upgrade --install prometheus prometheus \
  --repo "$PROMETHEUS_CHART_REPO" \
  --version "$PROMETHEUS_CHART_VERSION" \
  -n "$NAMESPACE" \
  -f "$ROOT_DIR/helm-values/prometheus-values.yaml" \
  --wait --timeout 5m

# --- Dashboard ConfigMap ---
echo ""
echo "[5/6] Creating Grafana dashboard ConfigMap..."
kubectl create configmap grafana-dashboards \
  -n "$NAMESPACE" \
  --from-file=karpenter-impact.json="$ROOT_DIR/dashboards/karpenter-impact.json" \
  --dry-run=client -o yaml | kubectl apply -f -

# --- Grafana ---
echo ""
echo "[6/6] Deploying Grafana (chart ${GRAFANA_CHART_VERSION})..."
helm upgrade --install grafana grafana \
  --repo "$GRAFANA_CHART_REPO" \
  --version "$GRAFANA_CHART_VERSION" \
  -n "$NAMESPACE" \
  -f "$ROOT_DIR/helm-values/grafana-values.yaml" \
  --wait --timeout 5m

# --- Verify control plane scrape targets ---
echo ""
echo "Checking EKS control plane scrape targets (the first scrape can take up to a minute)..."
TARGETS_PATH="/api/v1/namespaces/${NAMESPACE}/services/prometheus-server:80/proxy/api/v1/targets?state=active"
VERIFIED=false
if command -v python3 &>/dev/null; then
  for _ in {1..12}; do
    if RESULT=$(kubectl get --raw "$TARGETS_PATH" 2>/dev/null | python3 -c '
import json, sys
jobs = ("ksh-metrics", "kcm-metrics")
targets = [t for t in json.load(sys.stdin)["data"]["activeTargets"] if t["labels"].get("job") in jobs]
if not targets or any(t["health"] == "unknown" for t in targets):
    sys.exit(1)
for t in targets:
    print("  %-12s %-5s %s" % (t["labels"]["job"], t["health"], t.get("lastError", "")))
'); then
      echo "$RESULT"
      VERIFIED=true
      break
    fi
    sleep 10
  done
fi
if [ "$VERIFIED" != true ]; then
  echo "  Could not confirm target health. Check the Prometheus targets page manually:"
  echo "    kubectl -n $NAMESPACE port-forward svc/prometheus-server 9090:80"
  echo "    then open http://localhost:9090/targets"
fi

# --- Access ---
echo ""
echo "============================================"
echo " Deployment complete"
echo "============================================"
echo ""
echo "Grafana is ClusterIP only. Port-forward it to your workstation:"
echo "  kubectl -n $NAMESPACE port-forward svc/grafana 3000:80"
echo "Then open http://localhost:3000 and sign in as 'admin'. Read the generated password with:"
echo "  kubectl -n $NAMESPACE get secret grafana -o jsonpath='{.data.admin-password}' | base64 -d; echo"
echo ""
echo "Dashboard: Dashboards > EKS Auto Mode - Karpenter Impact"
echo "Allow 2-3 minutes for metrics to populate."
