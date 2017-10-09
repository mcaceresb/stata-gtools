#include "gisid.h"

int sf_hash_byvars_isid (struct StataInfo *st_info)
{

    int i;
    size_t N_if;
    ST_retcode rc = 42007;
    clock_t timer = clock();

    // Hash the data
    // -------------

    // Hashing: Throughout the code we allocate to heap bc C may run out
    // of memory in the stack.
    st_info->index   = calloc(st_info->N, sizeof(st_info->index));
    size_t *index    = st_info->index;
    uint64_t *ghash1 = calloc(st_info->N, sizeof *ghash1);
    uint64_t *ghash, *ghash2;

    if ( index  == NULL ) sf_oom_error("sf_hash_byvars", "index");
    if ( ghash1 == NULL ) sf_oom_error("sf_hash_byvars", "ghash1");

    if ( st_info->integers_ok ) {

        // Construct the hash using whole numbers
        // --------------------------------------

        // If al integers are passed, try to use them as the hash by doing
        // a bijection to the whole numbers.

        if ( st_info->kvars_by > 1 ) {
            if ( st_info->verbose )
                sf_printf("Hashing %d integer by variables to whole-nubmer index.\n", st_info->kvars_by);
            if ( (rc = sf_get_varlist_bijection (ghash1, 1,
                                                 st_info->kvars_by,
                                                 st_info->in1,
                                                 st_info->in2,
                                                 st_info->byvars_mins,
                                                 st_info->byvars_maxs,
                                                 st_info->verbose)) ) return(rc);
        }
        else {
            if ( st_info->verbose )
                sf_printf("Using sole integer by variable as hash.\n", st_info->kvars_by);
            if ( (rc = sf_get_variable_ashash (ghash1, 1,
                                               st_info->in1,
                                               st_info->in2,
                                               st_info->byvars_mins[0],
                                               st_info->byvars_maxs[0],
                                               st_info->verbose)) ) return(rc);
        }
        if ( st_info->benchmark ) sf_running_timer (&timer, "\tPlugin step 2: Hashed by variables");

        // Index the hash using a radix sort
        // ---------------------------------

        // index[i] gives the position in Stata of the ith entry
        rc = mf_radix_sort_index (ghash1, index, st_info->N, RADIX_SHIFT, 0, st_info->verbose);
        if ( rc ) return(rc);
        if ( st_info->benchmark ) sf_running_timer (&timer, "\tPlugin step 3: Sorted on integer-only hash index");

        // Adjust hash to only contain hashes that match [if] condition
        if ( st_info->any_if ) {
            N_if = 0;
            for (i = 0; i < st_info->N; i++) {
                if ( SF_ifobs(index[i] + st_info->in1) ) {
                    ghash1[N_if] = ghash1[i];
                    index[N_if]  = index[i];
                    N_if++;
                }
            }
            st_info->N = N_if;
            if ( st_info->benchmark ) sf_running_timer (&timer, "\t\tPlugin step 3.1: Adjusted index based on if condition");
        }

        // Check if hash gives unique observations
        rc = sf_isid (ghash1, st_info);
        if ( st_info->benchmark ) sf_running_timer (&timer, "\tPlugin step 4: Checked if varlist is ID");
    }
    else {

        // If non-integers, mix of numbers and strings, or if the bijection could fail,
        // hash the data using Jenkin's 128-bit spooky hash.
        //
        // References
        //     en.wikipedia.org/wiki/Jenkins_hash_function
        //     burtleburtle.net/bob/hash/spooky.html
        //     github.com/centaurean/spookyhash

        ghash2 = calloc(st_info->N, sizeof *ghash2);
        if ( ghash2  == NULL ) sf_oom_error("sf_hash_byvars", "ghash2");

        if ( st_info->kvars_by > 1 ) {
            if ( st_info->verbose ) {
                if ( st_info->byvars_maxlen > 0 ) {
                    if ( st_info->byvars_minlen > 0 ) {
                        sf_printf("Using 128-bit hash to index %d string-only by variables.\n", st_info->kvars_by);
                    }
                    else {
                        sf_printf("Using 128-bit hash to index %d by variables (string and numeric).\n", st_info->kvars_by);
                    }
                }
                else {
                    sf_printf("Using 128-bit hash to index %d numeric-only by variables\n", st_info->kvars_by);
                }
            }
            if ( (rc = sf_get_varlist_hash (ghash1, ghash2, 1,
                                            st_info->kvars_by,
                                            st_info->in1,
                                            st_info->in2,
                                            st_info->byvars_lens,
                                            st_info->verbose)) ) return(rc);
        }
        else {
            if ( (st_info->byvars_lens[0] > 0) & st_info->verbose ) {
                sf_printf("Using 128-bit hash to index string by variable.\n", st_info->kvars_by);
            }
            else if ( st_info->verbose ) {
                sf_printf("Using 128-bit hash to index numeric by variable.\n", st_info->kvars_by);
            }
            if ( (rc = sf_get_variable_hash (ghash1, ghash2, 1,
                                             st_info->in1,
                                             st_info->in2,
                                             st_info->byvars_lens[0],
                                             st_info->verbose)) ) return(rc);
        }
        if ( st_info->benchmark ) sf_running_timer (&timer, "\tPlugin step 2: Hashed by variables");

        // Index the hash using a radix sort
        // ---------------------------------

        // index[i] gives the position in Stata of the ith entry
        rc = mf_radix_sort_index (ghash1, index, st_info->N, RADIX_SHIFT, 0, st_info->verbose);
        if ( rc ) return(rc);
        if ( st_info->benchmark ) sf_running_timer (&timer, "\tPlugin step 3: Sorted on integer-only hash index");

        // Copy ghash2 in case you will need it
        ghash = calloc(st_info->N, sizeof *ghash);
        if ( ghash  == NULL ) sf_oom_error("sf_hash_byvars", "ghash");
        for (i = 0; i < st_info->N; i++) {
            ghash[i] = ghash2[index[i]];
        }
        free (ghash2);

        // Adjust hash to only contain hashes that match [if] condition
        if ( st_info->any_if ) {
            N_if = 0;
            for (i = 0; i < st_info->N; i++) {
                if ( SF_ifobs(index[i] + st_info->in1) ) {
                    ghash1[N_if] = ghash1[i];
                    ghash[N_if]  = ghash[i];
                    index[N_if]  = index[i];
                    N_if++;
                }
            }
            st_info->N = N_if;
            if ( st_info->benchmark ) sf_running_timer (&timer, "\t\tPlugin step 3.1: Adjusted index based on if condition");
        }

        // Check if hash gives unique observations
        rc = sf_isid128 (ghash1, ghash, index, st_info);
        if ( st_info->benchmark ) sf_running_timer (&timer, "\tPlugin step 4: Checked if varlist is ID");
        free (ghash);
    }
    free (ghash1);

    return (rc);
}

