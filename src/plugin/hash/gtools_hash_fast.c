int sf_check_hash_fast (struct StataInfo *st_info, int level);
int sf_check_hash_fast (struct StataInfo *st_info, int level)
{
    GT_size i, j, k;
    GT_size kvars   = st_info->kvars_by;
    GT_size kstr    = st_info->kvars_by_str;
    ST_retcode rc  = 0;
    clock_t timer  = clock();
    clock_t stimer = clock();

    // NOTE(mauricio): strbuffer will remain 0 if level is 22 and
    // multisort will be skipped. // 2017-11-21 08:02 EST

    st_info->strbuffer = 0;
    if ( st_info->biject ) {
        goto bycopy;
    }

    /*********************************************************************
     *                               Setup                               *
     *********************************************************************/

    GT_bool multisort, skipbycopy;
    GT_size start, end, sel, selx, rowbytes;
    GTOOLS_MAX (st_info->byvars_lens, kvars, kmax, k);

    // Will compare string in st_strbase to st_strcomp and number as are being
    // read to numbers in st_numbase and st_nummiss
    GT_size collisions_count = 0;
    GT_size collisions_row   = 0;
    char *str_base, *str_cmp;
    ST_double *dbl_base, *dbl_cmp;

    /*********************************************************************
     *             Allocate memory to final collapsed array              *
     *********************************************************************/

    if ( kstr > 0 ) {
        for (j = 0; j < st_info->J; j++) {
            start = i = st_info->info[j];
            end   = st_info->info[j + 1];

            // The idea is to compare all group entries to the first group entry
            str_base = st_info->st_charx + st_info->ix[i] * st_info->rowbytes;

            // Check 2nd entry of group onward
            collisions_row = 0;
            for (i = start + 1; i < end; i++) {
                str_cmp = st_info->st_charx + st_info->ix[i] * st_info->rowbytes;
                if ( memcmp(str_base, str_cmp, st_info->rowbytes) ) ++collisions_row;
            }

            if ( collisions_row > 0 ) ++collisions_count;
        }
    }
    else {
        for (j = 0; j < st_info->J; j++) {
            start = i = st_info->info[j];
            end   = st_info->info[j + 1];

            // The idea is to compare all group entries to the first group entry
            dbl_base = st_info->st_numx + st_info->ix[i] * kvars;

            // Check 2nd entry of group onward
            collisions_row = 0;
            for (i = start + 1; i < end; i++) {
                dbl_cmp = st_info->st_numx + st_info->ix[i] * kvars;
                if ( memcmp(dbl_base, dbl_cmp, st_info->rowbytes) ) ++collisions_row;
            }

            if ( collisions_row > 0 ) ++collisions_count;
        }
    }

    if ( st_info->benchmark > 2 )
        sf_running_timer (&stimer, "\t\tPlugin step 4.1: Checked for hash collisions");

    /*********************************************************************
     *                Prompt user if there are collisions                *
     *********************************************************************/

    if ( collisions_count > 0 ) {
        sf_errprintf ("There may be "
                      GT_size_cfmt" 128-bit hash collisions: "
                      GT_size_cfmt" variables, "
                      GT_size_cfmt" obs, "
                      GT_size_cfmt" groups\n",
                      collisions_count, st_info->kvars_by, st_info->N, st_info->J);
        sf_errprintf ("This is likely a bug; please file a bug report at github.com/mcaceresb/stata-gtools/issues\n");

        rc = 17000; level = 0;
    }
    else {
        if ( st_info->verbose )
            sf_printf ("There were no hash collisions: "
                       GT_size_cfmt" variables, "
                       GT_size_cfmt" obs, "
                       GT_size_cfmt" groups\n",
                       st_info->kvars_by, st_info->N, st_info->J);
    }

    /*********************************************************************
     *              Read in copy of variables, if requested              *
     *********************************************************************/

    // Create a de-duplicated copy of the by variables. In some cases it is
    // useful to keep the copy in memory, but most of the time you just want
    // the sort. Hence we skip the step if the data is already sorted and we
    // won't use the by copy later.

bycopy:

    multisort  = (st_info->biject == 0) & (st_info->unsorted == 0) & (st_info->sorted == 0);
    rowbytes   = st_info->rowbytes + sizeof(GT_size);
    skipbycopy = ( (multisort == 0) & (level == 22) ) | st_info->countonly;

    // debug
    // -----
    // printf("debug 1: multisort = %u, skipby = %u\n", multisort, skipbycopy);
    // printf("\tdebug 2: biject    = %lu\n", st_info->biject);
    // printf("\tdebug 2: unsorted  = %d\n", st_info->unsorted);
    // printf("\tdebug 2: sorted    = %d\n", st_info->sorted);
    // printf("\tdebug 3: multisort = %d\n", multisort);
    // printf("\tdebug 3: level     = %d\n", level);
    // printf("\tdebug 3: countonly = %d\n", st_info->countonly);

    if ( (level > 0) & (skipbycopy == 0) ) {
        if ( kstr > 0 ) {
            st_info->strL_bybytes = malloc(sizeof(st_info->strL_bybytes));;
            st_info->st_by_numx   = malloc(sizeof(st_info->st_by_numx));
            st_info->st_by_charx  = calloc(st_info->J, rowbytes);

            if ( st_info->strL_bybytes == NULL ) return (sf_oom_error("sf_read_byvars", "st_info->strL_bybytes"));
            if ( st_info->st_by_numx   == NULL ) return (sf_oom_error("sf_read_byvars", "st_info->st_by_numx"));
            if ( st_info->st_by_charx  == NULL ) return (sf_oom_error("sf_read_byvars", "st_info->st_by_charx"));

            GTOOLS_GC_ALLOCATED("st_info->strL_bybytes")
            GTOOLS_GC_ALLOCATED("st_info->st_by_numx")
            GTOOLS_GC_ALLOCATED("st_info->st_by_charx")

            for (j = 0; j < st_info->J; j++) {
                memset (st_info->st_by_charx + j * rowbytes, '\0', rowbytes);
                sel = j * rowbytes + st_info->positions[kvars];
                memcpy (st_info->st_by_charx + sel, &j, sizeof(GT_size));
            }

            for (j = 0; j < st_info->J; j++) {
                for (k = 0; k < kvars; k++) {
                    sel  = st_info->ix[st_info->info[j]] * st_info->rowbytes + st_info->positions[k];
                    selx = j * rowbytes + st_info->positions[k];
                    if ( st_info->byvars_lens[k] > 0 ) {
                        memcpy (st_info->st_by_charx + selx,
                                st_info->st_charx + sel,
                                strlen(st_info->st_charx + sel));
                        st_info->strbuffer += strlen(st_info->st_charx + sel);
                    }
                    else {
                        memcpy (st_info->st_by_charx + selx,
                                st_info->st_charx + sel,
                                sizeof(ST_double));
                    }
                }
            }
        }
        else {
            st_info->strL_bybytes = malloc(sizeof(st_info->strL_bybytes));;
            st_info->st_by_numx   = calloc(st_info->J * (kvars + 1), sizeof(st_info->st_by_numx));
            st_info->st_by_charx  = malloc(sizeof(st_info->st_by_charx));

            if ( st_info->strL_bybytes == NULL ) return (sf_oom_error("sf_read_byvars", "st_info->strL_bybytes"));
            if ( st_info->st_by_numx   == NULL ) return (sf_oom_error("sf_read_byvars", "st_info->st_by_numx"));
            if ( st_info->st_by_charx  == NULL ) return (sf_oom_error("sf_read_byvars", "st_info->st_by_charx"));

            GTOOLS_GC_ALLOCATED("st_info->strL_bybytes")
            GTOOLS_GC_ALLOCATED("st_info->st_by_numx")
            GTOOLS_GC_ALLOCATED("st_info->st_by_charx")

            for (j = 0; j < st_info->J; j++) {
                for (k = 0; k < kvars; k++) {
                    sel  = st_info->ix[st_info->info[j]] * kvars + k;
                    selx = j * (kvars + 1) + k;
                    st_info->st_by_numx[selx] = st_info->st_numx[sel];
                }
                st_info->st_by_numx[j * (kvars + 1) + kvars] = j;
            }
        }

        if ( st_info->benchmark > 2 )
            sf_running_timer (&stimer, "\t\tPlugin step 4.2: Keep only one row per group");

        st_info->free = 6;

        // Skip if the user specifies the results need not be sorted
        // (unsorted, countonly). Also skip with the bijection, where
        // you get the sorting for free, or if we determined the data
        // was already sorted.
        //
        // Note here unsorted refers to the Stata option that tells
        // the plugin to not sort the data, whereas sorted refers
        // to the plugin's internal check that determined the data
        // was already sorted.

        if ( (level > 1) &  multisort ) {
            if ( kstr > 0 ) {
                if ( st_info->mlast ) {
                    MultiQuicksortMCMlast (st_info->st_by_charx,
                                           st_info->J,
                                           0,
                                           kvars - 1,
                                           rowbytes,
                                           st_info->byvars_lens,
                                           st_info->invert,
                                           st_info->positions);
                }
                else {
                    MultiQuicksortMC (st_info->st_by_charx,
                                      st_info->J,
                                      0,
                                      kvars - 1,
                                      rowbytes,
                                      st_info->byvars_lens,
                                      st_info->invert,
                                      st_info->positions);
                }
            }
            else {
                if ( st_info->mlast ) {
                    MultiQuicksortDblMlast(st_info->st_by_numx,
                                           st_info->J,
                                           0,
                                           kvars - 1,
                                           (kvars + 1) * sizeof(ST_double),
                                           st_info->invert);
                }
                else {
                    MultiQuicksortDbl(st_info->st_by_numx,
                                      st_info->J,
                                      0,
                                      kvars - 1,
                                      (kvars + 1) * sizeof(ST_double),
                                      st_info->invert);
                }
            }

            if ( st_info->benchmark > 2 )
                sf_running_timer (&stimer, "\t\tPlugin step 4.3: Sorted groups in memory");
        }
    }
    else {
        st_info->free = 8;
    }

    free (st_info->st_numx);
    free (st_info->st_charx);

    GTOOLS_GC_FREED("st_info->st_numx")
    GTOOLS_GC_FREED("st_info->st_charx")

    if ( st_info->N < st_info->Nread ) {
        free (st_info->ix);
        GTOOLS_GC_FREED("st_info->ix")
    }

    st_info->ix = calloc(st_info->J, sizeof(st_info->ix));
    if ( st_info->ix == NULL ) sf_oom_error ("sf_check_hash", "st_info->ix");
    GTOOLS_GC_ALLOCATED("st_info->ix")

    if ( (level > 0) & (skipbycopy == 0) ) {
        st_info->free = 7;
        if ( kstr > 0 ) {
            for (j = 0; j < st_info->J; j++) {
                st_info->ix[j] = *((GT_size *) (st_info->st_by_charx + j * rowbytes + st_info->positions[kvars]));
            }
        }
        else {
            for (j = 0; j < st_info->J; j++) {
                st_info->ix[j] = (GT_size) st_info->st_by_numx[j * (kvars + 1) + kvars];
            }
        }
    }
    else {
        // This should also apply if the data is already sorted, bijection, etc.
        // else if ( st_info->kvars_by == 0 ) {
        for (j = 0; j < st_info->J; j++)
            st_info->ix[j] = j;
    }

    if ( st_info->benchmark > 1 )
        sf_running_timer (&timer, "\tPlugin step 4: Created indexed array with sorted by vars");

    return (rc);
}
