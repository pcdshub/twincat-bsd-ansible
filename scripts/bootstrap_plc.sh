#!/bin/bash
# Run (or re-run) this script to prepare a single plc for use in the ansible scripts.
# This will do the following, in order:
# - suggest an edit to the inventory and exit early if needed
# - create a host vars entry
# - and set us up for ssh key authentication with the plc
# - run the bootstrap playbook, so that the provision playbook can run properly
#
# Each user who wants to use ansible for a particular PLC must run this script!
# One of the steps is setting up SSH-based logins, which are done on an per-user basis.
#
# Expected usage, e.g. on a bsd test plc:
#
#   $ ./bootstrap_plc.sh plc-tst-bsd1
set -e

if [ -z "${1}" ]; then
  echo "Error: PLC name required"
  exit 1
fi

HOSTNAME="${1}"
shift

USERNAME="${PLC_USERNAME:=Administrator}"

THIS_SCRIPT="$(realpath "${0}")"
THIS_DIR="$(dirname "${THIS_SCRIPT}")"
source "${THIS_DIR}"/paths.sh

# Use the correct python env
source "${THIS_DIR}"/activate_python.sh

# Check the inventory for your plc
if grep -q "${HOSTNAME}:" "${INVENTORY_PATH}"; then
  echo "Found ${HOSTNAME} in ${INVENTORY_PATH}."
else
  # Add PLC to inventory
  python "${THIS_DIR}"/add_to_inventory.py "${HOSTNAME}"
fi

# Create vars, if they do not already exist
VARS_PATH="${ANSIBLE_ROOT}/host_vars/${HOSTNAME}/vars.yml"
if [ ! -f  "${VARS_PATH}" ]; then
  python "${THIS_DIR}"/make_vars.py "${HOSTNAME}"
else
  echo "${VARS_PATH} already exists, skipping creation."
fi

# Register the ssh key with the ssh agent if needed
source "${THIS_DIR}/ssh_agent_helper.sh"
# Stop the ssh agent at exit if we started it here
trap ssh_agent_helper_cleanup EXIT

# Send the public key to the plc, if it has not already been done
ssh-copy-id -i "${SSH_KEY_FILENAME}" -o PreferredAuthentications=keyboard-interactive "${USERNAME}@${HOSTNAME}"

# Check if we can log in using the key
ssh -F "${SSH_CONFIG}" -i "${SSH_KEY_FILENAME}" "${USERNAME}@${HOSTNAME}" "echo key-based login test successful"

# Check if the default password has been changed and prompt us to change it
PASS_WARNING="$(ssh -F "${SSH_CONFIG}" -i "${SSH_KEY_FILENAME}" "${USERNAME}@${HOSTNAME}" "test -x /home/Administrator/.default_warning && /home/Administrator/.default_warning || true")"
if [ -n "${PASS_WARNING}" ]; then
  echo "Please change the default password to the standard admin password."
  ssh -F "${SSH_CONFIG}" -i "${SSH_KEY_FILENAME}" -t "${USERNAME}@${HOSTNAME}" passwd
else
  echo "Password has been changed from default."
fi

# Check if python3 is installed
HAS_PYTHON="$(ssh -F "${SSH_CONFIG}" -i "${SSH_KEY_FILENAME}" "${USERNAME}@${HOSTNAME}" "test -e /usr/local/bin/python3 && echo yes || echo no")"
if [ "${HAS_PYTHON}" == "yes" ]; then
  echo "Already has python3, exiting"
  exit
fi

# Check the bsd os version
BSD_VER="$(ssh -F "${SSH_CONFIG}" -i "${SSH_KEY_FILENAME}" "${USERNAME}@${HOSTNAME}" "freebsd-version" | cut -d . -f 1)"
if [ "${BSD_VER}" == "13" ]; then
  SOURCE_DIR="/cds/group/pcds/tcbsd/bootstrap/bsd13"
elif [ "${BSD_VER}" == "14" ]; then
  SOURCE_DIR="/cds/group/pcds/tcbsd/bootstrap/bsd14"
else
  echo "BSD version ${BSD_VER} not supported"
  exit
fi

# Remove any existing previous bootstrap folder
ssh -F "${SSH_CONFIG}" -i "${SSH_KEY_FILENAME}" "${USERNAME}@${HOSTNAME}" "test -e ~/bootstrap && rm -rf ~/bootstrap || true"
# Copy the python packages and their dependencies over
scp -F "${SSH_CONFIG}" -i "${SSH_KEY_FILENAME}" -r "${SOURCE_DIR}" "${USERNAME}@${HOSTNAME}:~/bootstrap"

# Run the local install version of the bootstrap playbook
ansible-playbook "${ANSIBLE_ROOT}/tcbsd-bootstrap-from-local-playbook.yaml" --extra-vars "target=${HOSTNAME} ansible_ssh_private_key_file=${SSH_KEY_FILENAME}" --ask-become-pass "$@"
