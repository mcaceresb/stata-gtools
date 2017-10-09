/**
 * @brief tag stata variables
 *
 * @param st_info Pointer to container structure for Stata info
 * @return Tags first obs of gorup in Stata
 */
int sf_egen_tag (struct StataInfo *st_info)
{
    ST_double z ;
    ST_retcode rc ;
    int i, j, k, out;
    size_t start, end, minj;
    clock_t timer = clock();

    size_t *indexj = calloc(st_info->J, sizeof *indexj);
    uint64_t *firstj = calloc(st_info->J, sizeof *firstj);

    if ( indexj == NULL ) return(sf_oom_error("sf_collapse", "indexj"));
    if ( firstj == NULL ) return(sf_oom_error("sf_collapse", "firstj"));

    // Since we hash the data, the order in C has to be mapped to the order
    // in Stata via info and index. First figure out the order in which the
    // groups appear in Stata, and then write by looping over groups in that
    // order.

    for (j = 0; j < st_info->J; j++) {
        start = st_info->info[j];
        end   = st_info->info[j + 1];
        while ( !SF_ifobs(st_info->in1 + st_info->index[start]) & (start < end) ) {
            start++;
        }
        minj = st_info->index[start];
        for (i = start + 1; i < end; i++) {
            if ( SF_ifobs(st_info->in1 + st_info->index[i]) ) {
                if ( minj > st_info->index[i] ) minj = st_info->index[i];
            }
        }
        firstj[j] = minj;
        indexj[j] = j;
    }

    // indexj[j] will contain the order in which the jth C group appeared
    rc = mf_radix_sort_index (firstj, indexj, st_info->J, RADIX_SHIFT, 0, st_info->verbose);
    if ( rc ) return(rc);
    if ( st_info->benchmark ) sf_running_timer (&timer, "\tPlugin step 5.1: Tagged groups in memory");

    // We loop in C using indexj and write to Stata based on index
    k = st_info->start_target_vars;
    for (j = 0; j < st_info->J; j++) {
        start = st_info->info[indexj[j]];
        end   = st_info->info[indexj[j] + 1];
        while ( !SF_ifobs(st_info->in1 + st_info->index[start]) & (start < end) ) {
            start++;
        }
        if ( start < end ) {
            out = st_info->index[start] + st_info->in1;
            if ( (rc = SF_vstore(k, out, 1)) ) return (rc);
        }
    }

    // Tag ignores if/in for missing values (all non-tagged are 0)
    for (i = 1; i <= SF_nobs(); i++) {
        if ( (rc = SF_vdata(k, i, &z)) ) return(rc);
        if ( SF_is_missing(z) ) {
            if ( (rc = SF_vstore(k, i, 0)) ) return (rc);
        }
    }
    if ( st_info->benchmark ) sf_running_timer (&timer, "\tPlugin step 5.2: Copied tag to Stata");

    free (indexj);
    free (firstj);

    return(0);
}

/**
 * @brief index stata variables
 *
 * @param st_info Pointer to container structure for Stata info
 * @return indexes by variables in Stata
 */
