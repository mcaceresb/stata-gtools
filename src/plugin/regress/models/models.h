#ifndef GREGRESS_MODELS
#define GREGRESS_MODELS

// OLS
// ---

GT_bool (*gf_regress_ols) (
    ST_double *,
    ST_double *,
    ST_double *,
    ST_double *,
    ST_double *,
    ST_double *,
    ST_double *,
    GT_size *,
    GT_size,
    GT_size
);

GT_bool gf_regress_ols_colmajor(
    ST_double *X,
    ST_double *y,
    ST_double *w,
    ST_double *XX,
    ST_double *Xy,
    ST_double *e,
    ST_double *b,
    GT_size *colix,
    GT_size N,
    GT_size kx
);

GT_bool gf_regress_ols_wcolmajor(
    ST_double *X,
    ST_double *y,
    ST_double *w,
    ST_double *XX,
    ST_double *Xy,
    ST_double *e,
    ST_double *b,
    GT_size *colix,
    GT_size N,
    GT_size kx
);

// IV regression
// -------------

GT_bool (*gf_regress_iv) (
    ST_double *,
    ST_double *,
    ST_double *,
    ST_double *,
    ST_double *,
    ST_double *,
    ST_double *,
    ST_double *,
    ST_double *,
    ST_double *,
    GT_size *,
    GT_size,
    GT_size,
    GT_size,
    GT_size
);

GT_bool gf_regress_iv_unw(
    ST_double *Xendog,
    ST_double *Xexog,
    ST_double *Z,
    ST_double *y,
    ST_double *w,
    ST_double *XX,
    ST_double *XZ,
    ST_double *BZ,
    ST_double *e,
    ST_double *b,
    GT_size *colix,
    GT_size N,
    GT_size kendog,
    GT_size kexog,
    GT_size kz
);

GT_bool gf_regress_iv_w(
    ST_double *Xendog,
    ST_double *Xexog,
    ST_double *Z,
    ST_double *y,
    ST_double *w,
    ST_double *XX,
    ST_double *XZ,
    ST_double *BZ,
    ST_double *e,
    ST_double *b,
    GT_size *colix,
    GT_size N,
    GT_size kendog,
    GT_size kexog,
    GT_size kz
);

void gf_regress_linalg_iverror(
    ST_double *y,
    ST_double *A1,
    ST_double *A2,
    ST_double *b,
    ST_double *c,
    GT_size N,
    GT_size k1,
    GT_size k2
);

void gf_regress_linalg_iverror_ix(
    ST_double *y,
    ST_double *A1,
    ST_double *A2,
    ST_double *b,
    ST_double *c,
    GT_size *colix,
    GT_size N,
    GT_size koffset,
    GT_size k1,
    GT_size k2
);

void gf_regress_linalg_ivcollinear_ix(
    GT_size *colix,
    GT_size kendog,
    GT_size kexog,
    GT_size kz
);

#endif
