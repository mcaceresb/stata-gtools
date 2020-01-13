// NOTE(mauricio): The double memory swap seems inefficient...
// NOTE(mauricio): This leaves Xendog _projected_!!!
GT_bool gf_regress_iv_unw(
    ST_double *Xendog,
    ST_double *Xexog,
    ST_double *Z,
    ST_double *y,
    ST_double *w,
    ST_double *XX,
    ST_double *PZ,
    ST_double *BZ,
    ST_double *e,
    ST_double *b,
    GT_size *colix,
    GT_size N,
    GT_size kendog,
    GT_size kexog,
    GT_size kz)
{
    // GT_size i, j;
    GT_bool nonsingular = 1;
    GT_size kx_fs = kexog + kz;
    GT_size kx_ss = kendog + kexog;

    // Run the first stage; note that in memory, [Xendog Xexog Z]

    // [Xexog Z]' [Xexog Z] -> XX
    gf_regress_linalg_dsymm_colmajor  (Xexog, Xexog, XX, N, kx_fs);

    gf_regress_linalg_dsyqr (XX, kx_fs, XX + kx_fs * kx_fs, colix, &nonsingular); // collinearity check
    gf_regress_linalg_dsysv (XX, kx_fs, &nonsingular);                            // XX -> XX^-1

    if ( nonsingular ) {
        gf_regress_linalg_dgemTm_colmajor (Xexog, Xendog, PZ, N, kx_fs, kendog); // [Xexog Z]' X -> PZ
        gf_regress_linalg_dgemTm_colmajor (XX, PZ, BZ, kx_fs, kx_fs, kendog);    // XX PZ -> BZ

        memcpy(PZ, Xendog, sizeof(ST_double) * N * kendog);

        gf_regress_linalg_dgemm_colmajor  (Xexog, BZ, Xendog, N, kx_fs, kendog); // [Xexog Z] BZ -> Xendog

        // Run the second stage; OLS with X = [PZ (Xendog projected onto
        // Z) Xexog], which are contiguous in memory. Also note KZ = (kz +
        // kexog) * kendog >= kendog + kexog, so we can use ot for X' y

        gf_regress_linalg_dsymm_colmajor  (Xendog, Xendog, XX, N, kx_ss);

        gf_regress_linalg_dsyqr (XX, kx_ss, XX + kx_ss * kx_ss, colix, &nonsingular);
        gf_regress_linalg_dsysv (XX, kx_ss, &nonsingular);

        if ( nonsingular ) {
            gf_regress_linalg_dgemTv_colmajor (Xendog, y, BZ, N, kx_ss);
            gf_regress_linalg_dgemTv_colmajor (XX, BZ, b, kx_ss, kx_ss);

            // memcpy(Xendog, PZ, sizeof(ST_double) * N * kendog);
            gf_regress_linalg_iverror (y, PZ, Xexog, b, e, N, kendog, kexog);
        }
        else {
            memset(b, '\0', kx_ss * (sizeof *b));
        }
    }
    else {
        memset(b, '\0', kx_ss * (sizeof *b));
    }

    return (nonsingular);
}

