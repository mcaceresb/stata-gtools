ST_retcode sf_top (struct StataInfo *st_info, int level);

ST_retcode sf_top (struct StataInfo *st_info, int level)
{

    /*********************************************************************
     *                           Step 1: Setup                           *
     *********************************************************************/

    if ( st_info->top_ntop > ((ST_double) st_info->J) ) {
        st_info->top_ntop = (ST_double) st_info->J;
    }

    if ( st_info->top_ntop < -((ST_double) st_info->J) ) {
        st_info->top_ntop = -((ST_double) st_info->J);
    }

    if ( st_info->top_ntop < 0 ) {
        st_info->top_ntop = -st_info->top_ntop;
    }

    ST_retcode rc = 0;
    ST_double z, wsum;
    GT_size i, j, k, l, start, end;
    GT_size sel, numpos;
    GT_size numwidth = st_info->numfmt_max > 18? st_info->numfmt_max + 5: 23;
    GT_bool alpha    = st_info->top_alpha;
    GT_bool weights  = st_info->wcode > 0;
    GT_bool wpos     = st_info->wpos;
    GT_bool invert   = st_info->top_invert;
    GT_size kvars    = st_info->kvars_by;
    GT_size knum     = st_info->kvars_by_num;
    GT_size ntop     = GTOOLS_PWMAX((GT_size) st_info->top_ntop, 1);
    GT_size nrows    = ntop + st_info->top_miss + st_info->top_other;
    GT_size kalloc   = st_info->top_matasave? 1: (knum > 0? knum * ntop: 1);
    ST_double Ndbl   = (ST_double) st_info->N;
    GT_bool debug    = st_info->debug;
    clock_t timer    = clock();

    FILE *ftopnum;
    FILE *ftopmat;

    char GTOOLS_GTOPNUM_FILE[st_info->gfile_topnum];
    char GTOOLS_GTOPMAT_FILE[st_info->gfile_topmat];

    if ( debug ) {
        sf_printf_debug("debug 1 (sf_top): read in meta info\n");
        sf_printf_debug("\t"GT_size_cfmt" obs, "GT_size_cfmt" read, "GT_size_cfmt" groups.\n",
                        st_info->N, st_info->Nread, st_info->J);
        sf_printf_debug("\tin1 / in2: "GT_size_cfmt" / "GT_size_cfmt"\n", st_info->in1, st_info->in2);
        sf_printf_debug("\tkvars_by_str: "GT_size_cfmt"\n", st_info->kvars_by_str);
        sf_printf_debug("\tkvars_by_num: "GT_size_cfmt"\n", st_info->kvars_by_num);
        sf_printf_debug("\tnumfmt_max:   "GT_size_cfmt"\n", st_info->numfmt_max);
        sf_printf_debug("\n");
        sf_printf_debug("\tkvars:        "GT_size_cfmt"\n", kvars);
        sf_printf_debug("\tnumwidth:     "GT_size_cfmt"\n", numwidth);
        sf_printf_debug("\tweights:      %u\n",             weights);
        sf_printf_debug("\tinvert:       %u\n",             invert);
        sf_printf_debug("\talpha:        %u\n",             alpha);
        sf_printf_debug("\ntop:          "GT_size_cfmt"\n", ntop);
        sf_printf_debug("\tnrows:        "GT_size_cfmt"\n", nrows);
        sf_printf_debug("\tkalloc:       "GT_size_cfmt"\n", kalloc);
        sf_printf_debug("\n");
    }

    /*********************************************************************
     *                     Step 2: Sort group counts                     *
     *********************************************************************/

    ST_double *topnum = calloc(kalloc,                 sizeof *topnum);
    ST_double *toptop = calloc(5 * nrows,              sizeof *toptop);
    ST_double *topwgt = calloc(weights? st_info->J: 1, sizeof *topwgt);
    GT_size   *topall = calloc(weights? 1: st_info->J, sizeof *topall);
    GT_size   *topix  = calloc(st_info->J,             sizeof *topix);

    if ( topnum == NULL ) sf_oom_error("sf_top", "topnum");
    if ( toptop == NULL ) sf_oom_error("sf_top", "toptop");
    if ( topwgt == NULL ) sf_oom_error("sf_top", "topwgt");
    if ( topall == NULL ) sf_oom_error("sf_top", "topall");
    if ( topix  == NULL ) sf_oom_error("sf_top", "topix");

    GTOOLS_GC_ALLOCATED("topnum")
    GTOOLS_GC_ALLOCATED("toptop")
    GTOOLS_GC_ALLOCATED("topwgt")
    GTOOLS_GC_ALLOCATED("topall")
    GTOOLS_GC_ALLOCATED("topix")

    if ( debug ) {
        sf_printf_debug("debug 2 (sf_top): Memory allocation.\n");
    }

    // Read weights, if requested
    wsum = 0;
    if ( weights ) {
        ST_double *sumwgt = calloc(2 * st_info->J, sizeof *sumwgt);
        if ( sumwgt == NULL ) sf_oom_error("sf_top", "sumwgt");

        for (j = 0; j < st_info->J; j++) {
            sumwgt[2 * j]     = 0;
            sumwgt[2 * j + 1] = j;
            l     = st_info->ix[j];
            start = st_info->info[l];
            end   = st_info->info[l + 1];
            for (i = start; i < end; i++) {
                sel = st_info->index[i] + st_info->in1;
                if ( (rc = SF_vdata(wpos, sel, &z)) ) goto errorw;
                sumwgt[2 * j] += z;
                wsum += z;
            }
        }

        if ( debug ) {
            sf_printf_debug("debug 3 (sf_top): Top levels by weight.\n");
        }

        // We sort by xtileCompareInvert by default to get stuff in
        // descending order (largest to smallest; note have to use
        // MultiQuicksortDbl to keep the sort order of the levels).

        // quicksort_bsd (
        //     sumwgt,
        //     st_info->J,
        //     2 * (sizeof *sumwgt),
        //     invert? xtileCompare: xtileCompareInvert,
        //     NULL
        // );

        GT_size invertwgt[2]; invertwgt[0] = !invert; invertwgt[1] = 0;
        if ( (alpha == 0) | (ntop < st_info->J) ) {
            MultiQuicksortDbl(
                sumwgt,
                st_info->J,
                0,
                1,
                2 * (sizeof *sumwgt),
                invertwgt
            );
        }

        for (j = 0; j < st_info->J; j++) {
            topwgt[j] = sumwgt[2 * j];
            topix[j]  = (GT_size) sumwgt[2 * j + 1];
        }

errorw:
        free (sumwgt);
        if ( rc ) {
            goto error;
        }

        if ( debug ) {
            sf_printf_debug("debug 4 (sf_top): Sorted levels by weight.\n");
        }
    }
    else {
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

        if ( debug ) {
            sf_printf_debug("debug 3 (sf_top): Top (or bottom) levels by count.\n");
        }

        // Sort in ascending order, which is descending group order
        GT_size min   = invert? st_info->nj_min: st_info->N - st_info->nj_max;
        GT_size max   = invert? st_info->nj_max: st_info->N - st_info->nj_min;
        GT_size range = (st_info->nj_max - st_info->nj_min);
        GT_size ctol  = pow(2, 24);

        if ( (alpha == 0) | (ntop < st_info->J) ) {
            if ( range < ctol ) {
                if ( (rc = gf_counting_sort (topall, topix, st_info->J, min, max)) )
                    goto error;
            }
            else {
                if ( (rc = gf_radix_sort16 (topall, topix, st_info->J)) )
                    goto error;
            }
        }

        // Back to frequencies
        if ( !invert ) {
            for (j = 0; j < st_info->J; j++)
                topall[j] = st_info->N - topall[j];
        }

        if ( debug ) {
            sf_printf_debug("debug 4 (sf_top): Sorted levels by count.\n");
        }
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

    if ( st_info->top_matasave ) {
        bufferlen  = 1;
    }
    else {
        bufferlen  = totalseplen + 1;
        bufferlen += ntop * (totalrowlen + sprintextra * st_info->kvars_by_str);
        bufferlen += (kvars > 1)? 4 * ntop: 0;
    }

    macrobuffer = malloc(bufferlen * sizeof(char));
    if ( macrobuffer == NULL ) return (sf_oom_error("sf_top", "macrobuffer"));
    memset (macrobuffer, '\0', bufferlen * sizeof(char));

    // Column sep, label for miss, other
    // ---------------------------------

    char *colsep = malloc((st_info->colsep_len + 1) * sizeof(char));
    char *sep    = malloc((st_info->sep_len    + 1) * sizeof(char));
    char *numfmt = malloc((st_info->numfmt_len + 1) * sizeof(char));

    if ( colsep == NULL ) return (sf_oom_error("sf_top", "colsep"));
    if ( sep    == NULL ) return (sf_oom_error("sf_top", "sep"));
    if ( numfmt == NULL ) return (sf_oom_error("sf_top", "numfmt"));

    memset (colsep, '\0', (st_info->colsep_len + 1) * sizeof(char));
    memset (sep,    '\0', (st_info->sep_len    + 1) * sizeof(char));
    memset (numfmt, '\0', (st_info->numfmt_len + 1) * sizeof(char));

    if ( (rc = SF_macro_use("_colsep", colsep, (st_info->colsep_len + 1) * sizeof(char))) ) goto exit;
    if ( (rc = SF_macro_use("_sep",    sep,    (st_info->sep_len    + 1) * sizeof(char))) ) goto exit;
    if ( (rc = SF_macro_use("_numfmt", numfmt, (st_info->numfmt_len + 1) * sizeof(char))) ) goto exit;

    if ( debug ) {
        sf_printf_debug("debug 5 (sf_top): Read in locals with meta info.\n");
    }

    /*********************************************************************
     *             Step 4: Get top groups and summary Stats              *
     *********************************************************************/

    GT_size topprint = 0;
    GT_size rowmiss  = 0;
    GT_size totmiss  = 0;
    GT_size rowbytes = (st_info->rowbytes + sizeof(GT_size));

    strpos = macrobuffer;
    if ( weights ) {
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
                                    goto countmiss_charw;
                            }
                        }
                        else {
                            z = *((ST_double *) (st_info->st_by_charx + sel));
                            if ( SF_is_missing(z) ) {
                                rowmiss++;
                                if ( st_info->top_groupmiss )
                                    goto countmiss_charw;
                            }
                        }
                    }

                    if ( st_info->top_miss & (rowmiss == kvars) )
                        goto countmiss_charw;

                    if ( topprint < ntop ) {
                        toptop[topprint * 5 + 1] = topwgt[j];
                        toptop[topprint * 5 + 3] = topwgt[j] * 100 / wsum;

                        if ( (toptop[topprint * 5 + 3] < st_info->top_pct) |
                             (toptop[topprint * 5 + 1] < st_info->top_freq) )
                            continue;

                        // toptop[topprint * 5] = (ST_double) j;
                        toptop[topprint * 5] = (ST_double) topix[j];
                        topprint++;
                    }
                    continue;

