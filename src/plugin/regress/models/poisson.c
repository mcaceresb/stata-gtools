void gf_regress_poisson_init_unw(
    ST_double *yptr,
    ST_double *wptr,
    ST_double *mu,
    ST_double *eta,
    ST_double *dev,
    ST_double *lhs,
    GT_size nj)
{
    GT_size i;
    ST_double mean = 0;
    for (i = 0; i < nj; i++) {
        mean += yptr[i];
    }
    mean /= (ST_double) nj;
    for (i = 0; i < nj; i++) {
        mu[i]  = (yptr[i] + mean) / 2;
        eta[i] = log(mu[i]);
        dev[i] = 0;
        lhs[i] = eta[i] + (yptr[i] / mu[i] - 1);
    }
}

void gf_regress_poisson_init_w(
    ST_double *yptr,
    ST_double *wptr,
    ST_double *mu,
    ST_double *eta,
    ST_double *dev,
    ST_double *lhs,
    GT_size nj)
{
    GT_size i;
    ST_double mean = 0;
    ST_double W = 0;
    for (i = 0; i < nj; i++) {
        mean += yptr[i] * wptr[i];
        W += wptr[i];
    }
    mean /= (ST_double) W;
    for (i = 0; i < nj; i++) {
        mu[i]  = (yptr[i] + mean) / 2;
        eta[i] = log(mu[i]);
        dev[i] = 0;
        lhs[i] = eta[i] + (yptr[i] - mu[i]) / mu[i];
        mu[i] *= wptr[i];
    }
}

ST_double gf_regress_poisson_iter_unw(
    ST_double *yptr,
    ST_double *wptr,
    ST_double *e,
    ST_double *mu,
    ST_double *eta,
    ST_double *dev,
    ST_double *dev0,
    ST_double *lhs,
    GT_size nj)
{
    GT_size i;
    ST_double diff = 0;
    for (i = 0; i < nj; i++) {
        eta[i]  = lhs[i] - e[i];
        mu[i]   = exp(eta[i]);
        lhs[i]  = eta[i] + (yptr[i] / mu[i] - 1);
        dev0[i] = dev[i];
        // is dropping these OK?
        dev[i]  = yptr[i] > 0? 2 * (log(yptr[i] / mu[i]) - (yptr[i] - mu[i])): 0;
        diff    = GTOOLS_PWMAX(diff, fabs(dev[i] - dev0[i]) / (fabs(dev0[i]) + 1));
    }
    return (diff);
}

ST_double gf_regress_poisson_iter_w(
    ST_double *yptr,
    ST_double *wptr,
    ST_double *e,
    ST_double *mu,
    ST_double *eta,
    ST_double *dev,
    ST_double *dev0,
    ST_double *lhs,
    GT_size nj)
{
    GT_size i;
    ST_double diff = 0;
    for (i = 0; i < nj; i++) {
        eta[i]  = lhs[i] - e[i];
        mu[i]   = exp(eta[i]);
        lhs[i]  = eta[i] + (yptr[i] / mu[i] - 1);
        dev0[i] = dev[i];
        // is dropping these OK?
        dev[i]  = yptr[i] > 0? 2 * (log(yptr[i] / mu[i]) - (yptr[i] - mu[i])): 0;
        mu[i]  *= wptr[i];
        diff    = GTOOLS_PWMAX(diff, fabs(dev[i] - dev0[i]) / (fabs(dev0[i]) + 1));
    }
    return (diff);
}

ST_retcode gf_regress_poisson_post(
    GT_bool wcode,
    ST_double *wptr,
    ST_double *e,
    ST_double *mu,
    GT_size nj,
    ST_double diff,
    ST_double poistol,
    GT_size poisiter,
    char *buf1)
{
    GT_size i;
    if ( diff < poistol ) {
        if ( wcode == 2 ) {
            for (i = 0; i < nj; i++) {
                e[i] *= mu[i] / wptr[i];
            }
            memcpy(mu, wptr, nj * sizeof(ST_double));
        }
        return(0);
    }
    else {
        sf_format_size(poisiter, buf1);
        sf_errprintf("max iter (%s) reached; tolerance not achieved (%15.9g > %15.9g)\n",
                     buf1, diff, poistol);
        return(198);
    }
}
