#!/usr/bin/env bash

set -e # exit on failure
# set -x # echo commands

VALIDATOR_KEY_NAME=$1
VALIDATOR_KEYS_PASSPHRASE=$2

# echo ${VALIDATOR_KEYS_PASSPHRASE} | ~/upload/newchaind keys show -a ${VALIDATOR_KEY_NAME} --keyring-backend file
~/upload/newchaind keys show -a ${VALIDATOR_KEY_NAME} --keyring-backend test
