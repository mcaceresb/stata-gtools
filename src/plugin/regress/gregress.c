#include "gregress.h"
#include "models/models.h"
#include "vce/vce.h"
#include "linalg/linalg.h"

#include "models/ols.c"
#include "models/poisson.c"
#include "models/ivregress.c"
#include "models/models.h"

#include "vce/vceadj.c"
#include "vce/homoskedastic.c"
#include "vce/heteroskedastic.c"
#include "vce/cluster.c"

#include "linalg/colmajor.c"
#include "linalg/colmajor_w.c"
#include "linalg/colmajor_ix.c"
#include "linalg/rowmajor.c"
#include "linalg/common.c"
#include "linalg/decompositions.c"
#include "linalg/inverses.c"

#include "utils/read.c"

ST_retcode sf_regress (struct StataInfo *st_info, int level, char *fname)
{

    /*********************************************************************
     *                           Step 1: Setup                           *
     *********************************************************************/

    // ST_double z, d;
    ST_retcode rc = 0;
    ST_double *njclusptr, *njabsptr;
    ST_double diff, *xptr, *yptr, *wptr, *bptr, *septr, *xdmptr, *ivendog, *ivexog, *ivzptr;
    GT_size i, j, k, l, njobs, offset, krefb, krefse, krefhdfe, start, end, out, iter;
    GT_size *ixptr;

    FILE *fgregb;
    FILE *fgregse;
    FILE *fgregclus;
    FILE *fgregabs;

    char GTOOLS_GREGB_FILE   [st_info->gfile_gregb];
    char GTOOLS_GREGSE_FILE  [st_info->gfile_gregse];
    char GTOOLS_GREGCLUS_FILE[st_info->gfile_gregclus];
    char GTOOLS_GREGABS_FILE [st_info->gfile_gregabs];

    GTOOLS_CHAR(buf1, 32);
    GTOOLS_CHAR(buf2, 32);
    GTOOLS_CHAR(buf3, 32);
    GTOOLS_CHAR(buf4, 32);

    ST_double poistol     = st_info->gregress_poistol;
    ST_double hdfetol     = st_info->gregress_hdfetol;
    GT_size nj_max        = st_info->info[1] - st_info->info[0];
    GT_size kclus         = st_info->gregress_cluster;
    GT_size kabs          = st_info->gregress_absorb;
    GT_size bytesclus     = st_info->gregress_cluster_bytes;
    GT_size bytesabs      = st_info->gregress_absorb_bytes;
    GT_size *absoff       = st_info->gregress_absorb_offsets;
    GT_size kx            = st_info->gregress_kvars - 1 + (kabs == 0) * st_info->gregress_cons;
    GT_size ktot          = kx + 1;
    GT_size kmodel        = kx;
    GT_size N             = st_info->N;
    GT_size J             = st_info->J;
    GT_bool ivreg         = st_info->gregress_ivreg;
    GT_size ivkendog      = st_info->gregress_ivkendog;
    GT_size ivkexog       = st_info->gregress_ivkexog + (kabs == 0) * st_info->gregress_cons;
    GT_size ivkz          = st_info->gregress_ivkz;
    GT_size ivkss         = ivkendog + ivkexog;
    GT_size ivkdep        = 0;
    GT_size ivkmixed      = 0;
    GT_size kv            = ivreg? ivkexog + ivkendog: kx;
    GT_bool poisson       = st_info->gregress_poisson;
    GT_size poisiter      = st_info->gregress_poisiter;
    GT_bool runols        = st_info->gregress_savemse || st_info->gregress_savegse
                         || st_info->gregress_savemb  || st_info->gregress_savegb;
    GT_bool runse         = st_info->gregress_savemse || st_info->gregress_savegse;
    GT_bool interval      = st_info->gregress_range;
    GT_bool panelsetup    = 1;
    GT_size warncollinear = 0;
    GT_size warnsingular  = 0;
    GT_size warnivnotiden = 0;
    GT_size warnnocols    = 0;
    GT_bool singular      = 0;

    // TODO: Comment what each is. You are atm struggling to remember
    // the details of the differences between kx and kv

    // ST_double intlower = st_info->gregress_range_l;
    // ST_double intupper = st_info->gregress_range_u;
    // ST_double intlcode = st_info->gregress_range_ls;
    // ST_double intucode = st_info->gregress_range_us;
    // GT_int moving      = st_info->gregress_moving;
    // GT_int movlower    = st_info->gregress_moving_l;
    // GT_int movupper    = st_info->gregress_moving_u;

    clock_t timer      = clock();

    GtoolsGroupByTransform GtoolsGroupByTransform;
    GtoolsGroupByHDFE GtoolsGroupByHDFE;

    struct GtoolsHash *ghptr;
    struct GtoolsHash *ClusterHash  = malloc(sizeof *ClusterHash);
    struct GtoolsHash *AbsorbHashes = calloc(kabs? kabs: 1, sizeof *AbsorbHashes);

    for (j = 1; j < J; j++) {
        if (nj_max < (st_info->info[j + 1] - st_info->info[j]))
            nj_max = (st_info->info[j + 1] - st_info->info[j]);
    }

    // NOTE:
    //
    // XX               | X' X    in OLS algebra
    // XX + 1 * kx * kx | L, L^-1 in LDU decomposition
    // XX + 2 * kx * kx | U       in LDU decomposition
    // XX + 3 * kx * kx | D       in LDU decomposition

    // NOTE(mauricio): This takes slightly more memory than strictly
    // required atm (kx is enough here, not ktot). Leave as is until you
    // decide on the exact behavior of givregress (i.e. whether to add
    // the second collinearity check with the dependent var)

    ST_double *vars = calloc(N * ktot,        sizeof *vars);
    ST_double *e    = calloc(nj_max,          sizeof *e);
    ST_double *Xy   = calloc(kx,              sizeof *Xy);
    ST_double *b    = calloc(J * kx,          sizeof *b);
    ST_double *se   = calloc(J * kx,          sizeof *se);
    ST_double *XX   = calloc(4 * ktot * ktot, sizeof *XX);
    ST_double *V    = calloc(kx * kx,         sizeof *V);
    ST_double *VV   = calloc(kx * kx,         sizeof *VV);
    GT_size   *nj   = calloc(J,               sizeof *nj);

    ST_double *BZ   = calloc(ivreg? (ivkz + ivkexog) * ivkendog: 1, sizeof *BZ);
    ST_double *PZ   = calloc(ivreg? nj_max * ivkendog: 1, sizeof *PZ);
    ST_double *U    = calloc(kclus? nj_max * kx: 1, sizeof *U);
    GT_size   *ux   = calloc(kclus? nj_max: 1, sizeof *ux);
    void      *G    = calloc(kclus? N:  1, bytesclus? bytesclus: 1);
    void      *FE   = calloc(kabs?  N:  1, bytesabs?  bytesabs:  1);
    ST_double *I    = calloc(interval? N: 1, sizeof *I);
    ST_double *w    = calloc(st_info->wcode > 0? N: 1, sizeof *w);

    ST_double *poisaux = calloc(poisson? nj_max * (5 + (kabs > 0)):  1, sizeof *poisaux);
    ST_double *xdm     = calloc(poisson && (kabs > 0)? nj_max * kx: 1,  sizeof *poisaux);
    ST_double *njclus  = calloc(kclus? J:        1, sizeof *njclus);
    ST_double *njabs   = calloc(kabs?  J * kabs: 1, sizeof *njabs);
    ST_double *stats   = calloc(kabs?  kx:       1, sizeof *stats);
    GT_size   *maps    = calloc(kabs?  kx:       1, sizeof *maps);
    GT_bool   *clusinv = calloc(kclus? kclus:    1, sizeof *clusinv);
    GT_bool   *absinv  = calloc(kabs?  kabs:     1, sizeof *absinv);
    GT_size   *colix   = calloc(3 * ktot + 6, sizeof *colix);
    GT_int    *clustyp = st_info->gregress_cluster_types;
    GT_int    *abstyp  = st_info->gregress_absorb_types;

    if ( vars == NULL ) return(sf_oom_error("sf_regress", "vars"));
    if ( e    == NULL ) return(sf_oom_error("sf_regress", "e"));
    if ( Xy   == NULL ) return(sf_oom_error("sf_regress", "Xy"));
    if ( b    == NULL ) return(sf_oom_error("sf_regress", "b"));
    if ( se   == NULL ) return(sf_oom_error("sf_regress", "se"));
    if ( XX   == NULL ) return(sf_oom_error("sf_regress", "XX"));
    if ( V    == NULL ) return(sf_oom_error("sf_regress", "V"));
    if ( VV   == NULL ) return(sf_oom_error("sf_regress", "VV"));
    if ( nj   == NULL ) return(sf_oom_error("sf_regress", "nj"));

    if ( BZ   == NULL ) return(sf_oom_error("sf_regress", "BZ"));
    if ( PZ   == NULL ) return(sf_oom_error("sf_regress", "PZ"));
    if ( U    == NULL ) return(sf_oom_error("sf_regress", "U"));
    if ( ux   == NULL ) return(sf_oom_error("sf_regress", "ux"));
    if ( G    == NULL ) return(sf_oom_error("sf_regress", "G"));
    if ( FE   == NULL ) return(sf_oom_error("sf_regress", "FE"));
    if ( I    == NULL ) return(sf_oom_error("sf_regress", "I"));
    if ( w    == NULL ) return(sf_oom_error("sf_regress", "w"));

    if ( poisaux == NULL ) return(sf_oom_error("sf_regress", "poisaux"));
    if ( xdm     == NULL ) return(sf_oom_error("sf_regress", "xdm"));
    if ( njclus  == NULL ) return(sf_oom_error("sf_regress", "njclus"));
    if ( njabs   == NULL ) return(sf_oom_error("sf_regress", "njabs"));
    if ( stats   == NULL ) return(sf_oom_error("sf_regress", "stats"));
    if ( maps    == NULL ) return(sf_oom_error("sf_regress", "maps"));
    if ( clusinv == NULL ) return(sf_oom_error("sf_regress", "clusinv"));
    if ( absinv  == NULL ) return(sf_oom_error("sf_regress", "absinv"));
    if ( colix   == NULL ) return(sf_oom_error("sf_regress", "colix"));

    // NOTE(mauricio): The vars pointer switch for IV and _does not_
    // work with rowmajor (which is deprecated atm).

    ST_double *y = vars;
    ST_double *X = vars + N;

    ST_double *mu    = poisaux + 0 * nj_max;
    ST_double *eta   = poisaux + 1 * nj_max;
    ST_double *lhs   = poisaux + 2 * nj_max;
    ST_double *dev0  = poisaux + 3 * nj_max;
    ST_double *dev   = poisaux + 4 * nj_max;
    ST_double *lhsdm = kabs? poisaux + 5 * nj_max: lhs;

    memset(colix, '\0', (3 * ktot + 6) * (sizeof *colix));
    memset(G,     '\0', (kclus? N: 1) * (bytesclus? bytesclus: 1));
    memset(FE,    '\0', (kabs?  N: 1) * (bytesabs?  bytesabs:  1));

    if ( kabs ) {
        for (k = 0; k < kx; k++) {
            stats[k] = -2;
            maps[k]  = k;
        }
    }

    // assign correct functions to run based on weights/models
    {
        sf_regress_read = sf_regress_read_colmajor;
        if ( st_info->wcode > 0 || poisson ) {
            gf_regress_ols         = gf_regress_ols_wcolmajor;
            gf_regress_ols_se      = gf_regress_ols_sew;
            gf_regress_ols_robust  = gf_regress_ols_robust_wcolmajor;
            gf_regress_ols_cluster = gf_regress_ols_cluster_wcolmajor;
            if ( st_info->wcode == 2 ) {
                gf_regress_ols_robust  = gf_regress_ols_robust_fwcolmajor;
                gf_regress_ols_se      = gf_regress_ols_sefw;
            }
            else {
                gf_regress_ols_robust  = gf_regress_ols_robust_wcolmajor;
                gf_regress_ols_se      = gf_regress_ols_sew;
            }
        }
        else {
            gf_regress_ols         = gf_regress_ols_colmajor;
            gf_regress_ols_se      = gf_regress_ols_seunw;
            gf_regress_ols_robust  = gf_regress_ols_robust_colmajor;
            gf_regress_ols_cluster = gf_regress_ols_cluster_colmajor;
        }
    }

    // TODO: Mess with this based on aw, fw, pw, iw?
    if ( st_info->wcode > 0 ) {
        gf_regress_iv           = gf_regress_iv_w;
        gf_regress_poisson_init = gf_regress_poisson_init_w;
        gf_regress_poisson_iter = gf_regress_poisson_iter_w;
    }
    else {
        gf_regress_iv           = gf_regress_iv_unw;
        gf_regress_poisson_init = gf_regress_poisson_init_unw;
        gf_regress_poisson_iter = gf_regress_poisson_iter_unw;
    }

    // TODO: Mess with this based on aw, fw, pw, iw?
    if ( st_info->wcode > 0 || poisson ) {
        GtoolsGroupByTransform = GtoolsGroupByTransformWeighted;
        GtoolsGroupByHDFE      = GtoolsGroupByHDFEWeighted;
    }
    else {
        GtoolsGroupByTransform = GtoolsGroupByTransformUnweighted;
        GtoolsGroupByHDFE      = GtoolsGroupByHDFEUnweighted;
    }

    gf_regress_vceadj vceadj;
    if ( poisson ) {
        if ( st_info->wcode == 2 ) {
            if ( kclus ) {
                vceadj = gf_regress_vceadj_mle_cluster_fw;
            }
            else {
                vceadj = gf_regress_vceadj_mle_robust_fw;
            }
        }
        else {
            if ( kclus ) {
                vceadj = gf_regress_vceadj_mle_cluster;
            }
            else {
                vceadj = gf_regress_vceadj_mle_robust;
            }
        }
    }
    else {
        if ( st_info->wcode == 2 ) {
            if ( kclus ) {
                vceadj = gf_regress_vceadj_ols_cluster_fw;
            }
            else {
                vceadj = gf_regress_vceadj_ols_robust_fw;
            }
        }
        else {
            if ( kclus ) {
                vceadj = gf_regress_vceadj_ols_cluster;
            }
            else {
                vceadj = gf_regress_vceadj_ols_robust;
            }
        }
    }

    /*********************************************************************
     *                      Step 2: Read in varlist                      *
     *********************************************************************/

    if ( (rc = sf_regress_read (st_info, y, X, w, G, FE, I, nj)) ) goto exit;

    if ( st_info->benchmark > 1 )
        sf_running_timer (&timer, "\tregress step 1: Copied variables from Stata");

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
                goto exit;
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
                    goto exit;
                }
            }
            offset += N * absoff[k];
        }
    }

    // 2. Models
    // ---------

    // memset(b,  '\0', J * kx * (sizeof *b));
    // memset(se, '\0', J * kx * (sizeof *b));

    xptr  = X;
    yptr  = y;
    bptr  = b;
    septr = se;
    wptr  = w;

    njclusptr = njclus;
    njabsptr  = njabs;

    // TODO: Option for identification check to be soft. This would
    // be useful in group regressions where some groups have enough
    // observations and others don't. In that case simply return missing
    // values (in this case missing would be correct instead of 0) for
    // both SE and b.
    //
    // TODO: Stata drops variables that are perfectly correlated with
    // the dependent variable... Should I do that as well?
    //
    // TODO: Double-check that kx = ivkendog + ivkexog + ivkz

    if ( runols && ivreg ) {
        if ( runse ) {
            if ( kclus ) {

                // Cluster errors
                // --------------

                for (j = 0; j < J; j++) {
                    njobs   = nj[j];
                    kmodel  = kx;
                    ivendog = xptr;
                    ivexog  = ivendog + ivkendog * njobs;
                    ivzptr  = ivexog + ivkexog * njobs;
                    if ( kabs && (rc = gf_regress_absorb(AbsorbHashes,
                                                         GtoolsGroupByTransform,
                                                         GtoolsGroupByHDFE,
                                                         stats,
                                                         maps,
                                                         njobs,
                                                         kabs,
                                                         kx,
                                                         &kmodel,
                                                         njabsptr,
                                                         xptr,
                                                         yptr,
                                                         wptr,
                                                         xptr,
                                                         yptr,
                                                         1,
                                                         hdfetol)) ) {
                        goto exit;
                    }

                    // NOTE: Do this here since absorb automagically sets it using kx
                    kmodel -= ivkz;
                    if ( (rc = gf_regress_iv_notidentified(njobs,
                                                           kabs,
                                                           ivkendog,
                                                           ivkexog,
                                                           ivkz,
                                                           kmodel,
                                                           buf1,
                                                           buf2,
                                                           buf3)) ) {
                        goto exit;
                    }

                    // NOTE: ivendog gets _moved_ if there are collinear variables
                    singular = gf_regress_iv(
                        ivendog,
                        ivexog,
                        ivzptr,
                        yptr,
                        wptr,
                        XX,
                        PZ,
                        BZ,
                        e,
                        bptr,
                        colix,
                        njobs,
                        ivkendog,
                        ivkexog,
                        ivkz
                    );

                    ClusterHash->nobs = njobs;
                    if ( (rc = GtoolsHashPanel(ClusterHash)) ) {
                        if ( rc == 17902 ) {
                            return (sf_oom_error("sf_regress", "ClusterHash"));
                        }
                        else {
                            goto exit;
                        }
                    }
                    *njclusptr = ClusterHash->nlevels;

                    // singular =
                    //
                    // 0 | no issues detected
                    // 1 | collinear columns removed
                    // 2 | numerically zero determinant; no collinearity detected
                    // 3 | under-identified after collinearity check
                    // 4 | no usable columns (all numerically 0)

                    switch ( singular ) {
                        case 1:
                            warncollinear++;
                            break;
                        case 2:
                            warnsingular++;
                            break;
                        case 3:
                            warnivnotiden++;
                            for (k = 0; k < ivkss; k++) {
                                bptr[k]  = SV_missval;
                                septr[k] = SV_missval;
                            }
                            break;
                        case 4:
                            warnnocols++;
                            for (k = 0; k < ivkss; k++) {
                                bptr[k]  = SV_missval;
                                septr[k] = SV_missval;
                            }
                            break;
                    }

                    if ( singular != 3 && singular != 4 ) {
                        ixptr    = colix + 2 * ktot;
                        kmodel  -= (ivkss - ixptr[ivkss]);
                        ivkmixed = ixptr[ivkss + 1];
                        ivkdep   = (ivkendog - ixptr[ivkss + 2]);

                        // NOTE: If there were collinear endogenous covariates,
                        // they were projected continuously overriding ivendog.
                        // We _only_ make this adjustment when we have collinear
                        // endogenous vars, so we only adjust ivendog in this case.

                        gf_regress_ols_cluster(
                            e,
                            wptr,
                            ClusterHash->info,
                            ClusterHash->index,
                            ClusterHash->nlevels,
                            U,
                            ux,
                            V,
                            VV,
                            ivendog + njobs * ivkdep,
                            XX,
                            septr,
                            ixptr,
                            njobs,
                            ivkmixed,
                            kmodel,
                            vceadj
                        );

                        // NOTE: To save some memory I use Xy as a buffer
                        if ( singular == 1 ) {
                            gf_regress_adjust_collinear_b  (bptr,  Xy, colix, ixptr[ivkss], ivkss);
                            gf_regress_adjust_collinear_se (septr, Xy, colix, ixptr[ivkss], ivkss);
                        }

                        // Need to copy back for two reasons:  Get back this
                        // _unprojected_ de-meaned endogenous variables _and_ if
                        // there were any collinear variables, leave them in their
                        // original position. Note that you need the projected
                        // non-collinar endogeous variables for the SE, so the
                        // memcpy has to go here, at the end.

                        if ( kabs && st_info->gregress_saveghdfe ) {
                            memcpy(ivendog, PZ, sizeof(ST_double) * N * ivkendog);
                        }
                    }

                    GtoolsHashFreePartial(ClusterHash);
                    ClusterHash->offset += ClusterHash->nobs;

                    njclusptr++;
                    xptr  += njobs * kx;
                    yptr  += njobs;
                    wptr  += njobs;
                    bptr  += kv;
                    septr += kv;
                    ghptr  = AbsorbHashes;
                    for (k = 0; k < kabs; k++, ghptr++) {
                        GtoolsHashFreePartial(ghptr);
                        ghptr->offset += ghptr->nobs;
                    }
                }
            }
            else if ( st_info->gregress_robust ) {

                // Robust errors
                // -------------

                for (j = 0; j < J; j++) {
                    njobs   = nj[j];
                    kmodel  = kx;
                    ivendog = xptr;
                    ivexog  = ivendog + ivkendog * njobs;
                    ivzptr  = ivexog + ivkexog * njobs;
                    if ( kabs && (rc = gf_regress_absorb(AbsorbHashes,
                                                         GtoolsGroupByTransform,
                                                         GtoolsGroupByHDFE,
                                                         stats,
                                                         maps,
                                                         njobs,
                                                         kabs,
                                                         kx,
                                                         &kmodel,
                                                         njabsptr,
                                                         xptr,
                                                         yptr,
                                                         wptr,
                                                         xptr,
                                                         yptr,
                                                         1,
                                                         hdfetol)) ) {
                        goto exit;
                    }

                    // NOTE: Do this here since absorb automagically sets it using kx
                    kmodel -= ivkz;
                    if ( (rc = gf_regress_iv_notidentified(njobs, kabs, ivkendog, ivkexog, ivkz, kmodel, buf1, buf2, buf3)) ) {
                        goto exit;
                    }

                    // NOTE: ivendog gets _moved_ if there are collinear variables
                    singular = gf_regress_iv(
                        ivendog,
                        ivexog,
                        ivzptr,
                        yptr,
                        wptr,
                        XX,
                        PZ,
                        BZ,
                        e,
                        bptr,
                        colix,
                        njobs,
                        ivkendog,
                        ivkexog,
                        ivkz
                    );

                    // singular =
                    //
                    // 0 | no issues detected
                    // 1 | collinear columns removed
                    // 2 | numerically zero determinant; no collinearity detected
                    // 3 | under-identified after collinearity check
                    // 4 | no usable columns (all numerically 0)

                    switch ( singular ) {
                        case 1:
                            warncollinear++;
                            break;
                        case 2:
                            warnsingular++;
                            break;
                        case 3:
                            warnivnotiden++;
                            for (k = 0; k < ivkss; k++) {
                                bptr[k]  = SV_missval;
                                septr[k] = SV_missval;
                            }
                            break;
                        case 4:
                            warnnocols++;
                            for (k = 0; k < ivkss; k++) {
                                bptr[k]  = SV_missval;
                                septr[k] = SV_missval;
                            }
                            break;
                    }

                    if ( singular != 3 && singular != 4 ) {
                        ixptr    = colix + 2 * ktot;
                        kmodel  -= (ivkss - ixptr[ivkss]);
                        ivkmixed = ixptr[ivkss + 1];
                        ivkdep   = (ivkendog - ixptr[ivkss + 2]);

                        // NOTE: If there were collinear endogenous covariates,
                        // they were projected continuously overriding ivendog.
                        // We _only_ make this adjustment when we have collinear
                        // endogenous vars, so we only adjust ivendog in this case.

                        gf_regress_ols_robust(
                            e,
                            wptr,
                            V,
                            VV,
                            ivendog + njobs * ivkdep,
                            XX,
                            septr,
                            ixptr,
                            njobs,
                            ivkmixed,
                            kmodel,
                            vceadj
                        );

                        // NOTE: To save some memory I use Xy as a buffer
                        if ( singular == 1 ) {
                            gf_regress_adjust_collinear_b  (bptr,  Xy, colix, ixptr[ivkss], ivkss);
                            gf_regress_adjust_collinear_se (septr, Xy, colix, ixptr[ivkss], ivkss);
                        }

                        // Need to copy back for two reasons:  Get back this
                        // _unprojected_ de-meaned endogenous variables _and_ if
                        // there were any collinear variables, leave them in their
                        // original position. Note that you need the projected
                        // non-collinar endogeous variables for the SE, so the
                        // memcpy has to go here, at the end.

                        if ( kabs && st_info->gregress_saveghdfe ) {
                            memcpy(ivendog, PZ, sizeof(ST_double) * N * ivkendog);
                        }
                    }

                    xptr  += njobs * kx;
                    yptr  += njobs;
                    wptr  += njobs;
                    bptr  += kv;
                    septr += kv;
                    ghptr  = AbsorbHashes;
                    for (k = 0; k < kabs; k++, ghptr++) {
                        GtoolsHashFreePartial(ghptr);
                        ghptr->offset += ghptr->nobs;
                    }
                }
            }
            else {

                // Homoskedastic errors
                // --------------------

                for (j = 0; j < J; j++) {
                    njobs   = nj[j];
                    kmodel  = kx;
                    ivendog = xptr;
                    ivexog  = ivendog + ivkendog * njobs;
                    ivzptr  = ivexog + ivkexog * njobs;
                    if ( kabs && (rc = gf_regress_absorb(AbsorbHashes,
                                                         GtoolsGroupByTransform,
                                                         GtoolsGroupByHDFE,
                                                         stats,
                                                         maps,
                                                         njobs,
                                                         kabs,
                                                         kx,
                                                         &kmodel,
                                                         njabsptr,
                                                         xptr,
                                                         yptr,
                                                         wptr,
                                                         xptr,
                                                         yptr,
                                                         1,
                                                         hdfetol)) ) {
                        goto exit;
                    }

                    // NOTE: Do this here since absorb automagically sets it using kx
                    kmodel -= ivkz;
                    if ( (rc = gf_regress_iv_notidentified(njobs, kabs, ivkendog, ivkexog, ivkz, kmodel, buf1, buf2, buf3)) ) {
                        goto exit;
                    }

                    // NOTE: ivendog gets _moved_ if there are collinear variables
                    singular = gf_regress_iv(
                        ivendog,
                        ivexog,
                        ivzptr,
                        yptr,
                        wptr,
                        XX,
                        PZ,
                        BZ,
                        e,
                        bptr,
                        colix,
                        njobs,
                        ivkendog,
                        ivkexog,
                        ivkz
                    );

                    // singular =
                    //
                    // 0 | no issues detected
                    // 1 | collinear columns removed
                    // 2 | numerically zero determinant; no collinearity detected
                    // 3 | under-identified after collinearity check
                    // 4 | no usable columns (all numerically 0)

                    switch ( singular ) {
                        case 1:
                            warncollinear++;
                            break;
                        case 2:
                            warnsingular++;
                            break;
                        case 3:
                            warnivnotiden++;
                            for (k = 0; k < ivkss; k++) {
                                bptr[k]  = SV_missval;
                                septr[k] = SV_missval;
                            }
                            break;
                        case 4:
                            warnnocols++;
                            for (k = 0; k < ivkss; k++) {
                                bptr[k]  = SV_missval;
                                septr[k] = SV_missval;
                            }
                            break;
                    }

                    if ( singular != 3 && singular != 4 ) {
                        ixptr    = colix + 2 * ktot;
                        kmodel  -= (ivkss - ixptr[ivkss]);
                        ivkmixed = ixptr[ivkss + 1];
                        // ivkdep   = (ivkendog - ixptr[ivkss + 2]);

                        gf_regress_ols_se(
                            e,
                            wptr,
                            XX,
                            septr,
                            ixptr,
                            njobs,
                            ivkmixed,
                            kmodel
                        );

                        // NOTE: To save some memory I use Xy as a buffer
                        if ( singular == 1 ) {
                            gf_regress_adjust_collinear_b  (bptr,  Xy, colix, ixptr[ivkss], ivkss);
                            gf_regress_adjust_collinear_se (septr, Xy, colix, ixptr[ivkss], ivkss);
                        }

                        // Need to copy back for two reasons:  Get back this
                        // _unprojected_ de-meaned endogenous variables _and_ if
                        // there were any collinear variables, leave them in their
                        // original position. Note that you need the projected
                        // non-collinar endogeous variables for the SE, so the
                        // memcpy has to go here, at the end.

                        if ( kabs && st_info->gregress_saveghdfe ) {
                            memcpy(ivendog, PZ, sizeof(ST_double) * N * ivkendog);
                        }
                    }

                    xptr  += njobs * kx;
                    yptr  += njobs;
                    wptr  += njobs;
                    bptr  += kv;
                    septr += kv;
                    ghptr  = AbsorbHashes;
                    for (k = 0; k < kabs; k++, ghptr++) {
                        GtoolsHashFreePartial(ghptr);
                        ghptr->offset += ghptr->nobs;
                    }
                }
            }
        }
        else {
            for (j = 0; j < J; j++) {
                njobs   = nj[j];
                kmodel  = kx;
                ivendog = xptr;
                ivexog  = ivendog + ivkendog * njobs;
                ivzptr  = ivexog + ivkexog * njobs;
                if ( kabs && (rc = gf_regress_absorb(AbsorbHashes,
                                                     GtoolsGroupByTransform,
                                                     GtoolsGroupByHDFE,
                                                     stats,
                                                     maps,
                                                     njobs,
                                                     kabs,
                                                     kx,
                                                     &kmodel,
                                                     njabsptr,
                                                     xptr,
                                                     yptr,
                                                     wptr,
                                                     xptr,
                                                     yptr,
                                                     1,
                                                     hdfetol)) ) {
                    goto exit;
                }
                // NOTE: Do this here since absorb automagically sets it using kx
                kmodel -= ivkz;
                if ( (rc = gf_regress_iv_notidentified(njobs, kabs, ivkendog, ivkexog, ivkz, kmodel, buf1, buf2, buf3)) ) {
                    goto exit;
                }

                // NOTE: ivendog gets _moved_ if there are collinear variables
                singular = gf_regress_iv(
                    ivendog,
                    ivexog,
                    ivzptr,
                    yptr,
                    wptr,
                    XX,
                    PZ,
                    BZ,
                    e,
                    bptr,
                    colix,
                    njobs,
                    ivkendog,
                    ivkexog,
                    ivkz
                );

                // singular =
                //
                // 0 | no issues detected
                // 1 | collinear columns removed
                // 2 | numerically zero determinant; no collinearity detected
                // 3 | under-identified after collinearity check
                // 4 | no usable columns (all numerically 0)

                switch ( singular ) {
                    case 1:
                        warncollinear++;
                        break;
                    case 2:
                        warnsingular++;
                        break;
                    case 3:
                        warnivnotiden++;
                        for (k = 0; k < ivkss; k++) {
                            bptr[k]  = SV_missval;
                        }
                        break;
                    case 4:
                        warnnocols++;
                        for (k = 0; k < ivkss; k++) {
                            bptr[k]  = SV_missval;
                        }
                        break;
                }

                if ( singular != 3 && singular != 4 ) {
                    // NOTE: To save some memory I use Xy as a buffer
                    if ( singular == 1 ) {
                        ixptr = colix + 2 * ktot;
                        gf_regress_adjust_collinear_b (bptr, Xy, colix, ixptr[ivkss], ivkss);
                    }

                    // Need to copy back for two reasons:  Get back this
                    // _unprojected_ de-meaned endogenous variables _and_ if
                    // there were any collinear variables, leave them in their
                    // original position.

                    if ( kabs && st_info->gregress_saveghdfe ) {
                        memcpy(ivendog, PZ, sizeof(ST_double) * N * ivkendog);
                    }
                }

                xptr  += njobs * kx;
                yptr  += njobs;
                wptr  += njobs;
                bptr  += kv;
                ghptr  = AbsorbHashes;
                for (k = 0; k < kabs; k++, ghptr++) {
                    GtoolsHashFreePartial(ghptr);
                    ghptr->offset += ghptr->nobs;
                }
            }
        }
    }
    else if ( runols && poisson ) {
        if ( runse ) {
            if ( kclus ) {

                // Cluster errors
                // --------------

                for (j = 0; j < J; j++) {
                    singular   = 0;
                    njobs      = nj[j];
                    iter       = 0;
                    diff       = 1;
                    panelsetup = 1;
                    xdmptr     = kabs? xdm: xptr;
                    gf_regress_poisson_init(yptr, wptr, mu, eta, dev, lhs, njobs);

                    while ( (++iter < poisiter) && (fabs(diff) > poistol) && (singular != 4) ) {
                        kmodel = kx;
                        if ( kabs && (rc = gf_regress_absorb(AbsorbHashes,
                                                             GtoolsGroupByTransform,
                                                             GtoolsGroupByHDFE,
                                                             stats,
                                                             maps,
                                                             njobs,
                                                             kabs,
                                                             kx,
                                                             &kmodel,
                                                             NULL,
                                                             xptr,
                                                             lhs,
                                                             mu,
                                                             xdmptr,
                                                             lhsdm,
                                                             panelsetup,
                                                             hdfetol)) ) {
                            goto exit;
                        }
                        if ( (rc = gf_regress_notidentified(njobs, kabs, kx, kmodel, buf1, buf2, buf3)) ) {
                            goto exit;
                        }
                        singular = gf_regress_ols(xdmptr, lhsdm, mu, XX, Xy, e, bptr, colix, njobs, kx);
                        diff     = gf_regress_poisson_iter(yptr, wptr, e, mu, eta, dev, dev0, lhs, njobs);
                        panelsetup = 0;
                    }

                    ClusterHash->nobs = njobs;
                    if ( (rc = GtoolsHashPanel(ClusterHash)) ) {
                        if ( rc == 17902 ) {
                            return (sf_oom_error("sf_regress", "ClusterHash"));
                        }
                        else {
                            goto exit;
                        }
                    }
                    *njclusptr = ClusterHash->nlevels;

                    // singular =
                    //
                    // 0 | no issues detected
                    // 1 | collinear columns removed
                    // 2 | numerically zero determinant; no collinearity detected
                    // 4 | no usable columns (all numerically 0)

                    switch ( singular ) {
                        case 1:
                            kmodel -= (kx - colix[kx]);
                            warncollinear++;
                            break;
                        case 2:
                            warnsingular++;
                            break;
                        case 4:
                            warnnocols++;
                            for (k = 0; k < kx; k++) {
                                bptr[k]  = SV_missval;
                                septr[k] = SV_missval;
                            }
                            break;
                    }

                    if ( singular != 4 ) {
                        if ( (rc = gf_regress_poisson_post(st_info->wcode, wptr, e, mu, njobs, diff, poistol, poisiter, buf1)) ) {
                            goto exit;
                        }

                        gf_regress_ols_cluster(
                            e,
                            mu,
                            ClusterHash->info,
                            ClusterHash->index,
                            ClusterHash->nlevels,
                            U,
                            ux,
                            V,
                            VV,
                            xdmptr,
                            XX,
                            septr,
                            colix,
                            njobs,
                            kx,
                            kmodel,
                            vceadj
                        );

                        // NOTE: To save some memory I use Xy as a buffer
                        if ( singular == 1 ) {
                            gf_regress_adjust_collinear_b  (bptr,  Xy, colix, colix[kx], kx);
                            gf_regress_adjust_collinear_se (septr, Xy, colix, colix[kx], kx);
                        }
                    }

                    GtoolsHashFreePartial(ClusterHash);
                    ClusterHash->offset += ClusterHash->nobs;

                    njclusptr++;
                    xptr  += njobs * kx;
                    yptr  += njobs;
                    wptr  += njobs;
                    bptr  += kx;
                    septr += kx;
                    ghptr  = AbsorbHashes;
                    for (k = 0; k < kabs; k++, ghptr++) {
                        GtoolsHashFreePartial(ghptr);
                        ghptr->offset += ghptr->nobs;
                    }
                }
            }
            else if ( st_info->gregress_robust ) {

                // Robust errors
                // -------------

                for (j = 0; j < J; j++) {
                    singular   = 0;
                    njobs      = nj[j];
                    iter       = 0;
                    diff       = 1;
                    panelsetup = 1;
                    xdmptr     = kabs? xdm: xptr;
                    gf_regress_poisson_init(yptr, wptr, mu, eta, dev, lhs, njobs);
                    while ( (++iter < poisiter) && (fabs(diff) > poistol) && (singular != 4) ) {
                        kmodel = kx;
                        if ( kabs && (rc = gf_regress_absorb(AbsorbHashes,
                                                             GtoolsGroupByTransform,
                                                             GtoolsGroupByHDFE,
                                                             stats,
                                                             maps,
                                                             njobs,
                                                             kabs,
                                                             kx,
                                                             &kmodel,
                                                             NULL,
                                                             xptr,
                                                             lhs,
                                                             mu,
                                                             xdmptr,
                                                             lhsdm,
                                                             panelsetup,
                                                             hdfetol)) ) {
                            goto exit;
                        }
                        if ( (rc = gf_regress_notidentified(njobs, kabs, kx, kmodel, buf1, buf2, buf3)) ) {
                            goto exit;
                        }
                        singular = gf_regress_ols(xdmptr, lhsdm, mu, XX, Xy, e, bptr, colix, njobs, kx);
                        diff     = gf_regress_poisson_iter(yptr, wptr, e, mu, eta, dev, dev0, lhs, njobs);
                        panelsetup = 0;
                    }

                    // singular =
                    //
                    // 0 | no issues detected
                    // 1 | collinear columns removed
                    // 2 | numerically zero determinant; no collinearity detected
                    // 4 | no usable columns (all numerically 0)

                    switch ( singular ) {
                        case 1:
                            kmodel -= (kx - colix[kx]);
                            warncollinear++;
                            break;
                        case 2:
                            warnsingular++;
                            break;
                        case 4:
                            warnnocols++;
                            for (k = 0; k < kx; k++) {
                                bptr[k]  = SV_missval;
                                septr[k] = SV_missval;
                            }
                            break;
                    }

                    if ( singular != 4 ) {
                        if ( (rc = gf_regress_poisson_post(st_info->wcode, wptr, e, mu, njobs, diff, poistol, poisiter, buf1)) ) {
                            goto exit;
                        }

                        gf_regress_ols_robust(
                            e,
                            mu,
                            V,
                            VV,
                            xdmptr,
                            XX,
                            septr,
                            colix,
                            njobs,
                            kx,
                            kmodel,
                            vceadj
                        );

                        // NOTE: To save some memory I use Xy as a buffer
                        if ( singular == 1 ) {
                            gf_regress_adjust_collinear_b  (bptr,  Xy, colix, colix[kx], kx);
                            gf_regress_adjust_collinear_se (septr, Xy, colix, colix[kx], kx);
                        }
                    }

                    xptr  += njobs * kx;
                    yptr  += njobs;
                    wptr  += njobs;
                    bptr  += kx;
                    septr += kx;
                    ghptr  = AbsorbHashes;
                    for (k = 0; k < kabs; k++, ghptr++) {
                        GtoolsHashFreePartial(ghptr);
                        ghptr->offset += ghptr->nobs;
                    }
                }
            }
            else {

                // Homoskedastic errors
                // --------------------

                for (j = 0; j < J; j++) {
                    singular   = 0;
                    njobs      = nj[j];
                    iter       = 0;
                    diff       = 1;
                    panelsetup = 1;
                    xdmptr     = kabs? xdm: xptr;
                    gf_regress_poisson_init(yptr, wptr, mu, eta, dev, lhs, njobs);

                    while ( (++iter < poisiter) && (fabs(diff) > poistol) && (singular != 4) ) {
                        kmodel = kx;
                        if ( kabs && (rc = gf_regress_absorb(AbsorbHashes,
                                                             GtoolsGroupByTransform,
                                                             GtoolsGroupByHDFE,
                                                             stats,
                                                             maps,
                                                             njobs,
                                                             kabs,
                                                             kx,
                                                             &kmodel,
                                                             NULL,
                                                             xptr,
                                                             lhs,
                                                             mu,
                                                             xdmptr,
                                                             lhsdm,
                                                             panelsetup,
                                                             hdfetol)) ) {
                            goto exit;
                        }
                        if ( (rc = gf_regress_notidentified(njobs, kabs, kx, kmodel, buf1, buf2, buf3)) ) {
                            goto exit;
                        }
                        singular = gf_regress_ols(xdmptr, lhsdm, mu, XX, Xy, e, bptr, colix, njobs, kx);
                        diff     = gf_regress_poisson_iter(yptr, wptr, e, mu, eta, dev, dev0, lhs, njobs);
                        panelsetup = 0;
                    }

                    // singular =
                    //
                    // 0 | no issues detected
                    // 1 | collinear columns removed
                    // 2 | numerically zero determinant; no collinearity detected
                    // 4 | no usable columns (all numerically 0)

                    switch ( singular ) {
                        case 1:
                            kmodel -= (kx - colix[kx]);
                            warncollinear++;
                            break;
                        case 2:
                            warnsingular++;
                            break;
                        case 4:
                            warnnocols++;
                            for (k = 0; k < kx; k++) {
                                bptr[k]  = SV_missval;
                                septr[k] = SV_missval;
                            }
                            break;
                    }

                    if ( singular != 4 ) {
                        if ( (rc = gf_regress_poisson_post(st_info->wcode, wptr, e, mu, njobs, diff, poistol, poisiter, buf1)) ) {
                            goto exit;
                        }

                        gf_regress_ols_se(
                            e,
                            mu,
                            XX,
                            septr,
                            colix,
                            njobs,
                            kx,
                            kmodel
                        );

                        // NOTE: To save some memory I use Xy as a buffer
                        if ( singular == 1 ) {
                            gf_regress_adjust_collinear_b  (bptr,  Xy, colix, colix[kx], kx);
                            gf_regress_adjust_collinear_se (septr, Xy, colix, colix[kx], kx);
                        }
                    }

                    xptr  += njobs * kx;
                    yptr  += njobs;
                    wptr  += njobs;
                    bptr  += kx;
                    septr += kx;
                    ghptr  = AbsorbHashes;
                    for (k = 0; k < kabs; k++, ghptr++) {
                        GtoolsHashFreePartial(ghptr);
                        ghptr->offset += ghptr->nobs;
                    }
                }
            }
        }
        else {
            for (j = 0; j < J; j++) {
                singular   = 0;
                njobs      = nj[j];
                iter       = 0;
                diff       = 1;
                panelsetup = 1;
                xdmptr     = kabs? xdm: xptr;
                gf_regress_poisson_init(yptr, wptr, mu, eta, dev, lhs, njobs);

                while ( (++iter < poisiter) && (fabs(diff) > poistol) && (singular != 4) ) {
                    kmodel = kx;
                    if ( kabs && (rc = gf_regress_absorb(AbsorbHashes,
                                                         GtoolsGroupByTransform,
                                                         GtoolsGroupByHDFE,
                                                         stats,
                                                         maps,
                                                         njobs,
                                                         kabs,
                                                         kx,
                                                         &kmodel,
                                                         NULL,
                                                         xptr,
                                                         lhs,
                                                         mu,
                                                         xdmptr,
                                                         lhsdm,
                                                         panelsetup,
                                                         hdfetol)) ) {
                        goto exit;
                    }
                    if ( (rc = gf_regress_notidentified(njobs, kabs, kx, kmodel, buf1, buf2, buf3)) ) {
                        goto exit;
                    }
                    singular = gf_regress_ols (xdmptr, lhsdm, mu, XX, Xy, e, bptr, colix, njobs, kx);
                    diff     = gf_regress_poisson_iter(yptr, wptr, e, mu, eta, dev, dev0, lhs, njobs);
                    panelsetup = 0;
                }

                // singular =
                //
                // 0 | no issues detected
                // 1 | collinear columns removed
                // 2 | numerically zero determinant; no collinearity detected
                // 4 | no usable columns (all numerically 0)

                switch ( singular ) {
                    case 1:
                        // kmodel -= (kx - colix[kx]);
                        warncollinear++;
                        break;
                    case 2:
                        warnsingular++;
                        break;
                    case 4:
                        warnnocols++;
                        for (k = 0; k < kx; k++) {
                            bptr[k] = SV_missval;
                        }
                        break;
                }

                if ( singular != 4 ) {
                    if ( (rc = gf_regress_poisson_post(st_info->wcode, wptr, e, mu, njobs, diff, poistol, poisiter, buf1)) ) {
                        goto exit;
                    }

                    // NOTE: To save some memory I use Xy as a buffer
                    if ( singular == 1 ) {
                        gf_regress_adjust_collinear_b (bptr, Xy, colix, colix[kx], kx);
                    }
                }

                xptr  += njobs * kx;
                yptr  += njobs;
                wptr  += njobs;
                bptr  += kx;
                ghptr  = AbsorbHashes;
                for (k = 0; k < kabs; k++, ghptr++) {
                    GtoolsHashFreePartial(ghptr);
                    ghptr->offset += ghptr->nobs;
                }
            }
        }

        if ( kabs && st_info->gregress_saveghdfe ) {
            xptr  = X;
            yptr  = y;
            wptr  = w;
            gf_regress_absorb_iter(
                AbsorbHashes,
                GtoolsGroupByTransform,
                GtoolsGroupByHDFE,
                stats,
                maps,
                J,
                nj,
                kabs,
                kx,
                njabsptr,
                xptr,
                yptr,
                wptr,
                hdfetol
            );
        }
    }
    else if ( runols ) {
        if ( runse ) {
            if ( kclus ) {

                // Cluster errors
                // --------------

                for (j = 0; j < J; j++) {
                    njobs  = nj[j];
                    kmodel = kx;
                    if ( kabs && (rc = gf_regress_absorb(AbsorbHashes,
                                                         GtoolsGroupByTransform,
                                                         GtoolsGroupByHDFE,
                                                         stats,
                                                         maps,
                                                         njobs,
                                                         kabs,
                                                         kx,
                                                         &kmodel,
                                                         njabsptr,
                                                         xptr,
                                                         yptr,
                                                         wptr,
                                                         xptr,
                                                         yptr,
                                                         1,
                                                         hdfetol)) ) {
                        goto exit;
                    }

                    if ( (rc = gf_regress_notidentified(njobs, kabs, kx, kmodel, buf1, buf2, buf3)) ) {
                        goto exit;
                    }
                    singular = gf_regress_ols(xptr, yptr, wptr, XX, Xy, e, bptr, colix, njobs, kx);

                    ClusterHash->nobs = njobs;
                    if ( (rc = GtoolsHashPanel(ClusterHash)) ) {
                        if ( rc == 17902 ) {
                            return (sf_oom_error("sf_regress", "ClusterHash"));
                        }
                        else {
                            goto exit;
                        }
                    }
                    *njclusptr = ClusterHash->nlevels;

                    // singular =
                    //
                    // 0 | no issues detected
                    // 1 | collinear columns removed
                    // 2 | numerically zero determinant; no collinearity detected
                    // 4 | no usable columns (all numerically 0)

                    switch ( singular ) {
                        case 1:
                            kmodel -= (kx - colix[kx]);
                            warncollinear++;
                            break;
                        case 2:
                            warnsingular++;
                            break;
                        case 4:
                            warnnocols++;
                            for (k = 0; k < kx; k++) {
                                bptr[k]  = SV_missval;
                                septr[k] = SV_missval;
                            }
                            break;
                    }

                    if ( singular != 4 ) {
                        gf_regress_ols_cluster(
                            e,
                            wptr,
                            ClusterHash->info,
                            ClusterHash->index,
                            ClusterHash->nlevels,
                            U,
                            ux,
                            V,
                            VV,
                            xptr,
                            XX,
                            septr,
                            colix,
                            njobs,
                            kx,
                            kmodel,
                            vceadj
                        );

                        // NOTE: To save some memory I use Xy as a buffer
                        if ( singular == 1 ) {
                            gf_regress_adjust_collinear_b  (bptr,  Xy, colix, colix[kx], kx);
                            gf_regress_adjust_collinear_se (septr, Xy, colix, colix[kx], kx);
                        }
                    }

                    GtoolsHashFreePartial(ClusterHash);
                    ClusterHash->offset += ClusterHash->nobs;

                    njclusptr++;
                    xptr  += njobs * kx;
                    yptr  += njobs;
                    wptr  += njobs;
                    bptr  += kx;
                    septr += kx;
                    ghptr  = AbsorbHashes;
                    for (k = 0; k < kabs; k++, ghptr++) {
                        GtoolsHashFreePartial(ghptr);
                        ghptr->offset += ghptr->nobs;
                    }
                }
            }
            else if ( st_info->gregress_robust ) {

                // Robust errors
                // -------------

                for (j = 0; j < J; j++) {
                    njobs  = nj[j];
                    kmodel = kx;
                    if ( kabs && (rc = gf_regress_absorb(AbsorbHashes,
                                                         GtoolsGroupByTransform,
                                                         GtoolsGroupByHDFE,
                                                         stats,
                                                         maps,
                                                         njobs,
                                                         kabs,
                                                         kx,
                                                         &kmodel,
                                                         njabsptr,
                                                         xptr,
                                                         yptr,
                                                         wptr,
                                                         xptr,
                                                         yptr,
                                                         1,
                                                         hdfetol)) ) {
                        goto exit;
                    }

                    if ( (rc = gf_regress_notidentified(njobs, kabs, kx, kmodel, buf1, buf2, buf3)) ) {
                        goto exit;
                    }
                    singular = gf_regress_ols (xptr, yptr, wptr, XX, Xy, e, bptr, colix, njobs, kx);

                    // singular =
                    //
                    // 0 | no issues detected
                    // 1 | collinear columns removed
                    // 2 | numerically zero determinant; no collinearity detected
                    // 4 | no usable columns (all numerically 0)

                    switch ( singular ) {
                        case 1:
                            kmodel -= (kx - colix[kx]);
                            warncollinear++;
                            break;
                        case 2:
                            warnsingular++;
                            break;
                        case 4:
                            warnnocols++;
                            for (k = 0; k < kx; k++) {
                                bptr[k]  = SV_missval;
                                septr[k] = SV_missval;
                            }
                            break;
                    }

                    if ( singular != 4 ) {
                        gf_regress_ols_robust(
                            e,
                            wptr,
                            V,
                            VV,
                            xptr,
                            XX,
                            septr,
                            colix,
                            njobs,
                            kx,
                            kmodel,
                            vceadj
                        );

                        // NOTE: To save some memory I use Xy as a buffer
                        if ( singular == 1 ) {
                            gf_regress_adjust_collinear_b  (bptr,  Xy, colix, colix[kx], kx);
                            gf_regress_adjust_collinear_se (septr, Xy, colix, colix[kx], kx);
                        }
                    }

                    xptr  += njobs * kx;
                    yptr  += njobs;
                    wptr  += njobs;
                    bptr  += kx;
                    septr += kx;
                    ghptr  = AbsorbHashes;
                    for (k = 0; k < kabs; k++, ghptr++) {
                        GtoolsHashFreePartial(ghptr);
                        ghptr->offset += ghptr->nobs;
                    }
                }
            }
            else {

                // Homoskedastic errors
                // --------------------

                for (j = 0; j < J; j++) {
                    njobs  = nj[j];
                    kmodel = kx;
                    if ( kabs && (rc = gf_regress_absorb(AbsorbHashes,
                                                         GtoolsGroupByTransform,
                                                         GtoolsGroupByHDFE,
                                                         stats,
                                                         maps,
                                                         njobs,
                                                         kabs,
                                                         kx,
                                                         &kmodel,
                                                         njabsptr,
                                                         xptr,
                                                         yptr,
                                                         wptr,
                                                         xptr,
                                                         yptr,
                                                         1,
                                                         hdfetol)) ) {
                        goto exit;
                    }

                    if ( (rc = gf_regress_notidentified(njobs, kabs, kx, kmodel, buf1, buf2, buf3)) ) {
                        goto exit;
                    }

                    singular = gf_regress_ols(xptr, yptr, wptr, XX, Xy, e, bptr, colix, njobs, kx);

                    // singular =
                    //
                    // 0 | no issues detected
                    // 1 | collinear columns removed
                    // 2 | numerically zero determinant; no collinearity detected
                    // 4 | no usable columns (all numerically 0)

                    switch ( singular ) {
                        case 1:
                            kmodel -= (kx - colix[kx]);
                            warncollinear++;
                            break;
                        case 2:
                            warnsingular++;
                            break;
                        case 4:
                            warnnocols++;
                            for (k = 0; k < kx; k++) {
                                bptr[k]  = SV_missval;
                                septr[k] = SV_missval;
                            }
                            break;
                    }

                    if ( singular != 4 ) {
                        gf_regress_ols_se(
                            e,
                            wptr,
                            XX,
                            septr,
                            colix,
                            njobs,
                            kx,
                            kmodel
                        );

                        // NOTE: To save some memory I use Xy as a buffer
                        if ( singular == 1 ) {
                            gf_regress_adjust_collinear_b  (bptr,  Xy, colix, colix[kx], kx);
                            gf_regress_adjust_collinear_se (septr, Xy, colix, colix[kx], kx);
                        }
                    }

                    xptr  += njobs * kx;
                    yptr  += njobs;
                    wptr  += njobs;
                    bptr  += kx;
                    septr += kx;
                    ghptr  = AbsorbHashes;
                    for (k = 0; k < kabs; k++, ghptr++) {
                        GtoolsHashFreePartial(ghptr);
                        ghptr->offset += ghptr->nobs;
                    }
                }
            }
        }
        else {
            for (j = 0; j < J; j++) {
                njobs  = nj[j];
                kmodel = kx;
                if ( kabs && (rc = gf_regress_absorb(AbsorbHashes,
                                                     GtoolsGroupByTransform,
                                                     GtoolsGroupByHDFE,
                                                     stats,
                                                     maps,
                                                     njobs,
                                                     kabs,
                                                     kx,
                                                     &kmodel,
                                                     njabsptr,
                                                     xptr,
                                                     yptr,
                                                     wptr,
                                                     xptr,
                                                     yptr,
                                                     1,
                                                     hdfetol)) ) {
                    goto exit;
                }

                if ( (rc = gf_regress_notidentified(njobs, kabs, kx, kmodel, buf1, buf2, buf3)) ) {
                    goto exit;
                }
                singular = gf_regress_ols (xptr, yptr, wptr, XX, Xy, e, bptr, colix, njobs, kx);

                // singular =
                //
                // 0 | no issues detected
                // 1 | collinear columns removed
                // 2 | numerically zero determinant; no collinearity detected
                // 4 | no usable columns (all numerically 0)

                switch ( singular ) {
                    case 1:
                        // kmodel -= (kx - colix[kx]);
                        warncollinear++;
                        break;
                    case 2:
                        warnsingular++;
                        break;
                    case 4:
                        warnnocols++;
                        for (k = 0; k < kx; k++) {
                            bptr[k] = SV_missval;
                        }
                        break;
                }

                // if ( singular != 4 ) {
                // }

                // NOTE: To save some memory I use Xy as a buffer
                if ( singular == 1 ) {
                    gf_regress_adjust_collinear_b (bptr, Xy, colix, colix[kx], kx);
                }

                xptr  += njobs * kx;
                yptr  += njobs;
                wptr  += njobs;
                bptr  += kx;
                ghptr  = AbsorbHashes;
                for (k = 0; k < kabs; k++, ghptr++) {
                    GtoolsHashFreePartial(ghptr);
                    ghptr->offset += ghptr->nobs;
                }
            }
        }
    }
    else if ( kabs && st_info->gregress_saveghdfe ) {
        xptr  = X;
        yptr  = y;
        wptr  = w;
        gf_regress_absorb_iter(
            AbsorbHashes,
            GtoolsGroupByTransform,
            GtoolsGroupByHDFE,
            stats,
            maps,
            J,
            nj,
            kabs,
            kx,
            njabsptr,
            xptr,
            yptr,
            wptr,
            hdfetol
        );
    }

    gf_regress_warnings(
        J,
        warncollinear,
        warnsingular,
        warnivnotiden,
        warnnocols,
        buf1,
        buf2,
        buf3,
        buf4
    );

    /******************
     *  Interval Foo  *
     ******************/
    // NOTE: This is quite complicated because the right thing to do is
    //     1. Sort (I, ix) = (I_s, ix_s) within group j
    //     2. Start with i = 0
    //     3. Figure out bounded range for i using I_s, l(i), u(i)
    //     4. Run OLS with
    //         4.1. N = u(i) - l(i) + 1
    //         4.2. index = ix_s + l(i)
    //     5. i++
    //     6. If i > nj, exit; otherwise go to step 3
    //
    // This is n + (n log n): For each group, you sort (n log n) and
    // then you N OLS operations. The easy way is insanely slow: For
    // each element in the group, figure out which obs are in range and
    // use those. That is n^2 and takes forever.
    /****************
     *  Moving Foo  *
     ****************/
    // NOTE: init output to missing
    // if ( (movupper < SV_missval) && (movlower < SV_missval) ) {
    //     for (i = 0; i < nj; i++) {
    //         if ( (movupper < movlower ) || (i + movlower < 0) || (i + movupper >= nj) ) {
    //             continue;
    //         }
    //         else {
    //             nmoving = (GT_size) (movupper - movlower + 1);
    //             _xptr = xptr + (i + movlower) * kx;
    //             _yptr = yptr + (i + movlower);
    //             _wptr = wptr + (i + movlower);
    //         }
    //     }
    // }
    // else if ( movupper < SV_missval ) {
    //     for (i = 0; i < nj; i++) {
    //         if ( i + movupper >= nj ) {
    //             continue;
    //         }
    //         else {
    //             nmoving = (GT_size) (i + movupper + 1);
    //         }
    //     }
    // }
    // else if ( movlower < SV_missval ) {
    //     for (i = 0; i < nj; i++) {
    //         if ( i + movlower < 0 ) {
    //             continue;
    //         }
    //         else {
    //             nmoving = (GT_size) (nj - (i + movlower));
    //             _xptr = xptr + (i + movlower) * kx;
    //             _yptr = yptr + (i + movlower);
    //             _wptr = wptr + (i + movlower);
    //         }
    //     }
    // }
    // else {
    //     for (i = 0; i < nj; i++) {
    //     }
    // }

    if ( st_info->benchmark > 1 )
        sf_running_timer (&timer, "\tregress step 2: Computed beta, se");

    /*********************************************************************
     *                Step 4: Write results back to Stata                *
     *********************************************************************/

    if ( st_info->gregress_savemata ) {
        if ( st_info->gregress_savemb ) {
            if ( (rc = SF_macro_use("GTOOLS_GREGB_FILE",  GTOOLS_GREGB_FILE,  st_info->gfile_gregb)  )) goto exit;

            fgregb = fopen(GTOOLS_GREGB_FILE,  "wb");
            rc = rc | (fwrite(b, sizeof(b), J * kv, fgregb) != (J * kv));
            fclose(fgregb);
        }

        if ( st_info->gregress_savemse ) {
            if ( (rc = SF_macro_use("GTOOLS_GREGSE_FILE", GTOOLS_GREGSE_FILE, st_info->gfile_gregse) )) goto exit;

            fgregse = fopen(GTOOLS_GREGSE_FILE, "wb");
            rc = rc | (fwrite(se, sizeof(se), J * kv, fgregse) != (J * kv));
            fclose(fgregse);
        }

        if ( kclus && runols && runse ) {
            if ( (rc = SF_macro_use("GTOOLS_GREGCLUS_FILE", GTOOLS_GREGCLUS_FILE, st_info->gfile_gregclus) )) goto exit;

            fgregclus = fopen(GTOOLS_GREGCLUS_FILE, "wb");
            rc = rc | (fwrite(njclus, sizeof(njclus), J, fgregclus) != J);
            fclose(fgregclus);
        }

        if ( kabs && (runols || runse || st_info->gregress_saveghdfe) ) {
            if ( (rc = SF_macro_use("GTOOLS_GREGABS_FILE", GTOOLS_GREGABS_FILE, st_info->gfile_gregabs) )) goto exit;

            fgregabs = fopen(GTOOLS_GREGABS_FILE, "wb");
            rc = rc | (fwrite(njabs, sizeof(njabs), J * kabs, fgregabs) != (J * kabs));
            fclose(fgregabs);
        }

        if ( rc )
            goto exit;

        if ( (rc = sf_byx_save_top (st_info, 0, NULL)) ) goto exit;
    }

    if ( st_info->gregress_savegb || st_info->gregress_savegse || st_info->gregress_saveghdfe ) {
        krefb    = st_info->kvars_by + st_info->gregress_kvars + kclus + kabs + 1;
        krefse   = st_info->kvars_by + st_info->gregress_kvars + kclus + kabs + 1 + kv * st_info->gregress_savegb;
        krefhdfe = st_info->kvars_by + st_info->gregress_kvars + kclus + kabs + 1 + kv * st_info->gregress_savegb + kv * st_info->gregress_savegse;

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
                // beta and SE only compute one coef per xendog, xexog
                if ( st_info->gregress_savegb ) {
                    for (k = 0; k < kv; k++) {
                        if ( (rc = SF_vstore(krefb + k, out, bptr[k])) ) goto exit;
                    }
                }
                if ( st_info->gregress_savegse ) {
                    for (k = 0; k < kv; k++) {
                        if ( (rc = SF_vstore(krefse + k, out, septr[k])) ) goto exit;
                    }
                }
                // However, de-meanining/de-hdfe happened for xendog, xexog, _and_ Z
                if ( st_info->gregress_saveghdfe ) {
                    if ( (rc = SF_vstore(krefhdfe, out, *yptr)) ) goto exit;
                    for (k = 0; k < kx; k++) {
                        if ( (rc = SF_vstore(krefhdfe + 1 + k, out, *(xptr + nj[l] * k))) ) goto exit;
                    }
                    xptr++;
                    yptr++;
                }
            }
            bptr  += kv;
            septr += kv;
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

    free(vars);
    free(e);
    free(Xy);
    free(b);
    free(se);
    free(XX);
    free(V);
    free(VV);
    free(nj);

    free(BZ);
    free(PZ);
    free(U);
    free(ux);
    free(G);
    free(FE);
    free(I);
    free(w);

    free(poisaux);
    free(xdm);
    free(njclus);
    free(njabs);
    free(clusinv);
    free(absinv);
    free(colix);

    return (rc);
}

