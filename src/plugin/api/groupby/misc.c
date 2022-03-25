/**********************************************************************
 *                                HDFE                                *
 **********************************************************************/

// Note: The unweighted versions take weights so I can define them
// generically in higher-level functions. The unweighted versions can
// then take in a weight as an argument but ignore it.
//
// However, this is annoying since I'm just duplicating LoC. I really
// should move to passing NULL as weights in cases when they are not
// needed. Then internally here I could do weights == NULL? xx: xx

void GtoolsGroupByHDFEUnweighted(
    struct GtoolsHash *GtoolsHashInfo,
    GT_size   khashes,
    ST_double *sources,
    ST_double *weights,
    ST_double *targets,
    GT_size   ktargets,
    ST_double tol)
{

    GT_size iter = 0, feval = 0;
    ST_double diff = 1;
    GT_size maxiter = GtoolsHashInfo->hdfeMaxIter;
    GT_size verbose = GtoolsHashInfo->hdfeTraceIter;

    while ( ((iter++ < maxiter)? 1: maxiter == 0) && (diff > tol) ) {
        // Note: It's important to apply every level; else nested levels
        // might effect the algorithm to exit prematurely.
        diff = GtoolsGroupByHalperinUnweighted(GtoolsHashInfo, khashes, sources, weights, targets, ktargets, tol);
        feval++;
        if ( verbose > 0 ) printf("\tMAP (%lu): |x - x'| = %.9g\n", iter, diff);
    }

    GtoolsHashInfo->hdfeIter  = --iter;
    GtoolsHashInfo->hdfeFeval = feval;

    if ( verbose > 0 ) printf("MAP: %lu iter (%lu max), %lu feval, %.9g diff (%.9g tol)\n",
                              iter, maxiter, feval, diff, tol);

    if ( maxiter && iter >= maxiter ) GtoolsHashInfo->hdfeRc = 18402;
}

void GtoolsGroupByHDFEWeighted (
    struct GtoolsHash *GtoolsHashInfo,
    GT_size   khashes,
    ST_double *sources,
    ST_double *weights,
    ST_double *targets,
    GT_size   ktargets,
    ST_double tol)
{
    GT_size iter = 0, feval = 0;
    ST_double diff = 1;
    GT_size maxiter = GtoolsHashInfo->hdfeMaxIter;
    GT_size verbose = GtoolsHashInfo->hdfeTraceIter;
    while ( ((iter++ < maxiter)? 1: maxiter == 0) && (diff > tol) ) {
        // Note: It's important to apply every level; else nested levels
        // might effect the algorithm to exit prematurely.
        diff = GtoolsGroupByHalperinWeighted(GtoolsHashInfo, khashes, sources, weights, targets, ktargets, tol);
        feval++;
        if ( verbose > 0 ) printf("\tMAP (%lu): |x - x'| = %.9g\n", iter, diff);
    }

    GtoolsHashInfo->hdfeIter  = --iter;
    GtoolsHashInfo->hdfeFeval = feval;

    if ( verbose > 0 ) printf("MAP: %lu iter (%lu max), %lu feval, %.9g diff (%.9g tol)\n",
                              iter, maxiter, feval, diff, tol);

    if ( maxiter && iter >= maxiter ) GtoolsHashInfo->hdfeRc = 18402;
}

ST_double GtoolsGroupByHalperinUnweighted(
    struct GtoolsHash *GtoolsHashInfo,
    GT_size   khashes,
    ST_double *sources,
    ST_double *weights,
    ST_double *targets,
    GT_size   ktargets,
    ST_double tol)
{
    GT_bool update;
    GT_size i, j, k, l, m, start, nj, *ixptr;
    ST_double mean, *srcptr, *trgptr;
    ST_double diff = 1;
    struct GtoolsHash *ghptr;

    update = 0;
    ghptr  = GtoolsHashInfo;
    for (l = 0; l < khashes; l++, ghptr++) {
        diff = 0;
        for (j = 0; j < ghptr->nlevels; j++) {
            start  = ghptr->info[j];
            nj     = ghptr->info[j + 1] - start;
            ixptr  = ghptr->index + start;
            srcptr = update? targets: sources;
            trgptr = targets;
            for (k = 0; k < ktargets; k++, srcptr += ghptr->nobs, trgptr += ghptr->nobs) {
                mean = GtoolsStatsMean(srcptr, ixptr, nj);
                diff = GTOOLS_PWMAX(diff, fabs(mean));
                for (i = 0; i < nj; i++) {
                    m = ixptr[i];
                    trgptr[m] = srcptr[m] - mean;
                }
            }
        }
        update = 1;
    }

    return (diff);
}

ST_double GtoolsGroupByHalperinWeighted(
    struct GtoolsHash *GtoolsHashInfo,
    GT_size   khashes,
    ST_double *sources,
    ST_double *weights,
    ST_double *targets,
    GT_size   ktargets,
    ST_double tol)
{
    GT_bool update;
    GT_size i, j, k, l, m, start, nj, *ixptr;
    ST_double mean, *srcptr, *trgptr;
    struct GtoolsHash *ghptr;
    ST_double diff = 1;

    update = 0;
    ghptr  = GtoolsHashInfo;
    for (l = 0; l < khashes; l++, ghptr++) {
        diff = 0;
        for (j = 0; j < ghptr->nlevels; j++) {
            start  = ghptr->info[j];
            nj     = ghptr->info[j + 1] - start;
            ixptr  = ghptr->index + start;
            srcptr = update? targets: sources;
            trgptr = targets;
            for (k = 0; k < ktargets; k++, srcptr += ghptr->nobs, trgptr += ghptr->nobs) {
                mean = GtoolsStatsMeanWeighted(srcptr, weights, ixptr, nj);
                diff = GTOOLS_PWMAX(diff, fabs(mean));
                for (i = 0; i < nj; i++) {
                    m = ixptr[i];
                    trgptr[m] = srcptr[m] - mean;
                }
            }
        }
        update = 1;
    }

    return (diff);
}

