#ifndef HEADER_fd_src_ballet_block_fd_block_h
#define HEADER_fd_src_ballet_block_fd_block_h

/* Blocks are the logical representation of Solana block data.

   They consist of 64 entries, each containing a vector of txs. */

#include "../fd_ballet_base.h"
#include "../sha256/fd_sha256.h"

struct __attribute__((packed)) fd_entry {
  /* Number of PoH hashes between this entry and last entry */
  ulong hash_cnt;

  /* PoH state of last entry */
  uchar hash[ FD_SHA256_HASH_SZ ];

  /* Number of transactions in this entry */
  ulong txn_cnt;
};
typedef struct fd_entry_hdr fd_entry_hdr_t;

FD_STATIC_ASSERT( sizeof(fd_entry_hdr_t)==48UL, alignment );

/* `fd_txn_o` (read `fd_txn` owned) is a buffer that fits any `fd_txn_t`. */
struct fd_txn_o {
  /* Buffer containing `fd_txn_t`. */
  uchar txn_desc_raw[ FD_TXN_MAX_SZ ];
};
typedef struct fd_txn_o fd_txn_o_t;

/* `fd_rawtxn_b` references a serialized txn backing an `fd_txn_t`. */
struct fd_rawtxn_b {
  /* Pointer to txn in local wksp */
  void * raw; /* TODO: Make this a gaddr instead of laddr */

  /* Size of txn */
  ushort txn_sz;
};
typedef struct fd_rawtxn_b fd_rawtxn_b_t;

/* fd_entry: Buffer storing a deserialized entry. */
struct __attribute__((aligned(FD_ENTRY_ALIGN))) fd_entry {
  /* This point is 64-byte aligned */

  ulong magic;       /* ==FD_ENTRY_MAGIC */
  ulong txn_max_cnt; /* Max element cnt in `raw_tbl` and `txn_tbl` */

  /* TODO: Add synchronization metadata (write lock) */

  /* Points to "raw txns" VLA within this struct. */
  fd_rawtxn_b_t * raw_tbl;

  /* Points to "txn descriptors" VLA within this struct. */
  fd_txn_o_t * txn_tbl;

  /* This point is 64-byte aligned */

  /* Fixed size header */
  fd_entry_hdr_t hdr;

  /* This point is 16-byte aligned */

  /* Serialized transactions */
  uchar txn_data[];
};
typedef struct fd_entry fd_entry_t;

#endif /* HEADER_fd_src_ballet_block_fd_block_h */
