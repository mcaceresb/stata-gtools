#define SQUARE(x) ( (x) * (x) )
#define MAX(a, b) ( (a) > (b) ? (a) : (b) )
#define MIN(a, b) ( (a) > (b) ? (b) : (a) )

#define MAX_MATCHES 1

#include "gtools_math_w.h"

/**
 * @brief Weighted wrapper to choose summary function using internal code
 *
 * See gf_code_fun above
 *
 * @param fcode double with function code
 * @param v vector of doubles containing the current group's variables
 * @param N number of elements
 * @param w weights
 * @param vsum sum(v_i * w_i)
 * @param wsum sum(w_i)
 * @param vcount sum(v_i < SV_missval)
 * @param aw aweights adjustment
 * @return @fname(@v[@start to @end])
 */
ST_double gf_switch_fun_code_w (
    ST_double fcode,
    ST_double *v,
    GT_size N,
    ST_double *w,
    ST_double vsum,
    ST_double wsum,
    GT_size   vcount,
    GT_bool   aw,
    ST_double *p_buffer)
{
         if ( fcode == -1  )  return (aw? vsum * vcount / wsum: vsum);                               // sum
    else if ( fcode == -2  )  return (wsum == 0? SV_missval: vsum / wsum);                           // mean
    else if ( fcode == -3  )  return (gf_array_dsd_weighted      (v, N, w, vsum, wsum, vcount, aw)); // sd)
    else if ( fcode == -4  )  return (gf_array_dmax_weighted     (v, N));                            // max
    else if ( fcode == -5  )  return (gf_array_dmin_range        (v, 0, N));                         // min
    else if ( fcode == -9  )  return (gf_array_diqr_weighted     (v, N, w, wsum, vcount, p_buffer)); // iqr
    else if ( fcode == -15 )  return (gf_array_dsemean_weighted  (v, N, w, vsum, wsum, vcount, aw)); // semean
    else if ( fcode == -16 )  return (gf_array_dsebinom_weighted (v, N, w, vsum, wsum, vcount));     // sebinomial
    else if ( fcode == -17 )  return (gf_array_dsepois_weighted  (v, N, w, vsum, wsum, vcount));     // sepoisson
    else if ( fcode == -19 )  return (gf_array_dskew_weighted    (v, N, w, vsum, wsum, vcount));     // skewness
    else if ( fcode == -20 )  return (gf_array_dkurt_weighted    (v, N, w, vsum, wsum, vcount));     // kurtosis
    else if ( fcode == -21 )  return (gf_array_drawsum_weighted  (v, N));                            // rawsum
    else {
        return (gf_array_dquantile_weighted(v, N, w, fcode, wsum, vcount, p_buffer));                // percentiles
    }
}

/**
 * @brief Sum of entries in range of array, unweighted
 *
 * @param v vector of doubles containing the current group's variables
 * @param N number of elements
 * @return Unweighted sum
 */
ST_double gf_array_drawsum_weighted (ST_double *v, GT_size N)
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
        return (vsum);
    }
    else {
        return (SV_missval);
    }
}

/**
 * @brief Weighted quantile of enries in range of array
 *
 * This computes the (quantile)th quantile using qsort. When
 * computing multiple quantiles, the data will already be sorted for the
 * next iteration, so it's faster than sorting every time, but it it
 * still a VERY inefficient implementation.
 *
 * @param v vector of doubles containing the current group's variables
 * @param N number of elements
 * @param w weights
 * @param p_buffer Buffer where to put a copy of v and w to sort
 * @param quantile Quantile to compute
 * @param wsum sum(w_i)
 * @param vcount sum(v_i < SV_missval)
 * @return Quantile of the elements of @v from @start to @end
 */
