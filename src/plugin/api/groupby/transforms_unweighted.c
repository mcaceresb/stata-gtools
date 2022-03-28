void GtoolsTransformIndex (
    ST_double *source,
    ST_double *target,
    GT_size   *index,
    GT_size   N,
    ST_double statcode)
{
    if ( statcode == -2 ) {
        GtoolsTransformDeMean(source, target, index, N);
    }
}

void GtoolsTransformDeMeanIndex (
    ST_double *source,
    ST_double *target,
    GT_size   *index,
    GT_size   N)
{
    GT_size i;
    ST_double z = GtoolsStatsMean(source, index, N);
    for (i = 0; i < N; i++) {
        target[index[i]] = source[index[i]] - z;
    }
}
