/**
 * @brief Replaces a symmetric matrix A with its inverse, A^-1; returns the determinant |A|
 * @source http://www.irma-international.org/viewtitle/41011/
 *
 * @A K x K symmetric matrix
 * @K Number of rows and columns in A
 * @return Store A^-1 in @A and return the determinant |A|
 */
ST_double gf_regress_linalg_dsysv (ST_double *A, GT_size K, GT_bool *nonsingular)
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
        *nonsingular = 0;
    }

    return (D);
}

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
 * @nonsingular
 * @return
 */
void gf_regress_linalg_dsyldu (
    ST_double *A,
    GT_size N,
    ST_double *LDU,
    GT_size *colix,
    GT_bool *nonsingular)
{

    ST_double det = 1;
    GT_size i, j, k;
clock_t timer = clock();

    ST_double *L    = LDU;
    ST_double *U    = LDU + 1 * N * N;
    ST_double *D    = LDU + 2 * N * N;
    ST_double *Linv = LDU + 3 * N * N;
    ST_double *Uinv = LDU + 4 * N * N;

    memset(L,    '\0', N * N * sizeof(ST_double));
    memset(U,    '\0', N * N * sizeof(ST_double));
    memset(D,    '\0',     N * sizeof(ST_double));
    memset(Linv, '\0', N * N * sizeof(ST_double));
    memset(Uinv, '\0', N * N * sizeof(ST_double));

    for (i = 0; i < N; i++) {
        U[i * N + i] = 1;
    }

    for (i = 0; i < N; i++) {
        D[i] = A[i * N + i];
        for (j = 0; j < i; j++) {
            D[i] -= U[j * N + i] * U[j * N + i] * D[j];
        }
        if ( fabs(D[i]) < GTOOLS_64BIT_EPSILON ) {
            D[i] = 0;
            continue;
        }
        for (j = i + 1; j < N; j++) {
            U[i * N + j] = A[i * N + j];
            for (k = 0; k < i; k++) {
                U[i * N + j] -= U[k * N + i] * U[k * N + j] * D[k];
            }
            U[i * N + j] /= D[i];
        }
    }

    for (j = 0; j < N; j++) {
        for (i = 0; i < j; i++) {
            U[j * N + i] = U[i * N + j];
            U[i * N + j] = 0;
        }
    }

    gf_regress_linalg_dgemTm_wcolmajor (U, U, Uinv, D, N, N, N);

// gf_regress_printf_colmajor (U, N, N, "U");
// gf_regress_printf_colmajor (D, N, 1, "D");
gf_regress_printf_colmajor (Uinv, N, N, "LDU");
// gf_regress_printf_colmajor (A, N, N, "A");

    colix[N] = 0;
    for (i = 0; i < N; i++) {
        det *= D[i];
        if ( fabs(D[i]) < GTOOLS_64BIT_EPSILON ) {
// sf_printf_debug("column %lu colinear\n", i);
            continue;
        }

        D[i] = 1 / D[i];
        colix[colix[N]++] = i;
    }

    if ( fabs(det) < GTOOLS_64BIT_EPSILON || colix[N] < N ) {
        *nonsingular = 0;
    }

sf_running_timer (&timer, "\t\tdebug 3.1: coll check");

    // gf_regress_linalg_dtrans_colmajor (L, L, N, N);
    gf_regress_linalg_dtrsvT_norm_colmajor (U, Linv, N);
    // gf_regress_linalg_dtrsv_norm_colmajor  (U, Uinv, N);

    gf_regress_linalg_dgemTm_wcolmajor (Linv, Linv, U, D, N, N, N);
    gf_regress_linalg_dgemm_colmajor   (A, U, L, N, N, N);

sf_running_timer (&timer, "\t\tdebug 3.2: inversion");

gf_regress_printf_colmajor (U, N, N, "A^-1");
gf_regress_printf_colmajor (A, N, N, "A");
gf_regress_printf_colmajor (L, N, N, "A A^-1");

}

/*********************************************************************
 *                          LU Via Cholesky                          *
 *********************************************************************/

/**
 * @brief Find the collinear rows of a matrix via Cholesky decomposition
 *
 * @A N x N symmetric matrix
 * @N Number of rows and columns in A
 * @LU Helper vector where to store L, U, etc.
 * @colix Indeces for non-collinear columns
 * @nonsingular
 * @return
 */
