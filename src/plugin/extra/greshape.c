ST_retcode sf_reshape       (struct StataInfo *st_info, int level, char *fname);
ST_retcode sf_reshape_wide  (struct StataInfo *st_info, int level, char *fname);
ST_retcode sf_reshape_long  (struct StataInfo *st_info, int level, char *fname);
ST_retcode sf_reshape_read  (struct StataInfo *st_info, int level, char *fname);
GT_size sf_reshape_bytes(struct StataInfo *st_info, GT_size *outpos, GT_size *outtyp);

ST_retcode sf_reshape (struct StataInfo *st_info, int level, char *fname)
{
    if ( st_info->greshape_code == 1 ) {
        return (sf_reshape_long(st_info, level, fname));
    }
    else if ( st_info->greshape_code == 2 )  {
        return (sf_reshape_wide(st_info, level, fname));
    }
    else {
        return (198);
    }
}

/*********************************************************************
 *                           Reshape wide                            *
 *********************************************************************/

ST_retcode sf_reshape_wide (struct StataInfo *st_info, int level, char *fname)
{
    GT_bool debug = st_info->debug;
    if ( debug ) {
        sf_printf_debug("debug 1 (sf_reshape): Starting greshape.\n");
    }

    /*********************************************************************
     *                           Step 1: Setup                           *
     *********************************************************************/

    ST_retcode rc = 0;
    ST_double z;

    GT_size *ixptr;
    GT_size i, j, k, l, m;
    GT_size selx, start, end, jpos, rowbytes, outbytes, srcbytes;

    FILE *fhandle;
    char *strptr, *jstr, *outstr, *bufstr, *endstr;
    ST_double *dblptr, *jdbl, *outdbl, *bufdbl, *enddbl;

    GT_size kvars    = st_info->kvars_by;
    GT_size kout     = st_info->greshape_kout;
    GT_size kxij     = st_info->greshape_kxij;
    GT_size kxi      = st_info->greshape_kxi;
    GT_size klevels  = st_info->greshape_klvls;
    GT_size krow     = kvars + kxij + kxi;
    GT_size ksources = kout + 1 + kxi;
    GT_size ktargets = kxij + kxi;
    GT_size Nread    = st_info->Nread;
    GT_size J        = st_info->J;
    GT_size jbytes   = st_info->greshape_str * sizeof(char);
    clock_t timer    = clock();

    if ( jbytes ) {
        jbytes += sizeof(char);
    }
    else {
        jbytes = sizeof(ST_double);
    }

    if ( debug ) {
        sf_printf_debug("\tkvars:    "GT_size_cfmt"\n",  kvars);
        sf_printf_debug("\tkout:     "GT_size_cfmt"\n",  kout);
        sf_printf_debug("\tkxij:     "GT_size_cfmt"\n",  kxij);
        sf_printf_debug("\tkxi:      "GT_size_cfmt"\n",  kxi);
        sf_printf_debug("\tklevels:  "GT_size_cfmt"\n",  klevels);
        sf_printf_debug("\tkrow:     "GT_size_cfmt"\n",  krow);
        sf_printf_debug("\tksources: "GT_size_cfmt"\n",  ksources);
        sf_printf_debug("\tktargets: "GT_size_cfmt"\n",  ktargets);
        sf_printf_debug("\tNread:    "GT_size_cfmt"\n",  Nread);
        sf_printf_debug("\tJ:        "GT_size_cfmt"\n",  J);
    }

    // The variables passed to reshape long are of the form:
    //
    //     reshape wide a b c .., i(i1 i2 ...) j(j)
    //
    //     i         i1 i2
    //     j         jcode [encoded j]
    //     xij       a b c
    //     xij_names a1 a2 b10 b15 b20 c2 c15
    //     levels    1 2 10 15 20
    //
    //     types, array of length 3 with 0 if the kth variable is
    //     numeric and the string length if the kth variable is string.
    //
    // The variables passed to the plugin are i, jcode, and xij.

    GT_size *outpos   = calloc(kxij,  sizeof(outpos));
    GT_size *outtyp   = calloc(kxij,  sizeof(outtyp));
    GT_size *offset   = calloc(J,     sizeof *offset);
    GT_size *nj       = calloc(J + 1, sizeof *nj);
    GT_size *index_st = calloc(Nread, sizeof *index_st);

    if ( outpos   == NULL ) return(sf_oom_error("sf_reshape_wide", "outpos"));
    if ( outtyp   == NULL ) return(sf_oom_error("sf_reshape_wide", "outtyp"));
    if ( offset   == NULL ) return(sf_oom_error("sf_reshape_wide", "offset"));
    if ( nj       == NULL ) return(sf_oom_error("sf_reshape_wide", "nj"));
    if ( index_st == NULL ) return(sf_oom_error("sf_reshape_wide", "index_st"));

    jstr = calloc(klevels, jbytes);
    if ( st_info->greshape_str ) {
        jdbl = calloc(1, sizeof(jdbl));
    }
    else {
        jdbl = calloc(klevels, sizeof jdbl);
    }

    srcbytes = sizeof(ST_double);
    for (i = 0; i < kout; i++) {
        if ( (m = st_info->greshape_types[i]) ) {
            srcbytes += (m + 1) * sizeof(char);
        }
        else {
            srcbytes += sizeof(ST_double);
        }
    }

    outbytes = sf_reshape_bytes(st_info, outpos, outtyp);
    if ( st_info->greshape_anystr | st_info->kvars_by_str ) {
        outdbl = malloc(sizeof(ST_double));
        outstr = calloc(J, GTOOLS_PWMAX(outbytes, 1));
        memset(outstr, '\0', J * GTOOLS_PWMAX(outbytes, 1));
    }
    else {
        outstr = malloc(sizeof(char));
        outdbl = calloc(J * krow, sizeof outdbl);
    }

    if ( st_info->greshape_anystr ) {
        bufstr = calloc(Nread, srcbytes);
        bufdbl = malloc(sizeof(ST_double));
        memset(bufstr, '\0', Nread * GTOOLS_PWMAX(srcbytes, 1));
    }
    else {
        bufstr = malloc(sizeof(char));
        bufdbl = calloc(Nread * ksources, sizeof bufdbl);
    }

    if ( outdbl == NULL ) return(sf_oom_error("sf_reshape_wide", "outdbl"));
    if ( outstr == NULL ) return(sf_oom_error("sf_reshape_wide", "outstr"));
    if ( bufstr == NULL ) return(sf_oom_error("sf_reshape_wide", "bufstr"));
    if ( bufdbl == NULL ) return(sf_oom_error("sf_reshape_wide", "bufdbl"));

    if ( outbytes == 0 ) {
        rc = 198;
        goto exit;
    }

    /*********************************************************************
     *               Step 2: Read in variables from Stata                *
     *********************************************************************/

    if ( debug ) {
        sf_printf_debug("debug 2 (sf_reshape): Index Stata order.\n");
    }

    for (i = 0; i < st_info->J; i++) {
        offset[i] = 0;
    }

    for (i = 0; i < st_info->Nread; i++) {
        index_st[i] = 0;
    }

    nj[0] = 0;
    for (j = 0; j < J; j++) {
        l     = st_info->ix[j];
        start = st_info->info[l];
        end   = st_info->info[l + 1];
        nj[j + 1] = nj[j] + end - start;
        for (i = start; i < end; i++) {
            index_st[st_info->index[i]] = j + 1;
        }
    }

    if ( st_info->greshape_anystr == 0 ) {
        i = 0;
        for (ixptr = index_st; ixptr < index_st + Nread; ixptr++, i++) {
            if ( *ixptr == 0 ) continue;
            j = *ixptr - 1;
            dblptr = bufdbl + (nj[j] + offset[j]++) * ksources;
            if ( (rc = SF_vdata(kvars + 1, i + st_info->in1, dblptr++)) ) goto exit;
            for (k = 0; k < kout; k++) {
                if ( (rc = SF_vdata(kvars + k + 2, i + st_info->in1, dblptr++)) ) goto exit;
            }
        }
    }
    else {
        i = 0;
        for (ixptr = index_st; ixptr < index_st + Nread; ixptr++, i++) {
            if ( *ixptr == 0 ) continue;
            j = *ixptr - 1;
            strptr = bufstr + (nj[j] + offset[j]) * srcbytes;
            offset[j]++;

            if ( (rc = SF_vdata(kvars + 1, i + st_info->in1, &z)) ) goto exit;
            jpos = (GT_size) z;
            memcpy(strptr, &jpos, sizeof(GT_size));
            strptr += sizeof(ST_double);

            for (k = 0; k < kout; k++) {
                if ( (m = st_info->greshape_types[k]) ) {
                    if ( (rc = SF_sdata(kvars + k + 2,
                                        i + st_info->in1,
                                        strptr)) ) goto exit;
                    strptr += (m + 1);
                }
                else {
                    if ( (rc = SF_vdata(kvars + k + 2,
                                        i + st_info->in1,
                                        &z)) ) goto exit;

                    memcpy(strptr, &z, sizeof(ST_double));
                    strptr += sizeof(ST_double);
                }
            }
        }
    }

    if ( st_info->benchmark > 2 )
        sf_running_timer (&timer, "\t\treshape wide step 1: Read data in stata order");

    /*********************************************************************
     *                       Step 3: Reshape wide                        *
     *********************************************************************/

    // for (i = 0; i < Nread; i++) {
    //     selx = i * ksources;
    //     printf("%ld: ", i);
    //     for (k = 0; k < ksources; k++) {
    //         z = bufdbl[selx + k];
    //         if ( z < SV_missval ) {
    //             printf("\t%.3f\t(%ld)", z, selx + k);
    //         }
    //         else {
    //             printf("\t.");
    //         }
    //     }
    //     printf("\n");
    // }
    //     printf("\n");

    // for (i = 0; i < Nread; i++) {
    //     strptr = bufstr + i * srcbytes;
    //     printf("%ld: \t%ld", i, *(GT_size*) (strptr));
    //     strptr += sizeof(ST_double);
    //     for (k = 0; k < kout; k++) {
    //         if ( (m = st_info->greshape_types[k]) ) {
    //             printf("\t%s", strptr);
    //             strptr += m;
    //         }
    //         else {
    //                 z = (*(ST_double*) strptr);
    //                 if ( z < SV_missval ) {
    //                     printf("\t%.3f", z);
    //                 }
    //                 else {
    //                     printf("\t.");
    //                 }
    //                 strptr += sizeof(ST_double);
    //         }
    //     }
    //     printf("\n");
    // }
    //     printf("\n");

    rowbytes = (st_info->rowbytes + sizeof(GT_size));
    if ( st_info->greshape_anystr == 0 ) {
        if ( st_info->kvars_by_str == 0 ) {

            // All numeric
            // -----------

            for (j = 0; j < J; j++) {
                start  = nj[j];
                end    = nj[j + 1];
                quicksort_bsd (
                    bufdbl + start * ksources,
                    end - start,
                    ksources * sizeof(bufdbl),
                    xtileCompare,
                    NULL
                );

                selx = j * krow;
                dblptr = st_info->st_by_numx + j * (kvars + 1);
                for (k = 0; k < kvars; k++) {
                    outdbl[selx + k] = dblptr[k];
                }
                selx += kvars;

                dblptr = bufdbl + start * ksources;
                enddbl = bufdbl + end * ksources;
                jpos   = ((GT_size) dblptr[0]) - 1;
                for (l = 0; l < klevels; l++) {
                    if ( jpos == l && dblptr < enddbl ) {
                        for (k = 0; k < kout; k++) {
                            outdbl[selx + klevels * k + l] = dblptr[k + 1];
                        }
                        dblptr += ksources;
                        jpos    = ((GT_size) dblptr[0]) - 1;
                    }
                    else {
                        for (k = 0; k < kout; k++) {
                            outdbl[selx + klevels * k + l] = SV_missval;
                        }
                    }
                }
            }
        }
        else {

            // Sources numeric, by vars str
            // ----------------------------

            for (j = 0; j < J; j++) {
                start  = nj[j];
                end    = nj[j + 1];
                quicksort_bsd (
                    bufdbl + start * ksources,
                    end - start,
                    ksources * sizeof(bufdbl),
                    xtileCompare,
                    NULL
                );

                selx = j * outbytes;
                strptr = st_info->st_by_charx + j * rowbytes;
                memcpy(
                    outstr + selx,
                    strptr,
                    outpos[0]
                );

                dblptr = bufdbl + start * ksources;
                enddbl = bufdbl + end * ksources;
                jpos   = ((GT_size) dblptr[0]) - 1;
                for (l = 0; l < klevels; l++) {
                    if ( jpos == l && dblptr < enddbl ) {
                        for (k = 0; k < kout; k++) {
                            memcpy(
                                outstr + selx + outpos[klevels * k + l],
                                dblptr + k + 1,
                                sizeof(ST_double)
                            );
                        }
                        dblptr += ksources;
                        jpos    = ((GT_size) dblptr[0]) - 1;
                    }
                    else {
                        for (k = 0; k < kout; k++) {
                            memcpy(
                                outstr + selx + outpos[klevels * k + l],
                                &SV_missval,
                                sizeof(ST_double)
                            );
                        }
                    }
                }
            }
        }
    }
    else {
        if ( st_info->kvars_by_str == 0 ) {

            // Sources str, by vars numeric
            // ----------------------------

            for (j = 0; j < J; j++) {
                start = nj[j];
                end   = nj[j + 1];
                quicksort_bsd (
                    bufstr + start * srcbytes,
                    end - start,
                    srcbytes,
                    xtileCompare,
                    NULL
                );

                selx = j * outbytes;
                dblptr = st_info->st_by_numx + j * (kvars + 1);
                memcpy(
                    outstr + selx,
                    dblptr,
                    outpos[0]
                );

                strptr = bufstr + start * srcbytes;
                endstr = bufstr + end * srcbytes;
                jpos   = (*(GT_size*) strptr) - 1;
                for (l = 0; l < klevels; l++) {
                    if ( jpos == l && strptr < endstr ) {
                        strptr += sizeof(ST_double);
                        for (k = 0; k < kout; k++) {
                            m = st_info->greshape_types[k];
                            if ( m == 0 ) {
                                m = sizeof(ST_double);
                            }
                            else {
                                m++;
                            }
                            memcpy(
                                outstr + selx + outpos[klevels * k + l],
                                strptr,
                                m
                            );
                            strptr += m;
                        }
                        jpos = (*(GT_size*) strptr) - 1;
                    }
                    else {
                        for (k = 0; k < kout; k++) {
                            memcpy(
                                outstr + selx + outpos[klevels * k + l],
                                &SV_missval,
                                sizeof(ST_double)
                            );
                        }
                    }
                }
            }
        }
        else {

            // All str
            // -------

            for (j = 0; j < J; j++) {
                start = nj[j];
                end   = nj[j + 1];
                quicksort_bsd (
                    bufstr + start * srcbytes,
                    end - start,
                    srcbytes,
                    xtileCompare,
                    NULL
                );

                selx = j * outbytes;
                strptr = st_info->st_by_charx + j * rowbytes;
                memcpy(
                    outstr + selx,
                    strptr,
                    outpos[0]
                );

                strptr  = bufstr + start * srcbytes;
                endstr  = bufstr + end * srcbytes;
                jpos    = (*(GT_size*) strptr) - 1;
                for (l = 0; l < klevels; l++) {
                    if ( jpos == l && strptr < endstr ) {
                        strptr += sizeof(ST_double);
                        for (k = 0; k < kout; k++) {
                            m = st_info->greshape_types[k];
                            if ( m == 0 ) {
                                m = sizeof(ST_double);
                            }
                            else {
                                m++;
                            }
                            memcpy(
                                outstr + selx + outpos[klevels * k + l],
                                strptr,
                                m
                            );
                            strptr += m;
                        }
                        jpos = (*(GT_size*) strptr) - 1;
                    }
                    else {
                        for (k = 0; k < kout; k++) {
                            if ( st_info->greshape_types[k] == 0 ) {
                                memcpy(
                                    outstr + selx + outpos[klevels * k + l],
                                    &SV_missval,
                                    sizeof(ST_double)
                                );
                            }
                        }
                    }
                }
            }
        }
    }

    if ( st_info->benchmark > 2 )
        sf_running_timer (&timer, "\t\treshape wide step 2: transposed data");

    // printf("\n");
    // for (j = 0; j < J; j++) {
    //     selx = j * krow;
    //     printf("%ld: ", j);
    //     for (k = 0; k < kvars; k++) {
    //         z = outdbl[selx + k];
    //         if ( z < SV_missval ) {
    //             printf("\t%.3f", z);
    //         }
    //         else {
    //             printf("\t.");
    //         }
    //     }
    //     selx += kvars;
    //     for (l = 0; l < klevels; l++) {
    //         for (k = 0; k < kout; k++) {
    //             z = outdbl[selx + klevels * k + l];
    //             if ( z < SV_missval ) {
    //                 printf("\t%.3f", z);
    //             }
    //             else {
    //                 printf("\t.");
    //             }
    //         }
    //     }
    //     printf("\n");
    // }

    // printf("\n");
    // for (j = 0; j < J; j++) {
    //     selx = j * outbytes;
    //     printf("%ld: ", j);
    //     for (k = 0; k < kvars ; k++) {
    //         if ( st_info->byvars_lens[k] > 0) {
    //             printf("\t%s", outstr + selx + st_info->positions[k]);
    //         }
    //         else {
    //             z = *((ST_double *) (outstr + selx + st_info->positions[k]));
    //             printf("\t%.3f", z);
    //         }
    //     }
    //     for (l = 0; l < klevels; l++) {
    //         for (k = 0; k < kout; k++) {
    //             if ( outtyp[klevels * k + l] ) {
    //                 printf("\t%s", outstr + selx + outpos[klevels * k + l]);
    //             }
    //             else {
    //                 z = *((ST_double *) (outstr + selx + outpos[klevels * k + l]));
    //                 if ( z < SV_missval ) {
    //                     printf("\t%.3f", z);
    //                 }
    //                 else {
    //                     printf("\t.");
    //                 }
    //             }
    //         }
    //     }
    //     printf("\n");
    // }

    /*********************************************************************
     *                       Step 4: Copy to disk                        *
     *********************************************************************/

    if ( (rc = SF_scal_save ("__gtools_greshape_nrows", (ST_double) J))    ) goto exit;
    if ( (rc = SF_scal_save ("__gtools_greshape_ncols", (ST_double) krow)) ) goto exit;

    fhandle = fopen(fname, "wb");
    if ( st_info->greshape_anystr | st_info->kvars_by_str ) {
        fwrite (outstr, outbytes, J, fhandle);
    }
    else {
        fwrite (outdbl, sizeof(outdbl), J * krow, fhandle);
    }
    fclose (fhandle);

    if ( st_info->benchmark > 2 )
        sf_running_timer (&timer, "\t\treshape wide step 3: copied reshaped data to disk");

exit:
    free(bufdbl);
    free(bufstr);
    free(offset);
    free(outdbl);
    free(outpos);
    free(outstr);
    free(outtyp);

    free(index_st);
    free(jdbl);
    free(jstr);
    free(nj);

    return(rc);
}

