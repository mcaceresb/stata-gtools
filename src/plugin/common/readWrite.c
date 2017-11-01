ST_retcode sf_read_byvars (
    struct StataInfo *st_info,
    int level,
    GT_size *index
);

ST_retcode gf_bijection_limits (
    struct StataInfo *st_info,
    int level
);


ST_retcode sf_read_byvars (
    struct StataInfo *st_info,
    int level,
    GT_size *index)
{
    ST_retcode rc = 0;
    ST_double z;

    GT_size i, k, sel, obs;
    GT_size rowbytes   = st_info->rowbytes;
    GT_size N          = st_info->N;
    GT_size in1        = st_info->in1;
    GT_size kvars      = st_info->kvars_by;
    GT_size kstr       = st_info->kvars_by_str;
    GT_size *positions = st_info->positions;

    // index = calloc(N, sizeof(index));
    // if ( index == NULL ) return (sf_oom_error("sf_read_byvars", "index"));
    // GTOOLS_GC_ALLOCATED("index")

    if ( kstr > 0 ) {
        st_info->st_numx  = malloc(sizeof(ST_double));
        st_info->st_charx = calloc(N, rowbytes);

        if ( st_info->st_numx  == NULL ) return (sf_oom_error("sf_read_byvars", "st_info->st_numx"));
        if ( st_info->st_charx == NULL ) return (sf_oom_error("sf_read_byvars", "st_info->st_charx"));

        GTOOLS_GC_ALLOCATED("st_info->st_numx")
        GTOOLS_GC_ALLOCATED("st_info->st_charx")

        st_info->free = 3;

        // In this case, you need to clean all the chunks
        for (i = 0; i < N; i++)
            memset (st_info->st_charx + i * rowbytes, '\0', rowbytes);

        // Loop through all the by variables
        obs = 0;
        if ( st_info->any_if || (st_info->missing == 0) ) {
            if ( st_info->any_if & (st_info->missing == 0) ) {
                for (i = 0; i < N; i++) {
                    if ( SF_ifobs(i + in1) ) {
                        for (k = 0; k < kvars; k++) {
                            sel = obs * rowbytes + positions[k];
                            if ( st_info->byvars_lens[k] > 0 ) {
                                if ( (rc = SF_sdata(k + 1, i + in1, st_info->st_charx + sel)) )
                                    goto exit;

                                if ( strcmp(st_info->st_charx + sel, "") == 0 ) {
                                    if ( st_info->nomiss ) {
                                        rc = 459;
                                        goto exit;
                                    }
                                    memset (st_info->st_charx + obs * rowbytes, '\0', rowbytes);
                                    goto next_inner1;
                                }
                            }
                            else {
                                if ( (rc = SF_vdata(k + 1, i + in1, &z)) )
                                    goto exit;

                                if ( SF_is_missing(z) ) {
                                    if ( st_info->nomiss ) {
                                        rc = 459;
                                        goto exit;
                                    }
                                    memset (st_info->st_charx + obs * rowbytes, '\0', rowbytes);
                                    goto next_inner1;
                                }
                                memcpy (st_info->st_charx + sel, &z, sizeof(ST_double));
                            }
                        }
                        index[obs] = i;
                        ++obs;
next_inner1: continue;
                    }
                }
            }
            else if ( st_info->any_if & (st_info->missing == 1) ) {
                for (i = 0; i < N; i++) {
                    if ( SF_ifobs(i + in1) ) {
                        for (k = 0; k < kvars; k++) {
                            sel = obs * rowbytes + positions[k];
                            if ( st_info->byvars_lens[k] > 0 ) {
                                if ( (rc = SF_sdata(k + 1, i + in1, st_info->st_charx + sel)) )
                                    goto exit;
                            }
                            else {
                                if ( (rc = SF_vdata(k + 1, i + in1, &z)) )
                                    goto exit;
                                memcpy (st_info->st_charx + sel, &z, sizeof(ST_double));
                            }
                        }
                        index[obs] = i;
                        ++obs;
                    }
                }
            }
            else if ( (st_info->any_if == 0) & (st_info->missing == 0) ) {
                for (i = 0; i < N; i++) {
                    for (k = 0; k < kvars; k++) {
                        sel = obs * rowbytes + positions[k];
                        if ( st_info->byvars_lens[k] > 0 ) {
                            if ( (rc = SF_sdata(k + 1, i + in1, st_info->st_charx + sel)) )
                                goto exit;

                            if ( strcmp(st_info->st_charx + sel, "") == 0 ) {
                                if ( st_info->nomiss ) {
                                    rc = 459;
                                    goto exit;
                                }
                                memset (st_info->st_charx + obs * rowbytes, '\0', rowbytes);
                                goto next_inner2;
                            }
                        }
                        else {
                            if ( (rc = SF_vdata(k + 1, i + in1, &z)) )
                                goto exit;

                            if ( SF_is_missing(z) ) {
                                if ( st_info->nomiss ) {
                                    rc = 459;
                                    goto exit;
                                }
                                memset (st_info->st_charx + obs * rowbytes, '\0', rowbytes);
                                goto next_inner2;
                            }
                            memcpy (st_info->st_charx + sel, &z, sizeof(ST_double));
                        }
                    }
                    index[obs] = i;
                    ++obs;
next_inner2: continue;
                }
            }
            N = st_info->N = obs;
        }
        else {
            for (i = 0; i < N; i++) {
                index[i] = i;
                for (k = 0; k < kvars; k++) {
                    sel = i * rowbytes + positions[k];
                    if ( st_info->byvars_lens[k] > 0 ) {
                        if ( (rc = SF_sdata(k + 1, i + in1, st_info->st_charx + sel)) )
                            goto exit;
                    }
                    else {
                        if ( (rc = SF_vdata(k + 1, i + in1, &z)) ) goto exit;
                        memcpy (st_info->st_charx + sel, &z, sizeof(ST_double));
                    }
                }
            }
        }
    }
    else {
        st_info->st_numx  = calloc(N * kvars, sizeof(st_info->st_numx));
        st_info->st_charx = malloc(sizeof(char));

        if ( st_info->st_numx  == NULL ) return (sf_oom_error("sf_hash_byvars", "st_info->st_numx"));
        if ( st_info->st_charx == NULL ) return (sf_oom_error("sf_hash_byvars", "st_info->st_charx"));

        GTOOLS_GC_ALLOCATED("st_info->st_numx")
        GTOOLS_GC_ALLOCATED("st_info->st_charx")

        st_info->free = 3;

        // Loop through all the by variables
        obs = 0;
        if ( st_info->any_if || (st_info->missing == 0) ) {
            if ( st_info->any_if & (st_info->missing == 0) ) {
                for (i = 0; i < N; i++) {
                    if ( SF_ifobs(i + in1) ) {
                        for (k = 0; k < kvars; k++) {
                            sel = obs * kvars + k;
                            if ( (rc = SF_vdata(k + 1, i + in1, st_info->st_numx + sel)) )
                                goto exit;

                            if ( SF_is_missing(st_info->st_numx[sel]) ) {
                                if ( st_info->nomiss ) {
                                    rc = 459;
                                    goto exit;
                                }
                                goto next_inner3;
                            }
                        }
                        index[obs] = i;
                        ++obs;
next_inner3: continue;
                    }
                }
            }
            else if ( st_info->any_if & (st_info->missing == 1) ) {
                for (i = 0; i < N; i++) {
                    if ( SF_ifobs(i + in1) ) {
                        for (k = 0; k < kvars; k++) {
                            sel = obs * kvars + k;
                            if ( (rc = SF_vdata(k + 1, i + in1, st_info->st_numx + sel)) )
                                goto exit;
                        }
                        index[obs] = i;
                        ++obs;
                    }
                }
            }
            else if ( (st_info->any_if == 0) & (st_info->missing == 0) ) {
                for (i = 0; i < N; i++) {
                    for (k = 0; k < kvars; k++) {
                        sel = obs * kvars + k;
                        if ( (rc = SF_vdata(k + 1, i + in1, st_info->st_numx + sel)) )
                            goto exit;

                        if ( SF_is_missing(st_info->st_numx[sel]) ) {
                            if ( st_info->nomiss ) {
                                rc = 459;
                                goto exit;
                            }
                            goto next_inner4;
                        }
                    }
                    index[obs] = i;
                    ++obs;
next_inner4: continue;
                }
            }
            N = st_info->N = obs;
        }
        else {
            for (i = 0; i < N; i++) {
                index[i] = i;
                for (k = 0; k < kvars; k++) {
                    sel = i * kvars + k;
                    if ( (rc = SF_vdata(k + 1, i + in1, st_info->st_numx + sel)) )
                        goto exit;
                }
            }
        }
    }

exit:
    return (rc);
}

