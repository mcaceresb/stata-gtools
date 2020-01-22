/*********************************************************************
 *                                LDU                                *
 *********************************************************************/

/**
 * @brief Find the collinear rows of a matrix via LDU decomposition
 *
 * @A N x N symmetric matrix
 * @N Number of rows and columns in A
 * @QR Helper vector where to store L, D, L', etc.
 * @colix Indeces for non-collinear columns
 * @return
 */
void gf_regress_linalg_dcollinear (
    ST_double *A,
    GT_size N,
    ST_double *LDU,
    GT_size *colix)
{

    GT_size i, j, k;

    ST_double *U1 = LDU;             // L
    ST_double *D  = LDU + 1 * N * N; // D

    memset(U1, '\0', N * N * sizeof(ST_double));
    memset(D,  '\0',     N * sizeof(ST_double));

    colix[N] = 0;
    for (i = 0; i < N; i++) {
        U1[i * N + i] = 1;
    }

    for (i = 0; i < N; i++) {
        D[i] = A[i * N + i];
        for (j = 0; j < i; j++) {
            D[i] -= U1[j * N + i] * U1[j * N + i] * D[j];
        }

        // TODO: This check potentially fails due to the multi-way fixed
        // effects algoritm not being precise enough ): It is possible
        // to get a matrix with zeros that show up as 1e-15 and such
        // numbers, which _should_ just be zero but are not quite small
        // enough to be _numerically_ zero.

        if ( fabs(D[i]) < N * GTOOLS_64BIT_EPSILON ) {
            D[i] = 0;
            continue;
        }

        colix[colix[N]++] = i;
        for (j = i + 1; j < N; j++) {
            U1[i * N + j] = A[i * N + j];
            for (k = 0; k < i; k++) {
                U1[i * N + j] -= U1[k * N + i] * U1[k * N + j] * D[k];
            }
            U1[i * N + j] /= D[i];
        }
    }
}

/**
 * @brief Find the collinear rows of a matrix via LDU decomposition
 *
 * @A N x N symmetric matrix
 * @N Number of rows and columns in A
 * @QR Helper vector where to store L, D, L', etc.
 * @colix Indeces for non-collinear columns
 * @singular
 * @return
 */
void gf_regress_linalg_dsyldu (
    ST_double *A,
    GT_size N,
    ST_double *LDU,
    GT_size *colix,
    GT_bool *singular)
{

    ST_double det;
    GT_size i, j, k;
    GT_size kindep;

    ST_double *U1 = LDU;             // L -> Linv
    ST_double *U2 = LDU + 1 * N * N; // U
    ST_double *D  = LDU + 2 * N * N; // D

    memset(U1, '\0', N * N * sizeof(ST_double));
    memset(U2, '\0', N * N * sizeof(ST_double));
    memset(D,  '\0',     N * sizeof(ST_double));

    colix[N] = 0;
    for (i = 0; i < N; i++) {
        U1[i * N + i] = 1;
    }

    for (i = 0; i < N; i++) {
        D[i] = A[i * N + i];
        for (j = 0; j < i; j++) {
            D[i] -= U1[j * N + i] * U1[j * N + i] * D[j];
        }

        // TODO: This check potentially fails due to the multi-way fixed
        // effects algoritm not being precise enough ): It is possible
        // to get a matrix with zeros that show up as 1e-15 and such
        // numbers, which _should_ just be zero but are not quite small
        // enough to be _numerically_ zero.

        if ( fabs(D[i]) < N * GTOOLS_64BIT_EPSILON ) {
            D[i] = 0;
            continue;
        }

        colix[colix[N]++] = i;
        for (j = i + 1; j < N; j++) {
            U1[i * N + j] = A[i * N + j];
            for (k = 0; k < i; k++) {
                U1[i * N + j] -= U1[k * N + i] * U1[k * N + j] * D[k];
            }
            U1[i * N + j] /= D[i];
        }
    }

    kindep = colix[N];
    if ( kindep < N ) {
        det = 0;
        for (i = 0; i < kindep; i++) {
            D[i] = 1 / D[colix[i]];
        }

        for (j = 0; j < kindep; j++) {
            U2[j * kindep + j] = 1;
            for (i = 0; i < j; i++) {
                U2[j * kindep + i] = U1[colix[i] * N + colix[j]];
            }
        }

        gf_regress_linalg_dtrsvT_norm_colmajor (U2, U1, kindep);
        gf_regress_linalg_dgemTm_wcolmajor (U1, U1, A, D, kindep, kindep, kindep);
    }
    else {
        det = 1;
        for (i = 0; i < N; i++) {
            det *= D[i];
            D[i] = 1 / D[i];
        }

        for (j = 0; j < N; j++) {
            U2[j * kindep + j] = 1;
            for (i = 0; i < j; i++) {
                U2[j * N + i] = U1[i * N + j];
            }
        }

        gf_regress_linalg_dtrsvT_norm_colmajor (U2, U1, N);
        gf_regress_linalg_dgemTm_wcolmajor (U1, U1, A, D, N, N, N);
    }

    if ( colix[N] < N ) {
        *singular = 1;
    }
    else if ( fabs(det) < GTOOLS_64BIT_EPSILON ) {
        *singular = 2;
    }
    else {
        *singular = 0;
    }
}

/*********************************************************************
 *                          LU Via Cholesky                          *
 *********************************************************************/

