void gf_regress_ols_wcolmajor(
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
    gf_regress_linalg_dsymm_wcolmajor  (X, X, XX, w, N, kx);
    gf_regress_linalg_dsysv            (XX, kx);
    gf_regress_linalg_dgemTv_wcolmajor (X, y, Xy, w, N, kx);
    gf_regress_linalg_dgemTv_colmajor  (XX, Xy, b, kx, kx);
    gf_regress_linalg_error_wcolmajor  (y, X, b, w, e, N, kx);
}

void gf_regress_ols_robust_wcolmajor(
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

    gf_regress_linalg_dsymm_w2colmajor (X,  X,  e, V, N, kx);
    gf_regress_linalg_dgemm_colmajor   (V,  XX, VV, kx, kx, kx);
    gf_regress_linalg_dgemm_colmajor   (XX, VV, V,  kx, kx, kx);

    for (i = 0; i < N; i++) {
        Ndbl += w[i];
    }

    qc = Ndbl / (Ndbl - kmodel);
    for (i = 0; i < kx; i++) {
        se[i] = sqrt(V[i * kx + i] * qc);
    }
}

void gf_regress_ols_cluster_wcolmajor(
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
    GT_size kmodel)
{
    GT_size i, j, k, start, end;
    ST_double qc, *aptr, *bptr;
    ST_double Ndbl = 0;

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

    for (i = 0; i < N; i++) {
        Ndbl += w[i];
    }

    qc = (((ST_double) (Ndbl - 1)) / ((ST_double) (Ndbl - kmodel))) * ((ST_double) J / ((ST_double) (J - 1)));
    for (i = 0; i < kx; i++) {
        se[i] = sqrt(V[i * kx + i] * qc);
    }
}

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
