void GtoolsHashInit (
    struct GtoolsHash *GtoolsHashInfo,
    void *x,
    GT_size nobs,
    GT_size kvars,
    GT_int  *types,
    GT_bool *invert)
{
    GT_size k;

    GtoolsHashInfo->allocSizes     = 0;
    GtoolsHashInfo->allocPositions = 0;
    GtoolsHashInfo->allocIndex     = 0;
    GtoolsHashInfo->allocIndexj    = 0;
    GtoolsHashInfo->allocNj        = 0;
    GtoolsHashInfo->allocInfo      = 0;
    GtoolsHashInfo->allocHash1     = 0;
    GtoolsHashInfo->allocHash2     = 0;
    GtoolsHashInfo->allocHash3     = 0;

    GtoolsHashInfo->offset    = 0;
    GtoolsHashInfo->x         = x;
    GtoolsHashInfo->nobs      = nobs;
    GtoolsHashInfo->_nobsinit = nobs;
    GtoolsHashInfo->kvars     = kvars;
    GtoolsHashInfo->types     = types;
    GtoolsHashInfo->invert    = invert;
    GtoolsHashInfo->radixOK   = 0;
    GtoolsHashInfo->bijectOK  = 0;

    // Misc
    GtoolsHashInfo->hdfeBufferAlloc     = 0;
    GtoolsHashInfo->hdfeMeanBufferAlloc = 0;
    GtoolsHashInfo->hdfeFallback        = 0;
    GtoolsHashInfo->hdfeMaxIter         = 0;
    GtoolsHashInfo->hdfeIter            = 0;
    GtoolsHashInfo->hdfeTraceIter       = 0;
    GtoolsHashInfo->hdfeFeval           = 0;
    GtoolsHashInfo->hdfeRc              = 0;
    GtoolsHashInfo->hdfeStandardize     = 0;

    GtoolsHashInfo->sizes = calloc(kvars, sizeof *GtoolsHashInfo->sizes);
    // if ( GtoolsHashInfo->sizes == NULL ) return (17902);

    for (k = 0; k < kvars; k++) {
        GtoolsHashInfo->sizes[k] = types[k] > 0? types[k]: 0;
    }
}

void GtoolsHashFree (struct GtoolsHash *GtoolsHashInfo)
{
    if ( GtoolsHashInfo->allocSizes ) {
        free (GtoolsHashInfo->sizes);
    }

    if ( GtoolsHashInfo->allocPositions ) {
        free (GtoolsHashInfo->positions);
    }

    if ( GtoolsHashInfo->allocIndex ) {
        free (GtoolsHashInfo->index);
    }

    if ( GtoolsHashInfo->allocIndexj ) {
        free (GtoolsHashInfo->indexj);
    }

    if ( GtoolsHashInfo->allocNj ) {
        free (GtoolsHashInfo->nj);
    }

    if ( GtoolsHashInfo->allocInfo ) {
        free (GtoolsHashInfo->info);
    }

    if ( GtoolsHashInfo->allocHash1 ) {
        free (GtoolsHashInfo->hash1);
    }

    if ( GtoolsHashInfo->allocHash2 ) {
        free (GtoolsHashInfo->hash2);
    }

    if ( GtoolsHashInfo->allocHash3 ) {
        free (GtoolsHashInfo->hash3);
    }

    if ( GtoolsHashInfo->hdfeBufferAlloc ) {
        free (GtoolsHashInfo->hdfeBuffer);
    }

    if ( GtoolsHashInfo->hdfeMeanBufferAlloc ) {
        free (GtoolsHashInfo->hdfeMeanBuffer);
    }

    GtoolsHashInfo->x      = NULL;
    GtoolsHashInfo->types  = NULL;
    GtoolsHashInfo->invert = NULL;
}

void GtoolsHashFreePartial (struct GtoolsHash *GtoolsHashInfo)
{
    if ( GtoolsHashInfo->allocIndex ) {
        free (GtoolsHashInfo->index);
        GtoolsHashInfo->allocIndex = 0;
    }

    if ( GtoolsHashInfo->allocInfo ) {
        free (GtoolsHashInfo->info);
        GtoolsHashInfo->allocInfo = 0;
    }

    if ( GtoolsHashInfo->allocHash3 ) {
        free (GtoolsHashInfo->hash3);
        GtoolsHashInfo->allocHash3 = 0;
    }

    if ( GtoolsHashInfo->allocIndexj ) {
        free (GtoolsHashInfo->indexj);
        GtoolsHashInfo->allocIndexj = 0;
    }

    if ( GtoolsHashInfo->allocNj ) {
        free (GtoolsHashInfo->nj);
        GtoolsHashInfo->allocNj = 0;
    }
}

