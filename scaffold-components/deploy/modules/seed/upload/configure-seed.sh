#!/usr/bin/env bash

# set -x
set -e

NODE_INDEX=$1
if [[ "${NODE_INDEX}" = "0" ]]; then
    MONIKER="black"
elif [[ "${NODE_INDEX}" = "1" ]]; then
    MONIKER="white"
else
    MONIKER="gray"
fi

SEED_IPS_STR=$2
SEED_IPS=(${SEED_IPS_STR//,/ })
SEED_P2P_KEYS=(9038832904699724f0b62188e088a86acb629fad de77ff9811178b9b14507dae3cde3ffa0df68130 192fd886732afb466690f1e098ddd62cfe7a63e4)

VALIDATOR_IPS_STR=$3
VALIDATOR_IPS=(${VALIDATOR_IPS_STR//,/ })
VALIDATOR_P2P_KEYS=(7b23bfaa390d84699812fb709957a9222a7eb519 547217a2c7449d7c6f779e07b011aa27e61673fc 7aaf162f245915711940148fe5d0206e2b456457)

P2P_EXTERNAL_ADDRESS="tcp://${SEED_IPS[$NODE_INDEX]}:26656"

P2P_PERSISTENT_PEERS=""
N=${#VALIDATOR_IPS[@]}
N_MINUS_1=$(($N - 1))
for i in $(seq 0 $N_MINUS_1); do
    P2P_PERSISTENT_PEERS="${P2P_PERSISTENT_PEERS}${VALIDATOR_P2P_KEYS[$i]}@${VALIDATOR_IPS[$i]}:26656,"
done

rm -rf ~/.newchain
~/upload/newchaind init $MONIKER --chain-id newchain-test-1
cp ~/upload/node_key_seed_${NODE_INDEX}.json ~/.newchain/config/node_key.json
cp ~/upload/genesis.json ~/.newchain/config/

cat >/tmp/newchain.service <<-EOF
[Unit]
Description=start newchain blockchain client running as a seed node
Wants=network.target
After=syslog.target network-online.target

[Service]
Type=simple
ExecStart=sudo -u ubuntu /home/ubuntu/upload/start-seed.sh ${NODE_INDEX}
Restart=on-failure
RestartSec=10
KillMode=process

[Install]
WantedBy=multi-user.target

EOF
sudo cp /tmp/newchain.service /etc/systemd/system/newchain.service
sudo chmod 664 /etc/systemd/system/newchain.service
sudo systemctl daemon-reload

dasel put -f ~/.newchain/config/config.toml -t string -v "${P2P_EXTERNAL_ADDRESS}" .p2p.external_address
dasel put -f ~/.newchain/config/config.toml -t string -v "${P2P_PERSISTENT_PEERS}" .p2p.persistent_peers
dasel put -f ~/.newchain/config/app.toml -t bool -v true .api.enable
