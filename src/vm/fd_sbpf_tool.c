#include "../ballet/sbpf/fd_sbpf_loader.h"
#include "fd_sbpf_interp.h"
#include "fd_sbpf_disasm.h"
#include "fd_syscalls.h"
#include "../util/fd_util.h"

#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#include <sys/stat.h>

#include "../ballet/sbpf/fd_sbpf_maps.c"


struct fd_sbpf_tool_prog {
  void *                         bin_buf;
  fd_sbpf_program_t *            prog;
  fd_sbpf_program_info_t const * info;
  fd_sbpf_syscalls_t *           syscalls;
};

typedef struct fd_sbpf_tool_prog fd_sbpf_tool_prog_t;

static fd_sbpf_tool_prog_t *
fd_sbpf_tool_prog_create( fd_sbpf_tool_prog_t * tool_prog,
                          char const *          bin_path ) {

  /* Open file */

  FILE * bin_file = fopen( bin_path, "r" );
  if( FD_UNLIKELY( !bin_file ) )
    FD_LOG_ERR(( "fopen(\"%s\") failed: %s", bin_path, strerror( errno ) ));

  struct stat bin_stat;
  if( FD_UNLIKELY( 0!=fstat( fileno( bin_file ), &bin_stat ) ) )
    FD_LOG_ERR(( "fstat() failed: %s", strerror( errno ) ));
  if( FD_UNLIKELY( !S_ISREG( bin_stat.st_mode ) ) )
    FD_LOG_ERR(( "File \"%s\" not a regular file", bin_path ));

  /* Allocate file buffer */

  ulong  bin_sz  = (ulong)bin_stat.st_size;
  void * bin_buf = malloc( bin_sz+8UL );
  if( FD_UNLIKELY( !bin_buf ) )
    FD_LOG_ERR(( "malloc(%#lx) failed: %s", bin_sz, strerror( errno ) ));

  /* Allocate program buffer */

  ulong  prog_align     = fd_sbpf_program_align();
  ulong  prog_footprint = fd_sbpf_program_footprint();
  fd_sbpf_program_t * prog = fd_sbpf_program_new( aligned_alloc( prog_align, prog_footprint ) );

  if( FD_UNLIKELY( !prog ) )
    FD_LOG_ERR(( "aligned_alloc(%#lx, %#lx) failed: %s",
                 prog_align, prog_footprint, strerror( errno ) ));

  /* Allocate syscalls */

  fd_sbpf_syscalls_t * syscalls = fd_sbpf_syscalls_new(
      aligned_alloc( fd_sbpf_syscalls_align(), fd_sbpf_syscalls_footprint() ) );
  FD_TEST( syscalls );

  fd_vm_syscall_register_all( syscalls );

  /* Read program */

  if( FD_UNLIKELY( fread( bin_buf, bin_sz, 1UL, bin_file )!=1UL ) )
    FD_LOG_ERR(( "fread() failed: %s", strerror( errno ) ));
  FD_TEST( 0==fclose( bin_file ) );

  /* Load program */

  if( FD_UNLIKELY( 0!=fd_sbpf_program_load( prog, bin_buf, bin_sz, syscalls ) ) )
    FD_LOG_ERR(( "fd_sbpf_program_load() failed: %s", fd_sbpf_strerror() ));

  fd_sbpf_program_info_t const * info = fd_sbpf_program_get_info( prog );

  tool_prog->bin_buf   = bin_buf;
  tool_prog->prog      = prog;
  tool_prog->info = info;
  tool_prog->syscalls  = syscalls;

  return tool_prog;
}


static void
fd_sbpf_tool_prog_free( fd_sbpf_tool_prog_t * prog ) {
  free(                          prog->bin_buf    );
  free( fd_sbpf_program_delete ( prog->prog     ) );
  free( fd_sbpf_syscalls_delete( prog->syscalls ) );
}