void GtoolsHashCheckNumeric (struct GtoolsHash *GtoolsHashInfo)
{
    GT_size k;
    GtoolsHashInfo->allNumeric = 1;
    for (k = 0; k < GtoolsHashInfo->kvars; k++) {
        GtoolsHashInfo->allNumeric = GtoolsHashInfo->allNumeric && (GtoolsHashInfo->types[k] <= 0);
    }
}

void GtoolsHashCheckInteger (struct GtoolsHash *GtoolsHashInfo)
{
    GT_size k;
    GtoolsHashInfo->allInteger = 1;
    for (k = 0; k < GtoolsHashInfo->kvars; k++) {
        GtoolsHashInfo->allInteger = GtoolsHashInfo->allInteger && (GtoolsHashInfo->types[k] < 0);
    }
}

void GtoolsHashCheckSorted (struct GtoolsHash *GtoolsHashInfo)
{
    GT_size k;
    GT_int vlen;

    if ( GtoolsHashInfo->allNumeric ) {
        GtoolsHashInfo->sorted = MultiSortCheckDbl(
            (ST_double *) GtoolsHashInfo->x,
            GtoolsHashInfo->nobs,
            0,
            GtoolsHashInfo->kvars - 1,
            GtoolsHashInfo->kvars * sizeof(ST_double),
            (GT_size *) GtoolsHashInfo->invert
        );
        GtoolsHashInfo->rowbytes = sizeof(ST_double) * GtoolsHashInfo->kvars;
    }
    else {
        GtoolsHashInfo->positions[0] = GtoolsHashInfo->rowbytes = 0;
        for (k = 1; k < GtoolsHashInfo->kvars + 1; k++) {
            vlen = GtoolsHashInfo->sizes[k - 1] * sizeof(char);
            if ( vlen > 0 ) {
                GtoolsHashInfo->positions[k] = GtoolsHashInfo->positions[k - 1] + (vlen + sizeof(char));
                GtoolsHashInfo->rowbytes += (vlen + sizeof(char));
            }
            else {
                GtoolsHashInfo->positions[k] = GtoolsHashInfo->positions[k - 1] + sizeof(ST_double);
                GtoolsHashInfo->rowbytes += sizeof(ST_double);
            }
        }

        GtoolsHashInfo->sorted = MultiSortCheckMC (
            (char *) GtoolsHashInfo->x,
            GtoolsHashInfo->nobs,
            0,
            GtoolsHashInfo->kvars - 1,
            GtoolsHashInfo->rowbytes,
            GtoolsHashInfo->sizes,
            (GT_size *) GtoolsHashInfo->invert,
            GtoolsHashInfo->positions
        );
    }
}

GT_bool GtoolsHashCheckEqual(uint64_t *hash, GT_size N)
{
    uint64_t hfirst = *hash, *hptr;
    for (hptr = hash + 1; hptr < hash + N; hptr++) {
        if ( *hptr != hfirst ) return (0);
    }

    return (1);
}

GT_bool GtoolsHashCheckCollisions (struct GtoolsHash *GtoolsHashInfo)
{
    GT_size i, j, start, end;
    void *base, *cmp;

    for (j = 0; j < GtoolsHashInfo->nlevels; j++) {
        start = i = GtoolsHashInfo->info[j];
        end   = GtoolsHashInfo->info[j + 1];
        base  = GtoolsHashInfo->xptr + GtoolsHashInfo->index[i] * GtoolsHashInfo->rowbytes;
        for (i = start + 1; i < end; i++) {
            cmp = GtoolsHashInfo->xptr + GtoolsHashInfo->index[i] * GtoolsHashInfo->rowbytes;
            if ( memcmp(base, cmp, GtoolsHashInfo->rowbytes) )
                return (1);
        }
    }

    return (0);
}
