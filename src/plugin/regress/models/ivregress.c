// NOTE(mauricio): This leaves Xendog _projected_
// NOTE(mauricio): Xendog gets _moved_ if there are collinear variables

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
    ST_double *aptr, *bptr, *xptr, *XXinv;

    GT_size i, j, *ixptr;
    GT_size kindep_endog;
    GT_size kindep_exog;
    GT_size kindep_z;
    GT_size kindep_fs;
    GT_size kindep_ss;
    GT_size kmixed_ss;
    GT_size kindep_iv;
    GT_size kindep_diff;

    GT_bool singular  = 0;
    GT_size kx_fs     = kexog + kz;
    GT_size kx_ss     = kendog + kexog;
    GT_size kx_iv     = kendog + kexog + kz;
    GT_size *colix_fs = colix + 1 * (kx_iv + 1);
    GT_size *colix_ss = colix + 2 * (kx_iv + 1);

    /*********************************************************************
     *                        Colinearity Checks                         *
     *********************************************************************/

    // Run collinearity check; break if under-identified
    // [Xendog Xexog Z]' [Xendog Xexog Z] -> XX, then XX^-1

    gf_regress_linalg_dsymm_colmajor (Xendog, Xendog, XX, N, kx_iv);
    gf_regress_linalg_dcollinear (XX, kx_iv, XX + kx_iv * kx_iv, colix);

    // If there are no usable columns, exit and set all values to missing
    if ( colix[kx_iv] == 0 ) {
        return (4);
    }

    // Get # of independent variables for various parts of the model
    gf_regress_linalg_ivcollinear_ix (colix, kendog, kexog, kz);

    kindep_endog = colix[kx_iv + 1];
    kindep_exog  = colix[kx_iv + 2];
    kindep_z     = colix[kx_iv + 3];
    kindep_fs    = colix[kx_iv + 4];
    kindep_ss    = colix[kx_iv + 5];
    kindep_iv    = colix[kx_iv + 6];
    kmixed_ss    = kindep_endog + kexog;
    kindep_diff  = kendog - kindep_endog;

    // After collinearity check, if # endogenous > # exogenous then exit
    if ( kindep_endog > kindep_z ) {
        return (3);
    }

    // If there are no usable columns, exit and set all values to missing
    if ( kindep_endog == 0 || kindep_z == 0 ) {
        return (4);
    }

    // Index for first-stage collinar columns (use there were any
    // collinear instruments _or_ exogenous covariates).

    if ( kindep_fs < kx_fs ) {
        ixptr = colix_fs;
        for (j = kindep_endog; j < kindep_iv; j++, ixptr++) {
            *ixptr = colix[j] - kendog;
        }
        colix_fs[kx_fs] = kindep_fs;
    }

    // Index for second-stage collinar columns. Note the mixed nature.
    // Since we only project the non-collinear endogenous covariates,
    // they will be contiguous in memory regardless of whether there was
    // any collinearity detected. Hence the indexing is only required in
    // the second stage of there were collinear exogenous covariates.

    if ( kindep_exog < kexog ) {
        ixptr = colix_ss;
        for (j = 0; j < kindep_endog; j++, ixptr++) {
            *ixptr = j;
        }

        for (j = kindep_endog; j < kindep_ss; j++, ixptr++) {
            *ixptr = colix[j] - kindep_diff;
        }
    }

    // Note Xendog will be projected sequentially, so we will use
    // colix_ss in the SE calculations. Hence we always need colix_ss to
    // have info on the number of 2nd stage independent vars

    colix_ss[kmixed_ss] = kindep_ss;
    colix_ss[kx_ss]     = kindep_ss;
    colix_ss[kx_ss + 1] = kmixed_ss;
    colix_ss[kx_ss + 2] = kindep_endog;

    // NOTE(mauricio): We copy XX and PZ without collinear columns
    // _using_ colix, so that accounts for collinarity in _any_ group
    // (i.e. endogenous, exogenous, or instruments). Thus the two
    // indexing arrays we just created will suffice.

    /*********************************************************************
     *                            First Stage                            *
     *********************************************************************/

    // Copy back [Xexog Z]' X -> PZ w/o collinear cols
    // gf_regress_linalg_dgemTm_colmajor (Xexog, Xendog, PZ, N, kx_fs, kendog);
    aptr = PZ;
    for (j = 0; j < kindep_endog; j++) {
        bptr = XX + colix[j] * kx_iv;
        for (i = kindep_endog; i < kindep_iv; i++, aptr++) {
            *aptr = bptr[colix[i]];
        }
    }

    // Copy back to XX w/o collinear cols
    XXinv = aptr = XX + kx_iv * kx_iv;
    for (j = kindep_endog; j < kindep_iv; j++) {
        bptr = XX + colix[j] * kx_iv;
        for (i = kindep_endog; i < kindep_iv; i++, aptr++) {
            *aptr = bptr[colix[i]];
        }
    }

    // Invert XX = [Xexog Z]' [Xexog Z]
    gf_regress_linalg_dsysv (XXinv, kindep_fs, &singular);

    // XX PZ -> BZ (compute the first stage coefficients)
    gf_regress_linalg_dgemTm_colmajor (XXinv, PZ, BZ, kindep_fs, kindep_fs, kindep_endog);

    // PZ <- Xendog (copy the unprojected endogeous vars for the errors)
    memcpy(PZ, Xendog, sizeof(ST_double) * N * kendog);

    // Xendog <- [Xexog Z] BZ (first stage projection)
    xptr = Xendog + N * kindep_diff;

    // [Xexog Z] BZ -> Xendog (with colix switch)
    if ( kindep_fs < kx_fs ) {
        gf_regress_linalg_dgemm_colmajor_ix1 (Xexog, BZ, xptr, colix_fs, N, kindep_fs, kindep_endog);
    }
    else {
        gf_regress_linalg_dgemm_colmajor (Xexog, BZ, xptr, N, kx_fs, kindep_endog);
    }

    /*********************************************************************
     *                           Second Stage                            *
     *********************************************************************/

    // Run the second stage; OLS with
    //
    //     X = [(Xendog projected onto Z) Xexog]
    //
    // which are contiguous in memory. Also note
    //
    //     KZ = (kz + kexog) * kendog >= kendog + kexog
    //
    // so we can use ot for X' y

    // gf_regress_linalg_dsyldu (XX, kmixed_ss, XX + kmixed_ss * kmixed_ss, colix, &singular);
    if ( kindep_ss < kmixed_ss ) {
        // X' X -> XX, then XX^-1
        gf_regress_linalg_dsymm_colmajor_ix (xptr, xptr, XX, colix_ss, N, kindep_ss);
        gf_regress_linalg_dsysv (XX, kindep_ss, &singular);

        // Second stage coefficients
        gf_regress_linalg_dgemTv_colmajor_ix1 (xptr, y, BZ, colix_ss, N, kindep_ss);
        gf_regress_linalg_dgemTv_colmajor (XX, BZ, b, kindep_ss, kindep_ss);
    }
    else {
        // X' X -> XX, then XX^-1
        gf_regress_linalg_dsymm_colmajor (xptr, xptr, XX, N, kindep_ss);
        gf_regress_linalg_dsysv (XX, kindep_ss, &singular);

        // Second stage coefficients
        gf_regress_linalg_dgemTv_colmajor (xptr, y, BZ, N, kindep_ss);
        gf_regress_linalg_dgemTv_colmajor (XX, BZ, b, kindep_ss, kindep_ss);
    }

    // Note that we need the ix version for the errors if collinearity
    // was detected in the endogenous _or_ exogenous variables, but not
    // within the instruments.

    if ( kindep_endog < kendog || kindep_exog < kexog ) {
        // Second stage errors
        gf_regress_linalg_iverror_ix (y, PZ, Xexog, b, e, colix, N, kendog, kindep_endog, kindep_exog);
    }
    else {
        // Second stage errors
        gf_regress_linalg_iverror (y, PZ, Xexog, b, e, N, kendog, kexog);
    }

    // singular = 1 denotes _any_ collinearity (as opposed to numerically
    // zero determinant with no collinearity detected).

    if ( kindep_fs < kx_fs || kindep_ss < kx_ss ) {
        singular = 1;
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
    ST_double *aptr, *bptr, *xptr, *XXinv;

    GT_size i, j, *ixptr;
    GT_size kindep_endog;
    GT_size kindep_exog;
    GT_size kindep_z;
    GT_size kindep_fs;
    GT_size kindep_ss;
    GT_size kmixed_ss;
    GT_size kindep_iv;
    GT_size kindep_diff;

    GT_bool singular  = 0;
    GT_size kx_fs     = kexog + kz;
    GT_size kx_ss     = kendog + kexog;
    GT_size kx_iv     = kendog + kexog + kz;
    GT_size *colix_fs = colix + 1 * (kx_iv + 1);
    GT_size *colix_ss = colix + 2 * (kx_iv + 1);

    /*********************************************************************
     *                        Colinearity Checks                         *
     *********************************************************************/

    // Run collinearity check; break if under-identified
    // [Xendog Xexog Z]' W [Xendog Xexog Z] -> XX, then XX^-1

    gf_regress_linalg_dsymm_wcolmajor (Xendog, Xendog, XX, w, N, kx_iv);
    gf_regress_linalg_dcollinear (XX, kx_iv, XX + kx_iv * kx_iv, colix);

    // If there are no usable columns, exit and set all values to missing
    if ( colix[kx_iv] == 0 ) {
        return (4);
    }

    // Get # of independent variables for various parts of the model
    gf_regress_linalg_ivcollinear_ix (colix, kendog, kexog, kz);

    kindep_endog = colix[kx_iv + 1];
    kindep_exog  = colix[kx_iv + 2];
    kindep_z     = colix[kx_iv + 3];
    kindep_fs    = colix[kx_iv + 4];
    kindep_ss    = colix[kx_iv + 5];
    kindep_iv    = colix[kx_iv + 6];
    kmixed_ss    = kindep_endog + kexog;
    kindep_diff  = kendog - kindep_endog;

    // After collinearity check, if # endogenous > # exogenous then exit
    if ( kindep_endog > kindep_z ) {
        return (3);
    }

    // If there are no usable columns, exit and set all values to missing
    if ( kindep_endog == 0 || kindep_z == 0 ) {
        return (4);
    }

    // Index for first-stage collinar columns (use there were any
    // collinear instruments _or_ exogenous covariates).

    if ( kindep_fs < kx_fs ) {
        ixptr = colix_fs;
        for (j = kindep_endog; j < kindep_iv; j++, ixptr++) {
            *ixptr = colix[j] - kendog;
        }
        colix_fs[kx_fs] = kindep_fs;
    }

    // Index for second-stage collinar columns. Note the mixed nature.
    // Since we only project the non-collinear endogenous covariates,
    // they will be contiguous in memory regardless of whether there was
    // any collinearity detected. Hence the indexing is only required in
    // the second stage of there were collinear exogenous covariates.

    if ( kindep_exog < kexog ) {
        ixptr = colix_ss;
        for (j = 0; j < kindep_endog; j++, ixptr++) {
            *ixptr = j;
        }

        for (j = kindep_endog; j < kindep_ss; j++, ixptr++) {
            *ixptr = colix[j] - kindep_diff;
        }
    }

    // Note Xendog will be projected sequentially, so we will use
    // colix_ss in the SE calculations. Hence we always need colix_ss to
    // have info on the number of 2nd stage independent vars

    colix_ss[kmixed_ss] = kindep_ss;
    colix_ss[kx_ss]     = kindep_ss;
    colix_ss[kx_ss + 1] = kmixed_ss;
    colix_ss[kx_ss + 2] = kindep_endog;

    // NOTE(mauricio): We copy XX and PZ without collinear columns
    // _using_ colix, so that accounts for collinarity in _any_ group
    // (i.e. endogenous, exogenous, or instruments). Thus the two
    // indexing arrays we just created will suffice.

    /*********************************************************************
     *                            First Stage                            *
     *********************************************************************/

    // Copy back [Xexog Z]' W X -> PZ w/o collinear cols
    // gf_regress_linalg_dgemTm_wcolmajor (Xexog, Xendog, PZ, w, N, kx_fs, kendog);
    aptr = PZ;
    for (j = 0; j < kindep_endog; j++) {
        bptr = XX + colix[j] * kx_iv;
        for (i = kindep_endog; i < kindep_iv; i++, aptr++) {
            *aptr = bptr[colix[i]];
        }
    }

    // Copy back to XX w/o collinear cols
    XXinv = aptr = XX + kx_iv * kx_iv;
    for (j = kindep_endog; j < kindep_iv; j++) {
        bptr = XX + colix[j] * kx_iv;
        for (i = kindep_endog; i < kindep_iv; i++, aptr++) {
            *aptr = bptr[colix[i]];
        }
    }

    // Invert XX = [Xexog Z]' [Xexog Z]
    gf_regress_linalg_dsysv (XXinv, kindep_fs, &singular);

    // XX PZ -> BZ (compute the first stage coefficients)
    gf_regress_linalg_dgemTm_colmajor (XXinv, PZ, BZ, kindep_fs, kindep_fs, kindep_endog);

    // PZ <- Xendog (copy the unprojected endogeous vars for the errors)
    memcpy(PZ, Xendog, sizeof(ST_double) * N * kendog);

    // Xendog <- [Xexog Z] BZ (first stage projection)
    xptr = Xendog + N * kindep_diff;

    // [Xexog Z] BZ -> Xendog (with colix switch)
    if ( kindep_fs < kx_fs ) {
        gf_regress_linalg_dgemm_colmajor_ix1 (Xexog, BZ, xptr, colix_fs, N, kindep_fs, kindep_endog);
    }
    else {
        gf_regress_linalg_dgemm_colmajor (Xexog, BZ, xptr, N, kx_fs, kindep_endog);
    }

    /*********************************************************************
     *                           Second Stage                            *
     *********************************************************************/

    // Run the second stage; OLS with
    //
    //     X = [(Xendog projected onto Z) Xexog]
    //
    // which are contiguous in memory. Also note
    //
    //     KZ = (kz + kexog) * kendog >= kendog + kexog
    //
    // so we can use ot for X' y

    // gf_regress_linalg_dsyldu (XX, kmixed_ss, XX + kmixed_ss * kmixed_ss, colix, &singular);
    if ( kindep_ss < kmixed_ss ) {
        // X' X -> XX, then XX^-1
        gf_regress_linalg_dsymm_wcolmajor_ix (xptr, xptr, XX, w, colix_ss, N, kindep_ss);
        gf_regress_linalg_dsysv (XX, kindep_ss, &singular);

        // Second stage coefficients
        gf_regress_linalg_dgemTv_wcolmajor_ix1 (xptr, y, BZ, w, colix_ss, N, kindep_ss);
        gf_regress_linalg_dgemTv_colmajor (XX, BZ, b, kindep_ss, kindep_ss);
    }
    else {
        // X' X -> XX, then XX^-1
        gf_regress_linalg_dsymm_wcolmajor (xptr, xptr, XX, w, N, kindep_ss);
        gf_regress_linalg_dsysv (XX, kindep_ss, &singular);

        // Second stage coefficients
        gf_regress_linalg_dgemTv_wcolmajor (xptr, y, BZ, w, N, kindep_ss);
        gf_regress_linalg_dgemTv_colmajor (XX, BZ, b, kindep_ss, kindep_ss);
    }

    // Note that we need the ix version for the errors if collinearity
    // was detected in the endogenous _or_ exogenous variables, but not
    // within the instruments.

    if ( kindep_endog < kendog || kindep_exog < kexog ) {
        // Second stage errors
        gf_regress_linalg_iverror_ix (y, PZ, Xexog, b, e, colix, N, kendog, kindep_endog, kindep_exog);
    }
    else {
        // Second stage errors
        gf_regress_linalg_iverror (y, PZ, Xexog, b, e, N, kendog, kexog);
    }

    // singular = 1 denotes _any_ collinearity (as opposed to numerically
    // zero determinant with no collinearity detected).

    if ( kindep_fs < kx_fs || kindep_ss < kx_ss ) {
        singular = 1;
    }

    return (singular);
}

