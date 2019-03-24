ST_retcode sf_reshape_fast  (struct StataInfo *st_info, int level, char *fname);
ST_retcode sf_reshape_flong (struct StataInfo *st_info, int level, char *fname);

ST_retcode sf_reshape_fast (struct StataInfo *st_info, int level, char *fname)
{
    if ( st_info->greshape_code == 1 ) {
        return (sf_reshape_flong(st_info, level, fname));
    }
    else if ( st_info->greshape_code == 2 )  {
        sf_errprintf("direct reshape wide not available\n");
        return (198);
    }
    else {
        return (198);
    }
}

ST_retcode sf_reshape_flong (struct StataInfo *st_info, int level, char *fname)
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

    GT_size selx, i, j, k, l, outbytes, xibytes;

    FILE *fhandle;
    char *jstr, *outstr, *xistr;
    ST_double *jdbl, *outdbl, *xidbl;

    GT_size kvars    = st_info->kvars_by;
    GT_size kout     = st_info->greshape_kout;
    GT_size kxij     = st_info->greshape_kxij;
    GT_size kxi      = st_info->greshape_kxi;
    GT_size klevels  = st_info->greshape_klvls;
    GT_size krow     = kvars + 1 + kout + kxi;
    GT_size N        = st_info->N;
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
        sf_printf_debug("\tN:       "GT_size_cfmt"\n",  N);
        sf_printf_debug("\tJ:       "GT_size_cfmt"\n",  J);
    }

    // The variables passed to reshape long are of the form:
    //
    //     reshape long a b c .., i(i1 i2 ...)
    //
    //     i         i1 i2
    //     xij       a b c
    //     xij_names a1 a2 b10 b15 b20 c2 c15
    //     xi        other variables in memory
    //     levels    1 2 10 15 20
    //
    //     maplevel  1 2 0 0 0
    //               0 0 3 4 5
    //               0 6 0 7 0
    //
    //     types, array of length 7 with 0 if the kth variable is
    //     numeric and the string length if the kth variable is string.
    //
    // The variables passed to the plugin are i, xij_names, and xi.

    char ReS_jfile[st_info->greshape_jfile];

    char      *bufstr   = malloc(st_info->rowbytes);
    ST_double *bufdbl   = calloc(kvars, sizeof *bufdbl);
    GT_size   *xipos    = calloc(GTOOLS_PWMAX(kxi, 1), sizeof *xipos);
    GT_size   *outpos   = calloc(kout + kxi + 1, sizeof *outpos);
    GT_size   *outtyp   = calloc(kout + kxi + 1, sizeof *outtyp);
    GT_size   *maplevel = st_info->greshape_maplevel;

    if ( xipos  == NULL ) return(sf_oom_error("sf_reshape_flong", "xipos"));
    if ( bufstr == NULL ) return(sf_oom_error("sf_reshape_flong", "bufstr"));
    if ( outpos == NULL ) return(sf_oom_error("sf_reshape_flong", "outpos"));
    if ( outtyp == NULL ) return(sf_oom_error("sf_reshape_flong", "outtyp"));

    jstr = calloc(klevels, jbytes);
    if ( st_info->greshape_str ) {
        jdbl = calloc(1, sizeof *jdbl);
    }
    else {
        jdbl = calloc(klevels, sizeof *jdbl);
    }

    outbytes = sf_reshape_bytes(st_info, outpos, outtyp);
    if ( st_info->greshape_anystr ) {
        outdbl = malloc(sizeof(ST_double));
        outstr = calloc(N * klevels, GTOOLS_PWMAX(outbytes, 1));
        memset(outstr, '\0', N * klevels * GTOOLS_PWMAX(outbytes, 1));
    }
    else {
        outstr = malloc(sizeof(char));
        outdbl = calloc(N * klevels * krow, sizeof *outdbl);
    }

    xipos[0] = xibytes = 0;
    for (k = 0; k < kxi; k++) {
        if ( (l = st_info->greshape_xitypes[k]) ) {
            xibytes += ((l + 1) * sizeof(char));
        }
        else {
            xibytes += sizeof(ST_double);
        }
        if ( k < kxi - 1 ) {
            xipos[k + 1] = xibytes;
        }
    }

    xibytes = GTOOLS_PWMAX(xibytes, 1);
    xistr   = calloc(1, xibytes);
    xidbl   = calloc(GTOOLS_PWMAX(kxi, 1), sizeof *xidbl);
    memset(xistr, '\0', xibytes);

    if ( outdbl == NULL ) return(sf_oom_error("sf_reshape_flong", "outdbl"));
    if ( outstr == NULL ) return(sf_oom_error("sf_reshape_flong", "outstr"));
    if ( xistr  == NULL ) return(sf_oom_error("sf_reshape_flong", "xistr"));
    if ( xidbl  == NULL ) return(sf_oom_error("sf_reshape_flong", "xidbl"));

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
        rc = fread(jdbl, sizeof *jdbl, klevels, fhandle) != klevels;
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

    if ( st_info->benchmark > 2 )
        sf_running_timer (&timer, "\treshape long step 1: allocated memory");

    /*********************************************************************
     *                       Step 3: Reshape long                        *
     *********************************************************************/

    if ( debug ) {
        sf_printf_debug("debug 3 (sf_reshape): Reshape long\n");
    }

    if ( st_info->greshape_anystr == 0 ) {
        for (i = 0; i < N; i++) {
            // bufdbl is the row of the by variables
            for (k = 0; k < kvars; k++) {
                if ( (rc = SF_vdata(k + 1, i + st_info->in1, bufdbl + k)) ) goto exit;
            }

            // Copy each of the xi variables
            for (k = 0; k < kxi; k++) {
                if ( (rc = SF_vdata(kvars + k + 1,
                                    i + st_info->in1,
                                    xidbl + k)) ) goto exit;
            }

            for (j = 0; j < klevels; j++) {
                // selx is the row in the output (long) vector
                selx = i * krow * klevels + j * krow;

                // copy a row of the by variables to the output vector
                for (k = 0; k < kvars; k++) {
                    outdbl[selx + k] = bufdbl[k];
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

                // Copy each of the xi variables
                if ( kxi ) {
                    memcpy(
                        outdbl + selx + kvars + kout + 1,
                        xidbl,
                        kxi * sizeof(ST_double)
                    );
                }
            }
        }
    }
    else {
        if ( st_info->kvars_by_str ) {
            for (i = 0; i < N; i++) {
                memset(bufstr, '\0', st_info->rowbytes);
                for (k = 0; k < kvars; k++) {
                    if ( st_info->byvars_lens[k] > 0 ) {
                        if ( (rc = SF_sdata(k + 1,
                                            i + st_info->in1,
                                            bufstr + st_info->positions[k])) ) goto exit;
                    }
                    else {
                        if ( (rc = SF_vdata(k + 1,
                                            i + st_info->in1,
                                            &z)) ) goto exit;
                        memcpy(bufstr + st_info->positions[k], &z, sizeof(ST_double));
                    }
                }

                memset(xistr, '\0', xibytes);
                for (k = 0; k < kxi; k++) {
                    if ( st_info->greshape_xitypes[k] ) {
                        if ( (rc = SF_sdata(kvars + k + 1,
                                            i + st_info->in1,
                                            xistr + xipos[k])) ) goto exit;
                    }
                    else {
                        if ( (rc = SF_vdata(kvars + k + 1,
                                            i + st_info->in1,
                                            &z)) ) goto exit;
                        memcpy(xistr + xipos[k], &z, sizeof(ST_double));
                    }
                }

                for (j = 0; j < klevels; j++) {
                    selx = i * klevels * outbytes + j * outbytes;
                    memcpy(
                        outstr + selx,
                        bufstr,
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

                    if ( kxi ) {
                        memcpy(
                            outstr + selx + outpos[kout + 1],
                            xistr,
                            xibytes
                        );
                    }
                }
            }
        }
        else {
            for (i = 0; i < N; i++) {
                for (k = 0; k < kvars; k++) {
                    if ( (rc = SF_vdata(k + 1, i + st_info->in1, bufdbl + k)) ) goto exit;
                }

                memset(xistr, '\0', xibytes);
                for (k = 0; k < kxi; k++) {
                    if ( st_info->greshape_xitypes[k] ) {
                        if ( (rc = SF_sdata(kvars + k + 1,
                                            i + st_info->in1,
                                            xistr + xipos[k])) ) goto exit;
                    }
                    else {
                        if ( (rc = SF_vdata(kvars + k + 1,
                                            i + st_info->in1,
                                            &z)) ) goto exit;
                        memcpy(xistr + xipos[k], &z, sizeof(ST_double));
                    }
                }

                for (j = 0; j < klevels; j++) {
                    selx = i * klevels * outbytes + j * outbytes;
                    memcpy(
                        outstr + selx,
                        bufdbl,
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

                    if ( kxi ) {
                        memcpy(
                            outstr + selx + outpos[kout + 1],
                            xistr,
                            xibytes
                        );
                    }
                }
            }
        }
    }

    /* //
    if ( st_info->greshape_anystr == 0 ) {
        printf("\n");
        for (i = 0; i < Nread; i++) {
            for (j = 0; j < klevels; j++) {
                selx = i * klevels + j;
                printf("(%ld, %ld): ", i, j);
                for (k = 0; k < kvars ; k++) {
                    z = outdbl[selx + k];
                    if ( z < SV_missval ) {
                        printf("\t%.3f", z);
                    }
                    else {
                        printf("\t.");
                    }
                }
                for (k = 0; k < kout; k++) {
                    l = maplevel[k * klevels + j];
                    printf("\t(%ld, %ld, %ld)", outtyp[k + 1], l, outpos[k + 1]);
                    z = outdbl[selx + kvars + k + 1];
                    if ( z < SV_missval ) {
                        printf("\t%.3f", z);
                    }
                    else {
                        printf("\t.");
                    }
                }
                for (k = 0; k < kxi; k++) {
                    z = outdbl[selx + kvars + kout + k + 1];
                    if ( z < SV_missval ) {
                        printf("\t%.3f", z);
                    }
                    else {
                        printf("\t.");
                    }
                }
                printf("\n");
            }
        }
    }
    else {
        printf("\n");
        for (i = 0; i < Nread; i++) {
            for (j = 0; j < klevels; j++) {
                selx = i * klevels * outbytes + j * outbytes;
                printf("(%ld, %ld): ", i, j);
                for (k = 0; k < kvars ; k++) {
                    if ( st_info->byvars_lens[k] > 0) {
                        printf("\t%s", outstr + selx + st_info->positions[k]);
                    }
                    else {
                        z = *((ST_double *) (outstr + selx + st_info->positions[k]));
                        if ( z < SV_missval ) {
                            printf("\t%.3f", z);
                        }
                        else {
                            printf("\t.");
                        }
                    }
                }
                for (k = 0; k < kout; k++) {
                    l = maplevel[k * klevels + j];
                        printf("\t(%ld, %ld, %ld)", outtyp[k + 1], l, outpos[k + 1]);
                    if ( outtyp[k + 1] && (l > 0) ) {
                        printf("\t%s", outstr + selx + outpos[k + 1]);
                    }
                    else {
                        z = *((ST_double *) (outstr + selx + outpos[k + 1]));
                        if ( z < SV_missval ) {
                            printf("\t%.3f", z);
                        }
                        else {
                            printf("\t.");
                        }
                    }
                }
                for (k = 0; k < kxi; k++) {
                    if ( xitypes[k] ) {
                        printf("\t%s", outstr + selx + outpos[kout + 1 + k]);
                    }
                    else {
                        z = *((ST_double *) (outstr + selx + outpos[kout + 1 + k]));
                        if ( z < SV_missval ) {
                            printf("\t%.3f", z);
                        }
                        else {
                            printf("\t.");
                        }
                    }
                }
                printf("\n");
            }
        }
    }
    // */

    if ( st_info->benchmark > 2 )
        sf_running_timer (&timer, "\treshape long step 2: transposed data");

    /*********************************************************************
     *                       Step 4: Copy to disk                        *
     *********************************************************************/

    if ( (rc = SF_scal_save ("__gtools_greshape_nrows",
                             (ST_double) N * klevels)) ) goto exit;

    if ( (rc = SF_scal_save ("__gtools_greshape_ncols",
                             (ST_double) krow)) ) goto exit;

    fhandle = fopen(fname, "wb");
    if ( st_info->greshape_anystr ) {
        rc = (fwrite(outstr, outbytes, N * klevels, fhandle) != (N * klevels));
    }
    else {
        rc = (fwrite(outdbl, sizeof *outdbl, N * klevels * krow, fhandle) != (N * klevels * krow));
    }
    fclose (fhandle);

    if ( rc ) {
        sf_errprintf("unable to write output to disk\n");
        rc = 198;
        goto exit;
    }

    if ( st_info->benchmark > 2 )
        sf_running_timer (&timer, "\treshape long step 3: copied reshaped data to disk");

exit:
    free(outpos);
    free(outtyp);
    free(outstr);
    free(outdbl);
    free(bufstr);
    free(bufdbl);
    free(xipos);
    free(xistr);
    free(xidbl);
    free(jstr);
    free(jdbl);

    return (rc);
}
