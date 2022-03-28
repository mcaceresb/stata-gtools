GT_int GtoolsRadixPanel       (struct GtoolsHash *GtoolsHashInfo);
GT_int GtoolsRadixPanelDouble (struct GtoolsHash *GtoolsHashInfo);
GT_int GtoolsRadixPanelString (struct GtoolsHash *GtoolsHashInfo);
GT_int GtoolsRadixSort        (struct GtoolsHash *GtoolsHashInfo);
GT_int GtoolsRadixSortDouble  (ST_double *array, GT_size *index, GT_size N);
GT_int GtoolsRadixSortString  (char      *array, GT_size *index, GT_size N, GT_size bytes);
GT_int GtoolsRadixSortSize    (GT_size   *array, GT_size *index, GT_size N, GT_size _groupLength);

// xx gotta debug string

void RadixSortIndex64(
    int64_t  *array,
    uint64_t *index,
    uint64_t N,
    uint64_t groupLength,
    uint64_t bitLength,
    int64_t  *acopy,
    uint64_t *ixcopy,
    int8_t   negtype,
    double   *convert);

void RadixSortIndexCh(
    char *array,
    uint64_t *index,
    uint64_t N,
    uint64_t groupLength,
    uint64_t bitLength,
    char *acopy,
    uint64_t *ixcopy,
    uint64_t bytes);

#define RadixSortIndexGeneric(                                                                  \
    array,                                                                                      \
    index,                                                                                      \
    N,                                                                                          \
    groupLength,                                                                                \
    bitLength,                                                                                  \
    acopy,                                                                                      \
    ixcopy,                                                                                     \
    negtype,                                                                                    \
    convert)                                                                                    \
                                                                                                \
    int64_t i, c, shift, ix = 0;                                                                \
    typeof (*array) (*aptr);                                                                    \
    typeof (*array) (*copyptr);                                                                 \
    typeof (*index) (*ixptr);                                                                   \
    typeof (*index) (*ixcopyptr);                                                               \
                                                                                                \
    uint64_t groups    = bitLength / groupLength;                                               \
    uint64_t ncount    = 1 << groupLength;                                                      \
    uint64_t mask      = ncount - 1;                                                            \
    uint64_t negatives = 0;                                                                     \
    uint64_t negoffset = 0;                                                                     \
                                                                                                \
    int64_t *count = calloc(ncount, sizeof *count);                                             \
    int64_t *pref  = calloc(ncount, sizeof *pref);                                              \
                                                                                                \
    for (c = 0, shift = 0; c < groups; c++, shift += groupLength) {                             \
                                                                                                \
        /* reset count array */                                                                 \
        memset(count, '\0', sizeof(count) * ncount);                                            \
                                                                                                \
        /* counting elements of the c-th group */                                               \
        aptr = array;                                                                           \
        if ( c == 0 ) {                                                                         \
            for (i = 0; i < N; i++, aptr++) {                                                   \
                count[(*aptr >> shift) & mask]++;                                               \
                                                                                                \
                /* Count all negative values in first round */                                  \
                if ( *aptr < 0 ) negatives++;                                                   \
            }                                                                                   \
            negoffset = N - 1 + negatives;                                                      \
        }                                                                                       \
        else {                                                                                  \
            for (i = 0; i < N; i++, aptr++) {                                                   \
                count[(*aptr >> shift) & mask]++;                                               \
            }                                                                                   \
        }                                                                                       \
                                                                                                \
        /* compute prefixes (cum sum of counts) */                                              \
        pref[0] = 0;                                                                            \
        for (i = 1; i < ncount; i++)                                                            \
            pref[i] = pref[i - 1] + count[i - 1];                                               \
                                                                                                \
        if ( (c % 2) == 0 ) {                                                                   \
            aptr = array;                                                                       \
            ixptr = index;                                                                      \
            copyptr = acopy;                                                                    \
            ixcopyptr = ixcopy;                                                                 \
        }                                                                                       \
        else {                                                                                  \
            aptr = acopy;                                                                       \
            ixptr = ixcopy;                                                                     \
            copyptr = array;                                                                    \
            ixcopyptr = index;                                                                  \
        }                                                                                       \
                                                                                                \
        /* copy elements ordered by the cth group */                                            \
        if (c == (groups - 1) ) {                                                               \
            for (i = 0; i < N; i++, aptr++, ixptr++) {                                          \
                /* Get the right index to sort the number in */                                 \
                ix = negatives + pref[(*aptr >> shift) & mask]++;                               \
                                                                                                \
                /* In the last (most significant) group be sure to order */                     \
                /* negative numbers first. */                                                   \
                if ( (negtype ==  1 || negtype ==  2) && *aptr < 0 ) ix -= N;                   \
                if ( (negtype == -1 || negtype == -2) && *aptr < 0 ) ix = negoffset - ix;       \
                if ( (negtype == -2 || negtype ==  2) ) ix = N - ix - 1;                        \
                                                                                                \
                if ( convert == NULL ) copyptr[ix] = *aptr;                                     \
                else memcpy(convert + ix, (typeof(*convert) *) aptr, sizeof(*convert));         \
                                                                                                \
                ixcopyptr[ix] = *ixptr;                                                         \
            }                                                                                   \
        }                                                                                       \
        else {                                                                                  \
            for (i = 0; i < N; i++, aptr++, ixptr++) {                                          \
                ix = pref[(*aptr >> shift) & mask]++;                                           \
                copyptr[ix] = *aptr;                                                            \
                ixcopyptr[ix] = *ixptr;                                                         \
            }                                                                                   \
        }                                                                                       \
    }                                                                                           \
                                                                                                \
    free(count);                                                                                \
    free(pref);