ST_double gf_array_dquantile_weighted (
    ST_double *v,
    GT_size N,
    ST_double *w,
    ST_double quantile,
    ST_double wsum,
    GT_size   vcount,
    ST_double *p_buffer)
{
    if ( wsum == 0 ) return (SV_missval);

    ST_double *vptr = v;
    ST_double *wptr = w;

    ST_double q, qdbl, qfoo, cumsum, cumnorm, Ndbl;
    GT_size   Ndiv, qth, i;
    GT_bool   rfoo, Nmod;

    if ( N == 1 ) return (*v);

    // Sort group elements and weights
    // -------------------------------

    Ndbl = (ST_double) vcount;
    for (i = 0; i < N; i++, vptr++, wptr++) {
        p_buffer[2 * i]     = *vptr;
        p_buffer[2 * i + 1] = *wptr;
    }

    // quicksort_bsd(
    //     p_buffer,
    //     N,
    //     2 * sizeof(p_buffer),
    //     xtileCompare,
    //     NULL
    // );
    GT_size invert[2]; invert[0] = 0; invert[1] = 0;
    MultiQuicksortDbl(
        p_buffer,
        N,
        0,
        1,
        2 * sizeof(p_buffer),
        invert
    );

    // Numerical precision foo
    // -----------------------

    Nmod = vcount % 100;
    if ( Nmod ) {
        qdbl = quantile * Ndbl / 100;
    }
    else {
        Ndiv = vcount / 100;
        qdbl = quantile * Ndiv;
    }

    // Get position of quantile
    // ------------------------

    // i s.t. cumsum w_i > quantile
    i = 0;
    cumsum  = 0;
    cumnorm = Ndbl / wsum;
    do {
        cumsum += (qfoo = p_buffer[2 * i + 1] * cumnorm);
    } while ( ((cumsum - qdbl) < GTOOLS_WQUANTILES_TOL) & (++i < N) );

    qth     = i - 1;
    cumsum -= qfoo;
    rfoo    = !((qdbl - cumsum) > GTOOLS_WQUANTILES_TOL);

    // Return qth element or average
    // -----------------------------

    q = p_buffer[2 * qth];
    if ( rfoo && qth > 0 ) {
        q += p_buffer[2 * (qth - 1)];
        q /= 2;
    }

    return (q);
}

/**
 * @brief Weighted IRQ for enries in range of array
 *
 * @param v vector of doubles containing the current group's variables
 * @param N number of elements
 * @param w weights
 * @param p_buffer Buffer where to put a copy of v and w to sort
 * @param wsum sum(w_i)
 * @param vcount sum(v_i < SV_missval)
 * @return IRQ for the elements of @v weighted by w
 */
ST_double gf_array_diqr_weighted (
    ST_double *v,
    GT_size N,
    ST_double *w,
    ST_double wsum,
    GT_size   vcount,
    ST_double *p_buffer)
{
    return (gf_array_dquantile_weighted(v, N, w, 75, wsum, vcount, p_buffer) -
            gf_array_dquantile_weighted(v, N, w, 25, wsum, vcount, p_buffer));
}

/**
 * @brief Sum and weighted sum
 *
 * @param v vector of doubles containing the current group's variables
 * @param N number of elements
 * @param w weights
 * @param vsum where to store sum(v_i * w_i)
 * @param wsum where to store sum(w_i)
 * @param vcount sum(v_i < SV_missval)
 * @return Returns sum(w_i) and sum(v_i w_i)
 */
void gf_array_dsum_dcount_weighted (
    ST_double *v,
    GT_size N,
    ST_double *w,
    ST_double *vsum,
    ST_double *wsum,
    GT_size   *vcount)
{
    ST_double *vptr;
    ST_double *wptr   = w;
    ST_double _vsum   = 0;
    ST_double _wsum   = 0;
    GT_size   nobs    = 0;

    GT_size i = 0;
    for (vptr = v; vptr < v + N; vptr++, wptr++) {
        i++;
        if ( *vptr < SV_missval ) {
            _wsum += *wptr;
            _vsum += (*vptr) * (*wptr);
            nobs++;
        }
    }

    *vsum   = nobs? _vsum: SV_missval;
    *wsum   = nobs? _wsum: SV_missval;
    *vcount = nobs;
}

/**
 * @brief First non-missing
 *
 * @param v vector of doubles containing the current group's variables
 * @param N number of elements
 * @return First non-missnig element of @v
 */
