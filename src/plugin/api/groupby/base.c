/**********************************************************************
 *                                HDFE                                *
 **********************************************************************/

// Note: The unweighted versions take weights so I can define them
// generically in higher-level functions. The unweighted versions can
// then take in a weight as an argument but ignore it.

GT_int GtoolsAlgorithmMAP(
    struct GtoolsHash *GtoolsHashInfo,
    GT_size   khashes,
    ST_double *sources,
    ST_double *weights,
    ST_double *targets,
    GT_size   ktargets,
    ST_double tol)
{
    GT_int rc = 0;
    GT_size iter = 0, feval = 0;
    ST_double diff  = 1;
    GT_size N       = GtoolsHashInfo->nobs;
    GT_size maxiter = GtoolsHashInfo->hdfeMaxIter;
    GT_bool verbose = GtoolsHashInfo->hdfeTraceIter;
    GT_size bufferk = (weights == NULL? 1: 2) * (GTOOLSOMP? ktargets: 1) * N;
    ST_double *b = calloc(bufferk, sizeof *b); if ( b == NULL ) return(17902);

    // NB: It's important to apply every level; else nested levels might
    // effect the algorithm to exit prematurely.

    while ( ((iter++ < maxiter)? 1: maxiter == 0) && (diff > tol) ) {
        diff = GtoolsAbsorbHalperinBuffer(GtoolsHashInfo, khashes, sources, weights, targets, ktargets, tol, b);
        feval++;
        if ( verbose > 0 ) printf("\tMAP (%lu): |x - x'| = %.9g\n", iter, diff);
    }

    GtoolsHashInfo->hdfeIter  = --iter;
    GtoolsHashInfo->hdfeFeval = feval;

    if ( verbose > 0 ) printf("MAP: %lu iter (%lu max), %lu feval, %.9g diff (%.9g tol)\n",
                              iter, maxiter, feval, diff, tol);

    if ( maxiter && iter >= maxiter ) rc = 18402;

    free(b);

    return(rc);
}

/**********************************************************************
 *                              Halperin                              *
 **********************************************************************/

ST_double GtoolsAbsorbHalperin(
    struct GtoolsHash *GtoolsHashInfo,
    GT_size   khashes,
    ST_double *sources,
    ST_double *weights,
    ST_double *targets,
    GT_size   ktargets,
    ST_double tol)
{
    if ( weights == NULL ) {
        return (GtoolsAbsorbHalperinUnweighted(
            GtoolsHashInfo,
            khashes,
            sources,
            weights,
            targets,
            ktargets,
            tol
        ));
    }
    else {
        return (GtoolsAbsorbHalperinWeighted(
            GtoolsHashInfo,
            khashes,
            sources,
            weights,
            targets,
            ktargets,
            tol
        ));
    }
}