ST_double GtoolsGroupByHalperinSymmUnweighted(
    struct GtoolsHash *GtoolsHashInfo,
    GT_size   khashes,
    ST_double *sources,
    ST_double *weights,
    ST_double *targets,
    GT_size   ktargets,
    ST_double tol)
{
    GT_bool update;
    GT_size i, j, k, l, m, start, nj, *ixptr;
    ST_double mean, *srcptr, *trgptr;
    ST_double diff = 1;
    struct GtoolsHash *ghptr;

    l = 0;
    update = 0;
    ghptr  = GtoolsHashInfo;

    // Should loop l + 1 = 1, ..., khashes - 1, khashes, khashes - 1, ..., 1
    while (l < (khashes + (khashes - 1))) {
        diff = 0;
        for (j = 0; j < ghptr->nlevels; j++) {
            start  = ghptr->info[j];
            nj     = ghptr->info[j + 1] - start;
            ixptr  = ghptr->index + start;
            srcptr = update? targets: sources;
            trgptr = targets;
            for (k = 0; k < ktargets; k++, srcptr += ghptr->nobs, trgptr += ghptr->nobs) {
                mean = GtoolsStatsMean(srcptr, ixptr, nj);
                diff = GTOOLS_PWMAX(diff, fabs(mean));
                for (i = 0; i < nj; i++) {
                    m = ixptr[i];
                    trgptr[m] = srcptr[m] - mean;
                }
            }
        }
        update = 1;
        ++l < khashes? ghptr++: ghptr--;
    }

    return (diff);
}

ST_double GtoolsGroupByHalperinSymmWeighted(
    struct GtoolsHash *GtoolsHashInfo,
    GT_size   khashes,
    ST_double *sources,
    ST_double *weights,
    ST_double *targets,
    GT_size   ktargets,
    ST_double tol)
{
    GT_bool update;
    GT_size i, j, k, l, m, start, nj, *ixptr;
    ST_double mean, *srcptr, *trgptr;
    struct GtoolsHash *ghptr;
    ST_double diff = 1;

    l = 0;
    update = 0;
    ghptr  = GtoolsHashInfo;

    // Should loop l + 1 = 1, ..., khashes - 1, khashes, khashes - 1, ..., 1
    while (l < (khashes + (khashes - 1))) {
        diff = 0;
        for (j = 0; j < ghptr->nlevels; j++) {
            start  = ghptr->info[j];
            nj     = ghptr->info[j + 1] - start;
            ixptr  = ghptr->index + start;
            srcptr = update? targets: sources;
            trgptr = targets;
            for (k = 0; k < ktargets; k++, srcptr += ghptr->nobs, trgptr += ghptr->nobs) {
                mean = GtoolsStatsMeanWeighted(srcptr, weights, ixptr, nj);
                diff = GTOOLS_PWMAX(diff, fabs(mean));
                for (i = 0; i < nj; i++) {
                    m = ixptr[i];
                    trgptr[m] = srcptr[m] - mean;
                }
            }
        }
        update = 1;
        ++l < khashes? ghptr++: ghptr--;
    }

    return (diff);
}

// void GtoolsGroupByHDFEWeighted (
//     struct GtoolsHash *GtoolsHashInfo,
//     GT_size   khashes,
//     ST_double *sources,
//     ST_double *weights,
//     ST_double *targets,
//     GT_size   ktargets,
//     ST_double tol)
// {
//     GT_size i, j, k, l, start, nj, *ixptr;
//     ST_double diff, *trgptr, *wptr;
//     struct GtoolsHash *ghptr;
//     memcpy(targets, sources, GtoolsHashInfo->nobs * ktargets * sizeof(ST_double));
//
//     ST_double *wmeans = calloc(GtoolsHashInfo->nobs, sizeof *wmeans);
//     ST_double *wsums  = calloc(GtoolsHashInfo->nobs, sizeof *wmeans);
//     GT_size   *wx     = calloc(GtoolsHashInfo->nobs, sizeof *wx);
//
//     diff = 1;
//     while ( diff > tol ) {
//         ghptr = GtoolsHashInfo;
//         for (l = 0; l < khashes; l++, ghptr++) {
//             diff = 0;
//             for (j = 0; j < ghptr->nlevels; j++) {
//                 start  = ghptr->info[j];
//                 nj     = ghptr->info[j + 1] - start;
//                 ixptr  = ghptr->index + start;
//                 for (i = 0; i < nj; i++) {
//                     wx[ixptr[i]] = j;
//                 }
//             }
//             for (k = 0; k < ktargets; k++) {
//                 wptr   = weights;
//                 trgptr = targets + k * ghptr->nobs;
//                 memset(wsums, '\0', ghptr->nlevels * sizeof(ST_double));
//                 memset(wx,    '\0', ghptr->nlevels * sizeof(ST_double));
//                 for (i = 0; i < ghptr->nobs; i++, wptr++, trgptr++) {
//                     wmeans[wx[i]] += (*wptr) * (*trgptr);
//                     wsums[wx[i]]  += (*wptr);
//                 }
//                 for (j = 0; j < ghptr->nlevels; j++) {
//                     wmeans[j] /= wsums[j];
//                 }
//                 trgptr = targets + k * ghptr->nobs;
//                 for (i = 0; i < ghptr->nobs; i++, trgptr++) {
//                     diff = GTOOLS_PWMAX(diff, fabs(wmeans[wx[i]]));
//                     *trgptr -= wmeans[wx[i]];
//                 }
//             }
//             if ( diff < tol ) break;
//         }
//     }
//
//     free (wmeans);
//     free (wsums);
//     free (wx);
// }

