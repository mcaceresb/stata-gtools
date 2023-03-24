GT_int GtoolsSaveAlphas(
    struct GtoolsHash *GtoolsHashInfo,
    GT_size   khashes,
    ST_double *source,
    ST_double *weights,
    ST_double *alphas,
    ST_double tol)
{
    GT_int rc = 0;
    GT_size iter = 0, feval = 0;
    ST_double diff   = 1;
    GT_size N        = GtoolsHashInfo->nobs;
    GT_size maxiter  = GtoolsHashInfo->hdfeMaxIter;
    GT_bool verbose  = GtoolsHashInfo->hdfeTraceIter;
    GT_size bufferk  = ((weights == NULL? 2: 3) + khashes) * N;
    ST_double *b = calloc(bufferk, sizeof *b); if ( b == NULL ) return(17902);

    // NB: It's fine to destroy the source here because this code is
    // only invoked with multiple FE, where the interest is recovering
    // each individual set, not their sum
    while ( ((iter++ < maxiter)? 1: maxiter == 0) && (diff > tol) ) {
        diff = GtoolsSaveAlphasAbsorb(GtoolsHashInfo, khashes, source, weights, alphas, tol, b);
        feval++;
        if ( verbose > 0 ) sf_printf("\tSaveAlphas ("GT_size_cfmt"): |x - x'| = %.9g\n", iter, diff);
    }

    GtoolsHashInfo->hdfeIter  = --iter;
    GtoolsHashInfo->hdfeFeval = feval;

    if ( verbose > 0 ) sf_printf("SaveAlphas: "GT_size_cfmt" iter ("GT_size_cfmt" max), "GT_size_cfmt" feval, %.9g diff (%.9g tol)\n",
                                 iter, maxiter, feval, diff, tol);

    if ( maxiter && iter >= maxiter ) rc = 18402;

    free(b);

    return(rc);
}

ST_double GtoolsSaveAlphasAbsorb(
    struct GtoolsHash *GtoolsHashInfo,
    GT_size   khashes,
    ST_double *source,
    ST_double *weights,
    ST_double *alphas,
    ST_double tol,
    ST_double *allbuffer)
{
    if ( weights == NULL ) {
        return (GtoolsSaveAlphasAbsorbUnweighted(
            GtoolsHashInfo,
            khashes,
            source,
            weights,
            alphas,
            tol,
            allbuffer
        ));
    }
    else {
        return (GtoolsSaveAlphasAbsorbWeighted(
            GtoolsHashInfo,
            khashes,
            source,
            weights,
            alphas,
            tol,
            allbuffer
        ));
    }
}

ST_double GtoolsSaveAlphasAbsorbUnweighted(
    struct GtoolsHash *GtoolsHashInfo,
    GT_size   khashes,
    ST_double *source,
    ST_double *weights,
    ST_double *alphas,
    ST_double tol,
    ST_double *allbuffer)
{
    GT_bool update;
    GT_size i, j, l;
    GT_size nonmiss = GtoolsHashInfo->_nobspanel;
    GT_size N = GtoolsHashInfo->nobs;
    ST_double *proj, *means, *buffer;
    ST_double SXY, SXX, coef, diff[khashes];
    struct GtoolsHash *ghptr;

    buffer  = allbuffer + (khashes+0) * N;
    proj    = allbuffer + (khashes+1) * N;
    ghptr   = GtoolsHashInfo;
    update  = 0;
    memcpy(proj, source, N * sizeof(ST_double));

    for (l = 0; l < khashes; l++, ghptr++) {
        diff[l] = 0;
        means = allbuffer + l * N;
        memset(buffer, '\0', sizeof(buffer) * ghptr->nlevels);

        // Compute the sum; this loops through src in order and
        // computes the total by level for the lth abs var
        if ( update ) {
            for (i = 0; i < nonmiss; i++) {
                buffer[ghptr->indexj[i]] += proj[i];
            }
        }
        else {
            for (i = 0; i < nonmiss; i++) {
                buffer[ghptr->indexj[i]] += source[i];
            }
        }

        // make means; this just divides by # obs
        for (j = 0; j < ghptr->nlevels; j++) {
            buffer[j] /= ghptr->nj[j];
            diff[l] = GTOOLS_PWMAX(diff[l], fabs(buffer[j]));
        }

        // update target
        if ( update ) {
            for (i = 0; i < nonmiss; i++) {
                means[i] = buffer[ghptr->indexj[i]];
                proj[i] -= means[i];
            }
        }
        else {
            for (i = 0; i < nonmiss; i++) {
                means[i] = buffer[ghptr->indexj[i]];
                proj[i]  = source[i] - means[i];
            }
        }
        update = 1;
    }

    for (i = 0; i < nonmiss; i++) {
        proj[i] = source[i] - proj[i];
    }
    SXY  = GtoolsStatsDot(proj, source, nonmiss, NULL);
    SXX  = GtoolsStatsSS(proj, nonmiss, NULL);
    coef = GtoolsStatsDivide(SXY, SXX);
    for (i = 0; i < nonmiss; i++) {
        source[i] -= coef * proj[i];
    }
    // for (l  = 0; l < khashes; l++, ghptr++) {
    //     alpha = alphas    + l * N;
    //     means = allbuffer + l * N;
    //     for (i = 0; i < nonmiss; i++) {
    //         alpha[i] += coef * means[i];
    //     }
    // }
    for (i = 0; i < nonmiss * khashes; i++) {
        alphas[i] += coef * allbuffer[i];
    }

    return(GtoolsStatsMax(diff, khashes));
}

