// I had high hopes for this version but it ends up being slower
void RadixSortInternal(
    void     *array,
    uint64_t N,
    uint64_t groupLength,
    uint64_t bitLength,
    void     *acopy,
    int8_t   negtype,
    void     *convert,
    uint8_t  type,
    uint64_t es
);

void RadixSortInternal(
    void     *array,
    uint64_t N,
    uint64_t groupLength,
    uint64_t bitLength,
    void     *acopy,
    int8_t   negtype,
    void     *convert,
    uint8_t  type,
    uint64_t es)
{

    int64_t i, c, shift, index = 0;
    char *aptr, *copyptr;
    if ( es == 0 ) {
        es = type / 8;
    }

    uint64_t groups    = bitLength / groupLength;
    uint64_t ncount    = 1 << groupLength;
    uint64_t mask      = ncount - 1;
    uint64_t negatives = 0;
    uint64_t negoffset = 0;

    int64_t *count = calloc(ncount, sizeof *count);
    int64_t *pref  = calloc(ncount, sizeof *pref);

    for (c = (type == 0), shift = 0; c < groups; c++, shift += groupLength) {

        // reset count array
        memset(count, '\0', sizeof(count) * ncount);

        // counting elements of the c-th group
        aptr = (char *) array;
        if ( c == 0 ) {
            for (i = 0; i < N; i++, aptr+=es) {
                if ( type == 0  ) count[*(aptr + groups - c - 1) & mask]++;
                if ( type == 8  ) count[(*(int8_t  *)aptr >> shift) & mask]++;
                if ( type == 16 ) count[(*(int16_t *)aptr >> shift) & mask]++;
                if ( type == 32 ) count[(*(int32_t *)aptr >> shift) & mask]++;
                if ( type == 64 ) count[(*(int64_t *)aptr >> shift) & mask]++;

                // Count all negative values in first round
                if ( type == 8  && *(int8_t  *) aptr < 0 ) negatives++;
                if ( type == 16 && *(int16_t *) aptr < 0 ) negatives++;
                if ( type == 32 && *(int32_t *) aptr < 0 ) negatives++;
                if ( type == 64 && *(int64_t *) aptr < 0 ) negatives++;
            }
            negoffset = N - 1 + negatives;
        }
        else {
            for (i = 0; i < N; i++, aptr+=es) {
                if ( type == 0  ) count[*(aptr + groups - c - 1) & mask]++;
                if ( type == 8  ) count[(*(int8_t  *)aptr >> shift) & mask]++;
                if ( type == 16 ) count[(*(int16_t *)aptr >> shift) & mask]++;
                if ( type == 32 ) count[(*(int32_t *)aptr >> shift) & mask]++;
                if ( type == 64 ) count[(*(int64_t *)aptr >> shift) & mask]++;
            }
        }

        // compute prefixes (cum sum of counts)
        pref[0] = 0;
        for (i = 1; i < ncount; i++)
            pref[i] = pref[i - 1] + count[i - 1];

        if ( (c % 2) == 0 ) {
            aptr = (char *) array;
            copyptr = (char *) acopy;
        }
        else {
            aptr = (char *) acopy;
            copyptr = (char *) array;
        }

        // copy elements ordered by the cth group
        // (note: convert only with negtype == -1, -2 atm)
        if (c == (groups - 1) ) {
            for (i = 0; i < N; i++, aptr+=es){
                // Get the right index to sort the number in
                if ( type == 0  ) index = pref[*(aptr + groups - c - 1) & mask]++;
                if ( type == 8  ) index = negatives + pref[(*(int8_t  *) aptr >> shift) & mask]++;
                if ( type == 16 ) index = negatives + pref[(*(int16_t *) aptr >> shift) & mask]++;
                if ( type == 32 ) index = negatives + pref[(*(int32_t *) aptr >> shift) & mask]++;
                if ( type == 64 ) index = negatives + pref[(*(int64_t *) aptr >> shift) & mask]++;

                // In the last (most significant) group be sure to order
                // negative numbers first.
                if ( (negtype ==  1 || negtype ==  2) && type == 8  && *(int8_t  *) aptr < 0 ) index -= N;
                if ( (negtype ==  1 || negtype ==  2) && type == 16 && *(int16_t *) aptr < 0 ) index -= N;
                if ( (negtype ==  1 || negtype ==  2) && type == 32 && *(int32_t *) aptr < 0 ) index -= N;
                if ( (negtype ==  1 || negtype ==  2) && type == 64 && *(int64_t *) aptr < 0 ) index -= N;

                if ( (negtype == -1 || negtype == -2) && type == 8  && *(int8_t  *) aptr < 0 ) index = negoffset - index;
                if ( (negtype == -1 || negtype == -2) && type == 16 && *(int16_t *) aptr < 0 ) index = negoffset - index;
                if ( (negtype == -1 || negtype == -2) && type == 32 && *(int32_t *) aptr < 0 ) index = negoffset - index;
                if ( (negtype == -1 || negtype == -2) && type == 64 && *(int64_t *) aptr < 0 ) index = negoffset - index;

                if ( (negtype == -2 || negtype ==  2 || negtype == 3) ) index = N - index - 1;

                if ( convert != NULL && type == 32 ) *(((float  *)convert) + index) = *(float  *) aptr;
                if ( convert != NULL && type == 64 ) *(((double *)convert) + index) = *(double *) aptr;
                if ( convert == NULL ) memcpy(copyptr + es * index, aptr, es);
            }
        }
        else {
            for (i = 0; i < N; i++, aptr+=es) {
                if ( type == 0  ) index = pref[*(aptr + groups - c - 1) & mask]++;
                if ( type == 8  ) index = pref[(*(int8_t  *) aptr >> shift) & mask]++;
                if ( type == 16 ) index = pref[(*(int16_t *) aptr >> shift) & mask]++;
                if ( type == 32 ) index = pref[(*(int32_t *) aptr >> shift) & mask]++;
                if ( type == 64 ) index = pref[(*(int64_t *) aptr >> shift) & mask]++;

                memcpy(copyptr + es * index, aptr, es);
            }
        }
    }

    free(count);
    free(pref);
}