/**********************************************************************
 *                         Conjugate Gradient                         *
 **********************************************************************/

void GtoolsGroupByCGWeighted(
    struct GtoolsHash *GtoolsHashInfo,
    GT_size   khashes,
    ST_double *sources,
    ST_double *weights,
    ST_double *targets,
    GT_size   ktargets,
    ST_double tol)
{
    GT_size N = GtoolsHashInfo->nobs;
    GT_size nonmiss = GtoolsHashInfo->_nobspanel;
    GT_size maxiter = GtoolsHashInfo->hdfeMaxIter;
    GT_size verbose = GtoolsHashInfo->hdfeTraceIter;

    ST_double idiff, diff, buff;
    ST_double *x, *xptr, *rptr, *uptr, *vptr;
    ST_double alpha[ktargets], beta[ktargets], rr[ktargets], r0[ktargets];
    GT_size i, k, iter = 0, feval = 0;

    ST_double *r = GtoolsHashInfo->hdfeBuffer + ktargets * N * 0;
    ST_double *u = GtoolsHashInfo->hdfeBuffer + ktargets * N * 1;
    ST_double *v = GtoolsHashInfo->hdfeBuffer + ktargets * N * 2;

    idiff = GtoolsGroupByHalperinSymmWeighted(GtoolsHashInfo, khashes, sources, weights, targets, ktargets, tol);
    feval++;
    if ( verbose > 0 ) printf("\tCG: diff = %.9g\n", idiff);

    // x = x0
    // r  = - (I - T) x
    // rr = <r, r>
    // u  = r
    x = targets;
    if ( idiff >= tol ) {
        diff = GtoolsGroupByHalperinSymmWeighted(GtoolsHashInfo, khashes, x, weights, r, ktargets, tol);
        feval++;
        xptr = x;
        rptr = r;
        buff = 0;
        for (k = 0; k < ktargets; k++, rptr += N, xptr += N) {
            rr[k] = 0;
            for (i = 0; i < nonmiss; i++) {
                rptr[i] -= xptr[i];
                rr[k]   += weights[i] * rptr[i] * rptr[i];
            }
            buff += r[k];
        }
        memcpy(u, r, sizeof(ST_double) * ktargets * N);

        if ( verbose > 0 ) printf("\tCG: |x - Tx| = %.9g\n", diff);
        if ( verbose > 0 ) printf("\tCG: |rr|     = %.9g\n", buff);
    }

    while ( ((iter++ < maxiter)? 1: maxiter == 0) && (idiff > tol) ) {
        // v = (I - T) u
        diff = GtoolsGroupByHalperinSymmWeighted(GtoolsHashInfo, khashes, u, weights, v, ktargets, tol);
        feval++;
        vptr = v;
        uptr = u;
        for (k = 0; k < ktargets; k++, vptr += N, uptr += N) {
            for (i = 0; i < nonmiss; i++) {
                vptr[i] = uptr[i] - vptr[i];
            }
        }

        // a = rr / <u, v>
        vptr = v;
        uptr = u;
        for (k = 0; k < ktargets; k++, vptr += N, uptr += N) {
            alpha[k] = 0;
            for (i = 0; i < nonmiss; i++) {
                alpha[k] += weights[i] * vptr[i] * uptr[i];
            }
            if ( alpha[k] > 0 ) {
                alpha[k] = GTOOLS_PWMAX(alpha[k], GTOOLS_64BIT_EPSILON);
            }
            else {
                alpha[k] = GTOOLS_PWMIN(alpha[k], -GTOOLS_64BIT_EPSILON);
            }
            alpha[k] = rr[k] / alpha[k];
            r0[k]    = rr[k];
        }

        // x  = x + a u
        // r  = r - a v
        // rr = <r, r>
        // b  = rr/r0
        buff  = 0;
        idiff = 0;
        xptr  = x;
        uptr  = u;
        vptr  = v;
        rptr  = r;
        for (k = 0; k < ktargets; k++, xptr += N, uptr += N, vptr += N, rptr += N) {
            rr[k] = 0;
            for (i = 0; i < nonmiss; i++) {
                xptr[i] += alpha[k] * uptr[i];
                idiff    = GTOOLS_PWMAX(idiff, fabs(alpha[k] * uptr[i]));
                rptr[i] -= alpha[k] * vptr[i];
                rr[k]   += weights[i] * rptr[i] * rptr[i];
            }
            beta[k] = rr[k] / GTOOLS_PWMAX(r0[k], GTOOLS_64BIT_EPSILON);
            buff   += rr[k];
        }

        rptr = r;
        uptr = u;
        for (k = 0; k < ktargets; k++, rptr += N, uptr += N) {
            for (i = 0; i < nonmiss; i++) {
                uptr[i] = rptr[i] + beta[k] * uptr[i];
            }
        }

        if ( verbose > 0 ) printf("\tCG (%lu): |x - x'| = %.9g\n", iter, idiff);
        if ( verbose > 0 ) printf("\t          |v|      = %.9g\n", diff);
        if ( verbose > 0 ) printf("\t          |rr|     = %.9g\n", buff);

        // Avoid numerical precision traps: If alpha and/or ssr are too
        // close to 0, peace out.
        diff = 0;
        for (k = 0; k < ktargets; k++) {
            diff = GTOOLS_PWMAX(diff, GTOOLS_PWMIN(fabs(alpha[k]), r0[k]));
        }
        if ( diff < GTOOLS_64BIT_EPSILON ) {
            if ( verbose > 0 ) printf("(note: CG algorithm eps. close to 0; ");
            if ( GtoolsHashInfo->hdfeFallback ) {
                if ( verbose > 0 ) printf("falling back to SQUAREM)\n");
                // GtoolsGroupByHDFEWeighted(GtoolsHashInfo, khashes, x, weights, x, ktargets, tol);
                GtoolsGroupBySQUAREMWeighted(GtoolsHashInfo, khashes, x, weights, x, ktargets, tol);
                feval += GtoolsHashInfo->hdfeFeval;
                iter  += GtoolsHashInfo->hdfeIter;
            }
            else {
                if ( verbose > 0 ) printf("assuming convergence to avoid numerical precision errors)\n");
                GtoolsGroupByHalperinSymmWeighted(GtoolsHashInfo, khashes, x, weights, x, ktargets, tol); feval++;
            }
            idiff  = 0;
        }
    }

    GtoolsHashInfo->hdfeIter  = --iter;
    GtoolsHashInfo->hdfeFeval = feval;

    if ( verbose > 0 ) printf("CG: %lu iter (%lu max), %lu feval, %.9g diff (%.9g tol)\n",
                              iter, maxiter, feval, idiff, tol);

    if ( maxiter && iter >= maxiter ) GtoolsHashInfo->hdfeRc = 18402;
}

