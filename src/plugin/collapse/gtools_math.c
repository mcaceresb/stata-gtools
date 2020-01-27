#define SQUARE(x) ( (x) * (x) )
#define MAX(a, b) ( (a) > (b) ? (a) : (b) )
#define MIN(a, b) ( (a) > (b) ? (b) : (a) )

#define MAX_MATCHES 1

#include "gtools_math.h"
#include "qselect.c"

/**
 * @brief Standard deviation entries in range of array
 *
 * @param v vector of doubles containing the current group's variables
 * @param start summaryze starting at the @start-th entry
 * @param end summaryze until the (@end - 1)-th entry
 * @return Standard deviation of the elements of @v from @start to @end
 */
ST_double gf_array_dsd_range (const ST_double v[], const GT_size start, const GT_size end) {
    if ( gf_array_dsame(v + start, end - start) ) {
        return (0);
    }

    GT_size i;
    ST_double vvar  = 0;
    ST_double vmean = gf_array_dmean_range(v, start, end);
    for (i = start; i < end; i++)
        vvar += SQUARE(v[i] - vmean);

    return (sqrt(vvar / (end - start - 1)));
}

/**
 * @brief Variance of entries in range of array
 *
 * @param v vector of doubles containing the current group's variables
 * @param start summaryze starting at the @start-th entry
 * @param end summaryze until the (@end - 1)-th entry
 * @return Variance of the elements of @v from @start to @end
 */
ST_double gf_array_dvar_range (const ST_double v[], const GT_size start, const GT_size end) {
    if ( gf_array_dsame(v + start, end - start) ) {
        return (0);
    }

    GT_size i;
    ST_double vvar  = 0;
    ST_double vmean = gf_array_dmean_range(v, start, end);
    for (i = start; i < end; i++)
        vvar += SQUARE(v[i] - vmean);

    return (vvar / (end - start - 1));
}

/**
 * @brief Coefficient of variation of the entries in range of array
 *
 * @param v vector of doubles containing the current group's variables
 * @param start summaryze starting at the @start-th entry
 * @param end summaryze until the (@end - 1)-th entry
 * @return Coefficient of variation of the elements of @v from @start to @end
 */
ST_double gf_array_dcv_range (const ST_double v[], const GT_size start, const GT_size end) {
    if ( gf_array_dsame(v + start, end - start) ) {
        return (0);
    }

    GT_size i;
    ST_double vvar  = 0;
    ST_double vmean = gf_array_dmean_range(v, start, end);
    if ( vmean == 0 ) return(SV_missval);

    for (i = start; i < end; i++)
        vvar += SQUARE(v[i] - vmean);

    return (sqrt(vvar / (end - start - 1)) / vmean);
}

/**
 * @brief Mean of enries in range of array
 *
 * @param v vector of doubles containing the current group's variables
 * @param start summaryze starting at the @start-th entry
 * @param end summaryze until the (@end - 1)-th entry
 * @return Mean of the elements of @v from @start to @end
 */
ST_double gf_array_dmean_range (const ST_double v[], const GT_size start, const GT_size end) {
    return (gf_array_dsum_range(v, start, end) / (end - start));
}

/**
 * @brief Geometric mean of enries in range of array
 *
 * @param v vector of doubles containing the current group's variables
 * @param start summaryze starting at the @start-th entry
 * @param end summaryze until the (@end - 1)-th entry
 * @return Geometric mean of the elements of @v from @start to @end
 */
ST_double gf_array_dgeomean_range (const ST_double v[], const GT_size start, const GT_size end) {
    GT_size i;
    ST_double vsum = 0;
    for (i = start; i < end; i++)
        vsum += log(v[i]);

    return (exp(vsum / (end - start)));
}

/**
 * @brief Sum of entries in range of array
 *
 * @param v vector of doubles containing the current group's variables
 * @param start summaryze starting at the @start-th entry
 * @param end summaryze until the (@end - 1)-th entry
 * @return Mean of the elements of @v from @start to @end
 */