/*********************************************************************
 *                              Helpers                              *
 *********************************************************************/

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
    GT_size koffset,
    GT_size k1,
    GT_size k2)
{
    GT_size i, k = 0, kindep = k1 + k2;
    ST_double *aptr, *bptr, *cptr;
    memcpy(c, y, N * sizeof(ST_double));

    bptr = b;
    for (k = 0; k < k1; k++, bptr++) {
        aptr = A1 + colix[k] * N;
        cptr = c;
        for (i = 0; i < N; i++, aptr++, cptr++) {
            *cptr -= (*aptr) * (*bptr);
        }
    }

    for (k = k1; k < kindep; k++, bptr++) {
        aptr = A2 + (colix[k] - koffset) * N;
        cptr = c;
        for (i = 0; i < N; i++, aptr++, cptr++) {
            *cptr -= (*aptr) * (*bptr);
        }
    }
}

void gf_regress_linalg_ivcollinear_ix (
    GT_size *colix,
    GT_size kendog,
    GT_size kexog,
    GT_size kz)
{
    GT_size kx_ss        = kendog + kexog;
    GT_size kx_iv        = kendog + kexog + kz;
    GT_size kindep       = colix[kx_iv];
    GT_size k            = 0;
    GT_size kindep_endog = 0;
    GT_size kindep_exog  = 0;
    GT_size kindep_z     = 0;
    GT_size diff         = 0;

    while ( colix[k] < kendog && k <  kindep ) {
        if ( (colix[k] - k) > diff ) {
            diff++;
        }
        kindep_endog++;
        k++;
    }

    while ( colix[k] < kx_ss && k <  kindep ) {
        if ( (colix[k] - k) > diff ) {
            diff++;
        }
        kindep_exog++;
        k++;
    }

    while ( colix[k] < kx_iv && k <  kindep ) {
        if ( (colix[k] - k) > diff ) {
            diff++;
        }
        kindep_z++;
        k++;
    }

    colix[kx_iv + 1] = kindep_endog;
    colix[kx_iv + 2] = kindep_exog;
    colix[kx_iv + 3] = kindep_z;
    colix[kx_iv + 4] = kindep_exog + kindep_z;
    colix[kx_iv + 5] = kindep_endog + kindep_exog;
    colix[kx_iv + 6] = kindep_endog + kindep_exog + kindep_z;
}
