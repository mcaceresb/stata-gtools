ST_retcode gf_stats_transform_check (
    ST_double tcode,
    GT_size kstats
);

void gf_stats_transform_apply (
    ST_double *buffer,
    GT_size   nj,
    ST_double tcode,
    ST_double *stats
);

void gf_stats_transform_range(
    ST_double *buffer,
    ST_double *wbuffer,
    ST_double *ibuffer,
    ST_double *sbuffer,
    GT_int    *indeces,
    GT_size   nj,
    ST_double scode,
    GT_bool   aweights,
    ST_double *pbuffer,
    ST_double *output,
    ST_double lower,
    ST_double upper,
    ST_double lcode,
    ST_double ucode,
    GT_bool   excludeself,
    GT_bool   excludebounds
);

void gf_stats_transform_range_sort(
    ST_double *buffer,
    ST_double *wbuffer,
    ST_double *ibuffer,
    ST_double *sbuffer,
    GT_size   nj
);

void gf_stats_transform_moving(
    ST_double *buffer,
    ST_double *wbuffer,
    GT_size   nj,
    ST_double scode,
    GT_bool   aweights,
    ST_double *pbuffer,
    ST_double *output,
    ST_double lower,
    ST_double upper
);

void gf_stats_transform_rank(
    ST_double *buffer,
    ST_double *wbuffer,
    GT_size   nj,
    GT_size   ties,
    GT_bool   aweights,
    ST_double *sbuffer,
    ST_double *output
);

ST_double gf_stats_transform_stat (
    ST_double *buffer,
    ST_double *pbuffer,
    GT_size nj,
    ST_double scode,
    GT_bool   nomissing
);

ST_double gf_stats_transform_stat_exclude (
    ST_double *buffer,
    ST_double *pbuffer,
    GT_size   nj,
    ST_double scode,
    GT_bool   nomissing,
    GT_size   i
);

ST_double gf_stats_transform_stat_weighted (
    ST_double *buffer,
    ST_double *wbuffer,
    GT_size   nj,
    ST_double scode,
    GT_bool   aweights,
    ST_double *pbuffer
);

ST_double gf_stats_transform_stat_weighted_exclude (
    ST_double *buffer,
    ST_double *wbuffer,
    GT_size   nj,
    ST_double scode,
    GT_bool   aweights,
    ST_double *pbuffer,
    GT_size   i
);

ST_retcode sf_write_transform (
    struct StataInfo *st_info,
    ST_double *transform
);

ST_retcode sf_read_transform (
    struct StataInfo *st_info,
    ST_double *transform,
    ST_double *weights,
    ST_double *intvars
);

