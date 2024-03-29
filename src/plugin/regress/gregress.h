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
    GtoolsAlgorithmHDFE GtoolsAlgorithmHDFE,
    ST_double *stats,
    GT_size *maps,
    GT_size nj,
    GT_size kabs,
    GT_size kx,
    GT_size *kmodel,
    ST_double **njabsptr,
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
    GtoolsAlgorithmHDFE GtoolsAlgorithmHDFE,
    ST_double *stats,
    GT_size *maps,
    GT_size J,
    GT_size *nj,
    GT_size kabs,
    GT_size kx,
    ST_double **njabsptr,
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

void gf_regress_warnings (
    GT_size J,
    GT_size warncollinear,
    GT_size warnsingular,
    GT_size warnivnotiden,
    GT_size warnnocols,
    GT_size warnalpha,
    char *buf1,
    char *buf2,
    char *buf3,
    char *buf4,
    char *buf5
);


void gf_regress_adjust_collinear_b (
    ST_double *b,
    ST_double *buffer,
    GT_size *colix,
    GT_size k1,
    GT_size k2
);

void gf_regress_adjust_collinear_se (
    ST_double *se,
    ST_double *buffer,
    GT_size *colix,
    GT_size k1,
    GT_size k2
);

void gf_regress_adjust_collinear_V (
    ST_double *V,
    ST_double *buffer,
    GT_size *colix,
    GT_size k1,
    GT_size k2
);

#endif
