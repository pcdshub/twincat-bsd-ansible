#!/bin/bash
# This is meant to be sourced.
# Helper script for activating the correct python environment.
# Sets a default env or you can provide your own activate path for testing

DEFAULT_ENV=/cds/group/pcds/pyps/conda/venvs/ansible/bin/activate

if [ -f "${ANSIBLE_PYTHON_ACTIVATE:=${DEFAULT_ENV}}" ]; then
  source "${ANSIBLE_PYTHON_ACTIVATE}"
else
  echo "No Python activation script found at ${ANSIBLE_PYTHON_ACTIVATE}"
  return 1
fi
