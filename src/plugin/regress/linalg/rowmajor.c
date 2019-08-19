/**
 * @brief Run basic OLS
 *
 * @X Independent variables; array of length N x kx
 * @y Dependent variable; array of length N
 * @XX Array of length kx x kx where to store X' X and (X' X)^-1
 * @Xy Array of length kx where to store X y
 * @b Array of length kx where to store the coefficients
 * @N Number of observations
 * @kx Number of X variables
 * @return Store OLS coefficients in @b
 */
void gf_regress_ols_rowmajor(
    ST_double *X,
    ST_double *y,
    ST_double *XX,
    ST_double *Xy,
    ST_double *e,
    ST_double *b,
    GT_size N,
    GT_size kx)
{
    gf_regress_linalg_dsymm_rowmajor  (X, X, XX, N, kx);
    gf_regress_linalg_dsysv           (XX, kx);
    gf_regress_linalg_dgemTv_rowmajor (X, y, Xy, N, kx);
    gf_regress_linalg_dgemTv_rowmajor (XX, Xy, b, kx, kx);
    gf_regress_linalg_error_rowmajor  (y, X, b, e, N, kx);
}

void gf_regress_ols_robust_rowmajor(
    ST_double *e,
    ST_double *V,
    ST_double *VV,
    ST_double *X,
    ST_double *XX,
    ST_double *se,
    GT_size N,
    GT_size kx,
    GT_size kmodel)
{
    GT_size i;
    ST_double qc;

    gf_regress_linalg_dsymm_w2rowmajor(X,  X,  V, e, N, kx);
    gf_regress_linalg_dgemm_rowmajor  (V,  XX, VV, kx, kx, kx);
    gf_regress_linalg_dgemm_rowmajor  (XX, VV, V,  kx, kx, kx);

    qc = ((ST_double) N) / ((ST_double) (N - kmodel));
    for (i = 0; i < kx; i++) {
        se[i] = sqrt(V[i * kx + i] * qc);
    }
}

void gf_regress_ols_cluster_rowmajor(
    ST_double *e,
    GT_size   *info,
    GT_size   *index,
    GT_size   J,
    ST_double *U,
    ST_double *V,
    ST_double *VV,
    ST_double *X,
    ST_double *XX,
    ST_double *se,
    GT_size N,
    GT_size kx,
    GT_size kmodel)
{
    GT_size i, j, nj, *ix;
    ST_double qc, *uptr;

    uptr = U;
    ix = index;
    for (j = 0; j < J; j++, uptr += kx) {
        nj = info[j + 1] - info[j];
        gf_regress_linalg_dgemTv_ixrowmajor (X, e, uptr, ix, nj, kx);
        ix += nj;
    }

    gf_regress_linalg_dsymm_rowmajor (U, U, V, J, kx);
    gf_regress_linalg_dgemm_rowmajor (V,  XX, VV, kx, kx, kx);
    gf_regress_linalg_dgemm_rowmajor (XX, VV, V,  kx, kx, kx);

    qc = (((ST_double) (N - 1)) / ((ST_double) (N - kmodel))) * ((ST_double) J / ((ST_double) (J - 1)));
    for (i = 0; i < kx; i++) {
        se[i] = sqrt(V[i * kx + i] * qc);
    }
}

/**
 * @brief Compute C = AB assuming that either both A and B are symmetric or that A = B
 *
 * @A N x K matrix (symmetric, or A = B)
 * @B N x K matrix (symmetric, or A = B)
 * @C K x K array where to store AB
 * @N Number of rows in A, B
 * @K Number of columns in A, B
 * @return Store AB in @C
 */
