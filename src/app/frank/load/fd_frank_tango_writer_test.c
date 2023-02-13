#include "../../../disco/fd_disco.h"

int
fd_frank_tango_writer_test( int     argc,
                            char ** argv ) {

    (void)argc;
    fd_log_thread_set( argv[0] );

    /* Parse command-line arguments */
    char const * pod_gaddr = argv[1];
    char const * cfg_path  = argv[2];

    /* Load configuration for this frank instance */
    FD_LOG_INFO(( "using configuration in pod %s at path %s", pod_gaddr, cfg_path ));
    uchar const * pod     = fd_wksp_pod_attach( pod_gaddr );
    uchar const * cfg_pod = fd_pod_query_subpod( pod, cfg_path );
    if( FD_UNLIKELY( !cfg_pod ) ) FD_LOG_ERR(( "path not found" ));

    

}