ST_retcode sf_stats_transform (struct StataInfo *st_info, int level)
{

    GT_bool debug = st_info->debug;
    if ( debug ) {
        sf_printf_debug("debug 1 (sf_stats_transform): Starting gstats winsor.\n");
    }

    /*********************************************************************
     *                           Step 1: Setup                           *
     *********************************************************************/

    ST_retcode rc = 0;
    GT_size i, j, k, l, nj, spos, start, end;
    ST_double scode, tcode, *dblptr, *wgtptr, *intptr;

    GT_size kvars     = st_info->kvars_by;
    GT_size ksources  = st_info->transform_kvars;
    GT_size ktargets  = st_info->transform_ktargets;
    GT_size kgstats   = st_info->transform_kgstats;
    GT_size krange    = st_info->transform_range_k;
    GT_size koffset   = kvars + ksources + ktargets;
    GT_size wpos      = st_info->wpos;
    GT_size nj_max    = st_info->info[1] - st_info->info[0];
    GT_size Nread     = st_info->Nread;
    GT_size J         = st_info->J;
    clock_t timer     = clock();

    GT_bool greedy   = st_info->transform_greedy;
    GT_bool weights  = st_info->wcode > 0;
    GT_bool aweights = (st_info->wcode == 1);
    GT_bool range    = (krange > 0);

    for (j = 1; j < J; j++) {
        if (nj_max < (st_info->info[j + 1] - st_info->info[j]))
            nj_max = (st_info->info[j + 1] - st_info->info[j]);
    }

    ST_double *gsrc_intvars = calloc(range? (greedy? (krange * Nread): nj_max): 1, sizeof *gsrc_intvars);
    GT_int    *gsrc_indeces = calloc(range? 2 * nj_max: 1,         sizeof *gsrc_indeces);
    ST_double *gsrc_vars    = calloc(greedy?  (ksources  * Nread): 1, sizeof *gsrc_vars);
    ST_double *gsrc_pbuffer = calloc(weights? 2 * nj_max: nj_max,     sizeof *gsrc_pbuffer);
    ST_double *gsrc_sbuffer = calloc(weights? 4 * nj_max: 3 * nj_max, sizeof *gsrc_sbuffer);
    ST_double *gsrc_weight  = calloc(weights? Nread: 1, sizeof *gsrc_weight);

    ST_double *gsrc_output  = calloc(nj_max,   sizeof *gsrc_output);
    ST_double *gsrc_buffer  = calloc(nj_max,   sizeof *gsrc_buffer);
    ST_double *gsrc_stats   = calloc(kgstats,  sizeof *gsrc_stats);
    GT_size   *gsrc_kstats  = calloc(ktargets, sizeof *gsrc_kstats);

    if ( gsrc_intvars == NULL ) return(sf_oom_error("sf_stats_transform", "gsrc_intvars"));
    if ( gsrc_indeces == NULL ) return(sf_oom_error("sf_stats_transform", "gsrc_indeces"));
    if ( gsrc_vars    == NULL ) return(sf_oom_error("sf_stats_transform", "gsrc_vars"));
    if ( gsrc_pbuffer == NULL ) return(sf_oom_error("sf_stats_transform", "gsrc_pbuffer"));
    if ( gsrc_sbuffer == NULL ) return(sf_oom_error("sf_stats_transform", "gsrc_sbuffer"));
    if ( gsrc_weight  == NULL ) return(sf_oom_error("sf_stats_transform", "gsrc_weight"));

    if ( gsrc_output  == NULL ) return(sf_oom_error("sf_stats_transform", "gsrc_output"));
    if ( gsrc_buffer  == NULL ) return(sf_oom_error("sf_stats_transform", "gsrc_buffer"));
    if ( gsrc_stats   == NULL ) return(sf_oom_error("sf_stats_transform", "gsrc_stats"));
    if ( gsrc_kstats  == NULL ) return(sf_oom_error("sf_stats_transform", "gsrc_kstats"));

    for (k = 0; k < ktargets; k++) {
        tcode = st_info->transform_varfuns[k];
        gsrc_kstats[k] = 0;
        for (l = 0; l < kgstats; l++) {
            if ( st_info->transform_statmap[kgstats * k + l] > 0 ) {
                gsrc_kstats[k]++;
            }
        }
        if ( (rc = gf_stats_transform_check(tcode, gsrc_kstats[k])) ) goto exit;
    }

    if ( st_info->benchmark > 1 )
        sf_running_timer (&timer, "\ttransform step 1: variable setup");

    if ( weights ) {

        if ( greedy ) {

            // read stuff from stata in order; way faster
            if ( (rc = sf_read_transform (st_info, gsrc_vars, gsrc_weight, gsrc_intvars)) ) goto exit;

            if ( st_info->benchmark > 1 )
                sf_running_timer (&timer, "\ttransform step 2: copied sources in order");

            // apply the transforms
            dblptr = gsrc_vars;
            wgtptr = gsrc_weight;
            intptr = gsrc_intvars;
            for (j = 0; j < J; j++) {
                start  = st_info->info[j];
                end    = st_info->info[j + 1];
                nj     = end - start;
                for (k = 0; k < ktargets; k++) {
                    tcode  = st_info->transform_varfuns[k];
                    if ( tcode == -6 ) {
                        gf_stats_transform_rank(
                            dblptr,
                            wgtptr,
                            nj,
                            st_info->transform_rank_ties[k],
                            aweights,
                            gsrc_sbuffer,
                            gsrc_output
                        );
                    }
                    else if ( tcode == -5 ) {
                        gf_stats_transform_range(
                            dblptr,
                            wgtptr,
                            intptr + nj * (st_info->transform_range_pos[k] - 1),
                            gsrc_sbuffer,
                            gsrc_indeces,
                            nj,
                            st_info->transform_range[k],
                            aweights,
                            gsrc_pbuffer,
                            gsrc_output,
                            st_info->transform_range_l[k],
                            st_info->transform_range_u[k],
                            st_info->transform_range_ls[k],
                            st_info->transform_range_us[k],
                            st_info->transform_range_xs,
                            st_info->transform_range_xb
                        );
                    }
                    else if ( tcode == -4 ) {
                        gf_stats_transform_moving(
                            dblptr,
                            wgtptr,
                            nj,
                            st_info->transform_moving[k],
                            aweights,
                            gsrc_pbuffer,
                            gsrc_output,
                            st_info->transform_moving_l[k],
                            st_info->transform_moving_u[k]
                        );
                    }
                    else {
                        for (l = 0; l < gsrc_kstats[k]; l++) {
                            spos  = st_info->transform_statmap[kgstats * k + l] - 1;
                            scode = st_info->transform_statcode[spos];
                            gsrc_stats[l] = gf_stats_transform_stat_weighted(
                                dblptr,
                                wgtptr,
                                nj,
                                scode,
                                aweights,
                                gsrc_pbuffer
                            );
                        }
                        gf_stats_transform_apply(dblptr, nj, tcode, gsrc_stats);
                    }
                    dblptr += nj;
                }
                wgtptr += nj;
                if ( range ) intptr += nj * krange;
            }

            if ( st_info->benchmark > 1 )
                sf_running_timer (&timer, "\ttransform step 3: applied transform");

            // copy back to stata
            if ( (rc = sf_write_transform(st_info, gsrc_vars)) ) goto exit;

            if ( st_info->benchmark > 1 )
                sf_running_timer (&timer, "\ttransform step 4: copied targets to stata");

        }
        else {

            // read weights so they are all grouped; necessary bc weights are re-used
            wgtptr = gsrc_weight;
            for (j = 0; j < J; j++) {
                start  = st_info->info[j];
                end    = st_info->info[j + 1];
                nj     = end - start;
                for (i = start; i < end; i++, wgtptr++) {
                    if ( (rc = SF_vdata(wpos, st_info->index[i] + st_info->in1, wgtptr)) ) goto exit;
                }
            }

            if ( st_info->benchmark > 1 )
                sf_running_timer (&timer, "\ttransform step 2: read weights");

            // but the rest are read by group in not a particularly efficient fashion
            for (k = 0; k < ktargets; k++) {
                l      = st_info->transform_range_pos[k];
                tcode  = st_info->transform_varfuns[k];
                wgtptr = gsrc_weight;
                for (j = 0; j < J; j++) {
                    start  = st_info->info[j];
                    end    = st_info->info[j + 1];
                    nj     = end - start;
                    dblptr = gsrc_buffer;
                    intptr = gsrc_intvars;
                    if ( range ) {
                        for (i = start; i < end; i++, dblptr++, intptr++) {
                            if ( (rc = SF_vdata(kvars + k + 1, st_info->index[i] + st_info->in1, dblptr)) ) goto exit;
                            if ( (rc = SF_vdata(koffset + l,   st_info->index[i] + st_info->in1, intptr)) ) goto exit;
                        }
                    }
                    else {
                        for (i = start; i < end; i++, dblptr++) {
                            if ( (rc = SF_vdata(kvars + k + 1, st_info->index[i] + st_info->in1, dblptr)) ) goto exit;
                        }
                    }
                    if ( tcode == -6 ) {
                        gf_stats_transform_rank(
                            gsrc_buffer,
                            wgtptr,
                            nj,
                            st_info->transform_rank_ties[k],
                            aweights,
                            gsrc_sbuffer,
                            gsrc_output
                        );
                    }
                    else if ( tcode == -5 ) {
                        gf_stats_transform_range(
                            gsrc_buffer,
                            wgtptr,
                            gsrc_intvars,
                            gsrc_sbuffer,
                            gsrc_indeces,
                            nj,
                            st_info->transform_range[k],
                            aweights,
                            gsrc_pbuffer,
                            gsrc_output,
                            st_info->transform_range_l[k],
                            st_info->transform_range_u[k],
                            st_info->transform_range_ls[k],
                            st_info->transform_range_us[k],
                            st_info->transform_range_xs,
                            st_info->transform_range_xb
                        );
                    }
                    else if ( tcode == -4 ) {
                        gf_stats_transform_moving(
                            gsrc_buffer,
                            wgtptr,
                            nj,
                            st_info->transform_moving[k],
                            aweights,
                            gsrc_pbuffer,
                            gsrc_output,
                            st_info->transform_moving_l[k],
                            st_info->transform_moving_u[k]
                        );
                    }
                    else {
                        for (l = 0; l < gsrc_kstats[k]; l++) {
                            spos  = st_info->transform_statmap[kgstats * k + l] - 1;
                            scode = st_info->transform_statcode[spos];
                            gsrc_stats[l] = gf_stats_transform_stat_weighted(
                                gsrc_buffer,
                                wgtptr,
                                nj,
                                scode,
                                aweights,
                                gsrc_pbuffer
                            );
                        }
                        gf_stats_transform_apply(gsrc_buffer, nj, tcode, gsrc_stats);
                    }
                    wgtptr += nj;
                    dblptr = gsrc_buffer;
                    for (i = start; i < end; i++, dblptr++) {
                        if ( (rc = SF_vstore(kvars + k + 1 + ksources,
                                             st_info->index[i] + st_info->in1,
                                             *dblptr)) ) goto exit;
                    }
                }
            }

            if ( st_info->benchmark > 1 )
                sf_running_timer (&timer, "\ttransform step 3: applied transform");
        }
    }
    else {
        if ( greedy ) {

            // read stuff from stata in order; way faster
            if ( (rc = sf_read_transform (st_info, gsrc_vars, NULL, gsrc_intvars)) ) goto exit;

            if ( st_info->benchmark > 1 )
                sf_running_timer (&timer, "\ttransform step 2: copied sources in order");

            // apply the transforms
            dblptr = gsrc_vars;
            intptr = gsrc_intvars;
            for (j = 0; j < J; j++) {
                start  = st_info->info[j];
                end    = st_info->info[j + 1];
                nj     = end - start;
                for (k = 0; k < ktargets; k++) {
                    tcode  = st_info->transform_varfuns[k];
                    if ( tcode == -6 ) {
                        gf_stats_transform_rank(
                            dblptr,
                            NULL,
                            nj,
                            st_info->transform_rank_ties[k],
                            aweights,
                            gsrc_sbuffer,
                            gsrc_output
                        );
                    }
                    else if ( tcode == -5 ) {
                        gf_stats_transform_range(
                            dblptr,
                            NULL,
                            intptr + nj * (st_info->transform_range_pos[k] - 1),
                            gsrc_sbuffer,
                            gsrc_indeces,
                            nj,
                            st_info->transform_range[k],
                            aweights,
                            gsrc_pbuffer,
                            gsrc_output,
                            st_info->transform_range_l[k],
                            st_info->transform_range_u[k],
                            st_info->transform_range_ls[k],
                            st_info->transform_range_us[k],
                            st_info->transform_range_xs,
                            st_info->transform_range_xb
                        );
                    }
                    else if ( tcode == -4 ) {
                        gf_stats_transform_moving(
                            dblptr,
                            NULL,
                            nj,
                            st_info->transform_moving[k],
                            aweights,
                            gsrc_pbuffer,
                            gsrc_output,
                            st_info->transform_moving_l[k],
                            st_info->transform_moving_u[k]
                        );
                    }
                    else {
                        for (l = 0; l < gsrc_kstats[k]; l++) {
                            spos  = st_info->transform_statmap[kgstats * k + l] - 1;
                            scode = st_info->transform_statcode[spos];
                            gsrc_stats[l] = gf_stats_transform_stat(dblptr, gsrc_pbuffer, nj, scode, 0);
                        }
                        gf_stats_transform_apply(dblptr, nj, tcode, gsrc_stats);
                    }
                    dblptr += nj;
                }
                if ( range ) intptr += nj * krange;
            }

            if ( st_info->benchmark > 1 )
                sf_running_timer (&timer, "\ttransform step 3: applied transform");

            // copy back to stata
            if ( (rc = sf_write_transform(st_info, gsrc_vars)) ) goto exit;

            if ( st_info->benchmark > 1 )
                sf_running_timer (&timer, "\ttransform step 4: copied targets to stata");

        }
        else {

            // all at once! lean memory use
            for (k = 0; k < ktargets; k++) {
                l     = st_info->transform_range_pos[k];
                tcode = st_info->transform_varfuns[k];
                for (j = 0; j < J; j++) {
                    start  = st_info->info[j];
                    end    = st_info->info[j + 1];
                    nj     = end - start;
                    dblptr = gsrc_buffer;
                    intptr = gsrc_intvars;
                    if ( range ) {
                        for (i = start; i < end; i++, dblptr++, intptr++) {
                            if ( (rc = SF_vdata(kvars + k + 1, st_info->index[i] + st_info->in1, dblptr)) ) goto exit;
                            if ( (rc = SF_vdata(koffset + l,   st_info->index[i] + st_info->in1, intptr)) ) goto exit;
                        }
                    }
                    else {
                        for (i = start; i < end; i++, dblptr++) {
                            if ( (rc = SF_vdata(kvars + k + 1, st_info->index[i] + st_info->in1, dblptr)) ) goto exit;
                        }
                    }
                    if ( tcode == -6 ) {
                        gf_stats_transform_rank(
                            gsrc_buffer,
                            NULL,
                            nj,
                            st_info->transform_rank_ties[k],
                            aweights,
                            gsrc_sbuffer,
                            gsrc_output
                        );
                    }
                    else if ( tcode == -5 ) {
                        gf_stats_transform_range(
                            gsrc_buffer,
                            NULL,
                            gsrc_intvars,
                            gsrc_sbuffer,
                            gsrc_indeces,
                            nj,
                            st_info->transform_range[k],
                            aweights,
                            gsrc_pbuffer,
                            gsrc_output,
                            st_info->transform_range_l[k],
                            st_info->transform_range_u[k],
                            st_info->transform_range_ls[k],
                            st_info->transform_range_us[k],
                            st_info->transform_range_xs,
                            st_info->transform_range_xb
                        );
                    }
                    else if ( tcode == -4 ) {
                        gf_stats_transform_moving(
                            gsrc_buffer,
                            NULL,
                            nj,
                            st_info->transform_moving[k],
                            aweights,
                            gsrc_pbuffer,
                            gsrc_output,
                            st_info->transform_moving_l[k],
                            st_info->transform_moving_u[k]
                        );
                    }
                    else {
                        for (l = 0; l < gsrc_kstats[k]; l++) {
                            spos  = st_info->transform_statmap[kgstats * k + l] - 1;
                            scode = st_info->transform_statcode[spos];
                            gsrc_stats[l] = gf_stats_transform_stat(gsrc_buffer, gsrc_pbuffer, nj, scode, 0);
                        }
                        gf_stats_transform_apply(gsrc_buffer, nj, tcode, gsrc_stats);
                    }
                    dblptr = gsrc_buffer;
                    for (i = start; i < end; i++, dblptr++) {
                        if ( (rc = SF_vstore(kvars + k + 1 + ksources,
                                             st_info->index[i] + st_info->in1,
                                             *dblptr)) ) goto exit;
                    }
                }

                if ( st_info->benchmark > 1 )
                    sf_running_timer (&timer, "\ttransform step 2: applied transform");

            }
        }
    }

exit:

    free (gsrc_intvars);
    free (gsrc_indeces);
    free (gsrc_vars);
    free (gsrc_pbuffer);
    free (gsrc_sbuffer);
    free (gsrc_weight);

    free (gsrc_output);
    free (gsrc_buffer);
    free (gsrc_stats);
    free (gsrc_kstats);

    return (rc);
}

