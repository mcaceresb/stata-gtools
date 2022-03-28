/**********************************************************************
 *                     Berge with Irons and Tuck                      *
 **********************************************************************/

// NB: This fails with segfault. I can't be bothered to debug;
// it doesn't seem to make things all that much faster in this
// implementation, if at all. I disallow it from the top-level call.

// one advantage of Berge's method is that all the ancillary variables
// created don't need to be N by k, but #absorb levels by k.
GT_int GtoolsAlgorithmBergeIronsTuck(
    struct GtoolsHash *GtoolsHashInfo,
    GT_size   khashes,
    ST_double *sources,
    ST_double *weights,
    ST_double *targets,
    GT_size   ktargets,
    ST_double tol)
{
    GT_int rc = 0;
    struct GtoolsHash *ghptr = GtoolsHashInfo;
    GT_size maxiter = GtoolsHashInfo->hdfeMaxIter;
    GT_bool verbose = GtoolsHashInfo->hdfeTraceIter;

    ST_double diff, step[ktargets], DgXD2X[ktargets], D2XD2X[ktargets];
    ST_double *xptr, *gXptr, *ggXptr, *DXptr, *DgXptr, *D2Xptr, *x = targets;
    GT_size i, k, iter = 0, feval = 0;
    GT_size N = 0;
    for (k = 0; k < khashes; k++, ghptr++) {
        N += ghptr->nlevels;
    }
    GT_size bufferk = (weights == NULL? 3: 4) * (GTOOLSOMP? ktargets: 1) * N;

    ST_double *g   = calloc(ktargets * N, sizeof *g);
    ST_double *gX  = calloc(ktargets * N, sizeof *gX);
    ST_double *ggX = calloc(ktargets * N, sizeof *ggX);
    ST_double *DX  = calloc(ktargets * N, sizeof *DX);
    ST_double *DgX = calloc(ktargets * N, sizeof *DgX);
    ST_double *D2X = calloc(ktargets * N, sizeof *D2X);
    ST_double *b   = calloc(bufferk,      sizeof *b);

    if ( gX  == NULL ) return(17902);
    if ( ggX == NULL ) return(17902);
    if ( DX  == NULL ) return(17902);
    if ( DgX == NULL ) return(17902);
    if ( D2X == NULL ) return(17902);
    if ( b   == NULL ) return(17902);

    // b[0] = g = 0
    // b[1] = T(b[0])
    // gX   = b[1]
    memset(b, '\0', sizeof(b) * ktargets * N);
    memset(g, '\0', sizeof(b) * ktargets * N);
    diff = GtoolsAbsorbBerge(GtoolsHashInfo, khashes, sources, weights, x, ktargets, tol, b); feval++;
    memcpy(gX, b + ktargets * N * 1, sizeof(b) * ktargets * N);

    while ( ((iter++ < maxiter)? 1: maxiter == 0) && (diff > tol) ) {

        // b[0] = gX
        // b[1] = T(b[0])
        // ggX  = b[1]
        memcpy(b, gX, sizeof(b) * ktargets * N);
        diff = GtoolsAbsorbBerge(GtoolsHashInfo, khashes, x, weights, x, ktargets, tol, b); feval++;
        memcpy(ggX, b + ktargets * N * 1, sizeof(b) * ktargets * N);
        if ( verbose > 0 ) printf("\tBIT ("GT_size_cfmt"): |x - x'| = %.9g\n", iter, diff);
        if ( diff < tol ) break;

        xptr   = g;
        gXptr  = gX;
        ggXptr = ggX;
        DXptr  = DX;
        DgXptr = DgX;
        D2Xptr = D2X;
        for (k = 0; k < ktargets; k++, xptr += N, gXptr += N, ggXptr += N, DXptr += N, DgXptr += N, D2Xptr += N) {
            step[k]   = 0;
            DgXD2X[k] = 0;
            D2XD2X[k] = 0;
            for (i = 0; i < N; i++) {
                DXptr[i]  = gXptr[i]  - xptr[i];
                DgXptr[i] = ggXptr[i] - gXptr[i];
                D2Xptr[i] = DgXptr[i] - DXptr[i];
            }
            DgXD2X[k] = GtoolsStatsDot(DgXptr, D2Xptr, N, weights);
            D2XD2X[k] = GtoolsStatsSS(D2Xptr, N, weights);
            step[k]   = GtoolsStatsDivide(DgXD2X[k], D2XD2X[k]);
        }

        xptr   = g;
        ggXptr = ggX;
        DgXptr = DgX;
        for (k = 0; k < ktargets; k++, xptr += N, ggXptr += N, DgXptr += N) {
            for (i = 0; i < N; i++) {
                xptr[i] = ggXptr[i] - step[k] * DgXptr[i];
            }
        }

        // b[0] = g
        // b[1] = T(b[0])
        // gX   = b[1]
        memcpy(b, g, sizeof(b) * ktargets * N);
        diff = GtoolsAbsorbBerge(GtoolsHashInfo, khashes, x, weights, x, ktargets, tol, b); feval++;
        memcpy(gX, b + ktargets * N * 1, sizeof(b) * ktargets * N);
        if ( verbose > 0 ) printf("\tBIT ("GT_size_cfmt"): |x - x'| = %.9g\n", iter, diff);
        if ( diff < tol ) break;
    }

    GtoolsHashInfo->hdfeIter  = --iter;
    GtoolsHashInfo->hdfeFeval = feval;

    if ( verbose > 0 ) printf("BIT: "GT_size_cfmt" iter ("GT_size_cfmt" max), "GT_size_cfmt" feval, %.9g diff (%.9g tol)\n",
                              iter, maxiter, feval, diff, tol);

    if ( maxiter && iter >= maxiter ) rc = 18402;

    free(g);
    free(gX);
    free(ggX);
    free(DX);
    free(DgX);
    free(D2X);
    free(b);

    return(rc);
}

