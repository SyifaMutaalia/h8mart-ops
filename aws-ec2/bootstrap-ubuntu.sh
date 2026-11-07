#!/usr/bin/env bash
# Optional User Data, tanpa menyimpan secret. Untuk Ubuntu Server 24.04 pada EC2.
set -euo pipefail
exec > >(tee -a /var/log/h8mart-bootstrap.log) 2>&1
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y git curl unzip ca-certificates
curl -fsSL https://get.docker.com | sh
systemctl enable --now docker
usermod -aG docker ubuntu || true
if [ ! -f /swapfile ]; then
  fallocate -l 2G /swapfile
  chmod 600 /swapfile
  mkswap /swapfile
  swapon /swapfile
  grep -q '^/swapfile ' /etc/fstab || echo '/swapfile none swap sw 0 0' >> /etc/fstab
fi
docker compose version
free -h
