#!/usr/bin/env bash

set -e # exit on failure
# set -x # echo commands

SCRIPT_DIR=$(dirname $(readlink -f $0))
cd ${SCRIPT_DIR}/..
ENV=$1
DNS_ZONE_PARENT=$2
TLS_CERTIFICATE_EMAIL=$3

if [[ ! $ENV =~ ^mainnet|testnet$ || "$DNS_ZONE_PARENT" = "" || "$TLS_CERTIFICATE_EMAIL" = "" ]]; then
    echo "Usage: ./create-zone.sh <testnet|mainnet> <dns-zone-parent> <tls-certificate-contact-email>"
fi

cat >${SCRIPT_DIR}/dns.tfvars <<EOF
dns_zone_parent = "$DNS_ZONE_PARENT"
tls_certificate_email = "$TLS_CERTIFICATE_EMAIL"
EOF

ensure-workspace-exists-and-select-it() {
    WORKSPACE=$1
    if [[ "$(terraform workspace list)" =~ "${WORKSPACE}" ]]; then
        echo "selecting workspace ${WORKSPACE}"
        terraform workspace select ${WORKSPACE}
    else
        echo "creating workspace ${WORKSPACE}"
        terraform workspace new ${WORKSPACE}
    fi
}

ensure-workspace-exists-and-select-it ${ENV}
terraform -chdir=deploy apply -auto-approve -var="env=${ENV}" -var="num_validator_instances=0" -var="num_seed_instances=0" -var="create_explorer=false" -var-file="dns.tfvars"