countmiss_charw:
                    totmiss += topwgt[j];
                }
            }
            else {
                for (j = 0; j < st_info->J; j++) {
                    if ( topprint >= ntop ) break;

                    toptop[topprint * 5 + 1] = topwgt[j];
                    toptop[topprint * 5 + 3] = topwgt[j] * 100 / wsum;

                    if ( (toptop[topprint * 5 + 3] < st_info->top_pct) |
                         (toptop[topprint * 5 + 1] < st_info->top_freq) )
                        continue;

                    // toptop[topprint * 5] = (ST_double) j;
                    toptop[topprint * 5] = (ST_double) topix[j];
                    topprint++;
                }
            }

            if ( alpha & (ntop < st_info->J) ) {
                quicksort_bsd (
                    toptop,
                    topprint,
                    5 * (sizeof *toptop),
                    xtileCompare,
                    NULL
                );
            }

            if ( st_info->top_matasave ) {
                for (j = 0; j < topprint; j++) {
                    topix[j] = (GT_size) toptop[j * 5];
                    toptop[j * 5] = (ST_double) 1;
                }
            }
            else {
                for (j = 0; j < topprint; j++) {
                    numpos = 0;
                    topix[j] = l = (GT_size) toptop[j * 5];
                    toptop[j * 5] = (ST_double) 1;
                    if ( j > 0 ) strpos += sprintf(strpos, "%s", sep);
                    if ( kvars > 1 ) strpos += sprintf(strpos, "`\"");
                    for (k = 0; k < kvars; k++) {
                        if ( k > 0 ) strpos += sprintf(strpos, "%s", colsep);
                        sel = l * rowbytes + st_info->positions[k];
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
                            topnum[j * knum + numpos] = z;
                            // if ( (rc = SF_mat_store("__gtools_top_num", j + 1, numpos, z)) ) goto exit;
                        }
                    }
                    if ( kvars > 1 ) strpos += sprintf(strpos, "\"'");
                }
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
                                goto countmiss_dblw;
                        }
                    }

                    if ( st_info->top_miss & (rowmiss == kvars) )
                        goto countmiss_dblw;

                    if ( topprint < ntop ) {
                        toptop[topprint * 5 + 1] = topwgt[j];
                        toptop[topprint * 5 + 3] = topwgt[j] * 100 / wsum;

                        if ( (toptop[topprint * 5 + 3] < st_info->top_pct) |
                             (toptop[topprint * 5 + 1] < st_info->top_freq) )
                            continue;

                        // toptop[topprint * 5] = (ST_double) j;
                        toptop[topprint * 5] = (ST_double) topix[j];
                        topprint++;
                    }
                    continue;