ST_double gf_array_dfirstnm (
    ST_double *v,
    GT_size N)
{
    ST_double *vptr;
    for (vptr = v; vptr < v + N; vptr++)
        if ( *vptr < SV_missval ) return(*vptr);

    return (SV_missval);
}

/**
 * @brief Last non-missing
 *
 * @param v vector of doubles containing the current group's variables
 * @param N number of elements
 * @return Last non-missnig element of @v
 */
ST_double gf_array_dlastnm (
    ST_double *v,
    GT_size N)
{
    ST_double *vptr;
    for (vptr = v + N - 1; vptr >= v; vptr--)
        if ( *vptr < SV_missval ) return(*vptr);

    return (SV_missval);
}

/**
 * @brief Weighted sum of entries in range of array
 *
 * @param v vector of doubles containing the current group's variables
 * @param N number of elements
 * @param w weights
 * @return Sum of the elements of @v
 */
ST_double gf_array_dsum_weighted (
    ST_double *v,
    GT_size N,
    ST_double *w)
{
    ST_double *vptr;
    ST_double *wptr = w;
    ST_double vsum = 0;
    for (vptr = v; vptr < v + N; vptr++, wptr++)
        if ( *vptr < SV_missval ) vsum += (*vptr) * (*wptr);

    return (vsum);
}

/**
 * @brief Weighted mean of enries in range of array
 *
 * @param v vector of doubles containing the current group's variables
 * @param N number of elements
 * @param w weights
 * @return Mean of the elements of @v
 */
ST_double gf_array_dmean_weighted (
    ST_double *v,
    GT_size N,
    ST_double *w)
{
    ST_double *vptr;
    ST_double *wptr = w;
    ST_double vsum = 0;
    ST_double wsum = 0;

    for (vptr = v; vptr < v + N; vptr++, wptr++) {
        if ( *vptr < SV_missval ) {
            wsum += *wptr;
            vsum += (*vptr) * (*wptr);
        }
    }

    return (wsum == 0? SV_missval: vsum / wsum);
}

/**
 * @brief Weighted standard deviation entries in range of array
 *
 * @param v vector of doubles containing the current group's variables
 * @param N number of elements
 * @param w weights
 * @param vsum sum(v_i * w_i)
 * @param wsum sum(w_i)
 * @param vcount sum(v_i < SV_missval)
 * @param aw aweights adjustment
 * @return Standard deviation of the elements of @v
 */
ST_double gf_array_dsd_weighted (
    ST_double *v,
    GT_size N,
    ST_double *w,
    ST_double vsum,
    ST_double wsum,
    GT_size   vcount,
    GT_bool   aw)
{
    if ( (wsum == 0) || (wsum == 1) || (vcount < 2) ) return (SV_missval);

    if ( gf_array_dsame_unweighted(v, N) ) {
        return (0);
    }

    ST_double *vptr;
    ST_double *wptr  = w;
    ST_double vvar  = 0;
    ST_double vmean = vsum / wsum;
    GT_size   nobs  = 0;

    for (vptr = v; vptr < v + N; vptr++, wptr++) {
        if ( *vptr < SV_missval ) {
            vvar += (*wptr) * SQUARE(*vptr - vmean);
            nobs++;
        }
    }

    if ( aw ) {
        if ( nobs > 1 ) {
            return (sqrt((vcount / wsum) * vvar / (vcount - 1)));
        }
        else {
            return (SV_missval);
        }
    }
    else {
        vvar /= (wsum - 1);
        return(vvar < 0? SV_missval: sqrt(vvar));
    }

}

/**
 * @brief Weighted SE of the mean, sd / sqrt(n)
 *
 * @param v vector of doubles containing the current group's variables
 * @param N number of elements
 * @param w weights
 * @param vsum sum(v_i * w_i)
 * @param wsum sum(w_i)
 * @param vcount sum(v_i < SV_missval)
 * @param aw aweights adjustment
 * @return SE of the mean for the elements of @v
 */