/*********************************************************************
 *                         Helper functions                          *
 *********************************************************************/

ST_retcode gf_stats_transform_check (
    ST_double tcode,
    GT_size kstats)
{
    if ( (tcode == -1) & (kstats != 2) ) return(18301);
    if ( (tcode == -2) & (kstats != 1) ) return(18301);
    if ( (tcode == -3) & (kstats != 1) ) return(18301);
    if ( (tcode == -4) & (kstats != 0) ) return(18301);
    if ( (tcode == -5) & (kstats != 0) ) return(18301);
    if ( (tcode == -6) & (kstats != 0) ) return(18301);
    return (0);
}

void gf_stats_transform_apply (
    ST_double *buffer,
    GT_size   nj,
    ST_double tcode,
    ST_double *stats)
{
    ST_double *dblptr;
    if ( tcode == -1 ) {
        if ( (stats[0] < SV_missval) && (stats[1] < SV_missval) ) {
            for (dblptr = buffer; dblptr < buffer + nj; dblptr++) {
                if ( *dblptr < SV_missval ) {
                    *dblptr = (*dblptr - stats[0]) / stats[1];
                }
            }
        }
        else {
            for (dblptr = buffer; dblptr < buffer + nj; dblptr++) {
                *dblptr = SV_missval;
            }
        }
    }
    else if ( tcode == -2 ) {
        if ( stats[0] < SV_missval ) {
            for (dblptr = buffer; dblptr < buffer + nj; dblptr++) {
                if ( *dblptr < SV_missval ) {
                    *dblptr = (*dblptr - stats[0]);
                }
            }
        }
        else {
            for (dblptr = buffer; dblptr < buffer + nj; dblptr++) {
                *dblptr = SV_missval;
            }
        }
    }
    else if ( tcode == -3 ) {
        if ( stats[0] < SV_missval ) {
            for (dblptr = buffer; dblptr < buffer + nj; dblptr++) {
                if ( *dblptr < SV_missval ) {
                    *dblptr = (*dblptr - stats[0]);
                }
            }
        }
        else {
            for (dblptr = buffer; dblptr < buffer + nj; dblptr++) {
                *dblptr = SV_missval;
            }
        }
    }
    // moving stat implemented sepparately in gf_stats_transform_moving
    // range stat implemented sepparately in gf_stats_transform_range
    // rank stat implemented sepparately in gf_stats_transform_rank
}

/*********************************************************************
 *                            Range stats                            *
 *********************************************************************/

