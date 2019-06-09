ST_retcode gf_stats_transform_check (
    ST_double tcode,
    GT_size kstats
);

ST_double gf_stats_transform_stat (
    ST_double *buffer,
    ST_double *sbuffer,
    GT_size nj,
    ST_double scode
);

ST_double gf_stats_transform_stat_weighted (
    ST_double *buffer,
    ST_double *wbuffer,
    GT_size   nj,
    ST_double scode,
    GT_bool   aweights,
    ST_double *pbuffer
);

void gf_stats_transform_apply (
    ST_double *buffer,
    GT_size   nj,
    ST_double tcode,
    ST_double *stats
);

ST_retcode sf_write_transform (
    struct StataInfo *st_info,
    ST_double *transform
);

ST_retcode sf_read_transform (
    struct StataInfo *st_info,
    ST_double *transform,
    ST_double *weights
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
    ST_double scode, tcode, *dblptr, *wgtptr;

    GT_bool greedy   = st_info->transform_greedy;
    GT_bool weights  = st_info->wcode > 0;
    GT_bool aweights = (st_info->wcode == 1);

    GT_size kvars    = st_info->kvars_by;
    GT_size ksources = st_info->transform_kvars;
    GT_size ktargets = st_info->transform_ktargets;
    GT_size kgstats  = st_info->transform_kgstats;
    GT_size wpos     = st_info->wpos;
    GT_size nj_max   = st_info->info[1] - st_info->info[0];
    GT_size Nread    = st_info->Nread;
    GT_size J        = st_info->J;
    clock_t timer    = clock();

    for (j = 1; j < J; j++) {
        if (nj_max < (st_info->info[j + 1] - st_info->info[j]))
            nj_max = (st_info->info[j + 1] - st_info->info[j]);
    }

    ST_double *gsrc_vars    = calloc(greedy? ksources * Nread: 1, sizeof *gsrc_vars);
    ST_double *gsrc_weight  = calloc(weights? Nread: 1,           sizeof *gsrc_weight);
    ST_double *gsrc_pbuffer = calloc(weights? 2 * nj_max: 1,      sizeof *gsrc_pbuffer);

    ST_double *gsrc_buffer  = calloc(nj_max,   sizeof *gsrc_buffer);
    ST_double *gsrc_sbuffer = calloc(nj_max,   sizeof *gsrc_sbuffer);
    ST_double *gsrc_stats   = calloc(kgstats,  sizeof *gsrc_stats);
    GT_size   *gsrc_kstats  = calloc(ktargets, sizeof *gsrc_kstats);

    if ( gsrc_vars    == NULL ) return(sf_oom_error("sf_stats_transform", "gsrc_vars"));
    if ( gsrc_weight  == NULL ) return(sf_oom_error("sf_stats_transform", "gsrc_weight"));
    if ( gsrc_pbuffer == NULL ) return(sf_oom_error("sf_stats_transform", "gsrc_pbuffer"));

    if ( gsrc_buffer  == NULL ) return(sf_oom_error("sf_stats_transform", "gsrc_buffer"));
    if ( gsrc_sbuffer == NULL ) return(sf_oom_error("sf_stats_transform", "gsrc_sbuffer"));
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
            if ( (rc = sf_read_transform (st_info, gsrc_vars, gsrc_weight)) ) goto exit;

            if ( st_info->benchmark > 1 )
                sf_running_timer (&timer, "\ttransform step 2: copied sources in order");

            // apply the transforms
            dblptr = gsrc_vars;
            wgtptr = gsrc_weight;
            for (j = 0; j < J; j++) {
                start  = st_info->info[j];
                end    = st_info->info[j + 1];
                nj     = end - start;
                for (k = 0; k < ktargets; k++) {
                    tcode  = st_info->transform_varfuns[k];
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
                    dblptr += nj;
                }
                wgtptr += nj;
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
                tcode  = st_info->transform_varfuns[k];
                wgtptr = gsrc_weight;
                for (j = 0; j < J; j++) {
                    start  = st_info->info[j];
                    end    = st_info->info[j + 1];
                    nj     = end - start;
                    dblptr = gsrc_buffer;
                    for (i = start; i < end; i++, dblptr++) {
                        if ( (rc = SF_vdata(kvars + k + 1, st_info->index[i] + st_info->in1, dblptr)) ) goto exit;
                    }
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
            if ( (rc = sf_read_transform (st_info, gsrc_vars, NULL)) ) goto exit;

            if ( st_info->benchmark > 1 )
                sf_running_timer (&timer, "\ttransform step 2: copied sources in order");

            // apply the transforms
            dblptr = gsrc_vars;
            for (j = 0; j < J; j++) {
                start  = st_info->info[j];
                end    = st_info->info[j + 1];
                nj     = end - start;
                for (k = 0; k < ktargets; k++) {
                    tcode  = st_info->transform_varfuns[k];
                    for (l = 0; l < gsrc_kstats[k]; l++) {
                        spos  = st_info->transform_statmap[kgstats * k + l] - 1;
                        scode = st_info->transform_statcode[spos];
                        gsrc_stats[l] = gf_stats_transform_stat(dblptr, gsrc_sbuffer, nj, scode);
                    }
                    gf_stats_transform_apply(dblptr, nj, tcode, gsrc_stats);
                    dblptr += nj;
                }
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
                tcode = st_info->transform_varfuns[k];
                for (j = 0; j < J; j++) {
                    start  = st_info->info[j];
                    end    = st_info->info[j + 1];
                    nj     = end - start;
                    dblptr = gsrc_buffer;
                    for (i = start; i < end; i++, dblptr++) {
                        if ( (rc = SF_vdata(kvars + k + 1, st_info->index[i] + st_info->in1, dblptr)) ) goto exit;
                    }
                    for (l = 0; l < gsrc_kstats[k]; l++) {
                        spos  = st_info->transform_statmap[kgstats * k + l] - 1;
                        scode = st_info->transform_statcode[spos];
                        gsrc_stats[l] = gf_stats_transform_stat(gsrc_buffer, gsrc_sbuffer, nj, scode);
                    }
                    gf_stats_transform_apply(gsrc_buffer, nj, tcode, gsrc_stats);
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

    free (gsrc_vars);
    free (gsrc_weight);
    free (gsrc_pbuffer);

    free (gsrc_buffer);
    free (gsrc_sbuffer);
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
    return (0);
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

ST_double gf_stats_transform_stat (
    ST_double *buffer,
    ST_double *sbuffer,
    GT_size nj,
    ST_double scode)
{

    GT_int  sth, snj;
    GT_size sint;
    ST_double *dblptr, *sdblptr, sdbl;

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
        sint = 0;
        sdblptr = sbuffer;
        for (dblptr = buffer; dblptr < buffer + nj; dblptr++, sdblptr++) {
            if ( *dblptr < SV_missval ) {
                sint++;
                *sdblptr = *dblptr;
            }
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
                sdbl = gf_qselect_range(sbuffer, 0, snj, sth);
            }
        }
        else if ( scode < -1000 ) { // #th largest (all-missing selects among missing)
            snj = (GT_int) (sint > 0? sint: nj);
            sth = (GT_int) (snj + 1000 + floor(scode));
            if ( sth < 0 || sth >= snj ) {
                sdbl = SV_missval;
            }
            else {
                sdbl = gf_qselect_range(sbuffer, 0, snj, sth);
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
            sdbl = gf_switch_fun_code (scode, sbuffer, 0, sint);
        }
    }

    return (sdbl);
}

void gf_stats_transform_apply (
    ST_double *buffer,
    GT_size   nj,
    ST_double tcode,
    ST_double *stats)
{
    // TODO: maybe lag, rolling stats (e.g. moving average), etc.
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
}

/*********************************************************************
 *                       Quasi-generic helpers                       *
 *********************************************************************/

ST_retcode sf_read_transform (
    struct StataInfo *st_info,
    ST_double *transform,
    ST_double *weights)
{

    ST_retcode rc = 0;
    GT_size i, j, k, start, end, nj, sel;
    GT_bool wgt = (weights != NULL);

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
