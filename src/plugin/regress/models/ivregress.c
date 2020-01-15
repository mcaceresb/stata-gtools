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
    GT_bool singular = 0;
    GT_size kx_fs = kexog + kz;
    GT_size kx_ss = kendog + kexog;

    // Run the first stage; note that in memory, [Xendog Xexog Z]

    // [Xexog Z]' [Xexog Z] -> XX, then XX^-1
    gf_regress_linalg_dsymm_colmajor (Xexog, Xexog, XX, N, kx_fs);
    gf_regress_linalg_dsyldu (XX, kx_fs, XX + kx_fs * kx_fs, colix, &singular);

    // gf_regress_linalg_dsyqr (XX, kx_fs, XX + kx_fs * kx_fs, colix, &singular); // collinearity check
    // gf_regress_linalg_dsysv (XX, kx_fs, &singular);                            // XX -> XX^-1
    // gf_regress_printf_colmajor (XX, colix[kx_fs], colix[kx_fs], "XX^-1");

    if ( colix[kx_fs] < kx_fs ) {
        gf_regress_linalg_dgemTm_colmajor_ix1 (Xexog, Xendog, PZ, colix, N, kx_fs, kendog);     // [Xexog Z]' X -> PZ
        gf_regress_linalg_dgemTm_colmajor     (XX, PZ, BZ, colix[kx_fs], colix[kx_fs], kendog); // XX PZ -> BZ

        // NOTE: You need the unprojected endogeous vars for the errors
        memcpy(PZ, Xendog, sizeof(ST_double) * N * kendog);
        gf_regress_linalg_dgemm_colmajor_ix1  (Xexog, BZ, Xendog, colix, N, kx_fs, kendog);     // [Xexog Z] BZ -> Xendog
    }
    else {
        gf_regress_linalg_dgemTm_colmajor (Xexog, Xendog, PZ, N, kx_fs, kendog); // [Xexog Z]' X -> PZ
        gf_regress_linalg_dgemTm_colmajor (XX, PZ, BZ, kx_fs, kx_fs, kendog);    // XX PZ -> BZ

        // NOTE: You need the unprojected endogeous vars for the errors
        memcpy(PZ, Xendog, sizeof(ST_double) * N * kendog);
        gf_regress_linalg_dgemm_colmajor  (Xexog, BZ, Xendog, N, kx_fs, kendog); // [Xexog Z] BZ -> Xendog
    }

    // Run the second stage; OLS with
    //
    //     X = [PZ (Xendog projected onto Z) Xexog]
    //
    // which are contiguous in memory. Also note
    //
    //     KZ = (kz + kexog) * kendog >= kendog + kexog
    //
    // so we can use ot for X' y

    // X' X -> XX, then XX^-1
    gf_regress_linalg_dsymm_colmajor (Xendog, Xendog, XX, N, kx_ss);
    gf_regress_linalg_dsyldu (XX, kx_ss, XX + kx_ss * kx_ss, colix, &singular);

    // gf_regress_linalg_dsyqr (XX, kx_ss, XX + kx_ss * kx_ss, colix, &singular);
    // gf_regress_linalg_dsysv (XX, kx_ss, &singular);
    // gf_regress_printf_colmajor (XX, colix[kx_ss], colix[kx_ss], "XX^-1");

    // NOTE(mauricio): You use PZ rather than Xendog (this is the
    // issue with the double memory swap) because you use the original
    // variables for the errors, not the projected variables.

    if ( colix[kx_ss] < kx_ss ) {
        gf_regress_linalg_dgemTv_colmajor_ix1 (Xendog, y, BZ, colix, N, kx_ss);
        gf_regress_linalg_dgemTv_colmajor_ix2 (XX, BZ, b, colix, colix[kx_ss], kx_ss);

        // memcpy(Xendog, PZ, sizeof(ST_double) * N * kendog);
        gf_regress_linalg_iverror_ix (y, PZ, Xexog, b, e, colix, N, kendog, kexog);
    }
    else {
        gf_regress_linalg_dgemTv_colmajor (Xendog, y, BZ, N, kx_ss);
        gf_regress_linalg_dgemTv_colmajor (XX, BZ, b, kx_ss, kx_ss);

        // memcpy(Xendog, PZ, sizeof(ST_double) * N * kendog);
        gf_regress_linalg_iverror (y, PZ, Xexog, b, e, N, kendog, kexog);
    }

    return (singular);
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
    GT_bool singular = 0;
    GT_size kx_fs = kexog + kz;
    GT_size kx_ss = kendog + kexog;

    // Run the first stage; note that in memory, [Xendog Xexog Z]

    // [Xexog Z]' W [Xexog Z] -> XX
    gf_regress_linalg_dsymm_wcolmajor (Xexog, Xexog, XX, w, N, kx_fs);
    gf_regress_linalg_dsyldu (XX, kx_fs, XX + kx_fs * kx_fs, colix, &singular);

    if ( colix[kx_fs] < kx_fs ) {
        gf_regress_linalg_dgemTm_wcolmajor_ix1 (Xexog, Xendog, PZ, w, colix, N, kx_fs, kendog);  // [Xexog Z]' W X -> PZ
        gf_regress_linalg_dgemTm_colmajor      (XX, PZ, BZ, colix[kx_fs], colix[kx_fs], kendog); // XX PZ -> BZ

        // NOTE: You need the unprojected endogeous vars for the errors
        memcpy(PZ, Xendog, sizeof(ST_double) * N * kendog);
        gf_regress_linalg_dgemm_colmajor_ix1  (Xexog, BZ, Xendog, colix, N, kx_fs, kendog);      // [Xexog Z] BZ -> Xendog
    }
    else {
        gf_regress_linalg_dgemTm_wcolmajor (Xexog, Xendog, PZ, w, N, kx_fs, kendog); // [Xexog Z]' W X -> PZ
        gf_regress_linalg_dgemTm_colmajor  (XX, PZ, BZ, kx_fs, kx_fs, kendog);       // XX PZ -> BZ

        // NOTE: You need the unprojected endogeous vars for the errors
        memcpy(PZ, Xendog, sizeof(ST_double) * N * kendog);
        gf_regress_linalg_dgemm_colmajor   (Xexog, BZ, Xendog, N, kx_fs, kendog);    // [Xexog Z] BZ -> Xendog
    }

    // Run the second stage; OLS with
    //
    //     X = [PZ (Xendog projected onto Z) Xexog]
    //
    // which are contiguous in memory. Also note
    //
    //     KZ = (kz + kexog) * kendog >= kendog + kexog
    //
    // so we can use ot for X' y

    // X' X -> XX, then XX^-1
    gf_regress_linalg_dsymm_wcolmajor (Xendog, Xendog, XX, w, N, kx_ss);
    gf_regress_linalg_dsyldu (XX, kx_ss, XX + kx_ss * kx_ss, colix, &singular);

    // NOTE(mauricio): You use PZ rather than Xendog (this is the
    // issue with the double memory swap) because you use the original
    // variables for the errors, not the projected variables.

    if ( colix[kx_ss] < kx_ss ) {
        gf_regress_linalg_dgemTv_wcolmajor_ix1 (Xendog, y, BZ, w, colix, N, kx_ss);
        gf_regress_linalg_dgemTv_colmajor_ix2  (XX, BZ, b, colix, colix[kx_ss], kx_ss);

        // memcpy(Xendog, PZ, sizeof(ST_double) * N * kendog);
        gf_regress_linalg_iverror_ix (y, PZ, Xexog, b, e, colix, N, kendog, kexog);
    }
    else {
        gf_regress_linalg_dgemTv_wcolmajor (Xendog, y, BZ, w, N, kx_ss);
        gf_regress_linalg_dgemTv_colmajor  (XX, BZ, b, kx_ss, kx_ss);

        // memcpy(Xendog, PZ, sizeof(ST_double) * N * kendog);
        gf_regress_linalg_iverror (y, PZ, Xexog, b, e, N, kendog, kexog);
    }

    return (singular);
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

void gf_regress_linalg_iverror_ix(
    ST_double *y,
    ST_double *A1,
    ST_double *A2,
    ST_double *b,
    ST_double *c,
    GT_size *colix,
    GT_size N,
    GT_size k1,
    GT_size k2)
{
    GT_size i, k = 0, kindep = colix[k1 + k2];
    ST_double *aptr, *bptr, *cptr;
    memcpy(c, y, N * sizeof(ST_double));

    aptr = A1;
    while ( colix[k] < k1 && k <  kindep ) {
        cptr = c;
        bptr = b + colix[k];
        for (i = 0; i < N; i++, aptr++, cptr++) {
            *cptr -= (*aptr) * (*bptr);
        }
        k++;
    }

    aptr = A2;
    while ( k < kindep ) {
        cptr = c;
        bptr = b + colix[k];
        for (i = 0; i < N; i++, aptr++, cptr++) {
            *cptr -= (*aptr) * (*bptr);
        }
        k++;
    }
}
