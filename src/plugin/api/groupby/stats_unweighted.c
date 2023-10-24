ST_double GtoolsStatsIndex (
    ST_double *source,
    GT_size   *index,
    GT_size   N,
    ST_double statcode)
{
    if ( statcode == -2 ) {
        return (GtoolsStatsMeanIndex(source, index, N));
    }
    else {
        return (GtoolsStatsQuantileIndex(source, index, N));
    }
}

ST_double GtoolsStatsSumIndex (
    ST_double *source,
    GT_size   *index,
    GT_size   N)
{
    GT_size i;
    ST_double z = 0;
    for (i = 0; i < N; i++) {
        z += source[index[i]];
    }
    return (z);
}

ST_double GtoolsStatsMeanIndex (
    ST_double *source,
    GT_size   *index,
    GT_size   N)
{
    GT_size i;
    ST_double z = 0;
    for (i = 0; i < N; i++) {
        z += source[index[i]];
    }
    return (z / N);
}

ST_double GtoolsStatsQuantileIndex (
    ST_double *source,
    GT_size   *index,
    GT_size   N)
{
    // not yet implemented
    return(0);
}

/**********************************************************************
 *                          Unweighted stats                          *
 **********************************************************************/

ST_double GtoolsStatsDotUnweighted (
    ST_double *v1,
    ST_double *v2,
    GT_size   N)
{
    GT_size i;
    ST_double *x = v1, *y = v2, ssxy = 0;
    for (i = 0; i < N; i++, x++, y++) {
        ssxy += *x * *y;
    }
    return (ssxy);
}

ST_double GtoolsStatsSSUnweighted (
    ST_double *source,
    GT_size   N)
{
    GT_size i;
    ST_double *x = source, ssx = 0;
    for (i = 0; i < N; i++, x++) {
        ssx += *x * *x;
    }
    return (ssx);
}

ST_double GtoolsStatsSSDUnweighted (
    ST_double *source,
    GT_size   N)
{
    GT_size i;
    ST_double *x = source, ssx = 0, sum = 0;
    for (i = 0; i < N; i++, x++) {
        sum += *x;
        ssx += *x * *x;
    }
    return ((ssx - sum * sum / N));
}

ST_double GtoolsStatsSumUnweighted (
    ST_double *source,
    GT_size   N)
{
    GT_size i;
    ST_double *x = source, sum = 0;
    for (i = 0; i < N; i++, x++) {
        sum += *x;
    }
    return (sum);
}

ST_double GtoolsStatsMeanUnweighted (
    ST_double *source,
    GT_size   N)
{
    return (GtoolsStatsSumUnweighted(source, N) / N);
}

ST_double GtoolsStatsBiasedStdUnweighted (
    ST_double *source,
    GT_size   N)
{
    return (sqrt(GtoolsStatsBiasedVarianceUnweighted(source, N)));
}

ST_double GtoolsStatsBiasedVarianceUnweighted (
    ST_double *source,
    GT_size   N)
{
    if ( N > 1 ) {
        return (GtoolsStatsSSDUnweighted(source, N) / N);
    }
    else {
        return (0);
    }
}

ST_double GtoolsStatsStdUnweighted (
    ST_double *source,
    GT_size   N)
{
    return (sqrt(GtoolsStatsVarianceUnweighted(source, N)));
}

ST_double GtoolsStatsVarianceUnweighted (
    ST_double *source,
    GT_size   N)
{
    if ( N > 1 ) {
        return (GtoolsStatsSSDUnweighted(source, N) / (N - 1));
    }
    else {
        return (0);
    }
}

ST_double GtoolsStatsNormUnweighted (
    ST_double *source,
    GT_size   N)
{
    return (sqrt(GtoolsStatsSSUnweighted(source, N)));
}
