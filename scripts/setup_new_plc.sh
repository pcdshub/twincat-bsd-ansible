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

THIS_SCRIPT="$(realpath "${0}")"
THIS_DIR="$(dirname "${THIS_SCRIPT}")"

# Register the ssh key with the ssh agent if needed
source "${THIS_DIR}/ssh_agent_helper.sh"
# Stop the ssh agent at exit if we started it here
trap ssh_agent_helper_cleanup EXIT

# Run both playbooks and one-time pre-playbook setup
"${THIS_DIR}"/bootstrap_plc.sh "${1}"
"${THIS_DIR}"/provision_plc.sh "${1}"