void GtoolsGroupByCGUnweighted(
    struct GtoolsHash *GtoolsHashInfo,
    GT_size   khashes,
    ST_double *sources,
    ST_double *weights,
    ST_double *targets,
    GT_size   ktargets,
    ST_double tol)
{
    GT_size N = GtoolsHashInfo->nobs;
    GT_size nonmiss = GtoolsHashInfo->_nobspanel;
    GT_size maxiter = GtoolsHashInfo->hdfeMaxIter;
    GT_size verbose = GtoolsHashInfo->hdfeTraceIter;

    ST_double idiff, diff, buff;
    ST_double *x, *xptr, *rptr, *uptr, *vptr;
    ST_double alpha[ktargets], beta[ktargets], rr[ktargets], r0[ktargets];
    GT_size i, k, iter = 0, feval = 0;

    ST_double *r = GtoolsHashInfo->hdfeBuffer + ktargets * N * 0;
    ST_double *u = GtoolsHashInfo->hdfeBuffer + ktargets * N * 1;
    ST_double *v = GtoolsHashInfo->hdfeBuffer + ktargets * N * 2;

    idiff = GtoolsGroupByHalperinSymmUnweighted(GtoolsHashInfo, khashes, sources, weights, targets, ktargets, tol);
    feval++;
    if ( verbose > 0 ) printf("\tCG: diff = %.9g\n", idiff);

    // x = x0
    // r  = - (I - T) x
    // rr = <r, r>
    // u  = r
    x = targets;
    if ( idiff >= tol ) {
        diff = GtoolsGroupByHalperinSymmUnweighted(GtoolsHashInfo, khashes, x, weights, r, ktargets, tol);
        feval++;
        xptr = x;
        rptr = r;
        buff = 0;
        for (k = 0; k < ktargets; k++, rptr += N, xptr += N) {
            rr[k] = 0;
            for (i = 0; i < nonmiss; i++) {
                rptr[i] -= xptr[i];
                rr[k]   += rptr[i] * rptr[i];
            }
            buff += r[k];
        }
        memcpy(u, r, sizeof(ST_double) * ktargets * N);

        if ( verbose > 0 ) printf("\tCG: |x - Tx| = %.9g\n", diff);
        if ( verbose > 0 ) printf("\tCG: |rr|     = %.9g\n", buff);
    }

    while ( ((iter++ < maxiter)? 1: maxiter == 0) && (idiff > tol) ) {
        // v = (I - T) u
        diff = GtoolsGroupByHalperinSymmUnweighted(GtoolsHashInfo, khashes, u, weights, v, ktargets, tol);
        feval++;
        vptr = v;
        uptr = u;
        for (k = 0; k < ktargets; k++, vptr += N, uptr += N) {
            for (i = 0; i < nonmiss; i++) {
                vptr[i] = uptr[i] - vptr[i];
            }
        }

        // a = rr / <u, v>
        vptr = v;
        uptr = u;
        for (k = 0; k < ktargets; k++, vptr += N, uptr += N) {
            alpha[k] = 0;
            for (i = 0; i < nonmiss; i++) {
                alpha[k] += vptr[i] * uptr[i];
            }
            if ( alpha[k] > 0 ) {
                alpha[k] = GTOOLS_PWMAX(alpha[k], GTOOLS_64BIT_EPSILON);
            }
            else {
                alpha[k] = GTOOLS_PWMIN(alpha[k], -GTOOLS_64BIT_EPSILON);
            }
            alpha[k] = rr[k] / alpha[k];
            r0[k]    = rr[k];
        }

        // x  = x + a u
        // r  = r - a v
        // rr = <r, r>
        // b  = rr/r0
        buff  = 0;
        idiff = 0;
        xptr  = x;
        uptr  = u;
        vptr  = v;
        rptr  = r;
        for (k = 0; k < ktargets; k++, xptr += N, uptr += N, vptr += N, rptr += N) {
            rr[k] = 0;
            for (i = 0; i < nonmiss; i++) {
                xptr[i] += alpha[k] * uptr[i];
                idiff    = GTOOLS_PWMAX(idiff, fabs(alpha[k] * uptr[i]));
                rptr[i] -= alpha[k] * vptr[i];
                rr[k]   += rptr[i] * rptr[i];
            }
            beta[k] = rr[k] / GTOOLS_PWMAX(r0[k], GTOOLS_64BIT_EPSILON);
            buff   += rr[k];
        }

        rptr = r;
        uptr = u;
        for (k = 0; k < ktargets; k++, rptr += N, uptr += N) {
            for (i = 0; i < nonmiss; i++) {
                uptr[i] = rptr[i] + beta[k] * uptr[i];
            }
        }

        if ( verbose > 0 ) printf("\tCG (%lu): |x - x'| = %.9g\n", iter, idiff);
        if ( verbose > 0 ) printf("\t          |v|      = %.9g\n", diff);
        if ( verbose > 0 ) printf("\t          |rr|     = %.9g\n", buff);

        // Avoid numerical precision traps: If alpha and/or ssr are too
        // close to 0, apply transform directly and check if converged.
        diff = 0;
        for (k = 0; k < ktargets; k++) {
            diff = GTOOLS_PWMAX(diff, GTOOLS_PWMIN(fabs(alpha[k]), r0[k]));
        }
        if ( diff < GTOOLS_64BIT_EPSILON ) {
            if ( verbose > 0 ) printf("(note: CG algorithm eps. close to 0; ");
            if ( GtoolsHashInfo->hdfeFallback ) {
                if ( verbose > 0 ) printf("falling back to SQUAREM)\n");
                // GtoolsGroupByHDFEUnweighted(GtoolsHashInfo, khashes, x, weights, x, ktargets, tol);
                GtoolsGroupBySQUAREMUnweighted(GtoolsHashInfo, khashes, x, weights, x, ktargets, tol);
                feval += GtoolsHashInfo->hdfeFeval;
                iter  += GtoolsHashInfo->hdfeIter;
            }
            else {
                if ( verbose > 0 ) printf("assuming convergence to avoid numerical precision errors)\n");
                GtoolsGroupByHalperinSymmUnweighted(GtoolsHashInfo, khashes, x, weights, x, ktargets, tol); feval++;
            }
            idiff = 0;
        }
    }

    GtoolsHashInfo->hdfeIter  = --iter;
    GtoolsHashInfo->hdfeFeval = feval;

    if ( verbose > 0 ) printf("CG: %lu iter (%lu max), %lu feval, %.9g diff (%.9g tol)\n",
                              iter, maxiter, feval, idiff, tol);

    if ( maxiter && iter >= maxiter ) GtoolsHashInfo->hdfeRc = 18402;
}

