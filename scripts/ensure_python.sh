#!/bin/bash
# This is meant to be sourced.
# Helper script for ensuring we have a suitable python environment loaded.
# Needs to make sure the following binaries are available:
#   - ansible-playbook
# Needs to make sure the following ansible modules are available:
#   - community.general.xml
#   - community.general.sysrc
# Needs to make sure the following libraries are importable:
#   - lxml
#   - ruamel.yaml
# If any of these are missing, try to load the prepared python env.

ISSUES=()

if [ ! -x "$(command -v ansible-playbook)" ]; then
  ISSUES+=( "Missing ansible-playbook" )
elif [ ! -x "$(command -v ansible-doc)" ]; then
  ISSUES+=( "Missing ansible-doc" )
else
  for module in community.general.xml community.general.sysrc; do
    if [ "$(ansible-doc -j "${module}")" = "{}" ]; then
      ISSUES+=( "Missing ${module} ansible module" )
    fi
  done
fi
if [ ! -x "$(command -v python)" ]; then
  ISSUES+=( "Missing Python!" )
else
  for module in lxml ruamel.yaml; do
    if ! python -c "import ${module}"; then
      ISSUES+=( "Missing ${module} python module" )
    fi
  done
fi
for iss in "${ISSUES[@]}"; do
    echo "${iss}"
done