int sf_isid (
    uint64_t h1[],
    struct StataInfo *st_info)
{
    size_t i;

    // Search for a place in the sorted hash with two consecutive equal
    // values; if any two hashes are the same then we don't have an ID.
    for (i = 1; i < st_info->N; i++) {
        if ( h1[i] == h1[i - 1] ) return(42005);
    }

    // If no two hashes are the same, the varlist is an ID
    return (42006);
}

int sf_isid128 (
    uint64_t h1[],
    uint64_t h2[],
    size_t index[],
    struct StataInfo *st_info)
{

    size_t i, start, end, range;
    ST_retcode rc ;

    // Search for a place in the sorted hash with two consecutive equal values
    for (i = 1; i < st_info->N; i++) {
        if ( h1[i] == h1[i - 1] ) break;
    }

    if ( i < st_info->N ) {

        // If at least one hashes pair is the same, varlist may not be an ID.
        // Figure out where the equal hashes start and end.
        start = i - 1;
        for (end = i + 1; end < st_info->N; end++) {
            if ( h1[end] != h1[end - 1] ) break;
        }

        // If both parts of the hash are the same for every observation in
        // start to end, then two groups mapped to the same hash.  Check the
        // two groups are the same in the data. If they are then you don't
        // have an iD. If they are not then you have a collision.
        if ( !mf_check_allequal(h2, start, end) ) {
            range = end - start;

            size_t   *ix_l = calloc(range, sizeof *ix_l);
            size_t   *ix_c = calloc(range, sizeof *ix_c);
            uint64_t *h2_l = h2 + start;

            if ( ix_l == NULL ) return(sf_oom_error("mf_panelsetup128", "ix_l"));
            if ( ix_c == NULL ) return(sf_oom_error("mf_panelsetup128", "ix_c"));

            mf_radix_sort_index (h2_l, ix_l, range, RADIX_SHIFT, 0, 0);

            for (i = 0; i < range; i++)
                ix_c[i] = index[ix_l[i] + start];

            free (ix_l);

            for (i = start; i < range; i++)
                index[i] = ix_c[i - start];

            free (ix_c);

            for (i = 1; i < range; i++) {
                if ( h2_l[i] == h2_l[i - 1] ) break;
            }
            start += i - 1;
        }

        // Once this is sorted, you 
        if ( (rc = sf_check_isid_collision (st_info, index[start], index[start + 1])) ) return (rc);
        return (42005);
    }

