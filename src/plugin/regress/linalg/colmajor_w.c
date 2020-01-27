void gf_regress_linalg_dsymm_wcolmajor(
    ST_double *A,
    ST_double *B,
    ST_double *C,
    ST_double *w,
    GT_size N,
    GT_size K)
{
    GT_size i, j, l;
    ST_double *aptr, *bptr, *cptr, *wptr;

    for (i = 0; i < K; i++) {
        bptr = B;
        for (j = 0; j <= i; j++) {
            aptr = A + i * N;
            cptr = C + i * K + j;
            wptr = w;
            *cptr = 0;
            for (l = 0; l < N; l++, aptr++, bptr++, wptr++) {
                *cptr += (*aptr) * (*bptr) * (*wptr);
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

void gf_regress_linalg_dsymm_w2colmajor(
    ST_double *A,
    ST_double *B,
    ST_double *C,
    ST_double *w,
    GT_size N,
    GT_size K)
{
    GT_size i, j, l;
    ST_double *aptr, *bptr, *cptr, *wptr;

    for (i = 0; i < K; i++) {
        bptr = B;
        for (j = 0; j <= i; j++) {
            aptr = A + i * N;
            cptr = C + i * K + j;
            wptr = w;
            *cptr = 0;
            for (l = 0; l < N; l++, aptr++, bptr++, wptr++) {
                *cptr += (*aptr) * (*bptr) * (*wptr) * (*wptr);
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

void gf_regress_linalg_dsymm_we2colmajor(
    ST_double *A,
    ST_double *B,
    ST_double *C,
    ST_double *e,
    ST_double *w,
    GT_size N,
    GT_size K)
{
    GT_size i, j, l;
    ST_double *aptr, *bptr, *cptr, *eptr, *wptr;

    for (i = 0; i < K; i++) {
        bptr = B;
        for (j = 0; j <= i; j++) {
            aptr = A + i * N;
            cptr = C + i * K + j;
            wptr = w;
            eptr = e;
            *cptr = 0;
            for (l = 0; l < N; l++, aptr++, bptr++, eptr++, wptr++) {
                *cptr += (*aptr) * (*bptr) * (*eptr) * (*eptr) * (*wptr) * (*wptr);
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

void gf_regress_linalg_dsymm_fwe2colmajor(
    ST_double *A,
    ST_double *B,
    ST_double *C,
    ST_double *e,
    ST_double *w,
    GT_size N,
    GT_size K)
{
    GT_size i, j, l;
    ST_double *aptr, *bptr, *cptr, *eptr, *wptr;

    for (i = 0; i < K; i++) {
        bptr = B;
        for (j = 0; j <= i; j++) {
            aptr = A + i * N;
            cptr = C + i * K + j;
            wptr = w;
            eptr = e;
            *cptr = 0;
            for (l = 0; l < N; l++, aptr++, bptr++, eptr++, wptr++) {
                *cptr += (*aptr) * (*bptr) * (*eptr) * (*eptr) * (*wptr);
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

void gf_regress_linalg_dgemTv_wcolmajor(
    ST_double *A,
    ST_double *b,
    ST_double *c,
    ST_double *w,
    GT_size N,
    GT_size K)
{
    GT_size i, k;
    ST_double *aptr, *bptr, *cptr, *wptr;

    aptr = A;
    cptr = c;
    for (k = 0; k < K; k++, cptr++) {
        bptr  = b;
        *cptr = 0;
        wptr  = w;
        for (i = 0; i < N; i++, aptr++, bptr++, wptr++) {
            *cptr += (*aptr) * (*bptr) * (*wptr);
        }
    }
}

void gf_regress_linalg_error_wcolmajor(
    ST_double *y,
    ST_double *A,
    ST_double *b,
    ST_double *w,
    ST_double *c,
    GT_size N,
    GT_size K)
{
    GT_size i, k;
    ST_double *aptr, *bptr, *cptr, *wptr;
    memcpy(c, y, N * sizeof(ST_double));

    bptr = b;
    aptr = A;
    for (k = 0; k < K; k++, bptr++) {
        cptr = c;
        for (i = 0; i < N; i++, aptr++, cptr++) {
            *cptr -= (*aptr) * (*bptr);
        }
    }

    cptr = c;
    wptr = w;
    for (i = 0; i < N; i++, cptr++, wptr++) {
        *cptr *= *wptr;
    }
}

void gf_regress_linalg_dgemm_wcolmajor(
    ST_double *A,
    ST_double *B,
    ST_double *C,
    ST_double *w,
    GT_size k1,
    GT_size k2,
    GT_size k3)
{
    GT_size i, j, l;
    ST_double *aptr, *bptr, *cptr, *wptr;
    memset(C, '\0', k1 * k3 * sizeof(ST_double));
    bptr = B;
    for (i = 0; i < k3; i++) {
        aptr = A;
        for (j = 0; j < k2; j++, bptr++) {
            cptr = C + i * k1;
            wptr = w + j;
            for (l = 0; l < k1; l++, aptr++, cptr++) {
                *cptr += (*aptr) * (*bptr) * (*wptr);
            }
        }
    }
}

void gf_regress_linalg_dgemTm_wcolmajor(
    ST_double *A,
    ST_double *B,
    ST_double *C,
    ST_double *w,
    GT_size N,
    GT_size k1,
    GT_size k2)
{
    GT_size i, k, l;
    ST_double *aptr, *bptr, *cptr, *wptr;
    memset(C, '\0', k1 * k2 * sizeof(ST_double));
    cptr = C;
    for (l = 0; l < k2; l++) {
        aptr = A;
        for (k = 0; k < k1; k++, cptr++) {
            bptr  = B + l * N;
            wptr  = w;
            for (i = 0; i < N; i++, aptr++, bptr++, wptr++) {
                *cptr += (*aptr) * (*bptr) * (*wptr);
            }
        }
    }
}
