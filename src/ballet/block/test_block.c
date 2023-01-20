#include "fd_block.h"

#include "../../util/sanitize/fd_sanitize.h"

/* Data layout checks */
FD_STATIC_ASSERT( alignof(fd_entry_t)== 64UL, alignment );
FD_STATIC_ASSERT( sizeof (fd_entry_t)==128UL, alignment );

void
test_entry() {
  /* Ensure footprint is multiple of align */

  /*  for( ulong i=0UL; i<64UL; i++ ) {
    do { if( __builtin_expect( !!(!(( fd_entry_footprint( i ) %
# 14 "src/ballet/block/test_block.c" 3 4
   _Alignof
# 14 "src/ballet/block/test_block.c"
   (fd_entry_t) )==0UL)), 0L ) ) do { long _fd_log_msg_now = fd_log_wallclock(); fd_log_private_2( 4, _fd_log_msg_now, "src/ballet/block/test_block.c", 14, __func__, fd_log_private_0 ( "FAIL: " "( fd_entry_footprint( i ) % alignof(fd_entry_t) )==0UL" ) ); } while(0); } while(0);
  }*/

  for( ulong i=0UL; i<64UL; i++ ) {
    FD_TEST( ( fd_entry_footprint( i ) % alignof(fd_entry_t) )==0UL );
  }

  /* Test overflowing txn_max_cnt */

  FD_TEST( fd_entry_footprint( 5167155202719762UL )==0xfffffffffffffbc0UL );
  FD_TEST( fd_entry_footprint( 5167155202719763UL )==0UL  ); /* invalid */
  FD_TEST( fd_entry_new      ( (void *)64UL, 5167155202719763UL )==NULL ); /* fake shmem, invalid footprint */

  /* Test failure cases for fd_entry_new */

  FD_TEST( fd_entry_new( NULL,        16UL )==NULL ); /* null shmem */
  FD_TEST( fd_entry_new( (void *)1UL, 16UL )==NULL ); /* misaligned shmem */

  /* Test failure cases for fd_entry_join */

  FD_TEST( fd_entry_join( NULL        )==NULL ); /* null shentry */
  FD_TEST( fd_entry_join( (void *)1UL )==NULL ); /* misaligned shentry */

  /* Test entry creation */

  ulong txn_max_cnt = 16UL;
  ulong footprint = fd_entry_footprint( txn_max_cnt );
  FD_TEST( footprint );

  void * shmem = fd_alloca( FD_ENTRY_ALIGN, footprint );
  FD_TEST( shmem );

  void * shentry = fd_entry_new( shmem, txn_max_cnt );

  fd_entry_t * entry = fd_entry_join( shentry );
  FD_TEST( entry );

  /* Test bad magic value */

  entry->magic++;
  FD_TEST( fd_entry_join( shentry )==NULL );
  entry->magic--;

  /* Test entry destruction */

  FD_TEST( fd_entry_leave( NULL  )==NULL    ); /* null entry */
  FD_TEST( fd_entry_leave( entry )==shentry ); /* ok */

  FD_TEST( fd_entry_delete( NULL        )==NULL ); /* null shentry */
  FD_TEST( fd_entry_delete( (void *)1UL )==NULL ); /* misaligned shentry */

  /* Test bad magic value.
     Note that at this point our `entry` pointer is dangling. */
  entry->magic++;
  FD_TEST( fd_entry_delete( shentry )==NULL );
  entry->magic--;

  FD_TEST( fd_entry_delete( shentry )==shmem );
}

/* A serialized batch of entries.
   Sourced from the genesis of a `solana-test-validator`. */
FD_IMPORT_BINARY( localnet_batch_0, "src/ballet/shred/fixtures/localnet-slot0-batch0.bin" );

/* Target buffer for storing an `fd_entry_t`.
   In production, this would be a workspace. */
static uchar __attribute__((aligned(FD_ENTRY_ALIGN))) entry_buf[ 0x40000 ];

struct fd_entry_test_vec {
  uchar mixin[ FD_SHA256_HASH_SZ ];
  fd_entry_hdr_t hdr;
};
typedef struct fd_entry_test_vec fd_entry_test_vec_t;

void
test_parse_localnet_batch_0( void ) {
  FD_TEST( localnet_batch_0_sz==3080UL );

  /* Peek the number of entries, which is the first ulong. */
  ulong entry_cnt = *(ulong *)localnet_batch_0;
  FD_TEST( entry_cnt==64UL );

  /* Move past the first ulong to the entries. */
  void * batch_buf = (void *)((uchar *)localnet_batch_0    + 8UL);
  ulong  batch_bufsz =                 localnet_batch_0_sz - 8UL ;

  /* Check whether our .bss buffer fits. */
  ulong const txn_max_cnt = 10;
  ulong footprint = fd_entry_footprint( txn_max_cnt );
  FD_TEST( sizeof(entry_buf)>=footprint );

  /* Mark buffer for storing `fd_entry_t` as unallocated (poisoned).
     `fd_entry_new` will partially unpoison the beginning of this buffer.

     This helps catch OOB accesses beyond the end of `fd_entry_t`. */
  fd_asan_poison( entry_buf, sizeof(entry_buf) );

  /* Create new object in .bss buffer. */
  void * shentry = fd_entry_new( entry_buf, txn_max_cnt );
  FD_TEST( shentry );

  /* Get reference to newly created entry. */
  fd_entry_t * entry = fd_entry_join( shentry );
  FD_TEST( entry );

  /* Deserialize all entries. */
  fd_txn_parse_counters_t counters_opt = {0};
  void * next_buf;
  for( ulong i=0; i<entry_cnt; i++ ) {
    FD_TEST( batch_buf );

    next_buf = fd_entry_deserialize( entry, batch_buf, batch_bufsz, &counters_opt );
    batch_bufsz -= ((ulong)next_buf - (ulong)batch_buf);
    batch_buf    = next_buf;

    /* Each entry in the genesis block has 0 txns, 0 hashes, and the same prev hash */
    FD_TEST( entry->hdr.txn_cnt ==0UL );
    FD_TEST( entry->hdr.hash_cnt==0UL );
  }
}

int
main( int     argc,
      char ** argv ) {
  fd_boot( &argc, &argv );

  test_entry();
  test_parse_localnet_batch_0();

  FD_LOG_NOTICE(( "pass" ));
  fd_halt();
  return 0;
}
