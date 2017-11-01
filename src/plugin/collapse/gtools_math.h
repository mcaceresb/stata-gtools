#ifndef GTOOLS_MATH
#define GTOOLS_MATH

ST_double gf_array_dquantile_range (ST_double v[], const GT_size start, const GT_size end, const ST_double quantile);
ST_double gf_switch_fun (char *fname, ST_double v[], const GT_size start, const GT_size end);
ST_double gf_switch_fun_code (ST_double fcode, ST_double v[], const GT_size start, const GT_size end);
ST_double gf_code_fun (char * fname);

ST_double gf_array_dsum_range      (const ST_double v[], const GT_size start, const GT_size end);
ST_double gf_array_dmean_range     (const ST_double v[], const GT_size start, const GT_size end);
ST_double gf_array_dsd_range       (const ST_double v[], const GT_size start, const GT_size end);
ST_double gf_array_dmax_range      (const ST_double v[], const GT_size start, const GT_size end);
ST_double gf_array_dmin_range      (const ST_double v[], const GT_size start, const GT_size end);

ST_double gf_array_dmedian_range   (ST_double v[], const GT_size start, const GT_size end);
ST_double gf_array_diqr_range      (ST_double v[], const GT_size start, const GT_size end);

int gf_qsort_compare (const void * a, const void * b);
ST_boolean gf_array_dsorted_range (const ST_double v[], const GT_size start, const GT_size end);

#endif
