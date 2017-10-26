#ifndef ST_GENTOOLS
#define ST_GENTOOLS

#ifdef __APPLE__
#else
void * memcpy (void *dest, const void *src, size_t n);
#endif

// Stata utilities
// ---------------

size_t sf_anyobs_sel ();

void sf_running_timer (clock_t *timer, const char *msg);

int sf_oom_error (char * step_desc, char * obj_desc);

int sf_get_vector_length (char *st_matrix);
int sf_get_vector        (char *st_matrix, double *v);
int sf_get_vector_int    (char *st_matrix, size_t *v);

#endif