/*********************************************************************
 *            Check whether to hash or to use a bijection            *
 *********************************************************************/

ST_retcode gf_bijection_limits (
    struct StataInfo *st_info,
    int level)
{

    ST_retcode rc = 0;
    ST_double z;
    GT_size i, k, worst, range;
    GT_size N     = st_info->N;
    GT_size kvars = st_info->kvars_by;
    GT_size kint  = st_info->kvars_by_int;

    ST_double *double_mins = calloc(kvars, sizeof *double_mins);
    ST_double *double_maxs = calloc(kvars, sizeof *double_maxs);
    GT_bool   *any_missing = calloc(kvars, sizeof *any_missing);
    GT_bool   *all_missing = calloc(kvars, sizeof *all_missing);

    if ( double_mins == NULL ) return (sf_oom_error("gf_bijection_limits", "double_mins"));
    if ( double_maxs == NULL ) return (sf_oom_error("gf_bijection_limits", "double_maxs"));
    if ( any_missing == NULL ) return (sf_oom_error("gf_bijection_limits", "any_missing"));
    if ( all_missing == NULL ) return (sf_oom_error("gf_bijection_limits", "all_missing"));

    GTOOLS_GC_ALLOCATED("double_mins")
    GTOOLS_GC_ALLOCATED("double_maxs")
    GTOOLS_GC_ALLOCATED("any_missing")
    GTOOLS_GC_ALLOCATED("all_missing")

    // If only integers, check worst case of the bijection would not
    // overflow. Given K by variables, by_1 to by_K, where by_k belongs to the
    // set B_k, the general problem we face is devising a function f such that
    // f: B_1 x ... x B_K -> N, where N are the natural (whole) numbers. For
    // integers, we don't need to hash the data:
    //
    //     1. The first variable: z[i, 1] = f(1)(x[i, 1]) = x[i, 1] - min(x[, 1]) + 1
    //     2. The kth variable: z[i, k] = f(k)(x[i, k]) = i * range(z[, k - 1]) + (x[i, k - 1] - min(x[, 2]))
    //
    // If we have too many by variables, it is possible our integers will
    // overflow. We check whether this may happen below.

    if ( kint == kvars ) {
        if ( st_info->verbose )
            sf_printf("Bijection OK with all integers (i.e. no extended miss val)? ");

        st_info->biject = 1;
        for (k = 0; k < kvars; k++) {
            double_maxs[k] = double_mins[k] = 0;
            any_missing[k] = 0;
            all_missing[k] = 1;
        }

        for (i = 0; i < N; i++) {
            for (k = 0; k < kvars; k++) {
                z = *(st_info->st_numx + (i * kvars + k));
                if ( z > SV_missval ) {
                    st_info->biject = 0;
                    if ( st_info->verbose ) sf_printf("No; using hash.\n");
                    goto exit;
                }
                else {
                    if ( SF_is_missing(z) ) {
                        any_missing[k] = 1;
                    }
                    else if ( all_missing[k] ) {
                        all_missing[k] = 0;
                        double_mins[k] = z;
                        double_maxs[k] = z;
                    }
                    else {
                        if ( z < double_mins[k] ) double_mins[k]  = z;
                        if ( z > double_maxs[k] ) double_maxs[k]  = z;
                    }
                }
            }
        }
    }
    else {
        if ( st_info->verbose )
            sf_printf("Bijection OK with all numbers (i.e. no doubles)? ");

        st_info->biject = 1;
        for (k = 0; k < kvars; k++) {
            double_maxs[k] = double_mins[k] = 0;
            any_missing[k] = 0;
            all_missing[k] = 1;
        }

        for (i = 0; i < N; i++) {
            for (k = 0; k < kvars; k++) {
                z = *(st_info->st_numx + (i * kvars + k));
                if ( !((ceilf(z) == z) || (z == SV_missval)) ) {
                    st_info->biject = 0;
                    if ( st_info->verbose ) sf_printf("No; using hash.\n");
                    goto exit;
                }
                else {
                    if ( SF_is_missing(z) ) {
                        any_missing[k] = 1;
                    }
                    else if ( all_missing[k] ) {
                        all_missing[k] = 0;
                        double_mins[k] = z;
                        double_maxs[k] = z;
                    }
                    else {
                        if ( z < double_mins[k] ) double_mins[k]  = z;
                        if ( z > double_maxs[k] ) double_maxs[k]  = z;
                    }
                }
            }
        }
    }

    // Check whether bijection might overflow.
    if ( st_info->biject ) {
        for (k = 0; k < kvars; k++) {
            st_info->byvars_mins[k] = (GT_int) (double_mins[k]);
            st_info->byvars_maxs[k] = (GT_int) (double_maxs[k]) + any_missing[k];
        }
        worst = st_info->byvars_maxs[0] - st_info->byvars_mins[0] + 1;
        range = st_info->byvars_maxs[1] - st_info->byvars_mins[1] + 1;
        for (k = 1; k < kvars; k++) {
            if ( worst > (GTOOLS_BIJECTION_LIMIT / range)  ) {
                if ( st_info->verbose ) {
                    sf_printf("No.\n");
                    sf_printf("Values OK but range ("
                              GT_size_cfmt" * "
                              GT_size_cfmt") too large; falling back on hash.\n",
                              worst, range);
                }
                st_info->biject = 0;
                goto exit;
            }
            else {
                worst *= range;
                range  = st_info->byvars_maxs[k] - st_info->byvars_mins[k] + (k < (kvars - 1));
            }
        }
        if ( st_info->verbose ) sf_printf("Yes.\n");
    }

exit:

    free (any_missing);
    free (all_missing);
    free (double_mins);
    free (double_maxs);

    GTOOLS_GC_FREED("any_missing")
    GTOOLS_GC_FREED("all_missing")
    GTOOLS_GC_FREED("double_mins")
    GTOOLS_GC_FREED("double_maxs")

    return (rc);
}