/**********************************************************************
 *                             Internals                              *
 **********************************************************************/

ST_double GtoolsAbsorbBerge(
    struct GtoolsHash *GtoolsHashInfo,
    GT_size   khashes,
    ST_double *sources,
    ST_double *weights,
    ST_double *targets,
    GT_size   ktargets,
    ST_double tol,
    ST_double *allbuffer)
{
    if ( weights == NULL ) {
        return (GtoolsAbsorbBergeUnweighted(
            GtoolsHashInfo,
            khashes,
            sources,
            weights,
            targets,
            ktargets,
            tol,
            allbuffer
        ));
    }
    else {
        return (GtoolsAbsorbBergeWeighted(
            GtoolsHashInfo,
            khashes,
            sources,
            weights,
            targets,
            ktargets,
            tol,
            allbuffer
        ));
    }
}

ST_double GtoolsAbsorbBergeUnweighted(
    struct GtoolsHash *GtoolsHashInfo,
    GT_size   khashes,
    ST_double *sources,
    ST_double *weights,
    ST_double *targets,
    GT_size   ktargets,
    ST_double tol,
    ST_double *allbuffer)
{

    GT_bool update;
    GT_size i, j, k, l, ntot = 0;
    GT_size nonmiss = GtoolsHashInfo->_nobspanel;
    GT_size N = GtoolsHashInfo->nobs;
    ST_double *srcptr, *trgptr;
    ST_double diff[ktargets];
    struct GtoolsHash *ghptr = GtoolsHashInfo;;
    for (l = 0; l < khashes; l++, ghptr++) {
        ntot += ghptr->nlevels;
    }

    ST_double *Gsrc   = allbuffer + ktargets * ntot * 0;
    ST_double *Gtrg   = allbuffer + ktargets * ntot * 1;
    ST_double *buffer = allbuffer + ktargets * ntot * 2;
    memset(Gtrg, '\0', sizeof(Gtrg) * ktargets * ntot);

    // NB: This criterion is looking for largest deviation in any given
    // FE projection; if two FE projections cancel out, basically, it
    // would take the largest, not the sum. Is it better? Unsure. Improve
    // convergence criterion when you get the chance.

    for (k = 0; k < ktargets; k++) {
        diff[k] = 0;
        srcptr  = sources + k * N;
        trgptr  = targets + k * N;
        ghptr   = GtoolsHashInfo;
        update  = 0;
        for (l  = 0; l < khashes; l++, ghptr++) {

            // compute sums
            if ( update ) {
                for (i = 0; i < nonmiss; i++) {
                    Gtrg[ghptr->indexj[i]] += trgptr[i] + Gsrc[ghptr->indexj[i]];
                }
            }
            else {
                for (i = 0; i < nonmiss; i++) {
                    Gtrg[ghptr->indexj[i]] += srcptr[i] + Gsrc[ghptr->indexj[i]];
                }
            }

            // make means
            for (j = 0; j < ghptr->nlevels; j++) {
                Gtrg[j]  /= ghptr->nj[j];
                buffer[j] = Gsrc[j] - Gtrg[j];
                diff[k]   = GTOOLS_PWMAX(diff[k], fabs(buffer[j]));
            }

            // update target
            if ( update ) {
                for (i = 0; i < nonmiss; i++) {
                    trgptr[i] += buffer[ghptr->indexj[i]];
                }
            }
            else {
                for (i = 0; i < nonmiss; i++) {
                    trgptr[i] = srcptr[i] + buffer[ghptr->indexj[i]];
                }
            }

            update = 1;

            Gsrc += ghptr->nlevels;
            Gtrg += ghptr->nlevels;
        }
    }

    return (ktargets? GtoolsStatsMax(diff, ktargets): 0);
}

