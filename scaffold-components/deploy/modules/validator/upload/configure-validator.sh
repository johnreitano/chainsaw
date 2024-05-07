#!/usr/bin/env bash

set -x
set -e

ENV=$1
NODE_INDEX=$2
if [[ "${NODE_INDEX}" = "0" ]]; then
    MONIKER="red"
elif [[ "${NODE_INDEX}" = "1" ]]; then
    MONIKER="blue"
else
    MONIKER="green"
fi

VALIDATOR_IPS_STR=$3
VALIDATOR_IPS=(${VALIDATOR_IPS_STR//,/ })
VALIDATOR_P2P_KEYS=(7b23bfaa390d84699812fb709957a9222a7eb519 547217a2c7449d7c6f779e07b011aa27e61673fc 7aaf162f245915711940148fe5d0206e2b456457)

P2P_EXTERNAL_ADDRESS="tcp://${VALIDATOR_IPS[$NODE_INDEX]}:26656"

P2P_PERSISTENT_PEERS=""
N=${#VALIDATOR_IPS[@]}
N_MINUS_1=$(($N - 1))
for i in $(seq 0 $N_MINUS_1); do
    if [[ "${i}" != "${NODE_INDEX}" ]]; then
        P2P_PERSISTENT_PEERS="${P2P_PERSISTENT_PEERS}${VALIDATOR_P2P_KEYS[$i]}@${VALIDATOR_IPS[$i]}:26656,"
    fi
done

rm -rf ~/.newchain
~/upload/newchaind init $MONIKER --chain-id newchain-${ENV}-1
cp upload/node_key_validator_${NODE_INDEX}.json ~/.newchain/config/node_key.json

cat >/tmp/newchain.service <<-EOF
[Unit]
Description=start newchain blockchain client running as a validator node
Wants=network.target
After=syslog.target network-online.target

[Service]
Type=simple
ExecStart=sudo -u ubuntu /home/ubuntu/upload/start-validator.sh ${NODE_INDEX}
Restart=on-failure
RestartSec=10
KillMode=process

[Install]
WantedBy=multi-user.target

EOF
sudo cp /tmp/newchain.service /etc/systemd/system/newchain.service
sudo chmod 664 /etc/systemd/system/newchain.service
sudo systemctl daemon-reload

dasel put -f ~/.newchain/config/config.toml -v "${P2P_EXTERNAL_ADDRESS}" ".p2p.external_address"
dasel put -f ~/.newchain/config/config.toml -v "${P2P_PERSISTENT_PEERS}" ".p2p.persistent_peers"
dasel put -f ~/.newchain/config/config.toml -v "/home/ubuntu/cert/fullchain.pem" ".rpc.tls_cert_file"
dasel put -f ~/.newchain/config/config.toml -v "/home/ubuntu/cert/privkey.pem" ".rpc.tls_key_file"
dasel put -t bool -f ~/.newchain/config/app.toml -v true ".api.enable"
dasel put -f ~/.newchain/config/app.toml -v "tcp://localhost:1317" ".api.address"
dasel put -f ~/.newchain/config/app.toml -v "1stake" ".minimum-gas-prices"

# generate validator address and store address and mnemonic in ~/.newchain/config/keys-backup
if [[ "${ENV}" = "mainnet" ]]; then
    KEYRING_BACKEND="test" # TODO: change to "file"
else
    KEYRING_BACKEND="test"
fi
yes | ~/upload/newchaind keys delete ${MONIKER} --keyring-backend ${KEYRING_BACKEND} 2>/dev/null || :
MNEMONIC=$(~/upload/newchaind keys mnemonic --keyring-backend ${KEYRING_BACKEND})
echo $MNEMONIC | ~/upload/newchaind keys add ${MONIKER} --keyring-backend ${KEYRING_BACKEND} --recover
ADDRESS=$(~/upload/newchaind keys show ${MONIKER} -a --keyring-backend ${KEYRING_BACKEND})
mkdir -p ~/.newchain/config/keys-backup
echo ${MONIKER}-${ADDRESS} > ~/.newchain/config/keys-backup/validator-address-${MONIKER}.txt
echo ${MNEMONIC} > ~/.newchain/config/keys-backup/validator-mnemonic-${MONIKER}.txt
