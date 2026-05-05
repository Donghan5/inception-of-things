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
  curl -sfL https://get.k3s.io | sh -s - server --node-ip 192.168.56.110

  # save token to file
  while [ ! -f "/var/lib/rancher/k3s/server/node-token" ]; do
    echo "Waiting for token file to be created..."
    sleep 1
  done

  echo "Copy token from server to worker"
  sudo cat /var/lib/rancher/k3s/server/node-token > /vagrant/token

elif [ "$1" == "server-worker" ]; then
  echo "Install worker node dependencies"
  TOKEN=$(cat /vagrant/token)
  curl -sfL https://get.k3s.io | sh -s - agent --server https://192.168.56.110:6443 --token $TOKEN --node-ip 192.168.56.111
fi