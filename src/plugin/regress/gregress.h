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
    GT_size   *nj
);

ST_retcode sf_regress_read_rowmajor (
    struct StataInfo *st_info,
    ST_double *y,
    ST_double *X,
    ST_double *w,
    void      *G,
    void      *FE,
    GT_size   *nj
);

// ------------------------
// Linear Algebra Functions
// ------------------------

// Naming convention _tries_ to follow BLAS notation
//
// https://www.gnu.org/software/gsl/doc/html/blas.html

// Column-major order!

void gf_regress_linalg_dgemm_colmajor     (ST_double *A, ST_double *B, ST_double *C, GT_size k1, GT_size k2, GT_size k3);
void gf_regress_linalg_dsymm_colmajor     (ST_double *A, ST_double *B, ST_double *C, GT_size N, GT_size K);
void gf_regress_linalg_dgemTv_colmajor    (ST_double *A, ST_double *b, ST_double *c, GT_size N, GT_size K);
void gf_regress_linalg_dgemv_colmajor     (ST_double *A, ST_double *b, ST_double *c, GT_size N, GT_size K);
void gf_regress_linalg_error_colmajor     (ST_double *y, ST_double *A, ST_double *b, ST_double *c, GT_size N, GT_size K);

void gf_regress_linalg_dsymm_wcolmajor    (ST_double *A, ST_double *B, ST_double *C, ST_double *w, GT_size N, GT_size K);
void gf_regress_linalg_dsymm_w2colmajor   (ST_double *A, ST_double *B, ST_double *C, ST_double *w, GT_size N, GT_size K);
void gf_regress_linalg_dgemTv_wcolmajor   (ST_double *A, ST_double *b, ST_double *c, ST_double *w, GT_size N, GT_size K);
void gf_regress_linalg_error_wcolmajor    (ST_double *y, ST_double *A, ST_double *b, ST_double *w, ST_double *c, GT_size N, GT_size K);

void gf_regress_linalg_dsymm_ixcolmajor   (ST_double *A, ST_double *B, ST_double *C, GT_size *ix, GT_size nix, GT_size N, GT_size K);
void gf_regress_linalg_dgemTv_ixcolmajor  (ST_double *A, ST_double *b, ST_double *c, GT_size *ix, GT_size nix, GT_size N, GT_size K);
void gf_regress_linalg_error_ixcolmajor   (ST_double *y, ST_double *A, ST_double *b, GT_size *ix, GT_size nix, ST_double *c, GT_size N, GT_size K);

void gf_regress_linalg_dsymm_wixcolmajor  (ST_double *A, ST_double *B, ST_double *C, ST_double *w, GT_size *ix, GT_size nix, GT_size N, GT_size K);
void gf_regress_linalg_dsymm_w2ixcolmajor (ST_double *A, ST_double *B, ST_double *C, ST_double *w, GT_size *ix, GT_size nix, GT_size N, GT_size K);
void gf_regress_linalg_dgemTv_wixcolmajor (ST_double *A, ST_double *b, ST_double *c, ST_double *w, GT_size *ix, GT_size nix, GT_size N, GT_size K);
void gf_regress_linalg_error_wixcolmajor  (ST_double *y, ST_double *A, ST_double *b, ST_double *w, GT_size *ix, GT_size nix, ST_double *c, GT_size N, GT_size K);

// Row-major order!

void gf_regress_linalg_dgemm_rowmajor     (ST_double *A, ST_double *B, ST_double *C, GT_size k1, GT_size k2, GT_size k3);
void gf_regress_linalg_dsymm_rowmajor     (ST_double *A, ST_double *B, ST_double *C, GT_size N, GT_size K);
void gf_regress_linalg_dgemTv_rowmajor    (ST_double *A, ST_double *b, ST_double *c, GT_size N, GT_size K);
void gf_regress_linalg_dgemv_rowmajor     (ST_double *A, ST_double *b, ST_double *c, GT_size N, GT_size K);
void gf_regress_linalg_error_rowmajor     (ST_double *y, ST_double *A, ST_double *b, ST_double *c, GT_size N, GT_size K);

void gf_regress_linalg_dsymm_wrowmajor    (ST_double *A, ST_double *B, ST_double *C, ST_double *w, GT_size N, GT_size K);
void gf_regress_linalg_dsymm_w2rowmajor   (ST_double *A, ST_double *B, ST_double *C, ST_double *w, GT_size N, GT_size K);
void gf_regress_linalg_dgemTv_wrowmajor   (ST_double *A, ST_double *b, ST_double *c, ST_double *w, GT_size N, GT_size K);
void gf_regress_linalg_error_wrowmajor    (ST_double *y, ST_double *A, ST_double *b, ST_double *w, ST_double *c, GT_size N, GT_size K);

void gf_regress_linalg_dsymm_ixrowmajor   (ST_double *A, ST_double *B, ST_double *C, GT_size *ix, GT_size N, GT_size K);
void gf_regress_linalg_dgemTv_ixrowmajor  (ST_double *A, ST_double *b, ST_double *c, GT_size *ix, GT_size N, GT_size K);
void gf_regress_linalg_error_ixrowmajor   (ST_double *y, ST_double *A, ST_double *b, GT_size *ix, ST_double *c, GT_size N, GT_size K);

void gf_regress_linalg_dsymm_wixrowmajor  (ST_double *A, ST_double *B, ST_double *C, ST_double *w, GT_size *ix, GT_size N, GT_size K);
void gf_regress_linalg_dsymm_w2ixrowmajor (ST_double *A, ST_double *B, ST_double *C, ST_double *w, GT_size *ix, GT_size N, GT_size K);
void gf_regress_linalg_dgemTv_wixrowmajor (ST_double *A, ST_double *b, ST_double *c, ST_double *w, GT_size *ix, GT_size N, GT_size K);
void gf_regress_linalg_error_wixrowmajor  (ST_double *y, ST_double *A, ST_double *b, ST_double *w, GT_size *ix, ST_double *c, GT_size N, GT_size K);

