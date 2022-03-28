/**********************************************************************
 *                         Conjugate Gradient                         *
 **********************************************************************/

GT_int GtoolsAlgorithmCG(
    struct GtoolsHash *GtoolsHashInfo,
    GT_size   khashes,
    ST_double *sources,
    ST_double *weights,
    ST_double *targets,
    GT_size   ktargets,
    ST_double tol)
{
    GT_int rc = 0;
    GT_size N        = GtoolsHashInfo->nobs;
    GT_size nonmiss  = GtoolsHashInfo->_nobspanel;
    GT_bool standard = GtoolsHashInfo->hdfeStandardize;
    GT_size maxiter  = GtoolsHashInfo->hdfeMaxIter;
    GT_bool verbose  = GtoolsHashInfo->hdfeTraceIter;

    ST_double idiff = 1, diff, buff;
    ST_double *xptr, *rptr, *uptr, *vptr, *x = targets;
    GT_size i, k, iter = 0, feval = 0;
    GT_size bufferk = (weights == NULL? 1: 2) * (GTOOLSOMP? ktargets: 1) * N;
    ST_double alpha[ktargets], beta[ktargets], rr[ktargets], r0[ktargets], xx[ktargets], r1[ktargets], sd[ktargets];

    ST_double *r = calloc(ktargets * N, sizeof *r);
    ST_double *u = calloc(ktargets * N, sizeof *u);
    ST_double *v = calloc(ktargets * N, sizeof *v);
    ST_double *b = calloc(bufferk,      sizeof *b);

    if ( r == NULL ) return(17902);
    if ( u == NULL ) return(17902);
    if ( v == NULL ) return(17902);
    if ( b == NULL ) return(17902);

    if ( sources != x ) {
        memcpy(x, sources, sizeof(ST_double) * ktargets * N);
    }

    if ( standard ) {
        xptr = x;
        for (k = 0; k < ktargets; k++, xptr += N) {
            GtoolsTransformBiasedStandardizeVector(xptr, xptr, weights, nonmiss, sd + k);
        }
    }

    // x = x0
    // r  = (I - T) x
    // rr = <r, r>
    // u  = r
    xptr = x;
    for (k = 0; k < ktargets; k++, xptr += N) {
        xx[k] = GtoolsStatsSS(xptr, nonmiss, weights);
    }

    feval++;
    diff = GtoolsAbsorbHalperinSymm(GtoolsHashInfo, khashes, x, weights, r, ktargets, tol, b);
    xptr = x;
    rptr = r;
    for (k = 0; k < ktargets; k++, xptr += N, rptr += N) {
        for (i = 0; i < nonmiss; i++) {
            rptr[i] = xptr[i] - rptr[i];
        }
    }

    rptr = r;
    for (k = 0; k < ktargets; k++, rptr += N) {
        rr[k] = GtoolsStatsSS(rptr, nonmiss, weights);
    }

    memcpy(u, r, sizeof(ST_double) * ktargets * N);

    if ( verbose > 0 ) printf("\tCG: |x - Tx| = %.9g\n", diff);
    while ( ((iter++ < maxiter)? 1: maxiter == 0) && (idiff > tol) ) {
        // v = (I - T) u
        feval++;
        diff = GtoolsAbsorbHalperinSymm(GtoolsHashInfo, khashes, u, weights, v, ktargets, tol, b);
        uptr = u;
        vptr = v;
        for (k = 0; k < ktargets; k++, uptr += N, vptr += N) {
            for (i = 0; i < nonmiss; i++) {
                vptr[i] = uptr[i] - vptr[i];
            }
        }

        // a = rr / <u, v>
        // convergence foo
        uptr = u;
        vptr = v;
        buff = 0;
        for (k = 0; k < ktargets; k++, uptr += N, vptr += N) {
            // NB: GtoolsStatsDivide forces (signed) division by 64-bit epsilon
            // instead of 0; avoids numerical imprecision and also helps when xx is
            // 0 (e.g. as would happen with collinear vars).
            alpha[k] = GtoolsStatsDivide(rr[k], GtoolsStatsDot(uptr, vptr, nonmiss, weights));
            r1[k]    = alpha[k] * rr[k];
            xx[k]   -= r1[k];
            buff     = GTOOLS_PWMAX(buff, GtoolsStatsDivide(r1[k], xx[k]));
        }

        // x  = x - a u
        // r  = r - a v
        // rr = <r, r>
        // b  = rr/r0
        xptr = x;
        uptr = u;
        vptr  = v;
        rptr  = r;
        for (k = 0; k < ktargets; k++, xptr += N, uptr += N, vptr += N, rptr += N) {
            for (i = 0; i < nonmiss; i++) {
                xptr[i] -= alpha[k] * uptr[i];
                rptr[i] -= alpha[k] * vptr[i];
            }
            r0[k]   = rr[k];
            rr[k]   = GtoolsStatsSS(rptr, nonmiss, weights);
            beta[k] = GtoolsStatsDivide(rr[k], r0[k]);
        }

        // u = r + b u
        rptr = r;
        uptr = u;
        for (k = 0; k < ktargets; k++, rptr += N, uptr += N) {
            for (i = 0; i < nonmiss; i++) {
                uptr[i] = rptr[i] + beta[k] * uptr[i];
            }
        }

        idiff = sqrt(buff);
        if ( verbose > 0 ) printf("\tCG (%lu): |improvement| = %12.9g, ||a r|| = %12.9g\n",
                                  iter, idiff, GtoolsStatsNorm(r1, ktargets, NULL));

        // Avoid numerical precision issues?
        diff = GtoolsStatsAbsMax(r1, ktargets);
        // This is the criterion in reghdfe:
        // if ( diff < GTOOLS_64BIT_EPSILON ) {
        // This is functionally the same with the default tolerance of
        // 1e-8 (which is approx. sqrt(GTOOLS_64BIT_EPSILON)). However,
        // with tighter/looser tolerances it will adapt.
        if ( sqrt(diff) < tol ) {
            if ( verbose > 0 ) printf("(note: CG algorithm eps. close to 0 (%.9f); ", diff);
            if ( verbose > 0 ) printf("assuming convergence to avoid numerical precision errors)\n");
            feval++;
            GtoolsAbsorbHalperinSymm(GtoolsHashInfo, khashes, x, weights, x, ktargets, tol, b);
            idiff = 0;
        }
    }

    if ( standard ) {
        xptr = x;
        for (k = 0; k < ktargets; k++, xptr += N) {
            if ( sd[k] != 0 ) GtoolsTransformScaleVector(x, x, nonmiss, sd[k]);
        }
    }
    GtoolsHashInfo->hdfeIter  = --iter;
    GtoolsHashInfo->hdfeFeval = feval;

    if ( verbose > 0 ) printf("CG: %lu iter (%lu max), %lu feval, %.9g diff (%.9g tol)\n",
                              iter, maxiter, feval, idiff, tol);

    if ( maxiter && iter >= maxiter ) rc = 18402;

    free(r);
    free(u);
    free(v);
    free(b);

    return(rc);
}

