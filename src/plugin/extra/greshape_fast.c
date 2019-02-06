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

    GT_size selx, i, j, k, l, outbytes;

    FILE *fhandle;
    char *jstr, *outstr;
    ST_double *jdbl, *outdbl;

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

    char      *bufstr   = malloc(st_info->rowbytes);
    ST_double *bufdbl   = calloc(kvars, sizeof bufdbl);
    GT_size   *outpos   = calloc(kout + 1, sizeof(outpos));
    GT_size   *outtyp   = calloc(kout + 1, sizeof(outtyp));
    GT_size   *maplevel = st_info->greshape_maplevel;

    if ( bufstr == NULL ) return(sf_oom_error("sf_reshape_flong", "bufstr"));
    if ( outpos == NULL ) return(sf_oom_error("sf_reshape_flong", "outpos"));
    if ( outtyp == NULL ) return(sf_oom_error("sf_reshape_flong", "outtyp"));

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
        outstr = calloc(N * klevels, GTOOLS_PWMAX(outbytes, 1));
        memset(outstr, '\0', N * klevels * GTOOLS_PWMAX(outbytes, 1));
    }
    else {
        outstr = malloc(sizeof(char));
        outdbl = calloc(N * klevels * krow, sizeof outdbl);
    }

    if ( outdbl == NULL ) return(sf_oom_error("sf_reshape_flong", "outdbl"));
    if ( outstr == NULL ) return(sf_oom_error("sf_reshape_flong", "outstr"));

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
                }
            }
        }
        else {
            for (i = 0; i < N; i++) {
                for (k = 0; k < kvars; k++) {
                    if ( (rc = SF_vdata(k + 1, i + st_info->in1, bufdbl + k)) ) goto exit;
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
                }
            }
        }
    }

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
        rc = (fwrite(outdbl, sizeof(outdbl), N * klevels * krow, fhandle) != (N * klevels * krow));
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
    free(jstr);
    free(jdbl);

    return (rc);
}