ST_double gf_regress_linalg_dsysv (ST_double *A, GT_size K);

// ---
// OLS
// ---

void gf_regress_ols_se (ST_double *e, ST_double *V, ST_double *se, GT_size N, GT_size kx, GT_size kmodel);

// Linear coefficients

void gf_regress_ols_colmajor    (ST_double *X, ST_double *y, ST_double *XX, ST_double *Xy, ST_double *e,  ST_double *b, GT_size N, GT_size kx);
void gf_regress_ols_rowmajor    (ST_double *X, ST_double *y, ST_double *XX, ST_double *Xy, ST_double *e,  ST_double *b, GT_size N, GT_size kx);

void gf_regress_ols_wcolmajor   (ST_double *X, ST_double *y, ST_double *w,  ST_double *XX, ST_double *Xy, ST_double *e, ST_double *b, GT_size N, GT_size kx);
void gf_regress_ols_wrowmajor   (ST_double *X, ST_double *y, ST_double *w,  ST_double *XX, ST_double *Xy, ST_double *e, ST_double *b, GT_size N, GT_size kx);

void gf_regress_ols_ixcolmajor  (ST_double *X, ST_double *y, GT_size *ix, GT_size nix, ST_double *XX, ST_double *Xy, ST_double *e, ST_double *b, GT_size N, GT_size kx);
void gf_regress_ols_ixrowmajor  (ST_double *X, ST_double *y, GT_size *ix,              ST_double *XX, ST_double *Xy, ST_double *e, ST_double *b, GT_size N, GT_size kx);

void gf_regress_ols_wixcolmajor (ST_double *X, ST_double *y, ST_double *w, GT_size *ix, GT_size nix, ST_double *XX, ST_double *Xy, ST_double *e, ST_double *b, GT_size N, GT_size kx);
void gf_regress_ols_wixrowmajor (ST_double *X, ST_double *y, ST_double *w, GT_size *ix,              ST_double *XX, ST_double *Xy, ST_double *e, ST_double *b, GT_size N, GT_size kx);

// Robust SE

void gf_regress_ols_robust_colmajor    (ST_double *e, ST_double *V, ST_double *VV, ST_double *X,  ST_double *XX, ST_double *se, GT_size N, GT_size kx, GT_size kmodel);
void gf_regress_ols_robust_rowmajor    (ST_double *e, ST_double *V, ST_double *VV, ST_double *X,  ST_double *XX, ST_double *se, GT_size N, GT_size kx, GT_size kmodel);

void gf_regress_ols_robust_wcolmajor   (ST_double *e, ST_double *w, ST_double *V,  ST_double *VV, ST_double *X,  ST_double *XX, ST_double *se, GT_size N, GT_size kx, GT_size kmodel);
void gf_regress_ols_robust_wrowmajor   (ST_double *e, ST_double *w, ST_double *V,  ST_double *VV, ST_double *X,  ST_double *XX, ST_double *se, GT_size N, GT_size kx, GT_size kmodel);

void gf_regress_ols_robust_ixcolmajor  (ST_double *e, GT_size *ix, GT_size nix, ST_double *V, ST_double *VV, ST_double *X,  ST_double *XX, ST_double *se, GT_size N, GT_size kx, GT_size kmodel);
void gf_regress_ols_robust_ixrowmajor  (ST_double *e, GT_size *ix,              ST_double *V, ST_double *VV, ST_double *X,  ST_double *XX, ST_double *se, GT_size N, GT_size kx, GT_size kmodel);

void gf_regress_ols_robust_wixcolmajor (ST_double *e, ST_double *w, GT_size *ix, GT_size nix, ST_double *V,  ST_double *VV, ST_double *X,  ST_double *XX, ST_double *se, GT_size N, GT_size kx, GT_size kmodel);
void gf_regress_ols_robust_wixrowmajor (ST_double *e, ST_double *w, GT_size *ix,              ST_double *V,  ST_double *VV, ST_double *X,  ST_double *XX, ST_double *se, GT_size N, GT_size kx, GT_size kmodel);

// Cluster SE

void gf_regress_ols_cluster_colmajor (ST_double *e, GT_size *info, GT_size *index, GT_size J, ST_double *U, GT_size *ux, ST_double *V, ST_double *VV, ST_double *X, ST_double *XX, ST_double *se, GT_size N, GT_size kx, GT_size kmodel);
void gf_regress_ols_cluster_rowmajor (ST_double *e, GT_size *info, GT_size *index, GT_size J, ST_double *U,              ST_double *V, ST_double *VV, ST_double *X, ST_double *XX, ST_double *se, GT_size N, GT_size kx, GT_size kmodel);

void gf_regress_ols_cluster_wcolmajor (ST_double *e, ST_double *w, GT_size *info, GT_size *index, GT_size J, ST_double *U, GT_size *ux, ST_double *V, ST_double *VV, ST_double *X, ST_double *XX, ST_double *se, GT_size N, GT_size kx, GT_size kmodel);
void gf_regress_ols_cluster_wrowmajor (ST_double *e, ST_double *w, GT_size *info, GT_size *index, GT_size J, ST_double *U,              ST_double *V, ST_double *VV, ST_double *X, ST_double *XX, ST_double *se, GT_size N, GT_size kx, GT_size kmodel);

#endif
