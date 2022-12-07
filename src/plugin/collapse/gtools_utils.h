#ifndef GTOOLS_UTILS
#define GTOOLS_UTILS

ST_double gf_benchmark (char *fname);
ST_double gf_query_free_space (char *fname);
ST_double gf_dipow(ST_double base, GT_size exp);
GT_size gf_iipow(GT_size base, GT_size exp);
void gf_split_path_file(char** p, char** f, char *pf);

void gf_write_collapsed(
    char *collapsed_file,
    ST_double *collapsed_data,
    GT_size kstart,
    GT_size kend,
    GT_size J
);

void gf_read_collapsed(
    char *collapsed_file,
    ST_double *collapsed_data,
    GT_size knum,
    GT_size J
);

#endif
