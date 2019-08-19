#include "gregress.h"
#include "utils/read.c"
#include "linalg/common.c"
#include "linalg/colmajor.c"
#include "linalg/colmajor_w.c"
#include "linalg/colmajor_ix.c"
#include "linalg/rowmajor.c"
#include "linalg/rowmajor_w.c"
#include "linalg/rowmajor_ix.c"

ST_retcode sf_regress (struct StataInfo *st_info, int level, char *fname)
{

    /*********************************************************************
     *                           Step 1: Setup                           *
     *********************************************************************/

    // ST_double z, d;
    ST_double *xptr, *yptr, *bptr, *septr;
    ST_retcode rc = 0;
    GT_size i, j, k, l, offset, krefb, krefse, krefhdfe, start, end, out;

    FILE *fgregb;
    FILE *fgregse;

    char GTOOLS_GREGB_FILE [st_info->gfile_gregb];
    char GTOOLS_GREGSE_FILE[st_info->gfile_gregse];

    GTOOLS_CHAR(buf1, 32);
    GTOOLS_CHAR(buf2, 32);
    GTOOLS_CHAR(buf3, 32);

    ST_double hdfetol = st_info->gregress_hdfetol;
    GT_size nj_max    = st_info->info[1] - st_info->info[0];
    GT_size kclus     = st_info->gregress_cluster;
    GT_size kabs      = st_info->gregress_absorb;
    GT_size bytesclus = st_info->gregress_cluster_bytes;
    GT_size bytesabs  = st_info->gregress_absorb_bytes;
    // GT_size *clusoff  = st_info->gregress_cluster_offsets;
    GT_size *absoff   = st_info->gregress_absorb_offsets;
    GT_size kx        = st_info->gregress_kvars - 1 + (kabs == 0) * st_info->gregress_cons;
    GT_size kmodel    = kx;
    GT_size N         = st_info->N;
    GT_size J         = st_info->J;
    GT_bool runols    = st_info->gregress_savemse || st_info->gregress_savegse || st_info->gregress_savemb || st_info->gregress_savegb;
    GT_bool runse     = st_info->gregress_savemse || st_info->gregress_savegse;
    clock_t timer     = clock();

    struct GtoolsHash *ghptr;
    struct GtoolsHash *ClusterHash  = malloc(sizeof *ClusterHash);
    struct GtoolsHash *AbsorbHashes = calloc(kabs? kabs: 1, sizeof *AbsorbHashes);

    for (j = 1; j < J; j++) {
        if (nj_max < (st_info->info[j + 1] - st_info->info[j]))
            nj_max = (st_info->info[j + 1] - st_info->info[j]);
    }

    ST_double *y  = calloc(N,       sizeof *y);
    ST_double *X  = calloc(N * kx,  sizeof *X);
    ST_double *e  = calloc(nj_max,  sizeof *e);
    ST_double *Xy = calloc(kx,      sizeof *Xy);
    ST_double *b  = calloc(J * kx,  sizeof *b);
    ST_double *se = calloc(J * kx,  sizeof *se);
    ST_double *XX = calloc(kx * kx, sizeof *XX);
    ST_double *V  = calloc(kx * kx, sizeof *V);
    ST_double *VV = calloc(kx * kx, sizeof *VV);
    GT_size   *nj = calloc(J,       sizeof *nj);

    ST_double *U  = calloc(kclus? nj_max * kx: 1, sizeof *U);
    GT_size   *ux = calloc(kclus? nj_max: 1, sizeof *ux);
    void *G       = calloc(kclus? N:  1, bytesclus? bytesclus: 1);
    void *FE      = calloc(kabs?  N:  1, bytesabs?  bytesabs:  1);
    ST_double *w  = calloc(st_info->wcode > 0? N: 1, sizeof *w);

    ST_double *stats   = calloc(kabs?  kx: 1,    sizeof *stats);
    GT_size   *maps    = calloc(kabs?  kx: 1,    sizeof *maps);
    GT_bool   *clusinv = calloc(kclus? kclus: 1, sizeof *clusinv);
    GT_bool   *absinv  = calloc(kabs?  kabs:  1, sizeof *absinv);
    GT_int    *clustyp = st_info->gregress_cluster_types;
    GT_int    *abstyp  = st_info->gregress_absorb_types;

    if ( y  == NULL ) return(sf_oom_error("sf_regress", "y"));
    if ( X  == NULL ) return(sf_oom_error("sf_regress", "X"));
    if ( e  == NULL ) return(sf_oom_error("sf_regress", "e"));
    if ( Xy == NULL ) return(sf_oom_error("sf_regress", "Xy"));
    if ( b  == NULL ) return(sf_oom_error("sf_regress", "b"));
    if ( se == NULL ) return(sf_oom_error("sf_regress", "se"));
    if ( XX == NULL ) return(sf_oom_error("sf_regress", "XX"));
    if ( V  == NULL ) return(sf_oom_error("sf_regress", "V"));
    if ( VV == NULL ) return(sf_oom_error("sf_regress", "VV"));
    if ( nj == NULL ) return(sf_oom_error("sf_regress", "nj"));

    if ( U  == NULL ) return(sf_oom_error("sf_regress", "U"));
    if ( ux == NULL ) return(sf_oom_error("sf_regress", "ux"));
    if ( G  == NULL ) return(sf_oom_error("sf_regress", "G"));
    if ( FE == NULL ) return(sf_oom_error("sf_regress", "FE"));
    if ( w  == NULL ) return(sf_oom_error("sf_regress", "w"));

    if ( stats   == NULL ) return(sf_oom_error("sf_regress", "stats"));
    if ( maps    == NULL ) return(sf_oom_error("sf_regress", "maps"));
    if ( clusinv == NULL ) return(sf_oom_error("sf_regress", "clusinv"));
    if ( absinv  == NULL ) return(sf_oom_error("sf_regress", "absinv"));

    memset(G,  '\0', (kclus? N: 1) * (bytesclus? bytesclus: 1));
    memset(FE, '\0', (kabs?  N: 1) * (bytesabs?  bytesabs:  1));

    if ( kabs ) {
        for (k = 0; k < kx; k++) {
            stats[k] = -2;
            maps[k]  = k;
        }
    }

    /*********************************************************************
     *                      Step 2: Read in varlist                      *
     *********************************************************************/

    if ( st_info->gregress_rowmajor ) {
        if ( (rc = sf_regress_read_rowmajor (st_info, y, X, w, G, FE, nj)) ) goto exit;

        if ( st_info->benchmark > 1 )
            sf_running_timer (&timer, "\tregress step 1: Copied variables by row");
    }
    else {
        if ( (rc = sf_regress_read_colmajor (st_info, y, X, w, G, FE, nj)) ) goto exit;

        if ( st_info->benchmark > 1 )
            sf_running_timer (&timer, "\tregress step 1: Copied variables by column");
    }

    /*********************************************************************
     *                        Step 3: Compute OLS                        *
     *********************************************************************/

    // 1. Absorb, cluster setup
    // ------------------------

    if ( kclus ) {
        for (k = 0; k < kclus; k++) {
            clusinv[k] = 0;
        }
        GtoolsHashInit(ClusterHash, G, N, kclus, clustyp, clusinv);
        if ( (rc = GtoolsHashSetup(ClusterHash)) ) {
            if ( rc == 17902 ) {
                return (sf_oom_error("sf_regress", "ClusterHash"));
            }
            else {
                return (rc);
            }
        }
    }

    if ( kabs ) {
        offset = 0;
        ghptr  = AbsorbHashes;
        for (k = 0; k < kabs; k++, ghptr++) {
            absinv[k] = 0;
            GtoolsHashInit(ghptr, FE + offset, N, 1, abstyp + k, absinv + k);
            if ( (rc = GtoolsHashSetup(ghptr)) ) {
                if ( rc == 17902 ) {
                    return (sf_oom_error("sf_regress", "AbsorbHashes"));
                }
                else {
                    return (rc);
                }
            }
            offset += N * absoff[k];
        }
    }

    // 2. OLS
    // ------

    xptr  = X;
    yptr  = y;
    bptr  = b;
    septr = se;

    if ( st_info->gregress_rowmajor && runols ) {
        if ( st_info->gregress_cluster ) {
            for (j = 0; j < J; j++) {
                if ( kmodel >= nj[j] ) {
                    sf_format_size(nj[j], buf1);
                    sf_format_size(kx, buf2);
                    sf_errprintf("insufficient observations (%s) for %s variables\n",
                                 buf1, buf2);
                    rc = 18401;
                    goto exit;
                }

                if ( runse ) {
                    ClusterHash->nobs = nj[j];
                    if ( (rc = GtoolsHashPanel(ClusterHash)) ) {
                        if ( rc == 17902 ) {
                            return (sf_oom_error("sf_regress", "ClusterHash"));
                        }
                        else {
                            return (rc);
                        }
                    }
                }

                gf_regress_ols_rowmajor (xptr, yptr, XX, Xy, e, bptr, nj[j], kx);
                if ( runse ) {
                    gf_regress_ols_cluster_rowmajor(
                        e,
                        ClusterHash->info,
                        ClusterHash->index,
                        ClusterHash->nlevels,
                        U,
                        V,
                        VV,
                        X,
                        XX,
                        septr,
                        nj[j],
                        kx,
                        kmodel
                    );
                    GtoolsHashFreePartial (ClusterHash);
                    ClusterHash->offset += ClusterHash->nobs;
                }

                xptr  += nj[j] * kx;
                yptr  += nj[j];
                bptr  += kx;
                septr += kx;
            }
        }
        else if ( st_info->gregress_robust ) {
            for (j = 0; j < J; j++) {
                if ( kmodel >= nj[j] ) {
                    sf_format_size(nj[j], buf1);
                    sf_format_size(kx, buf2);
                    sf_errprintf("insufficient observations (%s) for %s variables\n",
                                 buf1, buf2);
                    rc = 18401;
                    goto exit;
                }
                gf_regress_ols_rowmajor (xptr, yptr, XX, Xy, e, bptr, nj[j], kx);
                if ( runse ) {
                    gf_regress_ols_robust_rowmajor (e, V, VV, xptr, XX, septr, nj[j], kx, kmodel);
                }
                xptr  += nj[j] * kx;
                yptr  += nj[j];
                bptr  += kx;
                septr += kx;
            }
        }
        else {
            for (j = 0; j < J; j++) {
                if ( kmodel >= nj[j] ) {
                    sf_format_size(nj[j], buf1);
                    sf_format_size(kx, buf2);
                    sf_errprintf("insufficient observations (%s) for %s variables\n",
                                 buf1, buf2);
                    rc = 18401;
                    goto exit;
                }
                gf_regress_ols_rowmajor (xptr, yptr, XX, Xy, e, bptr, nj[j], kx);
                if ( runse ) {
                    gf_regress_ols_se (e, XX, septr, nj[j], kx, kmodel);
                }
                xptr  += nj[j] * kx;
                yptr  += nj[j];
                bptr  += kx;
                septr += kx;
            }
        }
    }
    else if ( runols || (kabs > 0 && st_info->gregress_saveghdfe) ) {
        if ( st_info->gregress_cluster ) {
            for (j = 0; j < J; j++) {
                if ( kabs == 1 ) {
                    AbsorbHashes->nobs = nj[j];
                    if ( (rc = GtoolsHashPanel(AbsorbHashes)) ) {
                        if ( rc == 17902 ) {
                            return (sf_oom_error("sf_regress", "AbsorbHashes"));
                        }
                        else {
                            return (rc);
                        }
                    }
                    kmodel = kx + AbsorbHashes->nlevels;
                    GtoolsGroupByTransform (AbsorbHashes, stats, maps, xptr, NULL, kx);
                    GtoolsGroupByTransform (AbsorbHashes, stats, maps, yptr, NULL, 1);
                    GtoolsHashFreePartial (AbsorbHashes);
                    AbsorbHashes->offset += AbsorbHashes->nobs;
                }
                else if ( kabs > 1 ) {
                    ghptr  = AbsorbHashes;
                    kmodel = kx + 1;
                    for (k = 0; k < kabs; k++, ghptr++) {
                        ghptr->nobs = nj[j];
                        if ( (rc = GtoolsHashPanel(ghptr)) ) {
                            if ( rc == 17902 ) {
                                return (sf_oom_error("sf_regress", "AbsorbHashes"));
                            }
                            else {
                                return (rc);
                            }
                        }
                        kmodel += ghptr->nlevels;
                    }
                    kmodel -= kabs;
                    GtoolsGroupByHDFE(AbsorbHashes, kabs, xptr, NULL, kx, hdfetol);
                    GtoolsGroupByHDFE(AbsorbHashes, kabs, yptr, NULL, 1,  hdfetol);

                    ghptr = AbsorbHashes;
                    for (k = 0; k < kabs; k++, ghptr++) {
                        GtoolsHashFreePartial(ghptr);
                        ghptr->offset += ghptr->nobs;
                    }
                }

                if ( kmodel >= nj[j] ) {
                    sf_format_size(nj[j], buf1);
                    sf_format_size(kx, buf2);
                    if ( kabs ) {
                        sf_format_size((kmodel + kabs - kx - 1), buf3);
                        sf_errprintf("insufficient observations (%s) for %s variables and %s absorb levels\n",
                                     buf1, buf2, buf3);
                    }
                    else {
                        sf_errprintf("insufficient observations (%s) for %s variables\n",
                                     buf1, buf2);
                    }
                    rc = 18401;
                    goto exit;
                }

                if ( runse ) {
                    ClusterHash->nobs = nj[j];
                    if ( (rc = GtoolsHashPanel(ClusterHash)) ) {
                        if ( rc == 17902 ) {
                            return (sf_oom_error("sf_regress", "ClusterHash"));
                        }
                        else {
                            return (rc);
                        }
                    }
                }

                if ( runols ) {
                    gf_regress_ols_colmajor (xptr, yptr, XX, Xy, e, bptr, nj[j], kx);
                    if ( runse ) {
                        gf_regress_ols_cluster_colmajor(
                            e,
                            ClusterHash->info,
                            ClusterHash->index,
                            ClusterHash->nlevels,
                            U,
                            ux,
                            V,
                            VV,
                            X,
                            XX,
                            septr,
                            nj[j],
                            kx,
                            kmodel
                        );
                        GtoolsHashFreePartial (ClusterHash);
                        ClusterHash->offset += ClusterHash->nobs;
                    }
                }

                xptr  += nj[j] * kx;
                yptr  += nj[j];
                bptr  += kx;
                septr += kx;
            }
        }
        else if ( st_info->gregress_robust ) {
            for (j = 0; j < J; j++) {
                if ( kabs == 1 ) {
                    AbsorbHashes->nobs = nj[j];
                    if ( (rc = GtoolsHashPanel(AbsorbHashes)) ) {
                        if ( rc == 17902 ) {
                            return (sf_oom_error("sf_regress", "AbsorbHashes"));
                        }
                        else {
                            return (rc);
                        }
                    }
                    kmodel = kx + AbsorbHashes->nlevels;
                    GtoolsGroupByTransform (AbsorbHashes, stats, maps, xptr, NULL, kx);
                    GtoolsGroupByTransform (AbsorbHashes, stats, maps, yptr, NULL, 1);
                    GtoolsHashFreePartial (AbsorbHashes);
                    AbsorbHashes->offset += AbsorbHashes->nobs;
                }
                else if ( kabs > 1 ) {
                    ghptr  = AbsorbHashes;
                    kmodel = kx + 1;
                    for (k = 0; k < kabs; k++, ghptr++) {
                        ghptr->nobs = nj[j];
                        if ( (rc = GtoolsHashPanel(ghptr)) ) {
                            if ( rc == 17902 ) {
                                return (sf_oom_error("sf_regress", "AbsorbHashes"));
                            }
                            else {
                                return (rc);
                            }
                        }
                        kmodel += ghptr->nlevels;
                    }
                    kmodel -= kabs;
                    GtoolsGroupByHDFE(AbsorbHashes, kabs, xptr, NULL, kx, hdfetol);
                    GtoolsGroupByHDFE(AbsorbHashes, kabs, yptr, NULL, 1,  hdfetol);

                    ghptr = AbsorbHashes;
                    for (k = 0; k < kabs; k++, ghptr++) {
                        GtoolsHashFreePartial(ghptr);
                        ghptr->offset += ghptr->nobs;
                    }
                }

                if ( kmodel >= nj[j] ) {
                    sf_format_size(nj[j], buf1);
                    sf_format_size(kx, buf2);
                    if ( kabs ) {
                        sf_format_size((kmodel + kabs - kx - 1), buf3);
                        sf_errprintf("insufficient observations (%s) for %s variables and %s absorb levels\n",
                                     buf1, buf2, buf3);
                    }
                    else {
                        sf_errprintf("insufficient observations (%s) for %s variables\n",
                                     buf1, buf2);
                    }
                    rc = 18401;
                    goto exit;
                }

                if ( runols ) {
                    gf_regress_ols_colmajor (xptr, yptr, XX, Xy, e, bptr, nj[j], kx);
                    if ( runse ) {
                        gf_regress_ols_robust_colmajor (e, V, VV, xptr, XX, septr, nj[j], kx, kmodel);
                    }
                }
                xptr  += nj[j] * kx;
                yptr  += nj[j];
                bptr  += kx;
                septr += kx;
            }
        }
        else {
            for (j = 0; j < J; j++) {
                if ( kabs == 1 ) {
                    AbsorbHashes->nobs = nj[j];
                    if ( (rc = GtoolsHashPanel(AbsorbHashes)) ) {
                        if ( rc == 17902 ) {
                            return (sf_oom_error("sf_regress", "AbsorbHashes"));
                        }
                        else {
                            return (rc);
                        }
                    }
                    kmodel = kx + AbsorbHashes->nlevels;
                    GtoolsGroupByTransform (AbsorbHashes, stats, maps, xptr, NULL, kx);
                    GtoolsGroupByTransform (AbsorbHashes, stats, maps, yptr, NULL, 1);
                    GtoolsHashFreePartial (AbsorbHashes);
                    AbsorbHashes->offset += AbsorbHashes->nobs;
                }
                else if ( kabs > 1 ) {
                    ghptr  = AbsorbHashes;
                    kmodel = kx + 1;
                    for (k = 0; k < kabs; k++, ghptr++) {
                        ghptr->nobs = nj[j];
                        if ( (rc = GtoolsHashPanel(ghptr)) ) {
                            if ( rc == 17902 ) {
                                return (sf_oom_error("sf_regress", "AbsorbHashes"));
                            }
                            else {
                                return (rc);
                            }
                        }
                        kmodel += ghptr->nlevels;
                    }
                    kmodel -= kabs;
                    GtoolsGroupByHDFE(AbsorbHashes, kabs, xptr, NULL, kx, hdfetol);
                    GtoolsGroupByHDFE(AbsorbHashes, kabs, yptr, NULL, 1,  hdfetol);

                    ghptr = AbsorbHashes;
                    for (k = 0; k < kabs; k++, ghptr++) {
                        GtoolsHashFreePartial(ghptr);
                        ghptr->offset += ghptr->nobs;
                    }
                }

                if ( kmodel >= nj[j] ) {
                    sf_format_size(nj[j], buf1);
                    sf_format_size(kx, buf2);
                    if ( kabs ) {
                        sf_format_size((kmodel + kabs - kx - 1), buf3);
                        sf_errprintf("insufficient observations (%s) for %s variables and %s absorb levels\n",
                                     buf1, buf2, buf3);
                    }
                    else {
                        sf_errprintf("insufficient observations (%s) for %s variables\n",
                                     buf1, buf2);
                    }
                    rc = 18401;
                    goto exit;
                }

                if ( runols ) {
                    gf_regress_ols_colmajor (xptr, yptr, XX, Xy, e, bptr, nj[j], kx);
                    if ( runse ) {
                        gf_regress_ols_se (e, XX, septr, nj[j], kx, kmodel);
                    }
                }
                xptr  += nj[j] * kx;
                yptr  += nj[j];
                bptr  += kx;
                septr += kx;
            }
        }
    }

    if ( st_info->benchmark > 1 )
        sf_running_timer (&timer, "\tregress step 2: Computed beta, se");

    /*********************************************************************
     *                Step 4: Write results back to Stata                *
     *********************************************************************/

    if ( st_info->gregress_savemata ) {
        if ( st_info->gregress_savemb ) {
            if ( (rc = SF_macro_use("GTOOLS_GREGB_FILE",  GTOOLS_GREGB_FILE,  st_info->gfile_gregb)  )) goto exit;

            fgregb = fopen(GTOOLS_GREGB_FILE,  "wb");
            rc = rc | (fwrite(b, sizeof(b), J * kx, fgregb) != (J * kx));
            fclose(fgregb);
        }

        if ( st_info->gregress_savemse ) {
            if ( (rc = SF_macro_use("GTOOLS_GREGSE_FILE", GTOOLS_GREGSE_FILE, st_info->gfile_gregse) )) goto exit;

            fgregse = fopen(GTOOLS_GREGSE_FILE, "wb");
            rc = rc | (fwrite(se, sizeof(se), J * kx, fgregse) != (J * kx));
            fclose(fgregse);
        }

        if ( (rc = sf_byx_save_top (st_info, 0, NULL)) ) goto exit;
    }

    if ( st_info->gregress_savegb || st_info->gregress_savegse || st_info->gregress_saveghdfe ) {
        krefb    = st_info->kvars_by + st_info->gregress_kvars + kclus + kabs + 1;
        krefse   = st_info->kvars_by + st_info->gregress_kvars + kclus + kabs + 1 + kx * st_info->gregress_savegb;
        krefhdfe = st_info->kvars_by + st_info->gregress_kvars + kclus + kabs + 1 + kx * st_info->gregress_savegb + kx * st_info->gregress_savegse;

        bptr  = b;
        septr = se;
        yptr  = y;
        xptr  = X;
        for (j = 0; j < st_info->J; j++) {
            l     = st_info->ix[j];
            start = st_info->info[l];
            end   = st_info->info[l + 1];
            for (i = start; i < end; i++) {
                out = st_info->index[i] + st_info->in1;
                if ( st_info->gregress_savegb ) {
                    for (k = 0; k < kx; k++) {
                        if ( (rc = SF_vstore(krefb + k, out, bptr[k])) ) goto exit;
                    }
                }
                if ( st_info->gregress_savegse ) {
                    for (k = 0; k < kx; k++) {
                        if ( (rc = SF_vstore(krefse + k, out, septr[k])) ) goto exit;
                    }
                }
                if ( st_info->gregress_saveghdfe ) {
                    if ( (rc = SF_vstore(krefhdfe, out, *yptr)) ) goto exit;
                    for (k = 0; k < kx; k++) {
                        if ( (rc = SF_vstore(krefhdfe + 1 + k, out, *(xptr + nj[l] * k))) ) goto exit;
                    }
                    xptr++;
                    yptr++;
                }
            }
            bptr  += kx;
            septr += kx;
            // xptr  += end - start;
            // yptr  += end - start;
        }
    }

exit:

    if ( kclus ) {
        GtoolsHashFree(ClusterHash);
    }
    free (ClusterHash);

    if ( kabs ) {
        for (k = 0; k < kabs; k++) {
            GtoolsHashFree(AbsorbHashes + k);
        }
    }
    free (AbsorbHashes);

    free(y);
    free(X);
    free(e);
    free(Xy);
    free(b);
    free(se);
    free(XX);
    free(V);
    free(VV);
    free(nj);

    free(U);
    free(ux);
    free(G);
    free(FE);
    free(w);

    free(clusinv);
    free(absinv);

    return (rc);
}
