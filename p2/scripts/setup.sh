#!/bin/bash

set -e

echo "---- Update and upgrade apt packages ----"
sudo apt update -y
sudo apt upgrade -y

echo "---- Install utilities ----"
sudo apt install -y curl wget git vim net-tools

echo "---- Install K3s server ----"
IFACE=$(ip -o -4 addr show | awk '/192\.168\.56\.110/ {print $2}')
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server \
    --node-ip=192.168.56.110 \
    --flannel-iface=$IFACE \
    --disable=metrics-server" sh -

echo "---- Waiting for node to be Ready ----"
until sudo kubectl get nodes 2>/dev/null | grep -q " Ready "; do
    echo "Waiting for node..."
    sleep 5
done

echo "---- Waiting for Traefik deployment to exist ----"
until sudo kubectl get deployment/traefik -n kube-system &>/dev/null; do
    echo "Waiting for traefik deployment..."
    sleep 5
done

echo "---- Waiting for Traefik to be available ----"
sudo kubectl wait --for=condition=Available deployment/traefik \
    --namespace kube-system --timeout=180s

echo "---- Applying app manifests ----"
sudo kubectl apply -f /vagrant/confs/

echo "---- Cluster status ----"
sudo kubectl get pods -A
sudo kubectl get ingress