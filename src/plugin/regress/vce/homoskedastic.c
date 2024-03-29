/**
 * @brief Compute homo SE for OLS
 *
 * @e N length array of error terms
 * @V kx by kx matrix with (X' X)^-1
 * @se Array where to store SE
 * @N Number of obs
 * @kx Number of columns in A
 * @return Store sqrt(diag(sum(@e^2 / (@N - @kx)) * @V)) in @se
 */
void gf_regress_ols_seunw (
    ST_double *e,
    ST_double *w,
    ST_double *V,
    ST_double *se,
    GT_size *colix,
    GT_size N,
    GT_size kx,
    GT_size kmodel)
{
    GT_size i;
    ST_double z, *eptr;
    GT_size kindep = colix[kx];

    z = 0;
    for (eptr = e; eptr < e + N; eptr++) {
        z += (*eptr) * (*eptr);
    }
    z /= ((ST_double) (N - kmodel));

    for (i = 0; i < kindep; i++) {
        se[i] = sqrt(V[i * kindep + i] * z);
    }
}

void gf_regress_ols_sew (
    ST_double *e,
    ST_double *w,
    ST_double *V,
    ST_double *se,
    GT_size *colix,
    GT_size N,
    GT_size kx,
    GT_size kmodel)
{
    GT_size i;
    ST_double *eptr;
    ST_double z = 0;
    ST_double *wptr = w;
    GT_size kindep = colix[kx];

    for (eptr = e; eptr < e + N; eptr++, wptr++) {
        z += (*eptr) * (*eptr) * (*wptr);
    }
    z /= ((ST_double) (N - kmodel));

    for (i = 0; i < kindep; i++) {
        se[i] = sqrt(V[i * kindep + i] * z);
    }
}

void gf_regress_ols_sefw (
    ST_double *e,
    ST_double *w,
    ST_double *V,
    ST_double *se,
    GT_size *colix,
    GT_size N,
    GT_size kx,
    GT_size kmodel)
{
    GT_size i;
    ST_double *eptr;
    ST_double z = 0;
    ST_double Ndbl = 0;
    ST_double *wptr = w;
    GT_size kindep = colix[kx];

    for (eptr = e; eptr < e + N; eptr++, wptr++) {
        z += (*eptr) * (*eptr) * (*wptr);
        Ndbl += *wptr;
    }
    z /= (Ndbl - kmodel);

    for (i = 0; i < kindep; i++) {
        se[i] = sqrt(V[i * kindep + i] * z);
    }
}

void gf_regress_ols_copyvcov (
    ST_double *V,
    ST_double *XX,
    GT_size   kx,
    GT_size   *colix)
{
    GT_size i, j, kindep = colix[kx];
    for (i = 0; i < kindep; i++) {
        for (j = 0; j < kindep; j++) {
            V[i * kindep + j] = XX[i * kindep + j];
        }
    }
}
