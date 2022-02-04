void GtoolsGroupByHDFEUnweighted(
    struct GtoolsHash *GtoolsHashInfo,
    GT_size   khashes,
    ST_double *sources,
    ST_double *weights,
    ST_double *targets,
    GT_size   ktargets,
    ST_double tol)
{
    GT_bool update;
    GT_size i, j, k, l, m, start, nj, *ixptr;
    ST_double mean, diff, *srcptr, *trgptr;
    struct GtoolsHash *ghptr;

    update = 0;
    diff = 1;
    while ( diff > tol ) {
        ghptr = GtoolsHashInfo;
        for (l = 0; l < khashes; l++, ghptr++) {
            diff = 0;
            for (j = 0; j < ghptr->nlevels; j++) {
                start  = ghptr->info[j];
                nj     = ghptr->info[j + 1] - start;
                ixptr  = ghptr->index + start;
                srcptr = update? targets: sources;
                trgptr = targets;
                for (k = 0; k < ktargets; k++, srcptr += ghptr->nobs, trgptr += ghptr->nobs) {
                    mean = GtoolsStatsMean(srcptr, ixptr, nj);
                    diff = GTOOLS_PWMAX(diff, fabs(mean));
                    for (i = 0; i < nj; i++) {
                        m = ixptr[i];
                        trgptr[m] = srcptr[m] - mean;
                    }
                }
            }
            update = 1;
            // TODO: Delete; this was a bug. If you pass multiple
            // redundant levels it will stop the de-meaning prematurely.
            // if ( diff < tol ) break;
        }
    }
}

void GtoolsGroupByHDFEWeighted (
    struct GtoolsHash *GtoolsHashInfo,
    GT_size   khashes,
    ST_double *sources,
    ST_double *weights,
    ST_double *targets,
    GT_size   ktargets,
    ST_double tol)
{
    GT_bool update;
    GT_size i, j, k, l, m, start, nj, *ixptr;
    ST_double mean, diff, *srcptr, *trgptr;
    struct GtoolsHash *ghptr;

    update = 0;
    diff = 1;
    while ( diff > tol ) {
        ghptr = GtoolsHashInfo;
        for (l = 0; l < khashes; l++, ghptr++) {
            diff = 0;
            for (j = 0; j < ghptr->nlevels; j++) {
                start  = ghptr->info[j];
                nj     = ghptr->info[j + 1] - start;
                ixptr  = ghptr->index + start;
                srcptr = update? targets: sources;
                trgptr = targets;
                for (k = 0; k < ktargets; k++, srcptr += ghptr->nobs, trgptr += ghptr->nobs) {
                    mean = GtoolsStatsMeanWeighted(srcptr, weights, ixptr, nj);
                    diff = GTOOLS_PWMAX(diff, fabs(mean));
                    for (i = 0; i < nj; i++) {
                        m = ixptr[i];
                        trgptr[m] = srcptr[m] - mean;
                    }
                }
            }
            update = 1;
            // TODO: Delete; this was a bug. If you pass multiple
            // redundant levels it will stop the de-meaning prematurely.
            // if ( diff < tol ) break;
            if ( diff < tol ) break;
        }
    }
}

// void GtoolsGroupByHDFEWeighted (
//     struct GtoolsHash *GtoolsHashInfo,
//     GT_size   khashes,
//     ST_double *sources,
//     ST_double *weights,
//     ST_double *targets,
//     GT_size   ktargets,
//     ST_double tol)
// {
//     GT_size i, j, k, l, start, nj, *ixptr;
//     ST_double diff, *trgptr, *wptr;
//     struct GtoolsHash *ghptr;
//     memcpy(targets, sources, GtoolsHashInfo->nobs * ktargets * sizeof(ST_double));
// 
//     ST_double *wmeans = calloc(GtoolsHashInfo->nobs, sizeof *wmeans);
//     ST_double *wsums  = calloc(GtoolsHashInfo->nobs, sizeof *wmeans);
//     GT_size   *wx     = calloc(GtoolsHashInfo->nobs, sizeof *wx);
// 
//     diff = 1;
//     while ( diff > tol ) {
//         ghptr = GtoolsHashInfo;
//         for (l = 0; l < khashes; l++, ghptr++) {
//             diff = 0;
//             for (j = 0; j < ghptr->nlevels; j++) {
//                 start  = ghptr->info[j];
//                 nj     = ghptr->info[j + 1] - start;
//                 ixptr  = ghptr->index + start;
//                 for (i = 0; i < nj; i++) {
//                     wx[ixptr[i]] = j;
//                 }
//             }
//             for (k = 0; k < ktargets; k++) {
//                 wptr   = weights;
//                 trgptr = targets + k * ghptr->nobs;
//                 memset(wsums, '\0', ghptr->nlevels * sizeof(ST_double));
//                 memset(wx,    '\0', ghptr->nlevels * sizeof(ST_double));
//                 for (i = 0; i < ghptr->nobs; i++, wptr++, trgptr++) {
//                     wmeans[wx[i]] += (*wptr) * (*trgptr);
//                     wsums[wx[i]]  += (*wptr);
//                 }
//                 for (j = 0; j < ghptr->nlevels; j++) {
//                     wmeans[j] /= wsums[j];
//                 }
//                 trgptr = targets + k * ghptr->nobs;
//                 for (i = 0; i < ghptr->nobs; i++, trgptr++) {
//                     diff = GTOOLS_PWMAX(diff, fabs(wmeans[wx[i]]));
//                     *trgptr -= wmeans[wx[i]];
//                 }
//             }
//             if ( diff < tol ) break;
//         }
//     }
// 
//     free (wmeans);
//     free (wsums);
//     free (wx);
// }
