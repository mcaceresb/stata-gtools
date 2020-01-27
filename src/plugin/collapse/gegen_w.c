ST_retcode sf_egen_bulk_w (struct StataInfo *st_info, int level);

/**
 * @brief egen stata variables in bulk
 *
 * @param st_info Pointer to container structure for Stata info
 * @return Stores egen data in Stata
 */
ST_retcode sf_egen_bulk_w (struct StataInfo *st_info, int level)
{

    if ( st_info->kvars_targets < 1 ) {
        return (0);
    }

    GT_bool multiple_sources = (st_info->kvars_sources > 1);
    GT_bool one_target = (st_info->kvars_targets == 1)
                      || ( (st_info->kvars_targets == 2) & (st_info->statcode[1] == -14) );

    if ( multiple_sources & one_target ) {
        sf_errprintf ("Weights are not allowed with multiple sources per target.\n");
        return (198);
    }

    /*********************************************************************
     *                           Step 1: Setup                           *
     *********************************************************************/

    ST_retcode rc = 0;
    ST_double z, scode;

    GT_int sth, rawsth, snj;
    GT_bool aweights = (st_info->wcode == 1);
    GT_size i, j, k, l;
    GT_size nj, nj_max, start, startw, end;
    ST_double endw, endwraw;
    GT_size offset_output,
           offset_source,
           offset_buffer,
           offset_weight;

    clock_t  timer = clock();
    clock_t stimer = clock();

    GT_size N = st_info->N;
    GT_size J = st_info->J;

    GT_size kvars         = st_info->kvars_by;
    GT_size ksources      = st_info->kvars_sources;
    GT_size ktargets      = st_info->kvars_targets;
    GT_size start_sources = kvars + st_info->kvars_group + 1;
    GT_size wpos          = st_info->wpos;

    /*********************************************************************
     *                     Step 2: Memory allocation                     *
     *********************************************************************/

    GT_size *pos_sources = calloc(ksources, sizeof *pos_sources);
    ST_double *statcode  = calloc(ktargets, sizeof *statcode);

    if ( pos_sources == NULL ) return(sf_oom_error("sf_egen_bulk_w", "pos_sources"));
    if ( statcode    == NULL ) return(sf_oom_error("sf_egen_bulk_w", "statcode"));

    for (k = 0; k < ksources; k++)
        pos_sources[k] = start_sources + k;

    for (k = 0; k < st_info->kvars_stats; k++)
        statcode[k] = st_info->statcode[k];

    st_info->output = calloc(J * ktargets, sizeof *st_info->output);
    if ( st_info->output == NULL ) return(sf_oom_error("sf_egen_bulk_w", "st_info->output"));

    GTOOLS_GC_ALLOCATED("st_info->output")
    ST_double *output = st_info->output;
    st_info->free = 9;

    nj_max = st_info->info[1] - st_info->info[0];
    for (j = 1; j < st_info->J; j++) {
        if (nj_max < (st_info->info[j + 1] - st_info->info[j]))
            nj_max = (st_info->info[j + 1] - st_info->info[j]);
    }

    GT_size   *nuniq_ix    = calloc(st_info->nunique? nj_max: 1, sizeof *nuniq_ix);
    uint64_t  *nuniq_h1    = calloc(st_info->nunique? nj_max: 1, sizeof *nuniq_h1);
    uint64_t  *nuniq_h2    = calloc(st_info->nunique? nj_max: 1, sizeof *nuniq_h2);
    uint64_t  *nuniq_h3    = calloc(st_info->nunique? nj_max: 1, sizeof *nuniq_h3);
    uint64_t  *nuniq_xcopy = calloc(st_info->nunique? nj_max: 1, sizeof *nuniq_xcopy);

    if ( nuniq_ix    == NULL ) return(sf_oom_error("sf_egen_bulk_w", "nuniq_ix"));
    if ( nuniq_h1    == NULL ) return(sf_oom_error("sf_egen_bulk_w", "nuniq_h1"));
    if ( nuniq_h2    == NULL ) return(sf_oom_error("sf_egen_bulk_w", "nuniq_h2"));
    if ( nuniq_h3    == NULL ) return(sf_oom_error("sf_egen_bulk_w", "nuniq_h3"));
    if ( nuniq_xcopy == NULL ) return(sf_oom_error("sf_egen_bulk_w", "nuniq_xcopy"));

    // NOTE(mauricio): The ( + 1) because we need to define v_0, w_0 in some functions
    ST_double *p_buffer = calloc(2 * (nj_max + 1), sizeof *p_buffer);
    ST_double *weights  = calloc(N, sizeof *weights);
    GT_size   *nbuffer  = calloc(J, sizeof *nbuffer);

    if ( p_buffer == NULL ) return(sf_oom_error("sf_egen_bulk_w", "p_buffer"));
    if ( weights  == NULL ) return(sf_oom_error("sf_egen_bulk_w", "weights"));
    if ( nbuffer  == NULL ) return(sf_oom_error("sf_egen_bulk_w", "nbuffer"));

    ST_double *all_buffer     = calloc(N * ksources, sizeof *all_buffer);
    ST_double *all_wsum       = calloc(J * ksources, sizeof *all_wsum);
    ST_double *all_xwsum      = calloc(J * ksources, sizeof *all_xwsum);
    GT_size   *all_xcount     = calloc(J * ksources, sizeof *all_xcount);
    GT_size   *offsets_buffer = calloc(J, sizeof *offsets_buffer);
    GT_size   *nj_buffer      = calloc(J, sizeof *nj_buffer);

    if ( all_buffer     == NULL ) return(sf_oom_error("sf_egen_bulk_w", "all_buffer"));
    if ( all_wsum       == NULL ) return(sf_oom_error("sf_egen_bulk_w", "all_wsum"));
    if ( all_xwsum      == NULL ) return(sf_oom_error("sf_egen_bulk_w", "all_xwsum"));
    if ( all_xcount     == NULL ) return(sf_oom_error("sf_egen_bulk_w", "all_xcount"));
    if ( offsets_buffer == NULL ) return(sf_oom_error("sf_egen_bulk_w", "offsets_buffer"));
    if ( nj_buffer      == NULL ) return(sf_oom_error("sf_egen_bulk_w", "nj_buffer"));

    for (j = 0; j < J; j++)
        nbuffer[j] = 0;

    ST_double *nmfreq = calloc(ksources, sizeof *nmfreq);
    if ( nmfreq == NULL ) return(sf_oom_error("sf_egen_bulk_w", "nmfreq"));

    for (k = 0; k < ksources; k++)
        nmfreq[k] = 0;

    ST_double *firstmiss = calloc(ksources, sizeof *firstmiss);
    ST_double *lastmiss  = calloc(ksources, sizeof *lastmiss);
    ST_double *firstnm   = calloc(ksources, sizeof *firstnm);
    ST_double *lastnm    = calloc(ksources, sizeof *lastnm);

    if ( firstmiss == NULL ) return(sf_oom_error("sf_egen_bulk_w", "firstmiss"));
    if ( lastmiss  == NULL ) return(sf_oom_error("sf_egen_bulk_w", "lastmiss"));
    if ( firstnm   == NULL ) return(sf_oom_error("sf_egen_bulk_w", "firstnm"));
    if ( lastnm    == NULL ) return(sf_oom_error("sf_egen_bulk_w", "lastnm"));


    /*********************************************************************
     *               Step 3: Read in variables from Stata                *
     *********************************************************************/

    // Method 1: Continuously from Stata
    // ---------------------------------

    /*
     * The following maps the C group index to Stata so we can read
     * observations from Stata in order; this is only sometimes faster,
     */

    GT_size *index_st = calloc(st_info->Nread, sizeof *index_st);
    if ( index_st == NULL ) return(sf_oom_error("sf_egen_bulk_w", "index_st"));

    for (i = 0; i < st_info->Nread; i++) {
        index_st[i] = 0;
    }

    for (j = 0; j < J; j++) {
        l      = st_info->ix[j];
        start  = st_info->info[l];
        end    = st_info->info[l + 1];
        offsets_buffer[j] = start * ksources;
        nj_buffer[j]      = end - start;
        for (i = start; i < end; i++)
            index_st[st_info->index[i]] = l + 1;
    }

    offset_buffer = offset_source = 0;
    for (i = 0; i < st_info->Nread; i++) {
        if ( index_st[i] == 0 ) continue;
        j     = index_st[i] - 1;
        start = st_info->info[j];
        end   = st_info->info[j + 1];
        nj    = end - start;

        offset_buffer = start * ksources;
        offset_source = j * ksources;

        for (k = 0; k < ksources; k++) {
            // Read Stata in order and place into all_buffer in order as well
            if ( (rc = SF_vdata(pos_sources[k], i + st_info->in1, &z)) ) goto exit;
            all_buffer[offset_buffer + nj * k + nbuffer[j]] = z;
        }

        if ( (rc = SF_vdata(wpos, i + st_info->in1, &z)) ) goto exit;
        weights[start + nbuffer[j]] = z;
        nbuffer[j]++;
    }

    if ( st_info->benchmark > 2 )
        sf_running_timer (&stimer, "\t\tPlugin step 5.1: Read source variables sequentially");

    /*********************************************************************
     *                     Step 4: Pre-compute sums                      *
     *********************************************************************/

    for (j = 0; j < J; j++) {
        nj = nj_buffer[j];
        offset_buffer = offsets_buffer[j];
        offset_weight = st_info->info[st_info->ix[j]];
        for (k = 0; k < ksources; k++) {
            gf_array_dsum_dcount_weighted (
                all_buffer + offset_buffer + nj * k,
                nj,
                weights + offset_weight,
                all_xwsum  + j * ksources + k,
                all_wsum   + j * ksources + k,
                all_xcount + j * ksources + k
            );
        }
    }

    for (j = 0; j < J; j++) {
        for (k = 0; k < ksources; k++) {
            endwraw    = all_wsum[j * ksources + k];
            nmfreq[k] += endwraw == SV_missval? 0: endwraw;
        }
    }

    if ( st_info->benchmark > 2 )
        sf_running_timer (&stimer, "\t\tPlugin step 5.2: Pre-computed weighted sums");

    /*********************************************************************
     *                Step 5: Collapse variables by gorup                *
     *********************************************************************/

    if ( st_info->wselective == 0 ) {
        for (j = 0; j < J; j++) {

            // Remember we read things in group sort order but info and index
            // are in hash sort order, so the jth output corresponds to the
            // st_info->ix[j]th source
            offset_output = j * ktargets;
            offset_source = st_info->ix[j] * ksources;
            offset_buffer = offsets_buffer[j];
            offset_weight = st_info->info[st_info->ix[j]];
            nj            = nj_buffer[j];

            // Get the position of the first and last obs of each source
            // variable (in case they are modified by calling qselect)
            for (k = 0; k < ksources; k++) {
                start        = offset_buffer + nj * k;
                firstmiss[k] = all_buffer[start];
                lastmiss[k]  = all_buffer[start + nj - 1];
                firstnm[k]   = gf_array_dfirstnm(all_buffer + offset_buffer + nj * k, nj);
                lastnm[k]    = gf_array_dlastnm (all_buffer + offset_buffer + nj * k, nj);
            }

            for (k = 0; k < ktargets; k++) {

                // For each target, grab start and end position of source variable
                start    = offset_buffer + nj * st_info->pos_targets[k];
                startw   = j * ksources + st_info->pos_targets[k];
                endwraw  = all_wsum[startw];
                endw     = endwraw == SV_missval? 0: endwraw;
                scode    = statcode[k];

                // If there is at least one non-missing observation, we store
                // the result in output. If all observations are missing then
                // we store Stata's special SV_missval
                if ( scode == -6 ) { // count
                    // If count, you just need to know how many non-missing obs there are
                    output[offset_output + k] = aweights? all_xcount[startw]: endw;
                }
                else if ( scode == -14 ) { // freq
                    output[offset_output + k] = nj;
                }
                else if ( scode == -22 ) { // nmissing
                    // count number missing; freq - count only with aweights
                    if ( aweights )  {
                        output[offset_output + k] = nj - all_xcount[startw];
                    }
                    else {
                        output[offset_output + k] = gf_array_dnmissing_weighted(
                            all_buffer + start,
                            nj,
                            weights + offset_weight
                        );
                    }
                }
                else if ( scode == -7  ) { // percent
                    // Percent outputs the % of all non-missing values of
                    // that variable in that group relative to the number
                    // of non-missing values of that variable in the entire
                    // data. This latter count is stored in nmfreq; we divide
                    // by this when writing to Stata.
                    output[offset_output + k] = 100 * (endw / nmfreq[st_info->pos_targets[k]]);
                }
                else if ( scode == -10 ) { // first
                    output[offset_output + k] = firstmiss[st_info->pos_targets[k]];
                }
                else if ( scode == -11 ) { // firstnm
                    // First non-missing is the first entry in the inputs buffer;
                    // this is only missing if all are missing.
                    output[offset_output + k] = firstnm[st_info->pos_targets[k]];
                }
                else if (scode == -12 ) { // last
                    output[offset_output + k] = lastmiss[st_info->pos_targets[k]];
                }
                else if ( scode == -13 ) { // lastnm
                    // Last non-missing is the last entry in the inputs buffer;
                    // this is only missing is all are missing.
                    output[offset_output + k] = lastnm[st_info->pos_targets[k]];
                }
                else if ( scode == -18 ) { // nunique
                    if ( (rc = gf_array_nunique_range (
                            output + offset_output + k,
                            all_buffer + start,
                            nj,
                            (endwraw == SV_missval),
                            nuniq_h1,
                            nuniq_h2,
                            nuniq_h3,
                            nuniq_ix,
                            nuniq_xcopy
                        )
                    ) ) return (rc);
                }
                else if ( scode > 1000 ) { // #th smallest
                    sth = (GT_int) (floor(scode) - 1000);
                    rawsth = (GT_int) (ceil(scode) - 1000);
                    // switch to missing selection internally; only switch with unw
                    if ( rawsth == sth ) {
                        // if equal, do weighted; otherwise do raw
                        output[offset_output + k] = gf_array_dselect_weighted(
                            all_buffer + start,
                            nj,
                            weights + offset_weight,
                            (ST_double) sth,
                            all_wsum[startw],
                            all_xcount[startw],
                            p_buffer
                        );
                    }
                    else {
                        output[offset_output + k] = gf_array_dselect_unweighted(
                            all_buffer + start,
                            nj,
                            sth - 1,
                            all_xcount[startw],
                            p_buffer
                        );
                    }
                }
                else if ( scode < -1000 ) { // #th largest
                    sth = (GT_int) (ceil(scode) + 1000);
                    rawsth = (GT_int) (floor(scode) + 1000);
                     // switch to missing selection internally; only switch with unw
                    if ( rawsth == sth ) {
                        // if equal, do weighted; otherwise do raw
                        output[offset_output + k] = gf_array_dselect_weighted(
                            all_buffer + start,
                            nj,
                            weights + offset_weight,
                            (ST_double) sth,
                            all_wsum[startw],
                            all_xcount[startw],
                            p_buffer
                        );
                    }
                    else {
                        snj = (GT_int) (all_xcount[startw] > 0? all_xcount[startw]: nj);
                        sth = (GT_int) (snj + 1000 + ceil(scode));
                        output[offset_output + k] = gf_array_dselect_unweighted(
                            all_buffer + start,
                            nj,
                            sth,
                            all_xcount[startw],
                            p_buffer
                        );
                    }
                }
                else if ( endwraw == SV_missval ) { // all missing values
                    // If everything is missing, write a missing value, Except for
                    // sum and rawsum, which go to 0 for some frankly bizarre reason
                    // (this is the behavior of collapse), and min/max (which pick
                    // out the min/max missing value).
                    if ( (scode == -1) || (scode == -21) ) { // sum and rawsum
                        output[offset_output + k] = 0;
                    }
                    else if ( scode == -4 ) { // max
                        // min/max handle missings b/c they only do comparisons
                        output[offset_output + k] = gf_array_dmax_range (all_buffer + start, 0, nj);
                    }
                    else if ( scode == -5 ) { // min
                        // min/max handle missings b/c they only do comparisons
                        output[offset_output + k] = gf_array_dmin_range (all_buffer + start, 0, nj);
                    }
                    else {
                        output[offset_output + k] = SV_missval;
                    }
                }
                else {
                    // Otherwise compute the requested summary stat
                    output[offset_output + k] = gf_switch_fun_code_w (
                        scode,
                        all_buffer + start,
                        nj,
                        weights + offset_weight,
                        all_xwsum[startw],
                        all_wsum[startw],
                        all_xcount[startw],
                        aweights,
                        p_buffer
                    );
                }
            }
        }
    }
    else {
        for (j = 0; j < J; j++) {

            // Remember we read things in group sort order but info and index
            // are in hash sort order, so the jth output corresponds to the
            // st_info->ix[j]th source
            offset_output = j * ktargets;
            offset_source = st_info->ix[j] * ksources;
            offset_buffer = offsets_buffer[j];
            offset_weight = st_info->info[st_info->ix[j]];
            nj            = nj_buffer[j];

            // Get the position of the first and last obs of each source
            // variable (in case they are modified by calling qselect)
            for (k = 0; k < ksources; k++) {
                start        = offset_buffer + nj * k;
                firstmiss[k] = all_buffer[start];
                lastmiss[k]  = all_buffer[start + nj - 1];
                firstnm[k]   = gf_array_dfirstnm(all_buffer + offset_buffer + nj * k, nj);
                lastnm[k]    = gf_array_dlastnm (all_buffer + offset_buffer + nj * k, nj);
            }

            for (k = 0; k < ktargets; k++) {

                // For each target, grab start and end position of source variable
                start    = offset_buffer + nj * st_info->pos_targets[k];
                startw   = j * ksources + st_info->pos_targets[k];
                endwraw  = all_wsum[startw];
                endw     = endwraw == SV_missval? 0: endwraw;
                scode    = statcode[k];

                // If there is at least one non-missing observation, we store
                // the result in output. If all observations are missing then
                // we store Stata's special SV_missval
                if ( scode == -6 ) { // count
                    // If count, you just need to know how many non-missing obs there are
                    if ( st_info->wselmat[k] ) {
                        output[offset_output + k] = all_xcount[startw];
                    }
                    else {
                        output[offset_output + k] = aweights? all_xcount[startw]: endw;
                    }
                }
                else if ( scode == -14 ) { // freq
                    output[offset_output + k] = nj;
                }
                else if ( scode == -22 ) { // nmissing
                    // count number missing; freq - count only with aweights or with wselmat
                    if ( st_info->wselmat[k] || aweights )  {
                        output[offset_output + k] = nj - all_xcount[startw];
                    }
                    else {
                        output[offset_output + k] = gf_array_dnmissing_weighted(
                            all_buffer + start,
                            nj,
                            weights + offset_weight
                        );
                    }
                }
                else if ( scode == -7  ) { // percent
                    // Percent outputs the % of all non-missing values of
                    // that variable in that group relative to the number
                    // of non-missing values of that variable in the entire
                    // data. This latter count is stored in nmfreq; we divide
                    // by this when writing to Stata.
                    output[offset_output + k] = 100 * (endw / nmfreq[st_info->pos_targets[k]]);
                }
                else if ( scode == -10 ) { // first
                    output[offset_output + k] = firstmiss[st_info->pos_targets[k]];
                }
                else if ( scode == -11 ) { // firstnm
                    // First non-missing is the first entry in the inputs buffer;
                    // this is only missing if all are missing.
                    output[offset_output + k] = firstnm[st_info->pos_targets[k]];
                }
                else if (scode == -12 ) { // last
                    output[offset_output + k] = lastmiss[st_info->pos_targets[k]];
                }
                else if ( scode == -13 ) { // lastnm
                    // Last non-missing is the last entry in the inputs buffer;
                    // this is only missing is all are missing.
                    output[offset_output + k] = lastnm[st_info->pos_targets[k]];
                }
                else if ( scode == -18 ) { // nunique
                    if ( (rc = gf_array_nunique_range (
                            output + offset_output + k,
                            all_buffer + start,
                            nj,
                            (endwraw == SV_missval),
                            nuniq_h1,
                            nuniq_h2,
                            nuniq_h3,
                            nuniq_ix,
                            nuniq_xcopy
                        )
                    ) ) return (rc);
                }
                else if ( scode > 1000 ) { // #th smallest
                    sth = (GT_int) (floor(scode) - 1000);
                    rawsth = (GT_int) (ceil(scode) - 1000);
                    // switch to missing selection internally; only switch with unw
                    if ( (st_info->wselmat[k] == 0) && rawsth == sth ) {
                        // if equal, do weighted; otherwise do raw
                        output[offset_output + k] = gf_array_dselect_weighted(
                            all_buffer + start,
                            nj,
                            weights + offset_weight,
                            (ST_double) sth,
                            all_wsum[startw],
                            all_xcount[startw],
                            p_buffer
                        );
                    }
                    else {
                        output[offset_output + k] = gf_array_dselect_unweighted(
                            all_buffer + start,
                            nj,
                            sth - 1,
                            all_xcount[startw],
                            p_buffer
                        );
                    }
                }
                else if ( scode < -1000 ) { // #th largest
                    sth = (GT_int) (ceil(scode) + 1000);
                    rawsth = (GT_int) (floor(scode) + 1000);
                    // switch to missing selection internally; only switch with unw
                    if ( (st_info->wselmat[k] == 0) && rawsth == sth ) {
                        // if equal, do weighted; otherwise do raw
                        output[offset_output + k] = gf_array_dselect_weighted(
                            all_buffer + start,
                            nj,
                            weights + offset_weight,
                            (ST_double) sth,
                            all_wsum[startw],
                            all_xcount[startw],
                            p_buffer
                        );
                    }
                    else {
                        snj = (GT_int) (all_xcount[startw] > 0? all_xcount[startw]: nj);
                        sth = (GT_int) (snj + 1000 + ceil(scode));
                        output[offset_output + k] = gf_array_dselect_unweighted(
                            all_buffer + start,
                            nj,
                            sth,
                            all_xcount[startw],
                            p_buffer
                        );
                    }
                }
                else if ( endwraw == SV_missval ) { // all missing values
                    // If everything is missing, write a missing value, Except for
                    // sum and rawsum, which go to 0 for some frankly bizarre reason
                    // (this is the behavior of collapse), and min/max (which pick
                    // out the min/max missing value).
                    if ( (scode == -1) || (scode == -21) ) { // sum and rawsum
                        output[offset_output + k] = 0;
                    }
                    else if ( scode == -4 ) { // max
                        // min/max handle missings b/c they only do comparisons
                        output[offset_output + k] = gf_array_dmax_range (all_buffer + start, 0, nj);
                    }
                    else if ( scode == -5 ) { // min
                        // min/max handle missings b/c they only do comparisons
                        output[offset_output + k] = gf_array_dmin_range (all_buffer + start, 0, nj);
                    }
                    else {
                        output[offset_output + k] = SV_missval;
                    }
                }
                else {
                    // Otherwise compute the requested summary stat
                    if ( st_info->wselmat[k] ) {
                        output[offset_output + k] = gf_switch_fun_code_unw (
                            scode,
                            all_buffer + start,
                            nj,
                            all_xcount[startw],
                            p_buffer
                        );
                    }
                    else {
                        output[offset_output + k] = gf_switch_fun_code_w (
                            scode,
                            all_buffer + start,
                            nj,
                            weights + offset_weight,
                            all_xwsum[startw],
                            all_wsum[startw],
                            all_xcount[startw],
                            aweights,
                            p_buffer
                        );
                    }
                }
            }
        }
    }

    if ( st_info->benchmark > 2 )
        sf_running_timer (&stimer, "\t\tPlugin step 5.3: Computed summary stats");

    if ( st_info->benchmark > 1 )
        sf_running_timer (&timer, "\tPlugin step 5: Generated output array");

exit:

    free (pos_sources);
    free (statcode);

    free (index_st);

    free (nuniq_h1);
    free (nuniq_h2);
    free (nuniq_h3);
    free (nuniq_ix);
    free (nuniq_xcopy);

    free (p_buffer);
    free (weights);
    free (nbuffer);

    free (all_buffer);
    free (all_wsum);
    free (all_xwsum);
    free (all_xcount);
    free (offsets_buffer);
    free (nj_buffer);

    free (nmfreq);
    free (firstmiss);
    free (lastmiss);
    free (firstnm);
    free (lastnm);

    return (rc);
}
