#!/usr/bin/env bash

sudo mkdir -p \
  /etc/containers \
  /mnt/podman/graphroot \
  /mnt/podman/rl_storage

# We can't change the runroot away from the default, 
# since /mnt needs certain sticky bits and can't have
# noexec etc etc
sudo tee /etc/containers/storage.conf <<'EOF'
[storage]
driver = "overlay"
runroot = "/run/containers/storage"
graphroot = "/mnt/podman/graphroot"
rootless_storage_path = "/mnt/podman/rl_storage"
EOF

sudo podman info --debug | grep -E 'graphRoot|runRoot'

sudo chown -cR "${USER}":"${USER}" /mnt/podman
