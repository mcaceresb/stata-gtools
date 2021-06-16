void gf_regress_logit_init_unw(
    ST_double *yptr,
    ST_double *wptr,
    ST_double *mu,
    ST_double *wgt,
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
        eta[i] = log(mu[i] / (1 - mu[i]));
        wgt[i] = mu[i] * (1 - mu[i]);
        dev[i] = 0;
        lhs[i] = eta[i] + (yptr[i] - mu[i]) / wgt[i];
    }
}

void gf_regress_logit_init_w(
    ST_double *yptr,
    ST_double *wptr,
    ST_double *mu,
    ST_double *wgt,
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
        mu[i]   = (yptr[i] + mean) / 2;
        eta[i]  = log(mu[i] / (1 - mu[i]));
        wgt[i]  = mu[i] * (1 - mu[i]);
        dev[i]  = 0;
        lhs[i]  = eta[i] + (yptr[i] - mu[i]) / wgt[i];
        wgt[i] *= wptr[i];
    }
}

ST_double gf_regress_logit_iter_unw(
    ST_double *yptr,
    ST_double *wptr,
    ST_double *e,
    ST_double *mu,
    ST_double *wgt,
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
        mu[i]   = 1 / (1 + exp(-eta[i]));
        wgt[i]  = mu[i] * (1 - mu[i]);
        lhs[i]  = eta[i] + (yptr[i] - mu[i]) / wgt[i];
        dev0[i] = dev[i];
        dev[i]  = - 2 * (yptr[i] * log(mu[i]) + (1 - yptr[i]) * log(1 - mu[i]));
        diff    = GTOOLS_PWMAX(diff, fabs(dev[i] - dev0[i]) / (fabs(dev0[i]) + 1));
    }
    return (diff);
}

ST_double gf_regress_logit_iter_w(
    ST_double *yptr,
    ST_double *wptr,
    ST_double *e,
    ST_double *mu,
    ST_double *wgt,
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
        mu[i]   = 1 / (1 + exp(-eta[i]));
        wgt[i]  = mu[i] * (1 - mu[i]);
        lhs[i]  = eta[i] + (yptr[i] - mu[i]) / wgt[i];
        dev0[i] = dev[i];
        dev[i]  = - 2 * (yptr[i] * log(mu[i]) + (1 - yptr[i]) * log(1 - mu[i]));
        diff    = GTOOLS_PWMAX(diff, fabs(dev[i] - dev0[i]) / (fabs(dev0[i]) + 1));
        wgt[i] *= wptr[i];
    }
    return (diff);
}
