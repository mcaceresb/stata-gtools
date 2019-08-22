ST_double GtoolsStats (
    ST_double *source,
    GT_size   *index,
    GT_size   N,
    ST_double statcode)
{
    if ( statcode == -2 ) {
        return (GtoolsStatsMean(source, index, N));
    }
    else {
        return (GtoolsStatsQuantile(source, index, N));
    }
}

ST_double GtoolsStatsMean (
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

ST_double GtoolsStatsQuantile (
    ST_double *source,
    GT_size   *index,
    GT_size   N)
{
    // not yet implemented
    return(0);
}
