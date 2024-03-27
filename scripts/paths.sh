#!/bin/bash
# Sourceable script to set common vars for the various scripts.
# This sets a bunch of environment variables related to known paths
# and puts us into the ansible directory for the duration of the
# encapsulating script.
set -e

THIS_SCRIPT="$(realpath "${BASH_SOURCE[0]}")"
THIS_DIR="$(dirname "${THIS_SCRIPT}")"

ANSIBLE_ROOT="$(realpath "${THIS_DIR}/..")"
export ANSIBLE_ROOT
INVENTORY_PATH="${ANSIBLE_ROOT}/inventory/plcs.yaml"
export INVENTORY_PATH
SSH_CONFIG="${ANSIBLE_ROOT}/ssh_config"
export SSH_CONFIG

cd "${ANSIBLE_ROOT}"