ST_double GtoolsAbsorbHalperinUnweighted(
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
    ST_double diff = 0;
    struct GtoolsHash *ghptr;

    update = 0;
    ghptr  = GtoolsHashInfo;
    for (l = 0; l < khashes; l++, ghptr++) {
        for (j = 0; j < ghptr->nlevels; j++) {
            start  = ghptr->info[j];
            nj     = ghptr->info[j + 1] - start;
            ixptr  = ghptr->index + start;
            srcptr = update? targets: sources;
            trgptr = targets;
            for (k = 0; k < ktargets; k++, srcptr += ghptr->nobs, trgptr += ghptr->nobs) {
                mean = GtoolsStatsMeanIndex(srcptr, ixptr, nj);
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

ST_double GtoolsAbsorbHalperinWeighted(
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
    ST_double diff = 0;

    update = 0;
    ghptr  = GtoolsHashInfo;
    for (l = 0; l < khashes; l++, ghptr++) {
        for (j = 0; j < ghptr->nlevels; j++) {
            start  = ghptr->info[j];
            nj     = ghptr->info[j + 1] - start;
            ixptr  = ghptr->index + start;
            srcptr = update? targets: sources;
            trgptr = targets;
            for (k = 0; k < ktargets; k++, srcptr += ghptr->nobs, trgptr += ghptr->nobs) {
                mean = GtoolsStatsMeanIndexWeighted(srcptr, weights, ixptr, nj);
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

/**********************************************************************
 *                     Halperin with means buffer                     *
 **********************************************************************/

ST_double GtoolsAbsorbHalperinBuffer(
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
        return (GtoolsAbsorbHalperinBufferUnweighted(
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
        return (GtoolsAbsorbHalperinBufferWeighted(
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

ST_double GtoolsAbsorbHalperinBufferUnweighted(
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
    GT_size i, j, k, l;
    GT_size nonmiss = GtoolsHashInfo->_nobspanel;
    GT_size N = GtoolsHashInfo->nobs;
    ST_double *srcptr, *trgptr, *buffer;
    ST_double diff[ktargets];
    struct GtoolsHash *ghptr;

    // NB: This criterion is looking for largest deviation in any given
    // FE projection; if two FE projections cancel out, basically, it
    // would take the largest, not the sum. Is it better? Unsure. Improve
    // convergence criterion when you get the chance.

    /**/
    #if GTOOLSOMP
    #pragma omp parallel for \
        private(             \
            srcptr,          \
            trgptr,          \
            buffer,          \
            i,               \
            j,               \
            l,               \
            update,          \
            ghptr            \
        )                    \
        shared(              \
            N,               \
            sources,         \
            targets,         \
            allbuffer,       \
            khashes,         \
            nonmiss,         \
            diff,            \
            GtoolsHashInfo   \
        )
    #endif
    /**/
    for (k = 0; k < ktargets; k++) {
        diff[k] = 0;
        srcptr  = sources + k * N;
        trgptr  = targets + k * N;
        buffer  = allbuffer + N * k * GTOOLSOMP;
        ghptr   = GtoolsHashInfo;
        update  = 0;
        for (l  = 0; l < khashes; l++, ghptr++) {
            memset(buffer, '\0', sizeof(buffer) * ghptr->nlevels);

            // compute sums
            if ( update ) {
                for (i = 0; i < nonmiss; i++) {
                    buffer[ghptr->indexj[i]] += trgptr[i];
                }
            }
            else {
                for (i = 0; i < nonmiss; i++) {
                    buffer[ghptr->indexj[i]] += srcptr[i];
                }
            }

            // make means
            for (j = 0; j < ghptr->nlevels; j++) {
                buffer[j] /= ghptr->nj[j];
                diff[k] = GTOOLS_PWMAX(diff[k], fabs(buffer[j]));
            }

            // update target
            if ( update ) {
                for (i = 0; i < nonmiss; i++) {
                    trgptr[i] -= buffer[ghptr->indexj[i]];
                }
            }
            else {
                for (i = 0; i < nonmiss; i++) {
                    trgptr[i] = srcptr[i] - buffer[ghptr->indexj[i]];
                }
            }

            update = 1;
        }
    }

    return (GtoolsStatsMax(diff, ktargets));
}

ST_double GtoolsAbsorbHalperinBufferWeighted(
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
    GT_size i, j, k, l;
    GT_size nonmiss = GtoolsHashInfo->_nobspanel;
    GT_size N = GtoolsHashInfo->nobs;
    ST_double *srcptr, *trgptr, *buffer, *wbuffer;
    ST_double diff[ktargets];
    struct GtoolsHash *ghptr;

    // NB: This criterion is looking for largest deviation in any given
    // FE projection; if two FE projections cancel out, basically, it
    // would take the largest, not the sum. Is it better? Unsure. Improve
    // convergence criterion when you get the chance.

    /**/
    #if GTOOLSOMP
    #pragma omp parallel for \
        private(             \
            srcptr,          \
            trgptr,          \
            buffer,          \
            wbuffer,         \
            i,               \
            j,               \
            l,               \
            update,          \
            ghptr            \
        )                    \
        shared(              \
            N,               \
            sources,         \
            targets,         \
            weights,         \
            allbuffer,       \
            khashes,         \
            nonmiss,         \
            diff,            \
            GtoolsHashInfo   \
        )
    #endif
    /**/
    for (k = 0; k < ktargets; k++) {
        diff[k] = 0;
        srcptr  = sources + k * N;
        trgptr  = targets + k * N;
        buffer  = allbuffer + N * k * GTOOLSOMP * 2;
        update  = 0;
        ghptr   = GtoolsHashInfo;
        for (l  = 0; l < khashes; l++, ghptr++) {
            memset(buffer, '\0', sizeof(buffer) * ghptr->nlevels * 2);
            wbuffer = buffer + ghptr->nlevels;

            // compute sums
            if ( update ) {
                for (i = 0; i < nonmiss; i++) {
                    buffer[ghptr->indexj[i]]  += weights[i] * trgptr[i];
                    wbuffer[ghptr->indexj[i]] += weights[i];
                }
            }
            else {
                for (i = 0; i < nonmiss; i++) {
                    buffer[ghptr->indexj[i]]  += weights[i] * srcptr[i];
                    wbuffer[ghptr->indexj[i]] += weights[i];
                }
            }

            // make means
            for (j = 0; j < ghptr->nlevels; j++) {
                buffer[j] /= wbuffer[j];
                diff[k]    = GTOOLS_PWMAX(diff[k], fabs(buffer[j]));
            }

            // update target
            if ( update ) {
                for (i = 0; i < nonmiss; i++) {
                    trgptr[i] -= buffer[ghptr->indexj[i]];
                }
            }
            else {
                for (i = 0; i < nonmiss; i++) {
                    trgptr[i] = srcptr[i] - buffer[ghptr->indexj[i]];
                }
            }

            update = 1;
        }
    }

    return (GtoolsStatsMax(diff, ktargets));
}

/**********************************************************************
 *                         Halperin Symmetric                         *
 **********************************************************************/

void GtoolsOptimizeOrder(struct GtoolsHash *GtoolsHashInfo, GT_size khashes, GT_size *order)
{
    GT_size l, nlevels[khashes];
    struct GtoolsHash *ghptr = GtoolsHashInfo;
    for (l = 0; l < khashes; l++, ghptr++) {
        nlevels[l] = ghptr->nlevels;
        order[l]   = l;
    }
    GtoolsRadixSortSize(nlevels, order, khashes, 0);
}

ST_double GtoolsAbsorbHalperinSymm(
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
        return (GtoolsAbsorbHalperinSymmUnweighted(
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
        return (GtoolsAbsorbHalperinSymmWeighted(
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

ST_double GtoolsAbsorbHalperinSymmUnweighted(
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
    GT_size i, j, k, l, ghix;
    GT_size nonmiss = GtoolsHashInfo->_nobspanel;
    GT_size N = GtoolsHashInfo->nobs;
    ST_double *srcptr, *trgptr, *buffer;
    ST_double diff[ktargets];
    struct GtoolsHash *ghptr;
    GT_size order[khashes];
    GtoolsOptimizeOrder(GtoolsHashInfo, khashes, order);

    // NB: This criterion is looking for largest deviation in any given
    // FE projection; if two FE projections cancel out, basically, it
    // would take the largest, not the sum. Is it better? Unsure. Improve
    // convergence criterion when you get the chance.

    // NB: It's a.s. faster to parallelize the entire algorithm, rather
    // than just this step, but it's also more memory-intensive no?
    /**/
    #if GTOOLSOMP
    #pragma omp parallel for \
        private(             \
            srcptr,          \
            trgptr,          \
            buffer,          \
            ghix,            \
            i,               \
            j,               \
            l,               \
            update,          \
            ghptr            \
        )                    \
        shared(              \
            N,               \
            sources,         \
            targets,         \
            allbuffer,       \
            khashes,         \
            nonmiss,         \
            diff,            \
            GtoolsHashInfo   \
        )
    #endif
    /**/
    for (k = 0; k < ktargets; k++) {
        diff[k] = 0;
        srcptr  = sources + k * N;
        trgptr  = targets + k * N;
        buffer  = allbuffer + N * k * GTOOLSOMP;
        ghix    = 0;
        l       = 0;
        update  = 0;
        while (l < (khashes + (khashes - 1))) {
            ghptr = GtoolsHashInfo + order[ghix];
            memset(buffer, '\0', sizeof(buffer) * ghptr->nlevels);

            // compute sums
            if ( update ) {
                for (i = 0; i < nonmiss; i++) {
                    buffer[ghptr->indexj[i]] += trgptr[i];
                }
            }
            else {
                for (i = 0; i < nonmiss; i++) {
                    buffer[ghptr->indexj[i]] += srcptr[i];
                }
            }

            // make means
            for (j = 0; j < ghptr->nlevels; j++) {
                buffer[j] /= ghptr->nj[j];
                diff[k] = GTOOLS_PWMAX(diff[k], fabs(buffer[j]));
            }

            // update target
            if ( update ) {
                for (i = 0; i < nonmiss; i++) {
                    trgptr[i] -= buffer[ghptr->indexj[i]];
                }
            }
            else {
                for (i = 0; i < nonmiss; i++) {
                    trgptr[i] = srcptr[i] - buffer[ghptr->indexj[i]];
                }
            }

            update = 1;
            // ++l < khashes? ghptr++: ghptr--;
            ++l < khashes? ghix++: ghix--;
        }
    }

    return (GtoolsStatsMax(diff, ktargets));
}

ST_double GtoolsAbsorbHalperinSymmWeighted(
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
    GT_size i, j, k, l, ghix;
    GT_size nonmiss = GtoolsHashInfo->_nobspanel;
    GT_size N = GtoolsHashInfo->nobs;
    ST_double *srcptr, *trgptr, *buffer, *wbuffer;
    ST_double diff[ktargets];
    struct GtoolsHash *ghptr;
    GT_size order[khashes];
    GtoolsOptimizeOrder(GtoolsHashInfo, khashes, order);

    // NB: This criterion is looking for largest deviation in any given
    // FE projection; if two FE projections cancel out, basically, it
    // would take the largest, not the sum. Is it better? Unsure. Improve
    // convergence criterion when you get the chance.

    // NB: It's a.s. faster to parallelize the entire algorithm, rather
    // than just this step, but it's also more memory-intensive no?
    /**/
    #if GTOOLSOMP
    #pragma omp parallel for \
        private(             \
            srcptr,          \
            trgptr,          \
            buffer,          \
            wbuffer,         \
            ghix,            \
            i,               \
            j,               \
            l,               \
            update,          \
            ghptr            \
        )                    \
        shared(              \
            N,               \
            sources,         \
            targets,         \
            weights,         \
            allbuffer,       \
            khashes,         \
            nonmiss,         \
            diff,            \
            GtoolsHashInfo   \
        )
    #endif
    /**/
    for (k = 0; k < ktargets; k++) {
        diff[k] = 0;
        srcptr  = sources + k * N;
        trgptr  = targets + k * N;
        buffer  = allbuffer + N * k * GTOOLSOMP * 2;
        ghix    = 0;
        l       = 0;
        update  = 0;
        while (l < (khashes + (khashes - 1))) {
            ghptr = GtoolsHashInfo + order[ghix];
            memset(buffer, '\0', sizeof(buffer) * ghptr->nlevels * 2);
            wbuffer = buffer + ghptr->nlevels;

            // compute sums
            if ( update ) {
                for (i = 0; i < nonmiss; i++) {
                    buffer[ghptr->indexj[i]]  += trgptr[i] * weights[i];
                    wbuffer[ghptr->indexj[i]] += weights[i];
                }
            }
            else {
                for (i = 0; i < nonmiss; i++) {
                    buffer[ghptr->indexj[i]]  += srcptr[i] * weights[i];
                    wbuffer[ghptr->indexj[i]] += weights[i];
                }
            }

            // make means
            for (j = 0; j < ghptr->nlevels; j++) {
                buffer[j] /= wbuffer[j];
                diff[k]    = GTOOLS_PWMAX(diff[k], fabs(buffer[j]));
            }

            // update target
            if ( update ) {
                for (i = 0; i < nonmiss; i++) {
                    trgptr[i] -= buffer[ghptr->indexj[i]];
                }
            }
            else {
                for (i = 0; i < nonmiss; i++) {
                    trgptr[i] = srcptr[i] - buffer[ghptr->indexj[i]];
                }
            }

            update = 1;
            // ++l < khashes? ghptr++: ghptr--;
            ++l < khashes? ghix++: ghix--;
        }
    }

    return (GtoolsStatsMax(diff, ktargets));
}