countmiss_dblw:
                    totmiss += topwgt[j];
                }
            }
            else {
                for (j = 0; j < st_info->J; j++) {
                    if ( topprint >= ntop ) break;

                    toptop[topprint * 5 + 1] = topwgt[j];
                    toptop[topprint * 5 + 3] = topwgt[j] * 100 / wsum;

                    if ( (toptop[topprint * 5 + 3] < st_info->top_pct) |
                         (toptop[topprint * 5 + 1] < st_info->top_freq) )
                        continue;

                    // toptop[topprint * 5] = (ST_double) j;
                    toptop[topprint * 5] = (ST_double) topix[j];
                    topprint++;
                }
            }

            if ( alpha & (ntop < st_info->J) ) {
                quicksort_bsd (
                    toptop,
                    topprint,
                    5 * (sizeof *toptop),
                    xtileCompare,
                    NULL
                );
            }

            if ( st_info->top_matasave ) {
                for (j = 0; j < topprint; j++) {
                    topix[j] = (GT_size) toptop[j * 5];
                    toptop[j * 5] = (ST_double) 1;
                }
            }
            else {
                for (j = 0; j < topprint; j++) {
                    topix[j] = l = (GT_size) toptop[j * 5];
                    toptop[j * 5] = (ST_double) 1;
                    if ( j > 0 ) strpos += sprintf(strpos, "%s", sep);
                    if ( kvars > 1 ) strpos += sprintf(strpos, "`\"");
                    for (k = 0; k < kvars; k++) {
                        if ( k > 0 ) strpos += sprintf(strpos, "%s", colsep);
                        sel = l * (kvars + 1) + k;
                        z  = st_info->st_by_numx[sel];
                        if ( SF_is_missing(z) ) {
                            GTOOLS_SWITCH_MISSING
                        }
                        else {
                            strpos += sprintf(strpos, numfmt, z);
                        }
                        topnum[j * knum + k] = z;
                        // if ( (rc = SF_mat_store("__gtools_top_num", j + 1, k + 1, z)) ) goto exit;
                    }
                    if ( kvars > 1 ) strpos += sprintf(strpos, "\"'");
                }
            }
        }
    }
    else {
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

                        // toptop[topprint * 5] = (ST_double) j;
                        toptop[topprint * 5] = (ST_double) topix[j];
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

                    // toptop[topprint * 5] = (ST_double) j;
                    toptop[topprint * 5] = (ST_double) topix[j];
                    topprint++;
                }
            }

            if ( alpha & (ntop < st_info->J) ) {
                quicksort_bsd (
                    toptop,
                    topprint,
                    5 * (sizeof *toptop),
                    xtileCompare,
                    NULL
                );
            }

            if ( st_info->top_matasave ) {
                for (j = 0; j < topprint; j++) {
                    topix[j] = (GT_size) toptop[j * 5];
                    toptop[j * 5] = (ST_double) 1;
                }
            }
            else {
                for (j = 0; j < topprint; j++) {
                    numpos = 0;
                    topix[j] = l = (GT_size) toptop[j * 5];
                    toptop[j * 5] = (ST_double) 1;
                    if ( j > 0 ) strpos += sprintf(strpos, "%s", sep);
                    if ( kvars > 1 ) strpos += sprintf(strpos, "`\"");
                    for (k = 0; k < kvars; k++) {
                        if ( k > 0 ) strpos += sprintf(strpos, "%s", colsep);
                        sel = l * rowbytes + st_info->positions[k];
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
                            topnum[j * knum + numpos] = z;
                            // if ( (rc = SF_mat_store("__gtools_top_num", j + 1, numpos, z)) ) goto exit;
                        }
                    }
                    if ( kvars > 1 ) strpos += sprintf(strpos, "\"'");
                }
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

                        // toptop[topprint * 5] = (ST_double) j;
                        toptop[topprint * 5] = (ST_double) topix[j];
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

                    // toptop[topprint * 5] = (ST_double) j;
                    toptop[topprint * 5] = (ST_double) topix[j];
                    topprint++;
                }
            }

            if ( alpha & (ntop < st_info->J) ) {
                quicksort_bsd (
                    toptop,
                    topprint,
                    5 * (sizeof *toptop),
                    xtileCompare,
                    NULL
                );
            }

            if ( st_info->top_matasave ) {
                for (j = 0; j < topprint; j++) {
                    topix[j] = (GT_size) toptop[j * 5];
                    toptop[j * 5] = (ST_double) 1;
                }
            }
            else {
                for (j = 0; j < topprint; j++) {
                    topix[j] = l = (GT_size) toptop[j * 5];
                    toptop[j * 5] = (ST_double) 1;
                    if ( j > 0 ) strpos += sprintf(strpos, "%s", sep);
                    if ( kvars > 1 ) strpos += sprintf(strpos, "`\"");
                    for (k = 0; k < kvars; k++) {
                        if ( k > 0 ) strpos += sprintf(strpos, "%s", colsep);
                        sel = l * (kvars + 1) + k;
                        z  = st_info->st_by_numx[sel];
                        if ( SF_is_missing(z) ) {
                            GTOOLS_SWITCH_MISSING
                        }
                        else {
                            strpos += sprintf(strpos, numfmt, z);
                        }
                        topnum[j * knum + k] = z;
                        // if ( (rc = SF_mat_store("__gtools_top_num", j + 1, k + 1, z)) ) goto exit;
                    }
                    if ( kvars > 1 ) strpos += sprintf(strpos, "\"'");
                }
            }
        }
    }

    if ( debug ) {
        sf_printf_debug("debug 6 (sf_top): Read in levels into string buffer.\n");
    }

    if ( (rc = SF_macro_save("_vals", macrobuffer)) ) goto exit;
    if ( st_info->benchmark > 1 )
        sf_running_timer (&timer, "\tPlugin step 5: Wrote top levels to Stata macro");

    if ( weights ) Ndbl = wsum;
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

    // __gtools_top_matrix 
    // __gtools_top_num

    // for (j = 0; j < topprint; j++) {
    //     if ( (rc = SF_mat_store("__gtools_top_matrix", j + 1, 1, toptop[j * 5 + 0])) ) goto exit;
    //     if ( (rc = SF_mat_store("__gtools_top_matrix", j + 1, 2, toptop[j * 5 + 1])) ) goto exit;
    //     if ( (rc = SF_mat_store("__gtools_top_matrix", j + 1, 3, toptop[j * 5 + 2])) ) goto exit;
    //     if ( (rc = SF_mat_store("__gtools_top_matrix", j + 1, 4, toptop[j * 5 + 3])) ) goto exit;
    //     if ( (rc = SF_mat_store("__gtools_top_matrix", j + 1, 5, toptop[j * 5 + 4])) ) goto exit;
    // }

    if ( (rc = SF_macro_use("GTOOLS_GTOPNUM_FILE", GTOOLS_GTOPNUM_FILE, st_info->gfile_topnum) )) goto exit;
    if ( (rc = SF_macro_use("GTOOLS_GTOPMAT_FILE", GTOOLS_GTOPMAT_FILE, st_info->gfile_topmat) )) goto exit;

    ftopnum = fopen(GTOOLS_GTOPNUM_FILE, "wb");
    ftopmat = fopen(GTOOLS_GTOPMAT_FILE, "wb");

    rc = rc | (fwrite(topnum, sizeof *topnum, kalloc,    ftopnum) != kalloc);
    rc = rc | (fwrite(toptop, sizeof *toptop, 5 * nrows, ftopmat) != (5 * nrows));

    fclose(ftopnum);
    fclose(ftopmat);

    if ( debug ) {
        sf_printf_debug("debug 7 (sf_top): Created output matrix with frequency counts and such.\n");
    }

    if ( (rc = SF_scal_save("__gtools_top_nrows", (ST_double) nrows)) ) goto exit;
    if ( (rc = SF_scal_save("__gtools_top_ntop",  (ST_double) ntop))  ) goto exit;

    if ( st_info->top_matasave ) {
        if ( (alpha == 0) | (ntop < st_info->J) ) {
            if ( (rc = sf_byx_save_top (st_info, ntop, topix)) ) goto exit;
        }
        else {
            if ( (rc = sf_byx_save_top (st_info, 0, NULL)) ) goto exit;
        }
    }

exit:
    free (sep);
    free (colsep);
    free (numfmt);
    free (sprintfmt);
    free (macrobuffer);

error:
    free (topnum);
    free (toptop);
    free (topwgt);
    free (topall);
    free (topix);

    GTOOLS_GC_FREED("topnum")
    GTOOLS_GC_FREED("toptop")
    GTOOLS_GC_FREED("topwgt")
    GTOOLS_GC_FREED("topall")
    GTOOLS_GC_FREED("topix")

    return (rc);
}
