#ifndef GTOOLS_MATH
#define GTOOLS_MATH

ST_double gf_switch_fun (char *fname, ST_double v[], const GT_size start, const GT_size end);
ST_double gf_switch_fun_code (ST_double fcode, ST_double v[], const GT_size start, const GT_size end);
ST_double gf_code_fun (char * fname);

ST_double gf_array_dquantile_range (
    ST_double v[],
    const GT_size start,
    const GT_size end,
    const ST_double quantile
);

ST_double gf_array_dsum_range      (const ST_double v[], const GT_size start, const GT_size end);
ST_double gf_array_dmean_range     (const ST_double v[], const GT_size start, const GT_size end);
ST_double gf_array_dgeomean_range  (const ST_double v[], const GT_size start, const GT_size end);
ST_double gf_array_dsd_range       (const ST_double v[], const GT_size start, const GT_size end);
ST_double gf_array_dvar_range      (const ST_double v[], const GT_size start, const GT_size end);
ST_double gf_array_dcv_range       (const ST_double v[], const GT_size start, const GT_size end);
ST_double gf_array_dmax_range      (const ST_double v[], const GT_size start, const GT_size end);
ST_double gf_array_dmin_range      (const ST_double v[], const GT_size start, const GT_size end);
ST_double gf_array_drange_range    (const ST_double v[], const GT_size start, const GT_size end);

ST_double gf_array_dsemean_range   (const ST_double v[], const GT_size start, const GT_size end);
ST_double gf_array_dsebinom_range  (const ST_double v[], const GT_size start, const GT_size end);
ST_double gf_array_dsepois_range   (const ST_double v[], const GT_size start, const GT_size end);

ST_double gf_array_dskew_range     (const ST_double v[], const GT_size start, const GT_size end);
ST_double gf_array_dkurt_range     (const ST_double v[], const GT_size start, const GT_size end);

ST_double gf_array_dmedian_range   (ST_double v[], const GT_size start, const GT_size end);
ST_double gf_array_diqr_range      (ST_double v[], const GT_size start, const GT_size end);

int gf_qsort_compare (const void * a, const void * b);
GT_bool gf_array_dsorted_range (const ST_double v[], const GT_size start, const GT_size end);
GT_bool gf_array_dsame (const ST_double *v, const GT_size N);

#endif

// -23         // variance
// -24         // cv
// -25         // range
// 1000 + #    // #th smallest
// -1000 - #   // #th largest
// 1000.5 + #  // raw #th smallest
// -1000.5 - # // raw #th largest
