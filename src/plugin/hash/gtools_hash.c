#include "gtools_hash.h"
#include "../spookyhash/src/spookyhash_api.h"
#include "gtools_hash_check.c"

/**
 * @brief Hash single variable (string or float|double)
 *
 * Use the latest version of Jenkin's one-at-a-time hash, the spooky
 * hash, to hash the data into 128-bit integers stored in 2 unsinged
 * 64-bit arrays.
 *
 * @param h1 Where to store first halfs of each 128-bit hash
 * @param h2 Where to store second halfs of each 128-bit hash
 * @param k Hash kth variable passed from Stata
 * @param in1 Hash starting from in1th obs
 * @param in2 Hash starting from in2th obs
 * @param strmax Lenght of string if string or 0, -1 if double, integer
 * @return Store 128-bit hashes in 2 parts into @h1 and @h2
 *
 */
int sf_get_variable_hash (
    uint64_t h1[],
    uint64_t h2[],
    size_t k,
    size_t in1,
    size_t in2,
    int strmax,
    short verbose)
{

    if ( in2 < in1 ) {
        sf_errprintf("data ending position %'lu < starting position %'lu\n", in2, in1);
        return(198);
    }

    ST_retcode rc ;
    ST_double  z ;

    int i;
    size_t N = in2 - in1 + 1;
    char s[strmax + 1];
    spookyhash_context sc;

    // Get data on every row from in1 to in2 regardless of `if'; in case
    // the plugin was not called with an `if' statement this will not
    // work, so subset before starting the plugin. The if condition is
    // so we do not have multiple ifs within the long for loop.

    if ( strmax > 0 ) {
        for (i = 0; i < N; i++) {
            if ( (rc = SF_sdata(k, i + in1, s)) ) return(rc);
            spookyhash_context_init(&sc, 1, 2);
            spookyhash_update(&sc, &s, strlen(s));
            spookyhash_final(&sc, &h1[i], &h2[i]);
            // sf_printf ("Obs %9d = %s, %21lu, %21lu\n", i, s, h1[i], h2[i]);
        }
    }
    else {
        for (i = 0; i < N; i++) {
            if ( (rc = SF_vdata(k, i + in1, &z)) ) return(rc);
            spookyhash_context_init(&sc, 1, 2);
            spookyhash_update(&sc, &z, 8);
            spookyhash_final(&sc, &h1[i], &h2[i]);
            // sf_printf ("Obs %9d = %.1f, %21lu, %21lu\n", i, z, h1[i], h2[i]);
        }
    }
    return(0);
}

/**
 * @brief Hash set of variables (strings or floats|doubles)
 *
 * Use the latest version of Jenkin's one-at-a-time hash, the spooky
 * hash, to hash the data into 128-bit integers stored in 2 unsinged
 * 64-bit arrays.
 *
 * We can hash a mix of string and numeric variable's due to this
 * specific implementation of spooky hash, which uses context variables
 * to hash multi-part content.
 *
 * @param h1 Where to store first halfs of each 128-bit hash
 * @param h2 Where to store second halfs of each 128-bit hash
 * @param k1 Hash from k1th variable passed from Stata
 * @param k2 Hash through k2th variable passed from Stata
 * @param in1 Hash starting from in1th obs
 * @param in2 Hash starting from in2th obs
 * @param karr Lenght of each string varaible or 0, -1 if double, integer
 * @return Store 128-bit hashes in 2 parts into @h1 and @h2
 *
 */
