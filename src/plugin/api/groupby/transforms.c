void GtoolsTransformScaleVector (
    ST_double *source,
    ST_double *target,
    GT_size   N,
    ST_double scale)
{
    GT_size i;
    if ( source == target ) {
        for (i = 0; i < N; i++)
            target[i] = source[i] * scale;
    }
    else {
        for (i = 0; i < N; i++)
            target[i] *= scale;
    }
}

void GtoolsTransformScaleMatrix (
    ST_double *source,
    ST_double *target,
    GT_size   K,
    GT_size   N,
    ST_double *scale)
{
    GT_size k;
    ST_double *src = source, *trg = target;
    for (k = 0; k < K; k++, src += N, trg += N) {
        GtoolsTransformScaleVector(src, trg, N, scale[k]);
    }
}
