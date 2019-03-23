ST_retcode sf_levelsof     (struct StataInfo *st_info, int level);
ST_retcode sf_write_levels (struct StataInfo *st_info, int level);

ST_retcode sf_levelsof (struct StataInfo *st_info, int level)
{

    ST_retcode rc = 0;
    if ( (st_info->levels_return == 0) && (st_info->levels_matasave == 0) ) {
        if ( st_info->levels_gen == 0 ) {
            sf_printf("(note: glevelsof will not store the levels of varlist)\n");
            return (0);
        }
        else {
            return (sf_write_levels (st_info, level));
        }
    }
    else if ( st_info->levels_gen > 0 ) {
        if ( (rc = sf_write_levels (st_info, level) ) ) return (rc);
    }

    /*********************************************************************
     *                           Step 1: Setup                           *
     *********************************************************************/

    ST_double z;
    GT_size j, k;
    GT_size sel;
    GT_size numwidth = st_info->numfmt_max > 18? st_info->numfmt_max + 5: 23;
    GT_size kvars = st_info->kvars_by;
    GT_bool debug = st_info->debug;
    clock_t timer = clock();

    /*********************************************************************
     *                     Copy output back to stata                     *
     *********************************************************************/

    // 18446744073709551615 is the largest unsigned integer, but I think
    // the largest doubles require 22 digits (decimal dot and scientific
    // notation).  So we allocate 22 per number (-levelsof- prints 16
    // significant digits otherwise, so 22 should be enough).

    char *macrobuffer;
    GT_size bufferlen;

    // char *sleft = strdup("`\""), *sright = strdup("\"'");
    // GT_size lsleft = strlen(sleft), lsright = strlen(sright), ls;
    char *sprintfmt     = st_info->cleanstr? strdup("%s"): strdup("`\"%s\"'");
    GT_size sprintextra = st_info->cleanstr? 0: 4;
    GT_size totalseplen = (st_info->J - 1) * st_info->sep_len +
                          st_info->J * st_info->colsep_len * (kvars - 1);

    if ( debug ) {
        sf_printf_debug("debug 1 (sf_levelsof): read in meta info\n");
        sf_printf_debug("\t"GT_size_cfmt" obs, "GT_size_cfmt" read, "GT_size_cfmt" groups.\n",
                        st_info->N, st_info->Nread, st_info->J);
        sf_printf_debug("\tin1 / in2: "GT_size_cfmt" / "GT_size_cfmt"\n", st_info->in1, st_info->in2);
        sf_printf_debug("\tkvars_by_str: "GT_size_cfmt"\n", st_info->kvars_by_str);
        sf_printf_debug("\tkvars_by_num: "GT_size_cfmt"\n", st_info->kvars_by_num);
        sf_printf_debug("\tnumfmt_max:   "GT_size_cfmt"\n", st_info->numfmt_max);
        sf_printf_debug("\tkvars:        "GT_size_cfmt"\n", kvars);
        sf_printf_debug("\n");
        sf_printf_debug("\tnumwidth:     "GT_size_cfmt"\n", numwidth);
        sf_printf_debug("\tsprintfmt:    %s\n",             sprintfmt);
        sf_printf_debug("\tsprintextra:  "GT_size_cfmt"\n", sprintextra);
        sf_printf_debug("\ttotalseplen:  "GT_size_cfmt"\n", totalseplen);
        sf_printf_debug("\n");
        sf_printf_debug("\tcleanstr:     "GT_size_cfmt"\n", st_info->cleanstr);
        sf_printf_debug("\tsep_len:      "GT_size_cfmt"\n", st_info->sep_len);
        sf_printf_debug("\tcolsep_len:   "GT_size_cfmt"\n", st_info->colsep_len);
        sf_printf_debug("\tnumfmt_len:   "GT_size_cfmt"\n", st_info->numfmt_len);
        sf_printf_debug("\tstrbuffer:    "GT_size_cfmt"\n", st_info->strbuffer);
    }

    if ( st_info->kvars_by_str > 0 ) {
        bufferlen   = sizeof(char) * totalseplen + 1;
        bufferlen  += sizeof(char) * st_info->J * (sprintextra * st_info->kvars_by_str);
        bufferlen  += sizeof(char) * st_info->J * (st_info->kvars_by_num * numwidth);
        bufferlen  += sizeof(char) * ((kvars > 1)? 4 * st_info->J: 0);
        bufferlen  += st_info->strbuffer;
        if ( st_info->levels_matasave ) {
            bufferlen = 1;
        }
        macrobuffer = malloc(bufferlen);
    }
    else {
        bufferlen   = totalseplen + 1;
        bufferlen  += st_info->J * (st_info->kvars_by_num * numwidth);
        bufferlen  += ((kvars > 1)? 4 * st_info->J: 0);
        if ( st_info->levels_matasave ) {
            bufferlen = 1;
        }
        macrobuffer = malloc(bufferlen * sizeof(char));
    }

    if ( macrobuffer == NULL ) return (sf_oom_error("sf_levelsof", "macrobuffer"));
    memset (macrobuffer, '\0', bufferlen * sizeof(char));

    char *strpos = macrobuffer;
    GT_size rowbytes = (st_info->rowbytes + sizeof(GT_size));

    char *colsep = malloc((st_info->colsep_len + 1) * sizeof(char));
    char *sep    = malloc((st_info->sep_len    + 1) * sizeof(char));
    char *numfmt = malloc((st_info->numfmt_len + 1) * sizeof(char));

    if ( colsep == NULL ) return (sf_oom_error("sf_levelsof", "colsep"));
    if ( sep    == NULL ) return (sf_oom_error("sf_levelsof", "sep"));
    if ( numfmt == NULL ) return (sf_oom_error("sf_levelsof", "numfmt"));

    memset (colsep, '\0', (st_info->colsep_len + 1) * sizeof(char));
    memset (sep,    '\0', (st_info->sep_len    + 1) * sizeof(char));
    memset (numfmt, '\0', (st_info->numfmt_len + 1) * sizeof(char));

    if ( (rc = SF_macro_use("_colsep", colsep, (st_info->colsep_len + 1) * sizeof(char))) ) goto exit;
    if ( (rc = SF_macro_use("_sep",    sep,    (st_info->sep_len    + 1) * sizeof(char))) ) goto exit;
    if ( (rc = SF_macro_use("_numfmt", numfmt, (st_info->numfmt_len + 1) * sizeof(char))) ) goto exit;

    if ( debug ) {
        sf_printf_debug("debug 2 (sf_levelsof): Read in locals info.\n");
    }

    if ( st_info->levels_matasave == 0 ) {
        if ( kvars > 1 ) {
            if ( st_info->kvars_by_str > 0 ) {
                for (j = 0; j < st_info->J; j++) {
                    if ( j > 0 ) strpos += sprintf(strpos, "%s", sep);
                    strpos += sprintf(strpos, "`\"");
                    for (k = 0; k < kvars; k++) {
                        if ( k > 0 ) strpos += sprintf(strpos, "%s", colsep);
                        sel = j * rowbytes + st_info->positions[k];
                        if ( st_info->byvars_lens[k] > 0 ) {
                            strpos += sprintf(strpos, sprintfmt, st_info->st_by_charx + sel);
                        }
                        else {
                            z = *((ST_double *) (st_info->st_by_charx + sel));
                            if ( SF_is_missing(z) ) {
                                // strpos += sprintf(strpos, ".");
                                GTOOLS_SWITCH_MISSING
                            }
                            else {
                                strpos += sprintf(strpos, numfmt, z);
                            }
                        }
                    }
                    strpos += sprintf(strpos, "\"'");
                }
            }
            else {
                for (j = 0; j < st_info->J; j++) {
                    if ( j > 0 ) strpos += sprintf(strpos, "%s", sep);
                    strpos += sprintf(strpos, "`\"");
                    for (k = 0; k < kvars; k++) {
                        if ( k > 0 ) strpos += sprintf(strpos, "%s", colsep);
                        sel = j * (kvars + 1) + k;
                        z  = st_info->st_by_numx[sel];
                        if ( SF_is_missing(z) ) {
                            // strpos += sprintf(strpos, ".");
                            GTOOLS_SWITCH_MISSING
                        }
                        else {
                            strpos += sprintf(strpos, numfmt, z);
                        }
                    }
                    strpos += sprintf(strpos, "\"'");
                }
            }
        }
        else {
            if ( st_info->kvars_by_str > 0 ) {
                for (j = 0; j < st_info->J; j++) {
                    if ( j > 0 ) strpos += sprintf(strpos, "%s", sep);
                    sel = j * rowbytes;
                    if ( st_info->byvars_lens[0] > 0 ) {
                        // ls = strlen(st_info->st_by_charx + sel);
                        // if ( st_info->cleanstr ) {
                        //     memcpy(
                        //         strpos,
                        //         st_info->st_by_charx + sel,
                        //         ls
                        //     );
                        //     strpos += ls;
                        // }
                        // else {
                        //     memcpy(
                        //         strpos,
                        //         sleft,
                        //         lsleft
                        //     );
                        //     strpos += lsleft;
                        //     memcpy(
                        //         strpos,
                        //         st_info->st_by_charx + sel,
                        //         ls
                        //     );
                        //     strpos += ls;
                        //     memcpy(
                        //         strpos,
                        //         sright,
                        //         lsright
                        //     );
                        //     strpos += lsright;
                        // }
                        strpos += sprintf(strpos, sprintfmt, st_info->st_by_charx + sel);
                    }
                    else {
                        z = *((ST_double *) (st_info->st_by_charx + sel));
                        if ( SF_is_missing(z) ) {
                            // strpos += sprintf(strpos, ".");
                            GTOOLS_SWITCH_MISSING
                        }
                        else {
                            strpos += sprintf(strpos, numfmt, z);
                        }
                    }
                }
            }
            else {
                for (j = 0; j < st_info->J; j++) {
                    if ( j > 0 ) strpos += sprintf(strpos, "%s", sep);
                    sel = j * (kvars + 1);
                    z = st_info->st_by_numx[sel];
                    if ( SF_is_missing(z) ) {
                        // strpos += sprintf(strpos, ".");
                        GTOOLS_SWITCH_MISSING
                    }
                    else {
                        strpos += sprintf(strpos, numfmt, z);
                    }
                }
            }
        }
    }

    if ( debug ) {
        sf_printf_debug("debug 3 (sf_levelsof): Read all levels into string buffer.\n");
    }

    if ( (rc = SF_macro_save("_vals", macrobuffer)) ) goto exit;
    if ( st_info->benchmark > 1 )
        sf_running_timer (&timer, "\tPlugin step 5: Wrote levels to Stata macro");

    if ( st_info->levels_matasave ) {
        if ( (rc = sf_byx_save_top (st_info, 0, NULL)) ) goto exit;
    }

exit:
    free (sep);
    free (colsep);
    free (numfmt);
    free (sprintfmt);
    free (macrobuffer);

    return (rc);
}