ST_double GtoolsAbsorbBergeWeighted(
    struct GtoolsHash *GtoolsHashInfo,
    GT_size   khashes,
    ST_double *sources,
    ST_double *weights,
    ST_double *targets,
    GT_size   ktargets,
    ST_double tol,
    ST_double *allbuffer)
{
    GT_bool update;
    GT_size i, j, k, l, ntot = 0;
    GT_size nonmiss = GtoolsHashInfo->_nobspanel;
    GT_size N = GtoolsHashInfo->nobs;
    ST_double *srcptr, *trgptr;
    ST_double diff[ktargets];
    struct GtoolsHash *ghptr = GtoolsHashInfo;;
    for (l = 0; l < khashes; l++, ghptr++) {
        ntot += ghptr->nlevels;
    }

    ST_double *Gsrc    = allbuffer + ktargets * ntot * 0;
    ST_double *Gtrg    = allbuffer + ktargets * ntot * 1;
    ST_double *buffer  = allbuffer + ktargets * ntot * 2;
    ST_double *wbuffer = allbuffer + ktargets * ntot * 3;
    memset(Gtrg, '\0', sizeof(Gtrg) * ktargets * ntot);

    // NB: This criterion is looking for largest deviation in any given
    // FE projection; if two FE projections cancel out, basically, it
    // would take the largest, not the sum. Is it better? Unsure. Improve
    // convergence criterion when you get the chance.

    for (k = 0; k < ktargets; k++) {
        diff[k] = 0;
        srcptr  = sources + k * N;
        trgptr  = targets + k * N;
        ghptr   = GtoolsHashInfo;
        update  = 0;
        for (l  = 0; l < khashes; l++, ghptr++) {

            // compute sums
            if ( update ) {
                for (i = 0; i < nonmiss; i++) {
                    Gtrg[ghptr->indexj[i]]    += weights[i] * (trgptr[i] + Gsrc[ghptr->indexj[i]]);
                    wbuffer[ghptr->indexj[i]] += weights[i];
                }
            }
            else {
                for (i = 0; i < nonmiss; i++) {
                    Gtrg[ghptr->indexj[i]]    += weights[i] * (srcptr[i] + Gsrc[ghptr->indexj[i]]);
                    wbuffer[ghptr->indexj[i]] += weights[i];
                }
            }

            // make means
            for (j = 0; j < ghptr->nlevels; j++) {
                Gtrg[j]  /= wbuffer[j];
                buffer[j] = Gsrc[j] - Gtrg[j];
                diff[k]   = GTOOLS_PWMAX(diff[k], fabs(buffer[j]));
            }

            // update target
            if ( update ) {
                for (i = 0; i < nonmiss; i++) {
                    trgptr[i] += buffer[ghptr->indexj[i]];
                }
            }
            else {
                for (i = 0; i < nonmiss; i++) {
                    trgptr[i] = srcptr[i] + buffer[ghptr->indexj[i]];
                }
            }

            update = 1;

            // NB: This is an offset so it's actually non-trivial to
            // parallelize; not difficult at all, mind you, but not trivial.
            Gsrc += ghptr->nlevels;
            Gtrg += ghptr->nlevels;
        }
    }

    return (ktargets? GtoolsStatsMax(diff, ktargets): 0);
}
