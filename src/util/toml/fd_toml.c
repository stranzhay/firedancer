#include "fd_toml.h"
#include <stdlib.h>

struct fd_toml_parser_context {
  char *  content;
  ulong   cursor;
  ulong   len;
};
typedef struct fd_toml_parser_context fd_toml_parser_context_t;

uint
fd_toml_is_dec_digit( char c ) {
  return c >= '0' && c <= '9';
}

uint
fd_toml_is_minus_sign( char c ) {
  return c == '-';
}

uint
fd_toml_is_hex_prefix( char c0, char c1 ) {
  return c0 == '0' && c1 == 'x';
}

uint
fd_toml_is_underscore( char c ) {
  return c == '_';
}

uint
fd_toml_is_quote( char c ) {
  return c == '"';
}

uint
fd_toml_is_whitespace( char c ) {
  return c == ' ' || c == '\t';
}

uint
fd_toml_is_newline( char c ) {
  return c == '\n';
}

uint
fd_toml_is_nul( char c ) {
  return c == '\0';
}

uint
fd_toml_is_dot( char c ) {
  return c == '.';
}

uint
fd_toml_is_letter( char c ) {
  return ( c >= 'A' && c <= 'Z' ) 
      || ( c >= 'a' && c <= 'z' );
}

uint
fd_toml_is_equals_sign( char c ) {
  return c == '=';
}

void
fd_toml_consume_char( fd_toml_parser_context_t * ctx ) {
  ctx->cursor++;
}

void
fd_toml_consume_whitespace( fd_toml_parser_context_t * ctx ) {
  char next_char0 = ctx->content[ctx->cursor];
  while( fd_toml_is_whitespace( next_char0 ) ) {
    fd_toml_consume_char( ctx );
    next_char0 = ctx->content[ctx->cursor];
  }
}

int
fd_toml_parse_integer( fd_toml_parser_context_t * ctx, fd_toml_value_t * value ) {
  long integer = 0;

  char next_char0 = ctx->content[ctx->cursor];
  if( !fd_toml_is_dec_digit( next_char0 ) ) {
    return FD_TOML_PARSE_ERR_EXPECTED_DIGIT;
  }

  integer = (long)(next_char0 - '0');

  fd_toml_consume_char( ctx );
  next_char0 = ctx->content[ctx->cursor];

  while(1) {
    if( fd_toml_is_dec_digit( next_char0 ) ) {
      integer *= 10;
      integer += (long)(next_char0 - '0');  
    } else if( fd_toml_is_nul( next_char0 ) ) {
      break;
    } else if( fd_toml_is_whitespace( next_char0 ) ) {
      break;
    } else if( fd_toml_is_newline( next_char0 ) ) {
      break;
    } else if( fd_toml_is_underscore( next_char0 ) ) {
      // no-op
    } else {
      return FD_TOML_PARSE_ERR_EXPECTED_DIGIT;
    }

    fd_toml_consume_char( ctx );
    next_char0 = ctx->content[ctx->cursor];
  }

  value->value_type = fd_toml_value_type_integer;
  value->value_content.integer_value = integer;
  return FD_TOML_PARSE_SUCCESS;
}

int
fd_toml_parse_string( fd_toml_parser_context_t * ctx, fd_toml_value_t * value ) {
  char next_char0 = ctx->content[ctx->cursor];
  if( !fd_toml_is_quote( next_char0 ) ) {
    return FD_TOML_PARSE_ERR_EXPECTED_OPEN_QUOTE;
  }

  fd_toml_consume_char( ctx );
  ulong string_start_idx = ctx->cursor;
  next_char0 = ctx->content[ctx->cursor];

  while(1) {
    if( fd_toml_is_nul( next_char0 ) ) {
      return FD_TOML_PARSE_ERR_UNEXPECTED_EOF;
    } else if( fd_toml_is_newline( next_char0 ) ) {
      return FD_TOML_PARSE_ERR_UNEXPECTED_NEWLINE;
    } else if( fd_toml_is_quote( next_char0 ) ) {
      break;
    }
    // TODO: handle escaping
    
    fd_toml_consume_char( ctx );
    next_char0 = ctx->content[ctx->cursor];
  }
  
  ulong string_end_idx = ctx->cursor;
  fd_toml_consume_char( ctx );

  ulong string_len = string_end_idx - string_start_idx;
  char * string = (char *)malloc( sizeof( char ) * ( string_len + 1 ) );
  fd_memcpy( string, &ctx->content[string_start_idx], string_len );
  string[string_len] = '\0';

  value->value_type = fd_toml_value_type_string;
  value->value_content.string_value = string;
  return FD_TOML_PARSE_SUCCESS;
}