/**********************************************************************
 *                              SQUAREM                               *
 **********************************************************************/

void GtoolsGroupBySQUAREMWeighted(
    struct GtoolsHash *GtoolsHashInfo,
    GT_size   khashes,
    ST_double *sources,
    ST_double *weights,
    ST_double *targets,
    GT_size   ktargets,
    ST_double tol)
{
    GT_size N = GtoolsHashInfo->nobs;
    GT_size nonmiss = GtoolsHashInfo->_nobspanel;
    GT_size maxiter = GtoolsHashInfo->hdfeMaxIter;
    GT_size verbose = GtoolsHashInfo->hdfeTraceIter;

    ST_double alpha[ktargets], sr2[ktargets], sv2[ktargets], *x, *xptr, *x1ptr, *x2ptr, *q1ptr, *q2ptr;
    ST_double qdiff, diff, stepmax[ktargets], stepmin[ktargets], mstep;
    GT_size i, k, iter = 0, feval = 0;

    ST_double *x1 = GtoolsHashInfo->hdfeBuffer + ktargets * N * 0;
    ST_double *x2 = GtoolsHashInfo->hdfeBuffer + ktargets * N * 1;
    ST_double *q1 = GtoolsHashInfo->hdfeBuffer + ktargets * N * 2;
    ST_double *q2 = GtoolsHashInfo->hdfeBuffer + ktargets * N * 3;

    diff  = 1.0;
    mstep = 4.0;
    for (k = 0; k < ktargets; k++) {
        stepmax[k] = 1.0;
        stepmin[k] = 1.0;
    }

    diff = GtoolsGroupByHalperinWeighted(GtoolsHashInfo, khashes, sources, weights, targets, ktargets, tol); feval++;
    x = targets;

    if ( verbose > 0 ) printf("\tSQUAREM: |x - x'| = %.9g\n", diff);
    while ( ((iter++ < maxiter)? 1: maxiter == 0) && (diff > tol) ) {
        // va_start(args, f); f(x1, x,  args); va_end(args);
        // va_start(args, f); f(x2, x1, args); va_end(args);

        diff = GtoolsGroupByHalperinWeighted(GtoolsHashInfo, khashes, x, weights, x1, ktargets, tol); feval++;
        if ( verbose > 0 ) printf("\tSQUAREM (%lu): |x - x'| = %.9g\n", iter, diff);
        if ( diff < tol ) {
            memcpy(x, x1, sizeof(ST_double) * ktargets * N);
            break;
        }

        diff = GtoolsGroupByHalperinWeighted(GtoolsHashInfo, khashes, x1, weights, x2, ktargets, tol); feval++;
        if ( verbose > 0 ) printf("\tSQUAREM (%lu): |x - x'| = %.9g\n", iter, diff);
        if ( diff < tol ) {
            memcpy(x, x2, sizeof(ST_double) * ktargets * N);
            break;
        }

        xptr   = x;
        x1ptr  = x1;
        x2ptr  = x2;
        q1ptr  = q1;
        q2ptr  = q2;
        for (k = 0; k < ktargets; k++, xptr += N, x1ptr += N, x2ptr += N, q1ptr += N, q2ptr += N) {
            sr2[k] = 0;
            sv2[k] = 0;
            for (i = 0; i < nonmiss; i++) {
                q1ptr[i] = x1ptr[i] - xptr[i];
                q2ptr[i] = x2ptr[i] - x1ptr[i];
                qdiff    = q2ptr[i] - q1ptr[i];
                sr2[k]  += weights[i] * q1ptr[i] * q1ptr[i];
                sv2[k]  += weights[i] * qdiff * qdiff;
            }
        }

        for (k = 0; k < ktargets; k++) {
            alpha[k] = GTOOLS_PWMAX(stepmin[k], GTOOLS_PWMIN(stepmax[k], pow(sr2[k]/sv2[k], 0.5)));
        }

        xptr   = x;
        q1ptr  = q1;
        q2ptr  = q2;
        for (k = 0; k < ktargets; k++, xptr += N, q1ptr += N, q2ptr += N) {
            for (i = 0; i < nonmiss; i++) {
                xptr[i] += (2 * alpha[k] * q1ptr[i] + alpha[k] * alpha[k] * (q2ptr[i] - q1ptr[i]));
            }
        }

        diff = GtoolsGroupByHalperinWeighted(GtoolsHashInfo, khashes, x, weights, x, ktargets, tol); feval++;
        if ( verbose > 0 ) printf("\tSQUAREM (%lu): |x - x'| = %.9g\n", iter, diff);
        if ( diff < tol ) break;

        for (k = 0; k < ktargets; k++) {
            if (alpha[k] == stepmax[k]) stepmax[k] *= mstep;
            if ( (alpha[k] == stepmin[k]) && (alpha[k] < 0) ) stepmin[k] *= mstep;
        }
    }

    GtoolsHashInfo->hdfeIter  = --iter;
    GtoolsHashInfo->hdfeFeval = feval;

    if ( verbose > 0 ) printf("SQUAREM: %lu iter (%lu max), %lu feval, %.9g diff (%.9g tol)\n",
                              iter, maxiter, feval, diff, tol);

    if ( maxiter && iter >= maxiter ) GtoolsHashInfo->hdfeRc = 18402;
}

