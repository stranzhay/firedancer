/* fd_pubkey_map_perfect defines a few macros and functions for building
   compile-time perfect hash tables of account addresses (frequently
   called pubkeys).  If C's preprocessor were more powerful, it might be
   possible to do this all automatically and fully generically, but it's
   not.  The good thing this does provide is that it will fail to
   compile if your hash function doesn't result in a perfect hash table.
   It takes abusing the preprocessor a little and jumping through some
   hoops in order to get that property.

   This file also supports tables with no value, in which case it is
   essentially a set (quickly answering containment queries).  To use
   that functionality, simply do not define PMP_VAL.

   This file only supports one family of hash function:
     Let A be an account address, and let a' be bytes [8, 12) of A
     interpreted as a uint in little endian byte ordering.
     Let c be a random-ish constant (more details below).
     Let k be the desired size of the hash in bits, i.e. PMP_LG_TBL_SZ.

     Then hash(A) = ((uint)(c*a'))>>(32-k)

   I'm not too sure about the theory of this function, but it seems to
   work decently well in practice, and it's extremely cheap (2
   instructions, 4 cycles of latency, 1 cycle inverse throughput).
   It certainly seems to be the case that entropy is not evenly
   distributed among account addresses that are manually set (e.g.
   sysvars), which are one of the primary use cases for this file.


   Example usage:

   struct __attribute__((aligned(32))) addr_prio {
     uchar addr[32];
     ulong prio;
   };
   typedef struct addr_prio addr_prio_t;

#define PMP_LG_TBL_SZ 3 // table can fit at most 8 elements
#define PMP_T         addr_prio_t
#define PMP_HASH_C    650148382U  // A random uint, see below for details
#define PMP_KEY       addr
#define PMP_NAME      addr_prio_tbl
#define PMP_VAL       prio

#include "fd_pubkey_map_perfect.h"

PMP_TABLE_BEGIN()
ADD_ELE( SYSTEM_PROGRAM_ID, 12 ),
ADD_ELE( STAKE_PROGRAM_ID,  19 ),
ADD_ELE( CONFIG_PROGRAM_ID, 33 ),
...
PMP_TABLE_END()

  ulong
  get_priority( uchar * addr ) {
    addr_prio_t default = { 0 };
    addr_prio_t * query_result = addr_prio_tbl_query( addr, &default );
    return query_result->prio;
  }


  Example usage more as a set:

#define PMP_LG_TBL_SZ 3 // table can fit at most 8 elements
#define PMP_T         fd_acct_addr_t
#define PMP_HASH_C    650148382U  // A random uint, see below for details
#define PMP_KEY       b
#define PMP_NAME      key_lookup

#include "fd_pubkey_map_perfect.h"

PMP_TABLE_BEGIN()
ADD_ELE( SYSTEM_PROGRAM_ID ),
ADD_ELE( STAKE_PROGRAM_ID  ),
ADD_ELE( CONFIG_PROGRAM_ID ),
...
PMP_TABLE_END()


   void
   dispatch( uchar * addr ) {
     switch( key_lookup_hash_or_default( addr ) ) {
       case PERFECT_HASH_PP( SYSTEM_PROGRAM_ID ): execute_system_program(); break;
       case PERFECT_HASH_PP( STAKE_PROGRAM_ID  ): execute_stake_program();  break;
       case PERFECT_HASH_PP( CONFIG_PROGRAM_ID ): execute_config_program(); break;
       ...
       default: // wasn't in the table
     }
   }


   A note on picking PMP_HASH_C: I don't know a better way to find the
   constant other than brute force.  If we model the hash function as a
   random map, then the probability any given constant results in no
   collisions is:
                             N!/((N-m)!*N^m)
   where N is 2^PMP_LG_TBL_SZ and m is the number of elements in the
   table.  The simple estimate of the number of constants you need to
   try is then ((N-m)! N^m)/N!.  This function grows faster than
   exponential as a function of m.  The only real downside to a larger
   table is increased cache utilization and cache misses.

   You can use the following Python code to find a constant:

   import struct
   import base58
   import numpy as np
   import random
   import math

   arr = """  Sysvar1111111111111111111111111111111111111
     SysvarRecentB1ockHashes11111111111111111111
     ...
     So11111111111111111111111111111111111111112
     TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA
   """
   PMP_LG_TBL_SZ = 5

   b_ids = list(map(lambda x: struct.unpack('<I', base58.b58decode(x)[8:12])[0], arr.split()))
   assert( len(b_ids) < (1<<PMP_LG_TBL_SZ) )
   nn = np.array(b_ids)
   best = 0

   estimated_cnt = int(
       math.factorial( (1<<PMP_LG_TBL_SZ)-len(b_ids) ) * ((1<<PMP_LG_TBL_SZ)**len(b_ids)) /
       math.factorial((1<<PMP_LG_TBL_SZ)))
   if estimated_cnt > 2**32:
       print(f"Warning: the table is likely too full. Estimated {estimated_cnt} random values needed")
   print(f"Trying {2*estimated_cnt} random constants")

   for k in range(2*estimated_cnt):
       r = random.randint(0,2**32-1)
       cur = len(set( ((nn*r)>>(32-PMP_LG_TBL_SZ))&((1<<PMP_LG_TBL_SZ) - 1) ))
       if cur == len(b_ids):
           print(f"Success! Use {r} as the hash constant")
           break
       if cur>best:
           best = cur
           print(f"Progress: found projection onto {best} entries.")

*/


