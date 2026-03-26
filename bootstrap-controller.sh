#!/bin/bash
# bootstrap-controller.sh
# Run this ONCE on spark-01 (the control-plane node) to self-configure the entire cluster.
#
# What it does:
#   1. Installs ansible-core and git via apt
#   2. Clones this repo (if not already present)
#   3. Runs ansible-playbook site.yml — which:
#        - bootstraps OS prereqs on all nodes (SSH from controller to workers)
#        - installs NVIDIA toolkit on all nodes
#        - initialises the k8s control-plane (kubeadm init)
#        - joins worker nodes (SSH from controller to workers)
#        - configures the controller: Helm, CRDs, Envoy Gateway, Kuadrant, llm-d, Magpie TTS
#
# Prerequisites on spark-01 before running:
#   - SSH key at ~/.ssh/id_rsa with access to spark-02 (worker)
#   - spark-02 reachable by hostname "spark-02" (or update ansible/inventory/hosts.yml)
#   - Internet access for package downloads
#
# Usage:
#   ssh nvidia@spark-01
#   curl -fsSL https://raw.githubusercontent.com/elizabetht/homelab/main/bootstrap-controller.sh | bash
#   # or after cloning:
#   bash bootstrap-controller.sh

set -euo pipefail

REPO_URL="https://github.com/elizabetht/homelab.git"
REPO_DIR="${HOME}/homelab"

echo "==> [1/4] Installing Ansible and git..."
sudo apt-get update -qq
sudo apt-get install -y --no-install-recommends \
  ansible-core \
  git \
  python3-pip

echo "==> [2/4] Cloning homelab repo..."
if [[ -d "${REPO_DIR}/.git" ]]; then
  echo "    Repo already exists at ${REPO_DIR} — pulling latest..."
  git -C "${REPO_DIR}" pull --ff-only
else
  git clone "${REPO_URL}" "${REPO_DIR}"
fi

echo "==> [3/4] Installing Ansible community.general collection (needed for modprobe module)..."
ansible-galaxy collection install community.general --upgrade

echo "==> [4/4] Running full cluster playbook..."
cd "${REPO_DIR}"
ansible-playbook \
  -i ansible/inventory/hosts.yml \
  ansible/site.yml \
  --ask-become-pass

echo ""
echo "==> Done! Cluster is up. Verify with:"
echo "    kubectl get nodes"
echo "    kubectl get pods -A"
