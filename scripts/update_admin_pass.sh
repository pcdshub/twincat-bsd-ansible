#!/bin/bash
# Helper script for updating the admin password on some of or all of the PLCs.
# This is meant to be used when we change the admin password.
# Despite being a script, this is still a manual process.
# You will be prompted for the old password, the new password, and to retype the new password on each plc.
#
# Expected usage, e.g. on a bsd test plc:
#
#   $ ./update_admin_pass plc-tst-bsd1
#
# On a few test plcs:
#
#   $ ./update_admin_pass plc-tst-bsd1 plc-tst-bsd2
set -e

if [ -z "${1}" ]; then
  echo "Error: At least one PLC name required"
  exit 1
fi

USERNAME="${PLC_USERNAME:=Administrator}"
THIS_SCRIPT="$(realpath "${0}")"
THIS_DIR="$(dirname "${THIS_SCRIPT}")"
source "${THIS_DIR}"/paths.sh

# Register the ssh key with the ssh agent if needed
source "${THIS_DIR}/ssh_agent_helper.sh"
# Stop the ssh agent at exit if we started it here
trap ssh_agent_helper_cleanup EXIT

for HOSTNAME in "$@"; do
    echo "Logging into ${HOSTNAME}"
    ssh -F "${SSH_CONFIG}" -i "${SSH_KEY_FILENAME}" -t "${USERNAME}@${HOSTNAME}" passwd
done
