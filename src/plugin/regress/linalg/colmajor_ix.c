/*********************************************************************
 *                         Index; unweighted                         *
 *********************************************************************/

void gf_regress_ols_ixcolmajor(
    ST_double *X,
    ST_double *y,
    GT_size *ix,
    GT_size nix,
    ST_double *XX,
    ST_double *Xy,
    ST_double *e,
    ST_double *b,
    GT_size N,
    GT_size kx)
{
    gf_regress_linalg_dsymm_ixcolmajor  (X, X, XX, ix, nix, N, kx);
    gf_regress_linalg_dsysv             (XX, kx);
    gf_regress_linalg_dgemTv_ixcolmajor (X, y, Xy, ix, nix, N, kx);
    gf_regress_linalg_dgemTv_colmajor   (XX, Xy, b, kx, kx);
    gf_regress_linalg_error_ixcolmajor  (y, X, b, ix, nix, e, N, kx);
}

void gf_regress_ols_robust_ixcolmajor(
    ST_double *e,
    GT_size *ix,
    GT_size nix,
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

    gf_regress_linalg_dsymm_w2ixcolmajor (X,  X,  V, e, ix, nix, N, kx);
    gf_regress_linalg_dgemm_colmajor     (V,  XX, VV, kx, kx, kx);
    gf_regress_linalg_dgemm_colmajor     (XX, VV, V,  kx, kx, kx);

    qc = ((ST_double) N) / ((ST_double) (N - kmodel));
    for (i = 0; i < kx; i++) {
        se[i] = sqrt(V[i * kx + i] * qc);
    }
}

void gf_regress_linalg_dsymm_ixcolmajor(
    ST_double *A,
    ST_double *B,
    ST_double *C,
    GT_size *ix,
    GT_size nix,
    GT_size N,
    GT_size K)
{
    GT_size i, j, l, m;
    ST_double *aptr, *bptr, *cptr;

    for (i = 0; i < K; i++) {
        bptr = B;
        for (j = 0; j <= i; j++) {
            aptr = A + i * N;
            cptr = C + i * K + j;
            *cptr = 0;
            for (l = 0; l < nix; l++) {
                m = ix[l];
                *cptr += aptr[m] * bptr[m];
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

void gf_regress_linalg_dgemTv_ixcolmajor(
    ST_double *A,
    ST_double *b,
    ST_double *c,
    GT_size *ix,
    GT_size nix,
    GT_size N,
    GT_size K)
{
    GT_size i, k, m;
    ST_double *aptr, *cptr;

    aptr = A;
    cptr = c;
    for (k = 0; k < K; k++, aptr += N, cptr++) {
        *cptr = 0;
        for (i = 0; i < nix; i++) {
            m = ix[i];
            *cptr += aptr[m] * b[m];
        }
    }
}

void gf_regress_linalg_error_ixcolmajor(
    ST_double *y,
    ST_double *A,
    ST_double *b,
    GT_size *ix,
    GT_size nix,
    ST_double *c,
    GT_size N,
    GT_size K)
{
    GT_size i, k;
    ST_double *aptr, *bptr;

    for (i = 0; i < nix; i++) {
        c[i] = y[ix[i]];
    }

    aptr = A;
    bptr = b;
    for (k = 0; k < K; k++, bptr++, aptr += N) {
        for (i = 0; i < nix; i++) {
            c[i] -= aptr[ix[i]] * (*bptr);
        }
    }
}

/*********************************************************************
 *                        Index with weights                         *
 *********************************************************************/

void gf_regress_ols_wixcolmajor(
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
    gf_regress_linalg_dsymm_wixcolmajor  (X, X, XX, w, ix, nix, N, kx);
    gf_regress_linalg_dsysv              (XX, kx);
    gf_regress_linalg_dgemTv_wixcolmajor (X, y, Xy, w, ix, nix, N, kx);
    gf_regress_linalg_dgemTv_colmajor    (XX, Xy, b, kx, kx);
    gf_regress_linalg_error_wixcolmajor  (y, X, b, w, ix, nix, e, N, kx);
}

void gf_regress_ols_robust_wixcolmajor(
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
    GT_size kmodel)
{
    GT_size i;
    ST_double qc;
    ST_double Ndbl = 0;

    gf_regress_linalg_dsymm_w2ixcolmajor (X,  X,  V, e, ix, nix, N, kx);
    gf_regress_linalg_dgemm_colmajor     (V,  XX, VV, kx, kx, kx);
    gf_regress_linalg_dgemm_colmajor     (XX, VV, V,  kx, kx, kx);

    for (i = 0; i < nix; i++) {
        Ndbl += w[ix[i]];
    }

    qc = Ndbl / (Ndbl - kmodel);
    for (i = 0; i < kx; i++) {
        se[i] = sqrt(V[i * kx + i] * qc);
    }
}

void gf_regress_linalg_dsymm_wixcolmajor(
    ST_double *A,
    ST_double *B,
    ST_double *C,
    ST_double *w,
    GT_size *ix,
    GT_size nix,
    GT_size N,
    GT_size K)
{
    GT_size i, j, l, m;
    ST_double *aptr, *bptr, *cptr;

    for (i = 0; i < K; i++) {
        bptr = B;
        for (j = 0; j <= i; j++) {
            aptr = A + i * N;
            cptr = C + i * K + j;
            *cptr = 0;
            for (l = 0; l < nix; l++) {
                m = ix[l];
                *cptr += aptr[m] * bptr[m] * w[m];
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

void gf_regress_linalg_dsymm_w2ixcolmajor(
    ST_double *A,
    ST_double *B,
    ST_double *C,
    ST_double *w,
    GT_size *ix,
    GT_size nix,
    GT_size N,
    GT_size K)
{
    GT_size i, j, l, m;
    ST_double *aptr, *bptr, *cptr;

    for (i = 0; i < K; i++) {
        bptr = B;
        for (j = 0; j <= i; j++) {
            aptr = A + i * N;
            cptr = C + i * K + j;
            *cptr = 0;
            for (l = 0; l < nix; l++) {
                m = ix[l];
                *cptr += aptr[m] * bptr[m] * w[m] * w[m];
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

void gf_regress_linalg_dgemTv_wixcolmajor(
    ST_double *A,
    ST_double *b,
    ST_double *c,
    ST_double *w,
    GT_size *ix,
    GT_size nix,
    GT_size N,
    GT_size K)
{
    GT_size i, k, m;
    ST_double *aptr, *cptr;

    aptr = A;
    cptr = c;
    for (k = 0; k < K; k++, aptr += N, cptr++) {
        *cptr = 0;
        for (i = 0; i < nix; i++) {
            m = ix[i];
            *cptr += aptr[m] * b[m] * w[m];
        }
    }
}

void gf_regress_linalg_error_wixcolmajor(
    ST_double *y,
    ST_double *A,
    ST_double *b,
    ST_double *w,
    GT_size *ix,
    GT_size nix,
    ST_double *c,
    GT_size N,
    GT_size K)
{
    GT_size i, k;
    ST_double *aptr, *bptr;

    for (i = 0; i < nix; i++) {
        c[i] = y[ix[i]];
    }

    aptr = A;
    bptr = b;
    for (k = 0; k < K; k++, bptr++, aptr += N) {
        for (i = 0; i < nix; i++) {
            c[i] -= aptr[ix[i]] * (*bptr);
        }
    }

    for (i = 0; i < nix; i++) {
        c[i] *= w[ix[i]];
    }
}