void GtoolsGroupBySQUAREMUnweighted(
    struct GtoolsHash *GtoolsHashInfo,
    GT_size   khashes,
    ST_double *sources,
    ST_double *weights,
    ST_double *targets,
    GT_size   ktargets,
    ST_double tol)
{
    GT_size N = GtoolsHashInfo->nobs;
    GT_size nonmiss = GtoolsHashInfo->_nobspanel;
    GT_size maxiter = GtoolsHashInfo->hdfeMaxIter;
    GT_size verbose = GtoolsHashInfo->hdfeTraceIter;

    ST_double alpha[ktargets], sr2[ktargets], sv2[ktargets], *x, *xptr, *x1ptr, *x2ptr, *q1ptr, *q2ptr;
    ST_double qdiff, diff, stepmax[ktargets], stepmin[ktargets], mstep;
    GT_size i, k, iter = 0, feval = 0;

    ST_double *x1 = GtoolsHashInfo->hdfeBuffer + ktargets * N * 0;
    ST_double *x2 = GtoolsHashInfo->hdfeBuffer + ktargets * N * 1;
    ST_double *q1 = GtoolsHashInfo->hdfeBuffer + ktargets * N * 2;
    ST_double *q2 = GtoolsHashInfo->hdfeBuffer + ktargets * N * 3;

    diff  = 1.0;
    mstep = 4.0;
    for (k = 0; k < ktargets; k++) {
        stepmax[k] = 1.0;
        stepmin[k] = 1.0;
    }

    diff = GtoolsGroupByHalperinUnweighted(GtoolsHashInfo, khashes, sources, weights, targets, ktargets, tol); feval++;
    x = targets;

    if ( verbose > 0 ) printf("\tSQUAREM: |x - x'| = %.9g\n", diff);
    while ( ((iter++ < maxiter)? 1: maxiter == 0) && (diff > tol) ) {
        // va_start(args, f); f(x1, x,  args); va_end(args);
        // va_start(args, f); f(x2, x1, args); va_end(args);

        diff = GtoolsGroupByHalperinUnweighted(GtoolsHashInfo, khashes, x, weights, x1, ktargets, tol); feval++;
        if ( verbose > 0 ) printf("\tSQUAREM (%lu): |x - x'| = %.9g\n", iter, diff);
        if ( diff < tol ) {
            memcpy(x, x1, sizeof(ST_double) * ktargets * N);
            break;
        }

        diff = GtoolsGroupByHalperinUnweighted(GtoolsHashInfo, khashes, x1, weights, x2, ktargets, tol); feval++;
        if ( verbose > 0 ) printf("\tSQUAREM (%lu): |x - x'| = %.9g\n", iter, diff);
        if ( diff < tol ) {
            memcpy(x, x2, sizeof(ST_double) * ktargets * N);
            break;
        }

        xptr   = x;
        x1ptr  = x1;
        x2ptr  = x2;
        q1ptr  = q1;
        q2ptr  = q2;
        for (k = 0; k < ktargets; k++, xptr += N, x1ptr += N, x2ptr += N, q1ptr += N, q2ptr += N) {
            sr2[k] = 0;
            sv2[k] = 0;
            for (i = 0; i < nonmiss; i++) {
                q1ptr[i] = x1ptr[i] - xptr[i];
                q2ptr[i] = x2ptr[i] - x1ptr[i];
                qdiff    = q2ptr[i] - q1ptr[i];
                sr2[k]  += q1ptr[i] * q1ptr[i];
                sv2[k]  += qdiff * qdiff;
            }
        }

        for (k = 0; k < ktargets; k++) {
            alpha[k] = GTOOLS_PWMAX(stepmin[k], GTOOLS_PWMIN(stepmax[k], pow(sr2[k]/sv2[k], 0.5)));
        }

        xptr   = x;
        q1ptr  = q1;
        q2ptr  = q2;
        for (k = 0; k < ktargets; k++, xptr += N, q1ptr += N, q2ptr += N) {
            for (i = 0; i < nonmiss; i++) {
                xptr[i] += (2 * alpha[k] * q1ptr[i] + alpha[k] * alpha[k] * (q2ptr[i] - q1ptr[i]));
            }
        }

        diff = GtoolsGroupByHalperinUnweighted(GtoolsHashInfo, khashes, x, weights, x, ktargets, tol); feval++;
        if ( verbose > 0 ) printf("\tSQUAREM (%lu): |x - x'| = %.9g\n", iter, diff);
        if ( diff < tol ) break;

        for (k = 0; k < ktargets; k++) {
            if (alpha[k] == stepmax[k]) stepmax[k] *= mstep;
            if ( (alpha[k] == stepmin[k]) && (alpha[k] < 0) ) stepmin[k] *= mstep;
        }
    }

    GtoolsHashInfo->hdfeIter  = --iter;
    GtoolsHashInfo->hdfeFeval = feval;

    if ( verbose > 0 ) printf("SQUAREM: %lu iter (%lu max), %lu feval, %.9g diff (%.9g tol)\n",
                              iter, maxiter, feval, diff, tol);

    if ( maxiter && iter >= maxiter ) GtoolsHashInfo->hdfeRc = 18402;
}

