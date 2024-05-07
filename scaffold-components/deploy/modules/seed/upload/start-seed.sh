#!/usr/bin/env bash

set -e # exit on failure
# set -x # echo commands

NODE_INDEX=$1

if [[ "${NODE_INDEX}" = "0" ]]; then
    MONIKER="black"
elif [[ "${NODE_INDEX}" = "1" ]]; then
    MONIKER="white"
else
    MONIKER="gray"
fi

# nohup ignite chain serve --verbose >newchain.out 2>&1 </dev/null &
echo "About to start seed node ${MONIKER} with NODE_INDEX ${NODE_INDEX} and id $(~/upload/newchaind tendermint show-node-id)"
pkill newchaind || :
sleep 1
~/upload/newchaind start
sleep 1
