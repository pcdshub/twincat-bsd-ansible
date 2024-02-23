#!/bin/bash
# Run this script to prepare a plc and do the initial provisioning all in one go.
# This is more convenient for setting up a new PLC but cannot be run on inventory
# groups.
#
# Expected usage, e.g. on a bsd test plc:
#
#  $ ./new_plc_all.sh plc-tst-bsd1
set -e

if [ -z "${1}" ]; then
  echo "Error: PLC name required"
  exit 1
fi

THIS_SCRIPT="$(realpath "${0}")"
THIS_DIR="$(dirname "${THIS_SCRIPT}")"

"${THIS_DIR}"/first_time_setup.sh "${1}"
"${THIS_DIR}"/provision_plcs.sh "${1}"
