#ifndef GREGRESS
#define GREGRESS

ST_retcode sf_regress (struct StataInfo *st_info, int level, char *fname);

ST_retcode sf_regress_read_colmajor (
    struct StataInfo *st_info,
    ST_double *y,
    ST_double *X,
    ST_double *w,
    void      *G,
    void      *FE,
    ST_double *I,
    GT_size   *nj
);

ST_retcode sf_regress_read_rowmajor (
    struct StataInfo *st_info,
    ST_double *y,
    ST_double *X,
    ST_double *w,
    void      *G,
    void      *FE,
    ST_double *I,
    GT_size   *nj
);

ST_retcode (*sf_regress_read)(
    struct StataInfo *,
    ST_double *,
    ST_double *,
    ST_double *,
    void *,
    void *,
    ST_double *,
    GT_size *
);

ST_retcode gf_regress_absorb (
    struct GtoolsHash *AbsorbHashes,
    GtoolsGroupByTransform GtoolsGroupByTransform,
    GtoolsGroupByHDFE GtoolsGroupByHDFE,
    ST_double *stats,
    GT_size *maps,
    GT_size nj,
    GT_size kabs,
    GT_size kx,
    GT_size *kmodel,
    ST_double *njabsptr,
    ST_double *xptr,
    ST_double *yptr,
    ST_double *wptr,
    ST_double *xtarget,
    ST_double *ytarget,
    GT_bool setup,
    ST_double hdfetol
);

ST_retcode gf_regress_absorb_iter(
    struct GtoolsHash *AbsorbHashes,
    GtoolsGroupByTransform GtoolsGroupByTransform,
    GtoolsGroupByHDFE GtoolsGroupByHDFE,
    ST_double *stats,
    GT_size *maps,
    GT_size J,
    GT_size *nj,
    GT_size kabs,
    GT_size kx,
    ST_double *njabsptr,
    ST_double *xptr,
    ST_double *yptr,
    ST_double *wptr,
    ST_double hdfetol
);

ST_retcode gf_regress_iv_notidentified (
    GT_size nj,
    GT_size kabs,
    GT_size ivkendog,
    GT_size ivkexog,
    GT_size ivkz,
    GT_size kmodel,
    char *buf1,
    char *buf2,
    char *buf3
);

ST_retcode gf_regress_notidentified (
    GT_size nj,
    GT_size kabs,
    GT_size kx,
    GT_size kmodel,
    char *buf1,
    char *buf2,
    char *buf3
);

// ------------------------
// Linear Algebra Functions
// ------------------------

// Finite sample adjustment

typedef ST_double (*gf_regress_vceadj)(
    GT_size,
    GT_size,
    GT_size,
    ST_double *
);

ST_double gf_regress_vceadj_ols_robust     (GT_size N, GT_size kmodel, GT_size J, ST_double *w);
ST_double gf_regress_vceadj_ols_cluster    (GT_size N, GT_size kmodel, GT_size J, ST_double *w);
ST_double gf_regress_vceadj_mle_robust     (GT_size N, GT_size kmodel, GT_size J, ST_double *w);
ST_double gf_regress_vceadj_mle_cluster    (GT_size N, GT_size kmodel, GT_size J, ST_double *w);
ST_double gf_regress_vceadj_ols_robust_fw  (GT_size N, GT_size kmodel, GT_size J, ST_double *w);
ST_double gf_regress_vceadj_ols_cluster_fw (GT_size N, GT_size kmodel, GT_size J, ST_double *w);
ST_double gf_regress_vceadj_mle_robust_fw  (GT_size N, GT_size kmodel, GT_size J, ST_double *w);
ST_double gf_regress_vceadj_mle_cluster_fw (GT_size N, GT_size kmodel, GT_size J, ST_double *w);

// Naming convention _tries_ to follow BLAS notation
//
// https://www.gnu.org/software/gsl/doc/html/blas.html

// Column-major order!

