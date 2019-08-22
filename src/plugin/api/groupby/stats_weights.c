ST_double GtoolsStatsWeighted (
    ST_double *source,
    ST_double *weights,
    GT_size   *index,
    GT_size   N,
    ST_double statcode)
{
    if ( statcode == -2 ) {
        return (GtoolsStatsMeanWeighted(source, weights, index, N));
    }
    else {
        return (GtoolsStatsQuantileWeighted(source, weights, index, N));
    }
}

ST_double GtoolsStatsMeanWeighted (
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

ST_double GtoolsStatsQuantileWeighted (
    ST_double *source,
    ST_double *weights,
    GT_size   *index,
    GT_size   N)
{
    // not yet implemented
    return(0);
}
