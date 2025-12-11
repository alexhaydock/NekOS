#!/usr/bin/env sh

# Nix applies patches using patch -p1 in the
# patchPhase, so we generate a patch that
# adds a buildscript to our sources using
# this script
#
# We need to use git diff for this as a regular
# diff doesn't consider the file permissions
# and we need to ensure the executable bit
# is preserved.

(
cd buildscript || exit
chmod +x build.sh
git diff --no-index /dev/null build.sh > "../patches/0001-add-build-script.patch"
)
