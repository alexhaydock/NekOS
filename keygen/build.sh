#!/usr/bin/env bash
set -euo pipefail

# Build Secure Boot keys
podman build --target final -t keygen .

# Run container to copy Secure Boot and stboot keys into
# keys/ but only if they don't already exist so that we
# can keep our keys consistent if we've already got some
if ! [ -f "$(pwd)/keys/db-priv.pem" ]
  then
    podman run --rm -it -v "$(pwd)/keys:/opt/out:Z" --entrypoint rsync keygen -avsh /opt/sbkeys/ /opt/out/
    podman run --rm -it -v "$(pwd)/keys:/opt/out:Z" --entrypoint rsync keygen -avsh /opt/stbootkeys/ /opt/out/
  else
    echo ""
    echo "Keys already exist in keys/ directory"
    echo "Refusing to overwrite"
fi