GT_int GtoolsRadixPanel (struct GtoolsHash *GtoolsHashInfo)
{
    if ( GtoolsHashInfo->allNumeric ) {
         return (GtoolsRadixPanelDouble(GtoolsHashInfo));
    }
    else {
         return (GtoolsRadixPanelString(GtoolsHashInfo));
    }
}

GT_int GtoolsRadixPanelDouble (struct GtoolsHash *GtoolsHashInfo)
{
    GT_size i = 1;
    GT_size l = 0;
    ST_double *x = (ST_double *) GtoolsHashInfo->xptr;
    ST_double *xptr = x + 1;
    ST_double el = *x;

    GT_size *info_largest = calloc(GtoolsHashInfo->nobs + 1, sizeof *info_largest);
    if ( info_largest == NULL ) return (17902);

    info_largest[l++] = 0;
    if ( GtoolsHashInfo->nobs > 1 ) {
        do {
            if ( *xptr != el ) {
                info_largest[l++] = i;
                el  = *xptr;
            }
            i++; xptr++;
        } while( i < GtoolsHashInfo->nobs );
    }
    info_largest[l] = GtoolsHashInfo->nobs;
    GtoolsHashInfo->nlevels = l;

    GtoolsHashInfo->info = calloc(l + 1, sizeof GtoolsHashInfo->info);
    if ( GtoolsHashInfo->info == NULL ) return (17902);
    GtoolsHashInfo->allocInfo = 1;

    for (i = 0; i < l + 1; i++)
        GtoolsHashInfo->info[i] = info_largest[i];

    free (info_largest);
    return (0);
}

GT_int GtoolsRadixPanelString (struct GtoolsHash *GtoolsHashInfo)
{
    GT_size i = 1;
    GT_size l = 0;
    char el[GtoolsHashInfo->rowbytes];
    char *x  = (char *) GtoolsHashInfo->xptr;
    char *xptr = x + GtoolsHashInfo->rowbytes;
    memcpy(el, x, GtoolsHashInfo->rowbytes * sizeof(char));

    GT_size *info_largest = calloc(GtoolsHashInfo->nobs + 1, sizeof *info_largest);
    if ( info_largest == NULL ) return (17902);

    info_largest[l++] = 0;
    if ( GtoolsHashInfo->nobs > 1 ) {
        do {
            if ( strncmp(xptr, el, GtoolsHashInfo->rowbytes) ) {
                info_largest[l++] = i;
                memcpy(el, xptr, GtoolsHashInfo->rowbytes * sizeof(char));
            }
            i++; xptr += GtoolsHashInfo->rowbytes;
        } while( i < GtoolsHashInfo->nobs );
    }
    info_largest[l] = GtoolsHashInfo->nobs;
    GtoolsHashInfo->nlevels = l;

    GtoolsHashInfo->info = calloc(l + 1, sizeof GtoolsHashInfo->info);
    if ( GtoolsHashInfo->info == NULL ) return (17902);
    GtoolsHashInfo->allocInfo = 1;

    for (i = 0; i < l + 1; i++)
        GtoolsHashInfo->info[i] = info_largest[i];

    free (info_largest);
    return (0);
}