int sf_egen_group (struct StataInfo *st_info)
{
    ST_retcode rc ;
    short augment_id;
    int i, j, k, l, out;
    size_t start, end, nobs;
    clock_t timer = clock();

    MixedUnion *st_dtax;
    double *st_numx;
    size_t kvars = st_info->kvars_by + st_info->kvars_targets;
    if ( st_info->read_dtax & st_info->sort_memory ) {
        st_dtax = st_info->st_dtax;
        st_numx = st_info->st_numx;
        if ( st_info->kvars_by_str > 0 ) {
            for (j = 0; j < st_info->J; j++)
                st_dtax[(j + 1) * kvars - 1].dval = j;

            MultiQuicksort (st_dtax, st_info->J, 0, st_info->kvars_by - 1,
                            kvars * sizeof(*st_dtax), st_info->byvars_lens, st_info->invert);

            if ( st_info->benchmark ) sf_running_timer (&timer, "\tPlugin step 5.1: Indexed groups in memory");

            if ( st_info->group_count ) {
                if ( st_info->group_fill ) {
                    for (j = 0; j < st_info->J; j++) {
                        l      = (int) st_dtax[(j + 1) * kvars - 1].dval;
                        start  = st_info->info[l];
                        end    = st_info->info[l + 1];
                        nobs   = end - start;
                        out    = st_info->index[start] + st_info->in1;
                        if ( (rc = SF_vstore(st_info->start_target_vars,     out, j + 1)) ) return (rc);
                        if ( (rc = SF_vstore(st_info->start_target_vars + 1, out, nobs))  ) return (rc);
                        for (i = start + 1; i < end; i++) {
                            out = st_info->index[i] + st_info->in1;
                            if ( (rc = SF_vstore(st_info->start_target_vars, out, j + 1)) ) return (rc);
                            if ( (rc = SF_vstore(st_info->start_target_vars + 1, out, st_info->group_val)) ) return (rc);
                        }
                    }
                }
                else if ( st_info->group_data ) {
                    for (j = 0; j < st_info->J; j++) {
                        l      = (int) st_dtax[(j + 1) * kvars - 1].dval;
                        start  = st_info->info[l];
                        end    = st_info->info[l + 1];
                        nobs   = end - start;
                        if ( (rc = SF_vstore(st_info->start_target_vars + 1, j + 1, nobs)) ) return (rc);
                        for (i = start; i < end; i++) {
                            out = st_info->index[i] + st_info->in1;
                            if ( (rc = SF_vstore(st_info->start_target_vars, out, j + 1)) ) return (rc);
                        }
                    }
                }
                else {
                    for (j = 0; j < st_info->J; j++) {
                        l      = (int) st_dtax[(j + 1) * kvars - 1].dval;
                        start  = st_info->info[l];
                        end    = st_info->info[l + 1];
                        nobs   = end - start;
                        for (i = start; i < end; i++) {
                            out = st_info->index[i] + st_info->in1;
                            if ( (rc = SF_vstore(st_info->start_target_vars,     out, j + 1)) ) return (rc);
                            if ( (rc = SF_vstore(st_info->start_target_vars + 1, out, nobs))  ) return (rc);
                        }
                    }
                }
            }
            else {
                k = 1;    
                for (j = 0; j < st_info->J; j++) {
                    augment_id = 0;
                    l      = (int) st_dtax[(j + 1) * kvars - 1].dval;
                    start  = st_info->info[l];
                    end    = st_info->info[l + 1];
                    for (i = start; i < end; i++) {
                        out = st_info->index[i] + st_info->in1;
                        if ( SF_ifobs(out) ) {
                            if ( (rc = SF_vstore(st_info->start_target_vars, out, k)) ) return (rc);
                            augment_id = 1;
                        }
                    }
                    k += augment_id;
                }
            }

            if ( st_info->benchmark ) sf_running_timer (&timer, "\tPlugin step 5.2: Copied index to Stata");

            for (j = 0; j < st_info->J; j++) {
                for (k = 0; k < st_info->kvars_by_str; k++) {
                    free(st_dtax[j * kvars + (st_info->pos_str_byvars[k] - 1)].cval);
                }
            }
        }
        else {
            for (j = 0; j < st_info->J; j++)
                st_numx[(j + 1) * kvars - 1] = j;

            MultiQuicksort2 (st_numx, st_info->J, 0, st_info->kvars_by - 1,
                             kvars * sizeof(*st_numx), st_info->byvars_lens, st_info->invert);

            if ( st_info->benchmark ) sf_running_timer (&timer, "\tPlugin step 5.1: Indexed groups in memory");

            if ( st_info->group_count ) {
                if ( st_info->group_fill ) {
                    for (j = 0; j < st_info->J; j++) {
                        l      = (int) st_numx[(j + 1) * kvars - 1];
                        start  = st_info->info[l];
                        end    = st_info->info[l + 1];
                        out    = st_info->index[i] + st_info->in1;
                        nobs   = end - start;
                        out    = st_info->index[start] + st_info->in1;
                        if ( (rc = SF_vstore(st_info->start_target_vars,     out, j + 1)) ) return (rc);
                        if ( (rc = SF_vstore(st_info->start_target_vars + 1, out, nobs))  ) return (rc);
                        for (i = start + 1; i < end; i++) {
                            out = st_info->index[i] + st_info->in1;
                            if ( (rc = SF_vstore(st_info->start_target_vars, out, j + 1)) ) return (rc);
                            if ( (rc = SF_vstore(st_info->start_target_vars + 1, out, st_info->group_val)) ) return (rc);
                        }
                    }
                }
                else if ( st_info->group_data ) {
                    for (j = 0; j < st_info->J; j++) {
                        l      = (int) st_numx[(j + 1) * kvars - 1];
                        start  = st_info->info[l];
                        end    = st_info->info[l + 1];
                        out    = st_info->index[i] + st_info->in1;
                        nobs   = end - start;
                        if ( (rc = SF_vstore(st_info->start_target_vars + 1, j + 1, nobs))  ) return (rc);
                        for (i = start; i < end; i++) {
                            out = st_info->index[i] + st_info->in1;
                            if ( (rc = SF_vstore(st_info->start_target_vars, out, j + 1)) ) return (rc);
                        }
                    }
                }
                else {
                    for (j = 0; j < st_info->J; j++) {
                        l      = (int) st_numx[(j + 1) * kvars - 1];
                        start  = st_info->info[l];
                        end    = st_info->info[l + 1];
                        out    = st_info->index[i] + st_info->in1;
                        nobs   = end - start;
                        for (i = start; i < end; i++) {
                            out = st_info->index[i] + st_info->in1;
                            if ( (rc = SF_vstore(st_info->start_target_vars,     out, j + 1)) ) return (rc);
                            if ( (rc = SF_vstore(st_info->start_target_vars + 1, out, nobs))  ) return (rc);
                        }
                    }
                }
            }
            else {
                k = 1;    
                for (j = 0; j < st_info->J; j++) {
                    augment_id = 0;
                    l      = (int) st_numx[(j + 1) * kvars - 1];
                    start  = st_info->info[l];
                    end    = st_info->info[l + 1];
                    for (i = start; i < end; i++) {
                        out = st_info->index[i] + st_info->in1;
                        if ( SF_ifobs(out) ) {
                            if ( (rc = SF_vstore(st_info->start_target_vars, out, k)) ) return (rc);
                            augment_id = 1;
                        }
                    }
                    k += augment_id;
                }
            }

            if ( st_info->benchmark ) sf_running_timer (&timer, "\tPlugin step 5.2: Copied index to Stata");
        }

        free (st_info->output);
        free (st_dtax);
        free (st_numx);
    }
    else {

        if ( st_info->group_count ) {
            if ( st_info->group_fill ) {
                for (j = 0; j < st_info->J; j++) {
                    start  = st_info->info[j];
                    end    = st_info->info[j + 1];
                    nobs   = end - start;
                    out    = st_info->index[start] + st_info->in1;
                    if ( (rc = SF_vstore(st_info->start_target_vars,     out, j + 1)) ) return (rc);
                    if ( (rc = SF_vstore(st_info->start_target_vars + 1, out, nobs)) ) return (rc);
                    for (i = start + 1; i < end; i++) {
                        out = st_info->index[i] + st_info->in1;
                        if ( (rc = SF_vstore(st_info->start_target_vars,     out, j + 1)) ) return (rc);
                        if ( (rc = SF_vstore(st_info->start_target_vars + 1, out, st_info->group_val)) ) return (rc);
                    }
                }
                if ( st_info->benchmark ) sf_running_timer (&timer, "\tPlugin step 5.1: Copied index to Stata");
            }
            else if ( st_info->group_data ) {
                for (j = 0; j < st_info->J; j++) {
                    start  = st_info->info[j];
                    end    = st_info->info[j + 1];
                    nobs   = end - start;
                    if ( (rc = SF_vstore(st_info->start_target_vars + 1, j + 1, nobs)) ) return (rc);
                    for (i = start; i < end; i++) {
                        out = st_info->index[i] + st_info->in1;
                        if ( (rc = SF_vstore(st_info->start_target_vars, out, j + 1)) ) return (rc);
                    }
                }
                if ( st_info->benchmark ) sf_running_timer (&timer, "\tPlugin step 5.1: Copied index to Stata");
            }
            else {
                for (j = 0; j < st_info->J; j++) {
                    start  = st_info->info[j];
                    end    = st_info->info[j + 1];
                    nobs   = end - start;
                    for (i = start; i < end; i++) {
                        out = st_info->index[i] + st_info->in1;
                        if ( (rc = SF_vstore(st_info->start_target_vars,     out, j + 1)) ) return (rc);
                        if ( (rc = SF_vstore(st_info->start_target_vars + 1, out, nobs)) ) return (rc);
                    }
                }
                if ( st_info->benchmark ) sf_running_timer (&timer, "\tPlugin step 5.1: Copied index to Stata");
            }
        }
        else {
            for (j = 0; j < st_info->J; j++) {
                start  = st_info->info[j];
                end    = st_info->info[j + 1];
                for (i = start; i < end; i++) {
                    out = st_info->index[i] + st_info->in1;
                    if ( (rc = SF_vstore(st_info->start_target_vars, out, j + 1)) ) return (rc);
                }
            }
            if ( st_info->benchmark ) sf_running_timer (&timer, "\tPlugin step 5.1: Copied index to Stata");
        }

        // size_t *indexj = calloc(st_info->N, sizeof *indexj);
        // for (i = 0; i < st_info->N; i++) {
        //     if ( SF_ifobs(st_info->in1 + i) ) {
        //         if ( (rc = SF_vstore(st_info->start_target_vars, st_info->in1 + i, indexj[i])) ) return (rc);
        //     }
        // }
        // free (indexj);
    }
    return (0);
}
