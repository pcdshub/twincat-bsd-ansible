#!/bin/bash
# Run this script to prepare a plc and do the initial provisioning all in one go.
# This is more convenient for setting up a new PLC but cannot be run on inventory
# groups.
#
# Expected usage, e.g. on a bsd test plc:
#
#  $ ./setup_new_plc.sh plc-tst-bsd1
set -e

if [ -z "${1}" ]; then
  echo "Error: PLC name required"
  exit 1
fi

# Activate python env if we don't have ansible on the path
if [ ! -x ansible-playbook ]; then
  source /cds/group/pcds/pyps/conda/venvs/ansible/bin/activate
fi

THIS_SCRIPT="$(realpath "${0}")"
THIS_DIR="$(dirname "${THIS_SCRIPT}")"

"${THIS_DIR}"/bootstrap_plc.sh "${1}"
"${THIS_DIR}"/provision_plc.sh "${1}"
