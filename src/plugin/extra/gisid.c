ST_retcode gf_isid (
    uint64_t *h1,
    uint64_t *h2,
    struct StataInfo *st_info,
    GT_size *ix,
    const GT_bool hash_level
);

ST_retcode gf_isid_bijection (
    uint64_t *h1,
    struct StataInfo *st_info
);

ST_retcode gf_check_isid_collision (
    struct StataInfo *st_info,
    GT_size obs1,
    GT_size obs2
);

ST_retcode gf_isid_bijection (uint64_t *h1, struct StataInfo *st_info)
{
    GT_size i;

    // Search for a place in the sorted hash with two consecutive equal
    // values; if any two hashes are the same then we don't have an ID.

    for (i = 1; i < st_info->N; i++) {
        if ( h1[i] == h1[i - 1] ) return (17459);
    }

    // If no two hashes are the same, the varlist is an ID
    return (0);
}

ST_retcode gf_isid (
    uint64_t *h1,
    uint64_t *h2,
    struct StataInfo *st_info,
    GT_size *ix,
    const GT_bool hash_level)
{
    if (hash_level == 0) return (gf_isid_bijection (h1, st_info));

    ST_retcode rc ;
    GT_size i, start, end, range;
    GT_size   *ix_l;
    uint64_t *h2_l;

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
        // start to end, then two groups mapped to the same hash. Check the
        // two groups are the same in the data. If they are then you don't
        // have an iD. If they are not then you have a collision.
        if ( !gf_check_allequal(h2, start, end) ) {
            range = end - start;

            ix_l = ix + start;
            h2_l = h2 + start;

            if ( (rc = gf_radix_sort16 (h2_l, ix_l, range)) ) return (rc);

            for (i = 1; i < range; i++) {
                if ( h2_l[i] == h2_l[i - 1] ) break;
            }
            start += i - 1;
        }

        // Once this is sorted, you 
        if ( (rc = gf_check_isid_collision (st_info,
                                            ix[start],
                                            ix[start + 1])) ) return (rc);
        return (17459);
    }

    // If no two hashes are the same, the varlist is an ID
    return (0);
}

ST_retcode gf_check_isid_collision (struct StataInfo *st_info, GT_size obs1, GT_size obs2)
{
    ST_retcode rc = 0;

    /*********************************************************************
     *                               Setup                               *
     *********************************************************************/

    GT_size k;
    GT_size sel, numpos, strpos;
    GT_size kvars = st_info->kvars_by;
    GT_size kstr  = st_info->kvars_by_str;
    GT_size l_str = 0;
    GT_size k_num = 0;
    GTOOLS_MAX (st_info->byvars_lens, kvars, kmax, k);

    // Figure out the number of numeric by variables and the combined string
    // length of string by variables.
    for (k = 0; k < kvars; k++) {
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
    ST_double z;

    GT_size klen = kmax > 0? (kmax + 1): 1;
    char *s  = malloc(klen * sizeof(char)); memset (s, '\0', klen);
    char *st_strbase = malloc(l_str * sizeof(char)); memset (st_strbase, '\0', l_str);
    char *st_strcomp = malloc(l_str * sizeof(char)); memset (st_strcomp, '\0', l_str);

    if ( st_strbase == NULL ) return(sf_oom_error("sf_check_hash_index", "st_strbase"));
    if ( st_strcomp == NULL ) return(sf_oom_error("sf_check_hash_index", "st_strcomp"));

    ST_double *st_numbase = calloc(k_num > 0? k_num: 1, sizeof *st_numbase);
    GT_bool   *st_nummiss = calloc(k_num > 0? k_num: 1, sizeof *st_nummiss);

    if ( st_numbase == NULL ) return(sf_oom_error("sf_check_hash_index", "st_numbase"));
    if ( st_nummiss == NULL ) return(sf_oom_error("sf_check_hash_index", "st_nummiss"));

    GT_size collisions_count = 0;

    /*********************************************************************
     *             Allocate memory to final collapsed array              *
     *********************************************************************/

    st_info->strbuffer = 0;
    if ( kstr > 0 ) {

        // Read obs 1
        // ----------

        memset (st_strbase, '\0', l_str);
        strpos = 0;
        numpos = 0;

        for (k = 0; k < kvars; k++) {
            sel = obs1 * st_info->rowbytes + st_info->positions[k];
            if ( st_info->byvars_lens[k] > 0 ) {
                memcpy (st_strbase + strpos,
                        st_info->st_charx + sel,
                        strlen(st_info->st_charx + sel));
                strpos = strlen(st_strbase);
            }
            else {
                z = *((ST_double *) (st_info->st_charx + sel));
                st_numbase[numpos] = z;
                ++numpos;
            }
        }

        // Compare to obs 2
        // ----------------

        memset (st_strcomp, '\0', l_str);
        numpos = 0;
        strpos = 0;

        for (k = 0; k < kvars; k++) {
            sel = obs2 * st_info->rowbytes + st_info->positions[k];
            if ( st_info->byvars_lens[k] > 0 ) {
                // Concatenate string and compare result
                memcpy (st_strcomp + strpos,
                        st_info->st_charx + sel,
                        strlen(st_info->st_charx + sel));
                strpos = strlen(st_strcomp);
            }
            else {
                // Compare each number individually
                z = *((ST_double *) (st_info->st_charx + sel));
                if ( st_numbase[numpos] != z ) collisions_count = 1;
                ++numpos;
            }
        }

        if ( kmax > 0 ) {
            if ( (strlen (st_strbase) != strlen (st_strcomp)) ) {
                 collisions_count = 1;
            }
            else if ( strncmp(st_strbase, st_strcomp, strlen(st_strcomp)) != 0 ) {
                 collisions_count = 1;
            }
        }
    }
    else {

        // Read obs 1
        // ----------

        for (k = 0; k < kvars; k++) {
            sel  = obs1 * kvars + k;
            z    = *(st_info->st_numx + sel);
            st_numbase[k] = z;
        }

        // Check 2nd entry of group onward
        // -------------------------------

        for (k = 0; k < kvars; k++) {
            sel = obs2 * kvars + k;
            z   = *(st_info->st_numx + sel);
            if ( st_numbase[k] != z ) collisions_count = 1;
        }
    }

    /*********************************************************************
     *                Prompt user if there are collisions                *
     *********************************************************************/

    if ( collisions_count ) {
        sf_errprintf ("There may be 128-bit hash collisions: "
                      GT_size_cfmt" variables, "
                      GT_size_cfmt" obs ("
                      GT_size_cfmt", "
                      GT_size_cfmt")\n",
                      st_info->kvars_by, st_info->N, obs1, obs2);
        sf_errprintf ("This is likely a bug; please file a bug report at github.com/mcaceresb/stata-gtools/issues\n");

        rc = 17000;
    }

    free (s);
    free (st_strbase);
    free (st_strcomp);
    free (st_numbase);
    free (st_nummiss);

    return (rc);
}
