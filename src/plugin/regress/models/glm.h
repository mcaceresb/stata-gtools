#ifndef GREGRESS_GLM
#define GREGRESS_GLM

// GLM
// ---

void (*gf_regress_glm_init)(
    ST_double *,
    ST_double *,
    ST_double *,
    ST_double *,
    ST_double *,
    ST_double *,
    ST_double *,
    GT_size
);

ST_double (*gf_regress_glm_iter)(
    ST_double *,
    ST_double *,
    ST_double *,
    ST_double *,
    ST_double *,
    ST_double *,
    ST_double *,
    ST_double *,
    ST_double *,
    GT_size
);

ST_retcode gf_regress_glm_post(
    GT_bool wcode,
    ST_double *wptr,
    ST_double *e,
    ST_double *wgt,
    GT_size nj,
    ST_double diff,
    ST_double glmtol,
    GT_size glmiter,
    char *buf1
);

// Logit
// -----

void gf_regress_logit_init_w(
    ST_double *yptr,
    ST_double *wptr,
    ST_double *mu,
    ST_double *wgt,
    ST_double *eta,
    ST_double *dev,
    ST_double *lhs,
    GT_size nj
);

void gf_regress_logit_init_unw(
    ST_double *yptr,
    ST_double *wptr,
    ST_double *mu,
    ST_double *wgt,
    ST_double *eta,
    ST_double *dev,
    ST_double *lhs,
    GT_size nj
);

ST_double gf_regress_logit_iter_unw(
    ST_double *yptr,
    ST_double *wptr,
    ST_double *e,
    ST_double *mu,
    ST_double *wgt,
    ST_double *eta,
    ST_double *dev,
    ST_double *dev0,
    ST_double *lhs,
    GT_size nj
);

ST_double gf_regress_logit_iter_w(
    ST_double *yptr,
    ST_double *wptr,
    ST_double *e,
    ST_double *mu,
    ST_double *wgt,
    ST_double *eta,
    ST_double *dev,
    ST_double *dev0,
    ST_double *lhs,
    GT_size nj
);

// Poisson
// -------

void gf_regress_poisson_init_w(
    ST_double *yptr,
    ST_double *wptr,
    ST_double *mu,
    ST_double *wgt,
    ST_double *eta,
    ST_double *dev,
    ST_double *lhs,
    GT_size nj
);

void gf_regress_poisson_init_unw(
    ST_double *yptr,
    ST_double *wptr,
    ST_double *mu,
    ST_double *wgt,
    ST_double *eta,
    ST_double *dev,
    ST_double *lhs,
    GT_size nj
);

ST_double gf_regress_poisson_iter_unw(
    ST_double *yptr,
    ST_double *wptr,
    ST_double *e,
    ST_double *mu,
    ST_double *wgt,
    ST_double *eta,
    ST_double *dev,
    ST_double *dev0,
    ST_double *lhs,
    GT_size nj
);

ST_double gf_regress_poisson_iter_w(
    ST_double *yptr,
    ST_double *wptr,
    ST_double *e,
    ST_double *mu,
    ST_double *wgt,
    ST_double *eta,
    ST_double *dev,
    ST_double *dev0,
    ST_double *lhs,
    GT_size nj
);

#endif
