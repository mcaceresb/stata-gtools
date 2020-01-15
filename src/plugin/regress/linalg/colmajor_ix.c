void gf_regress_linalg_dgemTv_colmajor_ix1 (
    ST_double *A,
    ST_double *b,
    ST_double *c,
    GT_size *colix,
    GT_size N,
    GT_size K)
{
    GT_size i, k;
    ST_double *aptr, *bptr, *cptr;
    memset(c, '\0', K * (sizeof *c));

    cptr = c;
    for (k = 0; k < colix[K]; k++, cptr++) {
        aptr  = A + N * colix[k];
        bptr  = b;
        for (i = 0; i < N; i++, aptr++, bptr++) {
            *cptr += (*aptr) * (*bptr);
        }
    }
}

void gf_regress_linalg_dgemTv_wcolmajor_ix1 (
    ST_double *A,
    ST_double *b,
    ST_double *c,
    ST_double *w,
    GT_size *colix,
    GT_size N,
    GT_size K)
{
    GT_size i, k;
    ST_double *aptr, *bptr, *cptr, *wptr;
    memset(c, '\0', K * (sizeof *c));

    cptr = c;
    for (k = 0; k < colix[K]; k++, cptr++) {
        aptr = A + N * colix[k];
        bptr = b;
        wptr = w;
        for (i = 0; i < N; i++, aptr++, bptr++, wptr++) {
            *cptr += (*aptr) * (*bptr) * (*wptr);
        }
    }
}

void gf_regress_linalg_dgemTv_colmajor_ix2 (
    ST_double *A,
    ST_double *b,
    ST_double *c,
    GT_size *colix,
    GT_size N,
    GT_size K)
{
    GT_size i, k;
    ST_double *aptr, *bptr, *cptr;
    memset(c, '\0', K * (sizeof *c));

    aptr = A;
    for (k = 0; k < colix[K]; k++) {
        bptr = b;
        cptr = c + colix[k];
        for (i = 0; i < N; i++, aptr++, bptr++) {
            *cptr += (*aptr) * (*bptr);
        }
    }
}

void gf_regress_linalg_dgemTv_wcolmajor_ix2 (
    ST_double *A,
    ST_double *b,
    ST_double *c,
    ST_double *w,
    GT_size *colix,
    GT_size N,
    GT_size K)
{
    GT_size i, k;
    ST_double *aptr, *bptr, *cptr, *wptr;
    memset(c, '\0', K * (sizeof *c));

    aptr = A;
    for (k = 0; k < colix[K]; k++) {
        bptr = b;
        cptr = c + colix[k];
        wptr = w;
        for (i = 0; i < N; i++, aptr++, bptr++, wptr++) {
            *cptr += (*aptr) * (*bptr) * (*wptr);
        }
    }
}

void gf_regress_linalg_error_colmajor_ix (
    ST_double *y,
    ST_double *A,
    ST_double *b,
    ST_double *c,
    GT_size *colix,
    GT_size N,
    GT_size K)
{
    GT_size i, k;
    ST_double *aptr, *bptr, *cptr;
    memcpy(c, y, N * sizeof(ST_double));

    for (k = 0; k < colix[K]; k++) {
        aptr = A + N * colix[k];
        bptr = b + colix[k];
        cptr = c;
        for (i = 0; i < N; i++, aptr++, cptr++) {
            *cptr -= (*aptr) * (*bptr);
        }
    }
}

