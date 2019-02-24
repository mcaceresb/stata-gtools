#ifndef GTOOLS_MATH_W
#define GTOOLS_MATH_W

ST_double gf_switch_fun_code_w (
    ST_double fcode, 
    ST_double *v,
    GT_size N,
    ST_double *w,
    ST_double vsum,
    ST_double wsum,
    GT_size   vcount,
    GT_bool   aw,
    ST_double *p_buffer
);

ST_double gf_array_dmax_weighted (ST_double *v, GT_size N);
ST_double gf_array_drange_weighted (ST_double *v, GT_size N);

ST_double gf_array_dquantile_weighted (
    ST_double *v,
    GT_size   N,
    ST_double *w,
    ST_double quantile,
    ST_double wsum,
    GT_size   vcount,
    ST_double *p_buffer
);

ST_double gf_array_dselect_weighted (
    ST_double *v,
    GT_size   N,
    ST_double *w,
    ST_double sth,
    ST_double wsum,
    GT_size   vcount,
    ST_double *p_buffer
);

ST_double gf_array_diqr_weighted (
    ST_double *v,
    GT_size N,
    ST_double *w,
    ST_double wsum,
    GT_size   vcount,
    ST_double *p_buffer
);

ST_double gf_array_drawsum_weighted (
    ST_double *v,
    GT_size N
);

void gf_array_dsum_dcount_weighted (
    ST_double *v,
    GT_size N,
    ST_double *w,
    ST_double *vsum,
    ST_double *wsum,
    GT_size   *vcount
);

ST_double gf_array_dfirstnm (
    ST_double *v,
    GT_size N
);

ST_double gf_array_dlastnm (
    ST_double *v,
    GT_size N
);

ST_double gf_array_dsum_weighted (
    ST_double *v,
    GT_size N,
    ST_double *w
);

ST_double gf_array_dmean_weighted (
    ST_double *v,
    GT_size N,
    ST_double *w
);

ST_double gf_array_dsd_weighted (
    ST_double *v,
    GT_size N,
    ST_double *w,
    ST_double vsum,
    ST_double wsum,
    GT_size   vcount,
    GT_bool   aw
);

ST_double gf_array_dvar_weighted (
    ST_double *v,
    GT_size N,
    ST_double *w,
    ST_double vsum,
    ST_double wsum,
    GT_size   vcount,
    GT_bool   aw
);

ST_double gf_array_dcv_weighted (
    ST_double *v,
    GT_size N,
    ST_double *w,
    ST_double vsum,
    ST_double wsum,
    GT_size   vcount,
    GT_bool   aw
);

ST_double gf_array_dsemean_weighted (
    ST_double *v,
    GT_size N,
    ST_double *w,
    ST_double vsum,
    ST_double wsum,
    GT_size   vcount,
    GT_bool   aw
);

ST_double gf_array_dsebinom_weighted (
    ST_double *v,
    GT_size N,
    ST_double *w,
    ST_double vsum,
    ST_double wsum,
    GT_size   vcount
);

ST_double gf_array_dsepois_weighted (
    ST_double *v,
    GT_size N,
    ST_double *w,
    ST_double vsum,
    ST_double wsum,
    GT_size   vcount
);

ST_double gf_array_dkurt_weighted (
    ST_double *v,
    GT_size N,
    ST_double *w,
    ST_double vsum,
    ST_double wsum,
    GT_size   vcount
);

ST_double gf_array_dskew_weighted (
    ST_double *v,
    GT_size N,
    ST_double *w,
    ST_double vsum,
    ST_double wsum,
    GT_size   vcount
);

ST_double gf_array_dnmissing_weighted (
    ST_double *v,
    GT_size   N,
    ST_double *w
);

GT_bool gf_array_dsame_weighted (ST_double *v, ST_double *w, GT_size N);

GT_bool gf_array_dsame_unweighted (ST_double *v, GT_size N);

#endif