/**********************************************************************
 *                              SQUAREM                               *
 **********************************************************************/

void GtoolsGroupByIronsTuckWeighted(
    struct GtoolsHash *GtoolsHashInfo,
    GT_size   khashes,
    ST_double *sources,
    ST_double *weights,
    ST_double *targets,
    GT_size   ktargets,
    ST_double tol)
{
    GT_size N = GtoolsHashInfo->nobs;
    GT_size nonmiss = GtoolsHashInfo->_nobspanel;
    GT_size maxiter = GtoolsHashInfo->hdfeMaxIter;
    GT_size verbose = GtoolsHashInfo->hdfeTraceIter;

    ST_double diff, step[ktargets], DgXD2X[ktargets], D2XD2X[ktargets];
    ST_double *x, *xptr, *gXptr, *ggXptr, *DXptr, *DgXptr, *D2Xptr;
    GT_size i, k, iter = 0, feval = 0;

    ST_double *gX  = GtoolsHashInfo->hdfeBuffer + ktargets * N * 0;
    ST_double *ggX = GtoolsHashInfo->hdfeBuffer + ktargets * N * 1;
    ST_double *DX  = GtoolsHashInfo->hdfeBuffer + ktargets * N * 2;
    ST_double *DgX = GtoolsHashInfo->hdfeBuffer + ktargets * N * 3;
    ST_double *D2X = GtoolsHashInfo->hdfeBuffer + ktargets * N * 4;

    diff = GtoolsGroupByHalperinWeighted(GtoolsHashInfo, khashes, sources, weights, targets, ktargets, tol); feval++;
    x = targets;

    if ( verbose > 0 ) printf("\tIT: |x - x'| = %.9g\n", diff);
    while ( ((iter++ < maxiter)? 1: maxiter == 0) && (diff > tol) ) {
        diff = GtoolsGroupByHalperinWeighted(GtoolsHashInfo, khashes, x, weights, gX, ktargets, tol); feval++;
        if ( verbose > 0 ) printf("\tIT (%lu): |x - x'| = %.9g\n", iter, diff);
        if ( diff < tol ) {
            memcpy(x, gX, sizeof(ST_double) * ktargets * N);
            break;
        }

        diff = GtoolsGroupByHalperinWeighted(GtoolsHashInfo, khashes, gX, weights, ggX, ktargets, tol); feval++;
        if ( verbose > 0 ) printf("\tIT (%lu): |x - x'| = %.9g\n", iter, diff);
        if ( diff < tol ) {
            memcpy(x, ggX, sizeof(ST_double) * ktargets * N);
            break;
        }

        xptr   = x;
        gXptr  = gX;
        ggXptr = ggX;
        DXptr  = DX;
        DgXptr = DgX;
        D2Xptr = D2X;
        for (k = 0; k < ktargets; k++, xptr += N, gXptr += N, ggXptr += N, DXptr += N, DgXptr += N, D2Xptr += N) {
            step[k]   = 0;
            DgXD2X[k] = 0;
            D2XD2X[k] = 0;
            for (i = 0; i < nonmiss; i++) {
                DXptr[i]  = gXptr[i]  - xptr[i];
                DgXptr[i] = ggXptr[i] - gXptr[i];
                D2Xptr[i] = DgXptr[i] - DXptr[i];
                DgXD2X[k] += weights[i] * DgXptr[i] * D2Xptr[i];
                D2XD2X[k] += weights[i] * D2Xptr[i] * D2Xptr[i];
            }
            step[k] = DgXD2X[k] / D2XD2X[k];
        }

        xptr   = x;
        ggXptr = ggX;
        DgXptr = DgX;
        for (k = 0; k < ktargets; k++, xptr += N, ggXptr += N, DgXptr += N) {
            for (i = 0; i < nonmiss; i++) {
                xptr[i] = ggXptr[i] - step[k] * DgXptr[i];
            }
        }
    }

    GtoolsHashInfo->hdfeIter  = --iter;
    GtoolsHashInfo->hdfeFeval = feval;

    if ( verbose > 0 ) printf("IT: %lu iter (%lu max), %lu feval, %.9g diff (%.9g tol)\n",
                              iter, maxiter, feval, diff, tol);

    if ( maxiter && iter >= maxiter ) GtoolsHashInfo->hdfeRc = 18402;
}

