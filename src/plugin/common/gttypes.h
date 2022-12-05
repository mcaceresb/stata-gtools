#ifndef GTOOLS_TYPES
#define GTOOLS_TYPES

#include <inttypes.h>
#include <sys/types.h>

typedef uint8_t   GT_bool ;
typedef uint64_t  GT_size ;
typedef int64_t   GT_int ;
typedef uint16_t  GT_smallsize ;
typedef int16_t   GT_smallint ;

// #if defined(_WIN64) || defined(_WIN32)
// #    define GT_size_cfmt "%lu"
// #    define GT_size_sfmt "lu"
// #    define GT_int_cfmt  "%ld"
// #    define GT_int_sfmt  "ld"
// #else
// #    define GT_size_cfmt "%'lu"
// #    define GT_size_sfmt "lu"
// #    define GT_int_cfmt  "%'ld"
// #    define GT_int_sfmt  "ld"
// #endif

// #if defined(_WIN64) || defined(_WIN32)
// #    define GT_size_cfmt "%I64u"
// #    define GT_size_sfmt "I64u"
// #    define GT_int_cfmt  "%I64d"
// #    define GT_int_sfmt  "I64d"
// #else
// #    define GT_size_cfmt "%'I64u"
// #    define GT_size_sfmt "I64u"
// #    define GT_int_cfmt  "%'I64d"
// #    define GT_int_sfmt  "I64d"
// #endif

// NOTE: Comma-printing via locale messes up on some systems, presumably
// because their locale is reset in a way that makes Stata give errors.
// Best to not rely on locale at all.

/*
 * #if defined(_WIN64) || defined(_WIN32)
 *
 * #define COMMA_PRINTING                      \
 *     setlocale(LC_NUMERIC, "");              \
 *     struct lconv *ptrLocale = localeconv(); \
 *     strcpy(ptrLocale->thousands_sep, ",");
 * #else
 * #define COMMA_PRINTING setlocale (LC_ALL, "");
 * #endif
 *
 */

// #if defined(_WIN64) || defined(_WIN32)
// #    define GT_size_cfmt "%" PRIu64
// #    define GT_size_sfmt PRIu64
// #    define GT_int_cfmt  "%" PRId64
// #    define GT_int_sfmt  PRId64
// #else
// #    define GT_size_cfmt "%'" PRIu64
// #    define GT_size_sfmt PRIu64
// #    define GT_int_cfmt  "%'" PRId64
// #    define GT_int_sfmt  PRId64
// #endif

#define GT_size_cfmt "%" PRIu64
#define GT_size_sfmt PRIu64
#define GT_int_cfmt  "%" PRId64
#define GT_int_sfmt  PRId64

#endif
