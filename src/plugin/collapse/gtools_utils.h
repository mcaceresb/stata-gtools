#ifndef GTOOLS_UTILS
#define GTOOLS_UTILS

double mf_benchmark (char *fname);
double mf_query_free_space (char *fname);
void mf_split_path_file(char** p, char** f, char *pf);

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

#endif
