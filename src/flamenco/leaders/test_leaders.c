#include "fd_leaders.h"

FD_STATIC_ASSERT( alignof(fd_epoch_leaders_t)<=FD_EPOCH_LEADERS_ALIGN, alignment );


int
main( int     argc,
      char ** argv ) {
  fd_boot( &argc, &argv );

  /* TODO add test */

  FD_LOG_NOTICE(( "pass" ));
  fd_halt();
  return 0;
}