void gf_regress_linalg_dsymm_rowmajor(
    ST_double *A,
    ST_double *B,
    ST_double *C,
    GT_size N,
    GT_size K)
{
    GT_size i, j, l;
    ST_double *aptr, *bptr;

    for (i = 0; i < K; i++) {
        for (j = 0; j < K; j++) {
            C[i * K + j] = 0;
        }
    }

    bptr = B;
    for (i = 0; i < N; i++) {
        for (j = 0; j < K; j++, bptr++) {
            aptr = A + i * K + j;
            for (l = j; l < K; l++, aptr++) {
                C[j * K + l] += (*aptr) * (*bptr);
            }
        }
    }

    // Since C is symmetric, we only compute the upper triangle and then
    // copy it back into the lower triangle

    for (i = 0; i < K; i++) {
        for (j = i + 1; j < K; j++) {
            C[j * K + i] = C[i * K + j];
        }
    }
}

/**
 * @brief Compute c = A' b, where A is N by K and b is N by 1
 *
 * @A N x K matrix
 * @b N length array
 * @c K length array
 * @N Number of rows in A, B
 * @K Number of columns in A
 * @return Store A' b in @c
 */
void gf_regress_linalg_dgemTv_rowmajor(
    ST_double *A,
    ST_double *b,
    ST_double *c,
    GT_size N,
    GT_size K)
{
    GT_size i, k;
    ST_double *aptr, *bptr;

    for (k = 0; k < K; k++) {
        c[k] = 0;
    }

    aptr = A;
    bptr = b;
    for (i = 0; i < N; i++, bptr++) {
        for (k = 0; k < K; k++, aptr++) {
            c[k] += (*aptr) * (*bptr);
        }
    }
}

/**
 * @brief Compute c = Ab, where A is N by K and b is K by 1
 *
 * @A N x K matrix
 * @b N length array
 * @c K length array
 * @N Number of rows in A, B
 * @K Number of columns in A
 * @return Store Ab in @c
 */
void gf_regress_linalg_dgemv_rowmajor(
    ST_double *A,
    ST_double *b,
    ST_double *c,
    GT_size N,
    GT_size K)
{
    GT_size i, k;
    ST_double z, *aptr, *bptr;

    aptr = A;
    for (i = 0; i < N; i++) {
        z = 0;
        bptr = b;
        for (k = 0; k < K; k++, aptr++, bptr++) {
            z += (*aptr) * (*bptr);
        }
        c[i] = z;
    }
}

/**
 * @brief Compute c = y - Ab, where A is N by K, b is K by 1, and y is N by 1
 *
 * @y N length array
 * @A N x K matrix
 * @b N length array
 * @c K length array
 * @N Number of rows in A, B
 * @K Number of columns in A
 * @return Store Ab in @c
 */
void gf_regress_linalg_error_rowmajor(
    ST_double *y,
    ST_double *A,
    ST_double *b,
    ST_double *c,
    GT_size N,
    GT_size K)
{
    GT_size i, k;
    ST_double z, *aptr, *bptr;

    aptr = A;
    for (i = 0; i < N; i++) {
        z = 0;
        bptr = b;
        for (k = 0; k < K; k++, aptr++, bptr++) {
            z += (*aptr) * (*bptr);
        }
        c[i] = y[i] - z;
    }
}

/**
 * @brief Compute C = AB
 *
 * @A k1 x k2 matrix
 * @B k2 x k3 matrix
 * @C k1 x k3 array where to store AB
 * @k1 Number of rows in A
 * @k2 Number of columns in A, rows in B B
 * @k3 Number of columns in B
 * @return Store AB in @C
 */
void gf_regress_linalg_dgemm_rowmajor(
    ST_double *A,
    ST_double *B,
    ST_double *C,
    GT_size k1,
    GT_size k2,
    GT_size k3)
{
    GT_size i, j, l;
    ST_double z, *aptr, *bptr;

    for (i = 0; i < k3; i++) {
        for (j = 0; j < k1; j++) {
            aptr = A + j * k2;
            bptr = B + i;
            z = 0;
            for (l = 0; l < k2; l++, aptr++, bptr += k3) {
                z += (*aptr) * (*bptr);
            }
            C[j * k3 + i] = z;
        }
    }
}
