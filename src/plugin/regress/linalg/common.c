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
    GT_size N,
    GT_size kx,
    GT_size kmodel)
{
    GT_size i;
    ST_double z, *eptr;

    z = 0;
    for (eptr = e; eptr < e + N; eptr++) {
        z += (*eptr) * (*eptr);
    }
    z /= ((ST_double) (N - kmodel));

    for (i = 0; i < kx; i++) {
        se[i] = sqrt(V[i * kx + i] * z);
    }
}

void gf_regress_ols_sew (
    ST_double *e,
    ST_double *w,
    ST_double *V,
    ST_double *se,
    GT_size N,
    GT_size kx,
    GT_size kmodel)
{
    GT_size i;
    ST_double *eptr;
    ST_double z = 0;
    ST_double *wptr = w;

    for (eptr = e; eptr < e + N; eptr++, wptr++) {
        z += (*eptr) * (*eptr) * (*wptr);
    }
    z /= ((ST_double) (N - kmodel));

    for (i = 0; i < kx; i++) {
        se[i] = sqrt(V[i * kx + i] * z);
    }
}

void gf_regress_ols_sefw (
    ST_double *e,
    ST_double *w,
    ST_double *V,
    ST_double *se,
    GT_size N,
    GT_size kx,
    GT_size kmodel)
{
    GT_size i;
    ST_double *eptr;
    ST_double z = 0;
    ST_double Ndbl = 0;
    ST_double *wptr = w;

    for (eptr = e; eptr < e + N; eptr++, wptr++) {
        z += (*eptr) * (*eptr) * (*wptr);
        Ndbl += *wptr;
    }
    z /= (Ndbl - kmodel);

    for (i = 0; i < kx; i++) {
        se[i] = sqrt(V[i * kx + i] * z);
    }
}

// NOTE: Use D from dsysv to see if inverse exists? abs(D) < machine eps => warn numerically 0?
// NOTE: Colinearity!!!

/**
 * @brief Replaces a symmetric matrix A with its inverse, A^-1; returns the determinant |A|
 * @source http://www.irma-international.org/viewtitle/41011/
 *
 * @A K x K symmetric matrix
 * @K Number of rows and columns in A
 * @return Store A^-1 in @A and return the determinant |A|
 */
ST_double gf_regress_linalg_dsysv (ST_double *A, GT_size K)
{
    ST_double z, D = 1;
    GT_size i, j, p;

    p = 0;
    z = A[p * K + p];
    D = (z != 0)? 1: 0;
    while ( p < K && z > 0 ) {
        z  = A[p * K + p];
        D *= z;
        for (i = 0; i < K; i++) {
            if ( i != p ) {
                A[i * K + p] /= -z;
                for (j = 0; j < K; j++) {
                    if ( j != p ) {
                        A[i * K + j] += A[i * K + p] * A[p * K + j];
                    }
                }
            }
        }
        for (j = 0; j < K; j++) {
            if ( j != p ) {
                A[p * K + j] /= z;
            }
        }
        A[p * K + p] = 1 / z;
        p++;
    }

    if ( D < 1e-16 ) {
        sf_errprintf("singularity warning: matrix determinant < 1e-16\n");
    }

    return (D);
}

/*********************************************************************
 *                          VCE Adjustments                          *
 *********************************************************************/

ST_double gf_regress_vceadj_ols_robust(
    GT_size N,
    GT_size kmodel,
    GT_size J,
    ST_double *w)
{
    ST_double Ndbl = N;
    return(Ndbl / (Ndbl - kmodel));
}

ST_double gf_regress_vceadj_ols_cluster(
    GT_size N,
    GT_size kmodel,
    GT_size J,
    ST_double *w)
{
    ST_double Ndbl = N;
    ST_double Jdbl = J;
    return(((Ndbl - 1) / (Ndbl - kmodel)) * (Jdbl / (Jdbl - 1)));
}

ST_double gf_regress_vceadj_mle_robust(
    GT_size N,
    GT_size kmodel,
    GT_size J,
    ST_double *w)
{
    ST_double Ndbl = N;
    return(Ndbl / (Ndbl - 1));
}

ST_double gf_regress_vceadj_mle_cluster(
    GT_size N,
    GT_size kmodel,
    GT_size J,
    ST_double *w)
{
    ST_double Jdbl = J;
    return(Jdbl / (Jdbl - 1));
}

ST_double gf_regress_vceadj_ols_robust_fw(
    GT_size N,
    GT_size kmodel,
    GT_size J,
    ST_double *w)
{
    GT_size i;
    ST_double Ndbl = 0;
    for (i = 0; i < N; i++) {
        Ndbl += w[i];
    }
    return(Ndbl / (Ndbl - kmodel));
}

ST_double gf_regress_vceadj_ols_cluster_fw(
    GT_size N,
    GT_size kmodel,
    GT_size J,
    ST_double *w)
{
    GT_size i;
    ST_double Ndbl = 0;
    ST_double Jdbl = J;
    for (i = 0; i < N; i++) {
        Ndbl += w[i];
    }
    return(((Ndbl - 1) / (Ndbl - kmodel)) * (Jdbl / (Jdbl - 1)));
}

ST_double gf_regress_vceadj_mle_robust_fw(
    GT_size N,
    GT_size kmodel,
    GT_size J,
    ST_double *w)
{
    GT_size i;
    ST_double Ndbl = 0;
    for (i = 0; i < N; i++) {
        Ndbl += w[i];
    }
    return(Ndbl / (Ndbl - 1));
}

ST_double gf_regress_vceadj_mle_cluster_fw(
    GT_size N,
    GT_size kmodel,
    GT_size J,
    ST_double *w)
{
    ST_double Jdbl = J;
    return(Jdbl / (Jdbl - 1));
}
