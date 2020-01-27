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

void gf_regress_linalg_dsymm_ixrowmajor(
    ST_double *A,
    ST_double *B,
    ST_double *C,
    GT_size *ix,
    GT_size N,
    GT_size K)
{
    GT_size i, j, l, m;
    ST_double *aptr, *bptr;

    for (i = 0; i < K; i++) {
        for (j = 0; j < K; j++) {
            C[i * K + j] = 0;
        }
    }

    for (i = 0; i < N; i++) {
        m = ix[i];
        bptr = B + m * K;
        for (j = 0; j < K; j++, bptr++) {
            aptr = A + m * K + j;
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

void gf_regress_linalg_dsymm_wrowmajor(
    ST_double *A,
    ST_double *B,
    ST_double *C,
    ST_double *w,
    GT_size N,
    GT_size K)
{
    GT_size i, j, l;
    ST_double *aptr, *bptr, *wptr;

    for (i = 0; i < K; i++) {
        for (j = 0; j < K; j++) {
            C[i * K + j] = 0;
        }
    }

    bptr = B;
    wptr = w;
    for (i = 0; i < N; i++, wptr++) {
        for (j = 0; j < K; j++, bptr++) {
            aptr = A + i * K + j;
            for (l = j; l < K; l++, aptr++) {
                C[j * K + l] += (*aptr) * (*bptr) * (*wptr);
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