void gf_regress_linalg_dgemm_colmajor      (ST_double *A, ST_double *B, ST_double *C, GT_size k1, GT_size k2, GT_size k3);
void gf_regress_linalg_dsymm_colmajor      (ST_double *A, ST_double *B, ST_double *C, GT_size N, GT_size K);
void gf_regress_linalg_dgemTv_colmajor     (ST_double *A, ST_double *b, ST_double *c, GT_size N, GT_size K);
void gf_regress_linalg_dgemTm_colmajor     (ST_double *A, ST_double *B, ST_double *C, GT_size N, GT_size k1, GT_size k2);
void gf_regress_linalg_dgemv_colmajor      (ST_double *A, ST_double *b, ST_double *c, GT_size N, GT_size K);
void gf_regress_linalg_error_colmajor      (ST_double *y, ST_double *A, ST_double *b, ST_double *c, GT_size N, GT_size K);

void gf_regress_linalg_dsymm_wcolmajor     (ST_double *A, ST_double *B, ST_double *C, ST_double *w, GT_size N, GT_size K);
void gf_regress_linalg_dsymm_w2colmajor    (ST_double *A, ST_double *B, ST_double *C, ST_double *w, GT_size N, GT_size K);
void gf_regress_linalg_dsymm_we2colmajor   (ST_double *A, ST_double *B, ST_double *C, ST_double *e, ST_double *w, GT_size N, GT_size K);
void gf_regress_linalg_dsymm_fwe2colmajor  (ST_double *A, ST_double *B, ST_double *C, ST_double *e, ST_double *w, GT_size N, GT_size K);
void gf_regress_linalg_dgemTv_wcolmajor    (ST_double *A, ST_double *b, ST_double *c, ST_double *w, GT_size N, GT_size K);
void gf_regress_linalg_dgemTm_wcolmajor    (ST_double *A, ST_double *B, ST_double *C, ST_double *w, GT_size N, GT_size k1, GT_size k2);
void gf_regress_linalg_error_wcolmajor     (ST_double *y, ST_double *A, ST_double *b, ST_double *w, ST_double *c, GT_size N, GT_size K);

void gf_regress_linalg_dsymm_ixcolmajor    (ST_double *A, ST_double *B, ST_double *C, GT_size *ix, GT_size nix, GT_size N, GT_size K);
void gf_regress_linalg_dgemTv_ixcolmajor   (ST_double *A, ST_double *b, ST_double *c, GT_size *ix, GT_size nix, GT_size N, GT_size K);
void gf_regress_linalg_error_ixcolmajor    (ST_double *y, ST_double *A, ST_double *b, GT_size *ix, GT_size nix, ST_double *c, GT_size N, GT_size K);

void gf_regress_linalg_dsymm_wixcolmajor   (ST_double *A, ST_double *B, ST_double *C, ST_double *w, GT_size *ix, GT_size nix, GT_size N, GT_size K);
void gf_regress_linalg_dsymm_w2ixcolmajor  (ST_double *A, ST_double *B, ST_double *C, ST_double *w, GT_size *ix, GT_size nix, GT_size N, GT_size K);
void gf_regress_linalg_dsymm_we2ixcolmajor (ST_double *A, ST_double *B, ST_double *C, ST_double *e, ST_double *w, GT_size *ix, GT_size nix, GT_size N, GT_size K);
void gf_regress_linalg_dsymm_fwe2ixcolmajor(ST_double *A, ST_double *B, ST_double *C, ST_double *e, ST_double *w, GT_size *ix, GT_size nix, GT_size N, GT_size K);
void gf_regress_linalg_dgemTv_wixcolmajor  (ST_double *A, ST_double *b, ST_double *c, ST_double *w, GT_size *ix, GT_size nix, GT_size N, GT_size K);
void gf_regress_linalg_error_wixcolmajor   (ST_double *y, ST_double *A, ST_double *b, ST_double *w, GT_size *ix, GT_size nix, ST_double *c, GT_size N, GT_size K);

// Row-major order!

void gf_regress_linalg_dgemm_rowmajor      (ST_double *A, ST_double *B, ST_double *C, GT_size k1, GT_size k2, GT_size k3);
void gf_regress_linalg_dsymm_rowmajor      (ST_double *A, ST_double *B, ST_double *C, GT_size N, GT_size K);
void gf_regress_linalg_dgemTv_rowmajor     (ST_double *A, ST_double *b, ST_double *c, GT_size N, GT_size K);
void gf_regress_linalg_dgemv_rowmajor      (ST_double *A, ST_double *b, ST_double *c, GT_size N, GT_size K);
void gf_regress_linalg_error_rowmajor      (ST_double *y, ST_double *A, ST_double *b, ST_double *c, GT_size N, GT_size K);