ST_retcode gf_regress_absorb(
    struct GtoolsHash *AbsorbHashes,
    GtoolsGroupByTransform GtoolsGroupByTransform,
    GtoolsGroupByHDFE GtoolsGroupByHDFE,
    ST_double *stats,
    GT_size *maps,
    GT_size nj,
    GT_size kabs,
    GT_size kx,
    GT_size *kmodel,
    ST_double *njabsptr,
    ST_double *xptr,
    ST_double *yptr,
    ST_double *wptr,
    ST_double *xtarget,
    ST_double *ytarget,
    GT_bool setup,
    ST_double hdfetol)
{
    ST_retcode rc;
    GT_size k;
    struct GtoolsHash *ghptr;

    if ( kabs == 0 ) {
        return (0);
    }
    else if ( kabs == 1 ) {
        AbsorbHashes->nobs = nj;
        if ( setup && (rc = GtoolsHashPanel(AbsorbHashes)) ) {
            if ( rc == 17902 ) {
                return (sf_oom_error("sf_regress", "AbsorbHashes"));
            }
            else {
                return (rc);
            }
        }

        *kmodel = kx + AbsorbHashes->nlevels;
        if ( njabsptr != NULL ) {
            *njabsptr = AbsorbHashes->nlevels;
            njabsptr++;
        }

        GtoolsGroupByTransform(AbsorbHashes, stats, maps, xptr, wptr, xtarget, kx);
        GtoolsGroupByTransform(AbsorbHashes, stats, maps, yptr, wptr, ytarget, 1);
    }
    else if ( kabs > 1 ) {
        *kmodel = kx + 1;
        ghptr = AbsorbHashes;
        for (k = 0; k < kabs; k++, ghptr++) {
            ghptr->nobs = nj;
            if ( setup && (rc = GtoolsHashPanel(ghptr)) ) {
                if ( rc == 17902 ) {
                    return (sf_oom_error("sf_regress", "AbsorbHashes"));
                }
                else {
                    return (rc);
                }
            }
            *kmodel += ghptr->nlevels;
            if ( njabsptr != NULL ) {
                *njabsptr = ghptr->nlevels;
                njabsptr++;
            }
        }
        *kmodel -= kabs;

        GtoolsGroupByHDFE(AbsorbHashes, kabs, xptr, wptr, xtarget, kx, hdfetol);
        GtoolsGroupByHDFE(AbsorbHashes, kabs, yptr, wptr, ytarget, 1,  hdfetol);
    }

    return (0);
}

