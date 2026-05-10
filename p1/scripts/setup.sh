#!/bin/bash

set -e

echo "---- Update and upgrade apt packages ----"
sudo apt update -y
sudo apt upgrade -y

echo "---- Install utilities ----"
sudo apt install -y curl wget git vim net-tools

echo "---- Install dependencies for $1 ----"
if [ "$1" == "server" ]; then
  echo "Install control node dependencies"
  IFACE=$(ip -o -4 addr show | awk '/192\.168\.56\.110/ {print $2}')
  curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server \
      --node-ip=192.168.56.110 \
      --bind-address=192.168.56.110 \
      --advertise-address=192.168.56.110 \
      --flannel-iface=$IFACE \
      --disable=traefik \
      --disable=metrics-server \
      --disable=servicelb" sh -

  # save token to file
  while [ ! -f "/var/lib/rancher/k3s/server/node-token" ]; do
    echo "Waiting for token file to be created..."
    sleep 1
  done

  echo "Copy token from server to worker"
  sudo cp /var/lib/rancher/k3s/server/node-token /vagrant/token   # ← cat > 대신 cp

elif [ "$1" == "server-worker" ]; then
  echo "Install worker node dependencies"

  while [ ! -f /vagrant/token ]; do
    echo "Waiting for token file from server..."
    sleep 2
  done

  IFACE=$(ip -o -4 addr show | awk '/192\.168\.56\.111/ {print $2}')
  TOKEN=$(cat /vagrant/token)
  curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="agent \
      --server=https://192.168.56.110:6443 \
      --token=$TOKEN \
      --node-ip=192.168.56.111 \
      --flannel-iface=$IFACE" sh -
fi