/*********************************************************************
 *                           Reshape long                            *
 *********************************************************************/

ST_retcode sf_reshape_long (struct StataInfo *st_info, int level, char *fname)
{
    GT_bool debug = st_info->debug;
    if ( debug ) {
        sf_printf_debug("debug 1 (sf_reshape): Starting greshape.\n");
    }

    /*********************************************************************
     *                           Step 1: Setup                           *
     *********************************************************************/

    ST_retcode rc = 0;
    ST_double z;

    GT_size *ixptr;
    GT_size selx, i, j, k, l, m, rowbytes, outbytes;

    FILE *fhandle;
    char *strptr, *jstr, *outstr;
    ST_double *dblptr, *jdbl, *outdbl;

    GT_size kvars    = st_info->kvars_by;
    GT_size kout     = st_info->greshape_kout;
    GT_size kxij     = st_info->greshape_kxij;
    GT_size kxi      = st_info->greshape_kxi;
    GT_size klevels  = st_info->greshape_klvls;
    GT_size krow     = kvars + 1 + kout + kxi;
    GT_size Nread    = st_info->Nread;
    GT_size J        = st_info->J;
    GT_size jbytes   = st_info->greshape_str * sizeof(char);
    clock_t timer    = clock();

    if ( jbytes ) {
        jbytes += sizeof(char);
    }
    else {
        jbytes = sizeof(ST_double);
    }

    if ( debug ) {
        sf_printf_debug("\tkvars:   "GT_size_cfmt"\n",  kvars);
        sf_printf_debug("\tkout:    "GT_size_cfmt"\n",  kout);
        sf_printf_debug("\tkxij:    "GT_size_cfmt"\n",  kxij);
        sf_printf_debug("\tkxi:     "GT_size_cfmt"\n",  kxi);
        sf_printf_debug("\tklevels: "GT_size_cfmt"\n",  klevels);
        sf_printf_debug("\tkrow:    "GT_size_cfmt"\n",  krow);
        sf_printf_debug("\tNread:   "GT_size_cfmt"\n",  Nread);
        sf_printf_debug("\tJ:       "GT_size_cfmt"\n",  J);
    }

    // The variables passed to reshape long are of the form:
    //
    //     reshape long a b c .., i(i1 i2 ...)
    //
    //     i         i1 i2
    //     xij       a b c
    //     xij_names a1 a2 b10 b15 b20 c2 c15
    //     levels    1 2 10 15 20
    //
    //     maplevel  1 2 0 0 0
    //               0 0 3 4 5
    //               0 6 0 7 0
    //
    //     types, array of length 7 with 0 if the kth variable is
    //     numeric and the string length if the kth variable is string.
    //
    // The variables passed to the plugin are i and xij_names.

    char ReS_jfile[st_info->greshape_jfile];
    GT_size *outpos    = calloc(kout + 1, sizeof(outpos));
    GT_size *outtyp    = calloc(kout + 1, sizeof(outtyp));
    GT_size *index_st  = calloc(Nread, sizeof *index_st);
    GT_size *maplevel  = st_info->greshape_maplevel;

    if ( outpos   == NULL ) return(sf_oom_error("sf_reshape_long", "outpos"));
    if ( outtyp   == NULL ) return(sf_oom_error("sf_reshape_long", "outtyp"));
    if ( index_st == NULL ) return(sf_oom_error("sf_reshape_long", "index_st"));

    jstr = calloc(klevels, jbytes);
    if ( st_info->greshape_str ) {
        jdbl = calloc(1, sizeof(jdbl));
    }
    else {
        jdbl = calloc(klevels, sizeof jdbl);
    }

    outbytes = sf_reshape_bytes(st_info, outpos, outtyp);
    if ( st_info->greshape_anystr ) {
        outdbl = malloc(sizeof(ST_double));
        outstr = calloc(Nread * klevels, GTOOLS_PWMAX(outbytes, 1));
        memset(outstr, '\0', Nread * klevels * GTOOLS_PWMAX(outbytes, 1));
    }
    else {
        outstr = malloc(sizeof(char));
        outdbl = calloc(Nread * klevels * krow, sizeof outdbl);
    }

    if ( outdbl == NULL ) return(sf_oom_error("sf_reshape_long", "outdbl"));
    if ( outstr == NULL ) return(sf_oom_error("sf_reshape_long", "outstr"));

    if ( outbytes == 0 ) {
        rc = 198;
        goto exit;
    }

    /*********************************************************************
     *                      Step 2: Read in varlist                      *
     *********************************************************************/

    if ( debug ) {
        sf_printf_debug("debug 2 (sf_reshape): Index Stata order.\n");
    }

    if ( (rc = SF_macro_use("ReS_jfile", ReS_jfile, st_info->greshape_jfile) )) goto exit;
    fhandle = fopen(ReS_jfile, "rb");
    if ( st_info->greshape_str == 0 ) {
        rc = fread(jdbl, sizeof(jdbl), klevels, fhandle) != klevels;
    }
    fclose (fhandle);

    fhandle = fopen(ReS_jfile, "rb");
    rc = rc | (fread(jstr, jbytes, klevels, fhandle) != klevels);
    fclose (fhandle);

    if ( rc ) {
        sf_errprintf("unable to read in j levels\n");
        rc = 198;
        goto exit;
    }

    for (i = 0; i < Nread; i++)
        index_st[i] = 0;

    for (j = 0; j < J; j++) {
        l = st_info->ix[j];
        index_st[st_info->index[st_info->info[l]]] = l + 1;
    }

    if ( st_info->benchmark > 2 )
        sf_running_timer (&timer, "\t\treshape long step 1: Indexed in stata order");

    /*********************************************************************
     *                       Step 3: Reshape long                        *
     *********************************************************************/

    if ( debug ) {
        sf_printf_debug("debug 3 (sf_reshape): Reshape long\n");
    }

    rowbytes = (st_info->rowbytes + sizeof(GT_size));
    if ( st_info->greshape_anystr == 0 ) {
        i = 0;
        for (ixptr = index_st; ixptr < index_st + Nread; ixptr++, i++) {
            if ( *ixptr ) {
                // m is the level, in order, of st_by_numx
                m = st_info->info[*ixptr - 1];

                // dblptr is the row of the by variables
                dblptr = st_info->st_by_numx + m * (kvars + 1);
                for (j = 0; j < klevels; j++) {
                    // selx is the row in the output (long) vector
                    selx = m * krow * klevels + j * krow;

                    // copy a row of the by variables to the output vector
                    for (k = 0; k < kvars; k++) {
                        outdbl[selx + k] = dblptr[k];
                    }

                    // Copy the j variable value
                    outdbl[selx + kvars] = jdbl[j];

                    // Copy each of the xij variables
                    for (k = 0; k < kout; k++) {
                        if ( (l = maplevel[k * klevels + j]) > 0 ) {
                            if ( (rc = SF_vdata(l, i + st_info->in1, &z)) ) goto exit;
                            outdbl[selx + kvars + k + 1] = z;
                        }
                        else {
                            outdbl[selx + kvars + k + 1] = SV_missval;
                        }
                    }
                }
            }
        }
    }
    else {
        if ( st_info->kvars_by_str ) {
            i = 0;
            for (ixptr = index_st; ixptr < index_st + Nread; ixptr++, i++) {
                if ( *ixptr ) {
                    m = st_info->info[*ixptr - 1];
                    strptr = st_info->st_by_charx + m * rowbytes;

                    for (j = 0; j < klevels; j++) {
                        selx = m * klevels * outbytes + j * outbytes;
                        memcpy(
                            outstr + selx,
                            strptr,
                            outpos[0]
                        );

                        memcpy(
                            outstr + selx + outpos[0],
                            jstr + j * jbytes,
                            jbytes
                        );

                        for (k = 0; k < kout; k++) {
                            l = maplevel[k * klevels + j];
                            if ( outtyp[k + 1] && (l > 0) ) {
                                if ( (rc = SF_sdata(l,
                                                    i + st_info->in1,
                                                    outstr + selx + outpos[k + 1])) ) goto exit;
                            }
                            else {
                                if ( l > 0 ) {
                                    if ( (rc = SF_vdata(l, i + st_info->in1, &z)) ) goto exit;
                                }
                                else {
                                    z = SV_missval;
                                }
                                memcpy(
                                    outstr + selx + outpos[k + 1],
                                    &z,
                                    sizeof(ST_double)
                                );
                            }
                        }
                    }
                }
            }
        }
        else {
            i = 0;
            for (ixptr = index_st; ixptr < index_st + Nread; ixptr++, i++) {
                if ( *ixptr ) {
                    m = st_info->info[*ixptr - 1];
                    dblptr = st_info->st_by_numx + m * rowbytes;

                    for (j = 0; j < klevels; j++) {
                        selx = m * klevels * outbytes + j * outbytes;
                        memcpy(
                            outstr + selx,
                            dblptr,
                            outpos[0]
                        );

                        memcpy(
                            outstr + selx + outpos[0],
                            jstr + j * jbytes,
                            jbytes
                        );

                        for (k = 0; k < kout; k++) {
                            l = maplevel[k * klevels + j];
                            if ( outtyp[k + 1] && (l > 0) ) {
                                if ( (rc = SF_sdata(l,
                                                    i + st_info->in1,
                                                    outstr + selx + outpos[k + 1])) ) goto exit;
                            }
                            else {
                                if ( l > 0 ) {
                                    if ( (rc = SF_vdata(l, i + st_info->in1, &z)) ) goto exit;
                                }
                                else {
                                    z = SV_missval;
                                }
                                memcpy(
                                    outstr + selx + outpos[k + 1],
                                    &z,
                                    sizeof(ST_double)
                                );
                            }
                        }
                    }
                }
            }
        }
    }

    if ( st_info->benchmark > 2 )
        sf_running_timer (&timer, "\t\treshape long step 2: transposed data");

    /*********************************************************************
     *                       Step 4: Copy to disk                        *
     *********************************************************************/

    if ( (rc = SF_scal_save ("__gtools_greshape_nrows",
                             (ST_double) Nread * klevels)) ) goto exit;

    if ( (rc = SF_scal_save ("__gtools_greshape_ncols",
                             (ST_double) krow)) ) goto exit;

    fhandle = fopen(fname, "wb");
    if ( st_info->greshape_anystr ) {
        fwrite (outstr, outbytes, Nread * klevels, fhandle);
    }
    else {
        fwrite (outdbl, sizeof(outdbl), Nread * klevels * krow, fhandle);
    }
    fclose (fhandle);

    if ( st_info->benchmark > 2 )
        sf_running_timer (&timer, "\t\treshape long step 3: copied reshaped data to disk");

exit:
    free(index_st);
    free(outpos);
    free(outtyp);
    free(outstr);
    free(outdbl);
    free(jstr);
    free(jdbl);

    return (rc);
}

