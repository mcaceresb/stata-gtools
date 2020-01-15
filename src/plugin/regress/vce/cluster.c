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
    GT_size i, j, k, start, end, kindep;
    ST_double qc, *aptr, *bptr;

    kindep = colix[kx];
    memset(U, '\0', J * kindep * sizeof(ST_double));
    for (j = 0; j < J; j++) {
        start = info[j];
        end   = info[j + 1];
        for (i = start; i < end; i++) {
            ux[index[i]] = j;
        }
    }

    if ( kindep < kx ) {
        for (k = 0; k < kindep; k++) {
            aptr = X + colix[k] * N;
            bptr = e;
            for (i = 0; i < N; i++, aptr++, bptr++) {
                U[ux[i] * kindep + k] += (*aptr) * (*bptr);
            }
        }
    }
    else {
        aptr = X;
        for (k = 0; k < kindep; k++) {
            bptr = e;
            for (i = 0; i < N; i++, aptr++, bptr++) {
                U[ux[i] * kindep + k] += (*aptr) * (*bptr);
            }
        }
    }

    gf_regress_linalg_dsymm_rowmajor (U, U, V, J, kindep);
    gf_regress_linalg_dgemm_colmajor (XX, V,  VV, kindep, kindep, kindep);
    gf_regress_linalg_dgemm_colmajor (VV, XX, V,  kindep, kindep, kindep);

    qc = vceadj(N, kmodel, J, w);
    if ( kindep < kx ) {

        // NOTE(mauricio): Can I assume that kindep is at least 1? Surely
        // not _every_ column can be independent, so I should be safe here.
        // In any case, this seems like a rather poor way of doing this.
        // Think of a cleverer way if you can manage it.

        for (i = 0; i < kx; i++) {
            se[i] = SV_missval;
        }

        for (i = 0; i < kindep; i++) {
            se[colix[i]] = sqrt(V[i * kindep + i] * qc);
        }
    }
    else {
        for (i = 0; i < kindep; i++) {
            se[i] = sqrt(V[i * kindep + i] * qc);
        }
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
    GT_size i, j, k, start, end, kindep;
    ST_double qc, *aptr, *bptr, *wptr;

    kindep = colix[kx];
    memset(U, '\0', J * kindep * sizeof(ST_double));
    for (j = 0; j < J; j++) {
        start = info[j];
        end   = info[j + 1];
        for (i = start; i < end; i++) {
            ux[index[i]] = j;
        }
    }

    if ( kindep < kx ) {
        for (k = 0; k < kindep; k++) {
            aptr = X + colix[k] * N;
            bptr = e;
            wptr = w;
            for (i = 0; i < N; i++, aptr++, bptr++, wptr++) {
                U[ux[i] * kindep + k] += (*aptr) * (*bptr) * (*wptr);
            }
        }
    }
    else {
        aptr = X;
        for (k = 0; k < kindep; k++) {
            bptr = e;
            wptr = w;
            for (i = 0; i < N; i++, aptr++, bptr++, wptr++) {
                U[ux[i] * kindep + k] += (*aptr) * (*bptr) * (*wptr);
            }
        }
    }

    gf_regress_linalg_dsymm_rowmajor (U, U, V, J, kindep);
    gf_regress_linalg_dgemm_colmajor (XX, V,  VV, kindep, kindep, kindep);
    gf_regress_linalg_dgemm_colmajor (VV, XX, V,  kindep, kindep, kindep);

    qc = vceadj(N, kmodel, J, w);
    if ( kindep < kx ) {
        for (i = 0; i < kx; i++) {
            se[i] = SV_missval;
        }
        for (i = 0; i < kindep; i++) {
            se[colix[i]] = sqrt(V[i * kindep + i] * qc);
        }
    }
    else {
        for (i = 0; i < kindep; i++) {
            se[i] = sqrt(V[i * kindep + i] * qc);
        }
    }
}

