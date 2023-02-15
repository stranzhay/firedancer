#include <stddef.h>
#include <stdlib.h>

#include "../../../../util/fd_util.h"
#include "../../fd_quic_common.h"
#include "../../fd_quic_config.h"
#include "../../fd_quic_proto.h"
#include "../fd_quic_union.h"
#include "../fd_quic_transport_params.h"


typedef struct fd_quic_frame_context fd_quic_frame_context_t;

struct fd_quic_frame_context {
  void * quic;
  void * conn;
  void * pkt;
};


ulong
fd_quic_handle_v1_frame( uchar const *    buf,
                         ulong            buf_sz,
                         void *           scratch ) {
  fd_quic_frame_context_t frame_context[1] = {{ NULL, NULL, NULL }};

  uchar const * p     = buf;
  uchar const * p_end = buf + buf_sz;

  /* skip padding */
  while( p < p_end && *p == '\x00' ) {
    p++;
  }
  if( p == p_end ) return (ulong)(p - buf);

  /* frame id is first byte */
  uchar id    = *p;
  uchar id_lo = 255; /* allow for fragments to work */
  uchar id_hi = 0;

#include "../fd_quic_parse_frame.h"
#include "../fd_quic_frames_templ.h"
#include "../fd_quic_undefs.h"

  FD_LOG_DEBUG(( "unexpected frame type: %d  at offset: %ld", (int)*p, (long)( p - buf ) ));

  // if we get here we didn't understand "frame type"
  return FD_QUIC_PARSE_FAIL;
}


static ulong
fd_quic_frame_handle_ack_frame(
    void * vp_context,
    fd_quic_ack_frame_t * data,
    uchar const * p,
    ulong p_sz) {
  (void)vp_context;
  (void)data;
  (void)p;
  (void)p_sz;

  // fd_quic_frame_context_t context = *(fd_quic_frame_context_t*)vp_context;

  /* ack packets are not ack-eliciting (they are acked with other things) */

  uchar const * p_str = p;
  uchar const * p_end = p + p_sz;

  ulong ack_range_count = data->ack_range_count;

  // ulong cur_pkt_number = data->largest_ack - data->first_ack_range - 1u;

  /* walk thru ack ranges */
  for( ulong j = 0; j < ack_range_count; ++j ) {
    if( FD_UNLIKELY(  p_end <= p ) ) return FD_QUIC_PARSE_FAIL;

    fd_quic_ack_range_frag_t ack_range[1];
    ulong rc = fd_quic_decode_ack_range_frag( ack_range, p, (ulong)( p_end - p ) );
    if( rc == FD_QUIC_PARSE_FAIL ) return FD_QUIC_PARSE_FAIL;

    /* the number of packet numbers to skip (they are not being acked) */
    //cur_pkt_number -= ack_range->gap;

    /* adjust for next range */
    //cur_pkt_number -= ack_range->length - 1u;

    p += rc;
  }

  /* ECN counts
     we currently ignore them, but we must process them to get to the following bytes */
  if( data->type & 1u ) {
    if( FD_UNLIKELY(  p_end <= p ) ) return FD_QUIC_PARSE_FAIL;

    fd_quic_ecn_counts_frag_t ecn_counts[1];
    ulong rc = fd_quic_decode_ecn_counts_frag( ecn_counts, p, (ulong)( p_end - p ) );
    if( rc == FD_QUIC_PARSE_FAIL ) return FD_QUIC_PARSE_FAIL;

    p += rc;
  }

  return (ulong)( p - p_str );
}

static ulong
fd_quic_frame_handle_ack_range_frag(
    void * context,
    fd_quic_ack_range_frag_t * data,
    uchar const * p,
    ulong p_sz) {
  (void)context;
  (void)data;
  (void)p;
  (void)p_sz;
  return FD_QUIC_PARSE_FAIL;
}

static ulong
fd_quic_frame_handle_ecn_counts_frag(
    void * context,
    fd_quic_ecn_counts_frag_t * data,
    uchar const * p,
    ulong p_sz) {
  (void)context;
  (void)data;
  (void)p;
  (void)p_sz;
  return FD_QUIC_PARSE_FAIL;
}

static ulong
fd_quic_frame_handle_reset_stream_frame(
    void * context,
    fd_quic_reset_stream_frame_t * data,
    uchar const * p,
    ulong p_sz) {
  (void)context;
  (void)data;
  (void)p;
  (void)p_sz;
  return FD_QUIC_PARSE_FAIL;
}

static ulong
fd_quic_frame_handle_stop_sending_frame(
    void * context,
    fd_quic_stop_sending_frame_t * data,
    uchar const * p,
    ulong p_sz) {
  (void)context;
  (void)data;
  (void)p;
  (void)p_sz;
  return FD_QUIC_PARSE_FAIL;
}

static ulong
fd_quic_frame_handle_new_token_frame(
    void * context,
    fd_quic_new_token_frame_t * data,
    uchar const * p,
    ulong p_sz) {
  (void)context;
  (void)data;
  (void)p;
  (void)p_sz;
  return FD_QUIC_PARSE_FAIL;
}

static ulong
fd_quic_frame_handle_stream_frame(
    void *                       vp_context,
    fd_quic_stream_frame_t *     data,
    uchar const *                p,
    ulong                       p_sz ) {
  (void)vp_context;
  (void)data;
  (void)p;
  (void)p_sz;

  ulong data_sz   = data->length_opt ? data->length : p_sz;

  /* packet bytes consumed */
  return data_sz;
}

