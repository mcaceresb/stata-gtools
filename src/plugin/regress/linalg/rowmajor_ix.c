/*********************************************************************
 *                         Index; unweighted                         *
 *********************************************************************/

// TODO: vceadj should also pass ix
// TODO: when doing cluster, etc. you should also passs ix
void gf_regress_ols_ixrowmajor(
    ST_double *X,
    ST_double *y,
    ST_double *w,
    GT_size *ix,
    GT_size nix,
    ST_double *XX,
    ST_double *Xy,
    ST_double *e,
    ST_double *b,
    GT_size N,
    GT_size kx)
{
    gf_regress_linalg_dsymm_ixrowmajor  (X, X, XX, ix, N, kx);
    gf_regress_linalg_dsysv             (XX, kx);
    gf_regress_linalg_dgemTv_ixrowmajor (X, y, Xy, ix, N, kx);
    gf_regress_linalg_dgemTv_rowmajor   (XX, Xy, b, kx, kx);
    gf_regress_linalg_error_ixrowmajor  (y, X, b, ix, e, N, kx);
}

void gf_regress_ols_robust_ixrowmajor(
    ST_double *e,
    ST_double *w,
    GT_size *ix,
    GT_size nix,
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
    ST_double qc = vceadj(N, kmodel, 0, w);

    gf_regress_linalg_dsymm_w2ixrowmajor(X,  X,  V, e, ix, N, kx);
    gf_regress_linalg_dgemm_rowmajor    (V,  XX, VV, kx, kx, kx);
    gf_regress_linalg_dgemm_rowmajor    (XX, VV, V,  kx, kx, kx);

    qc = ((ST_double) N) / ((ST_double) (N - kmodel));
    for (i = 0; i < kx; i++) {
        se[i] = sqrt(V[i * kx + i] * qc);
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

void gf_regress_linalg_dgemTv_ixrowmajor(
    ST_double *A,
    ST_double *b,
    ST_double *c,
    GT_size *ix,
    GT_size N,
    GT_size K)
{
    GT_size i, k, m;
    ST_double *aptr, *bptr;

    for (k = 0; k < K; k++) {
        c[k] = 0;
    }

    for (i = 0; i < N; i++) {
        m = ix[i];
        aptr = A + m * K;
        bptr = b + m;
        for (k = 0; k < K; k++, aptr++) {
            c[k] += (*aptr) * (*bptr);
        }
    }
}

void gf_regress_linalg_error_ixrowmajor(
    ST_double *y,
    ST_double *A,
    ST_double *b,
    GT_size *ix,
    ST_double *c,
    GT_size N,
    GT_size K)
{
    GT_size i, k, m;
    ST_double z, *aptr, *bptr;

    for (i = 0; i < N; i++) {
        z = 0;
        m = ix[i];
        aptr = A + m * K;
        bptr = b;
        for (k = 0; k < K; k++, aptr++, bptr++) {
            z += (*aptr) * (*bptr);
        }
        c[i] = y[m] - z;
    }
}

/*********************************************************************
 *                        Index with weights                         *
 *********************************************************************/

void gf_regress_ols_wixrowmajor(
    ST_double *X,
    ST_double *y,
    ST_double *w,
    GT_size *ix,
    GT_size nix,
    ST_double *XX,
    ST_double *Xy,
    ST_double *e,
    ST_double *b,
    GT_size N,
    GT_size kx)
{
    gf_regress_linalg_dsymm_wixrowmajor  (X, X, XX, w, ix, N, kx);
    gf_regress_linalg_dsysv              (XX, kx);
    gf_regress_linalg_dgemTv_wixrowmajor (X, y, Xy, w, ix, N, kx);
    gf_regress_linalg_dgemTv_rowmajor    (XX, Xy, b, kx, kx);
    gf_regress_linalg_error_ixrowmajor   (y, X, b, ix, e, N, kx);
}

void gf_regress_ols_robust_wixrowmajor(
    ST_double *e,
    ST_double *w,
    GT_size *ix,
    GT_size nix,
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
    ST_double qc = vceadj(N, kmodel, 0, w);

    gf_regress_linalg_dsymm_we2ixrowmajor(X,  X,  V, e, w, ix, N, kx);
    gf_regress_linalg_dgemm_rowmajor     (V,  XX, VV, kx, kx, kx);
    gf_regress_linalg_dgemm_rowmajor     (XX, VV, V,  kx, kx, kx);

    for (i = 0; i < kx; i++) {
        se[i] = sqrt(V[i * kx + i] * qc);
    }
}

void gf_regress_ols_robust_fwixrowmajor(
    ST_double *e,
    ST_double *w,
    GT_size *ix,
    GT_size nix,
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
    ST_double qc = vceadj(N, kmodel, 0, w);

    gf_regress_linalg_dsymm_fwe2ixrowmajor(X,  X,  V, e, w, ix, N, kx);
    gf_regress_linalg_dgemm_rowmajor      (V,  XX, VV, kx, kx, kx);
    gf_regress_linalg_dgemm_rowmajor      (XX, VV, V,  kx, kx, kx);

    for (i = 0; i < kx; i++) {
        se[i] = sqrt(V[i * kx + i] * qc);
    }
}

void gf_regress_linalg_dsymm_wixrowmajor(
    ST_double *A,
    ST_double *B,
    ST_double *C,
    ST_double *w,
    GT_size *ix,
    GT_size N,
    GT_size K)
{
    GT_size i, j, l, m;
    ST_double *aptr, *bptr, *wptr;

    for (i = 0; i < K; i++) {
        for (j = 0; j < K; j++) {
            C[i * K + j] = 0;
        }
    }

    for (i = 0; i < N; i++) {
        m = ix[i];
        wptr = w + m;
        bptr = B + m * K;
        for (j = 0; j < K; j++, bptr++) {
            aptr = A + m * K + j;
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

void gf_regress_linalg_dsymm_w2ixrowmajor(
    ST_double *A,
    ST_double *B,
    ST_double *C,
    ST_double *w,
    GT_size *ix,
    GT_size N,
    GT_size K)
{
    GT_size i, j, l, m;
    ST_double *aptr, *bptr, *wptr;

    for (i = 0; i < K; i++) {
        for (j = 0; j < K; j++) {
            C[i * K + j] = 0;
        }
    }

    for (i = 0; i < N; i++, wptr++) {
        m = ix[i];
        wptr = w + m;
        bptr = B + m * K;
        for (j = 0; j < K; j++, bptr++) {
            aptr = A + m * K + j;
            for (l = j; l < K; l++, aptr++) {
                C[j * K + l] += (*aptr) * (*bptr) * (*wptr) * (*wptr);
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

void gf_regress_linalg_dsymm_we2ixrowmajor(
    ST_double *A,
    ST_double *B,
    ST_double *C,
    ST_double *e,
    ST_double *w,
    GT_size *ix,
    GT_size N,
    GT_size K)
{
    GT_size i, j, l, m;
    ST_double *aptr, *bptr, *eptr, *wptr;

    for (i = 0; i < K; i++) {
        for (j = 0; j < K; j++) {
            C[i * K + j] = 0;
        }
    }

    for (i = 0; i < N; i++) {
        m = ix[i];
        eptr = e + m;
        wptr = w + m;
        bptr = B + m * K;
        for (j = 0; j < K; j++, bptr++) {
            aptr = A + m * K + j;
            for (l = j; l < K; l++, aptr++) {
                C[j * K + l] += (*aptr) * (*bptr) * (*eptr) * (*eptr) * (*wptr) * (*wptr);
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

void gf_regress_linalg_dsymm_fwe2ixrowmajor(
    ST_double *A,
    ST_double *B,
    ST_double *C,
    ST_double *e,
    ST_double *w,
    GT_size *ix,
    GT_size N,
    GT_size K)
{
    GT_size i, j, l, m;
    ST_double *aptr, *bptr, *eptr, *wptr;

    for (i = 0; i < K; i++) {
        for (j = 0; j < K; j++) {
            C[i * K + j] = 0;
        }
    }

    for (i = 0; i < N; i++) {
        m = ix[i];
        eptr = e + m;
        wptr = w + m;
        bptr = B + m * K;
        for (j = 0; j < K; j++, bptr++) {
            aptr = A + m * K + j;
            for (l = j; l < K; l++, aptr++) {
                C[j * K + l] += (*aptr) * (*bptr) * (*eptr) * (*eptr) * (*wptr);
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

void gf_regress_linalg_dgemTv_wixrowmajor(
    ST_double *A,
    ST_double *b,
    ST_double *c,
    ST_double *w,
    GT_size *ix,
    GT_size N,
    GT_size K)
{
    GT_size i, k, m;
    ST_double *aptr, *bptr, *wptr;

    for (k = 0; k < K; k++) {
        c[k] = 0;
    }

    for (i = 0; i < N; i++, bptr++, wptr++) {
        m = ix[i];
        bptr = b + m;
        wptr = w + m;
        aptr = A + m * K;
        for (k = 0; k < K; k++, aptr++) {
            c[k] += (*aptr) * (*bptr) * (*wptr);
        }
    }
}

void gf_regress_linalg_error_wixrowmajor(
    ST_double *y,
    ST_double *A,
    ST_double *b,
    ST_double *w,
    GT_size *ix,
    ST_double *c,
    GT_size N,
    GT_size K)
{
    GT_size i, k, m;
    ST_double z, *aptr, *bptr, *wptr;

    for (i = 0; i < N; i++) {
        z = 0;
        m = ix[i];
        aptr = A + m * K;;
        bptr = b;
        wptr = w + m;;
        for (k = 0; k < K; k++, aptr++, bptr++) {
            z += (*aptr) * (*bptr);
        }
        c[i] = (y[m] - z) * (*wptr);
    }
}