ST_double gf_array_dsum_range (const ST_double v[], const GT_size start, const GT_size end)
{
    GT_size i;
    ST_double vsum = 0;
    for (i = start; i < end; i++)
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
ST_double gf_array_dmin_range (const ST_double v[], const GT_size start, const GT_size end)
{
    GT_size i;
    ST_double min = v[start];
    for (i = start + 1; i < end; ++i) {
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
ST_double gf_array_dmax_range (const ST_double v[], const GT_size start, const GT_size end)
{
    GT_size i;
    ST_double max = v[start];
    for (i = start + 1; i < end; ++i) {
        if (max < v[i]) max = v[i];
    }
    return (max);
}

/**
 * @brief Range of enries in range of array
 *
 * @param v vector of doubles containing the current group's variables
 * @param start summaryze starting at the @start-th entry
 * @param end summaryze until the (@end - 1)-th entry
 * @return Range of the elements of @v from @start to @end
 */
ST_double gf_array_drange_range (const ST_double v[], const GT_size start, const GT_size end)
{
    GT_size i;
    ST_double min = v[start];
    ST_double max = v[start];
    for (i = start + 1; i < end; ++i) {
        if (min > v[i]) min = v[i];
        if (max < v[i]) max = v[i];
    }
    return (max - min);
}

/**
 * @brief Quantile of enries in range of array
 *
 * This computes the (quantile)th quantile using qsort. When
 * computing multiple quantiles, the data will already be sorted for the
 * next iteration, so it's faster than sorting every time, but it it
 * still a VERY inefficient implementation.
 *
 * @param v vector of doubles containing the current group's variables
 * @param start summaryze starting at the @start-th entry
 * @param end summaryze until the (@end - 1)-th entry
 * @return Quantile of the elements of @v from @start to @end
 */
ST_double gf_array_dquantile_range (
    ST_double v[],
    const GT_size start,
    const GT_size end,
    const ST_double quantile)
{
    ST_double q, qdbl, qfoo, Ndbl;
    GT_size   Ndiv, qth;
    GT_bool   rfoo, Nmod;
    GT_size   N  = (end - start);

    // Special cases
    // -------------

    if ( N == 1 ) {
        // If only 1 entry, can't take quantile
        return (v[start]);
    }
    else if ( N == 2 ) {
        // If 2 entries, only 3 options
        if ( quantile > 50 ) {
            return (MAX(v[start], v[end - 1]));
        }
        else if ( quantile < 50 ) {
            return (MIN(v[start], v[end - 1]));
        }
        else {
            return ( (v[start] + v[end - 1]) / 2 );
        }
    }

    // Get position of quantile
    // ------------------------

    Nmod = N % 100;
    Ndbl = (ST_double) N;

    if ( Nmod ) { // Numerical precision foo
        qth  = floor(qdbl = quantile * Ndbl / 100);
        qfoo = round(qdbl);
        rfoo = ((qfoo * 100 / Ndbl) == quantile);
    }
    else {
        Ndiv = N / 100;
        qth  = floor(qdbl = quantile * Ndiv);
        qfoo = round(qdbl);
        rfoo = ((qfoo / Ndiv) == quantile);
    }

    // 0th quantile is not a thing, so we can just take the min
    if ( qth == 0 ) {
        return (gf_array_dmin_range(v, start, end));
    }

    // Full selection algorithm
    // ------------------------

    GT_size left = start, right = end;

    // I was doing the OR because I was concerned about a case where,
    // because of numerical precision, the correct quantile was the
    // largest value but qfoo or qth returned N - 2. However, I think
    // it's better to do cases.
    //
    // If rfoo, then the correct quantile is qfoo since the quantile is
    // exact. In this case, requesting exactly N - 1 should give the
    // average between N - 1 and N - 2. E.g. 80th out of an array of
    // length 5.
    //
    // If not rfoo, then qth, the floor, should give the correct
    // position of the quantile, and we would only care about the max
    // if it is N - 1 (and qfoo could, in fact, be incorrectly rounding
    // up). E.g. 70th for an array of length 5 asks for 3.5, which
    // clearly is position N - 2; however, rounding gives N - 1.

    // GT_bool dmax = (qth == (N - 1)) | (qfoo == (N - 1));

    if ( rfoo ) {
        // if ( dmax ) {
        if ( qfoo == (N - 1) ) {
            q = (
                gf_array_dmax_range(v, left, right) +
                gf_qselect_range (v, left, right, qfoo - 1)
            ) / 2;
        }
        else {
            q = (
                gf_qselect_range (v, left, right, qfoo) +
                gf_qselect_range (v, left, right, qfoo - 1)
            ) / 2;
        }
    }
    else {
        // if ( dmax ) {
        if ( qth == (N - 1) ) {
            q = gf_array_dmax_range(v, left, right);
        }
        else{
            q = gf_qselect_range (v, left, right, qth);
        }
    }

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
ST_double gf_array_dmedian_range (ST_double v[], const GT_size start, const GT_size end)
{
    return (gf_array_dquantile_range(v, start, end, 50));
}

/**
 * @brief IRQ for enries in range of array
 *
 * @param v vector of doubles containing the current group's variables
 * @param start summaryze starting at the @start-th entry
 * @param end summaryze until the (@end - 1)-th entry
 * @return IRQ for the elements of @v from @start to @end
 */
ST_double gf_array_diqr_range (ST_double v[], const GT_size start, const GT_size end)
{
    return (gf_array_dquantile_range(v, start, end, 75) - gf_array_dquantile_range(v, start, end, 25));
}

/**
 * @brief SE of the mean, sd / sqrt(n)
 *
 * @param v vector of doubles containing the current group's variables
 * @param start summaryze starting at the @start-th entry
 * @param end summaryze until the (@end - 1)-th entry
 * @return SE of the mean for the elements of @v from @start to @end
 */
ST_double gf_array_dsemean_range (const ST_double v[], const GT_size start, const GT_size end)
{
    return (gf_array_dsd_range(v, start, end) / sqrt(end - start));
}

/**
 * @brief SE of the mean, binomial, sqrt(p * (1 - p) / n)
 *
 * @param v vector of doubles containing the current group's variables
 * @param start summaryze starting at the @start-th entry
 * @param end summaryze until the (@end - 1)-th entry
 * @return SE of the mean for the elements of @v from @start to @end
 */
ST_double gf_array_dsebinom_range (const ST_double v[], const GT_size start, const GT_size end)
{
    GT_size i;
    ST_double p;
    for (i = start; i < end; i++) {
        if ( (v[i] != ((ST_double) 0)) && (v[i] != ((ST_double) 1)) ) return (SV_missval);
    }
    p = gf_array_dmean_range(v, start, end);
    return (sqrt(p * (1 - p) / (end - start)));
}

/**
 * @brief SE of the mean, poisson, sqrt(mean)
 *
 * @param v vector of doubles containing the current group's variables
 * @param start summaryze starting at the @start-th entry
 * @param end summaryze until the (@end - 1)-th entry
 * @return SE of the mean for the elements of @v from @start to @end
 */
ST_double gf_array_dsepois_range (const ST_double v[], const GT_size start, const GT_size end)
{
    GT_size i;
    // GT_size vsum = 0;
    for (i = start; i < end; i++) {
        if ( v[i] < 0 ) return (SV_missval);
        // vsum += (GT_size) round(v[i]);
    }

    // ST_double rmean = (GT_int) gf_array_dsum_range(v, start, end);
    ST_double rmean = (GT_int) (gf_array_dsum_range(v, start, end) + 0.5);
    return (sqrt(rmean) / (end - start));
}

/**
 * @brief Skewness
 *
 * @param v vector of doubles containing the current group's variables
 * @param start summaryze starting at the @start-th entry
 * @param end summaryze until the (@end - 1)-th entry
 * @return Skewness of @v from @start to @end
 */
ST_double gf_array_dskew_range (const ST_double v[], const GT_size start, const GT_size end)
{

    if ( gf_array_dsame(v + start, end - start) ) {
        return (SV_missval);
    }

    GT_size i;
    ST_double s1, s2, aux1, aux2;
    ST_double m2 = 0;
    ST_double m3 = 0;
    ST_double vmean = gf_array_dmean_range(v, start, end);

    for (i = start; i < end; i++) {
        s1  = (v[i] - vmean);
        s2  = s1 * s1;
        m2 += s2;
        m3 += s2 * s1;
    }

    m2 /= (end - start);
    m3 /= (end - start);

    aux1 = sqrt(m2);
    aux2 = aux1 * aux1 * aux1;

    return ((aux2 > 0)? m3 / aux2: SV_missval);
}

/**
 * @brief Kurtosis
 *
 * @param v vector of doubles containing the current group's variables
 * @param start summaryze starting at the @start-th entry
 * @param end summaryze until the (@end - 1)-th entry
 * @return Kurtosis of @v from @start to @end
 */
ST_double gf_array_dkurt_range (const ST_double v[], const GT_size start, const GT_size end)
{
    if ( gf_array_dsame(v + start, end - start) ) {
        return (SV_missval);
    }

    GT_size i;
    ST_double s;
    ST_double m2 = 0;
    ST_double m4 = 0;
    ST_double vmean = gf_array_dmean_range(v, start, end);

    for (i = start; i < end; i++) {
        s   = SQUARE(v[i] - vmean);
        m2 += s;
        m4 += s * s;
    }

    m2 /= (end - start);
    m4 /= (end - start);
    return (m2 > 0? m4 / (m2 * m2): SV_missval);
}

/**
 * @brief Gini coefficient of enries in range of array
 *
 * The Gini can be expressed as 1 - 2B, where B is the area under the
 * Lorenz curve. Let y_1 <= y_2 <= ... <= y_n be the incomes of a
 * population, and w_i the number of people who have income y_i.
 *
 * For a discrete population, the Lorenz can be expressed in terms of
 * the cmf (cummulative mass function) that a given individual has
 * income y_i, which is given by
 *
 *     W_i = sum from j = 0 to i of w_j
 *     F(y_i) = W_i / W_n
 *
 * with y_0, w_0 defined as 0. Let
 *
 *     Y_i = sum from j = 0 to i of y_i
 *
 * then, noting Y_i - Y_{i - 1} = y_i, we have the trapezoidal
 * approximation of the area under the Lorenz curve,
 *
 *     b_i = w_i y_i (W_i + W_{i - 1})
 *         = y_i (W_i - W_{i - 1}) (W_i + W_{i - 1})
 *         = y_i (W_i^2 - W_{i - 1}^2)
 *     B_i = 0.5 [(1 - W_i / W_n) + (1 - W_{i - 1} / W_n)] (w_i y_i / Y_n)
 *         = 0.5 [2 w_i y_i - b_i] / W_n Y_n
 *     B   = sum from i = 1 to n of B_i
 *         = [(sum from i = 1 to n of b_i) / (W_n Y_n)] - 1
 *
 * if w_i = 1, then
 *
 *     b_i = y_i (2i - 1) = 2i y_i - y_i
 *     B   = [(-Y_n + sum from i = 1 to n of 2i y_i) / (n Y_n)] - 1
 *         = 2 (sum from i = 1 to n of i y_i) / (n Y_n)
 *         - (n + 1) / n
 *
 * @param v vector of doubles containing the current group's variables
 * @param start summaryze starting at the @start-th entry
 * @param end summaryze until the (@end - 1)-th entry
 * @return Gini coefficient of the elements of @v from @start to @end
 */
ST_double gf_array_dgini_range (ST_double v[], const GT_size start, const GT_size end)
{
    GT_size i;
    ST_double Ndbl  = end - start;
    ST_double vsum  = 0;
    ST_double ivsum = 0;

    quicksort_bsd(
        v + start,
        end - start,
        (sizeof *v),
        xtileCompare,
        NULL
    );

    // truncate negative income to 0
    i = start;
    while ( v[i] < 0 && i < end ) {
        i++;
    }

    // sum over non-negative income but the correct i offset
    while ( i < end ) {
        vsum  += v[i];
        ivsum += (i - start + 1) * v[i];
        i++;
    }

    if ( vsum == 0 ) {
        return (SV_missval);
    }
    else {
        return (((2 * ivsum) / (Ndbl * vsum)) - ((Ndbl + 1) / Ndbl));
    }
}

ST_double gf_array_dginidrop_range (ST_double v[], const GT_size start, const GT_size end)
{
    GT_size i;
    ST_double Ndbl;
    ST_double vsum  = 0;
    ST_double ivsum = 0;
    GT_size   nobs  = 0;

    quicksort_bsd(
        v + start,
        end - start,
        (sizeof *v),
        xtileCompare,
        NULL
    );

    // drop negative income
    i = start;
    while ( v[i] < 0 && i < end ) {
        i++;
    }

    // sum over non-negative income but the correct offset
    while ( i < end ) {
        ++nobs;
        vsum  += v[i];
        ivsum += nobs * v[i];
        i++;
    }

    if ( nobs == 0 || vsum == 0 ) {
        return (SV_missval);
    }
    else {
        Ndbl = (ST_double) nobs;
        return (((2 * ivsum) / (Ndbl * vsum)) - ((Ndbl + 1) / Ndbl));
    }
}

ST_double gf_array_dginikeep_range (ST_double v[], const GT_size start, const GT_size end)
{
    GT_size i;
    ST_double Ndbl  = end - start;
    ST_double vsum  = 0;
    ST_double ivsum = 0;

    quicksort_bsd(
        v + start,
        end - start,
        (sizeof *v),
        xtileCompare,
        NULL
    );

    for (i = start; i < end; i++) {
        vsum  += v[i];
        ivsum += (i - start + 1) * v[i];
    }

    if ( vsum == 0 ) {
        return (SV_missval);
    }
    else {
        return (((2 * ivsum) / (Ndbl * vsum)) - ((Ndbl + 1) / Ndbl));
    }
}

/**
 * @brief Wrapper to encode summary function using an integer
 *
 * We use negative numbers so that we can return quantiles as is.
 *
 * @param fname Character with name of funtion
 * @return internal code for summary function
 */
ST_double gf_code_fun (char * fname)
{
         if ( strcmp (fname, "sum")          == 0 ) return (-1);    // sum
    else if ( strcmp (fname, "nansum")       == 0 ) return (-101);  // sum (keepmissing)
    else if ( strcmp (fname, "mean")         == 0 ) return (-2);    // mean
    else if ( strcmp (fname, "sd")           == 0 ) return (-3);    // sd
    else if ( strcmp (fname, "max")          == 0 ) return (-4);    // max
    else if ( strcmp (fname, "min")          == 0 ) return (-5);    // min
    else if ( strcmp (fname, "count")        == 0 ) return (-6);    // count
    else if ( strcmp (fname, "percent")      == 0 ) return (-7);    // percent
    else if ( strcmp (fname, "median")       == 0 ) return (50);    // median
    else if ( strcmp (fname, "iqr")          == 0 ) return (-9);    // iqr
    else if ( strcmp (fname, "first")        == 0 ) return (-10);   // first
    else if ( strcmp (fname, "firstnm")      == 0 ) return (-11);   // firstnm
    else if ( strcmp (fname, "last")         == 0 ) return (-12);   // last
    else if ( strcmp (fname, "lastnm")       == 0 ) return (-13);   // lastnm
    else if ( strcmp (fname, "semean")       == 0 ) return (-15);   // semean
    else if ( strcmp (fname, "sebinomial")   == 0 ) return (-16);   // sebinomial
    else if ( strcmp (fname, "sepoisson ")   == 0 ) return (-17);   // sepoisson
    else if ( strcmp (fname, "skewness")     == 0 ) return (-19);   // skewness
    else if ( strcmp (fname, "kurtosis")     == 0 ) return (-20);   // kurtosis
    else if ( strcmp (fname, "rawsum")       == 0 ) return (-21);   // rawsum
    else if ( strcmp (fname, "rawnansum")    == 0 ) return (-121);  // rawsum (keepmissing)
    else if ( strcmp (fname, "variance")     == 0 ) return (-23);   // variance
    else if ( strcmp (fname, "cv")           == 0 ) return (-24);   // cv
    else if ( strcmp (fname, "range")        == 0 ) return (-25);   // range
    else if ( strcmp (fname, "geomean")      == 0 ) return (-26);   // geomean
    else if ( strcmp (fname, "gini")         == 0 ) return (-27);   // gini
    else if ( strcmp (fname, "gini|dropneg") == 0 ) return (-27.1); // gini dropneg
    else if ( strcmp (fname, "gini|keepneg") == 0 ) return (-27.2); // gini keepneg
    else {
        ST_double q = (ST_double) atof(fname);                   // quantile
        return (q > 0? q: 0);
    }
}

/**
 * @brief Wrapper to choose summary function using internal code
 *
 * See gf_code_fun above
 *
 * @param fcode double with function code
 * @param v vector of doubles containing the current group's variables
 * @param start summaryze starting at the @start-th entry
 * @param end summaryze until the (@end - 1)-th entry
 * @return @fname(@v[@start to @end])
 */
ST_double gf_switch_fun_code (ST_double fcode, ST_double v[], const GT_size start, const GT_size end)
{
         if ( fcode == -1    ) return (gf_array_dsum_range      (v, start, end)); // sum
    else if ( fcode == -101  ) return (gf_array_dsum_range      (v, start, end)); // sum (keepmissing)
    else if ( fcode == -2    ) return (gf_array_dmean_range     (v, start, end)); // mean
    else if ( fcode == -3    ) return (gf_array_dsd_range       (v, start, end)); // sd)
    else if ( fcode == -4    ) return (gf_array_dmax_range      (v, start, end)); // max
    else if ( fcode == -5    ) return (gf_array_dmin_range      (v, start, end)); // min
    else if ( fcode == -9    ) return (gf_array_diqr_range      (v, start, end)); // iqr
    else if ( fcode == -15   ) return (gf_array_dsemean_range   (v, start, end)); // semean
    else if ( fcode == -16   ) return (gf_array_dsebinom_range  (v, start, end)); // sebinomial
    else if ( fcode == -17   ) return (gf_array_dsepois_range   (v, start, end)); // sepoisson
    else if ( fcode == -19   ) return (gf_array_dskew_range     (v, start, end)); // skewness
    else if ( fcode == -20   ) return (gf_array_dkurt_range     (v, start, end)); // kurtosis
    else if ( fcode == -21   ) return (gf_array_dsum_range      (v, start, end)); // rawsum
    else if ( fcode == -121  ) return (gf_array_dsum_range      (v, start, end)); // rawsum (keepmissing)
    else if ( fcode == -23   ) return (gf_array_dvar_range      (v, start, end)); // variance
    else if ( fcode == -24   ) return (gf_array_dcv_range       (v, start, end)); // cv
    else if ( fcode == -25   ) return (gf_array_drange_range    (v, start, end)); // range
    else if ( fcode == -26   ) return (gf_array_dgeomean_range  (v, start, end)); // geomean
    else if ( fcode == -27   ) return (gf_array_dgini_range     (v, start, end)); // gini
    else if ( fcode == -27.1 ) return (gf_array_dginidrop_range (v, start, end)); // gini dropneg
    else if ( fcode == -27.2 ) return (gf_array_dginikeep_range (v, start, end)); // gini keepneg
    else {
        return (gf_array_dquantile_range(v, start, end, fcode));                // percentiles
    }
}

/**
 * @brief Compare function for qsort
 *
 * @param a First element
 * @param b Second element
 * @return @a - @b
 */
int gf_qsort_compare (const void * a, const void * b)
{
    return ( (int) *(ST_double*)a - *(ST_double*)b );
}

/**
 * @brief Determine if of enries in range of array are sorted
 *
 * @param v vector of doubles containing the current group's variables
 * @param start summaryze starting at the @start-th entry
 * @param end summaryze until the (@end - 1)-th entry
 * @return Whether the elements of @v are sorted from @start to @end
 */
GT_bool gf_array_dsorted_range (const ST_double v[], const GT_size start, const GT_size end) {
    GT_size i;
    for (i = start + 1; i < end; i++) {
        if (v[i - 1] > v[i]) return (0);
    }
    return (1);
}

/**
 * @brief Determine if all entries are the same
 *
 * @param v vector of doubles containing the current group's variables
 * @param N number of elements
 * @return Whether the elements of @v are the same
 */
GT_bool gf_array_dsame (const ST_double *v, const GT_size N) {
    const ST_double *vptr;

    for (vptr = v + 1; vptr < v + N; vptr++) {
        if (*v != *vptr) return (0);
    }

    return (1);
}
