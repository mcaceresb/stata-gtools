#define SQUARE(x) ( (x) * (x) )
#define MAX(a, b) ( (a) > (b) ? (a) : (b) )
#define MIN(a, b) ( (a) > (b) ? (b) : (a) )

#define MAX_MATCHES 1

#include "gtools_math_unw.h"

/**
 * @brief Weighted wrapper to choose summary function using internal code
 *
 * See gf_code_fun above
 *
 * @param fcode double with function code
 * @param v vector of doubles containing the current group's variables
 * @param N number of elements
 * @return @fname(@v[@start to @end])
 */
ST_double gf_switch_fun_code_unw (
    ST_double fcode, 
    ST_double *v,
    GT_size N,
    GT_size vcount,
    ST_double *p_buffer)
{
         if ( fcode == -1   ) return (gf_array_drawsum_weighted    (v, N));                          // sum
    else if ( fcode == -101 ) return (gf_array_drawsum_weighted    (v, N));                          // sum (keepmissing)
    else if ( fcode == -2   ) return (gf_array_dmean_unweighted    (v, N));                          // mean
    else if ( fcode == -3   ) return ((vcount > 1)? gf_array_dsd_unweighted (v, N): SV_missval);     // sd)
    else if ( fcode == -4   ) return (gf_array_dmax_weighted       (v, N));                          // max
    else if ( fcode == -5   ) return (gf_array_dmin_range          (v, 0, N));                       // min
    else if ( fcode == -9   ) return (gf_array_diqr_unweighted     (v, N, p_buffer));                // iqr
    else if ( fcode == -15  ) return ((vcount > 1)? gf_array_dsemean_unweighted (v, N): SV_missval); // semean
    else if ( fcode == -16  ) return (gf_array_dsebinom_unweighted (v, N));                          // sebinomial
    else if ( fcode == -17  ) return (gf_array_dsepois_unweighted  (v, N));                          // sepoisson
    else if ( fcode == -19  ) return (gf_array_dskew_unweighted    (v, N));                          // skewness
    else if ( fcode == -20  ) return (gf_array_dkurt_unweighted    (v, N));                          // kurtosis
    else if ( fcode == -21  ) return (gf_array_drawsum_weighted    (v, N));                          // rawsum
    else if ( fcode == -121 ) return (gf_array_drawsum_weighted    (v, N));                          // rawsum (keepmissing)
    else if ( fcode == -23  ) return ((vcount > 1)? gf_array_dvar_unweighted (v, N): SV_missval);    // variance
    else if ( fcode == -24  ) return ((vcount > 1)? gf_array_dcv_unweighted  (v, N): SV_missval);    // cv
    else if ( fcode == -25  ) return (gf_array_drange_weighted     (v, N));                          // range
    else {
        return (gf_array_dquantile_unweighted(v, N, fcode, p_buffer));  // percentiles
    }
}

/**
 * @brief Mean of enries in range of array, unweighted
 *
 * @param v vector of doubles containing the current group's variables
 * @param N number of elements
 * @return Mean of the elements of @v from @start to @end
 */
ST_double gf_array_dmean_unweighted (ST_double *v, GT_size N)
{
    ST_double *vptr = v;
    ST_double vsum  = 0;
    GT_size   nobs  = 0;
    for (vptr = v; vptr < v + N; vptr++) {
        if ( *vptr < SV_missval ) {
            vsum += *vptr;
            nobs += 1;
        }
    }

    if ( nobs > 0 ) {
        return (vsum / nobs);
    }
    else {
        return (SV_missval);
    }
}

/**
 * @brief Unweighted IRQ for enries in range of array
 *
 * @param v vector of doubles containing the current group's variables
 * @param N number of elements
 * @return IRQ for the elements of @v unweighted by w
 */
ST_double gf_array_diqr_unweighted (
    ST_double *v,
    GT_size N,
    ST_double *p_buffer)
{
    return (gf_array_dquantile_unweighted(v, N, 75, p_buffer) - gf_array_dquantile_unweighted(v, N, 25, p_buffer));
}

/**
 * @brief Unweighted standard deviation entries in range of array
 *
 * @param v vector of doubles containing the current group's variables
 * @param N number of elements
 * @return Standard deviation of the elements of @v
 */
ST_double gf_array_dsd_unweighted (
    ST_double *v,
    GT_size N)
{
    if ( gf_array_dsame_unweighted(v, N) ) {
        return (0);
    }

    ST_double *vptr;
    ST_double vvar  = 0;
    ST_double vmean = gf_array_dmean_unweighted (v, N);
    GT_size   nobs  = 0;

    for (vptr = v; vptr < v + N; vptr++) {
        if ( *vptr < SV_missval ) {
            vvar += SQUARE(*vptr - vmean);
            nobs++;
        }
    }

    if ( nobs > 1 ) {
        return (sqrt(vvar / (nobs - 1)));
    }
    else {
        return (SV_missval);
    }
}

