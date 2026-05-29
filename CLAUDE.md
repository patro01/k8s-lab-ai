# Claude.md — k8s-lab-ai

## Environment
**KinD cluster, 3 nodes:** lab-control-plane (control), lab-worker, lab-worker2  
**Namespaces:** default, kube-system, local-path-storage, app-prod, app-staging, monitoring  
**App:** nginx-smoke-test (2 replicas, default ns) + core Kubernetes components

## Healthy State
- All pods: `Running` with `Ready: True`
- Expected: ~15 pods total (2 nginx + 9 in kube-system + 1 storage)
- All nodes: `Ready` condition True

## Diagnostics: Probe Timeouts + HTTP 500
**Pattern:** kube-apiserver, kube-scheduler, kube-controller-manager, etcd, coredns fail with timeouts/500s  
**Root cause:** etcd slow → kube-apiserver hangs → cascade failure  
**Steps:** (1) Check kube-apiserver logs for etcd timeouts (2) Check etcd logs (3) Check node pressure (4) Review events timeline

## Guardrails
✓ Safe: `kubectl get/describe/logs` (read-only)  
✗ Ask first: `kubectl apply/create/delete/scale/restart`  
✗ Never: `delete --all`, direct etcd ops
