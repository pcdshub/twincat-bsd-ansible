#!/bin/bash
# Run (or re-run) this script to prepare a single plc for use in the ansible scripts.
# This will create a host vars entry and set us up for ssh key authentication with the plc.
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
THIS_DIR="$(dirname "${SCRIPT}")"
ANSIBLE_ROOT="$(realpath "${THIS_DIR}/..")"
SSH_KEY_FILENAME="${ANSIBLE_ROOT}/tcbsd_key_rsa"

# Create vars, if they do not already exist
VARS_PATH="${ANSIBLE_ROOT}/host_vars/${HOSTNAME}/vars.yml"
if [ ! -f  "${VARS_PATH}" ]; then
  # Get the variables that the template is expecting
  export PLC_IP="$(getent hosts ${HOSTNAME} | cut -f 1 -d " ")"
  export PLC_NET_ID="${PLC_IP}.1.1"
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
