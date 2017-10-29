#ifndef SF_WRAPPERS
#define SF_WRAPPERS

#include <time.h>
#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <limits.h>
#include "gttypes.h"
#include "../spi/stplugin.h"

GT_size sf_anyobs_sel ();

void sf_running_timer (clock_t *timer, const char *msg);

ST_retcode sf_oom_error (char * step_desc, char * obj_desc);

GT_int     sf_get_vector_length (char *st_matrix);
ST_retcode sf_get_vector        (char *st_matrix, ST_double *v);
ST_retcode sf_get_vector_int    (char *st_matrix, GT_size *v);

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

#endif
