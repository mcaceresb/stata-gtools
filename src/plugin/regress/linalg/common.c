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

    if ( fabs(D) < GTOOLS_64BIT_EPSILON ) {
        sf_errprintf("singularity warning: matrix determinant < %.8g\n", GTOOLS_64BIT_EPSILON);
    }

    return (D);
}

// NOTE: You _could_ compute the inverse here and then set stuff to
// 0...no, better do colix, though it will be annoying...

/**
 * @brief Find the collinear rows of a matrix via QR decomposition
 *
 * @A N x N symmetric matrix
 * @N Number of rows and columns in A
 * @QR Helper vector where to store R, H, etc.
 * @ix Indeces for non-collinear columns
 * @return
 */
void gf_regress_linalg_dsyqr (ST_double *A, GT_size N, ST_double *QR)
{
    GT_size collinear;
    GT_size i, j;
    ST_double *rptr, rmax;

    // We don't need Q if we only care about collinearity
    ST_double *R = QR;
    ST_double *H = QR + 2 * N * N;

    // Initialize R = A and Q = I
    memcpy(R, A, N * N * sizeof(ST_double));

    // QR decomposition via Householder projections
    rptr = R + N * N;
    for (i = 0; i < N - 1; i++) {

        // H = I
        memset(H, '\0', N * N * sizeof(ST_double));
        for (j = 0; j < i; j++) {
            H[j * N + j] = 1;
        }

        // H[i::N, i::N] <- Householder using R[i::N, i]
        memcpy(rptr, R + i * N + i, (N - i) * sizeof(ST_double));
        gf_regress_linalg_dsyhh (rptr, N - i, i, H + i * N + i);

        // R <- H * R
        gf_regress_linalg_dgemm_colmajor (H, R, rptr, N, N, N);
        memcpy(R, rptr, N * N * sizeof(ST_double));
    }

    // NOTE: How much should I worry about false positives? False
    // negatives?  Should I try to compute the rank first? I mean, I
    // will have to have _some_ tolerance either way _somewhere_...

    collinear = 0;
    for (i = 0; i < N; i++) {

        // For each column a_i, we use tolerance = max(|a_i|) * N * eps,
        // where eps is the 64-bit machine epsilon, 2^-52

        rptr = A + i * N;
        rmax = fabs(rptr[0]);
        for (j = 1; j < N; j++) {
            if ( rmax < fabs(rptr[j]) ) rmax = fabs(rptr[j]);
        }
        rmax *= N;

        // If the i, i entry of R is numerically 0, then that column is
        // linearly dependent

        if ( (fabs(R[i * N + i]) / rmax) < GTOOLS_64BIT_EPSILON ) {
            collinear++;
            // Collinear
        }
        else {
            // OK
        }
    }

    // For now, just print a warning to the console
    if ( collinear ) {
        sf_errprintf("collinearity warning: "GT_size_cfmt" collinear columns detected\n", collinear);
    }
}

/**
 * @brief Find the Householder transformation of a vector a
 *
 * @a Vector of size N
 * @N length of vector
 * @H where to store Householder transformation
 * @return
 */
void gf_regress_linalg_dsyhh (ST_double *a, GT_size N, GT_size offset, ST_double *H)
{
    GT_size i, j;
    ST_double anorm, adot, *aptr, *hptr;


    if ( *a < 0 ) {
        anorm = -gf_regress_linalg_dnorm(a, N);
    }
    else {
        anorm = gf_regress_linalg_dnorm(a, N);
    }

    adot = 1;
    aptr = a + N;
    while ( --aptr > a ) {
        *aptr /= (*a + anorm);
        adot += (*aptr) * (*aptr);
    }
    *a = 1;

    adot = 2 / adot;
    for (i = 0; i < N; i++) {
        hptr  = H + i * (N + offset) + i;
        *hptr = 1 - adot * a[i] * a[i];
        hptr++;
        for (j = i + 1; j < N; j++, hptr++) {
            *hptr = -adot * a[i] * a[j];
        }
    }

    for (i = 0; i < N; i++) {
        for (j = i + 1; j < N; j++) {
            H[j * (N + offset) + i] = H[i * (N + offset) + j];
        }
    }
}

ST_double gf_regress_linalg_ddot (ST_double *a, GT_size N)
{
    ST_double *aptr;
    ST_double ddot = 0;
    for (aptr = a; aptr < a + N; aptr++) {
        ddot += (*aptr) * (*aptr);
    }
    return(ddot);
}

ST_double gf_regress_linalg_dnorm (ST_double *a, GT_size N)
{
    return (sqrt(gf_regress_linalg_ddot(a, N)));
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
