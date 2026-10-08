#!/bin/bash
# Clones tools from pcdshub repos that we want to install onto the PLCs
# Do this in a script here to avoid issues with ssh auth during the playbook run
set -e

THIS_SCRIPT="$(realpath "${BASH_SOURCE[0]}")"
THIS_DIR="$(dirname "${THIS_SCRIPT}")"
REPO_ROOT="$(realpath "${THIS_DIR}"/..)"
CACHE="${REPO_ROOT}"/.cache

# plcsnapshots
mkdir -p "${CACHE}"/plcsnapshots
for version in $(grep plcsnapshots_version "${REPO_ROOT}"/*_vars/*/*.yml | grep -v "#" | cut -d " " -f 2 | sort | uniq); do
    target="${CACHE}"/plcsnapshots/"${version}"
    if [ ! -d "$target" ]; then
        git clone git@github.com:pcdshub/plcsnapshots -b "${version}" "${target}"
    fi
done
