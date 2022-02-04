// All of these are identical except in the integer type.
// NOTE: I wrote a generic one but it was 0.5x speed ):

void RadixSortInternal64(
    int64_t  *array,
    uint64_t N,
    uint64_t groupLength,
    uint64_t bitLength,
    int64_t  *acopy,
    int8_t   negtype,
    double   *convert);

void RadixSortInternal64(
    int64_t  *array,
    uint64_t N,
    uint64_t groupLength,
    uint64_t bitLength,
    int64_t  *acopy,
    int8_t   negtype,
    double   *convert)
{

    int64_t i, c, shift, index = 0;
    int64_t *aptr, *copyptr;

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
            copyptr = acopy;
        }
        else {
            aptr = acopy;
            copyptr = array;
        }

        // copy elements ordered by the cth group
        // (note: convert only with negtype == -1, -2 atm)
        if (c == (groups - 1) ) {
            for (i = 0; i < N; i++, aptr++){
                // Get the right index to sort the number in
                index = negatives + pref[(*aptr >> shift) & mask]++;

                // In the last (most significant) group be sure to order
                // negative numbers first.
                if ( (negtype ==  1 || negtype ==  2) && *aptr < 0 ) index -= N;
                if ( (negtype == -1 || negtype == -2) && *aptr < 0 ) index = negoffset - index;
                if ( (negtype == -2 || negtype ==  2) ) index = N - index - 1;

                if ( convert != NULL ) convert[index] = *(double *) aptr;
                if ( convert == NULL ) copyptr[index] = *aptr;
            }
        }
        else {
            for (i = 0; i < N; i++, aptr++) {
                index = pref[(*aptr >> shift) & mask]++;
                copyptr[index] = *aptr;
            }
        }
    }

    free(count);
    free(pref);
}

void RadixSortInternal32(
    int32_t  *array,
    uint64_t N,
    uint64_t groupLength,
    uint64_t bitLength,
    int32_t  *acopy,
    int8_t   negtype,
    float    *convert);

void RadixSortInternal32(
    int32_t  *array,
    uint64_t N,
    uint64_t groupLength,
    uint64_t bitLength,
    int32_t  *acopy,
    int8_t   negtype,
    float    *convert)
{

    int64_t i, c, shift, index = 0;
    int32_t *aptr, *copyptr;

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
            copyptr = acopy;
        }
        else {
            aptr = acopy;
            copyptr = array;
        }

        // copy elements ordered by the cth group
        // (note: convert only with negtype == -1, -2 atm)
        if (c == (groups - 1) ) {
            for (i = 0; i < N; i++, aptr++){
                // Get the right index to sort the number in
                index = negatives + pref[(*aptr >> shift) & mask]++;

                // In the last (most significant) group be sure to order
                // negative numbers first.
                if ( (negtype ==  1 || negtype ==  2) && *aptr < 0 ) index -= N;
                if ( (negtype == -1 || negtype == -2) && *aptr < 0 ) index = negoffset - index;
                if ( (negtype == -2 || negtype ==  2) ) index = N - index - 1;

                if ( convert != NULL ) convert[index] = *(float *) aptr;
                if ( convert == NULL ) copyptr[index] = *aptr;
            }
        }
        else {
            for (i = 0; i < N; i++, aptr++) {
                index = pref[(*aptr >> shift) & mask]++;
                copyptr[index] = *aptr;
            }
        }
    }

    free(count);
    free(pref);
}

void RadixSortInternal16(
    int16_t  *array,
    uint64_t N,
    uint64_t groupLength,
    uint64_t bitLength,
    int16_t  *acopy,
    int8_t   negtype);

void RadixSortInternal16(
    int16_t  *array,
    uint64_t N,
    uint64_t groupLength,
    uint64_t bitLength,
    int16_t  *acopy,
    int8_t   negtype)
{

    int64_t i, c, shift, index = 0;
    int16_t *aptr, *copyptr;

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
            copyptr = acopy;
        }
        else {
            aptr = acopy;
            copyptr = array;
        }

        // copy elements ordered by the cth group
        if (c == (groups - 1) ) {
            for (i = 0; i < N; i++, aptr++){
                // Get the right index to sort the number in
                index = negatives + pref[(*aptr >> shift) & mask]++;

                // In the last (most significant) group be sure to order
                // negative numbers first.
                if ( (negtype ==  1 || negtype ==  2) && *aptr < 0 ) index -= N;
                if ( (negtype == -1 || negtype == -2) && *aptr < 0 ) index = negoffset - index;
                if ( (negtype == -2 || negtype ==  2) ) index = N - index - 1;

                copyptr[index] = *aptr;
            }
        }
        else {
            for (i = 0; i < N; i++, aptr++) {
                index = pref[(*aptr >> shift) & mask]++;
                copyptr[index] = *aptr;
            }
        }
    }

    free(count);
    free(pref);
}

void RadixSortInternal8(
    int8_t  *array,
    uint64_t N,
    uint64_t groupLength,
    uint64_t bitLength,
    int8_t  *acopy,
    int8_t   negtype);

void RadixSortInternal8(
    int8_t  *array,
    uint64_t N,
    uint64_t groupLength,
    uint64_t bitLength,
    int8_t  *acopy,
    int8_t   negtype)
{

    int64_t i, c, shift, index = 0;
    int8_t *aptr, *copyptr;

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
            copyptr = acopy;
        }
        else {
            aptr = acopy;
            copyptr = array;
        }

        // copy elements ordered by the cth group
        if (c == (groups - 1) ) {
            for (i = 0; i < N; i++, aptr++){
                // Get the right index to sort the number in
                index = negatives + pref[(*aptr >> shift) & mask]++;

                // In the last (most significant) group be sure to order
                // negative numbers first.
                if ( (negtype ==  1 || negtype ==  2) && *aptr < 0 ) index -= N;
                if ( (negtype == -1 || negtype == -2) && *aptr < 0 ) index = negoffset - index;
                if ( (negtype == -2 || negtype ==  2) ) index = N - index - 1;

                copyptr[index] = *aptr;
            }
        }
        else {
            for (i = 0; i < N; i++, aptr++) {
                index = pref[(*aptr >> shift) & mask]++;
                copyptr[index] = *aptr;
            }
        }
    }

    free(count);
    free(pref);
}

void RadixSortInternalCh(
    char *array,
    uint64_t N,
    uint64_t groupLength,
    uint64_t bitLength,
    char *acopy,
    uint64_t bytes);

void RadixSortInternalCh(
    char *array,
    uint64_t N,
    uint64_t groupLength,
    uint64_t bitLength,
    char *acopy,
    uint64_t bytes)
{

    uint64_t i, c, index, mod2;
    char *aptr, *copyptr;

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
            copyptr = acopy;
        }
        else {
            aptr = acopy;
            copyptr = array;
        }

        // Get the right index to sort the number in
        for (i = 0; i < N; i++, aptr+=bytes){
            index = pref[*(aptr + c) & mask]++;
            memcpy(copyptr + bytes * index, aptr, bytes * sizeof(char));
        }
    }

    free(count);
    free(pref);
}
