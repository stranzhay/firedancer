// Define all C feature flags, as we'll manage features via Rust.
#define FD_HAS_HOSTED    1
#define FD_HAS_ATOMIC    1
#define FD_HAS_THREADS   1
#define FD_USE_ATTR_WEAK 1

#include "firedancer/src/ballet/fd_ballet.h"
#include "firedancer/src/ballet/sbpf/fd_sbpf_loader.h"
#include "firedancer/src/ballet/sbpf/fd_sbpf_maps.c"
#include "firedancer/src/ballet/shred/fd_shred.h"
#include "firedancer/src/ballet/txn/fd_txn.h"