ST_retcode sf_write_levels (struct StataInfo *st_info, int level)
{

    /*********************************************************************
     *                           Step 1: Setup                           *
     *********************************************************************/

    ST_retcode rc = 0;
    ST_double z;

    GT_size j, k;
    GT_size sel, rowbytes;
    clock_t timer = clock();

    GT_size kvars = st_info->kvars_by;
    GT_size kpos  = st_info->levels_gen;

    /*********************************************************************
     *                   Write unique levels to memory                   *
     *********************************************************************/

    rowbytes = (st_info->rowbytes + sizeof(GT_size));
    if ( st_info->kvars_by_str > 0 ) {
        for (j = 0; j < st_info->J; j++) {
            for (k = 0; k < kvars; k++) {
                sel = j * rowbytes + st_info->positions[k];
                if ( st_info->byvars_lens[k] > 0 ) {
                    if ( (rc = SF_sstore(k + kpos, j + 1, st_info->st_by_charx + sel)) ) goto exit;
                }
                else {
                    z = *((ST_double *) (st_info->st_by_charx + sel));
                    if ( (rc = SF_vstore(k + kpos, j + 1, z)) ) goto exit;
                }
            }
        }

        if ( st_info->levels_replace ) {
            for (j = st_info->J; j < SF_nobs(); j++) {
                for (k = 0; k < kvars; k++) {
                    if ( st_info->byvars_lens[k] > 0 ) {
                        if ( (rc = SF_sstore(k + kpos, j + 1, "")) ) goto exit;
                    }
                    else {
                        if ( (rc = SF_vstore(k + kpos, j + 1, SV_missval)) ) goto exit;
                    }
                }
            }
        }
    }
    else {
        for (j = 0; j < st_info->J; j++) {
            for (k = 0; k < kvars; k++) {
                if ( (rc = SF_vstore(k + kpos,
                                     j + 1,
                                     st_info->st_by_numx[j * (kvars + 1) + k])) ) goto exit;
            }
        }

        if ( st_info->levels_replace ) {
            for (j = st_info->J; j < SF_nobs(); j++) {
                for (k = 0; k < kvars; k++) {
                    if ( (rc = SF_vstore(k + kpos, j + 1, SV_missval)) ) goto exit;
                }
            }
        }
    }

    if ( st_info->benchmark > 1 )
        sf_running_timer (&timer, "\tPlugin step 6: Copied unique levels to stata");

exit:
    return (rc);
}
