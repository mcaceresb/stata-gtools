void gf_quantiles_nq (
    ST_double *qout,
    ST_double *x,
    GT_size nquants,
    GT_size N,
    GT_size kx
);

void gf_quantiles (
    ST_double *qout,
    ST_double *x,
    ST_double *quants,
    GT_size nquants,
    GT_size N,
    GT_size kx
);

void gf_quantiles_nq_altdef (
    ST_double *qout,
    ST_double *x,
    GT_size nquants,
    GT_size N,
    GT_size kx
);

void gf_quantiles_altdef (
    ST_double *qout,
    ST_double *x,
    ST_double *quants,
    GT_size nquants,
    GT_size N,
    GT_size kx
);

void gf_quantiles_nq_qselect (
    ST_double *qout,
    ST_double *x,
    GT_size nquants,
    GT_size N
);

void gf_quantiles_qselect (
    ST_double *qout,
    ST_double *x,
    ST_double *quants,
    GT_size nquants,
    GT_size N
);

void gf_quantiles_nq_qselect_altdef (
    ST_double *qout,
    ST_double *x,
    GT_size nquants,
    GT_size N
);

void gf_quantiles_qselect_altdef (
    ST_double *qout,
    ST_double *x,
    ST_double *quants,
    GT_size nquants,
    GT_size N
);

void gf_quantiles_nq (
    ST_double *qout,
    ST_double *x,
    GT_size nquants,
    GT_size N,
    GT_size kx)
{
    GT_size i, q;
    ST_double qdbl;
    ST_double Ndbl  = (ST_double) N;
    ST_double nqdbl = (ST_double) nquants;

    for (i = 0; i < (nquants - 1); i++) {
        q = ceil(qdbl = ((i + 1) * Ndbl / nqdbl) - 1);
        qout[i] = x[kx * q];
        if ( (ST_double) q == qdbl ) {
            qout[i] += x[kx * q + kx];
            qout[i] /= 2;
        }
    }
    qout[nquants - 1] = x[kx * N - kx];
}

void gf_quantiles (
    ST_double *qout,
    ST_double *x,
    ST_double *quants,
    GT_size nquants,
    GT_size N,
    GT_size kx)
{
    GT_size i, q;
    ST_double qdbl;
    ST_double Ndbl = (ST_double) N;
    ST_double Ndiv = Ndbl / 100;

    if ( N % 100 ) { // Numerical precision foo...
        for (i = 0; i < nquants; i++) {
            q = ceil(qdbl = (quants[i] * Ndbl / 100) - 1);
            qout[i] = x[kx * q];
            if ( (ST_double) q == qdbl ) {
                qout[i] += x[kx * q + kx];
                qout[i] /= 2;
            }
        }
    }
    else {
        for (i = 0; i < nquants; i++) {
            q = ceil(qdbl = (quants[i] * Ndiv) - 1);
            qout[i] = x[kx * q];
            if ( (ST_double) q == qdbl ) {
                qout[i] += x[kx * q + kx];
                qout[i] /= 2;
            }
        }
    }
    qout[nquants] = x[kx * N - kx];
}

void gf_quantiles_nq_altdef (
    ST_double *qout,
    ST_double *x,
    GT_size nquants,
    GT_size N,
    GT_size kx)
{
    GT_size i, q;
    ST_double qdbl, qdiff;
    ST_double Ndbl  = (ST_double) N;
    ST_double nqdbl = (ST_double) nquants;

    for (i = 0; i < (nquants - 1); i++) {
        q = floor(qdbl = ((i + 1) * (Ndbl + 1) / nqdbl));
        if ( q > 0 ) {
            if ( q < N ) {
                q--;
                qout[i] = x[kx * q];
                if ( ((qdiff = (qdbl - 1 - (ST_double) q)) > 0) ) {
                    qout[i] *= (1 - qdiff);
                    qout[i] += qdiff * x[kx * q + kx];
                }
            }
            else {
                qout[i] = x[kx * N - kx];
            }
        }
        else {
            qout[i] = x[0];
        }
    }
    qout[nquants - 1] = x[kx * N - kx];
}

void gf_quantiles_altdef (
    ST_double *qout,
    ST_double *x,
    ST_double *quants,
    GT_size nquants,
    GT_size N,
    GT_size kx)
{
    GT_size i, q;
    ST_double qdbl, qdiff;
    ST_double Ndbl = (ST_double) N;
    ST_double Ndiv = (Ndbl + 1) / 100;

    if ( (N + 1) % 100 ) { // Numerical precision foo...
        for (i = 0; i < nquants; i++) {
            q = floor(qdbl = (quants[i] * (Ndbl + 1) / 100));
            if ( q > 0 ) {
                if ( q < N ) {
                    q--;
                    qout[i] = x[kx * q];
                    if ( ((qdiff = (qdbl - 1 - (ST_double) q)) > 0) ) {
                        qout[i] *= (1 - qdiff);
                        qout[i] += qdiff * x[kx * q + kx];
                    }
                }
                else {
                    qout[i] = x[kx * N - kx];
                }
            }
            else {
                qout[i] = x[0];
            }
        }
    }
    else {
        for (i = 0; i < nquants; i++) {
            q = floor(qdbl = (quants[i] * Ndiv));
            if ( q > 0 ) {
                if ( q < N ) {
                    q--;
                    qout[i] = x[kx * q];
                    if ( ((qdiff = (qdbl - 1 - (ST_double) q)) > 0) ) {
                        qout[i] *= (1 - qdiff);
                        qout[i] += qdiff * x[kx * q + kx];
                    }
                }
                else {
                    qout[i] = x[kx * N - kx];
                }
            }
            else {
                qout[i] = x[0];
            }
        }
    }
    qout[nquants] = x[kx * N - kx];
}

