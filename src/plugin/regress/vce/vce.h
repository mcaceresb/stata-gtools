#ifndef GREGRESS_VCE
#define GREGRESS_VCE

// Finite sample adjustment
// ------------------------

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

// Homoskedastic
// -------------

void (*gf_regress_ols_se) (ST_double *,  ST_double *,  ST_double *,  ST_double *,   GT_size *,      GT_size,   GT_size,    GT_size);
void gf_regress_ols_seunw (ST_double *e, ST_double *w, ST_double *V, ST_double *se, GT_size *colix, GT_size N, GT_size kx, GT_size kmodel);
void gf_regress_ols_sew   (ST_double *e, ST_double *w, ST_double *V, ST_double *se, GT_size *colix, GT_size N, GT_size kx, GT_size kmodel);
void gf_regress_ols_sefw  (ST_double *e, ST_double *w, ST_double *V, ST_double *se, GT_size *colix, GT_size N, GT_size kx, GT_size kmodel);

// Robust SE
// ---------

void (*gf_regress_ols_robust)  (
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
    gf_regress_vceadj
);

void gf_regress_ols_robust_colmajor    (ST_double *e, ST_double *w, ST_double *V, ST_double *VV, ST_double *X, ST_double *XX, ST_double *se, GT_size *colix, GT_size N, GT_size kx, GT_size kmodel, gf_regress_vceadj vceadj);
void gf_regress_ols_robust_wcolmajor   (ST_double *e, ST_double *w, ST_double *V, ST_double *VV, ST_double *X, ST_double *XX, ST_double *se, GT_size *colix, GT_size N, GT_size kx, GT_size kmodel, gf_regress_vceadj vceadj);
void gf_regress_ols_robust_fwcolmajor  (ST_double *e, ST_double *w, ST_double *V, ST_double *VV, ST_double *X, ST_double *XX, ST_double *se, GT_size *colix, GT_size N, GT_size kx, GT_size kmodel, gf_regress_vceadj vceadj);

// Cluster SE
// ----------

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
    GT_size *,
    GT_size,
    GT_size,
    GT_size,
    gf_regress_vceadj
);

void gf_regress_ols_cluster_colmajor  (ST_double *e, ST_double *w, GT_size *info, GT_size *index, GT_size J, ST_double *U, GT_size *ux, ST_double *V, ST_double *VV, ST_double *X, ST_double *XX, ST_double *se, GT_size *colix, GT_size N, GT_size kx, GT_size kmodel, gf_regress_vceadj vceadj);
void gf_regress_ols_cluster_wcolmajor (ST_double *e, ST_double *w, GT_size *info, GT_size *index, GT_size J, ST_double *U, GT_size *ux, ST_double *V, ST_double *VV, ST_double *X, ST_double *XX, ST_double *se, GT_size *colix, GT_size N, GT_size kx, GT_size kmodel, gf_regress_vceadj vceadj);

#endif