void gf_regress_linalg_dsylu (
    ST_double *A,
    GT_size N,
    ST_double *LU,
    GT_size *colix,
    GT_bool *nonsingular)
{

    GT_size i, j, k;

    ST_double *U    = LU;
    ST_double *Linv = LU + 1 * N * N;
    ST_double *Uinv = LU + 2 * N * N;

    memcpy(U,    A,    N * N * sizeof(ST_double));
    memset(Linv, '\0', N * N * sizeof(ST_double));
    memset(Uinv, '\0', N * N * sizeof(ST_double));

    for (j = 0; j < N; j++) {
        for (k = 0; k < j; k++) {
            for (i = j; i < N; i++) {
                U[j * N + i] -= U[k * N + i] * U[k * N + j];
            }
        }
        U[j * N + j] = sqrt(U[j * N + j]);
        if ( fabs(U[j * N + j]) < GTOOLS_64BIT_EPSILON ) {
            U[j * N + j] = 0;
            continue;
        }
        else {
            for (i = j + 1; i < N; i++) {
                U[j * N + i] /= U[j * N + j];
            }
        }
    }

    for (j = 0; j < N; j++) {
        for (i = 0; i < j; i++) {
            U[j * N + i] = U[i * N + j];
            U[i * N + j] = 0;
        }
    }

gf_regress_linalg_dgemTm_colmajor (U, U, Linv, N, N, N);
// gf_regress_printf_colmajor (U, N, N, "U");
// gf_regress_printf_colmajor (Linv, N, N, "U");

    // gf_regress_linalg_dtrans_colmajor (L, U, N, N);
    gf_regress_linalg_dtrsvT_colmajor (U, Linv, N);
    gf_regress_linalg_dtrsv_colmajor  (U, Uinv, N);
    gf_regress_linalg_dgemm_colmajor  (Uinv, Linv, U, N, N, N);

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
 * @nonsingular
 * @return
 */
void gf_regress_linalg_dsyqr (
    ST_double *A,
    GT_size N,
    ST_double *QR,
    GT_size *colix,
    GT_bool *nonsingular)
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

gf_regress_linalg_dgemm_colmajor (Q, R, rptr, N, N, N);
// gf_regress_printf_colmajor (A, N, N, "R");
// gf_regress_printf_colmajor (R, N, N, "R");
// gf_regress_printf_colmajor (rptr, N, N, "R");

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

    if ( fabs(det) < GTOOLS_64BIT_EPSILON || ncollinear ) {
        *nonsingular = 0;
    }

    // Replace A with the inverse of A'. Since A is symmetric this
    // should be the same; however, it is faster to compute the inverse
    // of A' = (QR)' = R' Q', which is Q (R')^-1 = Q (R^-1)'

    rptr = R + N * N;
    // qptr = Q + N * N;
    gf_regress_linalg_dtrsvT_colmajor (R, rptr, N);
    // gf_regress_linalg_dtrans_colmajor (Q, qptr, N, N);
    gf_regress_linalg_dgemm_colmajor (Q, rptr, R, N, N, N);
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

/**
 * @brief Computes the transpose of a matrix B = A'
 *
 * @A k1 x k2 matrix to be transposed
 * @B k2 x k1 transpose of A
 * @k1 Number of rows in A
 * @k2 Number of columns in A
 * @return Store A' in @B
 */
void gf_regress_linalg_dtrans_colmajor (ST_double *A, ST_double *B, GT_size k1, GT_size k2)
{
    GT_size i, j;
    for (j = 0; j < k2; j++) {
        for (i = 0; i < k1; i++) {
            B[j * k2 + i] = A[i * k2 + j];
        }
    }
}

/**
 * @brief Print matrix A
 *
 * @A k1 x k2 matrix to be printed
 * @k1 Number of rows in A
 * @k2 Number of columns in A
 * @return Prints entries of matrix A
 */
void gf_regress_printf_colmajor (
    ST_double *matrix,
    GT_size k1,
    GT_size k2,
    char *name)
{
    GT_size i, j;
    sf_printf_debug("%s\n", name);
    for (j = 0; j < k2; j++) {
        for (i = 0; i < k1; i++) {
            printf("%9.4f\t", matrix[j + k2 * i]);
        }
            printf("\n");
    }
            printf("\n");
}

/*********************************************************************
 *                        Triangular Inverses                        *
 *********************************************************************/

/**
 * @brief Computes the transpose of the inverse of an upper triangular
 * matrix B = (A^-1)'
 *
 * @A K x K upper triangular matrix
 * @B K x K inverse of A
 * @N Number of rows and columns in A
 * @return Store A^-1 in @B
 */
void gf_regress_linalg_dtrsvT_colmajor (ST_double *A, ST_double *B, GT_size N)
{
    // ST_double *aptr, *bptr;
    GT_int i, j, k;

    memset(B, '\0', N * N * sizeof(ST_double));
    for (j = 0; j < N; j++) {

        // Each jj diagonal entry is the inverse of the jj entry:
        //
        // B[j, j] = 1 / A[j, j]

        B[j * N + j] = 1 / A[j * N + j];

        for (i = j - 1; i >= 0; i--) {

            // Off diagonal entries are the minus the inverse of the ii
            // entry times the sum of the dot product:
            //
            //     dot = A[j, (1 + 1)::j] * B[j, (i + 1)::j]
            //     B[j, i] = - dot / A[i, i]
            //
            // When multiplying the A * B the B[i, j] entry gets
            // multiplied by A[i, i] and added to "dot".

            for (k = 0; k < j - i; k++) {
                // Note this is transposing B
                B[i * N + j] += A[(j - k) * N + i] * B[(j - k) * N + j];
            }

            // Note this is transposing B
            B[i * N + j] *= -B[i * N + i];
        }
    }
}

/**
 * @brief Computes the transpose of the inverse of an upper triangular
 * matrix B = (A^-1)'
 *
 * @A K x K upper triangular matrix
 * @B K x K inverse of A
 * @N Number of rows and columns in A
 * @return Store A^-1 in @B
 */
void gf_regress_linalg_dtrsv_colmajor (ST_double *A, ST_double *B, GT_size N)
{
    // ST_double *aptr, *bptr;
    GT_int i, j, k;

    memset(B, '\0', N * N * sizeof(ST_double));
    for (j = 0; j < N; j++) {

        // Each jj diagonal entry is the inverse of the jj entry:
        //
        // B[j, j] = 1 / A[j, j]

        B[j * N + j] = 1 / A[j * N + j];

        for (i = j - 1; i >= 0; i--) {

            // Off diagonal entries are the minus the inverse of the ii
            // entry times the sum of the dot product:
            //
            //     dot = A[j, (1 + 1)::j] * B[j, (i + 1)::j]
            //     B[j, i] = - dot / A[i, i]
            //
            // When multiplying the A * B the B[i, j] entry gets
            // multiplied by A[i, i] and added to "dot".

            for (k = 0; k < j - i; k++) {
                // Non-transposed version
                B[j * N + i] += A[(j - k) * N + i] * B[j * N + (j - k)];
            }

            // Non-transposed version
            B[j * N + i] *= -B[i * N + i];
        }
    }
}

void gf_regress_linalg_dtrsvT_norm_colmajor (ST_double *A, ST_double *B, GT_size N)
{
    ST_double z;
    GT_int i, j, k;
    memset(B, '\0', N * N * sizeof(ST_double));
    for (j = 0; j < N; j++) {
        B[j * N + j] = 1;
        for (i = j - 1; i >= 0; i--) {
            z = 0;
            for (k = 0; k < j - i; k++) {
                z += A[(j - k) * N + i] * B[(j - k) * N + j];
            }
            B[i * N + j] = -z;
        }
    }
}

void gf_regress_linalg_dtrsv_norm_colmajor (ST_double *A, ST_double *B, GT_size N)
{
    ST_double z;
    GT_int i, j, k;
    memset(B, '\0', N * N * sizeof(ST_double));
    for (j = 0; j < N; j++) {
        B[j * N + j] = 1;
        for (i = j - 1; i >= 0; i--) {
            z = 0;
            for (k = 0; k < j - i; k++) {
                z += A[(j - k) * N + i] * B[j * N + (j - k)];
            }
            B[j * N + i] = -z;
        }
    }
}
