#!/bin/bash
# Run (or re-run) this script to prepare a single plc for use in the ansible scripts.
# This will create a host vars entry and set us up for ssh key authentication with the plc.
# It will also check if your plc is in the inventory and suggest editing the inventory if not.
#
# Expected usage, e.g. on the bsd test plc:
#
#   $ ./first_time_setup.sh plc-tst-bsd
if [ -z "${1}" ]; then
  echo "Error: PLC name required"
  exit 1
fi

HOSTNAME="${1}"

THIS_SCRIPT="$(realpath "${0}")"
THIS_DIR="$(dirname "${THIS_SCRIPT}")"
ANSIBLE_ROOT="$(realpath "${THIS_DIR}/..")"
SSH_KEY_FILENAME="${ANSIBLE_ROOT}/tcbsd_key_rsa"
INVENTORY_PATH="${ANSIBLE_ROOT}/inventory/plcs.yaml"

# Check the inventory for your plc
if grep -q "${HOSTNAME}:" "${INVENTORY_PATH}"; then
  echo "Found ${HOSTNAME} in ${INVENTORY_PATH}."
else
  echo "Please add ${HOSTNAME} to ${INVENTORY_PATH}"
fi

# Create vars, if they do not already exist
VARS_PATH="${ANSIBLE_ROOT}/host_vars/${HOSTNAME}/vars.yml"
if [ ! -f  "${VARS_PATH}" ]; then
  # Get the variables that the template is expecting
  PLC_IP="$(getent hosts "${HOSTNAME}" | cut -f 1 -d " ")"
  PLC_NET_ID="${PLC_IP}.1.1"
  export PLC_IP
  export PLC_NET_ID
  mkdir -p "$(dirname "${VARS_PATH}")"
  envsubst < "${ANSIBLE_ROOT}/tcbsd-plc.yaml.template" > "${VARS_PATH}"
  echo "Created ${VARS_PATH}, please edit this as needed for plc-specific settings."
else
  echo "${VARS_PATH} already exists, skipping creation."
fi

# Create an ssh key, if it does not already exist
if [ ! -f "${SSH_KEY_FILENAME}" ]; then
  ssh-keygen -t rsa -f "${SSH_KEY_FILENAME}"
fi

# Send the public key to the plc, if it has not already been done
ssh-copy-id -i "${SSH_KEY_FILENAME}" "${PLC_USERNAME:=Administrator}@${HOSTNAME}"

# Check if we can log in using the key
ssh -i "${SSH_KEY_FILENAME}" "${PLC_USERNAME:=Administrator}@${HOSTNAME}" "echo key-based login test successful"