    // If no two hashes are the same, the varlist is an ID
    return (42006);
}

int sf_check_isid_collision (struct StataInfo *st_info, size_t obs1, size_t obs2)
{

    /*********************************************************************
     *                               Setup                               *
     *********************************************************************/

    int k, numpos, strpos;
    size_t l_str  = 0;
    size_t k_num  = 0;
    size_t k1     = 1;
    size_t k2     = st_info->kvars_by;
    size_t K      = k2 - k1 + 1;
    int    kmax   = mf_max_signed(st_info->byvars_lens, K);

    // Figure out the number of numeric by variables and the combined string
    // length of string by variables.
    for (k = 0; k < K; k++) {
        if (st_info->byvars_lens[k] > 0) {
            l_str += st_info->byvars_lens[k];
        }
        else {
            k_num += 1;
        }
    }
    l_str = l_str > 0? (l_str + 1): 1;

    // Will compare string in st_strbase to st_strcomp and number as are being
    // read to numbers in st_numbase and st_nummiss
    ST_retcode rc ;
    ST_double  z ;

    int klen = kmax > 0? (kmax + 1): 1;
    char *s = malloc(klen * sizeof(char)); memset (s, '\0', klen * sizeof(char));
    char *st_strbase = malloc(l_str * sizeof(char)); memset (st_strbase, '\0', l_str * sizeof(char));
    char *st_strcomp = malloc(l_str * sizeof(char)); memset (st_strcomp, '\0', l_str * sizeof(char));

    double *st_numbase = calloc(k_num > 0? k_num: 1, sizeof *st_numbase);
    short  *st_nummiss = calloc(k_num > 0? k_num: 1, sizeof *st_nummiss);

    /*********************************************************************
     *        Check for collisions without saving group variables        *
     *********************************************************************/


    // Read in base case
    // -----------------

    for (k = 0; k < k_num; k++)
        st_nummiss[k] = 0;

    memset (st_strbase, '\0', l_str);
    strpos = numpos = 0;
    for (k = 0; k < K; k++) {
        if ( st_info->byvars_lens[k] > 0 ) {
            if ( (rc = SF_sdata(k + k1, obs1 + st_info->in1, st_strbase + strpos)) ) return(rc);
            strpos = strlen(st_strbase);
        }
        else {
            if ( (rc = SF_vdata(k + k1, obs1 + st_info->in1, &z)) ) return(rc);
            if ( SF_is_missing(z) ) {
                st_nummiss[numpos] = 1;
            }
            else {
                st_numbase[numpos] = z;
            }
            ++numpos;
        }
    }

    // Read in comparison case
    // -----------------------

    memset (st_strcomp, '\0', l_str);
    strpos = numpos = 0;
    for (k = 0; k < K; k++) {
        if ( st_info->byvars_lens[k] > 0 ) {
            if ( (rc = SF_sdata(k + k1, obs2 + st_info->in1, st_strcomp + strpos)) ) return(rc);
            strpos = strlen(st_strcomp);
        }
        else {
            if ( (rc = SF_vdata(k + k1, obs2 + st_info->in1, &z)) ) return(rc);
            if ( SF_is_missing(z) ) {
                if ( !st_nummiss[numpos] ) goto collision;
            }
            else {
                if ( st_numbase[numpos] != z ) goto collision;
            }
            ++numpos;
        }
    }

    if ( kmax > 0 ) {
        if ( (strlen (st_strbase) != strlen (st_strcomp)) ) {
            goto collision;
        }
        else if ( strncmp(st_strbase, st_strcomp, strlen(st_strcomp)) != 0 ) {
            goto collision;
        }
    }

    free (s);
    free (st_numbase);
    free (st_nummiss);
    free (st_strbase);
    free (st_strcomp);
    return(0);

    /*********************************************************************
     *      Finish (prompt user for bug report if collisions happen      *
     *********************************************************************/

collision:
    sf_errprintf ("There may be 128-bit hash collisions: "FMT" variables, "FMT" obs ("FMT", "FMT")\n",
                  st_info->kvars_by, st_info->N, obs1, obs2);
    sf_errprintf ("This is likely a bug; please file a bug report at github.com/mcaceresb/stata-gtools/issues\n");

    free (s);
    free (st_numbase);
    free (st_nummiss);
    free (st_strbase);
    free (st_strcomp);

    return (42000);
}