/**
 * @brief Find the collinear rows of a matrix via Cholesky decomposition
 *
 * @A N x N full-rank symmetric matrix
 * @N Number of rows and columns in A
 * @LU Helper vector where to store L, U, etc.
 * @colix Indeces for non-collinear columns
 * @singular
 * @return
 */
void gf_regress_linalg_dsylu (
    ST_double *A,
    GT_size N,
    ST_double *LU,
    GT_bool *singular)
{

    ST_double det = 1;
    GT_size i, j, k;

    ST_double *U    = LU;
    ST_double *Linv = LU + 1 * N * N;

    memcpy(U,    A,    N * N * sizeof(ST_double));
    memset(Linv, '\0', N * N * sizeof(ST_double));

    for (j = 0; j < N; j++) {
        for (k = 0; k < j; k++) {
            for (i = j; i < N; i++) {
                U[j * N + i] -= U[k * N + i] * U[k * N + j];
            }
        }
        U[j * N + j] = sqrt(U[j * N + j]);
        for (i = j + 1; i < N; i++) {
            U[j * N + i] /= U[j * N + j];
        }
    }

    for (j = 0; j < N; j++) {
        det *= U[j * N + j];
        for (i = 0; i < j; i++) {
            U[j * N + i] = U[i * N + j];
            U[i * N + j] = 0;
        }
    }

    if ( fabs(det) < GTOOLS_64BIT_EPSILON ) {
        *singular = 2;
    }

    gf_regress_linalg_dtrsvT_colmajor (U, Linv, N);
    gf_regress_linalg_dgemTm_colmajor (Linv, Linv, A, N, N, N);
}

/*********************************************************************
 *                        QR Via HouseHolder                         *
 *********************************************************************/

/**
 * @brief Find the collinear rows of a matrix via QR decomposition
 *
 * @A N x N symmetric matrix
 * @N Number of rows and columns in A
 * @QR Helper vector where to store R, H, etc.
 * @colix Indeces for non-collinear columns
 * @singular
 * @return
 */
void gf_regress_linalg_dsyqr (
    ST_double *A,
    GT_size N,
    ST_double *QR,
    GT_size *colix,
    GT_bool *singular)
{

    ST_double det = 1;
    GT_size i, j, ncollinear;
    ST_double *qptr, *rptr, rmax;

    // Q is orthonormal and R is triangular, so I _should_ compute the
    // inverse here

    ST_double *Q = QR;
    ST_double *R = QR + 2 * N * N;
    ST_double *H = QR + 4 * N * N;

    // Initialize R = A and Q = I
    memcpy(R, A, N * N * sizeof(ST_double));
    memset(Q, '\0', N * N * sizeof(ST_double));
    for (i = 0; i < N; i++) {
        Q[i * N + i] = 1;
    }

    // QR decomposition via Householder projections
    qptr = Q + N * N;
    rptr = R + N * N;
    for (i = 0; i < N - 1; i++) {

        // H = I
        memset(H, '\0', N * N * sizeof(ST_double));
        for (j = 0; j < i; j++) {
            H[j * N + j] = 1;
        }

        // H[i::N, i::N] <- Householder using R[i::N, i]
        memcpy(rptr, R + i * N + i, (N - i) * sizeof(ST_double));
        gf_regress_linalg_dsyhh (rptr, N - i, i, H + i * N + i);

        // Q <- Q * H
        gf_regress_linalg_dgemm_colmajor (Q, H, qptr, N, N, N);
        memcpy(Q, qptr, N * N * sizeof(ST_double));

        // R <- H * R
        gf_regress_linalg_dgemm_colmajor (H, R, rptr, N, N, N);
        memcpy(R, rptr, N * N * sizeof(ST_double));
    }

    // NOTE: How much should I worry about false positives? False
    // negatives?  Should I try to compute the rank first? I mean, I
    // will have to have _some_ tolerance either way _somewhere_...

    ncollinear = colix[N] = 0;
    for (i = 0; i < N; i++) {

        // For each column a_i, we use tolerance = max(|a_i|) * N * eps,
        // where eps is the 64-bit machine epsilon, 2^-52 = 2.22e-16

        rptr = A + i * N;
        rmax = fabs(rptr[0]);
        for (j = 1; j < N; j++) {
            if ( rmax < fabs(rptr[j]) ) rmax = fabs(rptr[j]);
        }
        rmax *= N;

        // If the i, i entry of R is numerically 0, then that column is
        // linearly dependent

        if ( (fabs(R[i * N + i]) / rmax) < GTOOLS_64BIT_EPSILON ) {
            ncollinear++;
        }
        else {

            // colix has in the ith entry the kth independent column, and in
            // the Nth entry the number of independent columns overall.

            det *= R[i * N + i];
            colix[colix[N]++] = i;
        }
    }

    if ( ncollinear == 0 ) {
        memset(colix, '\0', (N + 1) * (sizeof *colix));
    }

    if ( fabs(det) < GTOOLS_64BIT_EPSILON ) {
        *singular = 2;
    }

    if ( ncollinear ) {
        *singular = 1;
    }

    // Replace A with the inverse of A'. Since A is symmetric this
    // should be the same; however, it is faster to compute the inverse
    // of A' = (QR)' = R' Q', which is Q (R')^-1 = Q (R^-1)'

    rptr = R + N * N;
    // qptr = Q + N * N;
    gf_regress_linalg_dtrsvT_colmajor (R, rptr, N);
    // gf_regress_linalg_dtrans_colmajor (Q, qptr, N, N);
    gf_regress_linalg_dgemm_colmajor (Q, rptr, A, N, N, N);
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
