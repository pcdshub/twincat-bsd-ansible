#!/bin/bash
# Run the ansible provision script on the designated plc or group of plcs.
#
# To run on a single plc, e.g. a bsd test plc:
#
#   $ ./provision_plc.sh plc-tst-bsd1
#
# To run on a group of plcs, e.g. all of the tst plcs:
#
#   $ ./provision_plc.sh tst_all
#
# Groups are defined in the inventory file.
set -e

if [ -z "${1}" ]; then
  echo "Ansible target required"
  exit 1
fi

TARGET="${1}"
shift

THIS_SCRIPT="$(realpath "${0}")"
THIS_DIR="$(dirname "${THIS_SCRIPT}")"
source "${THIS_DIR}"/paths.sh

# Use the correct python env
source "${THIS_DIR}"/activate_python.sh

# Register the ssh key with the ssh agent if needed
source "${THIS_DIR}/ssh_agent_helper.sh"
# Stop the ssh agent at exit if we started it here
trap ssh_agent_helper_cleanup EXIT

# Run the provision playbook
ansible-playbook "${ANSIBLE_ROOT}/tcbsd-provision-playbook.yaml" --extra-vars "target=${TARGET} ansible_ssh_private_key_file=${SSH_KEY_FILENAME}" --ask-become-pass "$@"

# Prompt to update deployment docs
"${THIS_DIR}"/docs_prompt.sh
