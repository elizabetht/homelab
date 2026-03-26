# homelab-monitoring

Flux v2 GitOps manifests for deploying `kube-prometheus-stack` (Prometheus + Grafana + Alertmanager) into a home lab Kubernetes cluster.

## Stack

| Component | Chart | Source |
|-----------|-------|--------|
| Prometheus | kube-prometheus-stack | prometheus-community |
| Grafana | bundled in kube-prometheus-stack | prometheus-community |
| Alertmanager | bundled in kube-prometheus-stack | prometheus-community |
| Node Exporter | bundled in kube-prometheus-stack | prometheus-community |
| kube-state-metrics | bundled in kube-prometheus-stack | prometheus-community |

## Directory Structure

```
clusters/homelab/
├── flux-system/
│   └── gotk-sync.yaml          # GitRepository pointing to this repo
└── monitoring/
    ├── namespace.yaml           # monitoring namespace
    ├── kustomization.yaml       # Flux Kustomization CRDs
    └── sources/
        └── prometheus-community.yaml  # HelmRepository

infrastructure/monitoring/
├── prometheus/
│   ├── helmrelease.yaml         # kube-prometheus-stack HelmRelease
│   ├── values.yaml              # homelab-tuned values
│   └── kustomization.yaml
└── grafana/
    ├── grafana-secret.yaml      # Admin credentials Secret
    ├── helmrelease.yaml         # Optional standalone Grafana (commented out)
    └── kustomization.yaml
```

## Prerequisites

- Kubernetes cluster (k3s, kind, kubeadm, etc.)
- Flux v2 installed (`flux bootstrap` or `flux install`)
- `kubectl` configured for your cluster

## Quick Start

### 1. Update Grafana credentials

Edit `infrastructure/monitoring/grafana/grafana-secret.yaml` and replace the base64-encoded password:

```bash
echo -n 'your-secure-password' | base64
```

> **Security note:** For production use, consider [Sealed Secrets](https://github.com/bitnami-labs/sealed-secrets) or [External Secrets Operator](https://external-secrets.io) instead of committing plain Secrets.

### 2. Bootstrap Flux (if not already done)

```bash
flux bootstrap git \
  --url=<YOUR_REPO_URL> \
  --branch=main \
  --path=clusters/homelab
```

### 3. Update the GitRepository URL

Edit `clusters/homelab/flux-system/gotk-sync.yaml` and replace `<REPO_URL>` with your actual repository URL.

### 4. Apply the Kustomizations

```bash
kubectl apply -f clusters/homelab/monitoring/kustomization.yaml
```

Flux will reconcile and deploy everything automatically.

## Enabling Persistent Storage

Uncomment the `storageSpec` / `persistence` sections in `infrastructure/monitoring/prometheus/values.yaml` and set your `storageClassName` (e.g. `local-path` for k3s).

## Accessing Grafana

```bash
# Port-forward Grafana
kubectl port-forward -n monitoring svc/kube-prometheus-stack-grafana 3000:80

# Then open http://localhost:3000
# Default login: admin / (password from your Secret)
```

## Accessing Prometheus

```bash
kubectl port-forward -n monitoring svc/kube-prometheus-stack-prometheus 9090:9090
# Open http://localhost:9090
```
