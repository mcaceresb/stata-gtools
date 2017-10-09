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
int sf_check_hash_index (struct StataInfo *st_info, int read_dtax)
{

    // If all intergers, there should not be a need to check the 'hash'
    // since the mapping to the natural numbers shouldn't give collisions.
    // #MathIsOnOurSide.

    if ( st_info->integers_ok ) {
        st_info->read_dtax = 0;
        return (0);
    }

    /*********************************************************************
     *                               Setup                               *
     *********************************************************************/

    int i, j, k;
    size_t start, end, sel, selx, numpos, strpos, slen, kvars;
    size_t l_str  = 0;
    size_t k_num  = 0;
    size_t k1     = 1;
    size_t k2     = st_info->kvars_by;
    size_t K      = k2 - k1 + 1;
    int    kmax   = mf_max_signed(st_info->byvars_lens, K);
    clock_t timer = clock();

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
    char *s = malloc(klen * sizeof(char)); memset (s, '\0', klen);
    char *st_strbase = malloc(l_str * sizeof(char)); memset (st_strbase, '\0', l_str);
    char *st_strcomp = malloc(l_str * sizeof(char)); memset (st_strcomp, '\0', l_str);

    if ( st_strbase == NULL ) return(sf_oom_error("sf_check_hash_index", "st_strbase"));
    if ( st_strcomp == NULL ) return(sf_oom_error("sf_check_hash_index", "st_strcomp"));

    double *st_numbase = calloc(k_num > 0? k_num: 1, sizeof *st_numbase);
    short  *st_nummiss = calloc(k_num > 0? k_num: 1, sizeof *st_nummiss);

    if ( st_numbase == NULL ) return(sf_oom_error("sf_check_hash_index", "st_numbase"));
    if ( st_nummiss == NULL ) return(sf_oom_error("sf_check_hash_index", "st_nummiss"));

    size_t collisions_count = 0;
    size_t collisions_row   = 0;

    /*********************************************************************
     *             Allocate memory to final collapsed array              *
     *********************************************************************/

    st_info->strbuffer = 0;
    kvars = (st_info->kvars_by + st_info->kvars_targets);
    if ( read_dtax & st_info->sort_memory ) {
        st_info->read_dtax = 1;
        if ( st_info->kvars_by_str > 0 ) {

            /*********************************************************************
             *           Mixed type (string and numeric by variables)            *
             *********************************************************************/

            // If there are string variables, use a mixed type container
            st_info->st_dtax = calloc(kvars * st_info->J, sizeof(st_info->st_dtax));
            if ( st_info->st_dtax == NULL )
                return (sf_oom_error("sf_check_hash_index", "st_info->st_dtax"));

            // In this case, you need to allocate time for all the strings
            for (j = 0; j < st_info->J; j++) {
                for (k = 0; k < st_info->kvars_by_str; k++) {
                    sel  = j * kvars + (st_info->pos_str_byvars[k] - 1);
                    slen = st_info->byvars_lens[st_info->pos_str_byvars[k] - 1];
                    if ( slen > 0 ) {
                        st_info->st_dtax[sel].cval = malloc((slen + 1) * sizeof(char));
                        if ( st_info->st_dtax[sel].cval == NULL )
                            return (sf_oom_error("sf_check_hash_index", "st_info->st_dtax[sel].cval"));
                        memset (st_info->st_dtax[sel].cval, '\0', slen + 1);
                    }
                    else {
                        sf_errprintf ("Unable to parse string lengths from Stata.\n");
                        return (198);
                    }
                }
            }
            st_info->st_numx = malloc(sizeof(double));
            st_info->output  = malloc(sizeof(double));

            // Loop through each group's observations
            for (j = 0; j < st_info->J; j++) {
                memset (st_strbase, '\0', l_str);
                start  = i = st_info->info[j];
                end    = st_info->info[j + 1];
                sel    = st_info->index[i] + st_info->in1;
                numpos = 0;
                strpos = 0;
                for (k = 0; k < k_num; k++)
                    st_nummiss[k] = 0;

                // The idea is to compare all group entries to the first group entry
                // -----------------------------------------------------------------

                for (k = 0; k < K; k++) {
                    selx = j * kvars + k;
                    if ( st_info->byvars_lens[k] > 0 ) {
                        if ( (rc = SF_sdata(k + k1, sel, st_info->st_dtax[selx].cval)) ) return(rc);
                        memcpy (st_strbase + strpos, st_info->st_dtax[selx].cval, strlen(st_info->st_dtax[selx].cval));
                        strpos = strlen(st_strbase);
                    }
                    else {
                        if ( (rc = SF_vdata(k + k1, sel, &(st_info->st_dtax[selx].dval))) ) return(rc);
                        if ( SF_is_missing(st_info->st_dtax[selx].dval) ) {
                            st_nummiss[numpos] = 1;
                        }
                        else {
                            st_numbase[numpos] = st_info->st_dtax[selx].dval;
                        }
                        ++numpos;
                    }
                }
                st_info->strbuffer += strpos;

                // Check 2nd entry of group onward
                // -------------------------------

                for (i = start + 1; i < end; i++) {
                    memset (st_strcomp, '\0', l_str);
                    collisions_row = 0;
                    numpos = 0;
                    strpos = 0;
                    sel    = st_info->index[i] + st_info->in1;
                    for (k = 0; k < K; k++) {
                        if ( st_info->byvars_lens[k] > 0 ) {
                            // Concatenate string and compare result
                            if ( (rc = SF_sdata(k + k1, sel, st_strcomp + strpos)) ) return(rc);
                            strpos = strlen(st_strcomp);
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

                    if ( kmax > 0 ) {
                        if ( (strlen (st_strbase) != strlen (st_strcomp)) ) {
                            // sf_printf ("collision (i = %lu; group %lu from %lu to %lu):\n",
                            //            st_info->index[i], j, st_info->info[j], st_info->info[j + 1]);
                            // sf_printf ("\t(%lu) %s\n", strlen(st_strbase), st_strbase);
                            // sf_printf ("\t(%lu) %s\n", strlen(st_strcomp), st_strcomp);
                            ++collisions_row;
                        }
                        else if ( strncmp(st_strbase, st_strcomp, strlen(st_strcomp)) != 0 ) {
                            // sf_printf ("collision (i = %lu; group %lu from %lu to %lu):\n",
                            //            st_info->index[i], j, st_info->info[j], st_info->info[j + 1]);
                            // sf_printf ("\t(%lu) %s\n", strlen(st_strbase), st_strbase);
                            // sf_printf ("\t(%lu) %s\n", strlen(st_strcomp), st_strcomp);
                            ++collisions_row;
                        }
                    }
                    if ( collisions_row > 0 ) ++collisions_count;
                }
            }
        }
        else {

            /*********************************************************************
             *                           Numeric only                            *
             *********************************************************************/

            // If only numbers, just allocate a double array
            st_info->st_dtax = malloc(sizeof(MixedUnion));
            st_info->output  = malloc(sizeof(double));
            st_info->st_numx = calloc(kvars * st_info->J, sizeof(st_info->st_numx));
            if ( st_info->st_numx  == NULL )
                return(sf_oom_error("sf_check_hash_index", "st_info->st_numx"));

            // Loop through each group's observations
            for (j = 0; j < st_info->J; j++) {
                start  = i = st_info->info[j];
                end    = st_info->info[j + 1];
                sel    = st_info->index[i] + st_info->in1;
                for (k = 0; k < k_num; k++)
                    st_nummiss[k] = 0;

                for (k = 0; k < K; k++) {
                    selx = j * kvars + k;
                    if ( (rc = SF_vdata(k + k1, sel, &(st_info->st_numx[selx]))) ) return(rc);
                    if ( SF_is_missing(st_info->st_numx[selx]) ) {
                        st_nummiss[k] = 1;
                    }
                    else {
                        st_numbase[k] = st_info->st_numx[selx];
                    }
                }

                // Check 2nd entry of group onward
                // -------------------------------

                for (i = start + 1; i < end; i++) {
                    collisions_row = 0;
                    sel = st_info->index[i] + st_info->in1;
                    for (k = 0; k < K; k++) {
                        // Compare each number individually
                        if ( (rc = SF_vdata(k + k1, sel, &z)) ) return(rc);
                        if ( SF_is_missing(z) ) {
                            if ( !st_nummiss[k] ) ++collisions_row;
                        }
                        else {
                            if ( st_numbase[k] != z ) ++collisions_row;
                        }
                    }
                    if ( collisions_row > 0 ) ++collisions_count;
                }
            }
        }
    }
    else {
        st_info->read_dtax = 0;

        /*********************************************************************
         *        Check for collisions without saving group variables        *
         *********************************************************************/

        // Loop through each group's observations
        for (j = 0; j < st_info->J; j++) {
            memset (st_strbase, '\0', l_str);
            start  = i = st_info->info[j];
            end    = st_info->info[j + 1];
            sel    = st_info->index[i] + st_info->in1;
            numpos = 0;
            strpos = 0;
            for (k = 0; k < k_num; k++)
                st_nummiss[k] = 0;

            // The idea is to compare all group entries to the first group entry
            // -----------------------------------------------------------------

            for (k = 0; k < K; k++) {
                if ( st_info->byvars_lens[k] > 0 ) {
                    // Concatenate string and compare result
                    if ( (rc = SF_sdata(k + k1, sel, st_strbase + strpos)) ) return(rc);
                    strpos = strlen(st_strbase);
                }
                else {
                    // Compare each number individually
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
            st_info->strbuffer += strpos;

            /***************
             *  debugging  *
             ***************
            sf_printf ("Checking: strings = '");
            sf_printf (st_strbase);
            sf_printf ("' and numbers = ");
            for (k = 0; k < k_num; k++) {
                if ( st_nummiss[k] ) {
                    sf_printf ("[missing], ");
                }
                else {
                    sf_printf ("%.5f, ", st_numbase[k]);
                }
            }
            sf_printf ("vs:\n");
             ***************
             *  debugging  *
             ***************/

            // Check 2nd entry of group onward
            // -------------------------------

            for (i = start + 1; i < end; i++) {
                memset (st_strcomp, '\0', l_str);
                collisions_row = 0;
                numpos = 0;
                strpos = 0;
                sel    = st_info->index[i] + st_info->in1;
                for (k = 0; k < K; k++) {
                    if (st_info->byvars_lens[k] > 0) {
                        // Concatenate string and compare result
                        if ( (rc = SF_sdata(k + k1, sel, st_strcomp + strpos)) ) return(rc);
                        strpos = strlen(st_strcomp);
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

                /***************
                 *  debugging  *
                 ***************
                sf_printf ("\tstrings = '");
                sf_printf (st_strbase);
                sf_printf ("' and numbers = ");
                for (k = 0; k < k_num; k++) {
                    if ( st_nummiss[k] ) {
                        sf_printf ("[missing], ");
                    }
                    else {
                        sf_printf ("%.5f, ", st_numbase[k]);
                    }
                }
                sf_printf ("\n");
                 ***************
                 *  debugging  *
                 ***************/

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
    }
    if ( st_info->benchmark ) sf_running_timer (&timer, "\tPlugin step 5.0: Checked for hash collisions");

    /*********************************************************************
     *      Finish (prompt user for bug report if collisions happen      *
     *********************************************************************/

    if ( collisions_count > 0 ) {
        sf_errprintf ("There may be "FMT" 128-bit hash collisions: "FMT" variables, "FMT" obs, "FMT" groups\n",
                      collisions_count, st_info->kvars_by, st_info->N, st_info->J);
        sf_errprintf ("This is likely a bug; please file a bug report at github.com/mcaceresb/stata-gtools/issues\n");

        free(s);
        free(st_strbase);
        free(st_strcomp);

        return (42000);
    }
    else {
        if ( st_info->verbose )
            sf_printf ("There were no hash collisions: "FMT" variables, "FMT" obs, "FMT" groups\n",
                       st_info->kvars_by, st_info->N, st_info->J);
    }

    free (s);
    free (st_strbase);
    free (st_strcomp);
    free (st_numbase);
    free (st_nummiss);

    return(0);
}

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
int sf_check_hashsort (struct StataInfo *st_info)
{

    // If all intergers, there should not be a need to check the 'hash'
    // since the mapping to the natural numbers shouldn't give collisions.
    // #MathIsOnOurSide.

    if ( st_info->integers_ok ) {
        st_info->read_dtax = 0;
        return (0);
    }

    /*********************************************************************
     *                               Setup                               *
     *********************************************************************/

    int i, j, k;
    size_t start, end, sel, selx, numpos, strpos, kvars;
    size_t l_str  = 0;
    size_t k_num  = 0;
    size_t k1     = 1;
    size_t k2     = st_info->kvars_by;
    size_t K      = k2 - k1 + 1;
    int    kmax   = mf_max_signed(st_info->byvars_lens, K);
    clock_t timer = clock();

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

    char *st_strbase = malloc(l_str * sizeof(char));
    char *st_strcomp = malloc(l_str * sizeof(char));

    if ( st_strbase == NULL ) return(sf_oom_error("sf_check_hashsort", "st_strbase"));
    if ( st_strcomp == NULL ) return(sf_oom_error("sf_check_hashsort", "st_strcomp"));

    double *st_numbase = calloc(k_num > 0? k_num: 1, sizeof *st_numbase);
    short  *st_nummiss = calloc(k_num > 0? k_num: 1, sizeof *st_nummiss);

    size_t collisions_count = 0;
    size_t collisions_row   = 0;

    /*********************************************************************
     *             Allocate memory to final collapsed array              *
     *********************************************************************/

    st_info->strbuffer = 0;
    st_info->read_dtax = 1;
    kvars = (st_info->kvars_by + 1);

    if ( st_info->kvars_by_str > 0 ) {

        /*********************************************************************
         *           Mixed type (string and numeric by variables)            *
         *********************************************************************/

        int ilen;
        size_t rowbytes, selrow;
        size_t *positions = calloc(kvars, sizeof *positions);
        if ( positions == NULL ) return(sf_oom_error("sf_check_hashsort", "positions"));

        positions[0] = rowbytes = 0;
        for (k = 1; k < kvars; k++) {
            ilen = st_info->byvars_lens[k - 1];
            if ( ilen > 0 ) {
                positions[k] = positions[k - 1] + (ilen + 1);
                rowbytes    += ((ilen + 1) * sizeof(char));
            }
            else {
                positions[k] = positions[k - 1] + sizeof(double);
                rowbytes    += sizeof(double);
            }
        }
        rowbytes += sizeof(int);

        st_info->st_charx  = calloc(st_info->J, rowbytes * sizeof(char));
        if ( st_info->st_charx == NULL ) return (sf_oom_error("sf_check_hashsort", "st_info->st_charx"));

        // In this case, you need to clean all the chunks
        for (j = 0; j < st_info->J; j++) {
            memset (st_info->st_charx + j * rowbytes, '\0', rowbytes);
            sel = j * rowbytes + positions[st_info->kvars_by];
            // i   = st_info->index[st_info->info[j]];
            memcpy (st_info->st_charx + sel, &j, sizeof(int));
        }

        // Loop through each group's observations
        for (j = 0; j < st_info->J; j++) {
            memset (st_strbase, '\0', l_str);
            start  = i = st_info->info[j];
            end    = st_info->info[j + 1];
            sel    = st_info->index[i] + st_info->in1;
            selrow = j * rowbytes;
            numpos = 0;
            strpos = 0;
            for (k = 0; k < k_num; k++)
                st_nummiss[k] = 0;

            // The idea is to compare all group entries to the first group entry
            // -----------------------------------------------------------------

            for (k = 0; k < K; k++) {
                selx = selrow + positions[k];
                if ( st_info->byvars_lens[k] > 0 ) {
                    if ( (rc = SF_sdata(k + k1, sel, st_info->st_charx + selx)) ) return(rc);
                    memcpy (st_strbase + strpos, st_info->st_charx + selx, strlen(st_info->st_charx + selx));
                    strpos = strlen(st_strbase);
                }
                else {
                    if ( (rc = SF_vdata(k + k1, sel, &z)) ) return(rc);
                    memcpy (st_info->st_charx + selx, &z, sizeof(double));
                    if ( SF_is_missing(z) ) {
                        st_nummiss[numpos] = 1;
                    }
                    else {
                        st_numbase[numpos] = z;
                    }
                    ++numpos;
                }
            }
            st_info->strbuffer += strpos;

            // Check 2nd entry of group onward
            // -------------------------------

            for (i = start + 1; i < end; i++) {
                memset (st_strcomp, '\0', l_str);
                collisions_row = 0;
                numpos = 0;
                strpos = 0;
                sel    = st_info->index[i] + st_info->in1;
                for (k = 0; k < K; k++) {
                    if ( st_info->byvars_lens[k] > 0 ) {
                        // Concatenate string and compare result
                        if ( (rc = SF_sdata(k + k1, sel, st_strcomp + strpos)) ) return(rc);
                        strpos = strlen(st_strcomp);
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

        free (positions);
    }
    else {

        /*********************************************************************
         *                           Numeric only                            *
         *********************************************************************/

        // If only numbers, just allocate a double array
        st_info->st_numx = calloc(kvars * st_info->J, sizeof(st_info->st_numx));
        if ( st_info->st_numx  == NULL ) return(sf_oom_error("sf_check_hash_index", "st_info->st_numx"));

        // Loop through each group's observations
        for (j = 0; j < st_info->J; j++) {
            start  = i = st_info->info[j];
            end    = st_info->info[j + 1];
            sel    = st_info->index[i] + st_info->in1;
            for (k = 0; k < k_num; k++)
                st_nummiss[k] = 0;

            for (k = 0; k < K; k++) {
                selx = j * kvars + k;
                if ( (rc = SF_vdata(k + k1, sel, &(st_info->st_numx[selx]))) ) return(rc);
                if ( SF_is_missing(st_info->st_numx[selx]) ) {
                    st_nummiss[k] = 1;
                }
                else {
                    st_numbase[k] = st_info->st_numx[selx];
                }
            }
            st_info->st_numx[j * kvars + K] = j;
            // st_info->st_numx[j * kvars + K] = st_info->index[start];

            // Check 2nd entry of group onward
            // -------------------------------

            for (i = start + 1; i < end; i++) {
                collisions_row = 0;
                sel = st_info->index[i] + st_info->in1;
                for (k = 0; k < K; k++) {
                    // Compare each number individually
                    if ( (rc = SF_vdata(k + k1, sel, &z)) ) return(rc);
                    if ( SF_is_missing(z) ) {
                        if ( !st_nummiss[k] ) ++collisions_row;
                    }
                    else {
                        if ( st_numbase[k] != z ) ++collisions_row;
                    }
                }
                if ( collisions_row > 0 ) ++collisions_count;
            }
        }
    }

    if ( st_info->benchmark ) sf_running_timer (&timer, "\tPlugin step 5.0: Checked for hash collisions");

    /*********************************************************************
     *      Finish (prompt user for bug report if collisions happen      *
     *********************************************************************/

    if ( collisions_count > 0 ) {
        sf_errprintf ("There may be "FMT" 128-bit hash collisions: "FMT" variables, "FMT" obs, "FMT" groups\n",
                      collisions_count, st_info->kvars_by, st_info->N, st_info->J);
        sf_errprintf ("This is likely a bug; please file a bug report at github.com/mcaceresb/stata-gtools/issues\n");

        free(st_strbase);
        free(st_strcomp);

        return (42000);
    }
    else {
        if ( st_info->verbose )
            sf_printf ("There were no hash collisions: "FMT" variables, "FMT" obs, "FMT" groups\n",
                       st_info->kvars_by, st_info->N, st_info->J);
    }

    free (st_strbase);
    free (st_strcomp);
    free (st_numbase);
    free (st_nummiss);

    return(0);
}
