#!/usr/bin/env bash
# set -x
set -e

SCRIPT_DIR=$(dirname $(readlink -f $0))
cd ${SCRIPT_DIR}/..

ENV=$1
if [[ ! $ENV =~ ^mainnet|testnet$  ]]; then
  echo "Usage: deestroy-all <mainnet|testnet>"
  exit 1
fi

terraform -chdir=deploy destroy  -var="env=${ENV}" -var="num_validator_instances=0" -var="num_seed_instances=0" -var="create_explorer=false" -var-file="dns.tfvars"
