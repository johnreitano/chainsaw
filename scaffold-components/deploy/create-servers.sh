#!/usr/bin/env bash

set -e # exit on failure
# set -x # echo commands

SCRIPT_DIR=$(dirname $(readlink -f $0))
cd ${SCRIPT_DIR}/..

ENV=$1
NUM_VALIDATORS=$2
NUM_SEEDS=$3

if [[ ! $ENV =~ ^mainnet|testnet$ || "$NUM_VALIDATORS" -lt "1" || "$NUM_VALIDATORS" -gt "100" || "$NUM_SEEDS" -lt "1" || "$NUM_SEEDS" -gt "100" ]]; then
  echo "Usage: create-servers <mainnet|testnet> <num-validators> <num-seeds>"
  exit 1
fi

if ! test -f "${SCRIPT_DIR}/persistent.tfvars"; then
  echo "File persistent.tfvars not found - run create-zone.sh before running this script."
  exit 1
fi

if [[ ! "$(terraform workspace list)" =~ "${ENV}" ]]; then
  echo "terraform workspace ${ENV} does not exist - run create-zone.sh before running this script."
  exit 1
fi

terraform workspace select ${ENV}
terraform -chdir=deploy apply -auto-approve -var="env=${ENV}" -var="num_validator_instances=$NUM_VALIDATORS" -var="num_seed_instances=${NUM_SEEDS}" -var="create_explorer=true" -var-file="persistent.tfvars"