ST_retcode gf_regress_absorb_iter(
    struct GtoolsHash *AbsorbHashes,
    GtoolsGroupByTransform GtoolsGroupByTransform,
    GtoolsGroupByHDFE GtoolsGroupByHDFE,
    ST_double *stats,
    GT_size *maps,
    GT_size J,
    GT_size *nj,
    GT_size kabs,
    GT_size kx,
    ST_double *njabsptr,
    ST_double *xptr,
    ST_double *yptr,
    ST_double *wptr,
    ST_double hdfetol)
{
    ST_retcode rc = 0;
    GT_size j, k, njobs;
    struct GtoolsHash *ghptr;
    if ( kabs == 1 ) {
        for (j = 0; j < J; j++) {
            njobs = nj[j];
            AbsorbHashes->nobs = njobs;
            if ( (rc = GtoolsHashPanel(AbsorbHashes)) ) {
                if ( rc == 17902 ) {
                    return (sf_oom_error("sf_regress", "AbsorbHashes"));
                }
                else {
                    goto exit;
                }
            }
            *njabsptr = AbsorbHashes->nlevels;
            njabsptr++;

            GtoolsGroupByTransform (AbsorbHashes, stats, maps, xptr, wptr, xptr, kx);
            GtoolsGroupByTransform (AbsorbHashes, stats, maps, yptr, wptr, yptr, 1);

            GtoolsHashFreePartial (AbsorbHashes);
            AbsorbHashes->offset += AbsorbHashes->nobs;

            xptr += njobs * kx;
            yptr += njobs;
            wptr += njobs;
        }
    }
    else if ( kabs > 1 ) {
        for (j = 0; j < J; j++) {
            njobs = nj[j];
            ghptr = AbsorbHashes;
            for (k = 0; k < kabs; k++, ghptr++) {
                ghptr->nobs = njobs;
                if ( (rc = GtoolsHashPanel(ghptr)) ) {
                    if ( rc == 17902 ) {
                        return (sf_oom_error("sf_regress", "AbsorbHashes"));
                    }
                    else {
                        goto exit;
                    }
                }
                *njabsptr = ghptr->nlevels;
                njabsptr++;
            }

            GtoolsGroupByHDFE(AbsorbHashes, kabs, xptr, wptr, xptr, kx, hdfetol);
            GtoolsGroupByHDFE(AbsorbHashes, kabs, yptr, wptr, yptr, 1,  hdfetol);

            ghptr = AbsorbHashes;
            for (k = 0; k < kabs; k++, ghptr++) {
                GtoolsHashFreePartial(ghptr);
                ghptr->offset += ghptr->nobs;
            }
            xptr += njobs * kx;
            yptr += njobs;
            wptr += njobs;
        }
    }

exit:
    return (rc);
}