int
fd_toml_parse_value( fd_toml_parser_context_t * ctx, fd_toml_value_t * value ) {
  char next_char0 = ctx->content[ctx->cursor];
  char next_char1 = ((ctx->cursor + 1) > ctx->len) ? '\0' : ctx->content[ctx->cursor + 1];
  (void) next_char1;

  int err;
  if( fd_toml_is_quote( next_char0 ) ) {
    if( ( err = fd_toml_parse_string( ctx, value ) ) != FD_TOML_PARSE_SUCCESS ) {
      return err;
    }
  } else if( fd_toml_is_dec_digit( next_char0 ) ) {
    if( ( err = fd_toml_parse_integer( ctx, value ) ) != FD_TOML_PARSE_SUCCESS ) {
      return err;
    }
  } else {
    return FD_TOML_PARSE_ERR_UNEXPECTED_INPUT;
  }

  return FD_TOML_PARSE_SUCCESS;
}



uint
fd_toml_is_key_part_char( char c ) {
  return fd_toml_is_letter( c ) 
      || fd_toml_is_dec_digit( c )
      || fd_toml_is_underscore( c )
      || fd_toml_is_minus_sign( c );
}

int
fd_toml_parse_key_part( fd_toml_parser_context_t * ctx ) {
  char next_char0 = ctx->content[ctx->cursor];
  if( !fd_toml_is_key_part_char( next_char0 ) ) {
    return FD_TOML_PARSE_ERR_EXPECTED_KEY;
  }

  ulong key_part_start_idx = ctx->cursor;
  fd_toml_consume_char( ctx );
  next_char0 = ctx->content[ctx->cursor];

  while( 1 ) {
    if( fd_toml_is_key_part_char( next_char0 ) ) {
      // no-op
    } else if( fd_toml_is_dot( next_char0 ) ) {
      break;
    } else if( fd_toml_is_whitespace( next_char0 ) ) {
      break;
    } else if( fd_toml_is_equals_sign( next_char0 ) ) {
      break;
    } else {
      return FD_TOML_PARSE_ERR_EXPECTED_KEY;
    }
    
    fd_toml_consume_char( ctx );
    next_char0 = ctx->content[ctx->cursor];
  }

  ulong key_part_end_idx = ctx->cursor;
  ulong key_part_len = key_part_end_idx - key_part_start_idx;

  char * key_part = (char *)malloc( sizeof( char ) * ( key_part_len + 1 ) );
  fd_memcpy( key_part, &ctx->content[key_part_start_idx], key_part_len );
  key_part[key_part_len] = '\0';

  return FD_TOML_PARSE_SUCCESS;
}

int fd_toml_parse_key( fd_toml_parser_context_t * ctx );

int
fd_toml_parse_key_tail( fd_toml_parser_context_t * ctx ) {
  char next_char0 = ctx->content[ctx->cursor];
  if( !fd_toml_is_dot( next_char0 ) ) {
    return FD_TOML_PARSE_ERR_EXPECTED_KEY;
  }

  fd_toml_consume_char( ctx );

  int err;
  if( ( err = fd_toml_parse_key( ctx ) ) != FD_TOML_PARSE_SUCCESS ) {
    return err;
  }

  return FD_TOML_PARSE_SUCCESS;
}

int
fd_toml_parse_key( fd_toml_parser_context_t * ctx ) {
  char next_char0 = ctx->content[ctx->cursor];

  int err;
  if( ( err = fd_toml_parse_key_part( ctx ) ) != FD_TOML_PARSE_SUCCESS ) {
    return err;
  }
  
  next_char0 = ctx->content[ctx->cursor];
  if( fd_toml_is_dot( next_char0 ) ) {
    if( ( err = fd_toml_parse_key_tail( ctx ) ) != FD_TOML_PARSE_SUCCESS ) {
      return err;
    }
  } else if( fd_toml_is_whitespace( next_char0 ) ) {
    return FD_TOML_PARSE_SUCCESS;
  } else if( fd_toml_is_equals_sign( next_char0 ) ) {
    return FD_TOML_PARSE_SUCCESS;
  } else {
    return FD_TOML_PARSE_ERR_EXPECTED_KEY;
  }

  return FD_TOML_PARSE_ERR_EXPECTED_KEY;
}

int
fd_toml_parse_key_value_pair( fd_toml_parser_context_t * ctx, fd_toml_key_value_pair_t * key_value_pair ) {
  (void)key_value_pair;
  fd_toml_consume_whitespace( ctx );
  fd_toml_parse_key( ctx );
  fd_toml_consume_whitespace( ctx );

  char next_char0 = ctx->content[ctx->cursor];
  if( !fd_toml_is_equals_sign( next_char0 ) ) {
    return FD_TOML_PARSE_ERR_EXPECTED_KV_PAIR;
  }
  fd_toml_consume_char( ctx );

  fd_toml_consume_whitespace( ctx );
  fd_toml_parse_value( ctx, NULL );
  fd_toml_consume_whitespace( ctx );

  next_char0 = ctx->content[ctx->cursor];
  if( !fd_toml_is_newline( next_char0 ) ) {
    return FD_TOML_PARSE_ERR_EXPECTED_NEWLINE;
  }
  fd_toml_consume_char( ctx );

  return FD_TOML_PARSE_SUCCESS;
}
 
int
fd_toml_parse_table( fd_toml_parser_context_t * ctx ) {
  (void)ctx;
  return -1;
}