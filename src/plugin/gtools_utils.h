#ifndef GTOOLS_UTILS
#define GTOOLS_UTILS

#ifdef __APPLE__
#else
void * memcpy (void *dest, const void *src, size_t n);
#endif

int mf_strcmp_wrapper (char * fname, char *compare);

void sf_running_timer (clock_t *timer, const char *msg);

int sf_get_vector_length(char * st_matrix);
int sf_get_vector(char * st_matrix, double v[]);

int mf_sum_signed(int x[], size_t N);
int mf_min_signed(int x[], size_t N);
int mf_max_signed(int x[], size_t N);

uint64_t mf_min(uint64_t x[], size_t N);
uint64_t mf_max(uint64_t x[], size_t N);

void mf_minmax(
    uint64_t x[],
    size_t N,
    uint64_t * min,
    uint64_t * max
);

double mf_benchmark (char *fname);
double mf_query_free_space (char *fname);

void mf_write_collapsed(
    char *collapsed_file,
    double *collapsed_data,
    size_t kstart,
    size_t kend,
    size_t J
);

void mf_read_collapsed(
    char *collapsed_file,
    double *collapsed_data,
    size_t knum,
    size_t J
);

void mf_split_path_file(char** p, char** f, char *pf);

#endif