/**
 * @brief Unweighted variance of entries in range of array
 *
 * @param v vector of doubles containing the current group's variables
 * @param N number of elements
 * @return Variance of the elements of @v
 */
ST_double gf_array_dvar_unweighted (
    ST_double *v,
    GT_size N)
{
    if ( gf_array_dsame_unweighted(v, N) ) {
        return (0);
    }

    ST_double *vptr;
    ST_double vvar  = 0;
    ST_double vmean = gf_array_dmean_unweighted (v, N);
    GT_size   nobs  = 0;

    for (vptr = v; vptr < v + N; vptr++) {
        if ( *vptr < SV_missval ) {
            vvar += SQUARE(*vptr - vmean);
            nobs++;
        }
    }

    if ( nobs > 1 ) {
        return (vvar / (nobs - 1));
    }
    else {
        return (SV_missval);
    }
}

/**
 * @brief Unweighted coefficient of variation entries in range of array
 *
 * @param v vector of doubles containing the current group's variables
 * @param N number of elements
 * @return Coefficient of variation of the elements of @v
 */
ST_double gf_array_dcv_unweighted (
    ST_double *v,
    GT_size N)
{
    if ( gf_array_dsame_unweighted(v, N) ) {
        return (0);
    }

    ST_double *vptr;
    ST_double vvar  = 0;
    ST_double vmean = gf_array_dmean_unweighted (v, N);
    GT_size   nobs  = 0;

    for (vptr = v; vptr < v + N; vptr++) {
        if ( *vptr < SV_missval ) {
            vvar += SQUARE(*vptr - vmean);
            nobs++;
        }
    }

    if ( nobs > 1 ) {
        return (sqrt(vvar / (nobs - 1)) / vmean);
    }
    else {
        return (SV_missval);
    }
}

/**
 * @brief Unweighted SE of the mean, sd / sqrt(n)
 *
 * @param v vector of doubles containing the current group's variables
 * @param N number of elements
 * @return SE of the mean for the elements of @v
 */
ST_double gf_array_dsemean_unweighted (
    ST_double *v,
    GT_size N)
{
    if ( gf_array_dsame_unweighted(v, N) ) {
        return (0);
    }

    ST_double *vptr;
    ST_double vvar  = 0;
    ST_double vmean = gf_array_dmean_unweighted (v, N);
    GT_size   nobs  = 0;

    for (vptr = v; vptr < v + N; vptr++) {
        if ( *vptr < SV_missval ) {
            vvar += SQUARE(*vptr - vmean);
            nobs++;
        }
    }

    if ( nobs > 1 ) {
        return (sqrt(vvar / (nobs - 1)) / sqrt(nobs));
    }
    else {
        return (SV_missval);
    }
}

/**
 * @brief Unweighted SE of the mean, binomial, sqrt(p * (1 - p) / n)
 *
 * @param v vector of doubles containing the current group's variables
 * @param N number of elements
 * @return SE of the mean for the elements of @v
 */
ST_double gf_array_dsebinom_unweighted (
    ST_double *v,
    GT_size N)
{
    GT_size   nobs  = 0;
    ST_double vsum  = 0;
    ST_double *vptr;
    ST_double p;

    for (vptr = v; vptr < v + N; vptr++) {
        if ( *vptr < SV_missval ) {
            if ( (*vptr != ((ST_double) 0)) && (*vptr != ((ST_double) 1)) ) {
                return (SV_missval);
            }
            else {
                vsum += *vptr;
                nobs += 1;
            }
        }
    }

    if ( nobs > 0 ) {
        p = vsum / nobs;
        return (sqrt(p * (1 - p) / nobs));
    }
    else {
        return (SV_missval);
    }
}

/**
 * @brief Unweighted SE of the mean, poisson, sqrt(mean)
 *
 * @param v vector of doubles containing the current group's variables
 * @param N number of elements
 * @return SE of the mean for the elements of @v
 */
ST_double gf_array_dsepois_unweighted (
    ST_double *v,
    GT_size N)
{
    ST_double *vptr;
    ST_double vsum  = 0;
    GT_size   nobs  = 0;

    for (vptr = v; vptr < v + N; vptr++) {
        if ( *vptr < 0 ) {
            return (SV_missval);
        }
        else if ( *vptr < SV_missval ) {
            vsum += *vptr;
            nobs += 1;
        }
    }

    if ( nobs > 0 ) {
        return (sqrt((GT_int) (vsum + 0.5)) / nobs);
    }
    else {
        return (SV_missval);
    }
}

/**
 * @brief Unweighted skewness
 *
 * @param v vector of doubles containing the current group's variables
 * @param N number of elements
 * @return Skewness for the elements of @v
 */
