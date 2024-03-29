#!/bin/bash
# Helper script for starting the ssh agent if needed and doing an ssh-add.
# This will let anyone smoothly run the ansible scripts without multiple password prompts.
# This script is intended to be sourced.
# Sourcing this script lets ssh-agent set the proper environment variables it needs to run properly.
#
# Expected usage:
#
# source ssh_agent_helper.sh
set -e

SSH_KEY_FILENAME="${HOME}/.ssh/tcbsd_key_rsa"
export SSH_KEY_FILENAME

HELPER_STARTED_AGENT="NO"
export HELPER_STARTED_AGENT

# Define an exportable helper for cleaning up the SSH agent
ssh_agent_helper_cleanup() {
    if [ "${HELPER_STARTED_AGENT}" = "YES" ] && [ -n "${SSH_AGENT_PID}" ]; then
        echo "Cleaning up SSH agent"
        kill "${SSH_AGENT_PID}"
        unset HELPER_STARTED_AGENT
        unset SSH_AGENT_PID
        unset SSH_AUTH_SOCK
        export HELPER_STARTED_AGENT
        export SSH_AGENT_PID
        export SSH_AUTH_SOCK
    fi
}
export ssh_agent_helper_cleanup
# Clean up immediately if something in this script fails
trap ssh_agent_helper_cleanup ERR

# Create an ssh key, if it does not already exist
if [ ! -f "${SSH_KEY_FILENAME}" ]; then
  echo "Generating your PLC Ansible SSH Key at ${SSH_KEY_FILENAME}."
  echo "Please encrypt this with the TCBSD Admin password!."
  ssh-keygen -t rsa -f "${SSH_KEY_FILENAME}"
fi

# Multipurpose check: return code is 1 if the command fails, 2 if cannot connect to agent.
# I'm not sure if need to differentiate between these cases
if PUBKEYS="$(ssh-add -L)"; then
    # Success, check output for pub key
    TCBSD_PUB_KEY="$(cut -f 2 -d " " "${SSH_KEY_FILENAME}.pub")"
    if [[ "${PUBKEYS}" == *"${TCBSD_PUB_KEY}"* ]]; then
        echo "TcBSD key is registered with ssh agent"
        return 0
    fi
else
    # Failed, start the ssh agent
    echo "Starting ssh agent"
    eval "$(ssh-agent -s)"
    HELPER_STARTED_AGENT="YES"
fi
# If we got this far, run ssh-add
echo "Running ssh-add, will prompt for PLC admin password:"
ssh-add "${SSH_KEY_FILENAME}"
