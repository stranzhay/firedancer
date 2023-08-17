#!/bin/bash

sudo pkill fddev
sudo pkill fdctl

# bash strict mode
set -euo pipefail
IFS=$'\n\t'
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd "${SCRIPT_DIR}"

NUM_TRANSACTIONS=${1:-1000}
TX_FILE=${2:tx}

# create test configuration for fddev
TMPDIR=$(mktemp -d)
cat > ${TMPDIR}/config.toml <<EOM
[development]
    sudo = true
    sandbox = true
    [development.netns]
        enabled = true
[tiles.quic]
    interface = "veth_test_xdp_0"
[layout]
    affinity = "0-12"
    verify_tile_count = 4
    bank_tile_count = 4
EOM
export FIREDANCER_CONFIG_TOML=${TMPDIR}/config.toml


./build/native/gcc/bin/fddev &> /dev/null &
#./build/native/gcc/bin/fddev --config ./src/app/fdctl/config/development.toml &> /dev/null &
FDDEV_PID=$?
echo "wait 10 seconds for fddev to startup..."
sleep 10
./test-transactions.sh $NUM_TRANSACTIONS $TX_FILE
./check_counts.sh
