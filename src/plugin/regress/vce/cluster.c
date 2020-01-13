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
    GT_size *colix,
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
    GT_size *colix,
    GT_size N,
    GT_size kx,
    GT_size kmodel,
    gf_regress_vceadj vceadj)
{
    GT_size i, j, k, start, end;
    ST_double qc, *aptr, *bptr, *wptr;
    qc = vceadj(N, kmodel, J, w);

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
        wptr = w;
        for (i = 0; i < N; i++, aptr++, bptr++, wptr++) {
            U[ux[i] * kx + k] += (*aptr) * (*bptr) * (*wptr);
        }
    }

    gf_regress_linalg_dsymm_rowmajor (U, U, V, J, kx);
    gf_regress_linalg_dgemm_colmajor (V,  XX, VV, kx, kx, kx);
    gf_regress_linalg_dgemm_colmajor (XX, VV, V,  kx, kx, kx);

    for (i = 0; i < kx; i++) {
        se[i] = sqrt(V[i * kx + i] * qc);
    }
}

