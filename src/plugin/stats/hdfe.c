ST_retcode sf_stats_hdfe (struct StataInfo *st_info, int level)
{
    FILE *fghdfeabs;
    char GTOOLS_GHDFEABS_FILE[st_info->gfile_ghdfeabs];
    GT_size j, k, offset, nonmiss, methodk, *njptr;
    ST_double *xptr, *wptr;
    ST_retcode rc = 0;

printf("debug15\n");
    GT_size   N         = st_info->N;
    GT_size   J         = st_info->J;
    GT_size   nj_max    = st_info->nj_max;
    GT_bool   debug     = st_info->debug;
    GT_bool   method    = st_info->hdfe_method;
    ST_double hdfetol   = st_info->hdfe_hdfetol;
    GT_size   maxiter   = st_info->hdfe_maxiter;
    GT_size   traceiter = st_info->hdfe_traceiter;
    GT_size   kabs      = st_info->hdfe_absorb;
    GT_size   kx        = st_info->hdfe_kvars;
    GT_size   bytesabs  = st_info->hdfe_absorb_bytes;
    GT_size   *absoff   = st_info->hdfe_absorb_offsets;
    GT_int    *abstyp   = st_info->hdfe_absorb_types;

printf("debug16\n");
    switch ( method ) {
        case 5:
            methodk = nj_max * kx * 5; break;
        case 4:
            methodk = nj_max * kx * 4; break;
        case 3:
            methodk = nj_max * kx * 3; break;
        case 2:
            methodk = nj_max * kx * 4; break;
        default:
            methodk = 1; break;
    }

printf("debug17\n");
    if ( debug ) {
        sf_printf_debug("debug 1 (sf_stats_hdfe): Starting gstats hdfe.\n");
    }

    clock_t timer = clock();

    GtoolsGroupByTransform SaveGtoolsGroupByTransform;
    GtoolsGroupByHDFE SaveGtoolsGroupByHDFE;

    struct GtoolsHash *ghptr;
    struct GtoolsHash *AbsorbHashes = calloc(kabs, sizeof *AbsorbHashes);

printf("debug18\n");
    if ( st_info->wcode > 0 ) {
        SaveGtoolsGroupByTransform = GtoolsGroupByTransformWeighted;
        switch ( method ) {
            case 5:
                SaveGtoolsGroupByHDFE = GtoolsGroupByIronsTuckWeighted; break;
            case 4:
                SaveGtoolsGroupByHDFE = GtoolsGroupByCGWeighted; break;
            case 3:
                SaveGtoolsGroupByHDFE = GtoolsGroupByCGWeighted; break;
            case 2:
                SaveGtoolsGroupByHDFE = GtoolsGroupBySQUAREMWeighted; break;
            default:
                SaveGtoolsGroupByHDFE = GtoolsGroupByHDFEWeighted;
        }
    }
    else {
        SaveGtoolsGroupByTransform = GtoolsGroupByTransformUnweighted;
        switch ( method ) {
            case 5:
                SaveGtoolsGroupByHDFE = GtoolsGroupByIronsTuckUnweighted; break;
            case 4:
                SaveGtoolsGroupByHDFE = GtoolsGroupByCGUnweighted; break;
            case 3:
                SaveGtoolsGroupByHDFE = GtoolsGroupByCGUnweighted; break;
            case 2:
                SaveGtoolsGroupByHDFE = GtoolsGroupBySQUAREMUnweighted; break;
            default:
                SaveGtoolsGroupByHDFE = GtoolsGroupByHDFEUnweighted;
        }
    }

    ST_double *X        = calloc(N * kx,         sizeof *X);
    GT_size   *index_st = calloc(st_info->Nread, sizeof *index_st);
    GT_size   *nj       = calloc(J * (kabs + 1), sizeof *nj);
    GT_bool   *absinv   = calloc(kabs,           sizeof *absinv);
    ST_double *njabs    = calloc(J * (kabs + 1), sizeof *njabs);
    GT_size   *maps     = calloc(kx,             sizeof *maps);
    ST_double *stats    = calloc(kx,             sizeof *stats);
    ST_double *sqm_buff = calloc(methodk,        sizeof *sqm_buff);
    ST_double *w        = calloc(st_info->wcode > 0? N: 1, sizeof *w);
    void      *FE       = calloc(N, bytesabs);

printf("debug19\n");
    if ( X        == NULL ) return(sf_oom_error("sf_stats_hdfe", "X"));
    if ( index_st == NULL ) return(sf_oom_error("sf_stats_hdfe", "index_st"));
    if ( nj       == NULL ) return(sf_oom_error("sf_stats_hdfe", "nj"));
    if ( absinv   == NULL ) return(sf_oom_error("sf_stats_hdfe", "absinv"));
    if ( njabs    == NULL ) return(sf_oom_error("sf_stats_hdfe", "njabs"));
    if ( stats    == NULL ) return(sf_oom_error("sf_stats_hdfe", "stats"));
    if ( maps     == NULL ) return(sf_oom_error("sf_stats_hdfe", "maps"));
    if ( sqm_buff == NULL ) return(sf_oom_error("sf_stats_hdfe", "sqm_buff"));
    if ( w        == NULL ) return(sf_oom_error("sf_stats_hdfe", "w"));
    if ( FE       == NULL ) return(sf_oom_error("sf_stats_hdfe", "FE"));

    // 1. Read
    // -------

printf("debug20\n");
    njptr  = nj + J;
    for (j = 0; j < J; j++) {
        nj[j] = 0;
        njptr[j * kabs] = st_info->info[j + 1] - st_info->info[j];
    }

    memset(FE, '\0', N * bytesabs);
    for (k = 0; k < kx; k++) {
        stats[k] = -2;
        maps[k]  = k;
    }

    sf_stats_hdfe_index(st_info, index_st);

printf("debug21\n");
    if ( (rc = sf_stats_hdfe_read (st_info, X, w, FE, nj, index_st)) ) goto exit;

    if ( st_info->benchmark > 1 )
        sf_running_timer (&timer, "\thdfe step 1: Copied variables from Stata");

    // 2. Absorb
    // ---------

printf("debug22\n");
    offset = 0;
    ghptr  = AbsorbHashes;
    for (k = 0; k < kabs; k++, ghptr++) {
        absinv[k] = 0;
        GtoolsHashInit(ghptr, FE + offset, N, 1, abstyp + k, absinv + k);
        if ( (rc = GtoolsHashSetup(ghptr)) ) {
            if ( rc == 17902 ) {
                return (sf_oom_error("sf_stats_hdfe", "AbsorbHashes"));
            }
            else {
                goto exit;
            }
        }
        offset += N * absoff[k];
    }
    AbsorbHashes->hdfeBuffer    = sqm_buff;
    AbsorbHashes->hdfeMaxIter   = maxiter;
    AbsorbHashes->hdfeTraceIter = traceiter;
    AbsorbHashes->hdfeFallback  = (method == 4);

    if ( st_info->benchmark > 1 )
        sf_running_timer (&timer, "\thdfe step 2: Initialized absorb variables");

printf("debug23\n");
    // 3. Transform
    // ------------

printf("debug24\n");
    xptr = X; wptr = w;
    if ( (rc = sf_stats_hdfe_absorb(
                    AbsorbHashes,
                    SaveGtoolsGroupByTransform,
                    SaveGtoolsGroupByHDFE,
                    stats,
                    maps,
                    J,
                    kabs,
                    kx,
                    nj,
                    njptr,
                    xptr,
                    wptr,
                    hdfetol)) ) {
        goto exit;
    }

printf("debug25\n");
    if ( st_info->benchmark > 1 ) {
        switch ( method ) {
            case 5:
                sf_running_timer (&timer, "\thdfe step 3: Applied transform (Irons and Tuck)"); break;
            case 4:
                sf_running_timer (&timer, "\thdfe step 3: Applied transform (Hybrid)"); break;
            case 3:
                sf_running_timer (&timer, "\thdfe step 3: Applied transform (Conjugate Gradient)"); break;
            case 2:
                sf_running_timer (&timer, "\thdfe step 3: Applied transform (SQUAREM)"); break;
            default:
                sf_running_timer (&timer, "\thdfe step 3: Applied transform (MAP)");
        }
    }

    // 4. Save in Stata
    // ----------------

    if ( st_info->kvars_by && st_info->hdfe_matasave ) {
        if ( (rc = SF_macro_use("GTOOLS_GHDFEABS_FILE", GTOOLS_GHDFEABS_FILE, st_info->gfile_ghdfeabs) )) goto exit;

        for (j = 0; j < J * (kabs + 1); j++) {
            njabs[j] = (ST_double) nj[j];
        }

        fghdfeabs = fopen(GTOOLS_GHDFEABS_FILE, "wb");
        rc = (fwrite(njabs, sizeof(njabs), J * (kabs + 1), fghdfeabs) != (J * (kabs + 1)));
        fclose(fghdfeabs);

        if ( rc ) {
            goto exit;
        }

        if ( (rc = sf_byx_save_top (st_info, 0, NULL)) ) goto exit;
    }
    else if ( st_info->kvars_by == 0 ) {
        for (j = 0; j < J * (kabs + 1); j++) {
            njabs[j] = (ST_double) nj[j];
        }

        for (k = 0; k < kabs; k++) {
            if ( (rc = SF_mat_store("__gtools_hdfe_nabsorb", 1, k + 1, njabs[k + 1]) )) goto exit;
        }

        if ( kabs > 1 ) {
            if ( (rc = SF_scal_save("__gtools_hdfe_iter",  (ST_double) AbsorbHashes->hdfeIter)  )) goto exit;
            if ( (rc = SF_scal_save("__gtools_hdfe_feval", (ST_double) AbsorbHashes->hdfeFeval) )) goto exit;
        }
    }

    nonmiss = 0;
    for (j = 0; j < st_info->J; j++) {
        nonmiss += nj[j];
        nj[j] = 0;
    }
    if ( (rc = SF_scal_save("__gtools_hdfe_nonmiss", nonmiss)) ) goto exit;

    if ( (rc = sf_stats_hdfe_write (st_info, X, nj, index_st)) ) goto exit;

    if ( st_info->benchmark > 1 )
        sf_running_timer (&timer, "\thdfe step 4: Saved to Stata");

    // 5. Exit
    // -------

exit:

    for (k = 0; k < kabs; k++) {
        GtoolsHashFree(AbsorbHashes + k);
    }
    free (AbsorbHashes);

    free(X);
    free(index_st);
    free(nj);
    free(njabs);
    free(absinv);
    free(stats);
    free(maps);
    free(w);
    free(sqm_buff);
    free(FE);

    return(rc);
}

