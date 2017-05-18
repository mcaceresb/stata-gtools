#define RADIX_SHIFT 16
#include "gtools_sort.h"

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
 * @param index vector of same length where to store the sort index
 * @param N length of array
 * @param dshift number of bits to sort at a time
 * @param raw alternatively, have d be the base power
 * @return stable sorted @x and @index of the sort
 */
void mf_radix_sort_index (
    uint64_t x[],
    size_t index[],
    const size_t N,
    const size_t dshift,
    const size_t raw,
    const int verbose)
{
    size_t nloops  = 0;
    uint64_t exp   = 1;
    uint64_t max   = mf_max(x, N);
    uint64_t min   = mf_min(x, N);
    uint64_t ctol  = pow(2, 31) - 1;

    size_t shift; uint64_t loops;
    if (raw) {
        shift = dshift;
        loops = log(max) / log(dshift);
    }
    else {
        loops = 64 / dshift - 1;
        shift = pow(2, dshift);
    }

    for (int i = 0; i < N; i++)
        index[i] = i;

    if ( max < ctol ) {
        mf_counting_sort_index (x, index, N, min, max);
        if ( verbose ) {
            sf_printf("counting sort on hash; min = %'lu, max = %'lu\n", min, max);
        }
    }
    else {
        do {
            mf_radix_sort_index_pass (x, index, N, exp, shift);
        } while ( (max > (exp *= shift)) & (nloops++ < loops) );
        if ( verbose ) {
            sf_printf("radix sort on hash: loops = %lu, bits = %lu, shift = %'lu\n",
                      nloops + 1, dshift, shift);
        }
    }

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
void mf_radix_sort_index_pass (
    uint64_t x[],
    size_t index[],
    const size_t N,
    const uint64_t exp,
    const size_t shift)
{
    // Allocate space for x, index copies and x mod 
    uint64_t *xmod = calloc(N, sizeof *xmod);
    uint64_t *outx = calloc(N, sizeof *outx);
    size_t   *outi = calloc(N, sizeof *outi);
    int i, c, count[shift];

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
void mf_counting_sort_index(
    uint64_t x[],
    size_t index[],
    const size_t N,
    const size_t min,
    const size_t max)
{
    size_t range = max - min + 1;

    // Allocate space for x, index copies and x mod 
    uint64_t *xcopy = calloc(N, sizeof *xcopy);
    size_t   *icopy = calloc(N, sizeof *icopy);
    int i, s, count[range + 1];

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
    for (i = N - 1; i >= 0; i--) {
        index[ s = count[xcopy[i] - 1]++ ] = icopy[i];
        x[s] = xcopy[i] - 1 + min;
    }

    // Free space
    free(xcopy);
    free(icopy);
}


/**
 * @brief Set up variables for panel using 128-bit hashes
 * 
 * Using sorted 128-bit hashes, generate info array with start and
 * ending positions of each group in the sorted hash.
 * 
 * @param h1 Array of 64-bit integers containing first half of 128-bit hashes
 * @param h2 Array of 64-bit integers containing second half of 128-bit hashes
 * @param index Index of sort (will modify if second half of hash is required)
 * @param N Length of h1, h2 arrays
 * @param J where to store the number of groups
 * @return info arary with start and end positions of each group
 */
size_t * mf_panelsetup128 (
    uint64_t h1[],
    uint64_t h2[],
    uint64_t index[],
    const size_t N,
    size_t * J)
{

    *J = 1;
    size_t collision64 = 0;
    size_t i = 0;
    size_t l = 0;
    size_t start_l;
    size_t range_l;

    uint64_t el = h1[i++];
    size_t *info_largest = calloc(N + 1, sizeof *info_largest);
    info_largest[l++] = 0;
    do {
        if (h1[i] != el) {

            // The 128-bit hash is stored in 2 64-bit parts; almost
            // surely sorting by one of them is sufficient, but in case
            // it is not, sort by the other, and that should be enough.
            //
            // Sorting by both keys all the time is time-consuming,
            // whereas sorting by only one key is fast. Since we only
            // expect about 1 collision every 4 billion groups, it
            // should be very rare to have to use both keys. (Stata caps
            // observations at 20 billion anyway, and there's one hash
            // per *group*, not row).
            // 
            // Still, if the 64-bit hashes are not enough, use the full
            // 128-bit hashes, wehere we don't expect a collision until
            // we have 16 quintillion groups in our data.
            // 
            // See burtleburtle.net/bob/hash/spooky.html for details.

            if ( !mf_check_allequal(h2, info_largest[l - 1], i) ) {
                collision64++;
                start_l = info_largest[l - 1];
                range_l = i - start_l;

                size_t   *ix_l = calloc(range_l, sizeof *ix_l);
                size_t   *ix_c = calloc(range_l, sizeof *ix_c);
                uint64_t *h2_l = calloc(range_l, sizeof *h2_l);

                for (size_t j = start_l; j < i; j++)
                    h2_l[j - start_l] = h2[j];

                mf_radix_sort_index (h2_l, ix_l, range_l, RADIX_SHIFT, 0, 0);
                free (h2_l);
                for (size_t j = 0; j < range_l; j++)
                    ix_c[j] = index[ix_l[j] + start_l];

                free (ix_l);
                for (size_t j = start_l; j < i; j++)
                    index[j] = ix_c[j - start_l];

                free (ix_c);
            }

            info_largest[l++] = i;
            el = h1[i];
        }
        i++;
    } while( i < N );
    info_largest[l] = N;

    *J = l;
    size_t *info = calloc(l + 1, sizeof *info);
    for (i = 0; i < l + 1; i++)
        info[i] = info_largest[i];
    free (info_largest);

    if ( collision64 > 0 )
        sf_printf("Found %lu 64-bit hash collision(s). Fell back on 128-bit hash.\n", collision64);

    return (info);
}

/**
 * @brief Short utility to check if segment of array is equal
 * 
 * Check if elements from start to end of array @hash are equan
 * from @start to @end.
 * 
 * @param hash Array of 64-bit integers to check are equal
 * @param start Start position of check
 * @param end End position of check
 * @return 1 if @hash is equal from @start to @end; 0 otherwise
 */
int mf_check_allequal (uint64_t hash[], size_t start, size_t end)
{
    uint64_t first = hash[start];
    for (size_t i = start + 1; i < end; i++)
        if ( hash[i] != first ) return (0);
    return (1);
}

/**
 * @brief Set up variables for panel using 64-bit hashes
 * 
 * Using sorted 64-bit hashes, generate info array with start and ending
 * positions of each group in the sorted hash. Gtools uses this only if
 * the inputs were all integers and was able to biject them into the
 * whole numbers.
 * 
 * @param h1 Array of 64-bit integers containing the result of the bijection.
 * @param N Length of h1, h2 arrays
 * @param J where to store the number of groups
 * @return info arary with start and end positions of each group
 */
size_t * mf_panelsetup (uint64_t h1[], const size_t N, size_t * J)
{
    *J = 1;
    size_t i = 0;
    size_t l = 0;

    uint64_t el = h1[i++];
    size_t *info_largest = calloc(N + 1, sizeof *info_largest);
    info_largest[l++] = 0;
    do {
        if (h1[i] != el) {
            info_largest[l++] = i;
            el  = h1[i];
        }
        i++;
    } while( i < N );
    info_largest[l] = N;

    *J = l;
    size_t *info = calloc(l + 1, sizeof *info);
    for (i = 0; i < l + 1; i++)
        info[i] = info_largest[i];
    free (info_largest);

    return (info);
}
