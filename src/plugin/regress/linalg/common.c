/**
 * @brief Compute homo SE for OLS
 *
 * @e N length array of error terms
 * @V kx by kx matrix with (X' X)^-1
 * @se Array where to store SE
 * @N Number of obs
 * @kx Number of columns in A
 * @return Store sqrt(diag(sum(@e^2 / (@N - @kx)) * @V)) in @se
 */
void gf_regress_ols_seunw (
    ST_double *e,
    ST_double *w,
    ST_double *V,
    ST_double *se,
    GT_size N,
    GT_size kx,
    GT_size kmodel)
{
    GT_size i;
    ST_double z, *eptr;

    z = 0;
    for (eptr = e; eptr < e + N; eptr++) {
        z += (*eptr) * (*eptr);
    }
    z /= ((ST_double) (N - kmodel));

    for (i = 0; i < kx; i++) {
        se[i] = sqrt(V[i * kx + i] * z);
    }
}

void gf_regress_ols_sew (
    ST_double *e,
    ST_double *w,
    ST_double *V,
    ST_double *se,
    GT_size N,
    GT_size kx,
    GT_size kmodel)
{
    GT_size i;
    ST_double *eptr;
    ST_double z = 0;
    ST_double *wptr = w;

    for (eptr = e; eptr < e + N; eptr++, wptr++) {
        z += (*eptr) * (*eptr) * (*wptr);
    }
    z /= ((ST_double) (N - kmodel));

    for (i = 0; i < kx; i++) {
        se[i] = sqrt(V[i * kx + i] * z);
    }
}

void gf_regress_ols_sefw (
    ST_double *e,
    ST_double *w,
    ST_double *V,
    ST_double *se,
    GT_size N,
    GT_size kx,
    GT_size kmodel)
{
    GT_size i;
    ST_double *eptr;
    ST_double z = 0;
    ST_double Ndbl = 0;
    ST_double *wptr = w;

    for (eptr = e; eptr < e + N; eptr++, wptr++) {
        z += (*eptr) * (*eptr) * (*wptr);
        Ndbl += *wptr;
    }
    z /= (Ndbl - kmodel);

    for (i = 0; i < kx; i++) {
        se[i] = sqrt(V[i * kx + i] * z);
    }
}

// NOTE: Use D from dsysv to see if inverse exists? abs(D) < machine eps => warn numerically 0?
// NOTE: Colinearity!!!

/**
 * @brief Replaces a symmetric matrix A with its inverse, A^-1; returns the determinant |A|
 * @source http://www.irma-international.org/viewtitle/41011/
 *
 * @A K x K symmetric matrix
 * @K Number of rows and columns in A
 * @return Store A^-1 in @A and return the determinant |A|
 */
ST_double gf_regress_linalg_dsysv (ST_double *A, GT_size K)
{
    ST_double z, D = 1;
    GT_size i, j, p;

    p = 0;
    z = A[p * K + p];
    D = (z != 0)? 1: 0;
    while ( p < K && z > 0 ) {
        z  = A[p * K + p];
        D *= z;
        for (i = 0; i < K; i++) {
            if ( i != p ) {
                A[i * K + p] /= -z;
                for (j = 0; j < K; j++) {
                    if ( j != p ) {
                        A[i * K + j] += A[i * K + p] * A[p * K + j];
                    }
                }
            }
        }
        for (j = 0; j < K; j++) {
            if ( j != p ) {
                A[p * K + j] /= z;
            }
        }
        A[p * K + p] = 1 / z;
        p++;
    }

    if ( fabs(D) < GTOOLS_64BIT_EPSILON ) {
        sf_errprintf("singularity warning: matrix determinant < %.8g\n", GTOOLS_64BIT_EPSILON);
    }

    return (D);
}

/**
 * @brief Find the collinear rows of a matrix via QR decomposition
 *
 * @A N x N symmetric matrix
 * @N Number of rows and columns in A
 * @QR Helper vector where to store R, H, etc.
 * @ix Indeces for non-collinear columns
 * @return
 */
void gf_regress_linalg_dsyqr (ST_double *A, GT_size N, ST_double *QR)
{
    GT_size i, j;
    ST_double *rptr, rmax;

    // We don't need Q if we only care about collinearity
    // ST_double *Q = QR;
    // ST_double *qptr = Q + N * N;
    ST_double *R = QR;
    ST_double *H = QR + 2 * N * N;

    // Initialize R = A and Q = I
    memcpy(R, A, N * N * sizeof(ST_double));
    // memset(Q, '\0', N * N * sizeof(ST_double));
    // for (i = 0; i < N; i++) {
    //     Q[i * N + i] = 1;
    // }

    // Rescale R by column so that numerical precision is not an
    // issue. Note that rescaling columns individually does not impact
    // collinearity.

    // for (i = 0; i < N; i++) {
    //     rptr = R + i * N;
    //     rmax = rptr[0];
    //     for (j = 1; j < N; j++) {
    //         if ( rmax < rptr[j] ) rmax = rptr[j];
    //     }
    //     for (j = 0; j < N; j++) {
    //         rptr[j] /= rmax;
    //     }
    // }

    // QR decomposition via Householder projections
    rptr = R + N * N;
    for (i = 0; i < N - 1; i++) {
        memset(H, '\0', N * N * sizeof(ST_double));
        for (j = 0; j < i; j++) {
            H[j * N + j] = 1;
        }

        memcpy(rptr, R + i * N + i, (N - i) * sizeof(ST_double));
        gf_regress_linalg_dsyhh (rptr, N - i, i, H + i * N + i);

        gf_regress_linalg_dgemm_colmajor (H, R, rptr, N, N, N);
        memcpy(R, rptr, N * N * sizeof(ST_double));
        // gf_regress_linalg_dsymm_colmajor (Q, H, qptr, N, N);
        // memcpy(Q, qptr, N * N * sizeof(ST_double));
    }

    // NOTE: How much should I worry about false positives?

    // NOTE: Compute rank first? You will have _some_ tolerance either
    // way... I worry this will miss sometimes

    for (i = 0; i < N; i++) {
        rptr = A + i * N;
        rmax = fabs(rptr[0]);
        for (j = 1; j < N; j++) {
            if ( rmax < fabs(rptr[j]) ) rmax = fabs(rptr[j]);
        }
        rmax *= N;
        if ( (fabs(R[i * N + i]) / rmax) < GTOOLS_64BIT_EPSILON ) {
            // printf("%ld: bad, %.9g\n", i, fabs(R[i * N + i]) / rmax);
        }
        else {
            // printf("%ld: ok, %.9g\n", i, fabs(R[i * N + i]) / rmax);
        }
    }
}

