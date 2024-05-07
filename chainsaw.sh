#!/bin/bash

set -e # exit on failure
# set -x # echo commands

SCRIPT_DIR=$(dirname $(readlink -f $0))

GITHUB_ORG=$1
CHAIN_NAME=$2
CHAIN_NAME=$(echo $CHAIN_NAME | tr '[:upper:]' '[:lower:]')
CHAIN_NAME_UPPER=$(echo $CHAIN_NAME | tr '[:lower:]' '[:upper:]')
CHAIN_NAME_TITLE=$(echo ${CHAIN_NAME:0:1} | tr '[:lower:]' '[:upper:]')${CHAIN_NAME:1}

if [[ "$GITHUB_ORG" = "" || "$CHAIN_NAME" = "" ]]; then
  echo "Usage: chainsaw <github-org-name> <chain-name>"
  exit 1
fi
rm -rf ~/.$CHAIN_NAME ~/.ignite/local-chains/$CHAIN_NAME
ignite scaffold chain github.com/${GITHUB_ORG}/$CHAIN_NAME --address-prefix $CHAIN_NAME --clear-cache
cd $CHAIN_NAME
cp -r ${SCRIPT_DIR}/scaffold-components/* .

find . -type f -exec perl -i -pe"s/newchain/$CHAIN_NAME/g" {} +
find . -type f -exec perl -i -pe"s/Newchain/$CHAIN_NAME_TITLE/g" {} +
find . -type f -exec perl -i -pe"s/NEWCHAIN/$CHAIN_NAME_UPPER/g" {} +
echo >>.gitignore <<-EOF
.terraform/
terraform.tfstate
terraform.tfstate.backup
terraform.tfvars
EOF
terraform -chdir=deploy init
git add .
