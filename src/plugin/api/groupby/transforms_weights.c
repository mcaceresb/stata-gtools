void GtoolsTransformIndexWeighted (
    ST_double *source,
    ST_double *weights,
    ST_double *target,
    GT_size   *index,
    GT_size   N,
    ST_double statcode)
{
    if ( statcode == -2 ) {
        GtoolsTransformDeMeanIndexWeighted(source, weights, target, index, N);
    }
}

void GtoolsTransformDeMeanIndexWeighted (
    ST_double *source,
    ST_double *weights,
    ST_double *target,
    GT_size   *index,
    GT_size   N)
{
    GT_size i;
    ST_double z = GtoolsStatsMeanIndexWeighted(source, weights, index, N);
    for (i = 0; i < N; i++) {
        target[index[i]] = source[index[i]] - z;
    }
}

/**********************************************************************
 *                              Weighted                              *
 **********************************************************************/

void GtoolsTransformBiasedStandardizeVector (
    ST_double *source,
    ST_double *target,
    ST_double *weights,
    GT_size   N,
    ST_double *sd)
{
    GT_size i;
    ST_double z = GtoolsStatsBiasedStd(source, N, weights);
    if ( source == target ) {
        for (i = 0; i < N; i++)
            if ( z != 0 ) target[i] = source[i] / z;
    }
    else {
        for (i = 0; i < N; i++)
            if ( z != 0 ) target[i] /= z;
    }
    if ( sd != NULL ) *sd = z;
}

void GtoolsTransformBiasedStandardizeMatrix (
    ST_double *source,
    ST_double *target,
    ST_double *weights,
    GT_size   K,
    GT_size   N,
    ST_double *sd)
{
    GT_size k;
    ST_double *src = source, *trg = target;
    for (k = 0; k < K; k++, src += N, trg += N) {
        GtoolsTransformBiasedStandardizeVector(src, trg, weights, N, sd == NULL? NULL: sd + k);
    }
}