/**********************************************************************
 *                              Helpers                               *
 **********************************************************************/

void sf_stats_hdfe_index (
    struct StataInfo *st_info,
    GT_size *index_st)
{
    GT_size i, j, l, start, end;
    for (i = 0; i < st_info->Nread; i++)
        index_st[i] = 0;

    for (j = 0; j < st_info->J; j++) {
        l     = st_info->ix[j];
        start = st_info->info[l];
        end   = st_info->info[l + 1];
        for (i = start; i < end; i++) {
            index_st[st_info->index[i]] = l + 1;
        }
    }
}

ST_retcode sf_stats_hdfe_read (
    struct StataInfo *st_info,
    ST_double *X,
    ST_double *w,
    void      *FE,
    GT_size   *nj,
    GT_size   *index_st)
{

    ST_retcode rc = 0;
    GT_size i, j, k, start, end, nobs, offset_buffer, *stptr;

    GT_size kref      = 0;
    GT_size kabs      = st_info->hdfe_absorb;
    GT_int  *abstyp   = st_info->hdfe_absorb_types;
    GT_size *absoff   = st_info->hdfe_absorb_offsets;
    GT_size kx        = st_info->hdfe_kvars;

    // Read Stata in order and place into C in column major order.  Missing
    // values (for variables _and_ absorb) are dropped from Stata.

    i = 0;
    for (stptr = index_st; stptr < index_st + st_info->Nread; stptr++, i++) {
        if ( *stptr ) {
            j     = *stptr - 1;
            start = st_info->info[j];
            end   = st_info->info[j + 1];
            nobs  = end - start;
            kref  = st_info->kvars_by + 1;

            offset_buffer = start * kx;
            for (k = 0; k < kx; k++) {
                if ( (rc = SF_vdata(kref + k,
                                    i + st_info->in1,
                                    X + offset_buffer + nj[j])) ) goto exit;
                offset_buffer += nobs;
            }

            kref += 2 * kx;
            offset_buffer = 0;
            for (k = 0; k < kabs; k++) {
                offset_buffer += (start + nj[j]) * absoff[k];
                if ( abstyp[k] > 0 ) {
                    if ( (rc = SF_sdata(kref + k,
                                        i + st_info->in1,
                                        (char *) (FE + offset_buffer))) ) goto exit;
                }
                else {
                    if ( (rc = SF_vdata(kref + k,
                                        i + st_info->in1,
                                        (ST_double *) (FE + offset_buffer))) ) goto exit;
                }
                offset_buffer += (st_info->N - start - nj[j]) * absoff[k];
            }

            if ( st_info->wcode > 0 ) {
                if ( (rc = SF_vdata(st_info->wpos,
                                    i + st_info->in1,
                                    w + start + nj[j])) ) goto exit;
            }

            nj[j]++;
        }
    }

exit:
    return (rc);
}

