/**********************************************************************
 *                             Unindexed                              *
 **********************************************************************/

ST_double GtoolsStatsDivide(ST_double a, ST_double b)
{
    if ( b > 0 ) {
        return(a / GTOOLS_PWMAX(b, GTOOLS_64BIT_EPSILON));
    }
    else {
        return(a / GTOOLS_PWMIN(b, -GTOOLS_64BIT_EPSILON));
    }
}

// NB: This shouldn't ever be called with N = 0, but just in case I
// return 0 so compiler doesn't yell at me.
ST_double GtoolsStatsSignedMin (
    ST_double *source,
    GT_size   N)
{
    if ( N < 1 ) return(0);
    GT_size i;
    ST_double min = *source, *x = source + 1;
    for (i = 1; i < N; i++, x++) {
        if ( fabs(min) > fabs(*x) ) min = *x;
    }
    return (min);
}

ST_double GtoolsStatsSignedMax (
    ST_double *source,
    GT_size   N)
{
    if ( N < 1 ) return(0);
    GT_size i;
    ST_double max = *source, *x = source + 1;
    for (i = 1; i < N; i++, x++) {
        if ( fabs(max) < fabs(*x) ) max = *x;
    }
    return (max);
}

ST_double GtoolsStatsAbsMin (
    ST_double *source,
    GT_size   N)
{
    if ( N < 1 ) return(0);
    GT_size i;
    ST_double min = *source, *x = source + 1;
    for (i = 1; i < N; i++, x++) {
        if ( min > fabs(*x) ) min = fabs(*x);
    }
    return (min);
}

ST_double GtoolsStatsAbsMax (
    ST_double *source,
    GT_size   N)
{
    if ( N < 1 ) return(0);
    GT_size i;
    ST_double max = *source, *x = source + 1;
    for (i = 1; i < N; i++, x++) {
        if ( max < fabs(*x) ) max = fabs(*x);
    }
    return (max);
}

ST_double GtoolsStatsMin (
    ST_double *source,
    GT_size   N)
{
    if ( N < 1 ) return(0);
    GT_size i;
    ST_double min = *source, *x = source + 1;
    for (i = 1; i < N; i++, x++) {
        if ( min > *x ) min = *x;
    }
    return (min);
}

ST_double GtoolsStatsMax (
    ST_double *source,
    GT_size   N)
{
    if ( N < 1 ) return(0);
    GT_size i;
    ST_double max = *source, *x = source + 1;
    for (i = 1; i < N; i++, x++) {
        if ( max < *x ) max = *x;
    }
    return (max);
}

/**********************************************************************
 *                          Weighted Switch                           *
 **********************************************************************/

ST_double GtoolsStatsDot (
    ST_double *v1,
    ST_double *v2,
    GT_size   N,
    ST_double *weights)
{
    return(weights == NULL? GtoolsStatsDotUnweighted(v1, v2, N): GtoolsStatsDotWeighted(v1, v2, N, weights));
}

ST_double GtoolsStatsSS (
    ST_double *source,
    GT_size   N,
    ST_double *weights)
{
    return(weights == NULL? GtoolsStatsSSUnweighted(source, N): GtoolsStatsSSWeighted(source, N, weights));
}

ST_double GtoolsStatsMean (
    ST_double *source,
    GT_size   N,
    ST_double *weights)
{
    return(weights == NULL? GtoolsStatsMeanUnweighted(source, N): GtoolsStatsMeanWeighted(source, N, weights));
}

ST_double GtoolsStatsBiasedStd (
    ST_double *source,
    GT_size   N,
    ST_double *weights)
{
    return(weights == NULL? GtoolsStatsBiasedStdUnweighted(source, N): GtoolsStatsBiasedStdWeighted(source, N, weights));
}

ST_double GtoolsStatsBiasedVariance (
    ST_double *source,
    GT_size   N,
    ST_double *weights)
{
    return(weights == NULL? GtoolsStatsBiasedStdUnweighted(source, N): GtoolsStatsBiasedStdWeighted(source, N, weights));
}

ST_double GtoolsStatsNorm (
    ST_double *source,
    GT_size   N,
    ST_double *weights)
{
    return(weights == NULL? GtoolsStatsNormUnweighted(source, N): GtoolsStatsNormWeighted(source, N, weights));
}
