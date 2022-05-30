#!/usr/bin/env bash

set -x
set -e

cd ~/newchain
THIS_NODE_ID=$(build/newchaind tendermint show-node-id)
for f in ~/.newchain/config/gentx/gentx-*.json; do
    base=$(basename ${f})
    if [[ "${base}" != "gentx-${THIS_NODE_ID}.json" ]]; then
        ADDRESS=$(cat ${f} | jq -r '.body.messages[0].delegator_address')
        AMOUNT=$(cat ${f} | jq -r '.body.messages[0].value.amount')
        DENOM=$(cat ${f} | jq -r '.body.messages[0].value.denom')
        build/newchaind add-genesis-account ${ADDRESS} ${AMOUNT}${DENOM}
    fi
done
build/newchaind collect-gentxs
