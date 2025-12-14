#!/usr/bin/env bash

sudo mkdir -p /etc/containers
sudo mkdir -p /mnt/podman

# We can't change the runroot since /mnt needs certain sticky
# bits and can't have noexec etc etc
sudo tee /etc/containers/storage.conf <<'EOF'
[storage]
driver = "overlay"
graphroot = "/mnt/podman"
EOF

sudo podman info --debug | grep -E 'graphRoot|runRoot'

sudo chown -cR "${USER}":"${USER}" /mnt/podman
