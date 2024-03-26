#!/bin/bash
# Get version info for inclusion on https://confluence.slac.stanford.edu/x/0IsFGg
# Includes a human-readable shorthand, a url to the commit, and the current time and date
THIS_SCRIPT="$(realpath "${0}")"
THIS_DIR="$(dirname "${THIS_SCRIPT}")"

VERSION="$(git -C "${THIS_DIR}" describe --tags)"
URL="https://github.com/pcdshub/twincat-bsd-ansible/tree/${VERSION}"

echo "If you made changes, please update the deployment docs (https://confluence.slac.stanford.edu/x/0IsFGg)"
echo "TcBSD Ansible Version: ${VERSION}"
echo "Link commit URL: ${URL}"
echo "PLC Updated on: $(date +'%b %d, %Y')"
