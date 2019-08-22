void GtoolsTransformWeighted (
    ST_double *source,
    ST_double *weights,
    ST_double *target,
    GT_size   *index,
    GT_size   N,
    ST_double statcode)
{
    if ( statcode == -2 ) {
        GtoolsTransformDeMeanWeighted(source, weights, target, index, N);
    }
}

void GtoolsTransformDeMeanWeighted (
    ST_double *source,
    ST_double *weights,
    ST_double *target,
    GT_size   *index,
    GT_size   N)
{
    GT_size i;
    ST_double z = GtoolsStatsMeanWeighted(source, weights, index, N);
    for (i = 0; i < N; i++) {
        target[index[i]] = source[index[i]] - z;
    }
}