ST_double gf_array_dskew_unweighted (
    ST_double *v,
    GT_size N)
{
    if ( gf_array_dsame_unweighted(v, N) ) {
        return (SV_missval);
    }

    ST_double *vptr, s1, s2, aux1, aux2;
    ST_double m2    = 0;
    ST_double m3    = 0;
    ST_double vmean = gf_array_dmean_unweighted (v, N);
    GT_size   nobs  = 0;

    for (vptr = v; vptr < v + N; vptr++) {
        if ( *vptr < SV_missval ) {
            s1 = (*vptr) - vmean;
            s2 = s1 * s1;
            m2 += s2;
            m3 += s2 * s1;
            nobs++;
        }
    }

    m2 /= nobs;
    m3 /= nobs;

    if ( (nobs > 1) && (m2 > 0) ) {
        aux1 = sqrt(m2);
        aux2 = aux1 * aux1 * aux1;
        return (aux2 > 0? m3 / aux2: SV_missval);
    }
    else {
        return (SV_missval);
    }
}

/**
 * @brief Unweighted kurtosis
 *
 * @param v vector of doubles containing the current group's variables
 * @param N number of elements
 * @return Kurtosis for the elements of @v
 */
ST_double gf_array_dkurt_unweighted (
    ST_double *v,
    GT_size N)
{
    if ( gf_array_dsame_unweighted(v, N) ) {
        return (SV_missval);
    }

    ST_double *vptr, s;
    ST_double m2    = 0;
    ST_double m4    = 0;
    ST_double vmean = gf_array_dmean_unweighted (v, N);
    GT_size   nobs  = 0;

    for (vptr = v; vptr < v + N; vptr++) {
        if ( *vptr < SV_missval ) {
            s  = SQUARE((*vptr) - vmean);
            m2 += s;
            m4 += s * s;
            nobs++;
        }
    }

    m2 /= nobs;
    m4 /= nobs;

    if ( (nobs > 1) && (m2 > 0) ) {
        return (m2 > 0? m4 / (m2 * m2): SV_missval);
    }
    else {
        return (SV_missval);
    }
}

/**
 * @brief Unweighted quantile of enries in range of array
 *
 * This computes the (quantile)th quantile using qsort. When
 * computing multiple quantiles, the data will already be sorted for the
 * next iteration, so it's faster than sorting every time, but it it
 * still a VERY inefficient implementation.
 *
 * @param v vector of doubles containing the current group's variables
 * @param N number of elements
 * @param quantile Quantile to compute
 * @param p_buffer Buffer where to put a copy of v and w to sort
 * @return Quantile of the elements of @v from @start to @end
 */
ST_double gf_array_dquantile_unweighted (
    ST_double *v,
    GT_size N,
    ST_double quantile,
    ST_double *p_buffer)
{

    GT_size   i;
    GT_size   vcount = 0;
    ST_double *vptr  = v;

    if ( N == 1 ) return (*v);

    // Copy to buffer and fall back on range version
    // ---------------------------------------------

    for (i = 0; i < N; i++, vptr++) {
        if ( *vptr < SV_missval ) {
            p_buffer[vcount] = *vptr;
            vcount++;
        }
    }

    if ( vcount == 0 ) {
        return (SV_missval);
    }

    // quicksort_bsd(
    //     p_buffer,
    //     N,
    //     sizeof(p_buffer),
    //     xtileCompare,
    //     NULL
    // );

    return (gf_array_dquantile_range(p_buffer, 0, vcount, quantile));
}

/**
 * @brief Unweighted select of enries in range of array
 *
 * @param v vector of doubles containing the current group's variables
 * @param N number of elements
 * @param sth element to select
 * @param p_buffer Buffer where to put a copy of v and w to sort
 * @return Quantile of the elements of @v from @start to @end
 */
ST_double gf_array_dselect_unweighted (
    ST_double *v,
    GT_size   N,
    GT_int    sth,
    GT_size   end,
    ST_double *p_buffer)
{

    GT_size   i;
    GT_size   vcount = 0;
    ST_double *vptr  = v;

    if ( N == 1 ) {
        return (*v);
    }
    else if ( sth < 0 ) {
        return (SV_missval);
    }
    else if ( end == 0 && sth < N ) {
        return (gf_qselect_range(v, 0, N, sth));
    }
    else if ( end > 0 && sth < end ) {
        for (i = 0; i < N; i++, vptr++) {
            if ( *vptr < SV_missval ) {
                p_buffer[vcount] = *vptr;
                vcount++;
            }
        }
        if ( vcount == 0 ) {
            return (gf_qselect_range(v, 0, N, sth));
        }
        else if ( sth < vcount ) {
            return (gf_qselect_range(p_buffer, 0, vcount, sth));
        }
        else {
            return (SV_missval);
        }
    }
    else {
        return (SV_missval);
    }

    // idea:
    // quicksort_bsd(
    //     p_buffer,
    //     N,
    //     sizeof(p_buffer),
    //     xtileCompare,
    //     NULL
    // );
    // memcpy(v, p_buffer, sizeof(v) * N);
    // return(v[sth]);
}
