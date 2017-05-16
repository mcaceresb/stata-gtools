#define square(x) ((x) * (x))
#define MAX_MATCHES 1
#include "gtools_math.h"

/**
 * @brief Standard deviation entries in range of array
 *
 * @param v vector of doubles containing the current group's variables
 * @param start summaryze starting at the @start-th entry
 * @param end summaryze until the (@end - 1)-th entry
 * @return Standard deviation of the elements of @v from @start to @end
 */
double mf_array_dsd_range (const double v[], const size_t start, const size_t end) {
    double vvar  = 0;
    double vmean = mf_array_dmean_range(v, start, end);
    for (size_t i = start; i < end; i++)
        vvar += square(v[i] - vmean);
    return (sqrt(vvar / (end - start - 1)));
}

/**
 * @brief Mean of enries in range of array
 *
 * @param v vector of doubles containing the current group's variables
 * @param start summaryze starting at the @start-th entry
 * @param end summaryze until the (@end - 1)-th entry
 * @return Mean of the elements of @v from @start to @end
 */
double mf_array_dmean_range (const double v[], const size_t start, const size_t end) {
    return (mf_array_dsum_range(v, start, end) / (end - start));
}

/**
 * @brief Sum of entries in range of array
 *
 * @param v vector of doubles containing the current group's variables
 * @param start summaryze starting at the @start-th entry
 * @param end summaryze until the (@end - 1)-th entry
 * @return Mean of the elements of @v from @start to @end
 */
double mf_array_dsum_range (const double v[], const size_t start, const size_t end)
{
    double vsum = 0;
    for (size_t i = start; i < end; i++)
        vsum += v[i];
    return (vsum);
}

/**
 * @brief Min of enries in range of array
 *
 * @param v vector of doubles containing the current group's variables
 * @param start summaryze starting at the @start-th entry
 * @param end summaryze until the (@end - 1)-th entry
 * @return Min of the elements of @v from @start to @end
 */
double mf_array_dmin_range (const double v[], const size_t start, const size_t end)
{
    double min = v[start];
    for (size_t i = start + 1; i < end; ++i) {
        if (min > v[i]) min = v[i];
    }
    return (min);
}

/**
 * @brief Max of enries in range of array
 *
 * @param v vector of doubles containing the current group's variables
 * @param start summaryze starting at the @start-th entry
 * @param end summaryze until the (@end - 1)-th entry
 * @return Max of the elements of @v from @start to @end
 */
double mf_array_dmax_range (const double v[], const size_t start, const size_t end)
{
    double max = v[start];
    for (size_t i = start + 1; i < end; ++i) {
        if (max < v[i]) max = v[i];
    }
    return (max);
}

/**
 * @brief Quantile of enries in range of array
 *
 * This computes the (100 * quantile)th quantile using qsort. When
 * computing multiple quantiles, the data will already be sorted for the
 * next iteration, so it's faster than sorting every time, but it it
 * still a VERY inefficient implementation.
 *
 * @param v vector of doubles containing the current group's variables
 * @param start summaryze starting at the @start-th entry
 * @param end summaryze until the (@end - 1)-th entry
 * @return Quantile of the elements of @v from @start to @end
 */
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

    // If only 1 or 2 entries, handle manually
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

    // In testing, this was slower than qsort
    // double q = mf_quickselect (v, left, right, qth);
    // if ( (double) qth == (quantile * N) ) {
    //     q += mf_quickselect (v, left, right, qth + 1);
    //     q /= 2;
    // }
    return (q);
}

/**
 * @brief Median of enries in range of array
 *
 * @param v vector of doubles containing the current group's variables
 * @param start summaryze starting at the @start-th entry
 * @param end summaryze until the (@end - 1)-th entry
 * @return Median of the elements of @v from @start to @end
 */
double mf_array_dmedian_range (double v[], const size_t start, const size_t end)
{
    return (mf_array_dquantile_range(v, start, end, 0.5));
}

/**
 * @brief IRQ for enries in range of array
 *
 * @param v vector of doubles containing the current group's variables
 * @param start summaryze starting at the @start-th entry
 * @param end summaryze until the (@end - 1)-th entry
 * @return IRQ for the elements of @v from @start to @end
 */
double mf_array_diqr_range (double v[], const size_t start, const size_t end)
{
    return (mf_array_dquantile_range(v, start, end, 0.75) - mf_array_dquantile_range(v, start, end, 0.25));
}

/**
 * @brief Wrapper to choose summary function using a string
 *
 * @param fname Character with name of funtion to apply to @v
 * @param v vector of doubles containing the current group's variables
 * @param start summaryze starting at the @start-th entry
 * @param end summaryze until the (@end - 1)-th entry
 * @return @fname(@v[@start to @end])
 */
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

/**
 * @brief Parse string into quantile
 *
 * THIS IS NOT GENERAL PURPOSE. It assumes Stata already checked that the
 * only acceptable things to parse are of the form p\d\d?(\.\d+)?.
 *
 * @param matchstr String to match to a quantil
 * @return Numeric part of matchstr
 */
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

/**
 * @brief Compare function for qsort
 *
 * @param a First element
 * @param b Second element
 * @return @a - @b
 */
int mf_qsort_compare (const void * a, const void * b)
{
    return ( (int) *(double*)a - *(double*)b );
}

/**
 * @brief Determine if of enries in range of array are sorted
 *
 * @param v vector of doubles containing the current group's variables
 * @param start summaryze starting at the @start-th entry
 * @param end summaryze until the (@end - 1)-th entry
 * @return Whether the elements of @v are sorted from @start to @end
 */
int mf_array_dsorted_range (const double v[], const size_t start, const size_t end) {
    for (size_t i = start + 1; i < end; i++) {
        if (v[i - 1] > v[i]) return (0);
    }
    return (1);
}
