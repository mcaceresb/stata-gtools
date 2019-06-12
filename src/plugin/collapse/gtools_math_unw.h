#ifndef GTOOLS_MATH_UNW
#define GTOOLS_MATH_UNW

ST_double gf_switch_fun_code_unw (
    ST_double fcode, 
    ST_double *v,
    GT_size N,
    GT_size vcount,
    ST_double *p_buffer
);

ST_double gf_array_dquantile_unweighted (
    ST_double *v,
    GT_size   N,
    ST_double quantile,
    ST_double *p_buffer
);

ST_double gf_array_dselect_unweighted (
    ST_double *v,
    GT_size   N,
    GT_int    sth,
    GT_size   end,
    ST_double *p_buffer
);

ST_double gf_array_diqr_unweighted (
    ST_double *v,
    GT_size N,
    ST_double *p_buffer
);

ST_double gf_array_dmean_unweighted (
    ST_double *v,
    GT_size N
);

ST_double gf_array_dgeomean_unweighted (
    ST_double *v,
    GT_size N
);

ST_double gf_array_dsd_unweighted (
    ST_double *v,
    GT_size N
);

ST_double gf_array_dvar_unweighted (
    ST_double *v,
    GT_size N
);

ST_double gf_array_dcv_unweighted (
    ST_double *v,
    GT_size N
);

ST_double gf_array_dsemean_unweighted (
    ST_double *v,
    GT_size N
);

ST_double gf_array_dsebinom_unweighted (
    ST_double *v,
    GT_size N
);

ST_double gf_array_dsepois_unweighted (
    ST_double *v,
    GT_size N
);

ST_double gf_array_dkurt_unweighted (
    ST_double *v,
    GT_size N
);

ST_double gf_array_dskew_unweighted (
    ST_double *v,
    GT_size N
);

#endif