/*********************************************************************
 *                    Generic quantile selection                     *
 *********************************************************************/

void gf_quantiles_nq_qselect (
    ST_double *qout,
    ST_double *x,
    GT_size nquants,
    GT_size N)
{
    GT_size i, q, qstart;
    ST_double qdbl;
    ST_double Ndbl  = (ST_double) N;
    ST_double nqdbl = (ST_double) nquants;

    qstart = 0;
    for (i = 0; i < (nquants - 1); i++) {
        q = ceil(qdbl = ((i + 1) * Ndbl / nqdbl) - 1);
        qout[i] = gf_qselect_xtile (x + qstart, 0, N - qstart, q - qstart);
        if ( (ST_double) q == qdbl ) {
            qout[i] += gf_qselect_xtile (x + qstart, 0, N - qstart, q + 1 - qstart);
            qout[i] /= 2;
        }
        qstart = q;
    }
    qout[nquants - 1] = gf_array_dmax_range(x, 0, N);
}

void gf_quantiles_qselect (
    ST_double *qout,
    ST_double *x,
    ST_double *quants,
    GT_size nquants,
    GT_size N)
{
    GT_size i, q, qstart;
    ST_double qdbl;
    ST_double Ndbl = (ST_double) N;
    ST_double Ndiv = Ndbl / 100;

    qstart = 0;
    if ( N % 100 ) { // Numerical precision foo...
        for (i = 0; i < nquants; i++) {
            q = ceil(qdbl = (quants[i] * Ndbl / 100) - 1);
            qout[i] = gf_qselect_xtile (x + qstart, 0, N - qstart, q - qstart);
            if ( (ST_double) q == qdbl ) {
                qout[i] += gf_qselect_xtile (x + qstart, 0, N - qstart, q + 1 - qstart);
                qout[i] /= 2;
            }
            qstart = q;
        }
    }
    else {
        for (i = 0; i < nquants; i++) {
            q = ceil(qdbl = (quants[i] * Ndiv) - 1);
            qout[i] = gf_qselect_xtile (x + qstart, 0, N - qstart, q - qstart);
            if ( (ST_double) q == qdbl ) {
                qout[i] += gf_qselect_xtile (x + qstart, 0, N - qstart, q + 1 - qstart);
                qout[i] /= 2;
            }
            qstart = q;
        }
    }
    qout[nquants] = gf_array_dmax_range(x, 0, N);
}

void gf_quantiles_nq_qselect_altdef (
    ST_double *qout,
    ST_double *x,
    GT_size nquants,
    GT_size N)
{
    GT_size i, q, qstart;
    ST_double qdbl, qdiff;
    ST_double Ndbl  = (ST_double) N;
    ST_double nqdbl = (ST_double) nquants;

    qstart = 0;
    for (i = 0; i < (nquants - 1); i++) {
        q = floor(qdbl = ((i + 1) * (Ndbl + 1) / nqdbl));
        if ( q > 0 ) {
            if ( q < N ) {
                q--;
                qout[i] = gf_qselect_xtile (x + qstart, 0, N - qstart, q - qstart);
                if ( ((qdiff = (qdbl - 1 - (ST_double) q)) > 0) ) {
                    qout[i] *= (1 - qdiff);
                    qout[i] += qdiff * gf_qselect_xtile (x + qstart, 0, N - qstart, q + 1 - qstart);
                }
            }
            else {
                qout[i] = gf_array_dmax_range(x, 0, N);
            }
        }
        else {
            qout[i] = gf_array_dmin_range(x, 0, N);
        }
        qstart = q;
    }
    qout[nquants - 1] = gf_array_dmax_range(x, 0, N);
}

void gf_quantiles_qselect_altdef (
    ST_double *qout,
    ST_double *x,
    ST_double *quants,
    GT_size nquants,
    GT_size N)
{
    GT_size i, q, qstart;
    ST_double qdbl, qdiff;
    ST_double Ndbl = (ST_double) N;
    ST_double Ndiv = (Ndbl + 1) / 100;

    qstart = 0;
    if ( (N + 1) % 100 ) { // Numerical precision foo...
        for (i = 0; i < nquants; i++) {
            q = floor(qdbl = (quants[i] * (Ndbl + 1) / 100));
            if ( q > 0 ) {
                if ( q < N ) {
                    q--;
                    qout[i] = gf_qselect_xtile (x + qstart, 0, N - qstart, q - qstart);
                    if ( ((qdiff = (qdbl - 1 - (ST_double) q)) > 0) ) {
                        qout[i] *= (1 - qdiff);
                        qout[i] += qdiff * gf_qselect_xtile (x + qstart, 0, N - qstart, q + 1 - qstart);
                    }
                }
                else {
                    qout[i] = gf_array_dmax_range(x, 0, N);
                }
            }
            else {
                qout[i] = gf_array_dmin_range(x, 0, N);
            }
            qstart = q;
        }
    }
    else {
        for (i = 0; i < nquants; i++) {
            q = floor(qdbl = (quants[i] * Ndiv));
            if ( q > 0 ) {
                if ( q < N ) {
                    q--;
                    qout[i] = gf_qselect_xtile (x + qstart, 0, N - qstart, q - qstart);
                    if ( ((qdiff = (qdbl - 1 - (ST_double) q)) > 0) ) {
                        qout[i] *= (1 - qdiff);
                        qout[i] += qdiff * gf_qselect_xtile (x + qstart, 0, N - qstart, q + 1 - qstart);
                    }
                }
                else {
                    qout[i] = gf_array_dmax_range(x, 0, N);
                }
            }
            else {
                qout[i] = gf_array_dmin_range(x, 0, N);
            }
            qstart = q;
        }
    }
    qout[nquants] = gf_array_dmax_range(x, 0, N);
}
