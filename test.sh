#!/bin/bash

sudo pkill fddev
sudo pkill fdctl

# bash strict mode
set -euo pipefail
IFS=$'\n\t'
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd "${SCRIPT_DIR}"

NUM_TRANSACTIONS=${1:-1000}

./build/native/gcc/bin/fddev --config ./src/app/fdctl/config/development.toml &> /dev/null &
FDDEV_PID=$?
echo "wait 10 seconds for fddev to startup..."
sleep 10
./test-transactions.sh $NUM_TRANSACTIONS
./check_counts.sh