void GtoolsGroupByIronsTuckUnweighted(
    struct GtoolsHash *GtoolsHashInfo,
    GT_size   khashes,
    ST_double *sources,
    ST_double *weights,
    ST_double *targets,
    GT_size   ktargets,
    ST_double tol)
{
    GT_size N = GtoolsHashInfo->nobs;
    GT_size nonmiss = GtoolsHashInfo->_nobspanel;
    GT_size maxiter = GtoolsHashInfo->hdfeMaxIter;
    GT_size verbose = GtoolsHashInfo->hdfeTraceIter;

    ST_double diff, step[ktargets], DgXD2X[ktargets], D2XD2X[ktargets];
    ST_double *x, *xptr, *gXptr, *ggXptr, *DXptr, *DgXptr, *D2Xptr;
    GT_size i, k, iter = 0, feval = 0;

    ST_double *gX  = GtoolsHashInfo->hdfeBuffer + ktargets * N * 0;
    ST_double *ggX = GtoolsHashInfo->hdfeBuffer + ktargets * N * 1;
    ST_double *DX  = GtoolsHashInfo->hdfeBuffer + ktargets * N * 2;
    ST_double *DgX = GtoolsHashInfo->hdfeBuffer + ktargets * N * 3;
    ST_double *D2X = GtoolsHashInfo->hdfeBuffer + ktargets * N * 4;

    diff = GtoolsGroupByHalperinUnweighted(GtoolsHashInfo, khashes, sources, weights, targets, ktargets, tol); feval++;
    x = targets;

    if ( verbose > 0 ) printf("\tIT: |x - x'| = %.9g\n", diff);
    while ( ((iter++ < maxiter)? 1: maxiter == 0) && (diff > tol) ) {
        diff = GtoolsGroupByHalperinUnweighted(GtoolsHashInfo, khashes, x, weights, gX, ktargets, tol); feval++;
        if ( verbose > 0 ) printf("\tIT (%lu): |x - x'| = %.9g\n", iter, diff);
        if ( diff < tol ) {
            memcpy(x, gX, sizeof(ST_double) * ktargets * N);
            break;
        }

        diff = GtoolsGroupByHalperinUnweighted(GtoolsHashInfo, khashes, gX, weights, ggX, ktargets, tol); feval++;
        if ( verbose > 0 ) printf("\tIT (%lu): |x - x'| = %.9g\n", iter, diff);
        if ( diff < tol ) {
            memcpy(x, ggX, sizeof(ST_double) * ktargets * N);
            break;
        }

        xptr   = x;
        gXptr  = gX;
        ggXptr = ggX;
        DXptr  = DX;
        DgXptr = DgX;
        D2Xptr = D2X;
        for (k = 0; k < ktargets; k++, xptr += N, gXptr += N, ggXptr += N, DXptr += N, DgXptr += N, D2Xptr += N) {
            step[k]   = 0;
            DgXD2X[k] = 0;
            D2XD2X[k] = 0;
            for (i = 0; i < nonmiss; i++) {
                DXptr[i]  = gXptr[i]  - xptr[i];
                DgXptr[i] = ggXptr[i] - gXptr[i];
                D2Xptr[i] = DgXptr[i] - DXptr[i];
                DgXD2X[k] += DgXptr[i] * D2Xptr[i];
                D2XD2X[k] += D2Xptr[i] * D2Xptr[i];
            }
            step[k] = DgXD2X[k] / D2XD2X[k];
        }

        xptr   = x;
        ggXptr = ggX;
        DgXptr = DgX;
        for (k = 0; k < ktargets; k++, xptr += N, ggXptr += N, DgXptr += N) {
            for (i = 0; i < nonmiss; i++) {
                xptr[i] = ggXptr[i] - step[k] * DgXptr[i];
            }
        }
    }

    GtoolsHashInfo->hdfeIter  = --iter;
    GtoolsHashInfo->hdfeFeval = feval;

    if ( verbose > 0 ) printf("IT: %lu iter (%lu max), %lu feval, %.9g diff (%.9g tol)\n",
                              iter, maxiter, feval, diff, tol);

    if ( maxiter && iter >= maxiter ) GtoolsHashInfo->hdfeRc = 18402;
}