/**********************************************************************
 *                              SQUAREM                               *
 **********************************************************************/

GT_int GtoolsAlgorithmSQUAREM(
    struct GtoolsHash *GtoolsHashInfo,
    GT_size   khashes,
    ST_double *sources,
    ST_double *weights,
    ST_double *targets,
    GT_size   ktargets,
    ST_double tol)
{
    GT_int rc = 0;
    GT_size N        = GtoolsHashInfo->nobs;
    GT_size nonmiss  = GtoolsHashInfo->_nobspanel;
    GT_bool standard = GtoolsHashInfo->hdfeStandardize;
    GT_size maxiter  = GtoolsHashInfo->hdfeMaxIter;
    GT_bool verbose  = GtoolsHashInfo->hdfeTraceIter;

    ST_double alpha[ktargets], sr2[ktargets], sv2[ktargets], sd[ktargets];
    ST_double *xptr, *x1ptr, *x2ptr, *q1ptr, *q2ptr, *x = targets;
    ST_double diff, stepmax[ktargets], stepmin[ktargets], mstep;
    GT_size bufferk = (weights == NULL? 1: 2) * (GTOOLSOMP? ktargets: 1) * N;
    GT_size i, k, iter = 0, feval = 0;

    ST_double *x1 = calloc(ktargets * N, sizeof *x1);
    ST_double *x2 = calloc(ktargets * N, sizeof *x2);
    ST_double *q1 = calloc(ktargets * N, sizeof *q1);
    ST_double *q2 = calloc(ktargets * N, sizeof *q2);
    ST_double *b  = calloc(bufferk,      sizeof *b);

    if ( x1 == NULL ) return(17902);
    if ( x2 == NULL ) return(17902);
    if ( q1 == NULL ) return(17902);
    if ( q2 == NULL ) return(17902);
    if ( b  == NULL ) return(17902);

    diff  = 1.0;
    mstep = 4.0;
    for (k = 0; k < ktargets; k++) {
        stepmax[k] = 1.0;
        stepmin[k] = 1.0;
    }

    if ( sources != x ) {
        memcpy(x, sources, sizeof(ST_double) * ktargets * N);
    }

    if ( standard ) {
        xptr = x;
        for (k = 0; k < ktargets; k++, xptr += N) {
            GtoolsTransformBiasedStandardizeVector(xptr, xptr, weights, nonmiss, sd + k);
        }
    }

    if ( verbose > 0 ) printf("\tSQUAREM: |x - x'| = %.9g\n", diff);
    while ( ((iter++ < maxiter)? 1: maxiter == 0) && (diff > tol) ) {
        diff = GtoolsAbsorbHalperinBuffer(GtoolsHashInfo, khashes, x, weights, x1, ktargets, tol, b); feval++;
        if ( verbose > 0 ) printf("\tSQUAREM (%lu): |x - x'| = %12.9g\n", iter, diff);
        if ( diff < tol ) {
            memcpy(x, x1, sizeof(ST_double) * ktargets * N);
            break;
        }

        diff = GtoolsAbsorbHalperinBuffer(GtoolsHashInfo, khashes, x1, weights, x2, ktargets, tol, b); feval++;
        if ( verbose > 0 ) printf("\tSQUAREM (%lu): |x - x'| = %12.9g\n", iter, diff);
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
            for (i = 0; i < nonmiss; i++) {
                q1ptr[i]  = x1ptr[i] - xptr[i];
                q2ptr[i]  = x2ptr[i] - x1ptr[i] - q1ptr[i];
            }
            sr2[k] = GtoolsStatsSS(q1ptr, nonmiss, weights);
            sv2[k] = GtoolsStatsSS(q2ptr, nonmiss, weights);
        }

        for (k = 0; k < ktargets; k++) {
            alpha[k] = GTOOLS_PWMAX(stepmin[k], GTOOLS_PWMIN(stepmax[k], pow(sr2[k]/sv2[k], 0.5)));
        }

        xptr   = x;
        q1ptr  = q1;
        q2ptr  = q2;
        for (k = 0; k < ktargets; k++, xptr += N, q1ptr += N, q2ptr += N) {
            for (i = 0; i < nonmiss; i++) {
                xptr[i] += (2 * alpha[k] * q1ptr[i] + alpha[k] * alpha[k] * q2ptr[i]);
            }
        }

        diff = GtoolsAbsorbHalperinBuffer(GtoolsHashInfo, khashes, x, weights, x, ktargets, tol, b); feval++;
        if ( verbose > 0 ) printf("\tSQUAREM (%lu): |x - x'| = %12.9g\n", iter, diff);
        if ( diff < tol ) break;

        for (k = 0; k < ktargets; k++) {
            if (alpha[k] == stepmax[k]) stepmax[k] *= mstep;
            if ( (alpha[k] == stepmin[k]) && (alpha[k] < 0) ) stepmin[k] *= mstep;
        }
    }

    if ( standard ) {
        xptr = x;
        for (k = 0; k < ktargets; k++, xptr += N) {
            if ( sd[k] != 0 ) GtoolsTransformScaleVector(x, x, nonmiss, sd[k]);
        }
    }
    GtoolsHashInfo->hdfeIter  = --iter;
    GtoolsHashInfo->hdfeFeval = feval;

    if ( verbose > 0 ) printf("SQUAREM: %lu iter (%lu max), %lu feval, %.9g diff (%.9g tol)\n",
                              iter, maxiter, feval, diff, tol);

    if ( maxiter && iter >= maxiter ) rc = 18402;

    free(x1);
    free(x2);
    free(q1);
    free(q2);
    free(b);

    return(rc);
}

