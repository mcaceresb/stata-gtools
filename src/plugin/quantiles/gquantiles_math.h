#ifndef GTOOLS_GQUANTILES_MATH
#define GTOOLS_GQUANTILES_MATH

void gf_quantiles_nq (
    ST_double *qout,
    ST_double *x,
    GT_size nquants,
    GT_size N,
    GT_size kx
);

void gf_quantiles (
    ST_double *qout,
    ST_double *x,
    ST_double *quants,
    GT_size nquants,
    GT_size N,
    GT_size kx
);

void gf_quantiles_nq_altdef (
    ST_double *qout,
    ST_double *x,
    GT_size nquants,
    GT_size N,
    GT_size kx
);

void gf_quantiles_altdef (
    ST_double *qout,
    ST_double *x,
    ST_double *quants,
    GT_size nquants,
    GT_size N,
    GT_size kx
);

void gf_quantiles_nq_qselect (
    ST_double *qout,
    ST_double *x,
    GT_size nquants,
    GT_size N
);

void gf_quantiles_qselect (
    ST_double *qout,
    ST_double *x,
    ST_double *quants,
    GT_size nquants,
    GT_size N
);

void gf_quantiles_nq_qselect_altdef (
    ST_double *qout,
    ST_double *x,
    GT_size nquants,
    GT_size N
);

void gf_quantiles_qselect_altdef (
    ST_double *qout,
    ST_double *x,
    ST_double *quants,
    GT_size nquants,
    GT_size N
);

GT_size gf_quantiles_gcd (
    GT_size a,
    GT_size b
);

#endif
