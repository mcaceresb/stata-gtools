#include "gtools_hash.h"
#include "spookyhash/src/spookyhash_api.h"

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
    int strmax)
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
    int karr[])
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
    int min)
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
    int maxs[])
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
    int i, k;

    offsets[0] = 0;
    for (k = 0; k < K - 1; k++) {
        offset *= (maxs[k] - mins[k] + 1);
        offsets[k + 1] = offset;
    }

    // Construct bijection to whole numbers (we index missing vaues to the
    // largest number plus 1 as a convention; note we set the maximum to
    // the actual max + 1 from Stata so the offsets are correct)
    for (i = 0; i < N; i++) {
        if ( (rc = SF_vdata(1, i + in1, &z)) ) return(rc);
        if ( SF_is_missing(z) ) z = maxs[0];
        h1[i] = z - mins[0] + 1;
        for (k = 1; k < K; k++) {
            if ( (rc = SF_vdata(k + k1, i + in1, &z)) ) return(rc);
            if ( SF_is_missing(z) ) z = maxs[k];
            h1[i] += (z - mins[k]) * offsets[k];
        }
        // sf_printf ("Obs %9d = %21lu\n", i, h1[i]);
    }

    return (0);
}

/* TODO: This is buggy; perhaps you need to allocate memory to s
 * as well, and zero it out at each loop, like with st_strbase and
 * st_strcomp? // 2017-05-24 02:37 EDT
 */

/**
 * @brief Check whether there were hash collisions
 *
 * C indexes the data into info and index. info notes the number of
 * observations in each group. index maps the ith observation of the jth
 * group to its corresponding position in Stata (+- SF_in1()). Hence if
 * all observations from info[j] to info[j + 1] are the same, there are
 * no collisions. If they are not, we have a collision.
 *
 * @param st_info Object containing index, info, and other Stata params
 * @return Store map to whole numbers in @h1
 *
 */
int sf_check_hash_index (struct StataInfo *st_info)
{
    int i, j, k;
    size_t start, end, sel, numpos, strpos;
    size_t l_str  = 0;
    size_t k_num  = 0;
    size_t k1     = 1;
    size_t k2     = st_info->kvars_by;
    size_t K      = k2 - k1 + 1;
    int    kmax   = mf_max_signed(st_info->byvars_lens, K);
    clock_t timer = clock();

    // Figure out the number of numeric by variables and the combined
    // string length of string by variables.
    for (k = 0; k < K; k++) {
        if (st_info->byvars_lens[k] > 0) {
            l_str += st_info->byvars_lens[k];
        }
        else {
            k_num += 1;
        }
    }
    l_str = l_str > 0? l_str: 1;

    // Will compare string in st_strbase to st_strcomp and number as are
    // being read to numbers in st_numbase and st_nummiss
    ST_retcode rc ;
    ST_double  z ;

    // char s[kmax > 0? kmax + 1: 1];
    int klen = kmax > 0? kmax + 1: 1;
    char *s; s = malloc(klen * sizeof(char));
    char *st_strbase; st_strbase = malloc(l_str * sizeof(char));
    char *st_strcomp; st_strcomp = malloc(l_str * sizeof(char));

    double st_numbase[k_num > 0? k_num: 1];
    short st_nummiss[k_num > 0? k_num: 1];
    size_t collisions_count = 0;
    size_t collisions_row   = 0;

    // Loop through each group's observations
    for (j = 0; j < st_info->J; j++) {
        memset (st_strbase, '\0', l_str);
        start  = i = st_info->info[j];
        end    = st_info->info[j + 1];
        sel    = st_info->index[i] + st_info->in1;
        numpos = 0;
        strpos = 0;
        for (k = 0; k < k_num; k++)
            st_nummiss[numpos] = 0;

        // Compare all entries in each group to the first entry that
        // appears in Stata
        for (k = 0; k < K; k++) {
            if (st_info->byvars_lens[k] > 0) {
                memset (s, '\0', klen);
                if ( (rc = SF_sdata(k + k1, sel, s)) ) return(rc);
                memcpy (st_strbase + strpos, &s, strlen(s));
                strpos += strlen(s);
            }
            else {
                if ( (rc = SF_vdata(k + k1, sel, &z)) ) return(rc);
                if ( SF_is_missing(z) ) {
                    st_nummiss[numpos] = 1;
                }
                else {
                    st_numbase[numpos] = z;
                }
                ++numpos;
            }
        }

        // debugging
        // sf_printf ("Checking: strings = '");
        // sf_printf (st_strbase);
        // sf_printf ("' and numbers = ");
        // for (k = 0; k < k_num; k++) {
        //     if ( st_nummiss[k] ) {
        //         sf_printf ("[missing], ");
        //     }
        //     else {
        //         sf_printf ("%.5f, ", st_numbase[k]);
        //     }
        // }
        // sf_printf ("vs:\n");
        // debugging

        // Check 2nd entry of group onward
        for (i = start + 1; i < end; i++) {
            memset (st_strcomp, '\0', l_str);
            collisions_row = 0;
            numpos = 0;
            strpos = 0;
            sel    = st_info->index[i] + st_info->in1;
            for (k = 0; k < K; k++) {
                if (st_info->byvars_lens[k] > 0) {
                    // Concatenate string and compare result
                    memset (s, '\0', klen);
                    if ( (rc = SF_sdata(k + k1, sel, s)) ) return(rc);
                    memcpy ( st_strcomp + strpos, &s, strlen(s) );
                    strpos += strlen(s);
                }
                else {
                    // Compare each number individually
                    if ( (rc = SF_vdata(k + k1, sel, &z)) ) return(rc);
                    if ( SF_is_missing(z) ) {
                        if ( !st_nummiss[numpos] ) ++collisions_row;
                    }
                    else {
                        if ( st_numbase[numpos] != z ) ++collisions_row;
                    }
                    ++numpos;
                }
            }
            // debugging
            // sf_printf ("\tstrings = '");
            // sf_printf (st_strbase);
            // sf_printf ("' and numbers = ");
            // for (k = 0; k < k_num; k++) {
            //     if ( st_nummiss[k] ) {
            //         sf_printf ("[missing], ");
            //     }
            //     else {
            //         sf_printf ("%.5f, ", st_numbase[k]);
            //     }
            // }
            // sf_printf ("\n");
            // debugging
            if ( kmax > 0 ) {
                if ( (strlen (st_strbase) != strlen (st_strcomp)) ) {
                    ++collisions_row;
                }
                else if ( strncmp(st_strbase, st_strcomp, strlen(st_strcomp)) != 0 ) {
                    ++collisions_row;
                }
            }
            if ( collisions_row > 0 ) ++collisions_count;
        }
    }
    if ( st_info->benchmark ) sf_running_timer (&timer, "\tPlugin step 5.0: Checked for hash collisions");

    // If there were any collisions, ask user to file bug report
    if ( collisions_count > 0 ) {
        sf_errprintf ("There may be %'lu 128-bit hash collisions: %'lu variables, %'lu obs, %'lu groups\n",
                      collisions_count, st_info->kvars_by, st_info->N, st_info->J);
        sf_errprintf ("This feature is in beta; please file a bug report at github.com/mcaceresb/stata-gtools\n");
        return (42000);
    }
    else {
        sf_printf ("There were no hash collisions: %'lu variables, %'lu obs, %'lu groups\n",
                   st_info->kvars_by, st_info->N, st_info->J);
    }

    free(s);
    free(st_strbase);
    free(st_strcomp);

    return(0);
}
