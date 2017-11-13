/**
 * @brief index stata variables
 *
 * @param st_info Pointer to container structure for Stata info
 * @return indexes by variables in Stata
 */
ST_retcode sf_encode (struct StataInfo *st_info, int level)
{
    ST_retcode rc ;
    GT_size i, j, l, out;
    GT_size start, end, nobs, within, missval;
    GT_size kvars = st_info->kvars_by;
    clock_t  timer = clock();
    clock_t stimer = clock();

    if ( st_info->kvars_group < 1 ) {
        return (0);
    }

    GT_size group_targets[3];
    group_targets[0] = st_info->group_targets[0] + kvars;
    group_targets[1] = st_info->group_targets[1] + kvars;
    group_targets[2] = st_info->group_targets[2] + kvars;

    if ( st_info->group_targets[2] ) {
        if ( st_info->group_init[0] ) {
            if ( st_info->group_init[1] ) {
                for (i = 1; i <= SF_nobs(); i++) {
                    if ( (rc = SF_vstore(group_targets[0], i, SV_missval)) ) return (rc);
                    if ( (rc = SF_vstore(group_targets[1], i, SV_missval)) ) return (rc);
                    if ( (rc = SF_vstore(group_targets[2], i, 0))          ) return (rc);
                }
            }
            else {
                for (i = 1; i <= SF_nobs(); i++) {
                    if ( (rc = SF_vstore(group_targets[0], i, SV_missval)) ) return (rc);
                    if ( (rc = SF_vstore(group_targets[2], i, 0))          ) return (rc);
                }
            }
        }
        else if ( st_info->group_init[1] ) {
            for (i = 1; i <= SF_nobs(); i++) {
                if ( (rc = SF_vstore(group_targets[1], i, SV_missval)) ) return (rc);
                if ( (rc = SF_vstore(group_targets[2], i, 0))          ) return (rc);
            }
        }
        else {
            for (i = 1; i <= SF_nobs(); i++) {
                if ( (rc = SF_vstore(group_targets[2], i, 0)) ) return (rc);
            }
        }
    }
    else {
        if ( st_info->group_init[0] ) {
            if ( st_info->group_init[1] ) {
                for (i = 1; i <= SF_nobs(); i++) {
                    if ( (rc = SF_vstore(group_targets[0], i, SV_missval)) ) return (rc);
                    if ( (rc = SF_vstore(group_targets[1], i, SV_missval)) ) return (rc);
                }
            }
            else {
                for (i = 1; i <= SF_nobs(); i++) {
                    if ( (rc = SF_vstore(group_targets[0], i, SV_missval)) ) return (rc);
                }
            }
        }
        else if ( st_info->group_init[1] ) {
            for (i = 1; i <= SF_nobs(); i++) {
                if ( (rc = SF_vstore(group_targets[1], i, SV_missval)) ) return (rc);
            }
        }
    }

    within   = (st_info->group_data == 0);
    missval  = (st_info->group_val != SV_missval);

    // Special case for group
    if ( st_info->group_targets[0] & !(st_info->group_targets[1]) & !(st_info->group_targets[2]) ) {
        GT_size *eptr;
        GT_size *encoding = calloc(GTOOLS_PWMAX(st_info->N, st_info->Nread), sizeof *encoding);
        if ( encoding  == NULL ) return (sf_oom_error("sf_encoding", "encoding"));

        if ( st_info->N < st_info->Nread ) {
            for (eptr = encoding; eptr < encoding + st_info->Nread; eptr++)
                *eptr = 0;

            for (j = 0; j < st_info->J; j++) {
                l      = st_info->ix[j];
                start  = st_info->info[l];
                end    = st_info->info[l + 1];
                for (i = start; i < end; i++) {
                    encoding[st_info->index[i]] = j + 1;
                }
            }

            if ( st_info->benchmark )
                sf_running_timer (&stimer, "\t\tPlugin step 5.1: Generated encoding in Stata order");

            eptr = encoding;
            for (i = 0; i < st_info->Nread; i++, eptr++) {
                if ( *eptr ) {
                    if ( (rc = SF_vstore(group_targets[0], i + st_info->in1, *eptr)) ) return (rc);
                }
            }

            if ( st_info->benchmark )
                sf_running_timer (&stimer, "\t\tPlugin step 5.2: Copied back encoding to Stata");
        }
        else {
            for (j = 0; j < st_info->J; j++) {
                l      = st_info->ix[j];
                start  = st_info->info[l];
                end    = st_info->info[l + 1];
                for (i = start; i < end; i++) {
                    encoding[st_info->index[i]] = j + 1;
                }
            }

            if ( st_info->benchmark )
                sf_running_timer (&stimer, "\t\tPlugin step 5.1: Generated encoding in Stata order");

            eptr = encoding;
            for (i = 0; i < st_info->N; i++, eptr++) {
                if ( (rc = SF_vstore(group_targets[0], i + st_info->in1, *eptr)) ) return (rc);
            }

            if ( st_info->benchmark )
                sf_running_timer (&stimer, "\t\tPlugin step 5.2: Copied back encoding to Stata");
        }

        free (encoding);
    }
    else {
        for (j = 0; j < st_info->J; j++) {
            l      = st_info->ix[j];
            start  = st_info->info[l];
            end    = st_info->info[l + 1];
            nobs   = end - start;
            out    = st_info->index[start] + st_info->in1;
            if ( st_info->group_targets[2] ) {
                if ( (rc = SF_vstore(group_targets[2], out, 1)) ) return (rc);
            }
            if ( st_info->group_targets[1] ) {
                if ( st_info->group_data ) {
                    if ( (rc = SF_vstore(group_targets[1], j + 1, nobs)) ) return (rc);
                }
                else {
                    if ( (rc = SF_vstore(group_targets[1], out, nobs)) ) return (rc);
                }
            }
            if ( st_info->group_targets[0] ) {
                if ( (rc = SF_vstore(group_targets[0], out, j + 1)) ) return (rc);
            }

            for (i = start + 1; i < end; i++) {
                out = st_info->index[i] + st_info->in1;
                if ( st_info->group_targets[1] ) {
                    if ( st_info->group_fill ) {
                        if ( missval ) {
                            if ( (rc = SF_vstore(group_targets[1], out, st_info->group_val)) ) return (rc);
                        }
                    }
                    else if ( within ) {
                        if ( (rc = SF_vstore(group_targets[1], out, nobs)) ) return (rc);
                    }
                }
                if ( st_info->group_targets[0] ) {
                    if ( (rc = SF_vstore(group_targets[0], out, j + 1)) ) return (rc);
                }
            }
        }
    }

    if ( st_info->benchmark )
        sf_running_timer (&timer, "\tPlugin step 5: Copied back encoding to Stata");

    return (0);
}
