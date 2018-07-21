#ifndef GQUANTILES_MATH_W
#define GQUANTILES_MATH_W

void gf_quantiles_nq_w (
    ST_double *qout,
    ST_double *x,
    GT_size nquants,
    GT_size N,
    GT_size kx
);

void gf_quantiles_w (
    ST_double *qout,
    ST_double *x,
    ST_double *quants,
    GT_size nquants,
    GT_size N,
    GT_size kx
);

#endif