GT_bool gf_regress_iv_w(
    ST_double *Xendog,
    ST_double *Xexog,
    ST_double *Z,
    ST_double *y,
    ST_double *w,
    ST_double *XX,
    ST_double *PZ,
    ST_double *BZ,
    ST_double *e,
    ST_double *b,
    GT_size *colix,
    GT_size N,
    GT_size kendog,
    GT_size kexog,
    GT_size kz)
{
    GT_bool nonsingular = 1;
    GT_size kx_fs = kexog + kz;
    GT_size kx_ss = kendog + kexog;

    // Run the first stage; note that in memory, [Xendog Xexog Z]

    // [Xexog Z]' W [Xexog Z] -> XX
    gf_regress_linalg_dsymm_wcolmajor (Xexog, Xexog, XX, w, N, kx_fs);          

    gf_regress_linalg_dsyqr (XX, kx_fs, XX + kx_fs * kx_fs, colix, &nonsingular); // collinearity check
    gf_regress_linalg_dsysv (XX, kx_fs, &nonsingular);                            // XX -> XX^-1

    if ( nonsingular ) {
        gf_regress_linalg_dgemTm_wcolmajor (Xexog, Xendog, PZ, w, N, kx_fs, kendog); // [Xexog Z]' W X -> PZ
        gf_regress_linalg_dgemTm_colmajor  (XX, PZ, BZ, kx_fs, kx_fs, kendog);       // XX PZ -> BZ

        memcpy(PZ, Xendog, sizeof(ST_double) * N * kendog);

        gf_regress_linalg_dgemm_colmajor   (Xexog, BZ, Xendog, N, kx_fs, kendog);    // [Xexog Z] BZ -> Xendog

        // Run the second stage; WLS with X = [PZ (Xendog projected onto
        // Z) Xexog], which are contiguous in memory. Also note KZ = (kz +
        // kexog) * kendog >= kendog + kexog, so we can use ot for X' y

        gf_regress_linalg_dsymm_wcolmajor (Xendog, Xendog, XX, w, N, kx_ss);

        gf_regress_linalg_dsyqr (XX, kx_ss, XX + kx_ss * kx_ss, colix, &nonsingular);
        gf_regress_linalg_dsysv (XX, kx_ss, &nonsingular);

        if ( nonsingular ) {
            gf_regress_linalg_dgemTv_wcolmajor (Xendog, y, BZ, w, N, kx_ss);
            gf_regress_linalg_dgemTv_colmajor  (XX, BZ, b, kx_ss, kx_ss);

            // memcpy(Xendog, PZ, sizeof(ST_double) * N * kendog);
            gf_regress_linalg_iverror (y, PZ, Xexog, b, e, N, kendog, kexog);
        }
        else {
            memset(b, '\0', kx_ss * (sizeof *b));
        }
    }
    else {
        memset(b, '\0', kx_ss * (sizeof *b));
    }

    return (nonsingular);
}

void gf_regress_linalg_iverror(
    ST_double *y,
    ST_double *A1,
    ST_double *A2,
    ST_double *b,
    ST_double *c,
    GT_size N,
    GT_size k1,
    GT_size k2)
{
    GT_size i, k;
    ST_double *aptr, *bptr, *cptr;
    memcpy(c, y, N * sizeof(ST_double));

    bptr = b;
    aptr = A1;
    for (k = 0; k < k1; k++, bptr++) {
        cptr = c;
        for (i = 0; i < N; i++, aptr++, cptr++) {
            *cptr -= (*aptr) * (*bptr);
        }
    }

    aptr = A2;
    for (k = 0; k < k2; k++, bptr++) {
        cptr = c;
        for (i = 0; i < N; i++, aptr++, cptr++) {
            *cptr -= (*aptr) * (*bptr);
        }
    }
}

//         printf("\n");
// for (i = 0; i < kx_fs; i++) {
//     for (j = 0; j < kx_fs; j++) {
//         printf("%9.5f\t", XX[i * kx_fs + j]);
//     }
//         printf("\n");
// }
//
//         printf("\n");
// for (i = 0; i < kx_fs; i++) {
//     for (j = 0; j < kendog; j++) {
//         printf("%9.5f\t", PZ[j * kx_fs + i]);
//     }
//         printf("\n");
// }
//
//         printf("\n");
// for (i = 0; i < kx_fs; i++) {
//     for (j = 0; j < kendog; j++) {
//         printf("%9.5f\t", BZ[j * kx_fs + i]);
//     }
//         printf("\n");
// }
//
//         printf("\n");
// for (i = 0; i < N; i++) {
//     for (j = 0; j < kendog; j++) {
//         printf("%9.5f\t", Xendog[j * N + i]);
//     }
//         printf("\n");
// }
