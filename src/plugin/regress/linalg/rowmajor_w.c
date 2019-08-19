void gf_regress_ols_wrowmajor(
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
    gf_regress_linalg_dsymm_wrowmajor  (X, X, XX, w, N, kx);
    gf_regress_linalg_dsysv            (XX, kx);
    gf_regress_linalg_dgemTv_wrowmajor (X, y, Xy, w, N, kx);
    gf_regress_linalg_dgemTv_rowmajor  (XX, Xy, b, kx, kx);
    gf_regress_linalg_error_wrowmajor  (y, X, b, w, e, N, kx);
}

void gf_regress_ols_robust_wrowmajor(
    ST_double *e,
    ST_double *w,
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
    ST_double Ndbl = 0;

    gf_regress_linalg_dsymm_w2rowmajor (X,  X,  V, e, N, kx);
    gf_regress_linalg_dgemm_rowmajor   (V,  XX, VV, kx, kx, kx);
    gf_regress_linalg_dgemm_rowmajor   (XX, VV, V,  kx, kx, kx);

    for (i = 0; i < N; i++) {
        Ndbl += w[i];
    }

    qc = Ndbl / (Ndbl - kmodel);
    for (i = 0; i < kx; i++) {
        se[i] = sqrt(V[i * kx + i] * qc);
    }
}

void gf_regress_ols_cluster_wrowmajor(
    ST_double *e,
    ST_double *w,
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
    ST_double Ndbl = 0;

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

    for (i = 0; i < N; i++) {
        Ndbl += w[i];
    }

    qc = (((ST_double) (Ndbl - 1)) / ((ST_double) (Ndbl - kmodel))) * ((ST_double) J / ((ST_double) (J - 1)));
    for (i = 0; i < kx; i++) {
        se[i] = sqrt(V[i * kx + i] * qc);
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

void gf_regress_linalg_dsymm_w2rowmajor(
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

void gf_regress_linalg_dgemTv_wrowmajor(
    ST_double *A,
    ST_double *b,
    ST_double *c,
    ST_double *w,
    GT_size N,
    GT_size K)
{
    GT_size i, k;
    ST_double *aptr, *bptr, *wptr;

    for (k = 0; k < K; k++) {
        c[k] = 0;
    }

    aptr = A;
    bptr = b;
    wptr = w;
    for (i = 0; i < N; i++, bptr++, wptr++) {
        for (k = 0; k < K; k++, aptr++) {
            c[k] += (*aptr) * (*bptr) * (*wptr);
        }
    }
}

void gf_regress_linalg_error_wrowmajor(
    ST_double *y,
    ST_double *A,
    ST_double *b,
    ST_double *w,
    ST_double *c,
    GT_size N,
    GT_size K)
{
    GT_size i, k;
    ST_double z, *aptr, *bptr, *wptr;

    aptr = A;
    wptr = w;
    for (i = 0; i < N; i++, wptr++) {
        z = 0;
        bptr = b;
        for (k = 0; k < K; k++, aptr++, bptr++) {
            z += (*aptr) * (*bptr);
        }
        c[i] = (y[i] - z) * (*wptr);
    }
}