/**********************************************************************
 *                           Irons and Tuck                           *
 **********************************************************************/

GT_int GtoolsAlgorithmIronsTuck(
    struct GtoolsHash *GtoolsHashInfo,
    GT_size   khashes,
    ST_double *sources,
    ST_double *weights,
    ST_double *targets,
    GT_size   ktargets,
    ST_double tol)
{
    GT_int rc = 0;
    GT_size N        = GtoolsHashInfo->nobs;
    GT_size nonmiss  = GtoolsHashInfo->_nobspanel;
    GT_bool standard = GtoolsHashInfo->hdfeStandardize;
    GT_size maxiter  = GtoolsHashInfo->hdfeMaxIter;
    GT_bool verbose  = GtoolsHashInfo->hdfeTraceIter;

    ST_double diff = 1, step[ktargets], DgXD2X[ktargets], D2XD2X[ktargets], sd[ktargets];
    ST_double *xptr, *gXptr, *ggXptr, *DXptr, *DgXptr, *D2Xptr, *x = targets;
    GT_size bufferk = (weights == NULL? 1: 2) * (GTOOLSOMP? ktargets: 1) * N;
    GT_size i, k, iter = 0, feval = 0;

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

    if ( sources != x ) {
        memcpy(x, sources, sizeof(ST_double) * ktargets * N);
    }

    if ( standard ) {
        xptr = x;
        for (k = 0; k < ktargets; k++, xptr += N) {
            GtoolsTransformBiasedStandardizeVector(xptr, xptr, weights, nonmiss, sd + k);
        }
    }

    while ( ((iter++ < maxiter)? 1: maxiter == 0) && (diff > tol) ) {
        diff = GtoolsAbsorbHalperinBuffer(GtoolsHashInfo, khashes, x, weights, gX, ktargets, tol, b); feval++;
        if ( verbose > 0 ) printf("\tIT (%lu): |x - x'| = %12.9g\n", iter, diff);
        if ( diff < tol ) {
            memcpy(x, gX, sizeof(ST_double) * ktargets * N);
            break;
        }

        diff = GtoolsAbsorbHalperinBuffer(GtoolsHashInfo, khashes, gX, weights, ggX, ktargets, tol, b); feval++;
        if ( verbose > 0 ) printf("\tIT (%lu): |x - x'| = %12.9g\n", iter, diff);
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
            }
            DgXD2X[k] = GtoolsStatsDot(DgXptr, D2Xptr, nonmiss, weights);
            D2XD2X[k] = GtoolsStatsSS(D2Xptr, nonmiss, weights);
            // NB: GtoolsStatsDivide forces (signed) division by 64-bit epsilon
            // instead of 0; avoids numerical imprecision and also helps when xx is
            // 0 (e.g. as would happen with collinear vars).
            step[k]   = GtoolsStatsDivide(DgXD2X[k], D2XD2X[k]);
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

    if ( standard ) {
        xptr = x;
        for (k = 0; k < ktargets; k++, xptr += N) {
            if ( sd[k] != 0 ) GtoolsTransformScaleVector(x, x, nonmiss, sd[k]);
        }
    }
    GtoolsHashInfo->hdfeIter  = --iter;
    GtoolsHashInfo->hdfeFeval = feval;

    if ( verbose > 0 ) printf("IT: %lu iter (%lu max), %lu feval, %.9g diff (%.9g tol)\n",
                              iter, maxiter, feval, diff, tol);

    if ( maxiter && iter >= maxiter ) rc = 18402;

    free(gX);
    free(ggX);
    free(DX);
    free(DgX);
    free(D2X);
    free(b);

    return(rc);
}