static ulong
fd_quic_frame_handle_max_data_frame(
    void *                     vp_context,
    fd_quic_max_data_frame_t * data,
    uchar const *              p,
    ulong                     p_sz ) {
  /* unused */
  (void)vp_context;
  (void)data;
  (void)p;
  (void)p_sz;

  return 0; /* no additional bytes consumed from buffer */
}

static ulong
fd_quic_frame_handle_max_stream_data(
    void *                      vp_context,
    fd_quic_max_stream_data_t * data,
    uchar const *               p,
    ulong                      p_sz ) {
  (void)vp_context;
  (void) data;
  (void)p;
  (void)p_sz;

  return 0;
}

static ulong
fd_quic_frame_handle_max_streams_frame(
    void * context,
    fd_quic_max_streams_frame_t * data,
    uchar const * p,
    ulong p_sz) {
  (void)context;
  (void)data;
  (void)p;
  (void)p_sz;
  return FD_QUIC_PARSE_FAIL;
}

static ulong
fd_quic_frame_handle_data_blocked_frame(
    void * context,
    fd_quic_data_blocked_frame_t * data,
    uchar const * p,
    ulong p_sz) {
  (void)context;
  (void)data;
  (void)p;
  (void)p_sz;
  return FD_QUIC_PARSE_FAIL;
}

static ulong
fd_quic_frame_handle_stream_data_blocked_frame(
    void * context,
    fd_quic_stream_data_blocked_frame_t * data,
    uchar const * p,
    ulong p_sz) {
  (void)context;
  (void)data;
  (void)p;
  (void)p_sz;
  return FD_QUIC_PARSE_FAIL;
}

static ulong
fd_quic_frame_handle_streams_blocked_frame(
    void * context,
    fd_quic_streams_blocked_frame_t * data,
    uchar const * p,
    ulong p_sz) {
  (void)context;
  (void)data;
  (void)p;
  (void)p_sz;
  return FD_QUIC_PARSE_FAIL;
}

static ulong
fd_quic_frame_handle_new_conn_id_frame(
    void * context,
    fd_quic_new_conn_id_frame_t * data,
    uchar const * p,
    ulong p_sz) {
  (void)context;
  (void)data;
  (void)p;
  (void)p_sz;
  return FD_QUIC_PARSE_FAIL;
}

static ulong
fd_quic_frame_handle_retire_conn_id_frame(
    void * context,
    fd_quic_retire_conn_id_frame_t * data,
    uchar const * p,
    ulong p_sz) {
  (void)context;
  (void)data;
  (void)p;
  (void)p_sz;
  return FD_QUIC_PARSE_FAIL;
}

static ulong
fd_quic_frame_handle_path_challenge_frame(
    void * context,
    fd_quic_path_challenge_frame_t * data,
    uchar const * p,
    ulong p_sz) {
  (void)context;
  (void)data;
  (void)p;
  (void)p_sz;
  return FD_QUIC_PARSE_FAIL;
}

static ulong
fd_quic_frame_handle_path_response_frame(
    void * context,
    fd_quic_path_response_frame_t * data,
    uchar const * p,
    ulong p_sz) {
  (void)context;
  (void)data;
  (void)p;
  (void)p_sz;
  return FD_QUIC_PARSE_FAIL;
}

static ulong
fd_quic_frame_handle_conn_close_frame(
    void *                       vp_context,
    fd_quic_conn_close_frame_t * data,
    uchar const *                p,
    ulong                       p_sz ) {
  (void)vp_context;
  (void)data;
  (void)p;
  (void)p_sz;
  
  return 0u;
}

static ulong
fd_quic_frame_handle_handshake_done_frame(
    void *                           vp_context,
    fd_quic_handshake_done_frame_t * data,
    uchar const *                    p,
    ulong                            p_sz) {
  (void)vp_context;
  (void)data;
  (void)p;
  (void)p_sz;

  return 0;
}

static ulong
fd_quic_frame_handle_common_frag(
    void * context,
    fd_quic_common_frag_t * data,
    uchar const * p,
    ulong p_sz) {
  (void)context;
  (void)data;
  (void)p;
  (void)p_sz;
  /* this callback is completely unused */
  /* TODO tag template to not generate code for this */
  return FD_QUIC_PARSE_FAIL;
}

static ulong
fd_quic_frame_handle_crypto_frame( void *                   vp_context,
                                   fd_quic_crypto_frame_t * crypto,
                                   uchar const *            p,
                                   ulong                   p_sz ) {
  (void) vp_context;
  (void) crypto;
  (void) p;
  (void) p_sz;
  return 0;
}

static ulong
fd_quic_frame_handle_ping_frame(
    void *                 vp_context,
    fd_quic_ping_frame_t * data,
    uchar const *          p,
    ulong                 p_sz ) {
  (void)data;
  (void)p;
  (void)p_sz;
  (void)vp_context;

  return 0;
}

static ulong
fd_quic_frame_handle_padding_frame(
    void * context,
    fd_quic_padding_frame_t * data,
    uchar const * p,
    ulong p_sz) {
  (void)context;
  (void)data;
  (void)p;
  (void)p_sz;
  return 0;
}


int
LLVMFuzzerInitialize( int  *   argc,
                      char *** argv ) {
  /* Set up shell without signal handlers */
  putenv( "FD_LOG_BACKTRACE=0" );
  fd_boot( argc, argv );
  atexit( fd_halt );

  return 0;
}

int
LLVMFuzzerTestOneInput( uchar const * data,
                        ulong         size ) {

  void * buf = malloc(sizeof(fd_quic_frame_u));
  
  fd_quic_handle_v1_frame( data, size, buf );

  free(buf);
  return 0;
}
