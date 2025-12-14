#!/usr/bin/env bash

sudo mkdir -p /etc/containers
sudo mkdir -p /mnt/podman/graphroot
sudo mkdir -p /mnt/podman/runroot

sudo tee /etc/containers/storage.conf <<'EOF'
[storage]
driver = "overlay"
graphroot = "/mnt/podman/graphroot"
runroot = "/mnt/podman/runroot"
EOF

sudo podman info --debug | grep -E 'graphRoot|runRoot'

sudo chown -R "${RUNNER_USER}":"${RUNNER_USER}" /mnt/podman
