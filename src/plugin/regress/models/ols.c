/**
 * @brief Run basic OLS
 *
 * @X Independent variables; array of length N x kx
 * @y Dependent variable; array of length N
 * @XX Array of length kx x kx where to store X' X and (X' X)^-1
 * @Xy Array of length kx where to store X y
 * @b Array of length kx where to store the coefficients
 * @N Number of observations
 * @kx Number of X variables
 * @return Store OLS coefficients in @b
 */
GT_bool gf_regress_ols_colmajor(
    ST_double *X,
    ST_double *y,
    ST_double *w,
    ST_double *XX,
    ST_double *Xy,
    ST_double *e,
    ST_double *b,
    GT_size *colix,
    GT_size N,
    GT_size kx)
{
    GT_size kindep;
    GT_bool singular = 0;

    gf_regress_linalg_dsymm_colmajor (X, X, XX, N, kx);
    gf_regress_linalg_dsyldu (XX, kx, XX + kx * kx, colix, &singular);

    // gf_regress_dprintf_colmajor (XX, kx, kx, "XX");
    // gf_regress_linalg_dsysv (XX, kx, &singular);
    // gf_regress_dprintf_colmajor (XX, kindep, kindep, "XX^-1");

    kindep = colix[kx];
    if ( kindep > 0 ) {
        if ( kindep < kx ) {
            gf_regress_linalg_dgemTv_colmajor_ix1 (X, y, Xy, colix, N, kindep);
            gf_regress_linalg_dgemTv_colmajor     (XX, Xy, b, kindep, kindep);
            gf_regress_linalg_error_colmajor_ix1  (y, X, b, e, colix, N, kindep);
        }
        else {
            gf_regress_linalg_dgemTv_colmajor (X, y, Xy, N, kx);
            gf_regress_linalg_dgemTv_colmajor (XX, Xy, b, kx, kx);
            gf_regress_linalg_error_colmajor  (y, X, b, e, N, kx);
        }
    }

    // gf_regress_dprintf_colmajor (Xy, 1, kindep, "Xy");
    // gf_regress_dprintf_colmajor (b,  1, kindep, "b");

    return(singular);
}

GT_bool gf_regress_ols_wcolmajor(
    ST_double *X,
    ST_double *y,
    ST_double *w,
    ST_double *XX,
    ST_double *Xy,
    ST_double *e,
    ST_double *b,
    GT_size *colix,
    GT_size N,
    GT_size kx)
{
    GT_size kindep;
    GT_bool singular = 0;
    gf_regress_linalg_dsymm_wcolmajor (X, X, XX, w, N, kx);
    gf_regress_linalg_dsyldu (XX, kx, XX + kx * kx, colix, &singular);

    kindep = colix[kx];
    if ( kindep > 0 ) {
        if ( kindep < kx ) {
            gf_regress_linalg_dgemTv_wcolmajor_ix1 (X, y, Xy, w, colix, N, kindep);
            gf_regress_linalg_dgemTv_colmajor      (XX, Xy, b, kindep, kindep);
            gf_regress_linalg_error_colmajor_ix1   (y, X, b, e, colix, N, kindep);
        }
        else {
            gf_regress_linalg_dgemTv_wcolmajor (X, y, Xy, w, N, kx);
            gf_regress_linalg_dgemTv_colmajor  (XX, Xy, b, kx, kx);
            gf_regress_linalg_error_colmajor   (y, X, b, e, N, kx);
        }
    }

    return (singular);
}