ST_double gf_array_dsemean_weighted (
    ST_double *v,
    GT_size N,
    ST_double *w,
    ST_double vsum,
    ST_double wsum,
    GT_size   vcount,
    GT_bool   aw)
{
    if ( (wsum == 0) || (wsum == 1) || (vcount < 2) ) return (SV_missval);

    if ( gf_array_dsame_unweighted(v, N) ) {
        return (0);
    }

    ST_double *vptr;
    ST_double *wptr  = w;
    ST_double vvar  = 0;
    ST_double vmean = vsum / wsum;

    for (vptr = v; vptr < v + N; vptr++, wptr++) {
        if ( *vptr < SV_missval ) {
            vvar += (*wptr) * SQUARE(*vptr - vmean);
        }
    }

    vvar /= (wsum * ((aw? vcount: wsum) - 1));
    return (vvar < 0? SV_missval: sqrt(vvar));
}

/**
 * @brief Weighted SE of the mean, binomial, sqrt(p * (1 - p) / n)
 *
 * @param v vector of doubles containing the current group's variables
 * @param N number of elements
 * @param w weights
 * @param vsum sum(v_i * w_i)
 * @param wsum sum(w_i)
 * @param vcount sum(v_i < SV_missval)
 * @return SE of the mean for the elements of @v
 */
ST_double gf_array_dsebinom_weighted (
    ST_double *v,
    GT_size N,
    ST_double *w,
    ST_double vsum,
    ST_double wsum,
    GT_size   vcount)
{
    if ( wsum == 0 ) return (SV_missval);

    ST_double *vptr;
    ST_double p;

    for (vptr = v; vptr < v + N; vptr++) {
        // if ( (*vptr != ((ST_double) 0)) && (*vptr != ((ST_double) 1)) ) return (SV_missval);
        if ( (*vptr < SV_missval) && (*vptr != ((ST_double) 0)) && (*vptr != ((ST_double) 1)) )
            return (SV_missval);
    }

    p = vsum / wsum;
    return (sqrt(p * (1 - p) / wsum));
}

/**
 * @brief Weighted SE of the mean, poisson, sqrt(mean)
 *
 * @param v vector of doubles containing the current group's variables
 * @param N number of elements
 * @param w weights
 * @param vsum sum(v_i * w_i)
 * @param wsum sum(w_i)
 * @param vcount sum(v_i < SV_missval)
 * @return SE of the mean for the elements of @v
 */
ST_double gf_array_dsepois_weighted (
    ST_double *v,
    GT_size N,
    ST_double *w,
    ST_double vsum,
    ST_double wsum,
    GT_size   vcount)
{
    if ( wsum == 0 ) return (SV_missval);

    ST_double *vptr;
    ST_double *wptr = w;

    for (vptr = v; vptr < v + N; vptr++, wptr++) {
        if ( *vptr < 0 ) return (SV_missval);
    }

    // return (sqrt(((GT_int) vsum) / wsum);
    return (sqrt((GT_int) (vsum + 0.5)) / wsum);
}

/**
 * @brief Weighted skewness
 *
 * @param v vector of doubles containing the current group's variables
 * @param N number of elements
 * @param w weights
 * @param vsum sum(v_i * w_i)
 * @param wsum sum(w_i)
 * @param vcount sum(v_i < SV_missval)
 * @return Skewness for the elements of @v
 */