void gf_stats_transform_range(
    ST_double *buffer,
    ST_double *wbuffer,
    ST_double *ibuffer,
    ST_double *sbuffer,
    GT_int    *indeces,
    GT_size   nj,
    ST_double scode,
    GT_bool   aweights,
    ST_double *pbuffer,
    ST_double *output,
    ST_double lower,
    ST_double upper,
    ST_double lcode,
    ST_double ucode,
    GT_bool   excludeself,
    GT_bool   excludebounds)
{

    // NOTE: The logic is commented in chunk 5
    //
    // excludeself (0, 1)
    // excludebounds (0, 1)
    //
    // 1. weighted
    //     both bounds
    //         lower and upper stat
    //         lower stat only
    //         upper stat only
    //         no bounds stat
    //     upper bound only
    //         upper stat
    //         no bounds stat
    //     lower bound only
    //         lower stat
    //         no bounds stat
    //     no bounds
    // 2. non-weighted
    //     both bounds
    //         lower and upper stat
    //         lower stat only
    //         upper stat only
    //         no bounds stat
    //     upper bound only
    //         upper stat
    //         no bounds stat
    //     lower bound only
    //         lower stat
    //         no bounds stat
    //     no bounds

    GT_size   nrange;
    GT_int    i, ixl, ixu;
    GT_bool   wgt = (wbuffer != NULL), nomissing = 0;
    ST_double z, zlow, zhigh, ldbl, udbl;
    ST_double *sptr, *eptr;
    GT_int    *ixlower = indeces;
    GT_int    *ixupper = indeces + nj;

    if ( wgt ) {
        if ( (upper < SV_missval) && (lower < SV_missval) ) {

            /*********************************************************************
             *                     1. weight with two bounds                     *
             *********************************************************************/

            if ( lcode != 0 ) {
                ldbl = lower * gf_stats_transform_stat_weighted(
                    ibuffer,
                    wbuffer,
                    nj,
                    lcode,
                    aweights,
                    pbuffer
                );
            }
            else {
                ldbl = lower;
            }

            if ( ucode != 0 ) {
                udbl = upper * gf_stats_transform_stat_weighted(
                    ibuffer,
                    wbuffer,
                    nj,
                    ucode,
                    aweights,
                    pbuffer
                );
            }
            else {
                udbl = upper;
            }

            gf_stats_transform_range_sort(buffer, wbuffer, ibuffer, sbuffer, nj);

            ixl  = 0;
            ixu  = nj;
            sptr = sbuffer;
            eptr = sbuffer + 4 * (nj - 1);

            nrange = nj;
            while ( (nrange > 0) && !(*eptr < SV_missval) ) {
                ixu--;
                nrange--;
                eptr -= 4;
            }

            if ( excludebounds ) {
                for (i = 0; i < nrange; i++, sptr += 4, eptr -= 4) {
                    zlow = *sptr + ldbl;
                    while ( (ixl < (nrange - 1)) && (zlow >= sbuffer[4 * ixl]) ) {
                        ixl++;
                    }
                    if ( (ixl < nrange) && (zlow >= sbuffer[4 * ixl]) ) ixl++;
                    ixlower[i] = ixl;

                    zhigh = *eptr + udbl;
                    while ( (ixu > 1) && (zhigh <= sbuffer[4 * (ixu - 1)]) ) {
                        ixu--;
                    }
                    if ( (ixu > 0)  && (zhigh <= sbuffer[4 * (ixu - 1)]) ) ixu--;
                    ixupper[nrange - i - 1] = ixu;

                    buffer[i]  = *(sptr + 1);
                    wbuffer[i] = *(sptr + 2);
                }
            }
            else {
                for (i = 0; i < nrange; i++, sptr += 4, eptr -= 4) {
                    zlow = *sptr + ldbl;
                    while ( (ixl < (nrange - 1)) && (zlow > sbuffer[4 * ixl]) ) {
                        ixl++;
                    }
                    if ( (ixl < nrange) && (zlow > sbuffer[4 * ixl]) ) ixl++;
                    ixlower[i] = ixl;

                    zhigh = *eptr + udbl;
                    while ( (ixu > 1) && (zhigh < sbuffer[4 * (ixu - 1)]) ) {
                        ixu--;
                    }
                    if ( (ixu > 0)  && (zhigh < sbuffer[4 * (ixu - 1)]) ) ixu--;
                    ixupper[nrange - i - 1] = ixu;

                    buffer[i]  = *(sptr + 1);
                    wbuffer[i] = *(sptr + 2);
                }
            }

            if ( excludeself ) {
                for (i = 0; i < nrange; i++) {
                    if ( i == ixlower[i]       ) ixlower[i]++;
                    if ( i == (ixupper[i] - 1) ) ixupper[i]--;

                    if ( ixupper[i] > ixlower[i] ) {
                        if ( i > ixlower[i] && i < ixupper[i] ) {
                            output[i] = gf_stats_transform_stat_weighted_exclude(
                                buffer + ixlower[i],
                                wbuffer + ixlower[i],
                                ixupper[i] - ixlower[i],
                                scode,
                                aweights,
                                pbuffer,
                                i - ixlower[i]
                            );
                        }
                        else {
                            output[i] = gf_stats_transform_stat_weighted(
                                buffer + ixlower[i],
                                wbuffer + ixlower[i],
                                ixupper[i] - ixlower[i],
                                scode,
                                aweights,
                                pbuffer
                            );
                        }
                    }
                    else if ( scode == -6 || scode == -14 ) {
                        output[i] = 0;
                    }
                    else {
                        output[i] = SV_missval;
                    }
                }
            }
            else {
                ixl = nj + 1; ixu = -1; z = SV_missval;
                for (i = 0; i < nrange; i++) {
                    if ( (ixl != ixlower[i]) || (ixu != ixupper[i]) ) { // if i = 0 this evals to False
                        ixl = ixlower[i];
                        ixu = ixupper[i];
                        if ( ixu > ixl ) {
                            z = gf_stats_transform_stat_weighted(
                                buffer + ixl,
                                wbuffer + ixl,
                                ixu - ixl,
                                scode,
                                aweights,
                                pbuffer
                            );
                        }
                        else if ( scode == -6 || scode == -14 ) {
                            z = 0;
                        }
                        else {
                            z = SV_missval;
                        }
                    }
                    output[i] = z;
                }
            }

            // Now set missing values
            for (i = nrange; i < nj; i++) {
                output[i] = SV_missval;
            }

            sptr = sbuffer + 3;
            for (i = 0; i < nj; i++, sptr += 4) {
                buffer[(GT_size) *sptr]  = output[i];
                pbuffer[(GT_size) *sptr] = wbuffer[i];
            }
            memcpy(wbuffer, pbuffer, nj * sizeof(ST_double));

        }
        else if ( upper < SV_missval ) {

            /*********************************************************************
             *                  2. weight with upper bound only                  *
             *********************************************************************/

            if ( ucode != 0 ) {
                udbl = upper * gf_stats_transform_stat_weighted(
                    ibuffer,
                    wbuffer,
                    nj,
                    ucode,
                    aweights,
                    pbuffer
                );
            }
            else {
                udbl = upper;
            }

            gf_stats_transform_range_sort(buffer, wbuffer, ibuffer, sbuffer, nj);

            ixu  = nj;
            sptr = sbuffer;
            eptr = sbuffer + 4 * (nj - 1);

            nrange = nj;
            while ( (nrange > 0) && !(*eptr < SV_missval) ) {
                ixu--;
                nrange--;
                eptr -= 4;
            }

            if ( excludebounds ) {
                for (i = 0; i < nrange; i++, sptr += 4, eptr -= 4) {
                    zhigh = *eptr + udbl;
                    while ( (ixu > 1) && (zhigh <= sbuffer[4 * (ixu - 1)]) ) {
                        ixu--;
                    }
                    if ( (ixu > 0)  && (zhigh <= sbuffer[4 * (ixu - 1)]) ) ixu--;
                    ixupper[nrange - i - 1] = ixu;
                    ixlower[i] = 0;
                    buffer[i]  = *(sptr + 1);
                    wbuffer[i] = *(sptr + 2);
                }
            }
            else {
                for (i = 0; i < nrange; i++, sptr += 4, eptr -= 4) {
                    zhigh = *eptr + udbl;
                    while ( (ixu > 1) && (zhigh < sbuffer[4 * (ixu - 1)]) ) {
                        ixu--;
                    }
                    if ( (ixu > 0)  && (zhigh < sbuffer[4 * (ixu - 1)]) ) ixu--;
                    ixupper[nrange - i - 1] = ixu;
                    ixlower[i] = 0;
                    buffer[i]  = *(sptr + 1);
                    wbuffer[i] = *(sptr + 2);
                }
            }

            if ( excludeself ) {
                for (i = 0; i < nrange; i++) {
                    if ( i == (ixupper[i] - 1) ) ixupper[i]--;

                    if ( ixupper[i] > 0 ) {
                        if ( i < ixupper[i] ) {
                            output[i] = gf_stats_transform_stat_weighted_exclude(
                                buffer,
                                wbuffer,
                                ixupper[i],
                                scode,
                                aweights,
                                pbuffer,
                                i
                            );
                        }
                        else {
                            output[i] = gf_stats_transform_stat_weighted(
                                buffer,
                                wbuffer,
                                ixupper[i],
                                scode,
                                aweights,
                                pbuffer
                            );
                        }
                    }
                    else if ( scode == -6 || scode == -14 ) {
                        output[i] = 0;
                    }
                    else {
                        output[i] = SV_missval;
                    }
                }
            }
            else {
                ixu = -1; z = SV_missval;
                for (i = 0; i < nrange; i++) {
                    if ( ixu != ixupper[i] ) { // if i = 0 this evals to False
                        ixu = ixupper[i];
                        if ( ixu > 0 ) {
                            z = gf_stats_transform_stat_weighted(
                                buffer,
                                wbuffer,
                                ixu,
                                scode,
                                aweights,
                                pbuffer
                            );
                        }
                        else if ( scode == -6 || scode == -14 ) {
                            z = 0;
                        }
                        else {
                            z = SV_missval;
                        }
                    }
                    output[i] = z;
                }
            }

            // Now set missing values
            for (i = nrange; i < nj; i++) {
                output[i] = SV_missval;
            }

            sptr = sbuffer + 3;
            for (i = 0; i < nj; i++, sptr += 4) {
                buffer[(GT_size) *sptr]  = output[i];
                pbuffer[(GT_size) *sptr] = wbuffer[i];
            }
            memcpy(wbuffer, pbuffer, nj * sizeof(ST_double));

        }
        else if ( lower < SV_missval ) {

            /*********************************************************************
             *                  3. weight with lower bound only                  *
             *********************************************************************/

            if ( lcode != 0 ) {
                ldbl = lower * gf_stats_transform_stat_weighted(
                    ibuffer,
                    wbuffer,
                    nj,
                    lcode,
                    aweights,
                    pbuffer
                );
            }
            else {
                ldbl = lower;
            }

            gf_stats_transform_range_sort(buffer, wbuffer, ibuffer, sbuffer, nj);

            ixl  = 0;
            sptr = sbuffer;
            eptr = sbuffer + 4 * (nj - 1);

            nrange = nj;
            while ( (nrange > 0) && !(*eptr < SV_missval) ) {
                nrange--;
                eptr -= 4;
            }

            if ( excludebounds ) {
                for (i = 0; i < nrange; i++, sptr += 4) {
                    zlow = *sptr + ldbl;
                    while ( (ixl < (nrange - 1)) && (zlow >= sbuffer[4 * ixl]) ) {
                        ixl++;
                    }
                    if ( (ixl < nrange) && (zlow >= sbuffer[4 * ixl]) ) ixl++;
                    ixlower[i] = ixl;
                    ixupper[i] = nrange;
                    buffer[i]  = *(sptr + 1);
                    wbuffer[i] = *(sptr + 2);
                }
            }
            else {
                for (i = 0; i < nrange; i++, sptr += 4) {
                    zlow = *sptr + ldbl;
                    while ( (ixl < (nrange - 1)) && (zlow > sbuffer[4 * ixl]) ) {
                        ixl++;
                    }
                    if ( (ixl < nrange) && (zlow > sbuffer[4 * ixl]) ) ixl++;
                    ixlower[i] = ixl;
                    ixupper[i] = nrange;
                    buffer[i]  = *(sptr + 1);
                    wbuffer[i] = *(sptr + 2);
                }
            }

            if ( excludeself ) {
                for (i = 0; i < nrange; i++) {
                    if ( i == ixlower[i] ) ixlower[i]++;

                    if ( nrange > ixlower[i] ) {
                        if ( i > ixlower[i] && i < nrange ) {
                            output[i] = gf_stats_transform_stat_weighted_exclude(
                                buffer + ixlower[i],
                                wbuffer + ixlower[i],
                                nrange - ixlower[i],
                                scode,
                                aweights,
                                pbuffer,
                                i - ixlower[i]
                            );
                        }
                        else {
                            output[i] = gf_stats_transform_stat_weighted(
                                buffer + ixlower[i],
                                wbuffer + ixlower[i],
                                nrange - ixlower[i],
                                scode,
                                aweights,
                                pbuffer
                            );
                        }
                    }
                    else if ( scode == -6 || scode == -14 ) {
                        output[i] = 0;
                    }
                    else {
                        output[i] = SV_missval;
                    }
                }
            }
            else {
                ixl = nj + 1; z = SV_missval;
                for (i = 0; i < nrange; i++) {
                    if ( ixl != ixlower[i] ) { // if i = 0 this evals to False
                        ixl = ixlower[i];
                        if ( nrange > ixl ) {
                            z = gf_stats_transform_stat_weighted(
                                buffer + ixl,
                                wbuffer + ixl,
                                nrange - ixl,
                                scode,
                                aweights,
                                pbuffer
                            );
                        }
                        else if ( scode == -6 || scode == -14 ) {
                            z = 0;
                        }
                        else {
                            z = SV_missval;
                        }
                    }
                    output[i] = z;
                }
            }

            // Now set missing values
            for (i = nrange; i < nj; i++) {
                output[i] = SV_missval;
            }

            sptr = sbuffer + 3;
            for (i = 0; i < nj; i++, sptr += 4) {
                buffer[(GT_size) *sptr]  = output[i];
                pbuffer[(GT_size) *sptr] = wbuffer[i];
            }
            memcpy(wbuffer, pbuffer, nj * sizeof(ST_double));

        }
        else {

            /*********************************************************************
             *                     4. weight with no bounds                      *
             *********************************************************************/

            if ( excludeself ) {
                for (i = 0; i < nj; i++) {
                    output[i] = gf_stats_transform_stat_weighted_exclude(
                        buffer,
                        wbuffer,
                        nj,
                        scode,
                        aweights,
                        pbuffer,
                        i
                    );
                }
                memcpy(buffer, output, nj * sizeof(ST_double));
            }
            else {
                z = gf_stats_transform_stat_weighted(
                    buffer,
                    wbuffer,
                    nj,
                    scode,
                    aweights,
                    pbuffer
                );
                for (i = 0; i < nj; i++) {
                    buffer[i] = z;
                }
            }
        }
    }
    else {
        if ( (upper < SV_missval) && (lower < SV_missval) ) {

            /*********************************************************************
             *                          5. bounds only                           *
             *********************************************************************/

            // Compute the upper and lower bounds on the range. If a
            // statistic was requested, compute scalar * stat.

            if ( lcode != 0 ) {
                ldbl = lower * gf_stats_transform_stat(ibuffer, pbuffer, nj, lcode, 0);
            }
            else {
                ldbl = lower;
            }

            if ( ucode != 0 ) {
                udbl = upper * gf_stats_transform_stat(ibuffer, pbuffer, nj, ucode, 0);
            }
            else {
                udbl = upper;
            }

            // Now sort the data based on the range reference
            // variable. The lazy thing to do is O(n^2):
            //
            // for (i = 0; i < nj; i++)
            //     zlow  = intvar[i] + lbdl
            //     zhigh = intvar[i] + ubdl
            //     k     = 0
            //     for (j = 0; j < nj; j++)
            //         if ( zlow < intvar[j] zhigh )
            //             buffer[k++] = buffer[j]
            //
            //     gf_stats_transform_stat(buffer, pbuffer, k, scode, 0)
            //
            // This is very slow. It is amazingly way faster to sort the
            // data first and then get the indeces for the start and end
            // positions of the range relative to each variable.

            gf_stats_transform_range_sort(buffer, wbuffer, ibuffer, sbuffer, nj);

            // The idea is simple: In the sorted range, the starting position
            // is defined by the first value that is greater than the lower
            // bound, and the ending position is the first value lower than th
            // eupper bound (counting from the end of the range).
            //
            // The bounds are identical for every value, so if you have the
            // starting positon for i, call it start[i], you only need to look
            // from start[i] onward for the starting position for i + 1, and
            // start[i + 1} for i + 2, and so on. For the ending position,
            // end[i], you only need to look from end[i] backwards for i - 1,
            // end[i - 1] backwards for i - 2, and so on.

            // ixl is the starting index and ixu is the ending. sptr
            // references the current value to use for the lower bound
            // and eptr the value to use for the upper bound. Note that
            // because the array is sorted, missing values are at the
            // end.

            ixl  = 0;
            ixu  = nj;
            sptr = sbuffer;
            eptr = sbuffer + 3 * (nj - 1);

            nrange = nj;
            while ( (nrange > 0) && !(*eptr < SV_missval) ) {
                ixu--;
                nrange--;
                eptr -= 3;
            }

            if ( excludebounds ) {
                for (i = 0; i < nrange; i++, sptr += 3, eptr -= 3) {
                    zlow = *sptr + ldbl;
                    while ( (ixl < (nrange - 1)) && (zlow >= sbuffer[3 * ixl]) ) {
                        ixl++;
                    }
                    if ( (ixl < nrange) && (zlow >= sbuffer[3 * ixl]) ) ixl++;
                    ixlower[i] = ixl;

                    zhigh = *eptr + udbl;
                    while ( (ixu > 1) && (zhigh <= sbuffer[3 * (ixu - 1)]) ) {
                        ixu--;
                    }
                    if ( (ixu > 0)  && (zhigh <= sbuffer[3 * (ixu - 1)]) ) ixu--;
                    ixupper[nrange - i - 1] = ixu;

                    buffer[i] = *(sptr + 1);
                }
            }
            else {
                for (i = 0; i < nrange; i++, sptr += 3, eptr -= 3) {

                    // while the current starting index gives a value
                    // higher than the reference lower bound, increase
                    // the starting index. For instance, suppose the
                    // lower bound is -2 and we have the array:
                    //
                    //     1 4 5
                    //
                    // now
                    //
                    //     i = 0, ixl = 0, 1 - 2 = -1 > 1 (false)
                    //
                    // so the first lower bound is 0. Now
                    //
                    //     i = 1, ixl = 0, 4 - 2 = 2 > 1 (true)
                    //
                    // So we need to increment ixl by 1. Now
                    //
                    //     i = 1, ixl = 1, 4 - 2 = 2 > 4 (false)
                    //
                    // so the second lower bound is 1. Similarly the
                    // third lower bound is also 1:
                    //
                    //     i = 2, ixl = 1, 5 - 2 = 3 > 4 (false)

                    zlow = *sptr + ldbl;
                    while ( (ixl < (nrange - 1)) && (zlow > sbuffer[3 * ixl]) ) {
                        ixl++;
                    }
                    if ( (ixl < nrange) && (zlow > sbuffer[3 * ixl]) ) ixl++;
                    ixlower[i] = ixl;

                    // while the current ending index gives a value
                    // lower than the reference upper bound, decrease
                    // the ending index. For instance, suppose the
                    // upper bound is 1 and we have the array:
                    //
                    //     1 4 5
                    //
                    // now
                    //
                    //     i = 2, ixu = 3, 5 + 1 = 6 < 5 (false)
                    //
                    // so the first upper bound is 3. Now
                    //
                    //     i = 1, ixu = 3, 4 + 1 = 5 < 5 (false)
                    //
                    // so the second upper bound is also 3. Last
                    //
                    //     i = 0, ixu = 3, 1 + 1 = 2 < 5 (true)
                    //     i = 0, ixu = 2, 1 + 1 = 2 < 4 (true)
                    //     i = 0, ixu = 1, 1 + 1 = 2 < 1 (false)
                    //
                    // so the last upper bound is 1.

                    zhigh = *eptr + udbl;
                    while ( (ixu > 1) && (zhigh < sbuffer[3 * (ixu - 1)]) ) {
                        ixu--;
                    }
                    if ( (ixu > 0)  && (zhigh < sbuffer[3 * (ixu - 1)]) ) ixu--;
                    ixupper[nrange - i - 1] = ixu;

                    buffer[i] = *(sptr + 1);
                }
            }

            // Finally we compute the statistic based on the start and end
            // positions. Note we made a copy of buffer in the sort order
            // of ibuffer. If ixlower[i] = nj or ixupper[i] = 0 then the
            // reference variable.
            //
            // Note that summary stats assume that a length of 0 does not
            // mean no observations; rather, it means that every observation
            // is missing, and handles that accordingly. In this case,
            // however, if the lower index is greater than or equal to the
            // upper index, it means that no element matches the subset
            // criteria, and that actually does meet the 'no observations'
            // criteria. If count or freq were requested then the answer is
            // 0, but for ever other stat the answer is missing.
            //
            // For this reason we have a special way to hantdle
            // 'excludeself', which means to exclude the current obs from he
            // statistic.

            if ( excludeself ) {
                for (i = 0; i < nrange; i++) {
                    if ( i == ixlower[i]       ) ixlower[i]++;
                    if ( i == (ixupper[i] - 1) ) ixupper[i]--;

                    if ( ixupper[i] > ixlower[i] ) {
                        if ( i > ixlower[i] && i < ixupper[i] ) {
                            output[i] = gf_stats_transform_stat_exclude(
                                buffer + ixlower[i],
                                pbuffer,
                                ixupper[i] - ixlower[i],
                                scode,
                                0,
                                i - ixlower[i]
                            );
                        }
                        else {
                            output[i] = gf_stats_transform_stat(
                                buffer + ixlower[i],
                                pbuffer,
                                ixupper[i] - ixlower[i],
                                scode,
                                0
                            );
                        }
                    }
                    else if ( scode == -6 || scode == -14 ) {
                        output[i] = 0;
                    }
                    else {
                        output[i] = SV_missval;
                    }
                }
            }
            else {

                // Optimized for duplicates in range variable (each
                // repeat observation in the range variable will give the
                // same stat, since the reference range is the same; since
                // this was sorted we can simply copy the first stat to
                // every subsequent observation until the range changes).

                ixl = nj + 1; ixu = -1; z = SV_missval;
                for (i = 0; i < nrange; i++) {
                    if ( (ixl != ixlower[i]) || (ixu != ixupper[i]) ) { // if i = 0 this evals to False
                        ixl = ixlower[i];
                        ixu = ixupper[i];
                        if ( ixu > ixl ) {
                            z = gf_stats_transform_stat(
                                buffer + ixl,
                                pbuffer,
                                ixu - ixl,
                                scode,
                                0
                            );
                        }
                        else if ( scode == -6 || scode == -14 ) {
                            z = 0;
                        }
                        else {
                            z = SV_missval;
                        }
                    }
                    output[i] = z;
                }
            }

            // Now set missing values
            for (i = nrange; i < nj; i++) {
                output[i] = SV_missval;
            }

            sptr = sbuffer + 2;
            for (i = 0; i < nj; i++, sptr += 3) {
                buffer[(GT_size) *sptr] = output[i];
            }

        }
        else if ( upper < SV_missval ) {

            /*********************************************************************
             *                        6. upper bound only                        *
             *********************************************************************/

            if ( ucode != 0 ) {
                udbl = upper * gf_stats_transform_stat(ibuffer, pbuffer, nj, ucode, 0);
            }
            else {
                udbl = upper;
            }

            gf_stats_transform_range_sort(buffer, wbuffer, ibuffer, sbuffer, nj);

            ixu  = nj;
            sptr = sbuffer;
            eptr = sbuffer + 3 * (nj - 1);

            nrange = nj;
            while ( (nrange > 0) && !(*eptr < SV_missval) ) {
                ixu--;
                nrange--;
                eptr -= 3;
            }

            if ( excludebounds ) {
                for (i = 0; i < nrange; i++, sptr += 3, eptr -= 3) {
                    zhigh = *eptr + udbl;
                    while ( (ixu > 1) && (zhigh <= sbuffer[3 * (ixu - 1)]) ) {
                        ixu--;
                    }
                    if ( (ixu > 0)  && (zhigh <= sbuffer[3 * (ixu - 1)]) ) ixu--;
                    ixupper[nrange - i - 1] = ixu;
                    ixlower[i] = 0;
                    buffer[i]  = *(sptr + 1);
                }
            }
            else {
                for (i = 0; i < nrange; i++, sptr += 3, eptr -= 3) {
                    zhigh = *eptr + udbl;
                    while ( (ixu > 1) && (zhigh < sbuffer[3 * (ixu - 1)]) ) {
                        ixu--;
                    }
                    if ( (ixu > 0)  && (zhigh < sbuffer[3 * (ixu - 1)]) ) ixu--;
                    ixupper[nrange - i - 1] = ixu;
                    ixlower[i] = 0;
                    buffer[i]  = *(sptr + 1);
                }
            }

            if ( excludeself ) {
                for (i = 0; i < nrange; i++) {
                    if ( i == (ixupper[i] - 1) ) ixupper[i]--;

                    if ( ixupper[i] > 0 ) {
                        if ( i < ixupper[i] ) {
                            output[i] = gf_stats_transform_stat_exclude(
                                buffer,
                                pbuffer,
                                ixupper[i],
                                scode,
                                0,
                                i
                            );
                        }
                        else {
                            output[i] = gf_stats_transform_stat(
                                buffer,
                                pbuffer,
                                ixupper[i],
                                scode,
                                0
                            );
                        }
                    }
                    else if ( scode == -6 || scode == -14 ) {
                        output[i] = 0;
                    }
                    else {
                        output[i] = SV_missval;
                    }
                }
            }
            else {
                ixu = -1; z = SV_missval;
                for (i = 0; i < nrange; i++) {
                    if ( ixu != ixupper[i] ) { // if i = 0 this evals to False
                        ixu = ixupper[i];
                        if ( ixu > 0 ) {
                            z = gf_stats_transform_stat(
                                buffer,
                                pbuffer,
                                ixu,
                                scode,
                                0
                            );
                        }
                        else if ( scode == -6 || scode == -14 ) {
                            z = 0;
                        }
                        else {
                            z = SV_missval;
                        }
                    }
                    output[i] = z;
                }
            }

            for (i = nrange; i < nj; i++) {
                output[i] = SV_missval;
            }

            sptr = sbuffer + 2;
            for (i = 0; i < nj; i++, sptr += 3) {
                buffer[(GT_size) *sptr] = output[i];
            }

        }
        else if ( lower < SV_missval ) {

            /*********************************************************************
             *                        7. lower bound only                        *
             *********************************************************************/

            if ( lcode != 0 ) {
                ldbl = lower * gf_stats_transform_stat(ibuffer, pbuffer, nj, lcode, 0);
            }
            else {
                ldbl = lower;
            }

            gf_stats_transform_range_sort(buffer, wbuffer, ibuffer, sbuffer, nj);

            ixl  = 0;
            sptr = sbuffer;
            eptr = sbuffer + 3 * (nj - 1);

            nrange = nj;
            while ( (nrange > 0) && !(*eptr < SV_missval) ) {
                nrange--;
                eptr -= 3;
            }

            if ( excludebounds ) {
                for (i = 0; i < nrange; i++, sptr += 3) {
                    zlow = *sptr + ldbl;
                    while ( (ixl < (nrange - 1)) && (zlow >= sbuffer[3 * ixl]) ) {
                        ixl++;
                    }
                    if ( (ixl < nrange) && (zlow >= sbuffer[3 * ixl]) ) ixl++;
                    ixlower[i] = ixl;
                    ixupper[i] = nrange;
                    buffer[i]  = *(sptr + 1);
                }
            }
            else {
                for (i = 0; i < nrange; i++, sptr += 3) {
                    zlow = *sptr + ldbl;
                    while ( (ixl < (nrange - 1)) && (zlow > sbuffer[3 * ixl]) ) {
                        ixl++;
                    }
                    if ( (ixl < nrange) && (zlow > sbuffer[3 * ixl]) ) ixl++;
                    ixlower[i] = ixl;
                    ixupper[i] = nrange;
                    buffer[i]  = *(sptr + 1);
                }
            }

            if ( excludeself ) {
                for (i = 0; i < nrange; i++) {
                    if ( i == ixlower[i] ) ixlower[i]++;

                    if ( nrange > ixlower[i] ) {
                        if ( i > ixlower[i] ) {
                            output[i] = gf_stats_transform_stat_exclude(
                                buffer + ixlower[i],
                                pbuffer,
                                nrange - ixlower[i],
                                scode,
                                0,
                                i - ixlower[i]
                            );
                        }
                        else {
                            output[i] = gf_stats_transform_stat(
                                buffer + ixlower[i],
                                pbuffer,
                                nrange - ixlower[i],
                                scode,
                                0
                            );
                        }
                    }
                    else if ( scode == -6 || scode == -14 ) {
                        output[i] = 0;
                    }
                    else {
                        output[i] = SV_missval;
                    }
                }
            }
            else {
                ixl = nj + 1; z = SV_missval;
                for (i = 0; i < nrange; i++) {
                    if ( ixl != ixlower[i] ) { // if i = 0 this evals to False
                        ixl = ixlower[i];
                        if ( nrange > ixl ) {
                            z = gf_stats_transform_stat(
                                buffer + ixl,
                                pbuffer,
                                nrange - ixl,
                                scode,
                                0
                            );
                        }
                        else if ( scode == -6 || scode == -14 ) {
                            z = 0;
                        }
                        else {
                            z = SV_missval;
                        }
                    }
                    output[i] = z;
                }
            }

            // Now set missing values
            for (i = nrange; i < nj; i++) {
                output[i] = SV_missval;
            }

            sptr = sbuffer + 2;
            for (i = 0; i < nj; i++, sptr += 3) {
                buffer[(GT_size) *sptr] = output[i];
            }

        }
        else {

            /*********************************************************************
             *                           8. no bounds                            *
             *********************************************************************/

            if ( excludeself ) {
                nomissing = 1;
                for (i = 0; i < nj; i++) {
                    if ( !(buffer[i] < SV_missval) ) {
                        nomissing = 0;
                        break;
                    }
                }

                for (i = 0; i < nj; i++) {
                    // output[i] = gf_stats_transform_stat_exclude(buffer, pbuffer, nj, scode, 0, i);
                    z         = buffer[i];
                    buffer[i] = buffer[0];
                    output[i] = gf_stats_transform_stat(buffer + 1, buffer + 1, nj - 1, scode, nomissing);
                    buffer[0] = z;
                }
                memcpy(buffer, output, nj * sizeof(ST_double));
            }
            else {
                z = gf_stats_transform_stat(buffer, pbuffer, nj, scode, 0);
                for (i = 0; i < nj; i++) {
                    buffer[i] = z;
                }
            }
        }
    }
}

