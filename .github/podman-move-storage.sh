#!/usr/bin/env bash

sudo mkdir -p /etc/containers
sudo mkdir -p /mnt/podman

sudo tee /etc/containers/storage.conf <<'EOF'
[storage]
driver = "overlay"
graphroot = "/mnt/podman"
runroot = "/mnt/podman/runroot"
EOF

sudo podman info --debug | grep -E 'graphRoot|runRoot'