void gf_regress_linalg_dsymm_wrowmajor     (ST_double *A, ST_double *B, ST_double *C, ST_double *w, GT_size N, GT_size K);
void gf_regress_linalg_dsymm_w2rowmajor    (ST_double *A, ST_double *B, ST_double *C, ST_double *w, GT_size N, GT_size K);
void gf_regress_linalg_dsymm_we2rowmajor   (ST_double *A, ST_double *B, ST_double *C, ST_double *e, ST_double *w, GT_size N, GT_size K);
void gf_regress_linalg_dsymm_fwe2rowmajor  (ST_double *A, ST_double *B, ST_double *C, ST_double *e, ST_double *w, GT_size N, GT_size K);
void gf_regress_linalg_dgemTv_wrowmajor    (ST_double *A, ST_double *b, ST_double *c, ST_double *w, GT_size N, GT_size K);
void gf_regress_linalg_error_wrowmajor     (ST_double *y, ST_double *A, ST_double *b, ST_double *w, ST_double *c, GT_size N, GT_size K);

void gf_regress_linalg_dsymm_ixrowmajor    (ST_double *A, ST_double *B, ST_double *C, GT_size *ix, GT_size N, GT_size K);
void gf_regress_linalg_dgemTv_ixrowmajor   (ST_double *A, ST_double *b, ST_double *c, GT_size *ix, GT_size N, GT_size K);
void gf_regress_linalg_error_ixrowmajor    (ST_double *y, ST_double *A, ST_double *b, GT_size *ix, ST_double *c, GT_size N, GT_size K);

void gf_regress_linalg_dsymm_wixrowmajor   (ST_double *A, ST_double *B, ST_double *C, ST_double *w, GT_size *ix, GT_size N, GT_size K);
void gf_regress_linalg_dsymm_w2ixrowmajor  (ST_double *A, ST_double *B, ST_double *C, ST_double *w, GT_size *ix, GT_size N, GT_size K);
void gf_regress_linalg_dsymm_we2ixrowmajor (ST_double *A, ST_double *B, ST_double *C, ST_double *e, ST_double *w, GT_size *ix, GT_size N, GT_size K);
void gf_regress_linalg_dsymm_fwe2ixrowmajor(ST_double *A, ST_double *B, ST_double *C, ST_double *e, ST_double *w, GT_size *ix, GT_size N, GT_size K);
void gf_regress_linalg_dgemTv_wixrowmajor  (ST_double *A, ST_double *b, ST_double *c, ST_double *w, GT_size *ix, GT_size N, GT_size K);
void gf_regress_linalg_error_wixrowmajor   (ST_double *y, ST_double *A, ST_double *b, ST_double *w, GT_size *ix, ST_double *c, GT_size N, GT_size K);

ST_double gf_regress_linalg_dsysv (ST_double *A, GT_size K);

// ---
// OLS
// ---

void (*gf_regress_ols_se) (ST_double *,  ST_double *,  ST_double *,  ST_double *,   GT_size,   GT_size,    GT_size);
void gf_regress_ols_seunw (ST_double *e, ST_double *w, ST_double *V, ST_double *se, GT_size N, GT_size kx, GT_size kmodel);
void gf_regress_ols_sew   (ST_double *e, ST_double *w, ST_double *V, ST_double *se, GT_size N, GT_size kx, GT_size kmodel);
void gf_regress_ols_sefw  (ST_double *e, ST_double *w, ST_double *V, ST_double *se, GT_size N, GT_size kx, GT_size kmodel);

// Linear coefficients

void gf_regress_ols_colmajor    (ST_double *X, ST_double *y, ST_double *w, ST_double *XX, ST_double *Xy, ST_double *e, ST_double *b, GT_size N, GT_size kx);
void gf_regress_ols_rowmajor    (ST_double *X, ST_double *y, ST_double *w, ST_double *XX, ST_double *Xy, ST_double *e, ST_double *b, GT_size N, GT_size kx);

void gf_regress_ols_wcolmajor   (ST_double *X, ST_double *y, ST_double *w, ST_double *XX, ST_double *Xy, ST_double *e, ST_double *b, GT_size N, GT_size kx);
void gf_regress_ols_wrowmajor   (ST_double *X, ST_double *y, ST_double *w, ST_double *XX, ST_double *Xy, ST_double *e, ST_double *b, GT_size N, GT_size kx);

