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