/*********************************************************************
 *                           Reshape read                            *
 *********************************************************************/

ST_retcode sf_reshape_read (struct StataInfo *st_info, int level, char *fname)
{
    GT_bool debug = st_info->debug;
    if ( debug ) {
        sf_printf_debug("debug 3 (sf_reshape): Reading back reshaped data.\n");
    }

    /*********************************************************************
     *                           Step 1: Setup                           *
     *********************************************************************/

    ST_retcode rc = 0;
    ST_double z;
    GT_size i, k;
    ST_double *outdbl;
    char *outstr, *outptr;

    GT_size kvars = st_info->kvars_by;
    GT_size kout  = st_info->greshape_kout;
    GT_size kxij  = st_info->greshape_kxij;
    GT_size kxi   = st_info->greshape_kxi;
    GT_size code  = st_info->greshape_code;
    GT_size kread = (code == 1)? kout + 1: kxij;
    GT_size krow  = kvars + kread + kxi;
    GT_size N     = st_info->N;
    clock_t timer = clock();

    if ( debug ) {
        sf_printf_debug("\tkvars: "GT_size_cfmt"\n", kvars);
        sf_printf_debug("\tkout:  "GT_size_cfmt"\n", kout);
        sf_printf_debug("\tkread: "GT_size_cfmt"\n", kread);
        sf_printf_debug("\tkxi:   "GT_size_cfmt"\n", kxi);
        sf_printf_debug("\tkrow:  "GT_size_cfmt"\n", krow);
        sf_printf_debug("\tN:     "GT_size_cfmt"\n", N);
    }

    GT_size *allpos  = calloc(krow,  sizeof(allpos));
    GT_size *alltyp  = calloc(krow,  sizeof(alltyp));
    GT_size *outpos  = calloc(kread, sizeof(outpos));
    GT_size *outtyp  = calloc(kread, sizeof(outtyp));
    GT_size outbytes = sf_reshape_bytes(st_info, outpos, outtyp);

    for (k = 0; k < kvars; k++) {
        allpos[k] = st_info->positions[k];
        alltyp[k] = (st_info->byvars_lens[k] > 0)? st_info->byvars_lens[k]: 0;
    }
    for (k = 0; k < kread; k++) {
        allpos[kvars + k] = outpos[k];
        alltyp[kvars + k] = outtyp[k];
    }

    if ( st_info->greshape_anystr | st_info->kvars_by_str ) {
        outdbl = malloc(sizeof(ST_double));
        outstr = calloc(N, GTOOLS_PWMAX(outbytes, 1));
        memset (outstr, '\0', N * GTOOLS_PWMAX(outbytes, 1));
    }
    else {
        outstr = malloc(sizeof(char));
        outdbl = calloc(N * krow, sizeof outdbl);
    }

    if ( outdbl == NULL ) return(sf_oom_error("sf_reshape_read", "outdbl"));
    if ( outstr == NULL ) return(sf_oom_error("sf_reshape_read", "outstr"));

    if ( outbytes == 0 ) {
        rc = 198;
        goto exit;
    }

    FILE *fhandle = fopen(fname, "rb");
    if ( st_info->greshape_anystr | st_info->kvars_by_str ) {
        if ( fread(outstr, outbytes, N, fhandle) != N ) {
            rc = 198;
            goto exit;
        }
    }
    else {
        if ( fread(outdbl, sizeof(outdbl), krow * N, fhandle) != (krow * N) ) {
            rc = 198;
            goto exit;
        }
    }
    fclose(fhandle);

    if ( st_info->benchmark > 2 )
        sf_running_timer (&timer, "\treshape long step 5: copied reshaped data back to mem");

    /*********************************************************************
     *                      Step 2: Read in varlist                      *
     *********************************************************************/

    if ( st_info->greshape_anystr | st_info->kvars_by_str ) {
        outptr = outstr;
        for (i = 0; i < N; i++) {
            for (k = 0; k < krow; k++) {
                if ( alltyp[k] ) {
                    if ( (rc = SF_sstore(k + 1, i + 1, outptr + allpos[k])) ) goto exit;
                }
                else {
                    z = *((ST_double *) (outptr + allpos[k]));
                    if ( (rc = SF_vstore(k + 1, i + 1, z)) ) goto exit;
                }
            }
            outptr += outbytes;
        }
    }
    else {
        for (i = 0; i < N; i++) {
            for (k = 0; k < krow; k++) {
                if ( (rc = SF_vstore(k + 1, i + 1, outdbl[i * krow + k])) ) goto exit;
            }
        }
    }

    if ( st_info->benchmark > 2 )
        sf_running_timer (&timer, "\treshape long step 6: copied reshaped data to stata");


exit:
    free(outpos);
    free(outtyp);
    free(outdbl);
    free(outstr);
    free(allpos);
    free(alltyp);

    return(rc);
}

