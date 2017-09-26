#ifndef GTOOLS_MATH
#define GTOOLS_MATH

double mf_array_dquantile_range (double v[], const size_t start, const size_t end, const double quantile);
double mf_switch_fun (char *fname, double v[], const size_t start, const size_t end);
double mf_switch_fun_code (double fcode, double v[], const size_t start, const size_t end);
double mf_code_fun (char * fname);

double mf_array_dsum_range      (const double v[], const size_t start, const size_t end);
double mf_array_dmean_range     (const double v[], const size_t start, const size_t end);
double mf_array_dsd_range       (const double v[], const size_t start, const size_t end);
double mf_array_dmax_range      (const double v[], const size_t start, const size_t end);
double mf_array_dmin_range      (const double v[], const size_t start, const size_t end);

double mf_array_dmedian_range   (double v[], const size_t start, const size_t end);
double mf_array_diqr_range      (double v[], const size_t start, const size_t end);

int mf_qsort_compare (const void * a, const void * b);
int mf_array_dsorted_range (const double v[], const size_t start, const size_t end);

#endif