int sf_get_varlist_hash (
    uint64_t h1[],
    uint64_t h2[],
    size_t k1,
    size_t k2,
    size_t in1,
    size_t in2,
    int karr[],
    short verbose)
{

    if ( k2 < k1 ) {
        sf_errprintf("requested variables %d to %d; must request varlist in order\n", k1, k2);
        return(198);
    }

    if ( in2 < in1 ) {
        sf_errprintf("data ending position %'lu < starting position %'lu\n", in2, in1);
        return(198);
    }

    ST_retcode rc ;
    ST_double  z ;
    size_t N = in2 - in1 + 1;          // Number of obse to hash
    size_t K = k2 - k1 + 1;            // Number of vars to hash
    int kmax = mf_max_signed(karr, K); // To detemrine if there are strings
    int kmin = mf_min_signed(karr, K); // To determine if there are nubmers
    char s[kmax + 1];
    spookyhash_context sc;
    int i, k;

    // Get data on every row from in1 to in2 regardless of `if'; in
    // case the plugin was not called with an `if' statement this will
    // not work, so subset before starting the plugin. All the if
    // statements are so we have fewer if conditions inside long loops

    // Note: The length of the character data is at most kmax; the
    // lenght of numeric data is at most 8 bytes.
    if (kmax > 0) {
        if (kmin > 0) {
            // All variables are strings (all have a length)
            for (i = 0; i < N; i++) {
                spookyhash_context_init(&sc, 1, 2);

                for (k = 0; k < K; k++) {
                    if ( (rc = SF_sdata(k + k1, i + in1, s)) ) return(rc);
                    spookyhash_update(&sc, &s, strlen(s));
                }

                spookyhash_final(&sc, &h1[i], &h2[i]);
                // sf_printf ("Obs %9d, %21lu, %21lu\n", i, h1[i], h2[i]);
            }
        }
        else {
            // Mix of variables and numeric.
            for (i = 0; i < N; i++) {
                spookyhash_context_init(&sc, 1, 2);

                for (k = 0; k < K; k++) {
                    if (karr[k] > 0) {
                        if ( (rc = SF_sdata(k + k1, i + in1, s)) ) return(rc);
                        spookyhash_update(&sc, &s, strlen(s));
                    }
                    else {
                        if ( (rc = SF_vdata(k + k1, i + in1, &z)) ) return(rc);
                        spookyhash_update(&sc, &z, 8);
                    }
                }

                spookyhash_final(&sc, &h1[i], &h2[i]);
                // sf_printf ("Obs %9d, %21lu, %21lu\n", i, h1[i], h2[i]);
            }
        }
    }
    else {
        // All variables are numeric
        for (i = 0; i < N; i++) {
            spookyhash_context_init(&sc, 1, 2);

            for (k = 0; k < K; k++) {
                if ( (rc = SF_vdata(k + k1, i + in1, &z)) ) return(rc);
                spookyhash_update(&sc, &z, 8);
            }

            spookyhash_final(&sc, &h1[i], &h2[i]);
            // sf_printf ("Obs %9d, %21lu, %21lu\n", i, h1[i], h2[i]);
        }
    }
    return(0);
}

/**
 * @brief Use the grouping variable as a hash
 *
 * The grouping variable is an integers and can be used as a hash.
 * Simply map values to whole numbers 1 to N.
 *
 * @param h1 Where to store the map to the whole nubmers
 * @param k Use kth variable as hash
 * @param in1 Hash starting from in1th obs
 * @param in2 Hash starting from in2th obs
 * @param min Smallest integer
 * @return Store map to whole numbers in @h1
 *
 */
int sf_get_variable_ashash (
    uint64_t h1[],
    size_t k,
    size_t in1,
    size_t in2,
    int min,
    int max,
    short verbose)
{

    if ( in2 < in1 ) {
        sf_errprintf("data ending position %'lu < starting position %'lu\n", in2, in1);
        return(198);
    }

    ST_retcode rc ;
    ST_double  z ;

    int i;
    size_t N = in2 - in1 + 1;

    // Get data on every row from in1 to in2 regardless of `if'; in case
    // the plugin was not called with an `if' statement this will not
    // work, so subset before starting the plugin. The if condition is
    // so we do not have multiple ifs within the long for loop.

    for (i = 0; i < N; i++) {
        if ( (rc = SF_vdata(k, i + in1, &z)) ) return(rc);
        if ( SF_is_missing(z) ) z = max;
        h1[i] = z - min + 1;
        // sf_printf ("Obs %9d = %.1f, %21lu\n", i, z, h1[i]);
    }

    return(0);
}

