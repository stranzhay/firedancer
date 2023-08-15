#!/bin/bash
rm -f /tmp/test-transactions.log
NUM_TRANSACTIONS=${1:-1000}
head -n $NUM_TRANSACTIONS tx | while read line; do
    sudo nsenter --net=/var/run/netns/veth_test_xdp_1 ./build/native/gcc/unit-test/test_quic_txn --payload-base64-encoded $line 2>&1 | tee -a /tmp/test-transactions.log
done
echo " $(grep 'rc 1' /tmp/test-transactions.log | wc -l) / $NUM_TRANSACTIONS successfully transmitted by clients"
