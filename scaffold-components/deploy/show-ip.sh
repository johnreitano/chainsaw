#!/usr/bin/env bash
# set -x
set -e

SCRIPT_DIR=$(dirname $(readlink -f $0))
NODE_TYPE=$1
NODE_INDEX=$2

terraform -chdir=$SCRIPT_DIR output --json | jq -r ".${NODE_TYPE}_ips.value[${NODE_INDEX}]"