/*********************************************************************
 *                             Aux stuff                             *
 *********************************************************************/

GT_size sf_reshape_bytes(struct StataInfo *st_info, GT_size *outpos, GT_size *outtyp)
{
    GT_size i, j, k, l, m, outbytes = 0;
    GT_size kvars   = st_info->kvars_by;
    GT_size kout    = st_info->greshape_kout;
    GT_size kxij    = st_info->greshape_kxij;
    GT_size klevels = st_info->greshape_klvls;

    if ( st_info->greshape_code == 1 ) {
        // First, we set up the position of the elements of the output
        // array. Setting them up is cheap so we always do it, but we will
        // only use outpos if the output array has any string variables. For
        // example,
        //
        //     name   | i1      | i2      | j       | a        |
        //     type   | numeric | string7 | numeric | string32 |
        //     length | 8 bytes | 7 bytes | 8 bytes | 32 bytes |
        //
        // If any set of variables, i, j, or xij, is not entirely numeric,
        // then we set up outpos to contain its position in the output array.

        outtyp[0] = st_info->greshape_str;
        outpos[0] = outbytes = st_info->rowbytes;
        if ( st_info->greshape_str ) {
            outbytes += st_info->greshape_str + sizeof(char);
            outpos[1] = outbytes;
        }
        else {
            outbytes += sizeof(ST_double);
            outpos[1] = outbytes;
        }

        // The vector types contains the string length for character
        // variables or 0 for numeric variables. Since the output vector
        // only contains kout long variables instead of kxij input
        // variables, we look through maplevel to obtain the correct column
        // length of the xij variables in the output vector.

        for (i = 0; i < kout; i++) {
            m = 0;
            for (j = 0; j < klevels; j++) {
                if ( (k = st_info->greshape_maplevel[klevels * i + j]) ) {
                    if ( (l = st_info->greshape_types[k - kvars - 1]) ) {
                        m = GTOOLS_PWMAX(l, m);
                    }
                }
            }
            if ( m ) {
                m++;
                m *= sizeof(char);
                outtyp[i + 1] = m;
            }
            else {
                m = sizeof(ST_double);
                outtyp[i + 1] = 0;
            }
            if ( i < (kout - 1) ) {
                outpos[2 + i] = outpos[2 + i -1] + m;
            }
            outbytes += m;
        }

        // Now we check if either i, j, or xij contain strings, and allocate
        // the output vector accordingly.

        if ( (st_info->kvars_by_str) | (st_info->greshape_str) ) {
            st_info->greshape_anystr = 1;
        }
        for (i = 0; i < kxij; i++) {
            if ( st_info->greshape_types[i] ) {
                st_info->greshape_anystr = 1;
            }
        }
    }
    else if ( st_info->greshape_code == 2 )  {

        // Boradly this follows the steps above, but for a wide output
        // array. Notably, j is not in the wide array

        k = 0;
        outpos[0] = outbytes = st_info->rowbytes;
        for (i = 0; i < kout; i++) {
            if ( (m = st_info->greshape_types[i]) ) {
                l = (m + 1) * sizeof(char);
                st_info->greshape_anystr = 1;
            }
            else {
                l = sizeof(ST_double);
            }
            for (j = 0; j < klevels; j++) {
                outbytes += l;
                outtyp[klevels * i + j] = m;
                if ( ++k < kxij ) {
                    outpos[klevels * i + j + 1] = outpos[klevels * i + j] + l;
                }
            }
        }
    }
    else {
        sf_errprintf("Unknown greshape command");
    }

    return (outbytes);
}
