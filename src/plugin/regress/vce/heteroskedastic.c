void gf_regress_ols_robust_colmajor(
    ST_double *e,
    ST_double *w,
    ST_double *V,
    ST_double *VV,
    ST_double *X,
    ST_double *XX,
    ST_double *se,
    GT_size *colix,
    GT_size N,
    GT_size kx,
    GT_size kmodel,
    gf_regress_vceadj vceadj)
{
    GT_size i;
    ST_double qc;

    gf_regress_linalg_dsymm_w2colmajor(X,  X,  V, e, N, kx);
    gf_regress_linalg_dgemm_colmajor  (V,  XX, VV, kx, kx, kx);
    gf_regress_linalg_dgemm_colmajor  (XX, VV, V,  kx, kx, kx);

    qc = vceadj(N, kmodel, 0, w);
    for (i = 0; i < kx; i++) {
        se[i] = sqrt(V[i * kx + i] * qc);
    }
}

void gf_regress_ols_robust_wcolmajor(
    ST_double *e,
    ST_double *w,
    ST_double *V,
    ST_double *VV,
    ST_double *X,
    ST_double *XX,
    ST_double *se,
    GT_size *colix,
    GT_size N,
    GT_size kx,
    GT_size kmodel,
    gf_regress_vceadj vceadj)
{
    GT_size i;
    ST_double qc = vceadj(N, kmodel, 0, w);

    gf_regress_linalg_dsymm_we2colmajor (X,  X,  V, e, w, N, kx);
    gf_regress_linalg_dgemm_colmajor    (V,  XX, VV, kx, kx, kx);
    gf_regress_linalg_dgemm_colmajor    (XX, VV, V,  kx, kx, kx);

    for (i = 0; i < kx; i++) {
        se[i] = sqrt(V[i * kx + i] * qc);
    }
}

void gf_regress_ols_robust_fwcolmajor(
    ST_double *e,
    ST_double *w,
    ST_double *V,
    ST_double *VV,
    ST_double *X,
    ST_double *XX,
    ST_double *se,
    GT_size *colix,
    GT_size N,
    GT_size kx,
    GT_size kmodel,
    gf_regress_vceadj vceadj)
{
    GT_size i;
    ST_double qc = vceadj(N, kmodel, 0, w);

    gf_regress_linalg_dsymm_fwe2colmajor(X,  X,  V, e, w, N, kx);
    gf_regress_linalg_dgemm_colmajor    (V,  XX, VV, kx, kx, kx);
    gf_regress_linalg_dgemm_colmajor    (XX, VV, V,  kx, kx, kx);

    for (i = 0; i < kx; i++) {
        se[i] = sqrt(V[i * kx + i] * qc);
    }
}

