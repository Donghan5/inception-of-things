#!/bin/bash

set -e

echo " =================================================================== "
echo " === This script will set up the environment for the IoT project. === "
echo " === Running in the virtual machine to set up the environment... === "
echo " =================================================================== "


SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Install dependencies
echo " === Installing dependencies... === "
sudo apt-get update -y
sudo apt-get install ca-certificates gnupg curl git wget -y

echo " === Setting up Docker repository... === "
sudo apt-get install -y ca-certificates curl gnupg
echo "=== Install docker's official GPG key... ==="
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list

echo " === Setting up kubectl repository... === "
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list

sudo apt-get update -y
sudo apt-get install -y docker-ce docker-ce-cli containerd.io kubectl

echo " === Starting Docker service... === "
sudo systemctl enable --now docker

# Install K3d
echo " === Installing K3d... ==="
curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash

echo " === Adding user to docker group... === "
if ! groups | grep -q docker; then
    sudo usermod -aG docker $USER
fi

echo " === Installation complete! Running setup script... === "
sg docker -c "${SCRIPT_DIR}/setup.sh"