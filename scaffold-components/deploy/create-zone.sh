#!/usr/bin/env bash

set -e # exit on failure
# set -x # echo commands

SCRIPT_DIR=$(dirname $(readlink -f $0))
cd ${SCRIPT_DIR}/..
ENV=$1
DNS_ZONE_PARENT=$2
TLS_CERTIFICATE_EMAIL=$3
TOKEN_NAME=$4
VALIDATOR_KEYS_PASSPHRASE=$5

if [[ (! $ENV =~ ^mainnet|testnet$) || "$DNS_ZONE_PARENT" = "" || "$TLS_CERTIFICATE_EMAIL" = "" || "${TOKEN_NAME}" = "" || "${VALIDATOR_KEYS_PASSPHRASE}" = "" ]]; then
    echo "Usage: ./create-zone.sh <testnet|mainnet> <dns-zone-parent> <tls-certificate-contact-email> <token-name> <valdiator-keys-passphrase>"
    exit 1
fi
cat >${SCRIPT_DIR}/persistent.tfvars <<EOF
dns_zone_parent = "$DNS_ZONE_PARENT"
tls_certificate_email = "$TLS_CERTIFICATE_EMAIL"
validator_keys_passphrase = "$VALIDATOR_KEYS_PASSPHRASE"
token_name = "${TOKEN_NAME}"
EOF

terraform workspace select -or-create ${ENV}
terraform -chdir=deploy apply -auto-approve -var="env=${ENV}" -var="num_validator_instances=0" -var="num_seed_instances=0" -var="create_explorer=false" -var-file="persistent.tfvars"
