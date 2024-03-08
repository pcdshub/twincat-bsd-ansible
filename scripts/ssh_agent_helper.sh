#!/bin/bash
# Helper script for starting the ssh agent if needed and doing an ssh-add.
# This will let anyone smoothly run the ansible scripts without multiple password prompts.
# This script is intended to be sourced.
# Sourcing this script lets ssh-agent set the proper environment variables it needs to run properly.
#
# Expected usage:
#
# source ssh_agent_helper.sh

THIS_SCRIPT="$(realpath "${BASH_SOURCE[0]}")"
THIS_DIR="$(dirname "${THIS_SCRIPT}")"
ANSIBLE_ROOT="$(realpath "${THIS_DIR}/..")"
SSH_KEY_FILENAME="${ANSIBLE_ROOT}/tcbsd_key_rsa"

# Multipurpose check: return code is 1 if the command fails, 2 if cannot connect to agent.
# I'm not sure if need to differentiate between these cases
if PUBKEYS="$(ssh-add -L)"; then
    # Success, check output for pub key
    TCBSD_PUB_KEY="$(cut -f 2 -d " " "${SSH_KEY_FILENAME}.pub")"
    if [[ "${PUBKEYS}" == *"${TCBSD_PUB_KEY}"* ]]; then
        echo "TcBSD key already registered with ssh agent"
        return 0
    fi
else
    # Failed, start the ssh agent
    echo "Starting ssh agent"
    eval "$(ssh-agent -s)"
fi
# If we got this far, run ssh-add
echo "Running ssh-add, will prompt for PLC admin password:"
ssh-add "${SSH_KEY_FILENAME}"
