#include "gquantiles_by.c"

ST_retcode sf_xtile (struct StataInfo *st_info, int level);

ST_retcode sf_xtile (struct StataInfo *st_info, int level)
{

    ST_double z, w, nqdbl, xmin, xmax;
    ST_double *xptr, *qptr, *optr, *gptr, *ixptr, *xptr2;
    GT_bool failmiss = 0, sorted = 0;
    GT_size i, q, sel, obs, N, qtot;
    ST_retcode rc = 0;
    clock_t  timer = clock();
    clock_t stimer = clock();

    /*********************************************************************
     *                           Step 1: Setup                           *
     *********************************************************************/

    GT_bool method = st_info->xtile_method;
    ST_double m1_etime, m2_etime, m_ratio;

    GT_size nq      = st_info->xtile_nq;
    GT_size nq2     = st_info->xtile_nq2;
    GT_size ncuts   = st_info->xtile_ncuts;
    GT_size cutvars = st_info->xtile_cutvars;
    GT_size qvars   = st_info->xtile_qvars;
    GT_size npoints = 0;
    GT_size nquants = 0;

    GT_size kgen    = st_info->xtile_gen;
    GT_bool pctile  = st_info->xtile_pctile;
    GT_bool genpct  = st_info->xtile_genpct;
    GT_bool pctpct  = st_info->xtile_pctpct;
    GT_size kpctile = pctile + pctpct + genpct;
    GT_size xstart  = kgen + kpctile;

    GT_bool weights  = st_info->wcode > 0;
    GT_bool altdef   = st_info->xtile_altdef;
    GT_bool minmax   = st_info->xtile_minmax;
    GT_bool bincount = st_info->xtile_bincount;
    GT_bool _pctile  = st_info->xtile__pctile;
    GT_bool debug    = st_info->debug;

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

    GT_size nout;
    nout = GTOOLS_PWMAX(nq,   (nq2 + 1));
    nout = GTOOLS_PWMAX(nout, (ncuts + 1));
    nout = GTOOLS_PWMAX(nout, 1);

    if ( debug ) {
        sf_printf_debug("debug 1 (sf_xtile): read in meta info\n");
        sf_printf_debug("\t"GT_size_cfmt" read, "GT_size_cfmt" groups.\n", Nread, st_info->J);
        sf_printf_debug("\tin1 / in2: "GT_size_cfmt" / "GT_size_cfmt"\n", st_info->in1, st_info->in2);
        sf_printf_debug("\n");
        sf_printf_debug("\tmethod:            %u\n",              method);
        sf_printf_debug("\tnout:              %u\n",              nout);
        sf_printf_debug("\tnq:                "GT_size_cfmt"\n",  nq);
        sf_printf_debug("\tnq2:               "GT_size_cfmt"\n",  nq2);
        sf_printf_debug("\tncuts:             "GT_size_cfmt"\n",  ncuts);
        sf_printf_debug("\tcutvars:           "GT_size_cfmt"\n",  cutvars);
        sf_printf_debug("\tqvars:             "GT_size_cfmt"\n",  qvars);
        sf_printf_debug("\tnpoints:           "GT_size_cfmt"\n",  npoints);
        sf_printf_debug("\tnquants:           "GT_size_cfmt"\n",  nquants);
        sf_printf_debug("\n");
        sf_printf_debug("\tkgen:              "GT_size_cfmt"\n",  kgen);
        sf_printf_debug("\tpctile:            %u\n",              pctile);
        sf_printf_debug("\tgenpct:            %u\n",              genpct);
        sf_printf_debug("\tpctpct:            %u\n",              pctpct);
        sf_printf_debug("\tkpctile:           "GT_size_cfmt"\n",  kpctile);
        sf_printf_debug("\txstart:            "GT_size_cfmt"\n",  xstart);
        sf_printf_debug("\n");
        sf_printf_debug("\tweights:           %u\n",              weights);
        sf_printf_debug("\taltdef:            %u\n",              altdef);
        sf_printf_debug("\tminmax:            %u\n",              minmax);
        sf_printf_debug("\tbincount:          %u\n",              bincount);
        sf_printf_debug("\t_pctile:           %u\n",              _pctile);
        sf_printf_debug("\tdebug:             %u\n",              debug);
        sf_printf_debug("\n");
        sf_printf_debug("\tkvars:             "GT_size_cfmt"\n",  kvars);
        sf_printf_debug("\tksources:          "GT_size_cfmt"\n",  ksources);
        sf_printf_debug("\tktargets:          "GT_size_cfmt"\n",  ktargets);
        sf_printf_debug("\tstart_sources:     "GT_size_cfmt"\n",  start_sources);
        sf_printf_debug("\tstart_targets:     "GT_size_cfmt"\n",  start_targets);
        sf_printf_debug("\tstart_xtile:       "GT_size_cfmt"\n",  start_xtile);
        sf_printf_debug("\tstart_genpct:      "GT_size_cfmt"\n",  start_genpct);
        sf_printf_debug("\tstart_cutvars:     "GT_size_cfmt"\n",  start_cutvars);
        sf_printf_debug("\tstart_qvars:       "GT_size_cfmt"\n",  start_qvars);
        sf_printf_debug("\tstart_xsources:    "GT_size_cfmt"\n",  start_xsources);
    }

    /*********************************************************************
     *                         Memory Allocation                         *
     *********************************************************************/

    GT_size kx = kgen? (3 + weights): (1 + weights);
    GT_size xmem_sources = kx * Nread;
    GT_size xmem_quant   = nout;
    GT_size xmem_points  = cutvars? (st_info->xtile_cutifin? Nread + 1: SF_nobs() + 1): 1;
    GT_size xmem_quants  = qvars? (st_info->xtile_cutifin? Nread + 1: SF_nobs() + 1): 1;

    ST_double *xsources = calloc(xmem_sources, sizeof *xsources);
    ST_double *xquant   = calloc(xmem_quant,   sizeof *xquant);
    ST_double *xpoints  = calloc(xmem_points,  sizeof *xpoints);
    ST_double *xquants  = calloc(xmem_quants,  sizeof *xquants);

    if ( xsources == NULL ) return(sf_oom_error("sf_quantiles", "xsources"));
    if ( xquant   == NULL ) return(sf_oom_error("sf_quantiles", "xquant"));
    if ( xpoints  == NULL ) return(sf_oom_error("sf_quantiles", "xpoints"));
    if ( xquants  == NULL ) return(sf_oom_error("sf_quantiles", "xquants"));

    if ( debug ) {
        sf_printf_debug("debug 2 (sf_xtile): Allocated memory\n");
    }

    /*********************************************************************
     *                     Cutvars and cutquantiles                      *
     *********************************************************************/

    if ( st_info->xtile_cutifin ) {
        if ( st_info->any_if ) {
            if ( debug ) {
                sf_printf_debug("debug 5 (sf_xtile): cut if in, any if\n");
            }

            if ( cutvars ) {
                if ( debug ) {
                    sf_printf_debug("debug 3 (sf_xtile): cut if in, any if, cut vars\n");
                }

                obs = 0;
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
                    sf_printf_debug("debug 4 (sf_xtile): cut if in, any if, q vars\n");
                }

                obs = 0;
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
            if ( debug ) {
                sf_printf_debug("debug 8 (sf_xtile): cut if in, not any if\n");
            }

            if ( cutvars ) {
                if ( debug ) {
                    sf_printf_debug("debug 8 (sf_xtile): cut if in, not any if, cut vars\n");
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
                    sf_printf_debug("debug 8 (sf_xtile): cut if in, not any if, q vars\n");
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
    else {
        if ( debug ) {
            sf_printf_debug("debug 9 (sf_xtile): not cut if in\n");
        }

        if ( cutvars ) {
            if ( debug ) {
                sf_printf_debug("debug 10 (sf_xtile): not cut if in, cut vars\n");
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
                sf_printf_debug("debug 11 (sf_xtile): not cut if in, q vars\n");
            }

            for (i = 0; i < SF_nobs(); i++) {
                if ( (rc = SF_vdata(start_qvars,
                                    i + 1,
                                    xquants + i)) ) goto error;
            }
            nquants = SF_nobs();
        }
    }

    /*********************************************************************
     *           Adjust percentiles or curoffs, if applicable            *
     *********************************************************************/

    failmiss = (ncuts > 0) | (npoints > 0) | (nquants > 0);
    nq2      = (nq2     == 0)? 0: gf_xtile_clean(st_info->xtile_quantiles, nq2,   1, st_info->xtile_dedup);
    ncuts    = (ncuts   == 0)? 0: gf_xtile_clean(st_info->xtile_cutoffs,   ncuts, 1, st_info->xtile_dedup);
    npoints  = (npoints == 0)? 0: gf_xtile_clean(xpoints, npoints, 1, st_info->xtile_dedup);
    nquants  = (nquants == 0)? 0: gf_xtile_clean(xquants, nquants, 1, st_info->xtile_dedup);

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

    if ( debug ) {
        sf_printf_debug("debug 12 (sf_xtile): adjusted percentiles and cutoffs\n");
    }

    /*********************************************************************
     *                      Select execution method                      *
     *********************************************************************/

    nout = GTOOLS_PWMAX(nout, (npoints + 1));
    nout = GTOOLS_PWMAX(nout, (nquants + 1));

    m_ratio = m1_etime = m2_etime = 0;
    if ( (nq > 0) | (nq2 > 0) | (nquants > 0) ) {
        if ( debug ) {
            sf_printf_debug("debug 13 (sf_xtile): Estimate method time (nq, nw2, or nquants)\n");
        }

        // Expected operations (in 'N' units):
        // - Method 1 (qsort): sort (log(N)) + 1 for xtile + 1 to rearrange + 1 counts
        // - Method 2 (qselect): # of selections + time to compute xtile + 1 counts
        if ( kgen ) {
            m1_etime = 2 * log(Nread) + 3;
            m2_etime = nout + 2;
        }
        else if ( pctpct | bincount ) {
            // No xtile
            m1_etime = log(Nread) + 2;
            m2_etime = nout + 1;
        }
        else {
            // No xtile, no counts
            m1_etime = log(Nread) + 1;
            m2_etime = nout;
        }
    }
    else if ( (ncuts > 0) | (npoints > 0) ) {
        if ( debug ) {
            sf_printf_debug("debug 14 (sf_xtile): Estimate method time (ncuts or npoints)\n");
        }

        if ( kgen ) {
            // Expected operations (in 'N' units):
            // - Method 1 (qsort): Ibid.
            // - Method 2 (qselect): No selections, but no reason to expect
            //                       cutoffs will define evenly spaced bins,
            //                       so time to count is higher; however, those
            //                       are just comparisons, not swaps!
            m1_etime = 2 * log(Nread) + 3;
            m2_etime = 0.1 * ((ST_double) nout) + 1;
        }
        else if ( pctpct | bincount ) {
            // No xtile
            m1_etime = log(Nread) + 2;
            m2_etime = 0.1 * ((ST_double) nout) + 1;
        }
        else {
            // No xtile, no counts. Here method 2 wins
            // m1_etime = log(Nread) + 1;
            // m2_etime = 0.05 * ((ST_double) nout);
            m1_etime = log(Nread) + 1;
            m2_etime = 1;
        }
    }

    if ( (m1_etime > 0) & (m1_etime > 0) ) {
        m_ratio = m1_etime / m2_etime;
    }

    if ( (method == 0) & !weights ) {
        if ( m_ratio > 0 ) {
            method  = (m_ratio > 1)? 2: 1;
            if ( st_info->verbose ) {
                if ( (nq > 0) | (nq2 > 0) | (nquants > 0) ) {
                    sf_printf("E(Method 1) ~ %.2f vs E(Method 2) ~ %.2f operations. ",
                              m1_etime, m2_etime);
                }
                else if ( (ncuts > 0) | (npoints > 0) ) {
                    sf_printf("Empirical decision rule (10 * Method 1 / Method 2): %.2f. ",
                              m_ratio);
                }
                if ( m2_etime < m1_etime ) {
                    sf_printf("Will use method 2\n");
                }
                else {
                    sf_printf("Will use method 1\n");
                }
            }
        }
        else {
            method = 1;
        }
    }
    else if ( (method != 2) | weights ) {
        method = 1;
    }

    if ( debug ) {
        sf_printf_debug("debug 15 (sf_xtile): Chose execution method %u.\n", method);
    }

    // method = 0; // expected optimal
    // method = 1; // qsort, fallback
    // method = 2; // qselect

    /*********************************************************************
     *                   Read in the source variables                    *
     *********************************************************************/

    // Special cases! Should be faster.

    obs   = 0;
    xptr2 = xsources;
    ixptr = xsources;
    if ( method == 2 ) {
        if ( debug ) {
            sf_printf_debug("debug 16 (sf_xtile): Read sources (method 2)\n");
        }

        xptr2 = kgen? xsources + 1 * Nread: xsources;
        ixptr = kgen? xsources + 2 * Nread: xsources;
        if ( st_info->any_if ) {
            if ( kgen ) {
                for (i = 0; i < Nread; i++) {
                    if ( SF_ifobs(i + in1) ) {
                        if ( (rc = SF_vdata(start_xsources,
                                            i + in1,
                                            &z)) ) goto error;
                        if ( SF_is_missing(z) ) continue;
                        xptr2[obs] = xsources[obs] = z;
                        ixptr[obs] = i;
                        obs++;
                    }
                }
            }
            else {
                for (i = 0; i < Nread; i++) {
                    if ( SF_ifobs(i + in1) ) {
                        if ( (rc = SF_vdata(start_xsources,
                                            i + in1,
                                            &z)) ) goto error;
                        if ( SF_is_missing(z) ) continue;
                        xsources[obs] = z;
                        obs++;
                    }
                }
            }
        }
        else {
            if ( kgen ) {
                for (i = 0; i < Nread; i++) {
                    if ( (rc = SF_vdata(start_xsources,
                                        i + in1,
                                        &z)) ) goto error;
                    if ( SF_is_missing(z) ) continue;
                    xptr2[obs] = xsources[obs] = z;
                    ixptr[obs] = i;
                    obs++;
                }
            }
            else {
                for (i = 0; i < Nread; i++) {
                    if ( (rc = SF_vdata(start_xsources,
                                        i + in1,
                                        &z)) ) goto error;
                    if ( SF_is_missing(z) ) continue;
                    xsources[obs] = z;
                    obs++;
                }
            }
        }
    }
    else if ( weights ) {
        if ( debug ) {
            sf_printf_debug("debug 17 (sf_xtile): Read sources (method 1; weighted)\n");
        }

        if ( st_info->any_if ) {
            if ( kgen ) {
                for (i = 0; i < Nread; i++) {
                    if ( SF_ifobs(i + in1) ) {
                        if ( (rc = SF_vdata(start_xsources,
                                            i + in1,
                                            &z)) ) goto error;
                        if ( SF_is_missing(z) ) continue;

                        if ( (rc = SF_vdata(wpos,
                                            i + in1,
                                            &w)) ) goto error;
                        if ( SF_is_missing(w) ) continue;

                        sel = kx * obs++;
                        xsources[sel] = z;
                        xsources[sel + 1] = w;
                        xsources[sel + 2] = i;
                        xsources[sel + 3] = obs - 1;
                    }
                }
            }
            else {
                for (i = 0; i < Nread; i++) {
                    if ( SF_ifobs(i + in1) ) {
                        if ( (rc = SF_vdata(start_xsources,
                                            i + in1,
                                            &z)) ) goto error;
                        if ( SF_is_missing(z) ) continue;

                        if ( (rc = SF_vdata(wpos,
                                            i + in1,
                                            &w)) ) goto error;
                        if ( SF_is_missing(w) ) continue;

                        sel = kx * obs++;
                        xsources[sel]     = z;
                        xsources[sel + 1] = w;
                    }
                }
            }
        }
        else {
            if ( kgen ) {
                for (i = 0; i < Nread; i++) {
                    if ( (rc = SF_vdata(start_xsources,
                                        i + in1,
                                        &z)) ) goto error;
                    if ( SF_is_missing(z) ) continue;

                    if ( (rc = SF_vdata(wpos,
                                        i + in1,
                                        &w)) ) goto error;
                    if ( SF_is_missing(w) ) continue;

                    sel = kx * obs++;
                    xsources[sel] = z;
                    xsources[sel + 1] = w;
                    xsources[sel + 2] = i;
                    xsources[sel + 3] = obs - 1;
                }
            }
            else {
                for (i = 0; i < Nread; i++) {
                    if ( (rc = SF_vdata(start_xsources,
                                        i + in1,
                                        &z)) ) goto error;
                    if ( SF_is_missing(z) ) continue;

                    if ( (rc = SF_vdata(wpos,
                                        i + in1,
                                        &w)) ) goto error;
                    if ( SF_is_missing(w) ) continue;

                    sel = kx * obs++;
                    xsources[sel]     = z;
                    xsources[sel + 1] = w;
                }
            }
        }
    }
    else {
        if ( debug ) {
            sf_printf_debug("debug 17 (sf_xtile): Read sources (method 1; unweighted)\n");
        }

        if ( st_info->any_if ) {
            if ( kgen ) {
                for (i = 0; i < Nread; i++) {
                    if ( SF_ifobs(i + in1) ) {
                        if ( (rc = SF_vdata(start_xsources,
                                            i + in1,
                                            &z)) ) goto error;
                        if ( SF_is_missing(z) ) continue;
                        sel = kx * obs++;
                        xsources[sel] = z;
                        xsources[sel + 1] = i;
                        xsources[sel + 2] = obs - 1;
                    }
                }
            }
            else {
                for (i = 0; i < Nread; i++) {
                    if ( SF_ifobs(i + in1) ) {
                        if ( (rc = SF_vdata(start_xsources,
                                            i + in1,
                                            &z)) ) goto error;
                        if ( SF_is_missing(z) ) continue;
                        sel = kx * obs++;
                        xsources[sel] = z;
                    }
                }
            }
        }
        else {
            if ( kgen ) {
                for (i = 0; i < Nread; i++) {
                    if ( (rc = SF_vdata(start_xsources,
                                        i + in1,
                                        &z)) ) goto error;
                    if ( SF_is_missing(z) ) continue;
                    sel = kx * obs++;
                    xsources[sel] = z;
                    xsources[sel + 1] = i;
                    xsources[sel + 2] = obs - 1;
                }
            }
            else {
                for (i = 0; i < Nread; i++) {
                    if ( (rc = SF_vdata(start_xsources,
                                        i + in1,
                                        &z)) ) goto error;
                    if ( SF_is_missing(z) ) continue;
                    sel = kx * obs++;
                    xsources[sel] = z;
                }
            }
        }
    }
    N = obs;

    if ( N == 0 ) {
        sf_errprintf("no observations\n");
        rc = 17001;
        goto error;
    }

    if ( debug ) {
        sf_printf_debug("debug 18 (sf_xtile): Check nq request is sane.\n");
    }

    // This limitation seems to have more to do with the number of rows in the
    // data being the limit to how many quantiles Stata can save via pctile.

    if ( nq > (N + 1) ) {
        if ( st_info->xtile_strict ) {
            sf_errprintf("nquantiles() must be less than or equal to # non-missing ["
                         GT_size_cfmt"] plus one\n", N);
            rc = 198;
            goto error;
        }
    }

    if ( st_info->benchmark > 1 )
        sf_running_timer (&timer, "\txtile step 2: Read in source variable");

    stimer = clock();

    /*********************************************************************
     *                         Memory allocation                         *
     *********************************************************************/

    if ( debug ) {
        sf_printf_debug("debug 19 (sf_xtile): Allocated memory for counts and output.\n");
    }

    GT_size xmem_count  = (pctpct | bincount)? nout: 1;
    GT_size xmem_output = (kgen & (method != 2))? N: 1;

    GT_size   *xcount;
    ST_double *wcount;
    ST_double *xoutput;

    if ( weights ) {
        wcount = calloc(xmem_count, sizeof *wcount);
        xcount = malloc(sizeof(xcount));
    }
    else {
        wcount = malloc(sizeof(wcount));
        xcount = calloc(xmem_count, sizeof *xcount);
    }
    xoutput = calloc(xmem_output,  sizeof *xoutput);

    if ( wcount  == NULL ) return(sf_oom_error("sf_quantiles", "wcount"));
    if ( xcount  == NULL ) return(sf_oom_error("sf_quantiles", "xcount"));
    if ( xoutput == NULL ) return(sf_oom_error("sf_quantiles", "xoutput"));

    if ( weights ) {
        for (i = 0; i < xmem_count; i++)
            wcount[i] = 0;
    }
    else {
        for (i = 0; i < xmem_count; i++)
            xcount[i] = 0;
    }

    /*********************************************************************
     *                               Sort!                               *
     *********************************************************************/

    if ( debug ) {
        sf_printf_debug("debug 20 (sf_xtile): Sort if method 1.\n");
    }

    if ( method == 2 ) kx = 1;

    // Check if already sorted
    i = 0;
    for (xptr = xsources;
         xptr < xsources + kx * (N - 1);
         xptr += kx, i++) {
        if ( *xptr > *(xptr + kx) ) break;
    }
    i++;

    GT_size invert[2]; invert[0] = 0; invert[1] = 0;
    if ( method == 2 ) {
        if ( i >= N ) {
            sorted = 2;
            if ( debug ) {
                sf_printf_debug("debug 20.1 (sf_xtile): already sorted; method 2.\n");
            }
        }
    }
    else if ( weights ) {
        MultiQuicksortDbl(
            xsources,
            N,
            0,
            1,
            kx * sizeof(xsources),
            invert
        );
        sorted = 1;
        if ( debug ) {
            sf_printf_debug("debug 20.2 (sf_xtile): multi-sorted (weights); method 1.\n");
        }
    }
    else {
        if ( i < N ) {
            quicksort_bsd (
                xsources,
                N,
                kx * sizeof(xsources),
                xtileCompare,
                NULL
            );
            sorted = 1;
            if ( debug ) {
                sf_printf_debug("debug 20.2 (sf_xtile): sorted; method 1.\n");
            }
        }
        else {
            sorted = 2;
            if ( debug ) {
                sf_printf_debug("debug 20.3 (sf_xtile): already sorted; method 1.\n");
            }
        }
    }

    /*********************************************************************
     *                         Copy pct to data                          *
     *********************************************************************/

    if ( debug ) {
        sf_printf_debug("debug 21 (sf_xtile): Copy pct to data if requested.\n");
    }

    if ( genpct ) {
        if ( nquants > 0 ) {
            for (i = 0; i < nquants; i++) {
                if ( (rc = SF_vstore(start_genpct, i + 1, xquants[i]) )) goto exit;
            }
        }
        else if ( nq2 > 0 ) {
            for (i = 0; i < nq2; i++) {
                if ( (rc = SF_vstore(start_genpct, i + 1, st_info->xtile_quantiles[i]) )) goto exit;
            }
        }
        else if ( nq > 0 ) {
            nqdbl = (ST_double) nq;
            for (i = 0; i < (nq - 1); i++) {
                if ( (rc = SF_vstore(start_genpct, i + 1, (100 * (i + 1) / nqdbl)) )) goto exit;
            }
        }
    }

    /*********************************************************************
     *      Turn quantiles into cutoffs (or point qptr to cutoffs)       *
     *********************************************************************/

    if ( debug ) {
        sf_printf_debug("debug 22 (sf_xtile): Transform quantiles using requested method (or altdef)\n");
    }

    qptr = NULL;
    if ( ncuts > 0 ) {
        qptr = st_info->xtile_cutoffs;
        qptr[ncuts] = (method == 1)? xsources[kx * N - kx]: gf_array_dmax_range(xptr2, 0, N);
    }
    else if ( npoints > 0 ) {
        qptr = xpoints;
        qptr[npoints] = (method == 1)? xsources[kx * N - kx]: gf_array_dmax_range(xptr2, 0, N);
    }
    else if ( altdef ) {
        // altdef and weights not allowed
        // if ( weights ) {
        //     rc = 198;
        //     goto error;
        // }
        if ( (method == 2) & (sorted < 2) ) {
            if ( nquants > 0 ) {
                gf_quantiles_qselect_altdef (xquants, xptr2, xquants, nquants, N);
                qptr = xquants;
            }
            else if ( nq2 > 0 ) {
                gf_quantiles_qselect_altdef (xquant, xptr2, st_info->xtile_quantiles, nq2, N);
                qptr = xquant;
            }
            else if ( nq > 0 ) {
                gf_quantiles_nq_qselect_altdef (xquant, xptr2, nq, N);
                qptr = xquant;
            }
        }
        else {
            if ( nquants > 0 ) {
                gf_quantiles_altdef (xquants, xsources, xquants, nquants, N, kx);
                qptr = xquants;
            }
            else if ( nq2 > 0 ) {
                gf_quantiles_altdef (xquant, xsources, st_info->xtile_quantiles, nq2, N, kx);
                qptr = xquant;
            }
            else if ( nq > 0 ) {
                gf_quantiles_nq_altdef (xquant, xsources, nq, N, kx);
                qptr = xquant;
            }
        }
    }
    else {
        if ( (method == 2) & (sorted < 2) ) {
            if ( nquants > 0 ) {
                gf_quantiles_qselect (xquants, xptr2, xquants, nquants, N);
                qptr = xquants;
            }
            else if ( nq2 > 0 ) {
                gf_quantiles_qselect (xquant, xptr2, st_info->xtile_quantiles, nq2, N);
                qptr = xquant;
            }
            else if ( nq > 0 ) {
                gf_quantiles_nq_qselect (xquant, xptr2, nq, N);
                qptr = xquant;
            }
        }
        else if ( weights ) {
            if ( nquants > 0 ) {
                gf_quantiles_w (xquants, xsources, xquants, nquants, N, kx);
                qptr = xquants;
            }
            else if ( nq2 > 0 ) {
                gf_quantiles_w (xquant, xsources, st_info->xtile_quantiles, nq2, N, kx);
                qptr = xquant;
            }
            else if ( nq > 0 ) {
                gf_quantiles_nq_w (xquant, xsources, nq, N, kx);
                qptr = xquant;
            }
        }
        else {
            if ( nquants > 0 ) {
                gf_quantiles (xquants, xsources, xquants, nquants, N, kx);
                qptr = xquants;
            }
            else if ( nq2 > 0 ) {
                gf_quantiles (xquant, xsources, st_info->xtile_quantiles, nq2, N, kx);
                qptr = xquant;
            }
            else if ( nq > 0 ) {
                gf_quantiles_nq (xquant, xsources, nq, N, kx);
                qptr = xquant;
            }
        }
    }

    if ( debug ) {
        sf_printf_debug("debug 23 (sf_xtile): Grab min and max while you're here.\n");
    }

    if ( method == 2 ) {
        xmin = gf_array_dmin_range(xptr2, 0, N);
        xmax = qptr[nout - 1];
    }
    else {
        xmin = xsources[0];
        xmax = qptr[nout - 1];
    }

    if ( st_info->benchmark > 1 ) {
        if ( method == 2 ) {
            if ( (nq2 > 0) | (nq > 0) | (nquants > 0) ) {
                sf_running_timer (&timer, "\txtile step 3: Computed quantiles");
            }
        }
        else {
            if ( (nq2 > 0) | (nq > 0) | (nquants > 0) ) {
                sf_running_timer (&timer, "\txtile step 3: Sorted source and computed quantiles");
            }
            else {
                sf_running_timer (&timer, "\txtile step 3: Sorted source variable");
            }
        }
    }
    stimer = clock();

    /*********************************************************************
     *    Compute xtile, if requested; else just count bin frequency     *
     *********************************************************************/

    if ( debug ) {
        sf_printf_debug("debug 24 (sf_xtile): Compute xtile using method.\n");
    }

    q = 0;
    if ( kgen ) {
        if ( method == 2 ) {
            if ( debug ) {
                sf_printf_debug("debug 25 (sf_xtile): xtile method 2\n");
            }

            if ( sorted ) {
                if ( bincount | pctpct ) {
                    for (xptr = xsources; xptr < xsources + N; xptr += 1) {
                        while ( *xptr > qptr[q] ) q++;
                        xcount[q]++;
                        xptr[0] = q + 1;
                    }
                }
                else {
                    for (xptr = xsources; xptr < xsources + N; xptr += 1) {
                        while ( *xptr > qptr[q] ) q++;
                        xptr[0] = q + 1;
                    }
                }
            }
            else {
                if ( bincount | pctpct ) {
                    for (xptr = xsources; xptr < xsources + N; xptr += 1) {
                        q = 0;
                        while ( *xptr > qptr[q] ) q++;
                        xcount[q]++;
                        xptr[0] = q + 1;
                    }
                }
                else {
                    for (xptr = xsources; xptr < xsources + N; xptr += 1) {
                        q = 0;
                        while ( *xptr > qptr[q] ) q++;
                        xptr[0] = q + 1;
                    }
                }
            }

            if ( st_info->benchmark > 2 )
                sf_running_timer (&stimer, "\t\txtile step 4.1: Computed xtile");

            optr  = xsources;
            ixptr = xsources + 2 * Nread;
            if ( N < Nread ) {
                for (optr = xsources; optr < xsources + N; optr += 1, ixptr += 1) {
                    if ( (rc = SF_vstore(start_xtile, ((GT_size) *ixptr) + in1, *optr)) ) goto exit;
                }
            }
            else {
                for (i = 0; i < N; i++, optr += 1) {
                    if ( (rc = SF_vstore(start_xtile, i + in1, *optr)) ) goto exit;
                }
            }

            if ( st_info->benchmark > 2 )
                sf_running_timer (&stimer, "\t\txtile step 4.2: Copied xtile to Stata sequentially");

            if ( st_info->benchmark > 1 )
                sf_running_timer (&timer, "\txtile step 4: Computed xtile and copied to Stata");

        }
        else {
            if ( debug ) {
                sf_printf_debug("debug 25 (sf_xtile): xtile method 1\n");
            }

            if ( weights ) {
                if ( bincount | pctpct ) {
                    for (xptr = xsources; xptr < xsources + kx * N; xptr += kx) {
                        while ( *xptr > qptr[q] ) q++;
                        wcount[q] += *(xptr + 1);
                        xoutput[(GT_size) *(xptr + kx - 1)] = q + 1;
                        // xptr[0] = q + 1;
                    }
                }
                else {
                    for (xptr = xsources; xptr < xsources + kx * N; xptr += kx) {
                        while ( *xptr > qptr[q] ) q++;
                        xoutput[(GT_size) *(xptr + kx - 1)] = q + 1;
                        // xptr[0] = q + 1;
                    }
                }
            }
            else {
                if ( bincount | pctpct ) {
                    for (xptr = xsources; xptr < xsources + kx * N; xptr += kx) {
                        while ( *xptr > qptr[q] ) q++;
                        xcount[q]++;
                        xoutput[(GT_size) *(xptr + kx - 1)] = q + 1;
                        // xptr[0] = q + 1;
                    }
                }
                else {
                    for (xptr = xsources; xptr < xsources + kx * N; xptr += kx) {
                        while ( *xptr > qptr[q] ) q++;
                        xoutput[(GT_size) *(xptr + kx - 1)] = q + 1;
                        // xptr[0] = q + 1;
                    }
                }
            }

            if ( st_info->benchmark > 2 )
                sf_running_timer (&stimer, "\t\txtile step 4.1: Computed xtile");

            // for (xptr = xsources; xptr < xsources + kx * N; xptr += kx) {
            //     xoutput[(GT_size) *(xptr + kx - 1)] = *xptr;
            // }

            if ( N < Nread ) {
                if ( weights ) {
                    for (xptr = xsources; xptr < xsources + kx * N; xptr += kx) {
                        xsources[kx * ((GT_size) *(xptr + kx - 1))] = *(xptr + 2);
                    }
                }
                else {
                    for (xptr = xsources; xptr < xsources + kx * N; xptr += kx) {
                        xsources[kx * ((GT_size) *(xptr + kx - 1))] = *(xptr + 1);
                    }
                }

                if ( st_info->benchmark > 2 )
                    sf_running_timer (&stimer, "\t\txtile step 4.2: Arranged xtile in memory");
            }

            optr = xoutput;
            xptr = xsources;
            if ( N < Nread ) {
                for (optr = xoutput; optr < xoutput + N; optr += 1, xptr += kx) {
                    if ( (rc = SF_vstore(start_xtile, ((GT_size) *xptr) + in1, *optr)) ) goto exit;
                }
            }
            else {
                for (i = 0; i < N; i++, optr += 1) {
                    if ( (rc = SF_vstore(start_xtile, i + in1, *optr)) ) goto exit;
                }
            }

            if ( st_info->benchmark > 2 )
                sf_running_timer (&stimer, "\t\txtile step 4.3: Copied xtile to Stata sequentially");

            if ( st_info->benchmark > 1 )
                sf_running_timer (&timer, "\txtile step 4: Computed xtile and copied to Stata");
        }
    }
    else if ( pctpct | bincount ) {
        if ( debug ) {
            sf_printf_debug("debug 26 (sf_xtile): no xtile; only counts and such.\n");
        }

        if ( weights ) {
            if ( sorted ) {
                for (xptr = xsources; xptr < xsources + kx * N; xptr += kx) {
                    while ( *xptr > qptr[q] ) q++;
                    wcount[q] += *(xptr + 1);
                }
            }
            else {
                for (xptr = xsources; xptr < xsources + kx * N; xptr += kx) {
                    q = 0;
                    while ( *xptr > qptr[q] ) q++;
                    wcount[q] += *(xptr + 1);
                }
            }
        }
        else {
            if ( sorted ) {
                for (xptr = xsources; xptr < xsources + kx * N; xptr += kx) {
                    while ( *xptr > qptr[q] ) q++;
                    xcount[q]++;
                }
            }
            else {
                for (xptr = xsources; xptr < xsources + kx * N; xptr += kx) {
                    q = 0;
                    while ( *xptr > qptr[q] ) q++;
                    xcount[q]++;
                }
            }
        }
    }

    if ( debug ) {
        sf_printf_debug("debug 27 (sf_xtile): Done with xtile, counts, etc.\n");
    }

    /*********************************************************************
     *         Return percentiles and frequencies, if requested          *
     *********************************************************************/

    // qtot = q + 1;
    qtot = GTOOLS_PWMIN((nout - 1), SF_nobs());

    if ( debug ) {
        sf_printf_debug("debug 28 (sf_xtile): Write pctile, xtile, and counts back to stata.\n");
    }

    if ( pctile ) {
        if ( pctpct ) {
            if ( weights ) {
                for (q = 0; q < qtot; q++) {
                    if ( (rc = SF_vstore(start_xtile + kgen,     q + 1, qptr[q])) ) goto exit;
                    if ( (rc = SF_vstore(start_xtile + kgen + 1, q + 1, wcount[q])) ) goto exit;
                }
            }
            else {
                for (q = 0; q < qtot; q++) {
                    if ( (rc = SF_vstore(start_xtile + kgen,     q + 1, qptr[q])) ) goto exit;
                    if ( (rc = SF_vstore(start_xtile + kgen + 1, q + 1, xcount[q])) ) goto exit;
                }
            }
        }
        else {
            for (q = 0; q < qtot; q++) {
                if ( (rc = SF_vstore(start_xtile + kgen, q + 1, qptr[q])) ) goto exit;
            }
        }
    }
    else if ( pctpct ) {
        if ( weights ) {
            for (q = 0; q < qtot; q++) {
                if ( (rc = SF_vstore(start_xtile + kgen, q + 1, wcount[q])) ) goto exit;
            }
        }
        else {
            for (q = 0; q < qtot; q++) {
                if ( (rc = SF_vstore(start_xtile + kgen, q + 1, xcount[q])) ) goto exit;
            }
        }
    }

    if ( ncuts > 0 ) {
        if ( bincount ) {
            if ( weights ) {
                for (q = 0; q < ncuts; q++) {
                    if ( (rc = SF_mat_store("__gtools_xtile_cutoffs", 1, q + 1, qptr[q])   )) goto exit;
                    if ( (rc = SF_mat_store("__gtools_xtile_cutbin",  1, q + 1, wcount[q]) )) goto exit;
                }
            }
            else {
                for (q = 0; q < ncuts; q++) {
                    if ( (rc = SF_mat_store("__gtools_xtile_cutoffs", 1, q + 1, qptr[q])   )) goto exit;
                    if ( (rc = SF_mat_store("__gtools_xtile_cutbin",  1, q + 1, xcount[q]) )) goto exit;
                }
            }
        }
        else {
            for (q = 0; q < ncuts; q++) {
                if ( (rc = SF_mat_store("__gtools_xtile_cutoffs", 1, q + 1, qptr[q]) )) goto exit;
            }
        }
    }

    if ( nq2 > 0 ) {
        if ( bincount ) {
            if ( weights ) {
                for (q = 0; q < nq2; q++) {
                    if ( (rc = SF_mat_store("__gtools_xtile_quantiles", 1, q + 1, qptr[q])   )) goto exit;
                    if ( (rc = SF_mat_store("__gtools_xtile_quantbin",  1, q + 1, wcount[q]) )) goto exit;
                }
            }
            else {
                for (q = 0; q < nq2; q++) {
                    if ( (rc = SF_mat_store("__gtools_xtile_quantiles", 1, q + 1, qptr[q])   )) goto exit;
                    if ( (rc = SF_mat_store("__gtools_xtile_quantbin",  1, q + 1, xcount[q]) )) goto exit;
                }
            }
        }
        else {
            for (q = 0; q < nq2; q++) {
                if ( (rc = SF_mat_store("__gtools_xtile_quantiles", 1, q + 1, qptr[q]) )) goto exit;
            }
        }
    }
    else if ( (nq > 0) & bincount & (pctpct == 0) ) {
        if ( _pctile ) {
            if ( weights ) {
                for (q = 0; q < (nq - 1); q++) {
                    if ( (rc = SF_mat_store("__gtools_xtile_quantiles", 1, q + 1, qptr[q])   )) goto exit;
                    if ( (rc = SF_mat_store("__gtools_xtile_quantbin",  1, q + 1, wcount[q]) )) goto exit;
                }
            }
            else {
                for (q = 0; q < (nq - 1); q++) {
                    if ( (rc = SF_mat_store("__gtools_xtile_quantiles", 1, q + 1, qptr[q])   )) goto exit;
                    if ( (rc = SF_mat_store("__gtools_xtile_quantbin",  1, q + 1, xcount[q]) )) goto exit;
                }
            }
        }
        else {
            if ( weights ) {
                for (q = 0; q < (nq - 1); q++) {
                    if ( (rc = SF_mat_store("__gtools_xtile_quantbin",  1, q + 1, wcount[q]) )) goto exit;
                }
            }
            else {
                for (q = 0; q < (nq - 1); q++) {
                    if ( (rc = SF_mat_store("__gtools_xtile_quantbin",  1, q + 1, xcount[q]) )) goto exit;
                }
            }
        }
    }
    else if ( (nq > 0) & _pctile ) {
        for (q = 0; q < (nq - 1); q++) {
            if ( (rc = SF_mat_store("__gtools_xtile_quantiles", 1, q + 1, qptr[q])   )) goto exit;
        }
    }

    if ( debug ) {
        sf_printf_debug("debug 29 (sf_xtile): Write info matrices.\n");
    }

    if ( (rc = SF_scal_save ("__gtools_xtile_nq",      (ST_double) nq       )) ) goto exit;
    if ( (rc = SF_scal_save ("__gtools_xtile_nq2",     (ST_double) nq2      )) ) goto exit;
    if ( (rc = SF_scal_save ("__gtools_xtile_cutvars", (ST_double) npoints  )) ) goto exit;
    if ( (rc = SF_scal_save ("__gtools_xtile_ncuts",   (ST_double) ncuts    )) ) goto exit;
    if ( (rc = SF_scal_save ("__gtools_xtile_qvars",   (ST_double) nquants  )) ) goto exit;
    if ( (rc = SF_scal_save ("__gtools_xtile_xvars",   (ST_double) N        )) ) goto exit;

    if ( minmax ) {
        if ( (rc = SF_scal_save ("__gtools_xtile_min", xmin )) ) goto exit;
        if ( (rc = SF_scal_save ("__gtools_xtile_max", xmax )) ) goto exit;
    }
    if ( (rc = SF_scal_save ("__gtools_xtile_method", m_ratio)) ) goto exit;

    if ( st_info->benchmark > 1 ) {
        if ( kgen ) {
            if ( pctile | (nq2 > 0) ) {
                sf_running_timer (&timer, "\txtile step 5: Copied quantiles to Stata");
            }
            else if ( pctpct | (ncuts > 0) ) {
                sf_running_timer (&timer, "\txtile step 5: Copied bin counts to Stata");
            }
        }
        else if ( pctile | (nq2 > 0) ) {
            sf_running_timer (&timer, "\txtile step 4: Copied quantiles to Stata");
        }
        else if ( pctpct | (ncuts > 0) ) {
            sf_running_timer (&timer, "\txtile step 4: Copied bin counts to Stata");
        }
    }

    if ( debug ) {
        sf_printf_debug("debug 30 (sf_xtile): Done with xtile.\n");
    }

exit:
    free (wcount);
    free (xcount);
    free (xoutput);

error:
    free (xsources);
    free (xquant);
    free (xpoints);
    free (xquants);

    return (rc);
}

/*********************************************************************
 *                              Scratch                              *
 *********************************************************************/

// A. with gen
//     1. Read cutvars
//         1.1 if
//             1.1.1 missing
//                 index + stata index
//             1.1.2 no missing
//                 index + stata index
//         1.2 no if
//             1.2.1 missing
//                 index
//             1.2.2 no missing
//                 index + stata index
//     2. no cutvars
//         2.1 if
//             2.1.1 missing
//                 index + stata index
//             2.1.2 no missing
//                 index + stata index
//         2.2 no if
//             2.2.1 missing
//                 index
//             2.2.2 no missing
//                 index + stata index
// B. no gen
//     1. read cutvars
//         1.1 if
//             1.1.1 missing
//             1.1.2 no missing
//         1.2 no if
//             1.2.1 missing
//             1.2.2 no missing
//     2. no cutvars
//         2.1 if
//             2.1.1 missing
//             2.1.2 no missing
//         2.2 no if
//             2.2.1 missing
//             2.2.2 no missing

// if ( kgen ) {                     // A. With gen
//     if ( cutvars ) {              // 1. Read cutvars
//         npoints = Nread;
//         if ( st_info->any_if ) {  // 1.1 if
//             obs = 0;
//             if ( missing ) {      // 1.1.1 missing
//                 for (i = 0; i < Nread; i++) {
//                     if ( (rc = SF_vdata(start_cutvars,
//                                         i + in1,
//                                         xpoints + i)) ) goto exit;
//                     if ( SF_ifobs(i + in1) ) {
//                         sel = kx * obs++;
//                         if ( (rc = SF_vdata(start_xsources,
//                                             i + in1,
//                                             xsources + sel)) ) goto exit;
//                         xsources[sel + 1] = i;
//                         xsources[sel + 2] = obs - 1;
//                     }
//                 }
//             }
//             else {                // 1.1.2 no missing
//                 for (i = 0; i < Nread; i++) {
//                     if ( (rc = SF_vdata(start_cutvars,
//                                         i + in1,
//                                         xpoints + i)) ) goto exit;
//                     if ( SF_ifobs(i + in1) ) {
//                         if ( (rc = SF_vdata(start_xsources,
//                                             i + in1,
//                                             &z)) ) goto exit;
//                         if ( !SF_is_missing(z) ) {
//                             sel = kx * obs++;
//                             xsources[sel] = z;
//                             xsources[sel + 1] = i;
//                             xsources[sel + 2] = obs - 1;
//                         }
//                     }
//                 }
//             }
//             N = obs;
//         }
//         else {                    // 1.2 no if
//             if ( missing ) {      // 1.2.1 missing
//                 for (i = 0; i < Nread; i++) {
//                     if ( (rc = SF_vdata(start_cutvars,
//                                         i + in1,
//                                         xpoints + i)) ) goto exit;
//                     if ( (rc = SF_vdata(start_xsources,
//                                         i + in1,
//                                         xsources + kx * i)) ) goto exit;
//                     xsources[kx * i + 1] = i;
//                 }
//                 N = Nread;
//             }
//             else {                // 1.2.2 no missing
//                 obs = 0;
//                 for (i = 0; i < Nread; i++) {
//                     if ( (rc = SF_vdata(start_cutvars,
//                                         i + in1,
//                                         xpoints + i)) ) goto exit;
//                     if ( (rc = SF_vdata(start_xsources,
//                                         i + in1,
//                                         &z)) ) goto exit;
//                     if ( !SF_is_missing(z) ) {
//                         sel = kx * obs++;
//                         xsources[sel] = z;
//                         xsources[sel + 1] = i;
//                         xsources[sel + 2] = obs - 1;
//                     }
//                 }
//                 N = obs;
//             }
//         }
//     }
//     else {                        // 2. no cutvars
//         if ( st_info->any_if ) {  // 2.1 if
//             obs = 0;
//             if ( missing ) {      // 2.1.1 missing
//                 for (i = 0; i < Nread; i++) {
//                     if ( SF_ifobs(i + in1) ) {
//                         sel = kx * obs++;
//                         if ( (rc = SF_vdata(start_xsources,
//                                             i + in1,
//                                             xsources + sel)) ) goto exit;
//                         xsources[sel + 1] = i;
//                         xsources[sel + 2] = obs - 1;
//                     }
//                 }
//             }
//             else {                // 2.1.2 no missing
//                 for (i = 0; i < Nread; i++) {
//                     if ( SF_ifobs(i + in1) ) {
//                         if ( (rc = SF_vdata(start_xsources,
//                                             i + in1,
//                                             &z)) ) goto exit;
//                         if ( !SF_is_missing(z) ) {
//                             sel = kx * obs++;
//                             xsources[sel] = z;
//                             xsources[sel + 1] = i;
//                             xsources[sel + 2] = obs - 1;
//                         }
//                     }
//                 }
//             }
//             N = obs;
//         }
//         else {                    // 2.2 no if
//             if ( missing ) {      // 2.2.1 missing
//                 for (i = 0; i < Nread; i++) {
//                     if ( (rc = SF_vdata(start_xsources,
//                                         i + in1,
//                                         xsources + kx * i)) ) goto exit;
//                     xsources[kx * i + 1] = i;
//                 }
//                 N = Nread;
//             }
//             else {                // 2.2.2 no missing
//                 obs = 0;
//                 for (i = 0; i < Nread; i++) {
//                     if ( (rc = SF_vdata(start_xsources,
//                                         i + in1,
//                                         &z)) ) goto exit;
//                     if ( !SF_is_missing(z) ) {
//                         sel = kx * obs++;
//                         xsources[sel] = z;
//                         xsources[sel + 1] = i;
//                         xsources[sel + 2] = obs - 1;
//                     }
//                 }
//                 N = obs;
//             }
//         }
//     }
// }
// else {
//     if ( cutvars ) {
//         npoints = Nread;
//         if ( st_info->any_if ) {
//             obs = 0;
//             if ( missing ) {
//                 for (i = 0; i < Nread; i++) {
//                     if ( (rc = SF_vdata(start_cutvars,
//                                         i + in1,
//                                         xpoints + i)) ) goto exit;
//                     if ( SF_ifobs(i + in1) ) {
//                         if ( (rc = SF_vdata(start_xsources,
//                                             i + in1,
//                                             xsources + obs++)) ) goto exit;
//                     }
//                 }
//             }
//             else {
//                 for (i = 0; i < Nread; i++) {
//                     if ( (rc = SF_vdata(start_cutvars,
//                                         i + in1,
//                                         xpoints + i)) ) goto exit;
//                     if ( SF_ifobs(i + in1) ) {
//                         if ( (rc = SF_vdata(start_xsources,
//                                             i + in1,
//                                             &z)) ) goto exit;
//                         if ( !SF_is_missing(z) ) {
//                             xsources[obs++] = z;
//                         }
//                     }
//                 }
//             }
//             N = obs;
//         }
//         else {
//             if ( missing ) {
//                 for (i = 0; i < Nread; i++) {
//                     if ( (rc = SF_vdata(start_cutvars,
//                                         i + in1,
//                                         xpoints + i)) ) goto exit;
//                     if ( (rc = SF_vdata(start_xsources,
//                                         i + in1,
//                                         xsources + i)) ) goto exit;
//                 }
//                 N = Nread;
//             }
//             else {
//                 obs = 0;
//                 for (i = 0; i < Nread; i++) {
//                     if ( (rc = SF_vdata(start_cutvars,
//                                         i + in1,
//                                         xpoints + i)) ) goto exit;
//                     if ( (rc = SF_vdata(start_xsources,
//                                         i + in1,
//                                         &z)) ) goto exit;
//                     if ( !SF_is_missing(z) ) {
//                         xsources[obs++] = z;
//                     }
//                 }
//                 N = obs;
//             }
//         }
//     }
//     else {
//         if ( st_info->any_if ) {
//             obs = 0;
//             if ( missing ) {
//                 for (i = 0; i < Nread; i++) {
//                     if ( SF_ifobs(i + in1) ) {
//                         if ( (rc = SF_vdata(start_xsources,
//                                             i + in1,
//                                             xsources + obs++)) ) goto exit;
//                     }
//                 }
//             }
//             else {
//                 for (i = 0; i < Nread; i++) {
//                     if ( SF_ifobs(i + in1) ) {
//                         if ( (rc = SF_vdata(start_xsources,
//                                             i + in1,
//                                             &z)) ) goto exit;
//                         if ( !SF_is_missing(z) ) {
//                             xsources[obs++] = z;
//                         }
//                     }
//                 }
//             }
//             N = obs;
//         }
//         else {
//             if ( missing ) {
//                 for (i = 0; i < Nread; i++) {
//                     if ( (rc = SF_vdata(start_xsources,
//                                         i + in1,
//                                         xsources + i)) ) goto exit;
//                 }
//                 N = Nread;
//             }
//             else {
//                 obs = 0;
//                 for (i = 0; i < Nread; i++) {
//                     if ( (rc = SF_vdata(start_xsources,
//                                         i + in1,
//                                         &z)) ) goto exit;
//                     if ( !SF_is_missing(z) ) {
//                         xsources[obs++] = z;
//                     }
//                 }
//                 N = obs;
//             }
//         }
//     }
// }

