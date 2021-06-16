ST_retcode gf_regress_glm_post(
    GT_bool wcode,
    ST_double *wptr,
    ST_double *e,
    ST_double *wgt,
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
                e[i] *= wgt[i] / wptr[i];
            }
            memcpy(wgt, wptr, nj * sizeof(ST_double));
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
