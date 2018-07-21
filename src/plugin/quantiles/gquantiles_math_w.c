#include "gquantiles_math_w.h"

void gf_quantiles_nq_w (
    ST_double *qout,
    ST_double *x,
    GT_size nquants,
    GT_size N,
    GT_size kx)
{
    GT_size i, ix, rfoo;
    ST_double Ndbl;
    ST_double nqdbl;
    ST_double qdbl, cumsum, cumnorm, wsum, wnorm;
    GT_size   Ndiv;
    GT_size   Nmod = N % nquants;

    // With weights, you can't pull off any numerical precision tricks!

    ix   = 0;
    wsum = 0;
    for (i = 0; i < N; i++)
        wsum += x[kx * i + 1];

    cumsum  = 0;
    cumnorm = ((ST_double) N) / wsum;

    if ( Nmod ) { // Numerical precision foo...
        for (i = 0; i < (nquants - 1); i++) {
            Ndiv  = gf_quantiles_gcd(nquants, Nmod);
            Ndbl  = N / Ndiv;
            nqdbl = nquants / Ndiv;
            qdbl  = Ndbl * ((i + 1) / nqdbl);

            do {
                cumsum += (wnorm = x[kx * ix + 1] * cumnorm);
            } while ( ((cumsum - qdbl) < GTOOLS_WQUANTILES_TOL) & (++ix < N) );
            ix     -= 1;
            cumsum -= wnorm;
            rfoo    = !((qdbl - cumsum) > GTOOLS_WQUANTILES_TOL);

            if ( rfoo && (ix > 0) ) {
                if ( x[kx * (ix - 1)] == x[kx * ix] ) {
                    qout[i] = x[kx * (ix - 1)];
                }
                else {
                    qout[i] = (x[kx * (ix - 1)] + x[kx * ix]) / 2;
                }
            }
            else {
                qout[i] = x[kx * ix];
            }
        }
    }
    else {
        Ndiv = N / nquants;
        for (i = 0; i < (nquants - 1); i++) {
            qdbl = (i + 1) * Ndiv;

            do {
                cumsum += (wnorm = x[kx * ix + 1] * cumnorm);
            } while ( ((cumsum - qdbl) < GTOOLS_WQUANTILES_TOL) & (++ix < N) );
            ix     -= 1;
            cumsum -= wnorm;
            rfoo    = !((qdbl - cumsum) > GTOOLS_WQUANTILES_TOL);

            if ( rfoo && (ix > 0) ) {
                if ( x[kx * (ix - 1)] == x[kx * ix] ) {
                    qout[i] = x[kx * (ix - 1)];
                }
                else {
                    qout[i] = (x[kx * (ix - 1)] + x[kx * ix]) / 2;
                }
            }
            else {
                qout[i] = x[kx * ix];
            }
        }
    }
    qout[nquants - 1] = x[kx * N - kx];
}

void gf_quantiles_w (
    ST_double *qout,
    ST_double *x,
    ST_double *quants,
    GT_size nquants,
    GT_size N,
    GT_size kx)
{
    GT_size i, ix;
    ST_double qdbl, cumsum, cumnorm, wsum, wnorm;
    ST_double Ndbl = (ST_double) N;
    GT_size   Nmod = N % 100;
    ST_double Ndiv;
    GT_bool   rfoo;

    // When you get q = qth * N / 100, there are 3 possible results:
    //
    //     a) ceil(q) == q
    //     b) ceil(q) > q
    //     c) ceil(q) > q but  qth == (ceil(q)  * N / 100)
    //                    or   qth == (floor(q) * N / 100)
    //                    i.e. qth == (round(q) * N / 100)
    //
    // In the first case, you want (x(q) + x(q + 1)) / 2.  In the second
    // case you want x(ceil(q)). However, in the third case you ALSO want
    // (x(q) + x(q + 1)). The third case can happen because of numerical
    // (im)precicion issues with representing integers as doubles.
    //
    // The check below is better than the naive ceil(q) == q
    // because that can lead to rounding errors.

    ix   = 0;
    wsum = 0;
    for (i = 0; i < N; i++)
        wsum += x[kx * i + 1];

    cumsum  = 0;
    cumnorm = Ndbl / wsum;

    if ( Nmod ) {
        for (i = 0; i < nquants; i++) {
            qdbl = quants[i] * Ndbl / 100;

            do {
                cumsum += (wnorm = x[kx * ix + 1] * cumnorm);
            } while ( ((cumsum - qdbl) < GTOOLS_WQUANTILES_TOL) & (++ix < N) );
            ix     -= 1;
            cumsum -= wnorm;
            rfoo    = !((qdbl - cumsum) > GTOOLS_WQUANTILES_TOL);

            if ( rfoo && (ix > 0) ) {
                if ( x[kx * (ix - 1)] == x[kx * ix] ) {
                    qout[i] = x[kx * (ix - 1)];
                }
                else {
                    qout[i] = (x[kx * (ix - 1)] + x[kx * ix]) / 2;
                }
            }
            else {
                qout[i] = x[kx * ix];
            }
        }
    }
    else {
        Ndiv = N / 100;
        for (i = 0; i < nquants; i++) {
            qdbl = quants[i] * Ndiv;

            do {
                cumsum += (wnorm = x[kx * ix + 1] * cumnorm);
            } while ( ((cumsum - qdbl) < GTOOLS_WQUANTILES_TOL) & (++ix < N) );
            ix     -= 1;
            cumsum -= wnorm;
            rfoo    = !((qdbl - cumsum) > GTOOLS_WQUANTILES_TOL);

            if ( rfoo && (ix > 0) ) {
                if ( x[kx * (ix - 1)] == x[kx * ix] ) {
                    qout[i] = x[kx * (ix - 1)];
                }
                else {
                    qout[i] = (x[kx * (ix - 1)] + x[kx * ix]) / 2;
                }
            }
            else {
                qout[i] = x[kx * ix];
            }
        }
    }
    qout[nquants] = x[kx * N - kx];
}
