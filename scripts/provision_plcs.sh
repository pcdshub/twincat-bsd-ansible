#!/bin/bash
# Run the ansible bootstrap and provision scripts on the designated plc or plcs.
#
# To run on a single plc, e.g. the bsd test plc:
#
#   $ ./provision_plcs.sh plc-tst-bsd
#
# To run on a group of plcs, e.g. all of the tst plcs:
#
#   $ ./provision_plcs.sh tst
#
# Groups are defined in the inventory file.
if [ -z "${1}" ]; then
  echo "Ansible target required"
  exit 1
if

TARGET="${1}"

THIS_SCRIPT="$(realpath "${0}")"
THIS_DIR="$(dirname "${THIS_SCRIPT}")"
ANSIBLE_ROOT="$(realpath "${THIS_DIR}/..")"
SSH_KEY_FILENAME="${ANSIBLE_ROOT}/tcbsd_key_rsa"

# Activate python env if we don't have ansible on the path
if [ ! -x ansible-playbook ]; then
  # You should create a reasonable venv here, it just needs ansible
  source "${THIS_DIR}/venv/bin/activate"
fi

# Run the bootstrap playbook
ansible-playbook "${ANSIBLE_ROOT}/tcbsd-bootstrap-playbook.yaml --extra-vars "target=${TARGET} ansible_ssh_private_key_file=${SSH_KEY_FILENAME}""

# Run the provision playbook
ansible-playbook "${ANSIBLE_ROOT}/tcbsd-provision-playbook.yaml --extra-vars "target=${TARGET} ansible_ssh_private_key_file=${SSH_KEY_FILENAME}""