/**
 * @brief Use the grouping variables as a hassh
 *
 * The grouping variables are all integer and can be used as a hash.
 * With all-integer variables, we can construct a bijection to the whole
 * numbers. Generally speaking, we want a function f so that f: X^K
 * -> N, where X is a subset of Z. Though there are generic ways to
 * impement this function for X = Z, in this case we know the bounds for
 * X. The function we use is as follows (using 1-based indexing for ease
 * of exposition):
 *
 *     offset = 1
 *     hash   = z[, 1] - min(z[, 1]) + 1
 *     for k = 2 to K
 *         offset *= (zmax[k - 1] - zmin[k - 1] + 1)
 *         hash   += ( z[, k] - min(z[, k]) ) * offset
 *
 * What is happening is that we are fisrt mapping
 *
 *     var1 -> 1 to range of var1
 *
 * Call this vmap1. Then we are mapping
 *
 *     Smallest # of var2 -> vmap1
 *     2-smallest # of var2 -> vmap1 + 2 * range of vmap1
 *     ...
 *     ith-smallest # of var2 -> vmap1 + i * range of vmap1
 *
 * Call this vmap2. Then we do
 *
 *     Smallest # of vark -> vmap(k - 1)
 *     2-smallest # of vark -> vmap(k - 1) + 2 * range of vmap(k - 1)
 *     ...
 *     ith-smallest # of vark -> vmap(k - 1) + i * range of vmap(k - 1)
 *
 * @param h1 Where to store the map to the whole nubmers
 * @param k1 Biject from k1th variable passed from Stata
 * @param k2 Biject through k2th variable passed from Stata
 * @param in1 Hash starting from in1th obs
 * @param in2 Hash starting from in2th obs
 * @param mins Minima for each variable
 * @param maxs Maxima for each variable
 * @return Store map to whole numbers in @h1
 *
 */
int sf_get_varlist_bijection (
    uint64_t h1[],
    size_t k1,
    size_t k2,
    size_t in1,
    size_t in2,
    int mins[],
    int maxs[],
    short verbose)
{

    if ( k2 < k1 ) {
        sf_errprintf("requested variables %d to %d; must request varlist in order\n", k1, k2);
        return(198);
    }

    if ( in2 < in1 ) {
        sf_errprintf("data ending position %'lu < starting position %'lu\n", in2, in1);
        return(198);
    }

    ST_retcode rc ;
    ST_double  z ;
    size_t N = in2 - in1 + 1;
    size_t K = k2 - k1 + 1;
    size_t offset = 1;
    size_t offsets[K];
    int i, k, l;

    offsets[0] = 0;
    for (k = 0; k < K - 1; k++) {
        l = K - (k + 1);
        offset *= (maxs[l] - mins[l] + 1);
        offsets[k + 1] = offset;
    }

    // Construct bijection to whole numbers (we index missing vaues to the
    // largest number plus 1 as a convention; note we set the maximum to
    // the actual max + 1 from Stata so the offsets are correct)
    for (i = 0; i < N; i++) {
        l = K - (0 + 1);
        if ( (rc = SF_vdata(l + k1, i + in1, &z)) ) return(rc);
        if ( SF_is_missing(z) ) z = maxs[l];
        h1[i] = z - mins[l] + 1;

        for (k = 1; k < K; k++) {
            l = K - (k + 1);
            if ( (rc = SF_vdata(l + k1, i + in1, &z)) ) return(rc);
            if ( SF_is_missing(z) ) z = maxs[l];
            h1[i] += (z - mins[l]) * offsets[k];
        }
        // sf_printf ("\tObs %9d = %21lu\n", i, h1[i]);
    }

    return (0);
}