ST_retcode sf_stats_hdfe_write (
    struct StataInfo *st_info,
    ST_double *X,
    GT_size   *nj,
    GT_size   *index_st)
{
    ST_retcode rc = 0;
    GT_size i, j, k, start, end, njobs, kref, offset_buffer, *stptr;
    GT_size kx = st_info->hdfe_kvars;

    i = 0;
    for (stptr = index_st; stptr < index_st + st_info->Nread; stptr++, i++) {
        if ( *stptr ) {
            j     = *stptr - 1;
            start = st_info->info[j];
            end   = st_info->info[j + 1];
            njobs = end - start;
            kref  = st_info->kvars_by + 1 + kx;

            offset_buffer = start * kx;
            for (k = 0; k < kx; k++) {
                if ( (rc = SF_vstore(kref + k, i + st_info->in1, X[offset_buffer + nj[j]])) ) goto exit;
                offset_buffer += njobs;
            }

            nj[j]++;
        }
    }

    // for (j = 0; j < st_info->J; j++) {
    //     l     = st_info->ix[j];
    //     start = st_info->info[l];
    //     end   = st_info->info[l + 1];
    //     for (i = start; i < end; i++) {
    //         out = st_info->index[i] + st_info->in1;
    //         for (k = 0; k < kx; k++) {
    //             if ( (rc = SF_vstore(krefhdfe + 1 + k, out, *(xptr + nj[l] * k))) ) goto exit;
    //         }
    //         xptr++;
    //     }
    // }

exit:
    return (rc);
}