ST_double gf_array_dskew_weighted (
    ST_double *v,
    GT_size N,
    ST_double *w,
    ST_double vsum,
    ST_double wsum,
    GT_size   vcount)
{
    if ( gf_array_dsame_unweighted(v, N) ) {
        return (SV_missval);
    }

    if ( wsum == 0 ) return (SV_missval);

    ST_double *vptr, s1, s2, aux1, aux2;
    ST_double *wptr = w;
    ST_double m2    = 0;
    ST_double m3    = 0;
    ST_double vmean = vsum / wsum;
    GT_size   nobs  = 0;

    for (vptr = v; vptr < v + N; vptr++, wptr++) {
        if ( *vptr < SV_missval ) {
            s1 = (*vptr) - vmean;
            s2 = s1 * s1;
            m2 += (*wptr) * s2;
            m3 += (*wptr) * s2 * s1;
            nobs++;
        }
    }

    m2 /= wsum;
    m3 /= wsum;

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
 * @brief Weighted kurtosis
 *
 * @param v vector of doubles containing the current group's variables
 * @param N number of elements
 * @param w weights
 * @param vsum sum(v_i * w_i)
 * @param wsum sum(w_i)
 * @param vcount sum(v_i < SV_missval)
 * @return Kurtosis for the elements of @v
 */
ST_double gf_array_dkurt_weighted (
    ST_double *v,
    GT_size N,
    ST_double *w,
    ST_double vsum,
    ST_double wsum,
    GT_size   vcount)
{
    if ( gf_array_dsame_unweighted(v, N) ) {
        return (SV_missval);
    }

    if ( wsum == 0 ) return (SV_missval);

    ST_double *vptr, s;
    ST_double *wptr = w;
    ST_double m2    = 0;
    ST_double m4    = 0;
    ST_double vmean = vsum / wsum;
    GT_size   nobs  = 0;

    for (vptr = v; vptr < v + N; vptr++, wptr++) {
        if ( *vptr < SV_missval ) {
            s  = SQUARE((*vptr) - vmean);
            m2 += (*wptr) * s;
            m4 += (*wptr) * s * s;
            nobs++;
        }
    }

    m2 /= wsum;
    m4 /= wsum;

    if ( (nobs > 1) && (m2 > 0) ) {
        return (m2 > 0? m4 / (m2 * m2): SV_missval);
    }
    else {
        return (SV_missval);
    }
}

/**
 * @brief Max of enries in range of array
 *
 * @param v vector of doubles containing the current group's variables
 * @param N number of elements
 * @return Max of the elements of @v from @start to @end
 */
ST_double gf_array_dmax_weighted (ST_double *v, GT_size N)
{
    GT_size i;
    ST_double *vptr = v;
    ST_double max;

    // Largest missing value
    i   = 0;
    max = *v;
    while ( (*vptr >= SV_missval) & (++i < N) ) {
        vptr++;
        if (max < *vptr) max = *vptr;
    }

    if ( *vptr < SV_missval ) {
        // Largest non-missing value, if not all are missing
        max = *(v + i - 1);
        for (vptr = v + i; vptr < v + N; vptr++) {
            if ( (*vptr < SV_missval) && (max < *vptr) ) {
                max = *vptr;
            }
        }
    }

    // Return largest non-missing if at least one non-missing; return
    // largest missing if all missing
    return (max);
}

/**
 * @brief Determine if all entries are the same, weighted
 *
 * @param v vector of doubles containing the current group's variables
 * @param N number of elements
 * @return Whether the elements of @v are the same, weighted
 */
GT_bool gf_array_dsame_weighted (ST_double *v, ST_double *w, GT_size N) {
    ST_double *vstart = v, *vptr;
    ST_double *wstart = w, *wptr;

    while ( (*vstart >= SV_missval) || (*wstart >= SV_missval) ) {
        vstart++;
        wstart++;
    }

    wptr = wstart + 1;
    for (vptr = vstart + 1; vptr < v + N; vptr++, wptr++) {
        if ( (*vptr < SV_missval) && (*wptr < SV_missval) && ( ((*vstart) * (*wstart)) != ((*vptr) * (*wptr)) ) ) {
            return (0);
        }
    }

    return (1);
}

/**
 * @brief Determine if all entries are the same, unweighted
 *
 * @param v vector of doubles containing the current group's variables
 * @param N number of elements
 * @return Whether the elements of @v are the same, unweighted
 */
GT_bool gf_array_dsame_unweighted (ST_double *v, GT_size N) {
    ST_double *vstart = v, *vptr;

    while ( *vstart >= SV_missval ) {
        vstart++;
    }

    for (vptr = vstart + 1; vptr < v + N; vptr++) {
        if ( (*vptr < SV_missval) && (*vstart != *vptr) ) return (0);
    }

    return (1);
}