ST_retcode gf_regress_iv_notidentified (
    GT_size nj,
    GT_size kabs,
    GT_size ivkendog,
    GT_size ivkexog,
    GT_size ivkz,
    GT_size kmodel,
    char *buf1,
    char *buf2,
    char *buf3)
{
    if ( (kmodel < nj) && ((kmodel + ivkz - ivkendog) < nj) ) {
        return(0);
    }
    else {
        if ( (kmodel + ivkz - ivkendog) >= nj ) {
            sf_format_size(nj, buf1);
            sf_format_size((kmodel + ivkz - ivkendog), buf2);
            if ( kabs ) {
                sf_format_size((kmodel + kabs - ivkendog - ivkexog - 1), buf3);
                sf_errprintf("insufficient observations (%s) for the first stage: %s variables and %s absorb levels\n",
                             buf1, buf2, buf3);
            }
            else {
                sf_errprintf("insufficient observations (%s) for the first stage: for %s variables\n",
                             buf1, buf2);
            }
        }

        if ( kmodel >= nj ) {
            sf_format_size(nj, buf1);
            sf_format_size(kmodel, buf2);
            if ( kabs ) {
                sf_format_size((kmodel + kabs - ivkendog - ivkexog - 1), buf3);
                sf_errprintf("insufficient observations (%s) for the second stage: %s variables and %s absorb levels\n",
                             buf1, buf2, buf3);
            }
            else {
                sf_errprintf("insufficient observations (%s) for the second stage: for %s variables\n",
                             buf1, buf2);
            }
        }

        return(18401);
    }
}

