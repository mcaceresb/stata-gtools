#include "gtools_utils.h"

int mf_min_signed(int x[], size_t N)
{
    int min = x[0];
    for (size_t i = 1; i < N; ++i) {
        if (min > x[i]) min = x[i];
    }
    return (min);
}

int mf_max_signed(int x[], size_t N)
{
    int max = x[0];
    for (size_t i = 1; i < N; ++i) {
        if (max < x[i]) max = x[i];
    }
    return (max);
}

uint64_t mf_min(uint64_t x[], size_t N)
{
    uint64_t min = x[0];
    for (size_t i = 1; i < N; ++i) {
        if (min > x[i]) min = x[i];
    }
    return (min);
}

uint64_t mf_max(uint64_t x[], size_t N)
{
    uint64_t max = x[0];
    for (size_t i = 1; i < N; ++i) {
        if (max < x[i]) max = x[i];
    }
    return (max);
}

void mf_minmax(uint64_t x[], size_t N, uint64_t * min, uint64_t * max)
{
    *min = *max = x[0];
    for (size_t i = 1; i < N; ++i) {
        if (*min > x[i]) *min = x[i];
        if (*max < x[i]) *max = x[i];
    }
}

int sf_get_vector_length(char * st_matrix)
{
    int ncol = SF_col(st_matrix);
    int nrow = SF_row(st_matrix);
    if ( (ncol > 1) & (nrow > 1) ) {
        sf_errprintf("tried to get the length a %d by %d matrix", nrow, ncol);
        return(198);
    }
    return ( ncol > nrow? ncol: nrow );
}

int sf_get_vector(char * st_matrix, double v[])
{
    ST_retcode rc ;
    ST_double  z ;
    int ncol = SF_col(st_matrix);
    int nrow = SF_row(st_matrix);
    if ( (ncol > 1) & (nrow > 1) ) {
        sf_errprintf("tried to read a %d by %d matrix into an array", nrow, ncol);
        return(198);
    }
    if ( ncol > 1 ) {
        for (int i = 0; i < ncol; i++) {
            if ( (rc = SF_mat_el(st_matrix, 1, i + 1, &z)) ) return(rc);
            v[i] = z;
        }
    }
    else {
        for (int i = 0; i < nrow; i++) {
            if ( (rc = SF_mat_el(st_matrix, i + 1, 1, &z)) ) return(rc);
            v[i] = z;
        }
    }
    return(0);
}