void gf_regress_ols_ixcolmajor  (ST_double *X, ST_double *y, ST_double *w, GT_size *ix, GT_size nix, ST_double *XX, ST_double *Xy, ST_double *e, ST_double *b, GT_size N, GT_size kx);
void gf_regress_ols_ixrowmajor  (ST_double *X, ST_double *y, ST_double *w, GT_size *ix, GT_size nix, ST_double *XX, ST_double *Xy, ST_double *e, ST_double *b, GT_size N, GT_size kx);

void gf_regress_ols_wixcolmajor (ST_double *X, ST_double *y, ST_double *w, GT_size *ix, GT_size nix, ST_double *XX, ST_double *Xy, ST_double *e, ST_double *b, GT_size N, GT_size kx);
void gf_regress_ols_wixrowmajor (ST_double *X, ST_double *y, ST_double *w, GT_size *ix, GT_size nix, ST_double *XX, ST_double *Xy, ST_double *e, ST_double *b, GT_size N, GT_size kx);

// Robust SE

void gf_regress_ols_robust_colmajor    (ST_double *e, ST_double *w, ST_double *V, ST_double *VV, ST_double *X,  ST_double *XX, ST_double *se, GT_size N, GT_size kx, GT_size kmodel, gf_regress_vceadj vceadj);
void gf_regress_ols_robust_rowmajor    (ST_double *e, ST_double *w, ST_double *V, ST_double *VV, ST_double *X,  ST_double *XX, ST_double *se, GT_size N, GT_size kx, GT_size kmodel, gf_regress_vceadj vceadj);

void gf_regress_ols_robust_wcolmajor   (ST_double *e, ST_double *w, ST_double *V, ST_double *VV, ST_double *X, ST_double *XX, ST_double *se, GT_size N, GT_size kx, GT_size kmodel, gf_regress_vceadj vceadj);
void gf_regress_ols_robust_wrowmajor   (ST_double *e, ST_double *w, ST_double *V, ST_double *VV, ST_double *X, ST_double *XX, ST_double *se, GT_size N, GT_size kx, GT_size kmodel, gf_regress_vceadj vceadj);
void gf_regress_ols_robust_fwcolmajor  (ST_double *e, ST_double *w, ST_double *V, ST_double *VV, ST_double *X, ST_double *XX, ST_double *se, GT_size N, GT_size kx, GT_size kmodel, gf_regress_vceadj vceadj);
void gf_regress_ols_robust_fwrowmajor  (ST_double *e, ST_double *w, ST_double *V, ST_double *VV, ST_double *X, ST_double *XX, ST_double *se, GT_size N, GT_size kx, GT_size kmodel, gf_regress_vceadj vceadj);

void gf_regress_ols_robust_ixcolmajor  (ST_double *e, ST_double *w, GT_size *ix, GT_size nix, ST_double *V, ST_double *VV, ST_double *X,  ST_double *XX, ST_double *se, GT_size N, GT_size kx, GT_size kmodel, gf_regress_vceadj vceadj);
void gf_regress_ols_robust_ixrowmajor  (ST_double *e, ST_double *w, GT_size *ix, GT_size nix, ST_double *V, ST_double *VV, ST_double *X,  ST_double *XX, ST_double *se, GT_size N, GT_size kx, GT_size kmodel, gf_regress_vceadj vceadj);

void gf_regress_ols_robust_wixcolmajor (ST_double *e, ST_double *w, GT_size *ix, GT_size nix, ST_double *V,  ST_double *VV, ST_double *X,  ST_double *XX, ST_double *se, GT_size N, GT_size kx, GT_size kmodel, gf_regress_vceadj vceadj);
void gf_regress_ols_robust_wixrowmajor (ST_double *e, ST_double *w, GT_size *ix, GT_size nix, ST_double *V,  ST_double *VV, ST_double *X,  ST_double *XX, ST_double *se, GT_size N, GT_size kx, GT_size kmodel, gf_regress_vceadj vceadj);
void gf_regress_ols_robust_fwixcolmajor(ST_double *e, ST_double *w, GT_size *ix, GT_size nix, ST_double *V,  ST_double *VV, ST_double *X,  ST_double *XX, ST_double *se, GT_size N, GT_size kx, GT_size kmodel, gf_regress_vceadj vceadj);
void gf_regress_ols_robust_fwixrowmajor(ST_double *e, ST_double *w, GT_size *ix, GT_size nix, ST_double *V,  ST_double *VV, ST_double *X,  ST_double *XX, ST_double *se, GT_size N, GT_size kx, GT_size kmodel, gf_regress_vceadj vceadj);

