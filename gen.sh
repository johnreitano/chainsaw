#!/bin/bash

set -e # exit on failure
# set -x # echo commands

SCRIPT_DIR=$(dirname $(readlink -f $0))

GITHUB_ORG=$1
CHAIN_NAME=$2

if [[ "$GITHUB_ORG" = "" || "$CHAIN_NAME" = "" ]]; then
  echo "Usage: ./gen.sh <github-org-name> <github-repo-name> [<chain-name>]"
  exit 1
fi
trash -rf ~/.$CHAIN_NAME ~/.ignite/local-chains/$CHAIN_NAME
echo "scaffolding chain ${NAME}..."
ignite scaffold chain github.com/${GITHUB_ORG}/$CHAIN_NAME --address-prefix $CHAIN_NAME
cd $CHAIN_NAME

# cd vue
# npm install
# npm run build
# cd ..

echo "deploying chain $CHAIN_NAME..."
cp -r ${SCRIPT_DIR}/scaffold-components/* .
find . -type f -exec perl -i -pe"s/newchain/$CHAIN_NAME/g" {} +
echo >>.gitignore <<-EOF
.terraform/
terraform.tfstate
terraform.tfstate.backup
terraform.tfvars
EOF
git add .gitignore
cd deploy
terraform init
git add .
terraform apply -auto-approve
