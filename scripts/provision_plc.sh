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
if [ -z "${1}" ]; then
  echo "Ansible target required"
  exit 1
fi

TARGET="${1}"
shift

THIS_SCRIPT="$(realpath "${0}")"
THIS_DIR="$(dirname "${THIS_SCRIPT}")"
ANSIBLE_ROOT="$(realpath "${THIS_DIR}/..")"
SSH_KEY_FILENAME="${ANSIBLE_ROOT}/tcbsd_key_rsa"

# Activate python env if we don't have ansible on the path
if [ ! -x ansible-playbook ]; then
  source /cds/group/pcds/pyps/conda/venvs/ansible/bin/activate
fi

# Run the provision playbook
ansible-playbook "${ANSIBLE_ROOT}/tcbsd-provision-playbook.yaml" --extra-vars "target=${TARGET} ansible_ssh_private_key_file=${SSH_KEY_FILENAME}" --ask-become-pass "$@"