// Cluster SE

void gf_regress_ols_cluster_colmajor  (ST_double *e, ST_double *w, GT_size *info, GT_size *index, GT_size J, ST_double *U, GT_size *ux, ST_double *V, ST_double *VV, ST_double *X, ST_double *XX, ST_double *se, GT_size N, GT_size kx, GT_size kmodel, gf_regress_vceadj vceadj);
void gf_regress_ols_cluster_rowmajor  (ST_double *e, ST_double *w, GT_size *info, GT_size *index, GT_size J, ST_double *U, GT_size *ux, ST_double *V, ST_double *VV, ST_double *X, ST_double *XX, ST_double *se, GT_size N, GT_size kx, GT_size kmodel, gf_regress_vceadj vceadj);

void gf_regress_ols_cluster_wcolmajor (ST_double *e, ST_double *w, GT_size *info, GT_size *index, GT_size J, ST_double *U, GT_size *ux, ST_double *V, ST_double *VV, ST_double *X, ST_double *XX, ST_double *se, GT_size N, GT_size kx, GT_size kmodel, gf_regress_vceadj vceadj);
void gf_regress_ols_cluster_wrowmajor (ST_double *e, ST_double *w, GT_size *info, GT_size *index, GT_size J, ST_double *U, GT_size *ux, ST_double *V, ST_double *VV, ST_double *X, ST_double *XX, ST_double *se, GT_size N, GT_size kx, GT_size kmodel, gf_regress_vceadj vceadj);

// Posson

void (*gf_regress_poisson_init)(
    ST_double *,
    ST_double *,
    ST_double *,
    ST_double *,
    ST_double *,
    ST_double *,
    GT_size
);

void gf_regress_poisson_init_w(
    ST_double *yptr,
    ST_double *wptr,
    ST_double *mu,
    ST_double *eta,
    ST_double *dev,
    ST_double *lhs,
    GT_size nj
);

void gf_regress_poisson_init_unw(
    ST_double *yptr,
    ST_double *wptr,
    ST_double *mu,
    ST_double *eta,
    ST_double *dev,
    ST_double *lhs,
    GT_size nj
);

ST_double (*gf_regress_poisson_iter)(
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

ST_double gf_regress_poisson_iter_unw(
    ST_double *yptr,
    ST_double *wptr,
    ST_double *e,
    ST_double *mu,
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
    ST_double *eta,
    ST_double *dev,
    ST_double *dev0,
    ST_double *lhs,
    GT_size nj
);

ST_retcode gf_regress_poisson_post(
    GT_bool wcode,
    ST_double *wptr,
    ST_double *e,
    ST_double *mu,
    GT_size nj,
    ST_double diff,
    ST_double poistol,
    GT_size poisiter,
    char *buf1
);

// Pointers

void (*gf_regress_ols) (
    ST_double *,
    ST_double *,
    ST_double *,
    ST_double *,
    ST_double *,
    ST_double *,
    ST_double *,
    GT_size,
    GT_size
);

void (*gf_regress_ols_robust)  (
    ST_double *,
    ST_double *,
    ST_double *,
    ST_double *,
    ST_double *,
    ST_double *,
    ST_double *,
    GT_size,
    GT_size,
    GT_size,
    gf_regress_vceadj
);

void (*gf_regress_ols_cluster) (
    ST_double *,
    ST_double *,
    GT_size *,
    GT_size *,
    GT_size,
    ST_double *,
    GT_size *,
    ST_double *,
    ST_double *,
    ST_double *,
    ST_double *,
    ST_double *,
    GT_size,
    GT_size,
    GT_size,
    gf_regress_vceadj
);

// IV regression

void (*gf_regress_iv) (
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
    GT_size,
    GT_size,
    GT_size,
    GT_size
);

void gf_regress_iv_unw(
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
    GT_size N,
    GT_size kendog,
    GT_size kexog,
    GT_size kz
);

void gf_regress_iv_w(
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

#endif
