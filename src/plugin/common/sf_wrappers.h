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
ST_retcode sf_get_vector_int    (char *st_matrix, GT_int  *v);
ST_retcode sf_get_vector_size   (char *st_matrix, GT_size *v);
ST_retcode sf_get_vector_bool   (char *st_matrix, GT_bool *v);
ST_retcode sf_byx_save          (struct StataInfo *st_info);

void sf_format_size (GT_size n, char *out);

#endif