void gf_stats_transform_range_sort(
    ST_double *buffer,
    ST_double *wbuffer,
    ST_double *ibuffer,
    ST_double *sbuffer,
    GT_size   nj)
{
    GT_size i;
    GT_bool wgt = (wbuffer != NULL);

    if ( wgt ) {
        for (i = 0; i < nj; i++) {
            sbuffer[i * 4 + 0] = ibuffer[i];
            sbuffer[i * 4 + 1] = buffer[i];
            sbuffer[i * 4 + 2] = wbuffer[i];
            sbuffer[i * 4 + 3] = i;
        }

        quicksort_bsd (
            sbuffer,
            nj,
            4 * (sizeof *sbuffer),
            xtileCompare,
            NULL
        );
    }
    else {
        for (i = 0; i < nj; i++) {
            sbuffer[i * 3 + 0] = ibuffer[i];
            sbuffer[i * 3 + 1] = buffer[i];
            sbuffer[i * 3 + 2] = i;
        }

        quicksort_bsd (
            sbuffer,
            nj,
            3 * (sizeof *sbuffer),
            xtileCompare,
            NULL
        );

    }
}

/*********************************************************************
 *                            Rank values                            *
 *********************************************************************/

void gf_stats_transform_rank(
    ST_double *buffer,
    ST_double *wbuffer,
    GT_size   nj,
    GT_size   ties,
    GT_bool   aweights,
    ST_double *sbuffer,
    ST_double *output)
{

    GT_size i, iprev, j, rank, nrank, nonmiss;
    ST_double z, wcum, rankdbl, nrankdbl;
    GT_size invert[2]; invert[0] = 0; invert[1] = 0;

    if ( wbuffer != NULL ) {
        nonmiss = 0;
        for (i = 0; i < nj; i++) {
            if ( buffer[i] < SV_missval && wbuffer[i] < SV_missval ) {
                sbuffer[nonmiss * 3 + 0] = buffer[i];
                sbuffer[nonmiss * 3 + 1] = i;
                sbuffer[nonmiss * 3 + 2] = wbuffer[i];
                nonmiss++;
            }
        }

        // NOTE: Field (2) counts # higher than, effectively inverting the
        // ranking. UniqueStable (5) uses a stable sort to break ties.

        if ( ties == 2 ) {
            quicksort_bsd (
                sbuffer,
                nonmiss,
                3 * (sizeof *sbuffer),
                xtileCompareInvert,
                NULL
            );
        }
        else if ( ties == 5 ) {
            MultiQuicksortDbl(
                sbuffer,
                nonmiss,
                0,
                1,
                3 * (sizeof *sbuffer),
                invert
            );
        }
        else {
            quicksort_bsd (
                sbuffer,
                nonmiss,
                3 * (sizeof *sbuffer),
                xtileCompare,
                NULL
            );
        }

        // NOTE: With weights, we count the value of the weight to use
        // as the ranking. Note that

        if ( ties == 1 ) {
            i = 0;
            wcum = 0;
            while ( i < nonmiss) {
                iprev    = i;
                z        = sbuffer[i * 3];
                nrankdbl = wcum;
                rankdbl  = 0;
                while ( i < nonmiss && z == sbuffer[i * 3] ) {
                    rankdbl  += sbuffer[i * 3 + 2] * (nrankdbl + (sbuffer[i * 3 + 2] + 1) / 2);
                    nrankdbl += sbuffer[i * 3 + 2];
                    i++;
                }
                rankdbl /= (nrankdbl - wcum);
                wcum     = nrankdbl;
                for (j = iprev; j < i; j++) {
                    buffer[(GT_size) sbuffer[j * 3 + 1]] = rankdbl;
                }
            }
        }
        else if ( ties == 2 || ties == 3 ) {

            // NOTE: Field (2) and track (3) are mirrors of each other
            // and the only difference should be how the vector was
            // sorted: ascending gives track, descending gives field.

            z = *sbuffer;
            rankdbl = wcum = 0;
            for (i = 0; i < nonmiss; i++) {
                if ( z != sbuffer[i * 3] ) {
                    rankdbl = wcum;
                    z = sbuffer[i * 3];
                }
                wcum += sbuffer[i * 3 + 2];
                buffer[(GT_size) sbuffer[i * 3 + 1]] = 1 + rankdbl;
            }
        }
        else if ( ties == 4 || ties == 5 ) {
            rankdbl = 0;
            for (i = 0; i < nonmiss; i++) {
                rankdbl += sbuffer[i * 3 + 2];
                buffer[(GT_size) sbuffer[i * 3 + 1]] = rankdbl;
            }
        }
    }
    else {
        nonmiss = 0;
        for (i = 0; i < nj; i++) {
            if ( buffer[i] < SV_missval ) {
                sbuffer[nonmiss * 2 + 0] = buffer[i];
                sbuffer[nonmiss * 2 + 1] = i;
                nonmiss++;
            }
        }

        // NOTE: Field (2) counts # higher than, effectively inverting
        // the ranking

        if ( ties == 2 ) {
            quicksort_bsd (
                sbuffer,
                nonmiss,
                2 * (sizeof *sbuffer),
                xtileCompareInvert,
                NULL
            );
        }
        else if ( ties == 5 ) {
            MultiQuicksortDbl(
                sbuffer,
                nonmiss,
                0,
                1,
                2 * (sizeof *sbuffer),
                invert
            );
        }
        else {
            quicksort_bsd (
                sbuffer,
                nonmiss,
                2 * (sizeof *sbuffer),
                xtileCompare,
                NULL
            );
        }

        if ( ties == 1 ) {
            i = 0;
            while ( i < nonmiss) {
                iprev   = i;
                z       = sbuffer[i * 2];
                rankdbl = i;
                nrank   = 1;
                while ( i < nonmiss && z == sbuffer[i * 2] ) {
                    nrank++;
                    i++;
                }
                rankdbl += ((nrank % 2)? (0.5 * nrank): (nrank / 2));
                for (j = iprev; j < i; j++) {
                    buffer[(GT_size) sbuffer[j * 2 + 1]] = rankdbl;
                }
            }
        }
        else if ( ties == 2 || ties == 3 ) {

            // NOTE: Field (2) and track (3) are mirrors of each other
            // and the only difference should be how the vector was
            // sorted: ascending gives track, descending gives field.

            z = *sbuffer;
            rank = 1;
            for (i = 0; i < nonmiss; i++) {
                if ( z != sbuffer[i * 2] ) {
                    rank = i + 1;
                    z = sbuffer[i * 2];
                }
                buffer[(GT_size) sbuffer[i * 2 + 1]] = rank;
            }
        }
        else if ( ties == 4 || ties == 5 ) {
            for (i = 0; i < nonmiss; i++) {
                buffer[(GT_size) sbuffer[i * 2 + 1]] = i + 1;
            }
        }
    }

}