#define RadixSortInternalGeneric(                                                               \
    array,                                                                                      \
    N,                                                                                          \
    groupLength,                                                                                \
    bitLength,                                                                                  \
    acopy,                                                                                      \
    negtype,                                                                                    \
    convert)                                                                                    \
                                                                                                \
    int64_t i, c, shift, index = 0;                                                             \
    typeof (*array) (*aptr);                                                                    \
    typeof (*array) (*copyptr);                                                                 \
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
            copyptr = acopy;                                                                    \
        }                                                                                       \
        else {                                                                                  \
            aptr = acopy;                                                                       \
            copyptr = array;                                                                    \
        }                                                                                       \
                                                                                                \
        /* copy elements ordered by the cth group */                                            \
        if (c == (groups - 1) ) {                                                               \
            for (i = 0; i < N; i++, aptr++){                                                    \
                /* Get the right index to sort the number in */                                 \
                index = negatives + pref[(*aptr >> shift) & mask]++;                            \
                                                                                                \
                /* In the last (most significant) group be sure to order */                     \
                /* negative numbers first. */                                                   \
                if ( (negtype ==  1 || negtype ==  2) && *aptr < 0 ) index -= N;                \
                if ( (negtype == -1 || negtype == -2) && *aptr < 0 ) index = negoffset - index; \
                if ( (negtype == -2 || negtype ==  2) ) index = N - index - 1;                  \
                                                                                                \
                if ( convert == NULL ) copyptr[index] = *aptr;                                  \
                else memcpy(convert + index, (typeof(*convert) *) aptr, sizeof(*convert));      \
            }                                                                                   \
        }                                                                                       \
        else {                                                                                  \
            for (i = 0; i < N; i++, aptr++) {                                                   \
                index = pref[(*aptr >> shift) & mask]++;                                        \
                copyptr[index] = *aptr;                                                         \
            }                                                                                   \
        }                                                                                       \
    }                                                                                           \
                                                                                                \
    free(count);                                                                                \
    free(pref);
