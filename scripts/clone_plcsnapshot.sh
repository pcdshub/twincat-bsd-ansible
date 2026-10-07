#!/bin/bash
set -e

VERSION=$1

THIS_SCRIPT="$(realpath "${BASH_SOURCE[0]}")"
THIS_DIR="$(dirname "${THIS_SCRIPT}")"

mkdir -p "$THIS_DIR"/../.cache/plcsnapshots
git clone git@github.com:pcdshub/plcsnapshots -b "$VERSION" "$THIS_DIR"/../.cache/plcsnapshots/"$VERSION"