/*********************************************************************
 *                           Moving stats                            *
 *********************************************************************/

void gf_stats_transform_moving(
    ST_double *buffer,
    ST_double *wbuffer,
    GT_size   nj,
    ST_double scode,
    GT_bool   aweights,
    ST_double *pbuffer,
    ST_double *output,
    ST_double lower,
    ST_double upper)
{

    GT_int    i, lint, uint;
    GT_size   nmoving;
    GT_bool   wgt = (wbuffer != NULL);
    ST_double z;

    if ( wgt ) {
        if ( (upper < SV_missval) && (lower < SV_missval) ) {
            lint = (GT_int) lower;
            uint = (GT_int) upper;
            for (i = 0; i < nj; i++) {
                if ( (uint < lint ) || (i + lint < 0) || (i + uint >= nj) ) {
                    output[i] = SV_missval;
                }
                else {
                    nmoving   = (GT_size) (uint - lint + 1);
                    output[i] = gf_stats_transform_stat_weighted(
                        buffer + (i + lint),
                        wbuffer + (i + lint),
                        nmoving,
                        scode,
                        aweights,
                        pbuffer
                    );
                }
            }
            memcpy(buffer, output, nj * sizeof(ST_double));
        }
        else if ( upper < SV_missval ) {
            uint = (GT_int) upper;
            for (i = 0; i < nj; i++) {
                if ( i + uint >= nj ) {
                    output[i] = SV_missval;
                }
                else {
                    nmoving   = (GT_size) (i + uint + 1);
                    output[i] = gf_stats_transform_stat_weighted(
                        buffer,
                        wbuffer,
                        nmoving,
                        scode,
                        aweights,
                        pbuffer
                    );
                }
            }
            memcpy(buffer, output, nj * sizeof(ST_double));
        }
        else if ( lower < SV_missval ) {
            lint = (GT_int) lower;
            for (i = 0; i < nj; i++) {
                if ( i + lint < 0 ) {
                    output[i] = SV_missval;
                }
                else {
                    nmoving   = (GT_size) (nj - (i + lint));
                    output[i] = gf_stats_transform_stat_weighted(
                        buffer + (i + lint),
                        wbuffer + (i + lint),
                        nmoving,
                        scode,
                        aweights,
                        pbuffer
                    );
                }
            }
            memcpy(buffer, output, nj * sizeof(ST_double));
        }
        else {
            z = gf_stats_transform_stat_weighted(
                buffer,
                wbuffer,
                nj,
                scode,
                aweights,
                pbuffer
            );
            for (i = 0; i < nj; i++) {
                buffer[i] = z;
            }
        }
    }
    else {
        if ( (upper < SV_missval) && (lower < SV_missval) ) {
            lint = (GT_int) lower;
            uint = (GT_int) upper;
            for (i = 0; i < nj; i++) {
                if ( (uint < lint ) || (i + lint < 0) || (i + uint >= nj) ) {
                    output[i] = SV_missval;
                }
                else {
                    nmoving   = (GT_size) (uint - lint + 1);
                    output[i] = gf_stats_transform_stat(buffer + (i + lint), pbuffer, nmoving, scode, 0);
                }
            }
            memcpy(buffer, output, nj * sizeof(ST_double));
        }
        else if ( upper < SV_missval ) {
            uint = (GT_int) upper;
            for (i = 0; i < nj; i++) {
                if ( i + uint >= nj ) {
                    output[i] = SV_missval;
                }
                else {
                    nmoving   = (GT_size) (i + uint + 1);
                    output[i] = gf_stats_transform_stat(buffer, pbuffer, nmoving, scode, 0);
                }
            }
            memcpy(buffer, output, nj * sizeof(ST_double));
        }
        else if ( lower < SV_missval ) {
            lint = (GT_int) lower;
            for (i = 0; i < nj; i++) {
                if ( i + lint < 0 ) {
                    output[i] = SV_missval;
                }
                else {
                    nmoving   = (GT_size) (nj - (i + lint));
                    output[i] = gf_stats_transform_stat(buffer + (i + lint), pbuffer, nmoving, scode, 0);
                }
            }
            memcpy(buffer, output, nj * sizeof(ST_double));
        }
        else {
            z = gf_stats_transform_stat(buffer, pbuffer, nj, scode, 0);
            for (i = 0; i < nj; i++) {
                buffer[i] = z;
            }
        }
    }
}

