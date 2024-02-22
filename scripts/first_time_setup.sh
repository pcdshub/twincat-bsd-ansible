#!/bin/bash
# Run (or re-run) this script to prepare a single plc for use in the ansible scripts.
# This will do the following, in order:
# - suggest an edit to the inventory and exit early if needed
# - create a host vars entry
# - and set us up for ssh key authentication with the plc
# - run the bootstrap playbook, so that the provision playbook can run properly
#
# Expected usage, e.g. on the bsd test plc:
#
#   $ ./first_time_setup.sh plc-tst-bsd
if [ -z "${1}" ]; then
  echo "Error: PLC name required"
  exit 1
fi

HOSTNAME="${1}"
shift

THIS_SCRIPT="$(realpath "${0}")"
THIS_DIR="$(dirname "${THIS_SCRIPT}")"
ANSIBLE_ROOT="$(realpath "${THIS_DIR}/..")"
SSH_KEY_FILENAME="${ANSIBLE_ROOT}/tcbsd_key_rsa"
INVENTORY_PATH="${ANSIBLE_ROOT}/inventory/plcs.yaml"

# Check the inventory for your plc
if grep -q "${HOSTNAME}:" "${INVENTORY_PATH}"; then
  echo "Found ${HOSTNAME} in ${INVENTORY_PATH}."
else
  echo "Please add ${HOSTNAME} to ${INVENTORY_PATH} and re-run this script."
  exit 1
fi

# Create vars, if they do not already exist
VARS_PATH="${ANSIBLE_ROOT}/host_vars/${HOSTNAME}/vars.yml"
if [ ! -f  "${VARS_PATH}" ]; then
  # Template uses IP, but hostname is also valid
  PLC_IP="${HOSTNAME}"
  RAW_IP="$(getent hosts "${HOSTNAME}" | cut -f 1 -d " ")"
  PLC_NET_ID="${RAW_IP}.1.1"
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

# Activate python env if we don't have ansible on the path
if [ ! -x ansible-playbook ]; then
  # You should create a reasonable venv here, it just needs ansible
  source "${THIS_DIR}/venv/bin/activate"
fi

# Run the bootstrap playbook
TARGET="${HOSTNAME}"
ansible-playbook "${ANSIBLE_ROOT}/tcbsd-bootstrap-playbook.yaml" --extra-vars "target=${TARGET} ansible_ssh_private_key_file=${SSH_KEY_FILENAME}" "$@"
