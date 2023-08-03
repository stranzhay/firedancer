/*
 * TOML v1.0.0 parser (spec at https://toml.io/en/v1.0.0)
 * 
 * NOTE: This parser is non-compliant with the TOML v1.0.0 specification. It 
 * does NOT add unspecified features to the TOML specification, only omits
 * certain unimplemented feature. The parser will error gracefully when such
 * features are used accidentally. The following are the current deviations from
 * the spec:
 * 
 * - No UTF-8 document validation: We do not validate the whole document as 
 *   being a valid UTF-8 document before parsing.
 * - No date, time, or date-time types: We do not support these types yet.
 * - No floating point types: We do not support this type yet.
 * - Newlines are LF only: Only LF can be used for delimiting new lines. CRLF 
 *   will not be recognized.
 * - No whitespace in keys: Dotted keys cannot contain whitespace before or 
 *   after a dot.
 * - No inline tables: We do not support this type yet.
 */

#ifndef HEADER_fd_src_util_toml_fd_toml_h
#define HEADER_fd_src_util_toml_fd_toml_h

#include "../fd_util_base.h"
#include "../../ballet/murmur3/fd_murmur3.h"

#define FD_TOML_PARSE_SUCCESS                 (0)
#define FD_TOML_PARSE_ERR_EXPECTED_OPEN_QUOTE (-1)
#define FD_TOML_PARSE_ERR_UNEXPECTED_EOF      (-2)
#define FD_TOML_PARSE_ERR_EXPECTED_DIGIT      (-3)
#define FD_TOML_PARSE_ERR_UNEXPECTED_INPUT    (-4)
#define FD_TOML_PARSE_ERR_UNEXPECTED_NEWLINE  (-5)
#define FD_TOML_PARSE_ERR_EXPECTED_NEWLINE    (-6)
#define FD_TOML_PARSE_ERR_EXPECTED_KV_PAIR    (-7)
#define FD_TOML_PARSE_ERR_EXPECTED_KEY        (-8)


FD_PROTOTYPES_BEGIN

typedef struct fd_toml_value fd_toml_value_t;
typedef struct fd_toml_table fd_toml_table_t;

struct fd_toml_array {
  ulong             sz;
  fd_toml_value_t * values;
};
typedef struct fd_toml_array fd_toml_array_t;

union fd_toml_value_content {
  char *            string_value;
  long              integer_value;
  double            float_value;
  ulong             boolean_value;
  void *            offset_date_time_value;
  void *            local_date_time_value;
  void *            local_date_value;
  void *            local_time_value;
  fd_toml_array_t   array_value;
  fd_toml_table_t * table_value;
};
typedef union fd_toml_value_content fd_toml_value_content_t;

enum {
  fd_toml_value_type_string             = 0,
  fd_toml_value_type_integer            = 1,
  fd_toml_value_type_float              = 2,
  fd_toml_value_type_boolean            = 3,
  fd_toml_value_type_offset_date_time   = 4,
  fd_toml_value_type_local_date_time    = 5,
  fd_toml_value_type_local_date         = 6,
  fd_toml_value_type_local_time         = 7,
  fd_toml_value_type_array              = 8,
  fd_toml_value_type_table              = 9,
};

struct fd_toml_value {
  ulong                   value_type;
  fd_toml_value_content_t value_content;
};
typedef struct fd_toml_value fd_toml_value_t;

struct fd_toml_key_value_pair {
  char *          key;
  uint            hash;
  fd_toml_value_t value;
};
typedef struct fd_toml_key_value_pair fd_toml_key_value_pair_t;

struct fd_toml_table {
  fd_toml_key_value_pair_t key_value_pair;
  fd_toml_table_t * next;
};
typedef struct fd_toml_table fd_toml_table_t;

int fd_toml_parse( char * content, fd_toml_table_t * table );

int poop( ) {
  const char * path[4] = { "fruits", "apple", "color", 0} 
  int x;

}

int fd_toml_lookup_integer(  );

FD_PROTOTYPES_END

#endif /* HEADER_fd_src_util_toml_fd_toml_h */