ST_retcode gf_regress_notidentified (
    GT_size nj,
    GT_size kabs,
    GT_size kx,
    GT_size kmodel,
    char *buf1,
    char *buf2,
    char *buf3)
{
    if ( kmodel < nj ) {
        return(0);
    }
    else {
        sf_format_size(nj, buf1);
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
        return(18401);
    }
}

void gf_regress_warnings (
    GT_size J,
    GT_size warncollinear,
    GT_size warnsingular,
    GT_size warnivnotiden,
    GT_size warnnocols,
    char *buf1,
    char *buf2,
    char *buf3,
    char *buf4)
{
    if ( warncollinear ) {
        if ( J > 1 ) {
            sf_format_size(warncollinear, buf1);
            if ( warncollinear > 1 ) {
                sf_printf("collinearity warning: collinear columns dropped in %s groups\n", buf1);
            }
            else {
                sf_printf("collinearity warning: collinear columns dropped in %s group\n", buf1);
            }
        }
        else {
            sf_printf("collinearity warning: collinear columns automatically dropped.\n");
        }
    }

    if ( warnsingular ) {
        sf_printf("singularity warning: collinear columns not detected but matrix\n");
        if ( J > 1 ) {
            sf_format_size(warnsingular, buf2);
            if ( warncollinear > 1 ) {
                sf_printf("determinant numerically zero (< %.8g) in %s group\n",
                             GTOOLS_64BIT_EPSILON, buf2);
            }
            else {
                sf_printf("determinant numerically zero (< %.8g) in %s group\n",
                             GTOOLS_64BIT_EPSILON, buf2);
            }
        }
        else {
            sf_printf("determinant numerically zero (< %.8g)\n", GTOOLS_64BIT_EPSILON);
        }
    }


    if ( warnivnotiden ) {
        if ( J > 1 ) {
            sf_format_size(warnivnotiden, buf3);
            if ( warnivnotiden > 1 ) {
                sf_printf("identification warning: In %s groups, model not identified after\n", buf3);
            }
            else {
                sf_printf("identification warning: In %s group, model not identified after\n", buf3);
            }
            sf_printf("removing collinear columns (# of endogenous > # instruments)\n");
        }
        else {
            sf_printf("identification warning: # of endogenous > # instruments after collinearity check\n");
        }
    }

    if ( warnnocols ) {
        if ( J > 1 ) {
            sf_format_size(warnnocols, buf4);
            if ( warnnocols > 1 ) {
                sf_printf("identification warning: Unable to compute estimates in %s groups; all", buf4);
            }
            else {
                sf_printf("identification warning: Unable to compute estimates in %s group; all\n", buf4);
            }
            sf_printf("covariates were numerically zero\n");
        }
        else {
            sf_printf("identification warning: Unable to compute estimates; all covariates numerically zero\n");
        }
    }
}

void gf_regress_adjust_collinear_b (
    ST_double *b,
    ST_double *buffer,
    GT_size *colix,
    GT_size k1,
    GT_size k2)
{
    GT_size j;
    memcpy(buffer, b, sizeof(ST_double) * k1);
    memset(b, '\0', sizeof(ST_double) * k2);
    for (j = 0; j < k1; j++) {
        b[colix[j]] = buffer[j];
    }
}

void gf_regress_adjust_collinear_se (
    ST_double *se,
    ST_double *buffer,
    GT_size *colix,
    GT_size k1,
    GT_size k2)
{
    GT_size j;
    memcpy(buffer, se, sizeof(ST_double) * k1);
    for (j = 0; j < k2; j++) {
        se[j] = SV_missval;
    }
    for (j = 0; j < k1; j++) {
        se[colix[j]] = buffer[j];
    }
}
