#ifndef GSTATS
#define GSTATS

ST_retcode sf_stats             (struct StataInfo *st_info, int level, char *fname);
ST_retcode sf_stats_winsor      (struct StataInfo *st_info, int level);
ST_retcode sf_stats_summarize   (struct StataInfo *st_info, int level, char *fname);
ST_retcode sf_stats_summarize_p (struct StataInfo *st_info, int level, char *fname);
ST_retcode sf_stats_summarize_w (struct StataInfo *st_info, int level, char *fname);
ST_retcode sf_stats_transform   (struct StataInfo *st_info, int level);
ST_retcode sf_stats_hdfe        (struct StataInfo *st_info, int level);

void sf_stats_hdfe_index (
    struct StataInfo *st_info,
    GT_size *index_st);

ST_retcode sf_stats_hdfe_read (
    struct StataInfo *st_info,
    ST_double *X,
    ST_double *w,
    void      *FE,
    GT_size   *nj,
    GT_size   *index_st);

ST_retcode sf_stats_hdfe_write (
    struct StataInfo *st_info,
    ST_double *X,
    GT_size   *nj,
    GT_size   *index_st);

ST_retcode sf_stats_hdfe_absorb(
    struct GtoolsHash *AbsorbHashes,
    GtoolsGroupByTransform GtoolsGroupByTransform,
    GtoolsGroupByHDFE GtoolsGroupByHDFE,
    ST_double *stats,
    GT_size *maps,
    GT_size J,
    GT_size kabs,
    GT_size kx,
    GT_size *nj,
    GT_size *njptr,
    ST_double *xptr,
    ST_double *wptr,
    ST_double hdfetol);

#endif