int cmd_disasm( char const * bin_path ) {

  fd_sbpf_tool_prog_t tool_prog;
  fd_sbpf_tool_prog_create( &tool_prog, bin_path );
  FD_LOG_NOTICE(( "Loading sBPF program: %s", bin_path ));

  fd_vm_sbpf_exec_context_t ctx = {
    .entrypoint          = 0,
    .program_counter     = 0,
    .instruction_counter = 0,
    .instrs              = (fd_vm_sbpf_instr_t const *)fd_type_pun_const( tool_prog.info->text ),
    .instrs_sz           = tool_prog.info->text_cnt,
  };

  int res = fd_sbpf_disassemble_program( ctx.instrs, ctx.instrs_sz, tool_prog.syscalls, stdout );
  printf( "\n" );

  fd_sbpf_tool_prog_free( &tool_prog );

  return res;
}

int cmd_trace( char const * bin_path ) {

  fd_sbpf_tool_prog_t tool_prog;
  fd_sbpf_tool_prog_create( &tool_prog, bin_path );
  FD_LOG_NOTICE(( "Loading sBPF program: %s", bin_path ));

  ulong trace_sz = 128 * 1024;
  ulong trace_used = 0;
  fd_vm_sbpf_trace_entry_t * trace = (fd_vm_sbpf_trace_entry_t *) malloc(trace_sz * sizeof(fd_vm_sbpf_trace_entry_t));

  fd_vm_sbpf_exec_context_t ctx = {
    .entrypoint          = (long)tool_prog.info->entry_pc,
    .program_counter     = 0,
    .instruction_counter = 0,
    .instrs              = (fd_vm_sbpf_instr_t const *)fd_type_pun_const( tool_prog.info->text ),
    .instrs_sz           = tool_prog.info->text_cnt,
  };

  ulong interp_res = fd_vm_sbpf_interp_instrs_trace( &ctx, trace, trace_sz, &trace_used );
  if( interp_res != 0 ) {
    return 1;
  }

  printf( "Frame 0\n" );

  for( ulong i = 0; i < trace_used; i++ ) {
    fd_vm_sbpf_trace_entry_t trace_ent = trace[i];
    printf( "%4lu [%016lX, %016lX, %016lX, %016lX, %016lX, %016lX, %016lX, %016lX, %016lX, %016lX, %016lX] %lu:\n",
        trace_ent.ic,
        trace_ent.register_file[0],
        trace_ent.register_file[1],
        trace_ent.register_file[2],
        trace_ent.register_file[3],
        trace_ent.register_file[4],
        trace_ent.register_file[5],
        trace_ent.register_file[6],
        trace_ent.register_file[7],
        trace_ent.register_file[8],
        trace_ent.register_file[9],
        trace_ent.register_file[10],
        trace_ent.pc
      );
  }

  return 0;
}

int
main( int     argc,
      char ** argv ) {
  fd_boot( &argc, &argv );

  char const * cmd = fd_env_strip_cmdline_cstr( &argc, &argv, "--cmd", NULL, NULL );
  if( FD_UNLIKELY( !cmd ) ) {
    FD_LOG_ERR(( "missing command" ));
    fd_halt();
    return 1;
  }

  if( !strcmp( cmd, "disasm" ) ) {
    char const * program_file = fd_env_strip_cmdline_cstr( &argc, &argv, "--program_file", NULL, NULL );

    if( FD_UNLIKELY( !cmd_disasm( program_file ) ) )
      FD_LOG_ERR(( "error during disassembly" ));
  } else if( !strcmp( cmd, "trace" ) ) {
    char const * program_file = fd_env_strip_cmdline_cstr( &argc, &argv, "--program_file", NULL, NULL );
    if( FD_UNLIKELY( !cmd_trace( program_file ) ) )
      FD_LOG_ERR(( "error during trace" ));
  } else {
    FD_LOG_ERR(( "unknown command: %s", cmd ));
  }
  fd_halt();
  return 0;
}
