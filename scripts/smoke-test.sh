#!/bin/bash
set -euo pipefail

echo "=== Smoke Test: Cluster Health ==="

# Check nodes are Ready
echo "Checking node status..."
NODES_READY=$(kubectl get nodes --no-headers | grep -c "Ready")
NODES_TOTAL=$(kubectl get nodes --no-headers | wc -l)

if [ "$NODES_READY" -ne "$NODES_TOTAL" ]; then
  echo "FAIL: Only $NODES_READY/$NODES_TOTAL nodes are Ready"
  kubectl get nodes
  exit 1
fi
echo "PASS: All $NODES_TOTAL nodes are Ready"

# Check system pods are running
# Check system pods are running
echo "Checking kube-system pods..."

# 1. Append "|| true" to prevent grep from crashing the script when 0 bad pods exist
# 2. Use [[:space:]] or clear formatting to prevent unexpected text matching
FAILING_PODS=$(kubectl get pods -n kube-system --no-headers | grep -v "Running\|Completed" | wc -l || true)

# Remove any accidental whitespace or padding from wc -l output
FAILING_PODS=$(echo "$FAILING_PODS" | tr -d ' ')

if [ "$FAILING_PODS" -gt 0 ]; then
  echo "FAIL: $FAILING_PODS system pods are not running"
  kubectl get pods -n kube-system
  exit 1
fi
echo "PASS: All system pods are healthy"


# Wait for smoke-test deployment rollout
echo "Waiting for nginx-smoke-test deployment..."
if ! kubectl rollout status deployment/nginx-smoke-test --timeout=90s; then
  echo "FAIL: Deployment did not become ready"
  kubectl describe deployment nginx-smoke-test
  kubectl get pods -l app=smoke-test
  exit 1
fi
echo "PASS: nginx-smoke-test deployment is ready"

# Verify pods are running with correct replica count
RUNNING=$(kubectl get pods -l app=smoke-test --no-headers | grep -c "Running")
if [ "$RUNNING" -lt 2 ]; then
  echo "FAIL: Expected 2 running pods, got $RUNNING"
  exit 1
fi
echo "PASS: $RUNNING/2 smoke-test pods running"

echo ""
echo "=== All Smoke Tests Passed ==="