void gf_regress_linalg_error_wcolmajor_ix (
    ST_double *y,
    ST_double *A,
    ST_double *b,
    ST_double *w,
    ST_double *c,
    GT_size *colix,
    GT_size N,
    GT_size K)
{
    GT_size i, k;
    ST_double *aptr, *bptr, *cptr, *wptr;
    memcpy(c, y, N * sizeof(ST_double));

    for (k = 0; k < colix[K]; k++) {
        aptr = A + N * colix[k];
        bptr = b + colix[k];
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

void gf_regress_linalg_dsymm_w2colmajor_ix (
    ST_double *A,
    ST_double *B,
    ST_double *C,
    ST_double *w,
    GT_size *colix,
    GT_size N,
    GT_size K)
{
    GT_size i, j, l;
    ST_double *aptr, *bptr, *cptr, *wptr;
    GT_size kindep = colix[K];

    for (i = 0; i < kindep; i++) {
        for (j = 0; j <= i; j++) {
            aptr = A + colix[i] * N;
            bptr = B + colix[j] * N;
            cptr = C + i * kindep + j;
            wptr = w;
            *cptr = 0;
            for (l = 0; l < N; l++, aptr++, bptr++, wptr++) {
                *cptr += (*aptr) * (*bptr) * (*wptr) * (*wptr);
            }
        }
    }

    // Since C is symmetric, we only compute the lower triangle and then
    // copy it back into the opper triangle

    for (i = 0; i < kindep; i++) {
        for (j = i + 1; j < kindep; j++) {
            C[i * kindep + j] = C[j * kindep + i];
        }
    }
}

void gf_regress_linalg_dsymm_we2colmajor_ix (
    ST_double *A,
    ST_double *B,
    ST_double *C,
    ST_double *e,
    ST_double *w,
    GT_size *colix,
    GT_size N,
    GT_size K)
{
    GT_size i, j, l;
    ST_double *aptr, *bptr, *cptr, *eptr, *wptr;
    GT_size kindep = colix[K];

    for (i = 0; i < kindep; i++) {
        for (j = 0; j <= i; j++) {
            aptr = A + colix[i] * N;
            bptr = B + colix[j] * N;
            cptr = C + i * kindep + j;
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

    for (i = 0; i < kindep; i++) {
        for (j = i + 1; j < kindep; j++) {
            C[i * kindep + j] = C[j * kindep + i];
        }
    }
}

void gf_regress_linalg_dsymm_fwe2colmajor_ix (
    ST_double *A,
    ST_double *B,
    ST_double *C,
    ST_double *e,
    ST_double *w,
    GT_size *colix,
    GT_size N,
    GT_size K)
{
    GT_size i, j, l;
    ST_double *aptr, *bptr, *cptr, *eptr, *wptr;
    GT_size kindep = colix[K];

    for (i = 0; i < kindep; i++) {
        for (j = 0; j <= i; j++) {
            aptr = A + colix[i] * N;
            bptr = B + colix[j] * N;
            cptr = C + i * kindep + j;
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

    for (i = 0; i < kindep; i++) {
        for (j = i + 1; j < kindep; j++) {
            C[i * kindep + j] = C[j * kindep + i];
        }
    }
}

// void gf_regress_linalg_dsymm_wcolmajor(
//     ST_double *A,
//     ST_double *B,
//     ST_double *C,
//     ST_double *w,
//     GT_size N,
//     GT_size K)
// {
//     GT_size i, j, l;
//     ST_double *aptr, *bptr, *cptr, *wptr;
// 
//     for (i = 0; i < K; i++) {
//         bptr = B;
//         for (j = 0; j <= i; j++) {
//             aptr = A + i * N;
//             cptr = C + i * K + j;
//             wptr = w;
//             *cptr = 0;
//             for (l = 0; l < N; l++, aptr++, bptr++, wptr++) {
//                 *cptr += (*aptr) * (*bptr) * (*wptr);
//             }
//         }
//     }
// 
//     // Since C is symmetric, we only compute the lower triangle and then
//     // copy it back into the opper triangle
// 
//     for (i = 0; i < K; i++) {
//         for (j = i + 1; j < K; j++) {
//             C[i * K + j] = C[j * K + i];
//         }
//     }
// }
//
// void gf_regress_linalg_dgemm_wcolmajor_ix (
//     ST_double *A,
//     ST_double *B,
//     ST_double *C,
//     ST_double *w,
//     GT_size k1,
//     GT_size k2,
//     GT_size k3)
// {
//     GT_size i, j, l;
//     ST_double *aptr, *bptr, *cptr, *wptr;
//     memset(C, '\0', k1 * k3 * sizeof(ST_double));
//     bptr = B;
//     for (i = 0; i < k3; i++) {
//         aptr = A;
//         for (j = 0; j < k2; j++, bptr++) {
//             cptr = C + i * k1;
//             wptr = w + j;
//             for (l = 0; l < k1; l++, aptr++, cptr++) {
//                 *cptr += (*aptr) * (*bptr) * (*wptr);
//             }
//         }
//     }
// }
//
// void gf_regress_linalg_dgemTm_wcolmajor(
//     ST_double *A,
//     ST_double *B,
//     ST_double *C,
//     ST_double *w,
//     GT_size N,
//     GT_size k1,
//     GT_size k2)
// {
//     GT_size i, k, l;
//     ST_double *aptr, *bptr, *cptr, *wptr;
//     memset(C, '\0', k1 * k2 * sizeof(ST_double));
//     cptr = C;
//     for (l = 0; l < k2; l++) {
//         aptr = A;
//         for (k = 0; k < k1; k++, cptr++) {
//             bptr  = B + l * N;
//             wptr  = w;
//             for (i = 0; i < N; i++, aptr++, bptr++, wptr++) {
//                 *cptr += (*aptr) * (*bptr) * (*wptr);
//             }
//         }
//     }
// }