/*********************************************************************
 *                          Stat functions                           *
 *********************************************************************/

// NOTE: This assumes that i is strictly within range
ST_double gf_stats_transform_stat_weighted_exclude (
    ST_double *buffer,
    ST_double *wbuffer,
    GT_size   nj,
    ST_double scode,
    GT_bool   aweights,
    ST_double *pbuffer,
    GT_size   i)
{
    ST_double z, w;

    w = wbuffer[i];
    wbuffer[i] = SV_missval;
    z = gf_stats_transform_stat_weighted(buffer, wbuffer, nj, scode, aweights, pbuffer);
    wbuffer[i] = w;

    // NOTE: These are based off of nj, so we need to subtract 1
    if ( scode == -14 || scode == -22 ) {
        z -= 1;
    }
    return (z);
}

ST_double gf_stats_transform_stat_weighted (
    ST_double *buffer,
    ST_double *wbuffer,
    GT_size   nj,
    ST_double scode,
    GT_bool   aweights,
    ST_double *pbuffer)
{
    GT_int snj, sth, rawsth;
    GT_size xcount;
    ST_double sdbl, xwsum, wsum, *dblptr, *wgtptr;

    if ( scode == -7  ) { // percent
        // TODO: not available; requires computing # across all obs
        sdbl = SV_missval;
    }
    else if ( scode == -10 ) { // first
        sdbl = *buffer;
    }
    else if ( scode == -11 ) { // firstnm
        sdbl   = SV_missval;
        wgtptr = wbuffer;
        for (dblptr = buffer; dblptr < buffer + nj; dblptr++, wgtptr++) {
            if ( (*dblptr < SV_missval) && (*wgtptr < SV_missval) ) {
                sdbl = *dblptr;
                break;
            }
        }
    }
    else if (scode == -12 ) { // last
        sdbl = *(buffer + nj - 1);
    }
    else if ( scode == -13 ) { // lastnm
        sdbl   = SV_missval;
        wgtptr = wbuffer + nj - 1;
        for (dblptr = buffer + nj - 1; dblptr >= buffer; dblptr--, wgtptr--) {
            if ( (*dblptr < SV_missval) && (*wgtptr < SV_missval) ) {
                sdbl = *dblptr;
                break;
            }
        }
    }
    else if ( scode == -14 ) { // freq
        sdbl = (ST_double) nj;
    }
    else if ( scode == -18 ) { // nunique
        // TODO: not available; requires computing # across all obs
        sdbl = SV_missval;
    }
    else {
        gf_array_dsum_dcount_weighted(buffer, nj, wbuffer, &xwsum, &wsum, &xcount);

        if ( scode == -6 ) { // count
            sdbl = aweights? xcount: (wsum == SV_missval? 0: wsum);
        }
        else if ( scode == -22 ) { // nmissing
            sdbl = aweights? (nj - xcount): gf_array_dnmissing_weighted(buffer, nj, wbuffer);
        }
        else if ( scode > 1000 ) { // #th smallest
            sth    = (GT_int) (floor(scode) - 1000);
            rawsth = (GT_int) (ceil(scode) - 1000);
            if ( rawsth == sth ) {
                sdbl = gf_array_dselect_weighted(
                    buffer,
                    nj,
                    wbuffer,
                    (ST_double) sth,
                    wsum,
                    xcount,
                    pbuffer
                );
            }
            else {
                sdbl = gf_array_dselect_unweighted(
                    buffer,
                    nj,
                    sth - 1,
                    xcount,
                    pbuffer
                );
            }
        }
        else if ( scode < -1000 ) { // #th largest
            sth    = (GT_int) (ceil(scode) + 1000);
            rawsth = (GT_int) (floor(scode) + 1000);
            if ( rawsth == sth ) {
                sdbl = gf_array_dselect_weighted(
                    buffer,
                    nj,
                    wbuffer,
                    (ST_double) sth,
                    wsum,
                    xcount,
                    pbuffer
                );
            }
            else {
                snj = (GT_int) (xcount > 0? xcount: nj);
                sth = (GT_int) (snj + 1000 + ceil(scode));
                sdbl = gf_array_dselect_unweighted(
                    buffer,
                    nj,
                    sth,
                    xcount,
                    pbuffer
                );
            }
        }
        else if ( wsum == SV_missval ) { // all missing values
            if ( (scode == -1) || (scode == -21) ) { // sum and rawsum
                sdbl = 0;
            }
            else if ( scode == -4 ) { // max
                sdbl = gf_array_dmax_range (buffer, 0, nj);
            }
            else if ( scode == -5 ) { // min
                sdbl = gf_array_dmin_range (buffer, 0, nj);
            }
            else {
                sdbl = SV_missval;
            }
        }
        else {
            sdbl = gf_switch_fun_code_w (
                scode,
                buffer,
                nj,
                wbuffer,
                xwsum,
                wsum,
                xcount,
                aweights,
                pbuffer
            );
        }
    }

    return (sdbl);
}

