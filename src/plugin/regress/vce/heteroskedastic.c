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
    ST_double qc = vceadj(N, kmodel, 0, w);
    GT_size kindep = colix[kx];

    // Compute D = X' diag(e) X
    if ( kindep < kx ) {
        gf_regress_linalg_dsymm_w2colmajor_ix (X, X, V, e, colix, N, kindep);
    }
    else {
        gf_regress_linalg_dsymm_w2colmajor (X, X, V, e, N, kx);
    }

    // Compute V = (X' X)^-1 D (X' X)^-1
    gf_regress_linalg_dgemm_colmajor (XX, V,  VV, kindep, kindep, kindep);
    gf_regress_linalg_dgemm_colmajor (VV, XX, V,  kindep, kindep, kindep);

    // Extract standard errors from diag(V)
    for (i = 0; i < kindep; i++) {
        se[i] = sqrt(V[i * kindep + i] * qc);
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
    GT_size kindep = colix[kx];

    if ( kindep < kx ) {
        gf_regress_linalg_dsymm_we2colmajor_ix (X, X, V, e, w, colix, N, kindep);
    }
    else {
        gf_regress_linalg_dsymm_we2colmajor (X, X, V, e, w, N, kx);
    }

    gf_regress_linalg_dgemm_colmajor (XX, V,  VV, kindep, kindep, kindep);
    gf_regress_linalg_dgemm_colmajor (VV, XX, V,  kindep, kindep, kindep);

    for (i = 0; i < kindep; i++) {
        se[i] = sqrt(V[i * kindep + i] * qc);
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
    GT_size kindep = colix[kx];

    if ( kindep < kx ) {
        gf_regress_linalg_dsymm_fwe2colmajor_ix (X, X, V, e, w, colix, N, kindep);
    }
    else {
        gf_regress_linalg_dsymm_fwe2colmajor (X, X, V, e, w, N, kx);
    }

    gf_regress_linalg_dgemm_colmajor (XX, V,  VV, kindep, kindep, kindep);
    gf_regress_linalg_dgemm_colmajor (VV, XX, V,  kindep, kindep, kindep);

    for (i = 0; i < kindep; i++) {
        se[i] = sqrt(V[i * kindep + i] * qc);
    }
}
