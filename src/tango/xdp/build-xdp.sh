#!/bin/bash

# Script to rebuild XDP program.
#
# Clang is the only supported eBPF compiler for now.
# Some versions of Clang attempt to build with stack protection
# which is not supported for the eBPF target -- the kernel verifier
# provides such safety features.

# bash strict mode
set -euo pipefail
IFS=$'\n\t'
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd "${SCRIPT_DIR}"

clang                           \
  -std=c17                      \
  -I./opt/include               \
  -target bpf                   \
  -O2                           \
  -fno-stack-protector          \
  -c -o fd_xdp_redirect_prog.o  \
  fd_xdp_redirect_prog.c

