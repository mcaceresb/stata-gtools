int RadixSortIndex (
    size_t *x,
    size_t *index,
    const size_t N,
    const size_t dshift,
    const size_t raw,
    const int verbose
);

int RadixSortIndexPass (
    size_t *x,
    size_t *index,
    const size_t N,
    const size_t exp,
    const size_t shift
);

int CountingSortIndex (
    size_t *x,
    size_t *index,
    const size_t N,
    const size_t min,
    const size_t max
);

/**
 * @brief Radix sort on unsigned 64-bit integers with index
 *
 * Perform a radix sort on an array of 64-bit integers. The radix
 * sort performs 64 / d passes of the counting sort, where the set of
 * integers is sorted d-bits at a time. In order to achiave this, we
 * sort x[i] mod 2^(d * (j - 1)) for j = 1 to 64 / d. Smaller values of
 * d will result in a slower sort (more pases of the counting sort are
 * required) but will use less memory.
 *
 * @param x vector of unsigned 64-bit integers to sort
 * @param ix vector of same length where to store the sort index
 * @param N length of array
 * @param dshift number of bits to sort at a time
 * @param raw alternatively, have d be the base power
 * @return stable sorted @x and @ix of the sort
 */
int RadixSortIndex (
    size_t *x,
    size_t *index,
    const size_t N,
    const size_t dshift,
    const size_t raw,
    const int verbose)
{
    int rc ;
    int i;
    size_t nloops  = 0;
    size_t exp   = 1;
    size_t max   = mf_max_unsigned(x, N);
    size_t min   = mf_min_unsigned(x, N);
    size_t range = max - min + 1;
    size_t ctol  = pow(2, 24);

    size_t shift; size_t loops;
    if (raw) {
        shift = dshift;
        loops = log(max) / log(dshift);
    }
    else {
        loops = 64 / dshift - 1;
        shift = pow(2, dshift);
    }

    for (i = 0; i < N; i++)
        index[i] = i;

    if ( range < ctol ) {
        if ( (rc = CountingSortIndex (x, index, N, min, max)) ) return(rc);
        if ( verbose ) {
            sf_printf("\t\tStep (2.1) counting sort: min = %'lu, max = %'lu\n", min, max);
        }
    }
    else {
        do {
            if ( (rc = RadixSortIndexPass (x, index, N, exp, shift)) ) return(rc);
        } while ( (max > (exp *= shift)) & (nloops++ < loops) );
        if ( verbose ) {
            sf_printf("\t\tStep (2.1) radix sort: loops = %lu, bits = %lu, shift = %'lu\n",
                      nloops, dshift, shift);
        }
    }

    return(0);
}

/**
 * @brief One pass of radix sort: Counting sort with index
 *
 * Perform one pass of the counting sort for the radix sort using
 * the modulus operator to sort log2(shift) bits at a time.
 *
 * @param x vector of unsigned 64-bit integers to sort
 * @param index vector of same length where to store the sort index
 * @param N length of array
 * @param exp the jth step gives exp = 2^(d * (j - 1))
 * @param shift number of bits to sort at a time (equal to 2^d)
 * @return jth pass of radix sort for @x and corresponding @index
 */
int RadixSortIndexPass (
    size_t *x,
    size_t *index,
    const size_t N,
    const size_t exp,
    const size_t shift)
{
    // Allocate space for x, index copies and x mod
    size_t *xmod = calloc(N, sizeof *xmod);
    size_t *outx = calloc(N, sizeof *outx);
    size_t *outi = calloc(N, sizeof *outi);
    int i, c, count[shift];

    if ( xmod == NULL ) return(sf_oom_error("RadixSortIndexPass", "xmod"));
    if ( outx == NULL ) return(sf_oom_error("RadixSortIndexPass", "outx"));
    if ( outi == NULL ) return(sf_oom_error("RadixSortIndexPass", "outi"));

    // Initialize count as 0s
    for (i = 0; i < shift; i++)
        count[i] = 0;

    // Freq count of ((x / exp) mod shift)
    for (i = 0; i < N; i++) {
        count[ xmod[i] = ((outx[i] = x[i]) / exp) % shift ]++;
        outi[i] = index[i];
    }

    // Cummulative freq count (position in output)
    for (i = 1; i < shift; i++)
        count[i] += count[i - 1];

    // Copy back in stable sorted order
    for (i = N - 1; i >= 0; i--) {
        index[c = count[xmod[i]]-- - 1] = outi[i];
        x[c] = outx[i];
    }

    // Free space
    free(xmod);
    free(outx);
    free(outi);

    return(0);
}

/**
 * @brief Counting sort with index
 *
 * Perform counting sort, additionally storing data shuffle
 * in index variable.
 *
 * @param x vector of unsigned 64-bit integers to sort
 * @param index vector of same length where to store the sort index
 * @param N length of array
 * @return Counting sort on integer array.
 */
int CountingSortIndex (
    size_t *x,
    size_t *index,
    const size_t N,
    const size_t min,
    const size_t max)
{
    int i, s;
    size_t range = max - min + 1;

    // Allocate space for x, index copies and x mod
    size_t *xcopy = calloc(N, sizeof *xcopy);
    size_t *icopy = calloc(N, sizeof *icopy);
    int    *count = calloc(range + 1, sizeof *count);

    if ( xcopy == NULL ) return(sf_oom_error("mf_counting_sort_index", "xcopy"));
    if ( icopy == NULL ) return(sf_oom_error("mf_counting_sort_index", "icopy"));
    if ( count == NULL ) return(sf_oom_error("mf_counting_sort_index", "count"));

    // Initialize count as 0s
    for (i = 0; i < range + 1; i++)
        count[i] = 0;

    // Freq count of x
    for (i = 0; i < N; i++) {
        count[ xcopy[i] = (x[i] + 1 - min) ]++;
        icopy[i] = index[i];
    }

    // Cummulative freq count (position in output)
    for (i = 1; i < range; i++)
        count[i] += count[i - 1];

    // Copy back in stable sorted order
    // for (i = N - 1; i >= 0; i--) {
    for (i = 0; i < N; i++) {
        index[ s = count[xcopy[i] - 1]++ ] = icopy[i];
        x[s] = xcopy[i] - 1 + min;
    }

    // Free space
    free (count);
    free (xcopy);
    free (icopy);

    return(0);
}
