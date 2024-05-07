#!/usr/bin/env bash

set -e # exit on failure
set -x # echo commands

ENV=$1
VALIDATOR_IPS_STR=$2
VALIDATOR_IPS=(${VALIDATOR_IPS_STR//,/ })
SSH_PRIVATE_KEY_PATH=$3
TOKEN_NAME=$4
VALIDATOR_KEYS_PASSPHRASE=$5

get_moniker() {
    case "$1" in
        0)
            echo -n "red"
            ;;
        1)
            echo -n "blue"
            ;;
        2)
            echo -n "green"
            ;;
        *)
            echo "unexpected validator node index $1"
            exit 1
            ;;
    esac
}

# loop over all validators 
PRIMARY_VALIDATOR_IP=${VALIDATOR_IPS[0]}
NUM_VALIDATORS=${#VALIDATOR_IPS[@]}
for NODE_INDEX in $(seq 0 $((${NUM_VALIDATORS}-1))); do
    # retrieve address and key name from validator
    VALIDATOR_IP=${VALIDATOR_IPS[${NODE_INDEX}]}
    VALIDATOR_KEY_NAME=$(get_moniker ${NODE_INDEX})
    echo ssh -o StrictHostKeyChecking=no -i ${SSH_PRIVATE_KEY_PATH} ubuntu@${VALIDATOR_IP} \~/upload/show-validator-address.sh ${VALIDATOR_KEY_NAME} ${VALIDATOR_KEYS_PASSPHRASE}
    VALIDATOR_ADDRESS=$(ssh -o StrictHostKeyChecking=no -i ${SSH_PRIVATE_KEY_PATH} ubuntu@${VALIDATOR_IP} \~/upload/show-validator-address.sh ${VALIDATOR_KEY_NAME} ${VALIDATOR_KEYS_PASSPHRASE})

    # create genesis account for this validator on primary validator
    ssh -o StrictHostKeyChecking=no -i ${SSH_PRIVATE_KEY_PATH} ubuntu@${PRIMARY_VALIDATOR_IP} \~/upload/newchaind genesis add-genesis-account ${VALIDATOR_ADDRESS} 100000000000${TOKEN_NAME}
                                                                                                                                                         
    mkdir -p /tmp/newchain
    rm -rf /tmp/newchain/*
done

# generate gentx files for all validators and copy them to primary validator
for NODE_INDEX in $(seq 0 $((${NUM_VALIDATORS}-1))); do
    VALIDATOR_IP=${VALIDATOR_IPS[${NODE_INDEX}]}
    VALIDATOR_KEY_NAME=$(get_moniker ${NODE_INDEX})

    if [[ "${NODE_INDEX}" != "0" ]]; then
        # copy genesis file from primary to secondary validator
        scp -o StrictHostKeyChecking=no -i ${SSH_PRIVATE_KEY_PATH} ubuntu@${PRIMARY_VALIDATOR_IP}:\~/.newchain/config/genesis.json ubuntu@${VALIDATOR_IP}:\~/.newchain/config/genesis.json
    fi
    
    # generate a gentx (signed genesis transaction)
    ssh -o StrictHostKeyChecking=no -i ${SSH_PRIVATE_KEY_PATH} ubuntu@${VALIDATOR_IP} rm -rf \~/.newchain/config/gentx/\*
    ssh -o StrictHostKeyChecking=no -i ${SSH_PRIVATE_KEY_PATH} ubuntu@${VALIDATOR_IP} \~/upload/generate-gentx.sh ${ENV} ${TOKEN_NAME} ${VALIDATOR_KEY_NAME} ${VALIDATOR_KEYS_PASSPHRASE}
    
    if [[ "${NODE_INDEX}" != "0" ]]; then
        # copy gentx file from secondary to primary validator
        scp -o StrictHostKeyChecking=no -i ${SSH_PRIVATE_KEY_PATH} ubuntu@${VALIDATOR_IP}:\~/.newchain/config/gentx/gentx-\*.json ubuntu@${PRIMARY_VALIDATOR_IP}:\~/.newchain/config/gentx/
    fi
done

# generate a new genesis file on primary validator that includes all the gentxs (signed genesis transactions)
ssh -o StrictHostKeyChecking=no -i ${SSH_PRIVATE_KEY_PATH} ubuntu@${PRIMARY_VALIDATOR_IP} \~/upload/newchaind genesis collect-gentxs

# copy new genesis file to secondary validators
for NODE_INDEX in $(seq 1 $((${NUM_VALIDATORS}-1))); do
    VALIDATOR_IP=${VALIDATOR_IPS[${NODE_INDEX}]}
    scp -o StrictHostKeyChecking=no -i ${SSH_PRIVATE_KEY_PATH} ubuntu@${PRIMARY_VALIDATOR_IP}:\~/.newchain/config/genesis.json ubuntu@${VALIDATOR_IP}:\~/.newchain/config/genesis.json
done