ST_retcode sf_stats_hdfe_absorb(
    struct GtoolsHash *AbsorbHashes,
    GtoolsGroupByTransform GtoolsGroupByTransform,
    GtoolsGroupByHDFE GtoolsGroupByHDFE,
    ST_double *stats,
    GT_size *maps,
    GT_size J,
    GT_size kabs,
    GT_size kx,
    GT_size *nj,
    GT_size *njptr,
    ST_double *xptr,
    ST_double *wptr,
    ST_double hdfetol)
{
    ST_retcode rc = 0;
    GT_size j, k, njobs;
    struct GtoolsHash *ghptr;

printf("debug26\n");
    // NOTE: nj[j] has obs net of missing values; need ALL obs for offset
    if ( kabs == 1 ) {
printf("debug27\n");
        for (j = 0; j < J; j++) {
            njobs = *njptr;
            AbsorbHashes->nobs = nj[j];
            if ( (rc = GtoolsHashPanel(AbsorbHashes)) ) {
                if ( rc == 17902 ) {
                    return (sf_oom_error("sf_stats_hdfe", "AbsorbHashes"));
                }
                else {
                    goto exit;
                }
            }

            AbsorbHashes->nobs = njobs;
            *njptr = AbsorbHashes->nlevels;
            njptr++;

            GtoolsGroupByTransform(AbsorbHashes, stats, maps, xptr, wptr, xptr, kx);
            GtoolsHashFreePartial(AbsorbHashes);
            AbsorbHashes->offset += AbsorbHashes->nobs;

            xptr += njobs * kx;
            wptr += njobs;
        }
    }
    else if ( kabs > 1 ) {
printf("debug28\n");
        for (j = 0; j < J; j++) {
printf("debug29\n");
            njobs = *njptr;
            ghptr = AbsorbHashes;
            for (k = 0; k < kabs; k++, ghptr++) {
                ghptr->nobs = nj[j];
                if ( (rc = GtoolsHashPanel(ghptr)) ) {
                    if ( rc == 17902 ) {
                        return (sf_oom_error("sf_stats_hdfe", "AbsorbHashes"));
                    }
                    else {
                        goto exit;
                    }
                }
                ghptr->nobs = njobs;
                *njptr = ghptr->nlevels;
                njptr++;
            }

printf("debug30\n");
            GtoolsGroupByHDFE(AbsorbHashes, kabs, xptr, wptr, xptr, kx, hdfetol);
            ghptr = AbsorbHashes;
            for (k = 0; k < kabs; k++, ghptr++) {
                GtoolsHashFreePartial(ghptr);
                ghptr->offset += ghptr->nobs;
            }
            xptr += njobs * kx;
            wptr += njobs;

            if ( (rc = AbsorbHashes->hdfeRc) ) goto exit;
        }
    }

exit:
    return (rc);
}