/**
 * @brief Find the Householder transformation of a vector a
 *
 * @a Vector of size N
 * @N length of vector
 * @H where to store Householder transformation
 * @return
 */
void gf_regress_linalg_dsyhh (ST_double *a, GT_size N, GT_size offset, ST_double *H)
{
    GT_size i, j;
    ST_double anorm, adot, *aptr, *hptr;


    if ( *a < 0 ) {
        anorm = -gf_regress_linalg_dnorm(a, N);
    }
    else {
        anorm = gf_regress_linalg_dnorm(a, N);
    }

    adot = 1;
    aptr = a + N;
    while ( --aptr > a ) {
        *aptr /= (*a + anorm);
        adot += (*aptr) * (*aptr);
    }
    *a = 1;

    adot = 2 / adot;
    for (i = 0; i < N; i++) {
        hptr  = H + i * (N + offset) + i;
        *hptr = 1 - adot * a[i] * a[i];
        hptr++;
        for (j = i + 1; j < N; j++, hptr++) {
            *hptr = -adot * a[i] * a[j];
        }
    }

    for (i = 0; i < N; i++) {
        for (j = i + 1; j < N; j++) {
            H[j * (N + offset) + i] = H[i * (N + offset) + j];
        }
    }
}

ST_double gf_regress_linalg_ddot (ST_double *a, GT_size N)
{
    ST_double *aptr;
    ST_double ddot = 0;
    for (aptr = a; aptr < a + N; aptr++) {
        ddot += (*aptr) * (*aptr);
    }
    return(ddot);
}

ST_double gf_regress_linalg_dnorm (ST_double *a, GT_size N)
{
    return (sqrt(gf_regress_linalg_ddot(a, N)));
}

/*********************************************************************
 *                          VCE Adjustments                          *
 *********************************************************************/

ST_double gf_regress_vceadj_ols_robust(
    GT_size N,
    GT_size kmodel,
    GT_size J,
    ST_double *w)
{
    ST_double Ndbl = N;
    return(Ndbl / (Ndbl - kmodel));
}

ST_double gf_regress_vceadj_ols_cluster(
    GT_size N,
    GT_size kmodel,
    GT_size J,
    ST_double *w)
{
    ST_double Ndbl = N;
    ST_double Jdbl = J;
    return(((Ndbl - 1) / (Ndbl - kmodel)) * (Jdbl / (Jdbl - 1)));
}

ST_double gf_regress_vceadj_mle_robust(
    GT_size N,
    GT_size kmodel,
    GT_size J,
    ST_double *w)
{
    ST_double Ndbl = N;
    return(Ndbl / (Ndbl - 1));
}

ST_double gf_regress_vceadj_mle_cluster(
    GT_size N,
    GT_size kmodel,
    GT_size J,
    ST_double *w)
{
    ST_double Jdbl = J;
    return(Jdbl / (Jdbl - 1));
}

ST_double gf_regress_vceadj_ols_robust_fw(
    GT_size N,
    GT_size kmodel,
    GT_size J,
    ST_double *w)
{
    GT_size i;
    ST_double Ndbl = 0;
    for (i = 0; i < N; i++) {
        Ndbl += w[i];
    }
    return(Ndbl / (Ndbl - kmodel));
}

ST_double gf_regress_vceadj_ols_cluster_fw(
    GT_size N,
    GT_size kmodel,
    GT_size J,
    ST_double *w)
{
    GT_size i;
    ST_double Ndbl = 0;
    ST_double Jdbl = J;
    for (i = 0; i < N; i++) {
        Ndbl += w[i];
    }
    return(((Ndbl - 1) / (Ndbl - kmodel)) * (Jdbl / (Jdbl - 1)));
}

ST_double gf_regress_vceadj_mle_robust_fw(
    GT_size N,
    GT_size kmodel,
    GT_size J,
    ST_double *w)
{
    GT_size i;
    ST_double Ndbl = 0;
    for (i = 0; i < N; i++) {
        Ndbl += w[i];
    }
    return(Ndbl / (Ndbl - 1));
}

ST_double gf_regress_vceadj_mle_cluster_fw(
    GT_size N,
    GT_size kmodel,
    GT_size J,
    ST_double *w)
{
    ST_double Jdbl = J;
    return(Jdbl / (Jdbl - 1));
}
