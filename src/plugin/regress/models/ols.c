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
    GT_bool nonsingular = 1;
clock_t timer = clock();
    gf_regress_linalg_dsymm_colmajor (X, X, XX, N, kx);
sf_running_timer (&timer, "\tdebug 1: XX");

    // gf_regress_linalg_dsyqr  (XX, kx, XX + kx * kx, colix, &nonsingular);
    // gf_regress_linalg_dsylu  (XX, kx, XX + kx * kx, colix, &nonsingular);
    // gf_regress_linalg_dsyldu (XX, kx, XX + kx * kx, colix, &nonsingular);
    // gf_regress_linalg_dsysv  (XX, kx, &nonsingular);

    gf_regress_linalg_dsyldu (XX, kx, XX + kx * kx, colix, &nonsingular);
sf_running_timer (&timer, "\tdebug 3: LDU");
    gf_regress_linalg_dsysv  (XX, kx, &nonsingular);
sf_running_timer (&timer, "\tdebug 4: SV");
gf_regress_printf_colmajor (XX, kx, kx, "A^-1 legit");

    if ( nonsingular ) {
        gf_regress_linalg_dgemTv_colmajor (X, y, Xy, N, kx);
        gf_regress_linalg_dgemTv_colmajor (XX, Xy, b, kx, kx);
        gf_regress_linalg_error_colmajor  (y, X, b, e, N, kx);
    }
    else {
        memset(b, '\0', kx * (sizeof *b));
    }

    return(nonsingular);
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
    GT_bool nonsingular = 1;
    gf_regress_linalg_dsymm_wcolmajor (X, X, XX, w, N, kx);

    gf_regress_linalg_dsyqr (XX, kx, XX + kx * kx, colix, &nonsingular);
    gf_regress_linalg_dsysv (XX, kx, &nonsingular);

    if ( nonsingular ) {
        gf_regress_linalg_dgemTv_wcolmajor (X, y, Xy, w, N, kx);
        gf_regress_linalg_dgemTv_colmajor  (XX, Xy, b, kx, kx);
        gf_regress_linalg_error_colmajor   (y, X, b, e, N, kx);
    }
    else {
        memset(b, '\0', kx * (sizeof *b));
    }

    return (nonsingular);
}