GT_int GtoolsRadixSort (struct GtoolsHash *GtoolsHashInfo)
{
    if ( GtoolsHashInfo->allNumeric ) {
         return(GtoolsRadixSortDouble((ST_double *) GtoolsHashInfo->xptr, GtoolsHashInfo->index, GtoolsHashInfo->nobs));
    }
    else {
         return(GtoolsRadixSortString((char *) GtoolsHashInfo->x, GtoolsHashInfo->index, GtoolsHashInfo->nobs, GtoolsHashInfo->rowbytes));
    }
}

GT_int GtoolsRadixSortDouble (ST_double *array, GT_size *index, GT_size N)
{
    GT_size _i;
    ST_double *_aptr  = array;
    GT_int    *acast  = calloc(N, sizeof *acast);
    GT_int    *acopy  = calloc(N, sizeof *acopy);
    GT_size   *ixcopy = calloc(N, sizeof *ixcopy);

    if ( acast  == NULL ) return (17902);
    if ( acopy  == NULL ) return (17902);
    if ( ixcopy == NULL ) return (17902);

    for (_i = 0; _i < N; _i++, _aptr++) {
        acast[_i] = *(GT_int *) _aptr;
    }

    // RadixSortIndex64(acast, index, N, 8, 64, acopy, ixcopy, -1, array);
    RadixSortIndexGeneric(acast, index, N, 8, 64, acopy, ixcopy, -1, array);

    free(acast);
    free(acopy);
    free(ixcopy);

    return(0);
}

// Assume last byte is null (i.e. null-terminated)
GT_int GtoolsRadixSortString(char *array, GT_size *index, GT_size N, GT_size bytes) 
{
    GT_size bitLength = bytes * 8 * sizeof(char);
    GT_size groupLength = 8 * sizeof(char);
    char    *acopy  = calloc(N, bytes * sizeof(char));
    GT_size *ixcopy = calloc(N, sizeof *ixcopy);

    if ( acopy  == NULL ) return (17902);
    if ( ixcopy == NULL ) return (17902);

    RadixSortIndexCh(array, index, N, groupLength, bitLength, acopy, ixcopy, bytes);
    if ( ((bitLength / groupLength) - 1) % 2 ) {
        memcpy(array, acopy,  N * bytes * sizeof(char));
        memcpy(index, ixcopy, N * sizeof(GT_size));
    }

    free(acopy);
    free(ixcopy);

    return(0);
}

GT_int GtoolsRadixSortSize(GT_size *array, GT_size *index, GT_size N, GT_size _groupLength)
{
    GT_size _i, flip = 0; GT_size range;
    if ( N <= 1 ) {
        return(0);
    }
    else if ( _groupLength == 0 ) {
        GTOOLS_MINMAX(array, N, min, max, _i)
        _groupLength = 8;
        range = max - min + 1;
    }
    else range = 0;

    GT_size *acopy  = calloc(N, sizeof *acopy);
    GT_size *ixcopy = calloc(N, sizeof *ixcopy);

    if ( acopy  == NULL ) return (17902);
    if ( ixcopy == NULL ) return (17902);

    if ( (range > 0) && (range < ((GT_size) pow(2, 8))) ) {
        RadixSortIndexGeneric(array, index, N, _groupLength, 8, acopy, ixcopy, 0, NULL);
        flip = (8 / _groupLength) % 2;
    }
    else if ( (range > 0) && (range < ((GT_size) pow(2, 16))) ) {
        RadixSortIndexGeneric(array, index, N, _groupLength, 16, acopy, ixcopy, 0, NULL);
        flip = (16 / _groupLength) % 2;
    }
    else if ( (range > 0) && (range < ((GT_size) pow(2, 32))) ) {
        RadixSortIndexGeneric(array, index, N, _groupLength, 32, acopy, ixcopy, 0, NULL);
        flip = (32 / _groupLength) % 2;
    }
    else {
        RadixSortIndexGeneric(array, index, N, _groupLength, 64, acopy, ixcopy, 0, NULL);
        flip = (64 / _groupLength) % 2;
    }

    if ( flip ) {
        memcpy(array, acopy,  N * sizeof(GT_size));
        memcpy(index, ixcopy, N * sizeof(GT_size));
    }

    free(acopy);
    free(ixcopy);

    return(0);
}