ST_double GtoolsSaveAlphasAbsorbWeighted(
    struct GtoolsHash *GtoolsHashInfo,
    GT_size   khashes,
    ST_double *source,
    ST_double *weights,
    ST_double *alphas,
    ST_double tol,
    ST_double *allbuffer)
{
    GT_bool update;
    GT_size i, j, l;
    GT_size nonmiss = GtoolsHashInfo->_nobspanel;
    GT_size N = GtoolsHashInfo->nobs;
    ST_double *proj, *means, *buffer, *wbuffer;
    ST_double SXY, SXX, coef, diff[khashes];
    struct GtoolsHash *ghptr;

    buffer  = allbuffer + (khashes+0) * N;
    proj    = allbuffer + (khashes+1) * N;
    wbuffer = allbuffer + (khashes+2) * N;
    ghptr   = GtoolsHashInfo;
    update  = 0;
    memcpy(proj, source, N * sizeof(ST_double));

    for (l = 0; l < khashes; l++, ghptr++) {
        diff[l] = 0;
        means = allbuffer + l * N;
        memset(buffer,  '\0', sizeof(buffer)  * ghptr->nlevels);
        memset(wbuffer, '\0', sizeof(wbuffer) * ghptr->nlevels);

        // Compute the sum; this loops through src in order and
        // computes the total by level for the lth abs var
        if ( update ) {
            for (i = 0; i < nonmiss; i++) {
                buffer[ghptr->indexj[i]]  += weights[i] * proj[i];
                wbuffer[ghptr->indexj[i]] += weights[i];
            }
        }
        else {
            for (i = 0; i < nonmiss; i++) {
                buffer[ghptr->indexj[i]]  += weights[i] * source[i];
                wbuffer[ghptr->indexj[i]] += weights[i];
            }
        }

        // make means; this just divides by # obs
        for (j = 0; j < ghptr->nlevels; j++) {
            buffer[j] /= wbuffer[j];
            diff[l]    = GTOOLS_PWMAX(diff[l], fabs(buffer[j]));
        }

        // update target
        if ( update ) {
            for (i = 0; i < nonmiss; i++) {
                means[i] = buffer[ghptr->indexj[i]];
                proj[i] -= means[i];
            }
        }
        else {
            for (i = 0; i < nonmiss; i++) {
                means[i] = buffer[ghptr->indexj[i]];
                proj[i]  = source[i] - means[i];
            }
        }
        update = 1;
    }

    for (i = 0; i < nonmiss; i++) {
        proj[i] = source[i] - proj[i];
    }
    SXY  = GtoolsStatsDot(proj, source, nonmiss, weights);
    SXX  = GtoolsStatsSS(proj, nonmiss, weights);
    coef = GtoolsStatsDivide(SXY, SXX);
    for (i = 0; i < nonmiss; i++) {
        source[i] -= coef * proj[i];
    }
    // for (l  = 0; l < khashes; l++, ghptr++) {
    //     alpha = alphas    + l * N;
    //     means = allbuffer + l * N;
    //     for (i = 0; i < nonmiss; i++) {
    //         alpha[i] += coef * means[i];
    //     }
    // }
    for (i = 0; i < nonmiss * khashes; i++) {
        alphas[i] += coef * allbuffer[i];
    }

    return(GtoolsStatsMax(diff, khashes));
}
