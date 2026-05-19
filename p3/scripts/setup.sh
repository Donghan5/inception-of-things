#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFS_DIR="$SCRIPT_DIR/../confs"

# Verifying k3d cluster is already exists and if exists delete it
if k3d cluster list | grep -q "^iot"; then
    echo " === Deleting existing k3d cluster === "
    k3d cluster delete iot
fi

# Making K3d cluster and setting up kubectl context
echo "=== Setting up K3d cluster... ==="
k3d cluster create iot --wait

kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace dev --dry-run=client -o yaml | kubectl apply -f -

echo "=== Applying Argo CD manifest... ==="
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml --server-side

sleep 5

kubectl wait --for=condition=available deployment/argocd-server -n argocd --timeout=300s
kubectl wait --for=condition=available deployment/argocd-repo-server -n argocd --timeout=300s

kubectl apply -f $CONFS_DIR/application.yaml

echo ""
echo "=== Argo CD admin password ==="
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d && echo

echo ""
echo "=== Access Argo CD UI ==="
echo "Run: kubectl port-forward svc/argocd-server -n argocd 8080:443"
echo "Then open: https://localhost:8080 in your browser"
echo "Username: admin"