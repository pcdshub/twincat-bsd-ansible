#!/bin/bash
# Get version info for inclusion on https://confluence.slac.stanford.edu/x/0IsFGg
# Includes a human-readable shorthand, a url to the commit, and the current time and date
THIS_SCRIPT="$(realpath "${0}")"
THIS_DIR="$(dirname "${THIS_SCRIPT}")"
source "${THIS_DIR}"/paths.sh

# Safe directory needed to check the git version, only apply once per user.
if ! git config --global --get-all safe.directory | grep "${ANSIBLE_ROOT}" &>/dev/null; then
    git config --global --add safe.directory "${ANSIBLE_ROOT}"
    echo "Added ${ANSIBLE_ROOT} as a git safe.directory to check the version."
fi
VERSION="$(git -C "${ANSIBLE_ROOT}" describe --tags)"
URL="https://github.com/pcdshub/twincat-bsd-ansible/tree/${VERSION}"

echo "If you made changes, please update the deployment docs (https://confluence.slac.stanford.edu/x/0IsFGg)"
echo "TcBSD Ansible Version: ${VERSION}"
echo "Link commit URL: ${URL}"
echo "PLC Updated on: $(date +'%b %d, %Y')"