void RadixSortIndex64(
    int64_t  *array,
    uint64_t *index,
    uint64_t N,
    uint64_t groupLength,
    uint64_t bitLength,
    int64_t  *acopy,
    uint64_t *ixcopy,
    int8_t   negtype,
    double   *convert)
{

    int64_t i, c, shift, ix = 0;
    int64_t *aptr, *copyptr; 
    uint64_t *ixptr, *ixcopyptr;

    uint64_t groups    = bitLength / groupLength;
    uint64_t ncount    = 1 << groupLength;
    uint64_t mask      = ncount - 1;
    uint64_t negatives = 0;
    uint64_t negoffset = 0;

    int64_t *count = calloc(ncount, sizeof *count);
    int64_t *pref  = calloc(ncount, sizeof *pref);

    for (c = 0, shift = 0; c < groups; c++, shift += groupLength) {

        // reset count array
        memset(count, '\0', sizeof(count) * ncount);

        // counting elements of the c-th group
        aptr = array;
        if ( c == 0 ) {
            for (i = 0; i < N; i++, aptr++) {
                count[(*aptr >> shift) & mask]++;

                // Count all negative values in first round
                if ( *aptr < 0 ) negatives++;
            }
            negoffset = N - 1 + negatives;
        }
        else {
            for (i = 0; i < N; i++, aptr++) {
                count[(*aptr >> shift) & mask]++;
            }
        }

        // compute prefixes (cum sum of counts)
        pref[0] = 0;
        for (i = 1; i < ncount; i++)
            pref[i] = pref[i - 1] + count[i - 1];

        if ( (c % 2) == 0 ) {
            aptr = array;
            ixptr = index;
            copyptr = acopy;
            ixcopyptr = ixcopy;
        }
        else {
            aptr = acopy;
            ixptr = ixcopy;
            copyptr = array;
            ixcopyptr = index;
        }

        // copy elements ordered by the cth group
        // (note: convert only with negtype == -1, -2 atm)
        if (c == (groups - 1) ) {
            for (i = 0; i < N; i++, aptr++, ixptr++) {
                // Get the right index to sort the number in
                ix = negatives + pref[(*aptr >> shift) & mask]++;

                // In the last (most significant) group be sure to order
                // negative numbers first.
                if ( (negtype ==  1 || negtype ==  2) && *aptr < 0 ) ix -= N;
                if ( (negtype == -1 || negtype == -2) && *aptr < 0 ) ix = negoffset - ix;
                if ( (negtype == -2 || negtype ==  2) ) ix = N - ix - 1;

                if ( convert != NULL ) convert[ix] = *(double *) aptr;
                if ( convert == NULL ) copyptr[ix] = *aptr;

                ixcopyptr[ix] = *ixptr;
            }
        }
        else {
            for (i = 0; i < N; i++, aptr++, ixptr++) {
                ix = pref[(*aptr >> shift) & mask]++;
                copyptr[ix]   = *aptr;
                ixcopyptr[ix] = *ixptr;
            }
        }
    }

    free(count);
    free(pref);
}

void RadixSortIndexCh(
    char *array,
    uint64_t *index,
    uint64_t N,
    uint64_t groupLength,
    uint64_t bitLength,
    char *acopy,
    uint64_t *ixcopy,
    uint64_t bytes)
{

    uint64_t i, c, ix, mod2;
    char *aptr, *copyptr;
    uint64_t *ixptr, *ixcopyptr;

    uint64_t groups = bitLength / groupLength;
    uint64_t ncount = 1 << groupLength;
    uint64_t mask   = ncount - 1;
    uint64_t *count = calloc(ncount, sizeof *count);
    uint64_t *pref  = calloc(ncount, sizeof *pref);

    c = groups - 1; mod2 = c? (groups - 2) % 2: 0;
    while (c > 0) {
        c--;

        // reset count array
        memset(count, '\0', sizeof(count) * ncount);

        // counting elements of the c-th group
        for (aptr = array; aptr < array + N * bytes; aptr+=bytes) {
            count[*(aptr + c) & mask]++;
        }

        // compute prefixes (cum sum of counts)
        pref[0] = 0;
        for (i = 1; i < ncount; i++)
            pref[i] = pref[i - 1] + count[i - 1];

        if ( (c % 2) == mod2 ) {
            aptr = array;
            ixptr = index;
            copyptr = acopy;
            ixcopyptr = ixcopy;
        }
        else {
            aptr = acopy;
            ixptr = ixcopy;
            copyptr = array;
            ixcopyptr = index;
        }

        // Get the right index to sort the number in
        for (i = 0; i < N; i++, aptr+=bytes, ixptr++) {
            ix = pref[*(aptr + c) & mask]++;
            memcpy(copyptr + bytes * ix, aptr, bytes * sizeof(char));
            ixcopyptr[ix] = *ixptr;
        }
    }

    free(count);
    free(pref);
}
