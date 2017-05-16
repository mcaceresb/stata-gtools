#define square(x) ((x) * (x))
#define MAX_MATCHES 1
#include "gtools_math.h"

double mf_array_dsd_range (const double v[], const size_t start, const size_t end) {
    double vvar  = 0;
    double vmean = mf_array_dmean_range(v, start, end);
    for (size_t i = start; i < end; i++)
        vvar += square(v[i] - vmean);
    return (sqrt(vvar / (end - start - 1)));
}

double mf_array_dmean_range (const double v[], const size_t start, const size_t end) {
    return (mf_array_dsum_range(v, start, end) / (end - start));
}

double mf_array_dsum_range (const double v[], const size_t start, const size_t end)
{
    double vsum = 0;
    for (size_t i = start; i < end; i++)
        vsum += v[i];
    return (vsum);
}

double mf_array_dmin_range (const double v[], const size_t start, const size_t end)
{
    double min = v[start];
    for (size_t i = start + 1; i < end; ++i) {
        if (min > v[i]) min = v[i];
    }
    return (min);
}

double mf_array_dmax_range (const double v[], const size_t start, const size_t end)
{
    double max = v[start];
    for (size_t i = start + 1; i < end; ++i) {
        if (max < v[i]) max = v[i];
    }
    return (max);
}

double mf_array_dquantile_range (double v[], const size_t start, const size_t end, const double quantile)
{
    // Special cases
    // -------------

    int left      = start;
    int right     = end - 1;
    size_t N      = end - left;
    size_t qth    = left + floor(N * quantile);
    double qlower = v[left];
    double qupper = v[right];

    if ( N == 1 ) return (v[start]);
    if ( N == 2 ) {
        if (v[left] > v[right]) {
            qlower = v[right];
            qupper = v[left];
        }
        if ( quantile > 0.5 ) {
            return (qupper);
        }
        else if ( quantile < 0.5 ) {
            return (qlower);
        }
        else {
            return ( (qlower + qupper) / 2 );
        }
    }
    if ( qth == start ) return (mf_array_dmin_range(v, start, end));
    if ( qth == end )   return (mf_array_dmax_range(v, start, end));

    // Full selection algorithm
    // ------------------------

    if ( !mf_array_dsorted_range(v, start, end) ) {
        qsort (v + start, N, sizeof(double), mf_qsort_compare);
    }
    double q = v[qth];
    if ( (double) qth == (quantile * N) ) {
        q += v[qth + 1];
        q /= 2;
    }

    // double q = mf_quickselect (v, left, right, qth);
    // if ( (double) qth == (quantile * N) ) {
    //     q += mf_quickselect (v, left, right, qth + 1);
    //     q /= 2;
    // }
    return (q);
}

double mf_array_dmedian_range (double v[], const size_t start, const size_t end)
{
    return (mf_array_dquantile_range(v, start, end, 0.5));
}

double mf_array_diqr_range (double v[], const size_t start, const size_t end)
{
    return (mf_array_dquantile_range(v, start, end, 0.75) - mf_array_dquantile_range(v, start, end, 0.25));
}

double mf_switch_fun (char * fname, double v[], const size_t start, const size_t end)
{
    if ( strcmp (fname, "sum")    == 0 ) return (mf_array_dsum_range    (v, start, end));
    if ( strcmp (fname, "mean")   == 0 ) return (mf_array_dmean_range   (v, start, end));
    if ( strcmp (fname, "sd")     == 0 ) return (mf_array_dsd_range     (v, start, end));
    if ( strcmp (fname, "max")    == 0 ) return (mf_array_dmax_range    (v, start, end));
    if ( strcmp (fname, "min")    == 0 ) return (mf_array_dmin_range    (v, start, end));
    if ( strcmp (fname, "median") == 0 ) return (mf_array_dmedian_range (v, start, end));
    if ( strcmp (fname, "iqr")    == 0 ) return (mf_array_diqr_range    (v, start, end));
    double q = mf_parse_percentile(fname) / 100;
    return (q > 0? mf_array_dquantile_range(v, start, end, q): 0);
}

double mf_parse_percentile (char *matchstr) {
	int regrc;
	regex_t regexp;
	regmatch_t matches[MAX_MATCHES];

	regrc = regcomp(&regexp, "[0-9][0-9]?(\\.[0-9]+)?", REG_EXTENDED);
	if (regrc != 0) {
        regfree (&regexp);
        return (0);
    }

	if (regexec(&regexp, matchstr, MAX_MATCHES, matches, 0) == 0) {
        char qstr[matches[0].rm_eo + 1];
        memcpy ( qstr, &matchstr[1], matches[0].rm_eo );
        qstr[matches[0].rm_eo] = '\0';
        regfree (&regexp);
        printf("%s\t", qstr);
        return ((double) atof(qstr));
	}
    else {
        regfree (&regexp);
        return (0);
    }
}

int mf_qsort_compare (const void * a, const void * b)
{
    return ( (int) *(double*)a - *(double*)b );
}

int mf_array_dsorted_range (const double v[], const size_t start, const size_t end) {
    for (size_t i = start + 1; i < end; i++) {
        if (v[i - 1] > v[i]) return (0);
    }
    return (1);
}
