ST_retcode sf_xtile_by (struct StataInfo *st_info, int level);

ST_retcode sf_xtile_by (struct StataInfo *st_info, int level)
{

    ST_double z, w, nqdbl;
    ST_double *xptr, *wptr, *qptr, *qptr2, *optr, *gptr, *xptr2;
    GT_size   *jptr, *stptr, *cptr;

    GT_bool failmiss = 0;
    GT_size i, j, l, q, sel, obs, start, end, cstart, cend, nj, ixstart;
    ST_retcode rc = 0;
    clock_t  timer = clock();
    clock_t stimer = clock();

    /*********************************************************************
     *                           Step 1: Setup                           *
     *********************************************************************/

    GT_size nq      = st_info->xtile_nq;
    GT_size nq2     = st_info->xtile_nq2;
    GT_size ncuts   = st_info->xtile_ncuts;
    GT_size cutvars = st_info->xtile_cutvars;
    GT_size qvars   = st_info->xtile_qvars;
    GT_size npoints = 0;
    GT_size nquants = 0;

    GT_bool weights = st_info->wcode > 0;
    GT_size kgen    = st_info->xtile_gen;
    GT_bool pctile  = st_info->xtile_pctile;
    GT_bool genpct  = st_info->xtile_genpct;
    GT_bool pctpct  = st_info->xtile_pctpct;
    GT_size kpctile = pctile + pctpct + genpct;
    GT_size xstart  = kgen + kpctile;

    GT_bool cstartj = st_info->xtile_cutby & (cutvars | qvars);
    GT_bool altdef  = st_info->xtile_altdef;
    GT_bool debug   = st_info->debug;

    // NOT ALLOWED WITH BY
    // GT_bool _pctile  = st_info->xtile__pctile;
    // GT_bool bincount = st_info->xtile_bincount;
    // GT_bool minmax   = st_info->xtile_minmax;
    // GT_bool method   = st_info->xtile_method;

    GT_size kvars          = st_info->kvars_by;
    GT_size ksources       = st_info->kvars_sources;
    GT_size ktargets       = st_info->kvars_targets;
    GT_size start_sources  = kvars + st_info->kvars_group + 1;
    GT_size start_targets  = start_sources + ksources;
    GT_size start_xtile    = start_targets + ktargets;
    GT_size start_genpct   = start_xtile   + kgen + pctile + pctpct;
    GT_size start_cutvars  = start_xtile   + xstart;
    GT_size start_qvars    = start_cutvars + cutvars;
    GT_size start_xsources = start_qvars   + qvars;
    GT_size wpos           = st_info->wpos;

    GT_size in1   = st_info->in1;
    GT_size Nread = st_info->Nread;
    GT_size N     = st_info->N;
    GT_size J     = st_info->J;

    GT_size nout;
    nout = GTOOLS_PWMAX(nq,   (nq2 + 1));
    nout = GTOOLS_PWMAX(nout, (ncuts + 1));
    nout = GTOOLS_PWMAX(nout, 1);

    if ( debug ) {
        sf_printf_debug("debug 1 (sf_xtile_by): read in meta info\n");
        sf_printf_debug("\t"GT_size_cfmt" obs, "GT_size_cfmt" read, "GT_size_cfmt" groups.\n", N, Nread, J);
        sf_printf_debug("\tin1 / in2: "GT_size_cfmt" / "GT_size_cfmt"\n", st_info->in1, st_info->in2);
        sf_printf_debug("\taltdef:    %u\n",  altdef);
        sf_printf_debug("\tkgen:      %d\n",  (kgen > 0));
        sf_printf_debug("\txpctile:   %u\n",  pctile);
        sf_printf_debug("\txpctpct:   %u\n",  pctpct);
        sf_printf_debug("\tcutifin:   %u\n",  st_info->xtile_cutifin);
        sf_printf_debug("\tcutby:     %u\n",  st_info->xtile_cutby);
        sf_printf_debug("\tnq:        "GT_size_cfmt"\n", nq);
        sf_printf_debug("\tnq2:       "GT_size_cfmt"\n", nq2);
        sf_printf_debug("\tncuts:     "GT_size_cfmt"\n", ncuts);
        sf_printf_debug("\tqvars:     "GT_size_cfmt"\n", qvars);
        sf_printf_debug("\tcutvars:   "GT_size_cfmt"\n", cutvars);
    }

    /*********************************************************************
     *                         Memory Allocation                         *
     *********************************************************************/

    GT_size kx = kgen? (2 + weights): (1 + weights);
    GT_size xmem_sources = kx * N;
    GT_size xmem_points  = cutvars?
        (
            st_info->xtile_cutby?  N + J:
            (
                st_info->xtile_cutifin?  Nread + 1: SF_nobs() + 1
            )
        ): 1;
    GT_size xmem_quants  = qvars?
        (
            st_info->xtile_cutby?  N + J:
            (
                st_info->xtile_cutifin?  Nread + 1: SF_nobs() + 1
            )
        ): 1;

    ST_double *xsources = calloc(xmem_sources, sizeof *xsources);
    ST_double *xpoints  = calloc(xmem_points,  sizeof *xpoints);
    ST_double *xquants  = calloc(xmem_quants,  sizeof *xquants);

    if ( xsources == NULL ) return(sf_oom_error("sf_quantiles", "xsources"));
    if ( xpoints  == NULL ) return(sf_oom_error("sf_quantiles", "xpoints"));
    if ( xquants  == NULL ) return(sf_oom_error("sf_quantiles", "xquants"));

    GT_size *index_st       = calloc(Nread, sizeof *index_st);
    GT_size *offsets_buffer = calloc(J,     sizeof *offsets_buffer);
    GT_size *all_nonmiss    = calloc(J,     sizeof *all_nonmiss);
    GT_size *points_nonmiss = calloc(J,     sizeof *points_nonmiss);
    GT_size *nj_buffer      = calloc(J,     sizeof *nj_buffer);

    if ( index_st       == NULL ) return(sf_oom_error("sf_quantiles_by", "index_st"));
    if ( offsets_buffer == NULL ) return(sf_oom_error("sf_quantiles_by", "offsets_buffer"));
    if ( all_nonmiss    == NULL ) return(sf_oom_error("sf_quantiles_by", "all_nonmiss"));
    if ( points_nonmiss == NULL ) return(sf_oom_error("sf_quantiles_by", "points_nonmiss"));
    if ( nj_buffer      == NULL ) return(sf_oom_error("sf_quantiles_by", "nj_buffer"));

    if ( debug ) {
        sf_printf_debug("debug 2 (sf_xtile_by): allocated memory\n");
        sf_printf_debug("\txmem_sources: "GT_size_cfmt"\n", xmem_sources);
        sf_printf_debug("\txmem_points:  "GT_size_cfmt"\n", xmem_points);
        sf_printf_debug("\txmem_quants:  "GT_size_cfmt"\n", xmem_quants);
    }

    /*********************************************************************
     *                     Cutvars and cutquantiles                      *
     *********************************************************************/

    obs = 0;
    if ( st_info->xtile_cutifin & (st_info->xtile_cutby == 0) ) {
        if ( st_info->any_if ) {
            if ( cutvars ) {
                if ( debug ) {
                    sf_printf_debug("debug 3 (sf_xtile_by): any_if, cutvars, cutifin, and no cutby\n");
                }

                for (i = 0; i < Nread; i++) {
                    if ( SF_ifobs(i + in1) ) {
                        if ( (rc = SF_vdata(start_cutvars,
                                            i + in1,
                                            xpoints + obs++)) ) goto error;
                    }
                }
                npoints = obs;
            }

            if ( qvars ) {
                if ( debug ) {
                    sf_printf_debug("debug 3 (sf_xtile_by): any_if, qvars, cutifin, and no cutby\n");
                }

                for (i = 0; i < Nread; i++) {
                    if ( SF_ifobs(i + in1) ) {
                        if ( (rc = SF_vdata(start_qvars,
                                            i + in1,
                                            xquants + obs++)) ) goto error;
                    }
                }
                nquants = obs;
            }
        }
        else {
            if ( cutvars ) {
                if ( debug ) {
                    sf_printf_debug("debug 3 (sf_xtile_by): no any_if, cutvars, cutifin, and no cutby\n");
                }

                for (i = 0; i < Nread; i++) {
                    if ( (rc = SF_vdata(start_cutvars,
                                        i + in1,
                                        xpoints + i)) ) goto error;
                }
                npoints = Nread;
            }

            if ( qvars ) {
                if ( debug ) {
                    sf_printf_debug("debug 3 (sf_xtile_by): no any_if, qvars, cutifin, and no cutby\n");
                }

                for (i = 0; i < Nread; i++) {
                    if ( (rc = SF_vdata(start_qvars,
                                        i + in1,
                                        xquants + i)) ) goto error;
                }
                nquants = Nread;
            }
        }
    }
    else if ( st_info->xtile_cutby == 0 ) {
        if ( cutvars ) {
            if ( debug ) {
                sf_printf_debug("debug 3 (sf_xtile_by): cutvars, no cutifin, and no cutby\n");
            }

            for (i = 0; i < SF_nobs(); i++) {
                if ( (rc = SF_vdata(start_cutvars,
                                    i + 1,
                                    xpoints + i)) ) goto error;
            }
            npoints = SF_nobs();
        }

        if ( qvars ) {
            if ( debug ) {
                sf_printf_debug("debug 3 (sf_xtile_by): qvars, no cutifin, and no cutby\n");
            }

            for (i = 0; i < SF_nobs(); i++) {
                if ( (rc = SF_vdata(start_qvars,
                                    i + 1,
                                    xquants + i)) ) goto error;
            }
            nquants = SF_nobs();
        }
    }

    if ( debug ) {
        sf_printf_debug("debug 4 (sf_xtile_by): npoints = "GT_size_cfmt
                        ", nquants = "GT_size_cfmt"\n", npoints, nquants);
    }

    /*********************************************************************
     *           Adjust percentiles or curoffs, if applicable            *
     *********************************************************************/

    if ( st_info->xtile_cutby ) {
        failmiss = (ncuts > 0);
        if ( debug ) {
            sf_printf_debug("debug 5 (sf_xtile_by): failmiss with cutby = %u\n", failmiss);
        }
    }
    else {
        failmiss = (ncuts > 0) | (npoints > 0) | (nquants > 0);
        npoints  = (npoints == 0)? 0: gf_xtile_clean(xpoints, npoints, 1, st_info->xtile_dedup);
        nquants  = (nquants == 0)? 0: gf_xtile_clean(xquants, nquants, 1, st_info->xtile_dedup);
        if ( debug ) {
            sf_printf_debug("debug 5 (sf_xtile_by): failmiss with no cutby = %u\n", failmiss);
            sf_printf_debug("debug 5 (sf_xtile_by): npoints = "GT_size_cfmt
                            ", nquants = "GT_size_cfmt"\n", npoints, nquants);
        }
    }

    nq2   = (nq2   == 0)? 0: gf_xtile_clean(st_info->xtile_quantiles, nq2,   1, st_info->xtile_dedup);
    ncuts = (ncuts == 0)? 0: gf_xtile_clean(st_info->xtile_cutoffs,   ncuts, 1, st_info->xtile_dedup);
    if ( debug ) {
        sf_printf_debug("debug 6 (sf_xtile_by): nq2 = "GT_size_cfmt
                        ", ncuts = "GT_size_cfmt"\n", nq2, ncuts);
    }

    if ( failmiss & (ncuts == 0) & (npoints == 0) & (nquants == 0) ) {
        if ( (ncuts == 0) & (npoints == 0) ) {
            sf_errprintf("all cutoff values are missing\n");
            rc = 198;
            goto error;
        }
        else if ( nquants == 0 ) {
            sf_errprintf("all quantile values are missing\n");
            rc = 198;
            goto error;
        }
    }

    if ( nquants > 0 ) {
        for (gptr = xquants; gptr < xquants + nquants; gptr += 1) {
            if ( (*gptr <= 0) || (*gptr >= 100) ) {
                sf_errprintf("cutquantiles() requires a variable with values strictly between 0 and 100\n");
                rc = 198;
                goto error;
            }
        }
    }

    if ( nq2 > 0 ) {
        for (gptr = st_info->xtile_quantiles; gptr < st_info->xtile_quantiles + nq2; gptr += 1) {
            if ( (*gptr <= 0) || (*gptr >= 100) ) {
                sf_errprintf("quantiles() requires a numlist with values strictly between 0 and 100\n");
                rc = 198;
                goto error;
            }
        }
    }

    if ( st_info->benchmark > 1 ) {
        if ( (ncuts > 0) || (npoints > 0) ) {
            sf_running_timer (&timer, "\txtile step 1: De-duplicated cutoff list");
        }
        else if ( (nq2 > 0) || (nquants > 0) ) {
            sf_running_timer (&timer, "\txtile step 1: De-duplicated quantile list");
        }
    }
    stimer = clock();

    /*********************************************************************
     *                      Select execution method                      *
     *********************************************************************/

    nout = GTOOLS_PWMAX(nout, (npoints + 1));
    nout = GTOOLS_PWMAX(nout, (nquants + 1));

    // method ignored and everything is sorted! may bring back method later.

    /*********************************************************************
     *                   Read in the source variables                    *
     *********************************************************************/

    if ( debug ) {
        sf_printf_debug("debug 7 (sf_xtile_by): Will read from Stata in order.\n");
    }

    for (i = 0; i < Nread; i++)
        index_st[i] = 0;

    for (j = 0; j < J; j++) {
        l      = st_info->ix[j];
        start  = st_info->info[l];
        end    = st_info->info[l + 1];

        points_nonmiss[j] = 0;
        all_nonmiss[j]    = 0;
        offsets_buffer[j] = start;
        nj_buffer[j]      = end - start;

        for (i = start; i < end; i++)
            index_st[st_info->index[i]] = l + 1;
    }

    if ( debug ) {
        sf_printf_debug("debug 8 (sf_xtile_by): Set up index_st.\n");
    }

    i = 0;
    if ( st_info->xtile_cutby & (cutvars | qvars) ) {
        nout    = GTOOLS_PWMAX(nout, (st_info->nj_max + 1));
        npoints = cutvars? st_info->nj_max: 0;
        nquants = qvars?   st_info->nj_max: 0;

        if ( cutvars ) {
            if ( kgen ) {
                if ( debug ) {
                    sf_printf_debug("debug 9 (sf_xtile_by): cutvars, kgen, and cutby.\n");
                }

                if ( weights ) {
                    for (stptr = index_st; stptr < index_st + Nread; stptr++, i++) {
                        if ( *stptr ) {
                            j     = *stptr - 1;
                            start = st_info->info[j];
                            sel   = start + j + points_nonmiss[j]++;
                            if ( (rc = SF_vdata(start_cutvars,
                                                i + in1,
                                                xpoints + sel)) ) goto error;

                            if ( (rc = SF_vdata(start_xsources, i + in1, &z)) ) goto error;
                            if ( SF_is_missing(z) ) continue;

                            if ( (rc = SF_vdata(wpos, i + in1, &w)) ) goto error;
                            if ( SF_is_missing(w) ) continue;

                            sel = kx * start + kx * all_nonmiss[j]++;
                            xsources[sel]     = z;
                            xsources[sel + 1] = w;
                            xsources[sel + 2] = i;
                        }
                    }
                }
                else {
                    for (stptr = index_st; stptr < index_st + Nread; stptr++, i++) {
                        if ( *stptr ) {
                            j     = *stptr - 1;
                            start = st_info->info[j];
                            sel   = start + j + points_nonmiss[j]++;
                            if ( (rc = SF_vdata(start_cutvars,
                                                i + in1,
                                                xpoints + sel)) ) goto error;

                            if ( (rc = SF_vdata(start_xsources, i + in1, &z)) ) goto error;
                            if ( SF_is_missing(z) ) continue;
                            sel = kx * start + kx * all_nonmiss[j]++;
                            xsources[sel]     = z;
                            xsources[sel + 1] = i;
                        }
                    }
                }
            }
            else {
                if ( debug ) {
                    sf_printf_debug("debug 9 (sf_xtile_by): cutvars, no kgen, and cutby.\n");
                }

                if ( weights ) {
                    for (stptr = index_st; stptr < index_st + Nread; stptr++, i++) {
                        if ( *stptr ) {
                            j     = *stptr - 1;
                            start = st_info->info[j];
                            sel   = start + j + points_nonmiss[j]++;
                            if ( (rc = SF_vdata(start_cutvars,
                                                i + in1,
                                                xpoints + sel)) ) goto error;

                            if ( (rc = SF_vdata(start_xsources, i + in1, &z)) ) goto error;
                            if ( SF_is_missing(z) ) continue;

                            if ( (rc = SF_vdata(wpos, i + in1, &w)) ) goto error;
                            if ( SF_is_missing(w) ) continue;

                            sel = start + all_nonmiss[j]++;
                            xsources[sel]     = z;
                            xsources[sel + 1] = w;
                        }
                    }
                }
                else {
                    for (stptr = index_st; stptr < index_st + Nread; stptr++, i++) {
                        if ( *stptr ) {
                            j     = *stptr - 1;
                            start = st_info->info[j];
                            sel   = start + j + points_nonmiss[j]++;
                            if ( (rc = SF_vdata(start_cutvars,
                                                i + in1,
                                                xpoints + sel)) ) goto error;

                            if ( (rc = SF_vdata(start_xsources, i + in1, &z)) ) goto error;
                            if ( SF_is_missing(z) ) continue;
                            sel = start + all_nonmiss[j]++;
                            xsources[sel] = z;
                        }
                    }
                }
            }
        }

        if ( qvars ) {
            if ( kgen ) {
                if ( debug ) {
                    sf_printf_debug("debug 9 (sf_xtile_by): qvars, kgen, and cutby.\n");
                }

                if ( weights ) {
                    for (stptr = index_st; stptr < index_st + Nread; stptr++, i++) {
                        if ( *stptr ) {
                            j     = *stptr - 1;
                            start = st_info->info[j];
                            sel   = start + j + points_nonmiss[j]++;
                            if ( (rc = SF_vdata(start_qvars,
                                                i + in1,
                                                xquants + sel)) ) goto error;

                            if ( (rc = SF_vdata(start_xsources, i + in1, &z)) ) goto error;
                            if ( SF_is_missing(z) ) continue;

                            if ( (rc = SF_vdata(wpos, i + in1, &w)) ) goto error;
                            if ( SF_is_missing(w) ) continue;

                            sel = kx * start + kx * all_nonmiss[j]++;
                            xsources[sel]     = z;
                            xsources[sel + 1] = w;
                            xsources[sel + 2] = i;
                        }
                    }
                }
                else {
                    for (stptr = index_st; stptr < index_st + Nread; stptr++, i++) {
                        if ( *stptr ) {
                            j     = *stptr - 1;
                            start = st_info->info[j];
                            sel   = start + j + points_nonmiss[j]++;
                            if ( (rc = SF_vdata(start_qvars,
                                                i + in1,
                                                xquants + sel)) ) goto error;

                            if ( (rc = SF_vdata(start_xsources, i + in1, &z)) ) goto error;
                            if ( SF_is_missing(z) ) continue;
                            sel = kx * start + kx * all_nonmiss[j]++;
                            xsources[sel]     = z;
                            xsources[sel + 1] = i;
                        }
                    }
                }
            }
            else {
                if ( debug ) {
                    sf_printf_debug("debug 9 (sf_xtile_by): qvars, no kgen, and cutby.\n");
                }

                if ( weights ) {
                    for (stptr = index_st; stptr < index_st + Nread; stptr++, i++) {
                        if ( *stptr ) {
                            j     = *stptr - 1;
                            start = st_info->info[j];
                            sel   = start + j + points_nonmiss[j]++;
                            if ( (rc = SF_vdata(start_qvars,
                                                i + in1,
                                                xquants + sel)) ) goto error;

                            if ( (rc = SF_vdata(start_xsources, i + in1, &z)) ) goto error;
                            if ( SF_is_missing(z) ) continue;

                            if ( (rc = SF_vdata(wpos, i + in1, &w)) ) goto error;
                            if ( SF_is_missing(w) ) continue;

                            sel = start + all_nonmiss[j]++;
                            xsources[sel]     = z;
                            xsources[sel + 1] = w;
                        }
                    }
                }
                else {
                    for (stptr = index_st; stptr < index_st + Nread; stptr++, i++) {
                        if ( *stptr ) {
                            j     = *stptr - 1;
                            start = st_info->info[j];
                            sel   = start + j + points_nonmiss[j]++;
                            if ( (rc = SF_vdata(start_qvars,
                                                i + in1,
                                                xquants + sel)) ) goto error;

                            if ( (rc = SF_vdata(start_xsources, i + in1, &z)) ) goto error;
                            if ( SF_is_missing(z) ) continue;

                            sel = start + all_nonmiss[j]++;
                            xsources[sel] = z;
                        }
                    }
                }
            }
        }
    }
    else {
        if ( kgen ) {
            if ( debug ) {
                sf_printf_debug("debug 9 (sf_xtile_by): kgen, no cutby.\n");
            }

            if ( weights ) {
                for (stptr = index_st; stptr < index_st + Nread; stptr++, i++) {
                    if ( *stptr ) {
                        j     = *stptr - 1;
                        start = st_info->info[j];
                        if ( (rc = SF_vdata(start_xsources, i + in1, &z)) ) goto error;
                        if ( SF_is_missing(z) ) continue;

                        if ( (rc = SF_vdata(wpos, i + in1, &w)) ) goto error;
                        if ( SF_is_missing(w) ) continue;

                        sel = kx * start + kx * all_nonmiss[j]++;
                        xsources[sel]     = z;
                        xsources[sel + 1] = w;
                        xsources[sel + 2] = i;
                    }
                }
            }
            else {
                for (stptr = index_st; stptr < index_st + Nread; stptr++, i++) {
                    if ( *stptr ) {
                        j     = *stptr - 1;
                        start = st_info->info[j];
                        if ( (rc = SF_vdata(start_xsources, i + in1, &z)) ) goto error;
                        if ( SF_is_missing(z) ) continue;
                        sel = kx * start + kx * all_nonmiss[j]++;
                        xsources[sel]     = z;
                        xsources[sel + 1] = i;
                    }
                }
            }
        }
        else {
            if ( debug ) {
                sf_printf_debug("debug 9 (sf_xtile_by): no kgen, no cutby.\n");
            }

            if ( weights ) {
                for (stptr = index_st; stptr < index_st + Nread; stptr++, i++) {
                    if ( *stptr ) {
                        j     = *stptr - 1;
                        start = st_info->info[j];
                        if ( (rc = SF_vdata(start_xsources, i + in1, &z)) ) goto error;
                        if ( SF_is_missing(z) ) continue;

                        if ( (rc = SF_vdata(wpos, i + in1, &w)) ) goto error;
                        if ( SF_is_missing(w) ) continue;

                        sel = start + all_nonmiss[j]++;
                        xsources[sel]     = z;
                        xsources[sel + 1] = w;
                    }
                }
            }
            else {
                for (stptr = index_st; stptr < index_st + Nread; stptr++, i++) {
                    if ( *stptr ) {
                        j     = *stptr - 1;
                        start = st_info->info[j];
                        if ( (rc = SF_vdata(start_xsources, i + in1, &z)) ) goto error;
                        if ( SF_is_missing(z) ) continue;
                        sel = start + all_nonmiss[j]++;
                        xsources[sel] = z;
                    }
                }
            }
        }

        if ( npoints > 0 ) {
            if ( debug ) {
                sf_printf_debug("debug 10 (sf_xtile_by): set all points_nonmiss to "GT_size_cfmt
                                " with no cutby.\n", npoints);
            }
            for (jptr = points_nonmiss; jptr < points_nonmiss + J; jptr++)
                *jptr = npoints;
        }

        if ( nquants > 0 ) {
            if ( debug ) {
                sf_printf_debug("debug 10 (sf_xtile_by): set all points_nonmiss to "GT_size_cfmt
                                " with no cutby.\n", nquants);
            }
            for (jptr = points_nonmiss; jptr < points_nonmiss + J; jptr++)
                *jptr = nquants;
        }

        if ( ncuts > 0 ) {
            if ( debug ) {
                sf_printf_debug("debug 10 (sf_xtile_by): set all points_nonmiss to "GT_size_cfmt
                                " with no cutby.\n", ncuts);
            }
            for (jptr = points_nonmiss; jptr < points_nonmiss + J; jptr++)
                *jptr = ncuts;
        }

        if ( nq2 > 0 ) {
            if ( debug ) {
                sf_printf_debug("debug 10 (sf_xtile_by): set all points_nonmiss to "GT_size_cfmt
                                " with no cutby.\n", nq2);
            }
            for (jptr = points_nonmiss; jptr < points_nonmiss + J; jptr++)
                *jptr = nq2;
        }

        if ( nq > 0 ) {
            if ( debug ) {
                sf_printf_debug("debug 10 (sf_xtile_by): set all points_nonmiss to "GT_size_cfmt
                                " with no cutby.\n", nq);
            }
            for (jptr = points_nonmiss; jptr < points_nonmiss + J; jptr++)
                *jptr = nq - 1;
        }
    }

    obs = 0;
    for (jptr = all_nonmiss; jptr < all_nonmiss + J; jptr++)
        obs += *jptr;

    if ( debug ) {
        sf_printf_debug("debug 11 (sf_xtile_by): count the number of obs "GT_size_cfmt"\n", obs);
    }

    if ( obs == 0 ) {
        sf_errprintf("no observations in any group\n");
        rc = 17001;
        goto error;
    }

    if ( st_info->benchmark > 1 )
        sf_running_timer (&timer, "\txtile step 2: Read in source variable");

    stimer = clock();

    /*********************************************************************
     *                         Memory allocation                         *
     *********************************************************************/

    GT_size xmem_quant  = nout;
    GT_size xmem_count  = ( pctpct | pctile )? Nread: 1;
    GT_size xmem_qout   = ( pctpct | pctile )? Nread: 1;
    GT_size xmem_output = kgen? Nread: 1;

    GT_size   *xcount;
    ST_double *wcount;
    ST_double *xquant;
    ST_double *xqout;
    ST_double *xoutput;

    if ( weights ) {
        xcount = malloc(sizeof *xcount);
        wcount = calloc(xmem_count, sizeof *wcount);
    }
    else {
        xcount = calloc(xmem_count, sizeof *xcount);
        wcount = malloc(sizeof *wcount);
    }

    xquant  = calloc(xmem_quant,   sizeof *xquant);
    xqout   = calloc(xmem_qout,    sizeof *xqout);
    xoutput = calloc(xmem_output,  sizeof *xoutput);

    if ( xcount   == NULL ) return(sf_oom_error("sf_quantiles", "xcount"));
    if ( wcount   == NULL ) return(sf_oom_error("sf_quantiles", "wcount"));
    if ( xquant   == NULL ) return(sf_oom_error("sf_quantiles", "xquant"));
    if ( xqout    == NULL ) return(sf_oom_error("sf_quantiles", "xqout"));
    if ( xoutput  == NULL ) return(sf_oom_error("sf_quantiles", "xoutput"));

    if ( weights ) {
        for (wptr = wcount; wptr < wcount + xmem_count; wptr++)
            *wptr = 0;
    }
    else {
        for (cptr = xcount; cptr < xcount + xmem_count; cptr++)
            *cptr = 0;
    }

    for (optr = xoutput; optr < xoutput + xmem_output; optr++)
        *optr = 0;

    if ( debug ) {
        sf_printf_debug("debug 12 (sf_xtile_by): allocated memory\n");
        sf_printf_debug("\txmem_quant:  "GT_size_cfmt"\n", xmem_quant);
        sf_printf_debug("\txmem_count:  "GT_size_cfmt"\n", xmem_count);
        sf_printf_debug("\txmem_qout:   "GT_size_cfmt"\n", xmem_qout);
        sf_printf_debug("\txmem_output: "GT_size_cfmt"\n", xmem_output);
    }

    /*********************************************************************
     *                         Copy pct to data                          *
     *********************************************************************/

    if ( st_info->xtile_strict ) {
        if ( genpct ) {
            if ( nquants > 0 ) {
                if ( cstartj ) {
                    for (j = 0; j < J; j++) {
                        cend   = points_nonmiss[j];
                        nj     = nj_buffer[j];
                        if ( (cend == 0) | (cend > nj) ) continue;
                        start  = offsets_buffer[j];
                        cstart = start + j;
                        qptr   = xquants + cstart;
                        for (jptr = st_info->index + start;
                             jptr < st_info->index + start + cend;
                             jptr++, qptr++) {
                            if ( (rc = SF_vstore(start_genpct, *jptr + in1, *qptr) )) goto exit;
                        }
                    }
                }
                else {
                    for (j = 0; j < J; j++) {
                        nj     = nj_buffer[j];
                        if ( nquants > nj ) continue;
                        start  = offsets_buffer[j];
                        qptr   = xquants;
                        for (jptr = st_info->index + start;
                             jptr < st_info->index + start + nquants;
                             jptr++, qptr++) {
                            if ( (rc = SF_vstore(start_genpct, *jptr + in1, *qptr) )) goto exit;
                        }
                    }
                }
            }
            else if ( nq2 > 0 ) {
                for (j = 0; j < J; j++) {
                    nj     = nj_buffer[j];
                    if ( nq2 > nj ) continue;
                    start  = offsets_buffer[j];
                    qptr   = st_info->xtile_quantiles;
                    for (jptr = st_info->index + start;
                         jptr < st_info->index + start + nq2;
                         jptr++, qptr++) {
                        if ( (rc = SF_vstore(start_genpct, *jptr + in1, *qptr) )) goto exit;
                    }
                }
            }
            else if ( nq > 0 ) {
                nqdbl  = (ST_double) nq;
                for (j = 0; j < J; j++) {
                    nj   = nj_buffer[j];
                    if ( (nq - 1) > nj ) continue;
                    jptr = st_info->index + offsets_buffer[j];
                    for (i = 0; i < (nq - 1); i++, jptr++) {
                        if ( (rc = SF_vstore(start_genpct, *jptr + in1, (100 * (i + 1) / nqdbl)) )) goto exit;
                    }
                }
            }
        }
    }
    else {
        if ( genpct ) {
            if ( nquants > 0 ) {
                if ( cstartj ) {
                    for (j = 0; j < J; j++) {
                        cend   = points_nonmiss[j];
                        if ( cend == 0 ) continue;
                        start  = offsets_buffer[j];
                        cstart = start + j;
                        nj     = GTOOLS_PWMIN(cend, nj_buffer[j]);
                        qptr   = xquants + cstart;
                        for (jptr = st_info->index + start;
                             jptr < st_info->index + start + nj;
                             jptr++, qptr++) {
                            if ( (rc = SF_vstore(start_genpct, *jptr + in1, *qptr) )) goto exit;
                        }
                    }
                }
                else {
                    for (j = 0; j < J; j++) {
                        start  = offsets_buffer[j];
                        nj     = GTOOLS_PWMIN(nquants, nj_buffer[j]);
                        qptr   = xquants;
                        for (jptr = st_info->index + start;
                             jptr < st_info->index + start + nj;
                             jptr++, qptr++) {
                            if ( (rc = SF_vstore(start_genpct, *jptr + in1, *qptr) )) goto exit;
                        }
                    }
                }
            }
            else if ( nq2 > 0 ) {
                for (j = 0; j < J; j++) {
                    start  = offsets_buffer[j];
                    nj     = GTOOLS_PWMIN(nq2, nj_buffer[j]);
                    qptr   = st_info->xtile_quantiles;
                    for (jptr = st_info->index + start;
                         jptr < st_info->index + start + nj;
                         jptr++, qptr++) {
                        if ( (rc = SF_vstore(start_genpct, *jptr + in1, *qptr) )) goto exit;
                    }
                }
            }
            else if ( nq > 0 ) {
                nqdbl  = (ST_double) nq;
                for (j = 0; j < J; j++) {
                    nj   = GTOOLS_PWMIN((nq - 1), nj_buffer[j]);
                    jptr = st_info->index + offsets_buffer[j];
                    for (i = 0; i < nj; i++, jptr++) {
                        if ( (rc = SF_vstore(start_genpct, *jptr + in1, (100 * (i + 1) / nqdbl)) )) goto exit;
                    }
                }
            }
        }
    }

    /*********************************************************************
     *                               Sort!                               *
     *********************************************************************/

    GT_size invert[2]; invert[0] = 0; invert[1] = 0;
    if ( cutvars & st_info->xtile_cutby ) {
        if ( debug ) {
            sf_printf_debug("debug 13 (sf_xtile_by): cutvars, cutby\n");
        }

        if ( weights ) {
            for (j = 0; j < J; j++) {
                cstart = offsets_buffer[j] + j;
                cend   = points_nonmiss[j];
                start  = kx * offsets_buffer[j];
                end    = all_nonmiss[j];
                xptr   = xsources + start;
                gptr   = xpoints + cstart;

                if ( end && cend ) {
                    points_nonmiss[j] = gf_xtile_clean(gptr, cend, 1, st_info->xtile_dedup);
                    if ( points_nonmiss[j] ) {
                        MultiQuicksortDbl(
                            xptr,
                            end,
                            0,
                            1,
                            kx * (sizeof *xptr),
                            invert
                        );
                    }
                }
                else {
                    all_nonmiss[j]    = 0;
                    points_nonmiss[j] = 0;
                }
            }
        }
        else {
            for (j = 0; j < J; j++) {
                cstart = offsets_buffer[j] + j;
                cend   = points_nonmiss[j];
                start  = kx * offsets_buffer[j];
                end    = all_nonmiss[j];
                xptr   = xsources + start;
                gptr   = xpoints + cstart;

                if ( end && cend ) {
                    points_nonmiss[j] = gf_xtile_clean(gptr, cend, 1, st_info->xtile_dedup);
                    if ( points_nonmiss[j] ) {
                        i = 0;
                        for (xptr2 = xptr;
                             xptr2 < xptr + kx * (end - 1);
                             xptr2 += kx, i++) {
                            if ( *xptr2 > *(xptr2 + kx) ) break;
                        }
                        i++;

                        if ( i < end ) {
                            quicksort_bsd (
                                xptr,
                                end,
                                kx * (sizeof *xptr),
                                xtileCompare,
                                NULL
                            );
                        }
                    }
                }
                else {
                    all_nonmiss[j]    = 0;
                    points_nonmiss[j] = 0;
                }
            }
        }
    }
    else if ( qvars & st_info->xtile_cutby ) {
        if ( debug ) {
            sf_printf_debug("debug 13 (sf_xtile_by): qvars, cutby\n");
        }

        if ( weights ) {
            for (j = 0; j < J; j++) {
                cstart = offsets_buffer[j] + j;
                cend   = points_nonmiss[j];
                start  = kx * offsets_buffer[j];
                end    = all_nonmiss[j];
                xptr   = xsources + start;
                gptr   = xquants + cstart;

                if ( end && cend ) {
                    points_nonmiss[j] = gf_xtile_clean(gptr, cend, 1, st_info->xtile_dedup);
                    if ( points_nonmiss[j] ) {
                        MultiQuicksortDbl(
                            xptr,
                            end,
                            0,
                            1,
                            kx * (sizeof *xptr),
                            invert
                        );
                    }
                }
                else {
                    all_nonmiss[j]    = 0;
                    points_nonmiss[j] = 0;
                }
            }
        }
        else {
            for (j = 0; j < J; j++) {
                cstart = offsets_buffer[j] + j;
                cend   = points_nonmiss[j];
                start  = kx * offsets_buffer[j];
                end    = all_nonmiss[j];
                xptr   = xsources + start;
                gptr   = xquants + cstart;

                if ( end && cend ) {
                    points_nonmiss[j] = gf_xtile_clean(gptr, cend, 1, st_info->xtile_dedup);
                    if ( points_nonmiss[j] ) {
                        i = 0;
                        for (xptr2 = xptr;
                             xptr2 < xptr + kx * (end - 1);
                             xptr2 += kx, i++) {
                            if ( *xptr2 > *(xptr2 + kx) ) break;
                        }
                        i++;

                        if ( i < end ) {
                            quicksort_bsd (
                                xptr,
                                end,
                                kx * (sizeof *xptr),
                                xtileCompare,
                                NULL
                            );
                        }
                    }
                }
                else {
                    all_nonmiss[j]    = 0;
                    points_nonmiss[j] = 0;
                }
            }
        }
    }
    else {
        if ( debug ) {
            sf_printf_debug("debug 13 (sf_xtile_by): no cutby\n");
        }

        if ( weights ) {
            for (j = 0; j < J; j++) {
                start = kx * offsets_buffer[j];
                end   = all_nonmiss[j];
                xptr  = xsources + start;
                MultiQuicksortDbl(
                    xptr,
                    end,
                    0,
                    1,
                    kx * (sizeof *xptr),
                    invert
                );
            }
        }
        else {
            for (j = 0; j < J; j++) {
                start = kx * offsets_buffer[j];
                end   = all_nonmiss[j];
                xptr  = xsources + start;

                if ( end ) {
                    i = 0;
                    for (xptr2 = xptr;
                         xptr2 < xptr + kx * (end - 1);
                         xptr2 += kx, i++) {
                        if ( *xptr2 > *(xptr2 + kx) ) break;
                    }
                    i++;

                    if ( i < end ) {
                        quicksort_bsd (
                            xptr,
                            end,
                            kx * (sizeof *xptr),
                            xtileCompare,
                            NULL
                        );
                    }
                }
            }
        }
    }

    if ( st_info->benchmark > 1 )
        sf_running_timer (&stimer, "\txtile step 3: Sorted inputs by group");

    /*********************************************************************
     *      Turn quantiles into cutoffs (or point qptr to cutoffs)       *
     *********************************************************************/

    qptr = NULL;

    if ( ncuts > 0 ) {
        qptr = st_info->xtile_cutoffs;
    }
    else if ( npoints > 0 ) {
        qptr = xpoints;
    }
    else if ( nquants > 0 ) {
        qptr = cstartj? xquants: xquant;
    }
    else if ( nq2 > 0 ) {
        qptr = xquant;
    }
    else if ( nq > 0 ) {
        qptr = xquant;
    }

    if ( debug ) {
        sf_printf_debug("debug 14 (sf_xtile_by): assign qptr to %p (NULL is %p)\n", qptr, NULL);
    }

    if ( kgen & (pctpct | pctile) ) {
        if ( debug ) {
            sf_printf_debug("debug 15 (sf_xtile_by): kgen and pctile or pctpct (cstartj = %u, J = %lu)\n", cstartj, J);
        }

        if ( weights )  {
            for (j = 0; j < J; j++) {
                cend = points_nonmiss[j];
                end  = all_nonmiss[j];
                nj   = nj_buffer[j];

                if ( (end == 0) || (cend == 0) ) continue;
                if ( st_info->xtile_strict && (cend > nj) ) continue;

                cstart = cstartj? offsets_buffer[j] + j: 0;
                start  = kx * (ixstart = offsets_buffer[j]);
                xptr   = xsources + start;
                qptr2  = qptr + cstart;

                if ( ncuts > 0 ) {
                    qptr2[cend] = xptr[kx * end - kx];
                }
                else if ( npoints > 0 ) {
                    qptr2[cend] = xptr[kx * end - kx];
                }
                else {
                    if ( nquants > 0 ) {
                        gf_quantiles_w (qptr2, xptr, xquants + cstart, cend, end, kx);
                    }
                    else if ( nq2 > 0 ) {
                        gf_quantiles_w (qptr2, xptr, st_info->xtile_quantiles, cend, end, kx);
                    }
                    else if ( nq > 0 ) {
                        gf_quantiles_nq_w (qptr2, xptr, cend + 1, end, kx);
                    }
                }

                nj = GTOOLS_PWMIN(cend, nj);
                q  = 0;
                for (jptr = st_info->index + ixstart;
                     jptr < st_info->index + ixstart + nj;
                     jptr++, q++) {
                    wcount[*jptr] = 1;
                    xqout[*jptr]  = qptr2[q];
                }

                q    = 0;
                jptr = st_info->index + ixstart;
                for (xptr2 = xptr; xptr2 < xptr + kx * end; xptr2 += kx) {
                    while ( *xptr2 > qptr2[q] ) {
                        q++;
                        jptr++;
                    }
                    if ( q < nj ) {
                        wcount[*jptr] += *(xptr2 + 1);
                    }
                    xoutput[(GT_size) *(xptr2 + kx - 1)] = q + 1;
                }
            }
        }
        else {
            for (j = 0; j < J; j++) {
                cend = points_nonmiss[j];
                end  = all_nonmiss[j];
                nj   = nj_buffer[j];

                if ( (end == 0) || (cend == 0) ) continue;
                if ( st_info->xtile_strict && (cend > nj) ) continue;

                cstart = cstartj? offsets_buffer[j] + j: 0;
                start  = kx * (ixstart = offsets_buffer[j]);
                xptr   = xsources + start;
                qptr2  = qptr + cstart;

                if ( ncuts > 0 ) {
                    qptr2[cend] = xptr[kx * end - kx];
                }
                else if ( npoints > 0 ) {
                    qptr2[cend] = xptr[kx * end - kx];
                }
                else if ( altdef ) {
                    // altdef and weights not allowed
                    if ( nquants > 0 ) {
                        gf_quantiles_altdef (qptr2, xptr, xquants + cstart, cend, end, kx);
                    }
                    else if ( nq2 > 0 ) {
                        gf_quantiles_altdef (qptr2, xptr, st_info->xtile_quantiles, cend, end, kx);
                    }
                    else if ( nq > 0 ) {
                        gf_quantiles_nq_altdef (qptr2, xptr, cend + 1, end, kx);
                    }
                }
                else {
                    if ( nquants > 0 ) {
                        gf_quantiles (qptr2, xptr, xquants + cstart, cend, end, kx);
                    }
                    else if ( nq2 > 0 ) {
                        gf_quantiles (qptr2, xptr, st_info->xtile_quantiles, cend, end, kx);
                    }
                    else if ( nq > 0 ) {
                        gf_quantiles_nq (qptr2, xptr, cend + 1, end, kx);
                    }
                }

                nj = GTOOLS_PWMIN(cend, nj);
                q  = 0;
                for (jptr = st_info->index + ixstart;
                     jptr < st_info->index + ixstart + nj;
                     jptr++, q++) {
                    xcount[*jptr] = 1;
                    xqout[*jptr]  = qptr2[q];
                }

                q    = 0;
                jptr = st_info->index + ixstart;
                for (xptr2 = xptr; xptr2 < xptr + kx * end; xptr2 += kx) {
                    while ( *xptr2 > qptr2[q] ) {
                        q++;
                        jptr++;
                    }
                    if ( q < nj ) {
                        xcount[*jptr]++;
                    }
                    xoutput[(GT_size) *(xptr2 + kx - 1)] = q + 1;
                }
            }
        }

        if ( st_info->benchmark > 2 )
            sf_running_timer (&stimer, "\t\txtile step 4.1: Computed xtile and pctile");

        optr = xoutput;
        if ( (obs < Nread) | (st_info->xtile_strict) ) {
            for (i = 0; i < Nread; i++, optr++) {
                if ( *optr ) {
                    if ( (rc = SF_vstore(start_xtile, i + in1, *optr)) ) goto exit;
                }
            }
        }
        else {
            for (i = 0; i < Nread; i++, optr++) {
                if ( (rc = SF_vstore(start_xtile, i + in1, *optr)) ) goto exit;
            }
        }

        if ( st_info->benchmark > 2 )
            sf_running_timer (&stimer, "\t\txtile step 4.2: Copied xtile to Stata sequentially");

        if ( st_info->benchmark > 1 )
            sf_running_timer (&timer, "\txtile step 4: Computed xtile and copied to Stata");
    }
    else if ( kgen ) {
        if ( debug ) {
            sf_printf_debug("debug 15 (sf_xtile_by): kgen only\n");
        }

        if ( weights ) {
            for (j = 0; j < J; j++) {
                cend = points_nonmiss[j];
                end  = all_nonmiss[j];
                nj   = nj_buffer[j];

                if ( (end == 0) || (cend == 0) ) continue;
                if ( st_info->xtile_strict && (cend > nj) ) continue;

                cstart = cstartj? offsets_buffer[j] + j: 0;
                start  = kx * offsets_buffer[j];
                xptr   = xsources + start;
                qptr2  = qptr + cstart;

                if ( ncuts > 0 ) {
                    qptr2[cend] = xptr[kx * end - kx];
                }
                else if ( npoints > 0 ) {
                    qptr2[cend] = xptr[kx * end - kx];
                }
                else {
                    if ( nquants > 0 ) {
                        gf_quantiles_w (qptr2, xptr, xquants + cstart, cend, end, kx);
                    }
                    else if ( nq2 > 0 ) {
                        gf_quantiles_w (qptr2, xptr, st_info->xtile_quantiles, cend, end, kx);
                    }
                    else if ( nq > 0 ) {
                        gf_quantiles_nq_w (qptr2, xptr, cend + 1, end, kx);
                    }
                }

                q = 0;
                for (xptr2 = xptr; xptr2 < xptr + kx * end; xptr2 += kx) {
                    while ( *xptr2 > qptr2[q] ) q++;
                    xoutput[(GT_size) *(xptr2 + kx - 1)] = q + 1;
                }
            }
        }
        else {
            for (j = 0; j < J; j++) {
                cend = points_nonmiss[j];
                end  = all_nonmiss[j];
                nj   = nj_buffer[j];

                if ( (end == 0) || (cend == 0) ) continue;
                if ( st_info->xtile_strict && (cend > nj) ) continue;

                cstart = cstartj? offsets_buffer[j] + j: 0;
                start  = kx * offsets_buffer[j];
                xptr   = xsources + start;
                qptr2  = qptr + cstart;

                if ( ncuts > 0 ) {
                    qptr2[cend] = xptr[kx * end - kx];
                }
                else if ( npoints > 0 ) {
                    qptr2[cend] = xptr[kx * end - kx];
                }
                else if ( altdef ) {
                    if ( nquants > 0 ) {
                        gf_quantiles_altdef (qptr2, xptr, xquants + cstart, cend, end, kx);
                    }
                    else if ( nq2 > 0 ) {
                        gf_quantiles_altdef (qptr2, xptr, st_info->xtile_quantiles, cend, end, kx);
                    }
                    else if ( nq > 0 ) {
                        gf_quantiles_nq_altdef (qptr2, xptr, cend + 1, end, kx);
                    }
                }
                else {
                    if ( nquants > 0 ) {
                        gf_quantiles (qptr2, xptr, xquants + cstart, cend, end, kx);
                    }
                    else if ( nq2 > 0 ) {
                        gf_quantiles (qptr2, xptr, st_info->xtile_quantiles, cend, end, kx);
                    }
                    else if ( nq > 0 ) {
                        gf_quantiles_nq (qptr2, xptr, cend + 1, end, kx);
                    }
                }

                q = 0;
                for (xptr2 = xptr; xptr2 < xptr + kx * end; xptr2 += kx) {
                    while ( *xptr2 > qptr2[q] ) q++;
                    xoutput[(GT_size) *(xptr2 + kx - 1)] = q + 1;
                }
            }
        }

        if ( st_info->benchmark > 2 )
            sf_running_timer (&stimer, "\t\txtile step 4.1: Computed xtile");

        optr = xoutput;
        if ( (obs < Nread) | (st_info->xtile_strict) ) {
            for (i = 0; i < Nread; i++, optr++) {
                if ( *optr ) {
                    if ( (rc = SF_vstore(start_xtile, i + in1, *optr)) ) goto exit;
                }
            }
        }
        else {
            for (i = 0; i < Nread; i++, optr++) {
                if ( (rc = SF_vstore(start_xtile, i + in1, *optr)) ) goto exit;
            }
        }

        if ( st_info->benchmark > 2 )
            sf_running_timer (&stimer, "\t\txtile step 4.2: Copied xtile to Stata sequentially");

        if ( st_info->benchmark > 1 )
            sf_running_timer (&timer, "\txtile step 4: Computed xtile and copied to Stata");
    }
    else if ( pctpct | pctile ) {
        if ( debug ) {
            sf_printf_debug("debug 15 (sf_xtile_by): pctile or pctpct only\n");
        }

        if ( weights ) {
            for (j = 0; j < J; j++) {
                cend = points_nonmiss[j];
                end  = all_nonmiss[j];
                nj   = nj_buffer[j];

                if ( (end == 0) || (cend == 0) ) continue;
                if ( st_info->xtile_strict && (cend > nj) ) continue;

                cstart = cstartj? offsets_buffer[j] + j: 0;
                start  = kx * (ixstart = offsets_buffer[j]);
                xptr   = xsources + start;
                qptr2  = qptr + cstart;

                if ( ncuts > 0 ) {
                    qptr2[cend] = xptr[kx * end - kx];
                }
                else if ( npoints > 0 ) {
                    qptr2[cend] = xptr[kx * end - kx];
                }
                else {
                    if ( nquants > 0 ) {
                        gf_quantiles_w (qptr2, xptr, xquants + cstart, cend, end, kx);
                    }
                    else if ( nq2 > 0 ) {
                        gf_quantiles_w (qptr2, xptr, st_info->xtile_quantiles, cend, end, kx);
                    }
                    else if ( nq > 0 ) {
                        gf_quantiles_nq_w (qptr2, xptr, cend + 1, end, kx);
                    }
                }

                nj = GTOOLS_PWMIN(cend, nj);
                q  = 0;
                for (jptr = st_info->index + ixstart;
                     jptr < st_info->index + ixstart + nj;
                     jptr++) {
                    wcount[*jptr] = 1;
                    xqout[*jptr]  = qptr2[q++];
                }

                q    = 0;
                jptr = st_info->index + ixstart;
                for (xptr2 = xptr; xptr2 < xptr + kx * end; xptr2 += kx) {
                    while ( *xptr2 > qptr2[q] ) {
                        q++;
                        jptr++;
                    }
                    if ( q < nj ) {
                        wcount[*jptr] += *(xptr2 + 1);
                    }
                }
            }
        }
        else {
            for (j = 0; j < J; j++) {
                cend = points_nonmiss[j];
                end  = all_nonmiss[j];
                nj   = nj_buffer[j];

                if ( (end == 0) || (cend == 0) ) continue;
                if ( st_info->xtile_strict && (cend > nj) ) continue;

                cstart = cstartj? offsets_buffer[j] + j: 0;
                start  = kx * (ixstart = offsets_buffer[j]);
                xptr   = xsources + start;
                qptr2  = qptr + cstart;

                if ( ncuts > 0 ) {
                    qptr2[cend] = xptr[kx * end - kx];
                }
                else if ( npoints > 0 ) {
                    qptr2[cend] = xptr[kx * end - kx];
                }
                else if ( altdef ) {
                    if ( nquants > 0 ) {
                        gf_quantiles_altdef (qptr2, xptr, xquants + cstart, cend, end, kx);
                    }
                    else if ( nq2 > 0 ) {
                        gf_quantiles_altdef (qptr2, xptr, st_info->xtile_quantiles, cend, end, kx);
                    }
                    else if ( nq > 0 ) {
                        gf_quantiles_nq_altdef (qptr2, xptr, cend + 1, end, kx);
                    }
                }
                else {
                    if ( nquants > 0 ) {
                        gf_quantiles (qptr2, xptr, xquants + cstart, cend, end, kx);
                    }
                    else if ( nq2 > 0 ) {
                        gf_quantiles (qptr2, xptr, st_info->xtile_quantiles, cend, end, kx);
                    }
                    else if ( nq > 0 ) {
                        gf_quantiles_nq (qptr2, xptr, cend + 1, end, kx);
                    }
                }

                nj = GTOOLS_PWMIN(cend, nj);
                q  = 0;
                for (jptr = st_info->index + ixstart;
                     jptr < st_info->index + ixstart + nj;
                     jptr++) {
                    xcount[*jptr] = 1;
                    xqout[*jptr]  = qptr2[q++];
                }

                q    = 0;
                jptr = st_info->index + ixstart;
                for (xptr2 = xptr; xptr2 < xptr + kx * end; xptr2 += kx) {
                    while ( *xptr2 > qptr2[q] ) {
                        q++;
                        jptr++;
                    }
                    if ( q < nj ) {
                        xcount[*jptr]++;
                    }
                }
            }
        }
    }

    if ( debug ) {
        sf_printf_debug("debug 16 (sf_xtile_by): done with main computations\n");
    }

    /*********************************************************************
     *         Return percentiles and frequencies, if requested          *
     *********************************************************************/

    wptr = wcount;
    cptr = xcount;
    qptr = xqout;
    if ( pctile ) {
        if ( pctpct ) {
            if ( debug ) {
                sf_printf_debug("debug 17 (sf_xtile_by): write pctile and pctpct\n");
            }

            if ( weights ) {
                for (i = 0; i < Nread; i++, wptr++, qptr++) {
                    if ( *wptr ) {
                        if ( (rc = SF_vstore(start_xtile + kgen,     i + in1, *qptr))     ) goto exit;
                        if ( (rc = SF_vstore(start_xtile + kgen + 1, i + in1, *wptr - 1)) ) goto exit;
                    }
                }
            }
            else {
                for (i = 0; i < Nread; i++, cptr++, qptr++) {
                    if ( *cptr ) {
                        if ( (rc = SF_vstore(start_xtile + kgen,     i + in1, *qptr))     ) goto exit;
                        if ( (rc = SF_vstore(start_xtile + kgen + 1, i + in1, *cptr - 1)) ) goto exit;
                    }
                }
            }
        }
        else {
            if ( debug ) {
                sf_printf_debug("debug 17 (sf_xtile_by): write pctile\n");
            }

            if ( weights ) {
                for (i = 0; i < Nread; i++, wptr++, qptr++) {
                    if ( *wptr ) {
                        if ( (rc = SF_vstore(start_xtile + kgen, i + in1, *qptr)) ) goto exit;
                    }
                }
            }
            else {
                for (i = 0; i < Nread; i++, cptr++, qptr++) {
                    if ( *cptr ) {
                        if ( (rc = SF_vstore(start_xtile + kgen, i + in1, *qptr)) ) goto exit;
                    }
                }
            }
        }
    }
    else if ( pctpct ) {
        if ( debug ) {
            sf_printf_debug("debug 17 (sf_xtile_by): write pctpct\n");
        }

        if ( weights ) {
            for (i = 0; i < Nread; i++, wptr++, qptr++) {
                if ( *wptr ) {
                    if ( (rc = SF_vstore(start_xtile + kgen + 1, i + in1, *wptr - 1)) ) goto exit;
                }
            }
        }
        else {
            for (i = 0; i < Nread; i++, cptr++, qptr++) {
                if ( *cptr ) {
                    if ( (rc = SF_vstore(start_xtile + kgen + 1, i + in1, *cptr - 1)) ) goto exit;
                }
            }
        }
    }

    if ( debug ) {
        sf_printf_debug("debug 18 (sf_xtile_by): everything should be in Stata\n");
    }

    if ( st_info->benchmark ) {
        if ( kgen ) {
            if ( pctile ) {
                sf_running_timer (&timer, "\txtile step 5: Copied quantiles to Stata");
            }
            else if ( pctpct ) {
                sf_running_timer (&timer, "\txtile step 5: Copied bin counts to Stata");
            }
        }
        else if ( pctile ) {
            sf_running_timer (&timer, "\txtile step 4: Copied quantiles to Stata");
        }
        else if ( pctpct ) {
            sf_running_timer (&timer, "\txtile step 4: Copied bin counts to Stata");
        }
    }

    if ( (rc = SF_scal_save ("__gtools_xtile_nq",      (ST_double) nq       )) ) goto exit;
    if ( (rc = SF_scal_save ("__gtools_xtile_nq2",     (ST_double) nq2      )) ) goto exit;
    if ( (rc = SF_scal_save ("__gtools_xtile_cutvars", (ST_double) npoints  )) ) goto exit;
    if ( (rc = SF_scal_save ("__gtools_xtile_ncuts",   (ST_double) ncuts    )) ) goto exit;
    if ( (rc = SF_scal_save ("__gtools_xtile_qvars",   (ST_double) nquants  )) ) goto exit;
    if ( (rc = SF_scal_save ("__gtools_xtile_xvars",   (ST_double) obs      )) ) goto exit;

exit:
    free (xcount);
    free (wcount);
    free (xoutput);
    free (xqout);
    free (xquant);

    if ( debug ) {
        sf_printf_debug("debug 19 (sf_xtile_by): free 1\n");
    }

error:
    free (index_st);
    free (offsets_buffer);
    free (all_nonmiss);
    free (points_nonmiss);
    free (nj_buffer);

    if ( debug ) {
        sf_printf_debug("debug 19 (sf_xtile_by): free 2\n");
    }

    free (xsources);
    free (xpoints);
    free (xquants);

    if ( debug ) {
        sf_printf_debug("debug 19 (sf_xtile_by): free 3\n");
    }

    return (rc);
}
