ST_retcode sf_top (struct StataInfo *st_info, int level);

ST_retcode sf_top (struct StataInfo *st_info, int level)
{

    /*********************************************************************
     *                           Step 1: Setup                           *
     *********************************************************************/

    ST_retcode rc = 0;
    ST_double z;
    GT_size j, k, l;
    GT_size sel, numpos;
    GT_size numwidth = st_info->numfmt_max > 19? st_info->numfmt_max + 4: 23;
    GT_bool invert   = st_info->top_ntop < 0;
    GT_size kvars    = st_info->kvars_by;
    GT_size ntop     = (GT_size) (invert? -st_info->top_ntop: st_info->top_ntop);
    GT_size nrows    = ntop + st_info->top_miss + st_info->top_other;
    GT_size nalloc   = nrows > 0? nrows: 1;
    ST_double Ndbl   = (ST_double) st_info->N;
    clock_t timer    = clock();

    /*********************************************************************
     *                     Step 2: Sort group counts                     *
     *********************************************************************/

    ST_double *toptop = calloc(5 * nalloc, sizeof *toptop);
    GT_size   *topall = calloc(st_info->J, sizeof *topall);
    GT_size   *topix  = calloc(st_info->J, sizeof *topix);

    if ( toptop == NULL ) sf_oom_error("sf_top", "toptop");
    if ( topall == NULL ) sf_oom_error("sf_top", "topall");
    if ( topix  == NULL ) sf_oom_error("sf_top", "topix");

    GTOOLS_GC_ALLOCATED("toptop")
    GTOOLS_GC_ALLOCATED("topall")
    GTOOLS_GC_ALLOCATED("topix")

    // Read group sizes as N - size so we sort in ascending order
    if ( invert ) {
        for (j = 0; j < st_info->J; j++) {
            l = st_info->ix[j];
            topall[j] = st_info->info[l + 1] - st_info->info[l];
            topix[j]  = j;
        }
    }
    else {
        for (j = 0; j < st_info->J; j++) {
            l = st_info->ix[j];
            topall[j] = st_info->N - (st_info->info[l + 1] - st_info->info[l]);
            topix[j]  = j;
        }
    }

    for (j = 0; j < nrows; j++) {
        for (k = 0; k < 5; k++)
            toptop[j * 5 + k] = (ST_double) 0;
    }

    GT_size min   = invert? st_info->nj_max: st_info->N - st_info->nj_max;
    GT_size max   = invert? st_info->nj_min: st_info->N - st_info->nj_min;
    GT_size range = (st_info->nj_max - st_info->nj_min);
    GT_size ctol  = pow(2, 24);

    // Sort in ascending order, which is descending group order
    if ( range < ctol ) {
        if ( (rc = gf_counting_sort (topall, topix, st_info->J, min, max)) )
            goto error;
    }
    else {
        if ( (rc = gf_radix_sort16 (topall, topix, st_info->J)) )
            goto error;
    }

    // Back to frequencies
    if ( !invert ) {
        for (j = 0; j < st_info->J; j++)
            topall[j] = st_info->N - topall[j];
    }

    /*********************************************************************
     *            Step 3: Set up variables to print to levels            *
     *********************************************************************/
    
    char *strpos;
    char *sprintfmt = st_info->cleanstr? strdup("%s"): strdup("`\"%s\"'");

    // Buffer for levels
    // -----------------

    char *macrobuffer;
    GT_size bufferlen;

    GT_size sprintextra = st_info->cleanstr? 0: 4;
    GT_size totalseplen = (nrows - 1) * st_info->sep_len +
                          nrows * st_info->colsep_len * (kvars - 1);

    GT_size totalrowlen = 0;
    for (k = 0; k < kvars; k++) {
        totalrowlen += st_info->byvars_lens[k] > 0? st_info->byvars_lens[k] + 1: numwidth;
    }

    bufferlen   = totalseplen + 1;
    bufferlen  += ntop * (totalrowlen + sprintextra * st_info->kvars_by_str);
    bufferlen  += (kvars > 1)? 4 * ntop: 0;

    macrobuffer = malloc(bufferlen * sizeof(char));
    if ( macrobuffer == NULL ) return (sf_oom_error("sf_top", "macrobuffer"));
    memset (macrobuffer, '\0', bufferlen * sizeof(char));

    // Column sep, label for miss, other
    // ---------------------------------

    char *colsep = malloc((st_info->colsep_len + 1) * sizeof(char));
    char *sep    = malloc((st_info->sep_len    + 1) * sizeof(char));
    char *numfmt = malloc((st_info->numfmt_max + 1) * sizeof(char));

    if ( colsep == NULL ) return (sf_oom_error("sf_levelsof", "colsep"));
    if ( sep    == NULL ) return (sf_oom_error("sf_levelsof", "sep"));
    if ( numfmt == NULL ) return (sf_oom_error("sf_levelsof", "numfmt"));

    memset (colsep, '\0', (st_info->colsep_len + 1) * sizeof(char));
    memset (sep,    '\0', (st_info->sep_len    + 1) * sizeof(char));
    memset (numfmt, '\0', (st_info->numfmt_max + 1) * sizeof(char));

    if ( (rc = SF_macro_use("_colsep", colsep, (st_info->colsep_len + 1) * sizeof(char))) ) goto exit;
    if ( (rc = SF_macro_use("_sep",    sep,    (st_info->sep_len    + 1) * sizeof(char))) ) goto exit;
    if ( (rc = SF_macro_use("_numfmt", numfmt, (st_info->numfmt_max + 1) * sizeof(char))) ) goto exit;

    /*********************************************************************
     *             Step 4: Get top groups and summary Stats              *
     *********************************************************************/

    GT_size topprint = 0;
    GT_size rowmiss  = 0;
    GT_size totmiss  = 0;
    GT_size rowbytes = (st_info->rowbytes + sizeof(GT_size));

    strpos = macrobuffer;
    if ( st_info->kvars_by_str > 0 ) {
        if ( st_info->top_miss ) {
            for (j = 0; j < st_info->J; j++) {
                rowmiss = 0;
                for (k = 0; k < kvars; k++) {
                    sel = topix[j] * rowbytes + st_info->positions[k];
                    if ( st_info->byvars_lens[k] > 0 ) {
                        if ( strcmp(st_info->st_by_charx + sel, "") == 0 ) {
                            rowmiss++;
                            if ( st_info->top_groupmiss )
                                goto countmiss_char;
                        }
                    }
                    else {
                        z = *((ST_double *) (st_info->st_by_charx + sel));
                        if ( SF_is_missing(z) ) {
                            rowmiss++;
                            if ( st_info->top_groupmiss )
                                goto countmiss_char;
                        }
                    }
                }

                if ( st_info->top_miss & (rowmiss == kvars) )
                    goto countmiss_char;

                if ( topprint < ntop ) {
                    toptop[topprint * 5 + 1] = (ST_double) topall[j];
                    toptop[topprint * 5 + 3] = (ST_double) topall[j] * 100 / Ndbl;

                    if ( (toptop[topprint * 5 + 3] < st_info->top_pct) | 
                         (toptop[topprint * 5 + 1] < st_info->top_freq) )
                        continue;

                    toptop[topprint * 5] = (ST_double) j;
                    topprint++;
                }
                continue;

countmiss_char:
                totmiss += topall[j];
            }
        }
        else {
            for (j = 0; j < st_info->J; j++) {
                if ( topprint >= ntop ) break;

                toptop[topprint * 5 + 1] = (ST_double) topall[j];
                toptop[topprint * 5 + 3] = (ST_double) topall[j] * 100 / Ndbl;

                if ( (toptop[topprint * 5 + 3] < st_info->top_pct) | 
                     (toptop[topprint * 5 + 1] < st_info->top_freq) )
                    continue;

                toptop[topprint * 5] = (ST_double) j;
                topprint++;
            }
        }

        for (j = 0; j < topprint; j++) {
            numpos = 0;
            l = (GT_size) toptop[j * 5];
            toptop[j * 5] = (ST_double) 1;
            if ( j > 0 ) strpos += sprintf(strpos, "%s", sep);
            if ( kvars > 1 ) strpos += sprintf(strpos, "`\"");
            for (k = 0; k < kvars; k++) {
                if ( k > 0 ) strpos += sprintf(strpos, "%s", colsep);
                sel = topix[l] * rowbytes + st_info->positions[k];
                if ( st_info->byvars_lens[k] > 0 ) {
                    strpos += sprintf(strpos, sprintfmt, st_info->st_by_charx + sel);
                }
                else {
                    z = *((ST_double *) (st_info->st_by_charx + sel));
                    if ( SF_is_missing(z) ) {
                        GTOOLS_SWITCH_MISSING
                    }
                    else {
                        strpos += sprintf(strpos, numfmt, z);
                    }
                    numpos++;
                    if ( (rc = SF_mat_store("__gtools_top_num", j + 1, numpos, z)) ) goto exit;
                }
            }
            if ( kvars > 1 ) strpos += sprintf(strpos, "\"'");
        }
    }
    else {
        if ( st_info->top_miss ) {
            for (j = 0; j < st_info->J; j++) {
                rowmiss = 0;
                for (k = 0; k < kvars; k++) {
                    sel = topix[j] * (kvars + 1) + k;
                    if ( SF_is_missing(st_info->st_by_numx[sel]) ) {
                        rowmiss++;
                        if ( st_info->top_groupmiss )
                            goto countmiss_dbl;
                    }
                }

                if ( st_info->top_miss & (rowmiss == kvars) )
                    goto countmiss_dbl;

                if ( topprint < ntop ) {
                    toptop[topprint * 5 + 1] = (ST_double) topall[j];
                    toptop[topprint * 5 + 3] = (ST_double) topall[j] * 100 / Ndbl;

                    if ( (toptop[topprint * 5 + 3] < st_info->top_pct) | 
                         (toptop[topprint * 5 + 1] < st_info->top_freq) )
                        continue;

                    toptop[topprint * 5] = (ST_double) j;
                    topprint++;
                }
                continue;

countmiss_dbl:
                totmiss += topall[j];
            }
        }
        else {
            for (j = 0; j < st_info->J; j++) {
                if ( topprint >= ntop ) break;

                toptop[topprint * 5 + 1] = (ST_double) topall[j];
                toptop[topprint * 5 + 3] = (ST_double) topall[j] * 100 / Ndbl;

                if ( (toptop[topprint * 5 + 3] < st_info->top_pct) | 
                     (toptop[topprint * 5 + 1] < st_info->top_freq) )
                    continue;

                toptop[topprint * 5] = (ST_double) j;
                topprint++;
            }
        }

        for (j = 0; j < topprint; j++) {
            l = (GT_size) toptop[j * 5];
            toptop[j * 5] = (ST_double) 1;
            if ( j > 0 ) strpos += sprintf(strpos, "%s", sep);
            if ( kvars > 1 ) strpos += sprintf(strpos, "`\"");
            for (k = 0; k < kvars; k++) {
                if ( k > 0 ) strpos += sprintf(strpos, "%s", colsep);
                sel = topix[l] * (kvars + 1) + k;
                z  = st_info->st_by_numx[sel];
                if ( SF_is_missing(z) ) {
                    GTOOLS_SWITCH_MISSING
                }
                else {
                    strpos += sprintf(strpos, numfmt, z);
                }
                if ( (rc = SF_mat_store("__gtools_top_num", j + 1, k + 1, z)) ) goto exit;
            }
            if ( kvars > 1 ) strpos += sprintf(strpos, "\"'");
        }
    }

    if ( (rc = SF_macro_save("_vals", macrobuffer)) ) goto exit;
    if ( st_info->benchmark )
        sf_running_timer (&timer, "\tPlugin step 5: Wrote top levels to Stata macro");

    if ( totmiss > 0 ) {
        toptop[topprint * 5 + 0] = 2;
        toptop[topprint * 5 + 1] = totmiss;
        toptop[topprint * 5 + 3] = (ST_double) 100 * totmiss / Ndbl;
        topprint++;
    }

    toptop[2] = toptop[1];
    toptop[4] = toptop[3];
    for (j = 1; j < topprint; j++) {
        toptop[j * 5 + 2] = toptop[(j - 1) * 5 + 2] + toptop[j * 5 + 1];
        toptop[j * 5 + 4] = 100 * toptop[j * 5 + 2] / Ndbl;
    }

    if ( topprint == 0 ) {
        if ( st_info->top_other ) {
            toptop[topprint * 5 + 0] = 3;
            toptop[topprint * 5 + 1] = Ndbl;
            toptop[topprint * 5 + 2] = Ndbl;
            toptop[topprint * 5 + 3] = 100;
            toptop[topprint * 5 + 4] = 100;
            topprint++;
        }
    }
    else if ( topprint > 0 ) {
        if ( st_info->top_other & (toptop[(topprint - 1) * 5 + 2] < Ndbl) ) {
            toptop[topprint * 5 + 0] = 3;
            toptop[topprint * 5 + 1] = Ndbl - toptop[(topprint - 1) * 5 + 2];
            toptop[topprint * 5 + 2] = Ndbl;
            toptop[topprint * 5 + 3] = 100 * toptop[topprint * 5 + 1] / Ndbl;
            toptop[topprint * 5 + 4] = 100;
            topprint++;
        }
    }

    for (j = 0; j < topprint; j++) {
        if ( (rc = SF_mat_store("__gtools_top_matrix", j + 1, 1, toptop[j * 5 + 0])) ) goto exit;
        if ( (rc = SF_mat_store("__gtools_top_matrix", j + 1, 2, toptop[j * 5 + 1])) ) goto exit;
        if ( (rc = SF_mat_store("__gtools_top_matrix", j + 1, 3, toptop[j * 5 + 2])) ) goto exit;
        if ( (rc = SF_mat_store("__gtools_top_matrix", j + 1, 4, toptop[j * 5 + 3])) ) goto exit;
        if ( (rc = SF_mat_store("__gtools_top_matrix", j + 1, 5, toptop[j * 5 + 4])) ) goto exit;
    }

exit:
    free (sep);
    free (colsep);
    free (numfmt);
    free (sprintfmt);
    free (macrobuffer);

error:
    free (toptop);
    free (topall);
    free (topix);

    GTOOLS_GC_FREED("toptop")
    GTOOLS_GC_FREED("topall")
    GTOOLS_GC_FREED("topix")

    return (rc);
}