#ifndef PMP_LG_TBL_SZ
#error "Define PMP_LG_TBL_SZ"
#endif

#ifndef PMP_T
#error "Define PMP_T"
#endif

#ifndef PMP_HASH_C
#error "Define PMP_HASH_C"
#endif

#ifndef PMP_KEY
#error "Define PMP_KEY"
#endif

#ifndef PMP_NAME
#error "Define PMP_NAME"
#endif

#define PERFECT_HASH( u ) (( PMP_HASH_C * (uint)(u))>>(32-(PMP_LG_TBL_SZ)))
#define PERFECT_HASH_PUBKEY( pubkey ) PERFECT_HASH( fd_uint_load_4( (uchar*)(pubkey) + 8UL ) )
#define PERFECT_HASH_PP( PUBKEY ) PERFECT_HASH_PP_( PUBKEY )
#define PERFECT_HASH_PP_( a00,a01,a02,a03,a04,a05,a06,a07,a08,a09,a10,a11,a12,a13,a14,a15,  \
                          a16,a17,a18,a19,a20,a21,a22,a23,a24,a25,a26,a27,a28,a29,a30,a31 ) \
                          PERFECT_HASH( ((uint)a08 | ((uint)a09<<8) | ((uint)a10<<16) | ((uint)a11<<24)) )


#ifdef PMP_VAL_NAME
#define ADD_ELE( PUBKEY, val ) [ PERFECT_HASH_PP_( PUBKEY ) ] = {  . PMP_KEY = { PUBKEY },  . PMP_VAL_NAME = (val) }
#else
#define ADD_ELE( PUBKEY, val ) [ PERFECT_HASH_PP_( PUBKEY ) ] = {  . PMP_KEY = { PUBKEY } }
#endif

#define PMP_TABLE_BEGIN() static const PMP_T PMP_(tbl)[ 1<<PMP_LG_TBL_SZ ] = {
#define PMP_TABLE_END()   };

#define PMP_(n) FD_EXPAND_THEN_CONCAT3(PMP_NAME,_,n)

/* Forward declare */
static const PMP_T PMP_(tbl)[ 1<<PMP_LG_TBL_SZ ];

static inline int
PMP_(contains)( uchar const * pubkey ) {
  uint hash = PERFECT_HASH_PUBKEY( pubkey );
  return memcmp( PMP_(tbl)[ hash ].PMP_KEY, pubkey, 32UL )==0;
}

static inline PMP_T const *
PMP_(query)( uchar const * pubkey, PMP_T const * null ) {
  uint hash = PERFECT_HASH_PUBKEY( pubkey );
  int contained = memcmp( PMP_(tbl)[ hash ].PMP_KEY, pubkey, 32UL )==0;
  return fd_ptr_if( contained, PMP_(tbl)+hash, null );
}

static inline uint
PMP_(hash_or_default)( uchar const * pubkey ) {
  uint hash = PERFECT_HASH_PUBKEY( pubkey );
  int contained = memcmp( PMP_(tbl)[ hash ].PMP_KEY, pubkey, 32UL )==0;
  return fd_uint_if( contained, hash, 1U<<PMP_LG_TBL_SZ );
}

/* Unfortunately, can't #undef the variables because of how we use them
   in the macros. */
