ST_double GtoolsStatsIndexWeighted (
    ST_double *source,
    ST_double *weights,
    GT_size   *index,
    GT_size   N,
    ST_double statcode)
{
    if ( statcode == -2 ) {
        return (GtoolsStatsMeanIndexWeighted(source, weights, index, N));
    }
    else {
        return (GtoolsStatsQuantileIndexWeighted(source, weights, index, N));
    }
}

ST_double GtoolsStatsSumIndexWeighted (
    ST_double *source,
    ST_double *weights,
    GT_size   *index,
    GT_size   N)
{
    GT_size i;
    ST_double w;
    ST_double z = 0;
    for (i = 0; i < N; i++) {
        w  = weights[index[i]];
        z += source[index[i]] * w;
    }
    return (z);
}

ST_double GtoolsStatsMeanIndexWeighted (
    ST_double *source,
    ST_double *weights,
    GT_size   *index,
    GT_size   N)
{
    GT_size i;
    ST_double w;
    ST_double z = 0;
    ST_double W = 0;
    for (i = 0; i < N; i++) {
        w  = weights[index[i]];
        z += source[index[i]] * w;
        W += w;
    }
    return (z / W);
}

ST_double GtoolsStatsQuantileIndexWeighted (
    ST_double *source,
    ST_double *weights,
    GT_size   *index,
    GT_size   N)
{
    // not yet implemented
    return(0);
}

/**********************************************************************
 *                           Weighted stats                           *
 **********************************************************************/

ST_double GtoolsStatsDotWeighted (
    ST_double *v1,
    ST_double *v2,
    GT_size   N,
    ST_double *weights)
{
    GT_size i;
    ST_double *x = v1, *y = v2, ssxy = 0, *w = weights;
    for (i = 0; i < N; i++, x++, y++, w++) {
        ssxy += *w * *x * *y;
    }
    return (ssxy);
}

ST_double GtoolsStatsSSWeighted (
    ST_double *source,
    GT_size   N,
    ST_double *weights)
{
    GT_size i;
    ST_double *x = source, ssx = 0, *w = weights;
    for (i = 0; i < N; i++, x++, w++) {
        ssx += *w * *x * *x;
    }
    return (ssx);
}

ST_double GtoolsStatsMeanWeighted (
    ST_double *source,
    GT_size   N,
    ST_double *weights)
{
    GT_size i;
    ST_double *x = source, *w = weights, sum = 0, wsum = 0;
    for (i = 0; i < N; i++, x++, w++) {
        wsum += *w;
        sum  += *w * *x;
    }
    return (sum / wsum);
}

ST_double GtoolsStatsBiasedStdWeighted (
    ST_double *source,
    GT_size   N,
    ST_double *weights)
{
    return(sqrt(GtoolsStatsBiasedVarianceWeighted(source, N, weights)));
}

ST_double GtoolsStatsBiasedVarianceWeighted (
    ST_double *source,
    GT_size   N,
    ST_double *weights)
{
    GT_size i;
    ST_double *x = source, *w = weights, ssx = 0, sum = 0, wsum = 0;
    if ( N > 1 ) {
        for (i = 0; i < N; i++, x++, w++) {
            wsum += *w;
            sum  += *w * *x;
            ssx  += *w * *x * *x;
        }

        if ( wsum == 0 ) {
            return(0);
        }
        else {
            return ((ssx - sum * sum / wsum) / wsum);
        }
    }
    else {
        return (0);
    }
}

ST_double GtoolsStatsNormWeighted (
    ST_double *source,
    GT_size   N,
    ST_double *weights)
{
    GT_size i;
    ST_double *x = source, ssx = 0, *w = weights;
    for (i = 0; i < N; i++, x++, w++) {
        ssx += *w * *x * *x;
    }
    return (sqrt(ssx));
}
