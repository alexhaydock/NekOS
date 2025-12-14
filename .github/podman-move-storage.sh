#!/usr/bin/env bash

sudo mkdir -p /etc/containers
sudo mkdir -p /mnt/podman

sudo tee /etc/containers/storage.conf <<'EOF'
[storage]
driver = "overlay"
graphroot = "/mnt/podman"
runroot = "/run/containers/storage"
EOF

sudo podman info --debug | grep -E 'graphRoot|runRoot'
