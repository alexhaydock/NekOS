#!/usr/bin/env bash
set -euo pipefail

# Build Secure Boot keys
podman build -t secboot .

# Run container to copy Secure Boot keys into keys/
# but only if they don't already exist so that we can
# keep our keys consistent if we've already got some
if ! [ -f "$(pwd)/keys/db-priv.pem" ]
  then
    podman run --rm -it -v "$(pwd)/keys:/opt/out:Z" --entrypoint rsync secboot -avsh /opt/keys/ /opt/out/
  else
    echo ""
    echo "Secure Boot keys already exist in keys/ directory"
    echo "Refusing to overwrite"
fi
