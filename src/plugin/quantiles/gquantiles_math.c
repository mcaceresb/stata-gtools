#include "gquantiles_math.h"

GT_size gf_quantiles_gcd (
    GT_size a,
    GT_size b)
{
    GT_size _b = a % b;
    GT_size _a = b;
    GT_size  t = _b;
    while ( _b ) {
        _b = _a % _b;
        _a = t;
         t = _b;
    }
    return (_a);
}

void gf_quantiles_nq (
    ST_double *qout,
    ST_double *x,
    GT_size nquants,
    GT_size N,
    GT_size kx)
{
    GT_size i, q, rfoo;
    ST_double Ndbl;
    ST_double nqdbl;
    GT_size   nqdiv;
    GT_size   Ndiv;
    GT_size   Nmod = N % nquants;

    if ( Nmod ) { // Numerical precision foo...
        Ndiv  = gf_quantiles_gcd(nquants, Nmod);
        Ndbl  = N / Ndiv;
        nqdbl = (nqdiv = (nquants / Ndiv));

        for (i = 0; i < (nquants - 1); i++) {
            rfoo = (i + 1) % nqdiv;
            if ( rfoo ) {
                q = ceil((i + 1) * Ndbl / nqdbl) - 1;
                qout[i] = x[kx * q];
            }
            else {
                q = Ndbl * ((i + 1) / nqdbl);
                if ( x[kx * (q - 1)] == x[kx * q] ) {
                    qout[i] = x[kx * (q - 1)];
                }
                else {
                    qout[i] = (x[kx * (q - 1)] + x[kx * q]) / 2;
                }
            }
        }
    }
    else {
        Ndiv = N / nquants;
        for (i = 1; i < nquants; i++) {
            q = i * Ndiv;
            if ( x[kx * (q - 1)] == x[kx * q] ) {
                qout[i - 1] = x[kx * (q - 1)];
            }
            else {
                qout[i - 1] = (x[kx * (q - 1)] + x[kx * q]) / 2;
            }
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
    GT_size i, q, qfoo;
    ST_double qdbl;
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

    if ( Nmod ) {
        for (i = 0; i < nquants; i++) {
            qdbl = quants[i] * Ndbl / 100;
            qfoo = round(qdbl);
            rfoo = ((qfoo * 100 / Ndbl) == quants[i]);
            if ( rfoo ) {
                if ( x[kx * (qfoo - 1)] == x[kx * qfoo] ) {
                    qout[i] = x[kx * (qfoo - 1)];
                }
                else {
                    qout[i] = (x[kx * (qfoo - 1)] + x[kx * qfoo]) / 2;
                }
            }
            else {
                q = ceil(qdbl) - 1;
                qout[i] = x[kx * q];
            }
        }
    }
    else {
        Ndiv = N / 100;
        for (i = 0; i < nquants; i++) {
            qdbl = quants[i] * Ndiv;
            qfoo = round(qdbl);
            rfoo = ((qfoo / Ndiv) == quants[i]);
            if ( rfoo ) {
                if ( x[kx * (qfoo - 1)] == x[kx * qfoo] ) {
                    qout[i] = x[kx * (qfoo - 1)];
                }
                else {
                    qout[i] = (x[kx * (qfoo - 1)] + x[kx * qfoo]) / 2;
                }
            }
            else {
                q = ceil(qdbl) - 1;
                qout[i] = x[kx * q];
            }
        }
    }
    qout[nquants] = x[kx * N - kx];
}

/**
 * @brief Compute nq quantiles using alternative definition
 *
 * XX
 *
 * @param qout
 * @param x
 * @param nquants
 * @param N
 * @param kx
 *
 * @return Stores nq quantiles of x in qout
 *
 * @note XX
 * @warning XX
 */
void gf_quantiles_nq_altdef (
    ST_double *qout,
    ST_double *x,
    GT_size nquants,
    GT_size N,
    GT_size kx)
{

    // Note that when computing quantiles, altdef makes it so these
    // numerical precision issues are minimized because it is a convex
    // combination that takes into account which number is closest to
    // the quantile in question.
    //
    // However, when you run into numerical precision issues this
    // number, while close, will not be exact. This becomes a noticeable
    // problem when computing xtile because it relies on comparisons.
    // Hence you might get different results with an exact quantile vs
    // an approximate one.

    GT_size i, q, rfoo;
    ST_double Ndbl, nqdbl, qdbl, qdiff;
    GT_size nqdiv, Ndiv, Nmod;

    // If the number of quantiles divides N + 1, then it is better for
    // numerical precision to compute (N + 1) / nquants exactly using
    // integer division.

    Nmod = (N + 1) % nquants;
    if ( Nmod ) {

        // In this case we find the greatest common divisor and reduce
        // the fraction, N / NQ, to its lowest form. This is merely
        // using Euclid's algorithm: GCD(A, B) = GCB(B, A mod B)

        Ndiv  = gf_quantiles_gcd(nquants, Nmod);
        Ndbl  = (N + 1) / Ndiv;
        nqdbl = (nqdiv = (nquants / Ndiv));

        for (i = 0; i < (nquants - 1); i++) {
            q = floor(qdbl = ((i + 1) * Ndbl / nqdbl));
            if ( q > 0 ) {      // The 0th quantile is the min
                if ( q < N ) {  // The Nth quantile is the max

                    // If 0 < q < N, then figure out if we again have an
                    // exact quantile. That is, if q = floor(qdbl). This
                    // will be the case if (NQ / GCD(N, NQ)) divides (i + 1).

                    rfoo = (i + 1) % nqdiv;
                    if ( rfoo ) {

                        // If the division is not exact, then q =/= floor(qdbl)
                        // and the formula applies. Note that if the two numbers
                        // are the same we avoid the multiplication for numerical
                        // precision purposes.

                        if ( x[kx * (q - 1)] == x[kx * q] ) {
                            qout[i] = x[kx * (q - 1)];
                        }
                        else {
                            qdiff   = (qdbl - q);
                            qout[i] = (1 - qdiff) * x[kx * (q - 1)] + qdiff * x[kx * q];
                        }
                    }
                    else {

                        // If the division is exact, then (qdbl - q) = 0
                        // and we can simplify the formula. Mathematically
                        // speaking none of this makes a difference, but
                        // since not all numbers can be represented exactly
                        // in binary, we need these workarounds to preserve
                        // numerical precision.

                        qout[i] = x[kx * (q - 1)];
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

        // In this case you know that every quantile will be transformed
        // to an exact integer, so q == floor(qdbl) and h = qdbl - q is
        // 0. Thus we can pick out q exactly.

        Ndiv = (N + 1) / nquants;
        for (i = 1; i < nquants; i++) {
            q = i * Ndiv - 1;
            qout[i - 1] = x[kx * q];
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
    GT_size i, q, qfoo;
    ST_double qdbl, qdiff, Ndiv;
    ST_double Ndbl = (ST_double) N + 1;
    GT_size   Nmod = (N + 1) % 100;
    GT_bool   rfoo;

    // See various notes on numerical precision in
    //
    //     gf_quantiles
    //     gf_quantiles_nq_altdef
    //
    // for an explanation.

    if ( Nmod ) {
        for (i = 0; i < nquants; i++) {
            q = floor(qdbl = (quants[i] * Ndbl / 100));
            if ( q > 0 ) {
                if ( q < N ) {

                    // Here the idea is similar, but the check is a little
                    // different. q might be floor(qdbl) or it might be
                    // floor(qdbl - 1) due to numerical (im)precision. If
                    // inverting round(qdbl) gives qdbl then it must be that
                    // floor(qdbl) = q.  Hence (qdbl - q) = 0.

                    qfoo = round(qdbl);
                    rfoo = ((qfoo * 100 / Ndbl) == quants[i]);

                    if ( rfoo ) {
                        qout[i] = x[kx * (qfoo - 1)];
                    }
                    else if ( x[kx * (q - 1)] == x[kx * q] ) {

                        // We take the average of two numbers.  If they
                        // are the same then the average is just the
                        // number and there is no reason to introduce
                        // additional operations (the more operations
                        // the worse for numerical precision)

                        qout[i] = x[kx * (q - 1)];
                    }
                    else {
                        qdiff   = (qdbl - q);
                        qout[i] = (1 - qdiff) * x[kx * (q - 1)] + qdiff * x[kx * q];
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
        Ndiv = (N + 1) / 100;
        for (i = 0; i < nquants; i++) {
            q = floor(qdbl = (quants[i] * Ndiv));
            if ( q > 0 ) {
                if ( q < N ) { // Same notes as above
                    qfoo = round(qdbl);
                    rfoo = ((qfoo / Ndiv) == quants[i]);
                    if ( rfoo ) {
                        qout[i] = x[kx * (qfoo - 1)];
                    }
                    else if ( x[kx * (q - 1)] == x[kx * q] ) {
                        qout[i] = x[kx * (q - 1)];
                    }
                    else {
                        qdiff   = (qdbl - q);
                        qout[i] = (1 - qdiff) * x[kx * (q - 1)] + qdiff * x[kx * q];
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
    GT_size i, q, qstart, rfoo;
    ST_double Ndbl;
    ST_double nqdbl;
    ST_double qlo, qhi;
    GT_size   nqdiv;
    GT_size   Ndiv;
    GT_size   Nmod = N % nquants;

    qstart = 0;
    if ( Nmod ) {
        Ndiv  = gf_quantiles_gcd(nquants, Nmod);
        Ndbl  = N / Ndiv;
        nqdbl = (nqdiv = (nquants / Ndiv));

        for (i = 0; i < (nquants - 1); i++) {
            rfoo = (i + 1) % nqdiv;
            if ( rfoo ) {
                q = ceil((i + 1) * Ndbl / nqdbl) - 1;
                qout[i] = gf_qselect_xtile (x + qstart, 0, N - qstart, q - qstart);
                qstart = q;
            }
            else {
                q   = Ndbl * ((i + 1) / nqdbl) - 1;
                qlo = gf_qselect_xtile (
                    x + qstart,
                    0,
                    N - qstart,
                    q - qstart
                );
                qstart = q;
                qhi = gf_qselect_xtile (
                    x + qstart,
                    0,
                    N - qstart,
                    1
                );
                qout[i] = (qlo == qhi)? qlo: (qlo + qhi) / 2;
            }
        }
    }
    else {
        Ndiv = N / nquants;
        for (i = 1; i < nquants; i++) {
            q   = i * Ndiv - 1;
            qlo = gf_qselect_xtile (
                x + qstart,
                0,
                N - qstart,
                q - qstart
            );
            qstart = q;
            qhi = gf_qselect_xtile (
                x + qstart,
                0,
                N - qstart,
                1
            );
            qout[i - 1] = (qlo == qhi)? qlo: (qlo + qhi) / 2;
        }
    }
    qout[nquants - 1] = gf_array_dmax_range(x, qstart, N);
}

void gf_quantiles_qselect (
    ST_double *qout,
    ST_double *x,
    ST_double *quants,
    GT_size nquants,
    GT_size N)
{
    GT_size i, q, qstart, qfoo;
    ST_double qdbl, qhi, qlo;
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

    qstart = 0;
    if ( Nmod ) { // Numerical precision foo...
        for (i = 0; i < nquants; i++) {
            // More numerical precision foo...
            qdbl = quants[i] * Ndbl / 100;
            qfoo = round(qdbl);
            rfoo = ((qfoo * 100 / Ndbl) == quants[i]);
            if ( rfoo ) {
                q   = qfoo - 1;
                qlo = gf_qselect_xtile (
                    x + qstart,
                    0,
                    N - qstart,
                    q - qstart
                );
                qstart = q;
                qhi = gf_qselect_xtile (
                    x + qstart,
                    0,
                    N - qstart,
                    1
                );
                qout[i] = (qlo == qhi)? qlo: (qlo + qhi) / 2;
            }
            else {
                q = ceil(qdbl) - 1;
                qout[i] = gf_qselect_xtile (x + qstart, 0, N - qstart, q - qstart);
                qstart = q;
            }
        }
    }
    else {
        Ndiv = N / 100;
        for (i = 0; i < nquants; i++) {
            qdbl = quants[i] * Ndiv;
            qfoo = round(qdbl);
            rfoo = ((qfoo / Ndiv) == quants[i]);
            if ( rfoo ) {
                q = qfoo - 1;
                qlo = gf_qselect_xtile (
                    x + qstart,
                    0,
                    N - qstart,
                    q - qstart
                );
                qstart = q;
                qhi = gf_qselect_xtile (
                    x + qstart,
                    0,
                    N - qstart,
                    1
                );
                qout[i] = (qlo == qhi)? qlo: (qlo + qhi) / 2;
            }
            else {
                q = ceil(qdbl) - 1;
                qout[i] = gf_qselect_xtile (x + qstart, 0, N - qstart, q - qstart);
                qstart = q;
            }
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
    GT_size i, q, qstart, rfoo;
    ST_double Ndbl, nqdbl, qdbl, qdiff, qhi, qlo;
    GT_size nqdiv, Ndiv, Nmod;


    // See notes in gf_quantiles_nq_altdef

    Nmod   = (N + 1) % nquants;
    qstart = 0;
    if ( Nmod ) {

        Ndiv  = gf_quantiles_gcd(nquants, Nmod);
        Ndbl  = (N + 1) / Ndiv;
        nqdbl = (nqdiv = (nquants / Ndiv));

        for (i = 0; i < (nquants - 1); i++) {
            q = floor(qdbl = ((i + 1) * Ndbl / nqdbl));
            if ( q > 0 ) {
                if ( q < N ) {
                    rfoo = (i + 1) % nqdiv;
                    if ( rfoo ) {
                        qdiff   = (qdbl - q);
                        q--;    
                        qlo     = gf_qselect_xtile(x + qstart, 0, N - qstart, q - qstart);
                        qstart  = q;
                        qhi     = gf_qselect_xtile(x + qstart, 0, N - qstart, 1);
                        qout[i] = (qlo == qhi)? qlo: (1 - qdiff) * qlo + qdiff * qhi;
                    }
                    else {
                        q--;
                        qout[i] = gf_qselect_xtile(x + qstart, 0, N - qstart, q - qstart);
                        qstart  = q;
                    }
                }
                else {
                    qout[i] = gf_array_dmax_range(x, qstart, N);
                }
            }
            else {
                qout[i] = gf_array_dmin_range(x, 0, N);
            }
        }
    }
    else {
        Ndiv = (N + 1) / nquants;
        for (i = 1; i < nquants; i++) {
            q = i * Ndiv - 1;
            qout[i - 1] = gf_qselect_xtile(x + qstart, 0, N - qstart, q - qstart);
            qstart = q;
        }
    }
    qout[nquants - 1] = gf_array_dmax_range(x, qstart, N);
}

void gf_quantiles_qselect_altdef (
    ST_double *qout,
    ST_double *x,
    ST_double *quants,
    GT_size nquants,
    GT_size N)
{
    GT_size i, q, qstart, qfoo;
    ST_double qdbl, qdiff, Ndiv, qhi, qlo;
    ST_double Ndbl = (ST_double) N + 1;
    GT_size   Nmod = (N + 1) % 100;
    GT_bool   rfoo;

    // See various notes on numerical precision in
    //
    //     gf_quantiles
    //     gf_quantiles_nq_altdef
    //
    // for an explanation.

    qstart = 0;
    if ( Nmod ) {
        for (i = 0; i < nquants; i++) {
            q = floor(qdbl = (quants[i] * Ndbl / 100));
            if ( q > 0 ) {
                if ( q < N ) {
                    qfoo = round(qdbl);
                    rfoo = ((qfoo * 100 / Ndbl) == quants[i]);

                    if ( rfoo ) {
                        q        = qfoo - 1;
                        qout[i]  = gf_qselect_xtile(x + qstart, 0, N - qstart, q - qstart);
                        qstart   = q;
                    }
                    else {
                        qdiff   = (qdbl - q);
                        q--;
                        qlo     = gf_qselect_xtile(x + qstart, 0, N - qstart, q - qstart);
                        qstart  = q;
                        qhi     = gf_qselect_xtile(x + qstart, 0, N - qstart, 1);
                        qout[i] = (qlo == qhi)? qlo: (1 - qdiff) * qlo + qdiff * qhi;
                    }
                }
                else {
                    qout[i] = gf_array_dmax_range(x, qstart, N);
                }
            }
            else {
                qout[i] = gf_array_dmin_range(x, 0, N);
            }
        }
    }
    else {
        Ndiv = (N + 1) / 100;
        for (i = 0; i < nquants; i++) {
            q = floor(qdbl = (quants[i] * Ndiv));
            if ( q > 0 ) {
                if ( q < N ) {
                    qfoo = round(qdbl);
                    rfoo = ((qfoo / Ndiv) == quants[i]);

                    if ( rfoo ) {
                        q        = qfoo - 1;
                        qout[i]  = gf_qselect_xtile(x + qstart, 0, N - qstart, q - qstart);
                        qstart   = q;
                    }
                    else {
                        qdiff   = (qdbl - q);
                        q--;    
                        qlo     = gf_qselect_xtile(x + qstart, 0, N - qstart, q - qstart);
                        qstart  = q;
                        qhi     = gf_qselect_xtile(x + qstart, 0, N - qstart, 1);
                        qout[i] = (qlo == qhi)? qlo: (1 - qdiff) * qlo + qdiff * qhi;
                    }
                }
                else {
                    qout[i] = gf_array_dmax_range(x, qstart, N);
                }
            }
            else {
                qout[i] = gf_array_dmin_range(x, 0, N);
            }
        }
    }
    qout[nquants] = gf_array_dmax_range(x, qstart, N);
}
