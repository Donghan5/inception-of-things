#!/bin/bash
set -e

echo " =================================================================== "
echo " === This script will set up the environment for the IoT project. === "
echo " === Running in the virtual machine to set up the environment... === "
echo " =================================================================== "

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Clean up any stale broken repo files from previous failed runs
sudo rm -f /etc/apt/sources.list.d/docker.list
sudo rm -f /etc/apt/sources.list.d/kubernetes.list

# Install dependencies
echo " === Installing dependencies... === "
sudo apt-get update -y
sudo apt-get install -y ca-certificates gnupg curl git wget

echo " === Setting up Docker repository... === "
echo "=== Installing docker's official GPG key... ==="
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update -y
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

echo " === Starting Docker service... === "
sudo systemctl enable --now docker

echo " === Installing kubectl (direct binary, bypassing apt v3 signature issue)... === "
KUBECTL_VERSION=$(curl -L -s https://dl.k8s.io/release/stable.txt)
curl -LO "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl"
sudo install -m 0755 -o root -g root kubectl /usr/local/bin/kubectl
rm kubectl
kubectl version --client

echo " === Installing K3d... === "
curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | sudo bash

echo " === Installing Argo CD CLI... === "
curl -sSL -o argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
sudo install -m 555 argocd /usr/local/bin/argocd
rm argocd

echo " === Adding user to docker group... === "
if ! groups | grep -q docker; then
    sudo usermod -aG docker $USER
fi

echo " === Installation complete! Running setup script... === "
sg docker -c "${SCRIPT_DIR}/setup.sh"