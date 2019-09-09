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
void gf_regress_ols_colmajor(
    ST_double *X,
    ST_double *y,
    ST_double *w,
    ST_double *XX,
    ST_double *Xy,
    ST_double *e,
    ST_double *b,
    GT_size N,
    GT_size kx)
{
    gf_regress_linalg_dsymm_colmajor  (X, X, XX, N, kx);
    // gf_regress_linalg_dsyqr           (XX, kx, XX + kx * kx);
    gf_regress_linalg_dsysv           (XX, kx);
    gf_regress_linalg_dgemTv_colmajor (X, y, Xy, N, kx);
    gf_regress_linalg_dgemTv_colmajor (XX, Xy, b, kx, kx);
    gf_regress_linalg_error_colmajor  (y, X, b, e, N, kx);
}

void gf_regress_ols_robust_colmajor(
    ST_double *e,
    ST_double *w,
    ST_double *V,
    ST_double *VV,
    ST_double *X,
    ST_double *XX,
    ST_double *se,
    GT_size N,
    GT_size kx,
    GT_size kmodel,
    gf_regress_vceadj vceadj)
{
    GT_size i;
    ST_double qc;

    gf_regress_linalg_dsymm_w2colmajor(X,  X,  V, e, N, kx);
    gf_regress_linalg_dgemm_colmajor  (V,  XX, VV, kx, kx, kx);
    gf_regress_linalg_dgemm_colmajor  (XX, VV, V,  kx, kx, kx);

    qc = vceadj(N, kmodel, 0, w);
    for (i = 0; i < kx; i++) {
        se[i] = sqrt(V[i * kx + i] * qc);
    }
}

void gf_regress_ols_cluster_colmajor(
    ST_double *e,
    ST_double *w,
    GT_size   *info,
    GT_size   *index,
    GT_size   J,
    ST_double *U,
    GT_size   *ux,
    ST_double *V,
    ST_double *VV,
    ST_double *X,
    ST_double *XX,
    ST_double *se,
    GT_size N,
    GT_size kx,
    GT_size kmodel,
    gf_regress_vceadj vceadj)
{
    GT_size i, j, k, start, end;
    ST_double qc, *aptr, *bptr;

    memset(U, '\0', J * kx * sizeof(ST_double));
    for (j = 0; j < J; j++) {
        start = info[j];
        end   = info[j + 1];
        for (i = start; i < end; i++) {
            ux[index[i]] = j;
        }
    }

    aptr = X;
    for (k = 0; k < kx; k++) {
        bptr = e;
        for (i = 0; i < N; i++, aptr++, bptr++) {
            U[ux[i] * kx + k] += (*aptr) * (*bptr);
        }
    }

    gf_regress_linalg_dsymm_rowmajor (U, U, V, J, kx);
    gf_regress_linalg_dgemm_colmajor (V,  XX, VV, kx, kx, kx);
    gf_regress_linalg_dgemm_colmajor (XX, VV, V,  kx, kx, kx);

    qc = vceadj(N, kmodel, J, w);
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
void gf_regress_linalg_dsymm_colmajor(
    ST_double *A,
    ST_double *B,
    ST_double *C,
    GT_size N,
    GT_size K)
{
    GT_size i, j, l;
    ST_double *aptr, *bptr, *cptr;

    for (i = 0; i < K; i++) {
        bptr = B;
        for (j = 0; j <= i; j++) {
            aptr = A + i * N;
            cptr = C + i * K + j;
            *cptr = 0;
            for (l = 0; l < N; l++, aptr++, bptr++) {
                *cptr += (*aptr) * (*bptr);
            }
        }
    }

    // Since C is symmetric, we only compute the lower triangle and then
    // copy it back into the opper triangle

    for (i = 0; i < K; i++) {
        for (j = i + 1; j < K; j++) {
            C[i * K + j] = C[j * K + i];
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
void gf_regress_linalg_dgemTv_colmajor(
    ST_double *A,
    ST_double *b,
    ST_double *c,
    GT_size N,
    GT_size K)
{
    GT_size i, k;
    ST_double *aptr, *bptr, *cptr;

    aptr = A;
    cptr = c;
    for (k = 0; k < K; k++, cptr++) {
        bptr  = b;
        *cptr = 0;
        for (i = 0; i < N; i++, aptr++, bptr++) {
            *cptr += (*aptr) * (*bptr);
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
void gf_regress_linalg_dgemv_colmajor(
    ST_double *A,
    ST_double *b,
    ST_double *c,
    GT_size N,
    GT_size K)
{
    GT_size i, k;
    ST_double *aptr, *bptr;

    for (i = 0; i < N; i++) {
        c[i] = 0;
    }

    bptr = b;
    aptr = A;
    for (k = 0; k < K; k++, bptr++) {
        for (i = 0; i < N; i++, aptr++) {
            c[i] += (*aptr) * (*bptr);
        }
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
void gf_regress_linalg_error_colmajor(
    ST_double *y,
    ST_double *A,
    ST_double *b,
    ST_double *c,
    GT_size N,
    GT_size K)
{
    GT_size i, k;
    ST_double *aptr, *bptr, *cptr;
    memcpy(c, y, N * sizeof(ST_double));

    bptr = b;
    aptr = A;
    for (k = 0; k < K; k++, bptr++) {
        cptr = c;
        for (i = 0; i < N; i++, aptr++, cptr++) {
            *cptr -= (*aptr) * (*bptr);
        }
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
void gf_regress_linalg_dgemm_colmajor(
    ST_double *A,
    ST_double *B,
    ST_double *C,
    GT_size k1,
    GT_size k2,
    GT_size k3)
{
    GT_size i, j, l;
    ST_double *aptr, *bptr, *cptr;
    memset(C, '\0', k1 * k3 * sizeof(ST_double));
    bptr = B;
    for (i = 0; i < k3; i++) {
        aptr = A;
        for (j = 0; j < k2; j++, bptr++) {
            cptr = C + i * k1;
            for (l = 0; l < k1; l++, aptr++, cptr++) {
                *cptr += (*aptr) * (*bptr);
            }
        }
    }
}

/**
 * @brief Compute C = A' B, where A is N by k1 and B is N by k2
 *
 * @A N x k1 matrix
 * @B N x k2 matrix
 * @C k1 x k2 matrix
 * @N Number of rows in A, B
 * @k1 Number of columns in A
 * @k2 Number of columns in B
 * @return Store A' B in @C
 */
void gf_regress_linalg_dgemTm_colmajor(
    ST_double *A,
    ST_double *B,
    ST_double *C,
    GT_size N,
    GT_size k1,
    GT_size k2)
{
    GT_size i, k, l;
    ST_double *aptr, *bptr, *cptr;
    memset(C, '\0', k1 * k2 * sizeof(ST_double));
    cptr = C;
    for (l = 0; l < k2; l++) {
        aptr = A;
        for (k = 0; k < k1; k++, cptr++) {
            bptr = B + l * N;
            for (i = 0; i < N; i++, aptr++, bptr++) {
                *cptr += (*aptr) * (*bptr);
            }
        }
    }
}