// NOTE: This assumes that i is strictly within range
ST_double gf_stats_transform_stat_exclude (
    ST_double *buffer,
    ST_double *pbuffer,
    GT_size   nj,
    ST_double scode,
    GT_bool   nomissing,
    GT_size   i)
{

    ST_double *dblptr, *bufptr;

    bufptr = pbuffer;
    for (dblptr = buffer; dblptr < buffer + i; dblptr++, bufptr++) {
        *bufptr = *dblptr;
    }

    for (dblptr = buffer + i + 1; dblptr < buffer + nj; dblptr++, bufptr++) {
        *bufptr = *dblptr;
    }

    return (gf_stats_transform_stat(pbuffer, pbuffer, nj - 1, scode, nomissing));
}

ST_double gf_stats_transform_stat (
    ST_double *buffer,
    ST_double *pbuffer,
    GT_size   nj,
    ST_double scode,
    GT_bool   nomissing)
{

    GT_int  sth, snj;
    GT_size sint;
    ST_double *dblptr, sdbl;

    if ( scode == -7  ) { // percent
        // TODO: not available; requires computing # across all obs
        sdbl = SV_missval;
    }
    else if ( scode == -10 ) { // first
        sdbl = *buffer;
    }
    else if ( scode == -11 ) { // firstnm
        sdbl = SV_missval;
        for (dblptr = buffer; dblptr < buffer + nj; dblptr++) {
            if ( *dblptr < SV_missval ) {
                sdbl = *dblptr;
                break;
            }
        }
    }
    else if (scode == -12 ) { // last
        sdbl = *(buffer + nj - 1);
    }
    else if ( scode == -13 ) { // lastnm
        sdbl = SV_missval;
        for (dblptr = buffer + nj - 1; dblptr >= buffer; dblptr--) {
            if ( *dblptr < SV_missval ) {
                sdbl = *dblptr;
                break;
            }
        }
    }
    else if ( scode == -14 ) { // freq
        sdbl = (ST_double) nj;
    }
    else if ( scode == -18 ) { // nunique
        // TODO: not available, requires various extra steps
        sdbl = SV_missval;
    }
    else {
        if ( nomissing ) {
            sint = nj;
            dblptr = buffer;
        }
        else {
            sint = 0;
            for (dblptr = buffer; dblptr < buffer + nj; dblptr++) {
                if ( *dblptr < SV_missval ) {
                    pbuffer[sint++] = *dblptr;
                }
            }
            dblptr = pbuffer;
        }

        if ( scode == -6 ) { // count
            sdbl = (ST_double) sint;
        }
        else if ( scode == -22 ) { // nmissing
            sdbl = (ST_double) (nj - sint);
        }
        else if ( scode > 1000 ) { // #th smallest (all-missing selects among missing)
            snj = (GT_int) (sint > 0? sint: nj);
            sth = (GT_int) (ceil(scode) - 1001);
            if ( sth < 0 || sth >= snj ) {
                sdbl = SV_missval;
            }
            else {
                sdbl = gf_qselect_range(dblptr, 0, snj, sth);
            }
        }
        else if ( scode < -1000 ) { // #th largest (all-missing selects among missing)
            snj = (GT_int) (sint > 0? sint: nj);
            sth = (GT_int) (snj + 1000 + floor(scode));
            if ( sth < 0 || sth >= snj ) {
                sdbl = SV_missval;
            }
            else {
                sdbl = gf_qselect_range(dblptr, 0, snj, sth);
            }
        }
        else if ( sint == 0 ) { // no obs
            if ( (scode == -1) || (scode == -21) ) { // sum and rawsum
                sdbl = 0;
            }
            else if ( scode == -4 ) { // max
                sdbl = gf_array_dmax_range (buffer, 0, nj);
            }
            else if ( scode == -5 ) { // min
                sdbl = gf_array_dmin_range (buffer, 0, nj);
            }
            else {
                sdbl = SV_missval;
            }
        }
        else if ( (scode == -3 || scode == -23 || scode == -24 || scode == -15) & (sint < 2) ) { // sd, variance, cv, semean
            sdbl = SV_missval;
        }
        else { // etc
            sdbl = gf_switch_fun_code (scode, dblptr, 0, sint);
        }
    }

    return (sdbl);
}

/*********************************************************************
 *                       Quasi-generic helpers                       *
 *********************************************************************/

ST_retcode sf_read_transform (
    struct StataInfo *st_info,
    ST_double *transform,
    ST_double *weights,
    ST_double *intvars)
{

    ST_retcode rc = 0;
    GT_size i, j, k, start, end, nj, sel;
    GT_bool wgt  = (weights != NULL);
    GT_size koff = st_info->kvars_by + st_info->transform_kvars + st_info->transform_ktargets;

    GT_size *pos      = calloc(st_info->J,     sizeof *pos);
    GT_size *index_st = calloc(st_info->Nread, sizeof *index_st);

    for (j = 0; j < st_info->J; j++) {
        pos[j] = 0;
    }

    for (i = 0; i < st_info->Nread; i++) {
        index_st[i] = 0;
    }

    for (j = 0; j < st_info->J; j++) {
        start  = st_info->info[j];
        end    = st_info->info[j + 1];
        for (i = start; i < end; i++)
            index_st[st_info->index[i]] = j + 1;
    }

    for (i = 0; i < st_info->Nread; i++) {
        if ( index_st[i] == 0 ) continue;
        j     = index_st[i] - 1;
        start = st_info->info[j];
        end   = st_info->info[j + 1];
        nj    = end - start;
        for (k = 0; k < st_info->transform_kvars; k++) {
            sel = start * st_info->transform_kvars + nj * k;
            if ( (rc = SF_vdata(st_info->kvars_by + k + 1,
                                i + st_info->in1,
                                transform + sel + pos[j])) ) goto exit;
        }
        for (k = 0; k < st_info->transform_range_k; k++) {
            sel = start * st_info->transform_range_k + nj * k;
            if ( (rc = SF_vdata(koff + k + 1,
                                i + st_info->in1,
                                intvars + sel + pos[j])) ) goto exit;
        }
        if ( wgt ) {
            if ( (rc = SF_vdata(st_info->wpos,
                                i + st_info->in1,
                                weights + start + pos[j])) ) goto exit;
        }
        pos[j]++;
    }

exit:
    free (pos);
    free (index_st);

    return (rc);
}

ST_retcode sf_write_transform (
    struct StataInfo *st_info,
    ST_double *transform)
{

    ST_retcode rc = 0;
    GT_size i, j, k, start, end, nj, sel;
    GT_size *pos = calloc(st_info->J, sizeof *pos);

    for (j = 0; j < st_info->J; j++) {
        pos[j] = 0;
    }

    for (j = 0; j < st_info->J; j++) {
        start  = st_info->info[j];
        end    = st_info->info[j + 1];
        nj     = end - start;
        for (i = start; i < end; i++) {
            for (k = 0; k < st_info->transform_ktargets; k++) {
                sel = start * st_info->transform_ktargets + nj * k;
                if ( (rc = SF_vstore(st_info->kvars_by + k + 1 + st_info->transform_kvars,
                                     st_info->index[i] + st_info->in1,
                                     *(transform + sel + pos[j]))) ) goto exit;
            }
            pos[j]++;
        }
    }

exit:
    free (pos);

    return (rc);
}
