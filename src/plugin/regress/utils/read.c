ST_retcode sf_regress_read_colmajor (
    struct StataInfo *st_info,
    ST_double *y,
    ST_double *X,
    ST_double *w,
    void      *G,
    void      *FE,
    ST_double *I,
    GT_size   *nj)
{

    ST_retcode rc = 0;
    ST_double *xptr;
    GT_size i, j, k, l, start, end, nobs, offset_buffer, *stptr;

    GT_bool interval  = st_info->gregress_range;
    GT_size kref      = 0;
    GT_size kclus     = st_info->gregress_cluster;
    GT_size kabs      = st_info->gregress_absorb;
    GT_int  *clustyp  = st_info->gregress_cluster_types;
    GT_int  *abstyp   = st_info->gregress_absorb_types;
    GT_size *clusoff  = st_info->gregress_cluster_offsets;
    GT_size *absoff   = st_info->gregress_absorb_offsets;
    GT_size bytesclus = st_info->gregress_cluster_bytes;
    GT_size kv        = st_info->gregress_kvars - 1;
    GT_size kx        = kv + (kabs == 0) * st_info->gregress_cons;
    GT_bool skip      = (kabs == 0) * st_info->gregress_cons;
    GT_size kz        = st_info->gregress_ivkz;

    GT_size *index_st = calloc(st_info->Nread, sizeof *index_st);
    if ( index_st == NULL ) return(sf_oom_error("sf_regress_read_colmajor", "index_st"));

    for (i = 0; i < st_info->Nread; i++) {
        index_st[i] = 0;
    }

    for (j = 0; j < st_info->J; j++) {
        nj[j] = 0;
    }

    for (j = 0; j < st_info->J; j++) {
        l      = st_info->ix[j];
        start  = st_info->info[l];
        end    = st_info->info[l + 1];
        for (i = start; i < end; i++) {
            index_st[st_info->index[i]] = l + 1;
        }
    }

    // Read Stata in order and place into C in column major order.
    // There should be no missing values bc we always use `touse' from
    // Stata for no missing values row-wise, including the weight.
    //
    // Since we hash cluster jointly, it is always read by
    // row. Similarly, since we hash absorb sepparately, it is always
    // read in coumn order w/o grouping them.

    i = 0;
    if ( st_info->wcode > 0 ) {
        if ( kclus || kabs || interval ) {
            for (stptr = index_st; stptr < index_st + st_info->Nread; stptr++, i++) {
                if ( *stptr ) {
                    j     = *stptr - 1;
                    start = st_info->info[j];
                    end   = st_info->info[j + 1];
                    nobs  = end - start;
                    kref  = st_info->kvars_by + 1;

                    if ( (rc = SF_vdata(kref,
                                        i + st_info->in1,
                                        y + start + nj[j])) ) goto exit;

                    kref += 1;
                    offset_buffer = start * kx;
                    for (k = 0; k < kv - kz; k++) {
                        if ( (rc = SF_vdata(kref + k,
                                            i + st_info->in1,
                                            X + offset_buffer + nj[j])) ) goto exit;
                        offset_buffer += nobs;
                    }

                    // If any IV, read them at the end; blank "middle" col will be _cons
                    kref += (kv - kz);
                    if ( skip ) {
                        offset_buffer += nobs;
                    }
                    for (k = 0; k < kz; k++) {
                        if ( (rc = SF_vdata(kref + k,
                                            i + st_info->in1,
                                            X + offset_buffer + nj[j])) ) goto exit;
                        offset_buffer += nobs;
                    }

                    kref += kz;
                    offset_buffer = (start + nj[j]) * bytesclus;
                    for (k = 0; k < kclus; k++) {
                        if ( clustyp[k] > 0 ) {
                            if ( (rc = SF_sdata(kref + k,
                                                i + st_info->in1,
                                                (char *) (G + offset_buffer))) ) goto exit;
                        }
                        else {
                            if ( (rc = SF_vdata(kref + k,
                                                i + st_info->in1,
                                                (ST_double *) (G + offset_buffer))) ) goto exit;
                        }
                        offset_buffer += clusoff[k];
                    }

                    kref += kclus;
                    offset_buffer = 0;
                    for (k = 0; k < kabs; k++) {
                        offset_buffer += (start + nj[j]) * absoff[k];
                        if ( abstyp[k] > 0 ) {
                            if ( (rc = SF_sdata(kref + k,
                                                i + st_info->in1,
                                                (char *) (FE + offset_buffer))) ) goto exit;
                        }
                        else {
                            if ( (rc = SF_vdata(kref + k,
                                                i + st_info->in1,
                                                (ST_double *) (FE + offset_buffer))) ) goto exit;
                        }
                        offset_buffer += (st_info->N - start - nj[j]) * absoff[k];
                    }

                    if ( interval ) {
                        kref += kabs;
                        if ( (rc = SF_vdata(kref,
                                            i + st_info->in1,
                                            I + start + nj[j])) ) goto exit;
                    }

                    if ( (rc = SF_vdata(st_info->wpos,
                                        i + st_info->in1,
                                        w + start + nj[j])) ) goto exit;

                    nj[j]++;
                }
            }
        }
        else {
            for (stptr = index_st; stptr < index_st + st_info->Nread; stptr++, i++) {
                if ( *stptr ) {
                    j     = *stptr - 1;
                    start = st_info->info[j];
                    end   = st_info->info[j + 1];
                    nobs  = end - start;
                    kref  = st_info->kvars_by + 1;

                    if ( (rc = SF_vdata(kref,
                                        i + st_info->in1,
                                        y + start + nj[j])) ) goto exit;

                    kref += 1;
                    offset_buffer = start * kx;
                    for (k = 0; k < kv - kz; k++) {
                        if ( (rc = SF_vdata(kref + k,
                                            i + st_info->in1,
                                            X + offset_buffer + nj[j])) ) goto exit;
                        offset_buffer += nobs;
                    }

                    // If any IV, read them at the end; blank "middle" col will be _cons
                    kref += (kv - kz);
                    if ( skip ) {
                        offset_buffer += nobs;
                    }
                    for (k = 0; k < kz; k++) {
                        if ( (rc = SF_vdata(kref + k,
                                            i + st_info->in1,
                                            X + offset_buffer + nj[j])) ) goto exit;
                        offset_buffer += nobs;
                    }

                    if ( (rc = SF_vdata(st_info->wpos,
                                        i + st_info->in1,
                                        w + start + nj[j])) ) goto exit;

                    nj[j]++;
                }
            }
        }
    }
    else {
        if ( kclus || kabs || interval ) {
            for (stptr = index_st; stptr < index_st + st_info->Nread; stptr++, i++) {
                if ( *stptr ) {
                    j     = *stptr - 1;
                    start = st_info->info[j];
                    end   = st_info->info[j + 1];
                    nobs  = end - start;
                    kref  = st_info->kvars_by + 1;

                    if ( (rc = SF_vdata(kref,
                                        i + st_info->in1,
                                        y + start + nj[j])) ) goto exit;

                    kref += 1;
                    offset_buffer = start * kx;
                    for (k = 0; k < kv - kz; k++) {
                        if ( (rc = SF_vdata(kref + k,
                                            i + st_info->in1,
                                            X + offset_buffer + nj[j])) ) goto exit;
                        offset_buffer += nobs;
                    }

                    // If any IV, read them at the end; blank "middle" col will be _cons
                    kref += (kv - kz);
                    if ( skip ) {
                        offset_buffer += nobs;
                    }
                    for (k = 0; k < kz; k++) {
                        if ( (rc = SF_vdata(kref + k,
                                            i + st_info->in1,
                                            X + offset_buffer + nj[j])) ) goto exit;
                        offset_buffer += nobs;
                    }

                    kref += kz;
                    offset_buffer = (start + nj[j]) * bytesclus;
                    for (k = 0; k < kclus; k++) {
                        if ( clustyp[k] > 0 ) {
                            if ( (rc = SF_sdata(kref + k,
                                                i + st_info->in1,
                                                (char *) (G + offset_buffer))) ) goto exit;
                        }
                        else {
                            if ( (rc = SF_vdata(kref + k,
                                                i + st_info->in1,
                                                (ST_double *) (G + offset_buffer))) ) goto exit;
                        }
                        offset_buffer += clusoff[k];
                    }

                    kref += kclus;
                    offset_buffer = 0;
                    for (k = 0; k < kabs; k++) {
                        offset_buffer += (start + nj[j]) * absoff[k];
                        if ( abstyp[k] > 0 ) {
                            if ( (rc = SF_sdata(kref + k,
                                                i + st_info->in1,
                                                (char *) (FE + offset_buffer))) ) goto exit;
                        }
                        else {
                            if ( (rc = SF_vdata(kref + k,
                                                i + st_info->in1,
                                                (ST_double *) (FE + offset_buffer))) ) goto exit;
                        }
                        offset_buffer += (st_info->N - start - nj[j]) * absoff[k];
                    }

                    if ( interval ) {
                        kref += kabs;
                        if ( (rc = SF_vdata(kref,
                                            i + st_info->in1,
                                            I + start + nj[j])) ) goto exit;
                    }

                    nj[j]++;
                }
            }
        }
        else {
            for (stptr = index_st; stptr < index_st + st_info->Nread; stptr++, i++) {
                if ( *stptr ) {
                    j     = *stptr - 1;
                    start = st_info->info[j];
                    end   = st_info->info[j + 1];
                    nobs  = end - start;
                    kref  = st_info->kvars_by + 1;

                    if ( (rc = SF_vdata(kref,
                                        i + st_info->in1,
                                        y + start + nj[j])) ) goto exit;

                    kref += 1;
                    offset_buffer = start * kx;
                    for (k = 0; k < kv - kz; k++) {
                        if ( (rc = SF_vdata(kref + k,
                                            i + st_info->in1,
                                            X + offset_buffer + nj[j])) ) goto exit;
                        offset_buffer += nobs;
                    }

                    // If any IV, read them at the end; blank "middle" col will be _cons
                    kref += (kv - kz);
                    if ( skip ) {
                        offset_buffer += nobs;
                    }
                    for (k = 0; k < kz; k++) {
                        if ( (rc = SF_vdata(kref + k,
                                            i + st_info->in1,
                                            X + offset_buffer + nj[j])) ) goto exit;
                        offset_buffer += nobs;
                    }

                    nj[j]++;
                }
            }
        }
    }
    // If IV, we copy X = [Xendog Xexog 1 Z]
    if ( st_info->gregress_cons && (kabs == 0) ) {
        xptr = X;
        offset_buffer = kv - kz;
        for (j = 0; j < st_info->J; j++) {
            xptr += nj[j] * offset_buffer;
            for (i = 0; i < nj[j]; i++, xptr++) {
                *xptr = 1;
            }
            xptr += nj[j] * kz;
        }
    }

exit:
    free(index_st);

    return (rc);
}

ST_retcode sf_regress_read_rowmajor (
    struct StataInfo *st_info,
    ST_double *y,
    ST_double *X,
    ST_double *w,
    void      *G,
    void      *FE,
    ST_double *I,
    GT_size   *nj)
{

    ST_retcode rc = 0;
    ST_double *xptr;
    GT_size i, j, k, l, start, end, offset_buffer, *stptr;

    GT_bool interval  = st_info->gregress_range;
    GT_size kref      = 0;
    GT_size kclus     = st_info->gregress_cluster;
    GT_size kabs      = st_info->gregress_absorb;
    GT_int  *clustyp  = st_info->gregress_cluster_types;
    GT_int  *abstyp   = st_info->gregress_absorb_types;
    GT_size *clusoff  = st_info->gregress_cluster_offsets;
    GT_size *absoff   = st_info->gregress_absorb_offsets;
    GT_size bytesclus = st_info->gregress_cluster_bytes;
    GT_size kv        = st_info->gregress_kvars - 1;
    GT_size kx        = kv + (kabs == 0) * st_info->gregress_cons;

    GT_size *index_st = calloc(st_info->Nread, sizeof *index_st);
    if ( index_st == NULL ) return(sf_oom_error("sf_regress_read_rowmajor", "index_st"));

    for (i = 0; i < st_info->Nread; i++) {
        index_st[i] = 0;
    }

    for (j = 0; j < st_info->J; j++) {
        nj[j] = 0;
    }

    for (j = 0; j < st_info->J; j++) {
        l      = st_info->ix[j];
        start  = st_info->info[l];
        end    = st_info->info[l + 1];
        for (i = start; i < end; i++) {
            index_st[st_info->index[i]] = l + 1;
        }
    }

    // Read Stata in order and place into C in row major order.  There
    // should be no missing values bc we always use `touse' from Stata
    // for no missing values row-wise, including the weight.
    //
    // Since we hash cluster jointly, it is always read by
    // row. Similarly, since we hash absorb sepparately, it is always
    // read in coumn order w/o grouping them.

    i = 0;
    if ( st_info->wcode > 0 ) {
        if ( kclus || kabs || interval ) {
            for (stptr = index_st; stptr < index_st + st_info->Nread; stptr++, i++) {
                if ( *stptr ) {
                    j     = *stptr - 1;
                    start = st_info->info[j];
                    end   = st_info->info[j + 1];
                    kref  = st_info->kvars_by + 1;

                    if ( (rc = SF_vdata(kref,
                                        i + st_info->in1,
                                        y + start + nj[j])) ) goto exit;

                    kref += 1;
                    offset_buffer = (start + nj[j]) * kx;
                    for (k = 0; k < kv; k++) {
                        if ( (rc = SF_vdata(kref + k,
                                            i + st_info->in1,
                                            X + offset_buffer++)) ) goto exit;
                    }

                    kref += kv;
                    offset_buffer = (start + nj[j]) * bytesclus;
                    for (k = 0; k < kclus; k++) {
                        if ( clustyp[k] > 0 ) {
                            if ( (rc = SF_sdata(kref + k,
                                                i + st_info->in1,
                                                (char *) (G + offset_buffer))) ) goto exit;
                        }
                        else {
                            if ( (rc = SF_vdata(kref + k,
                                                i + st_info->in1,
                                                (ST_double *) (G + offset_buffer))) ) goto exit;
                        }
                        offset_buffer += clusoff[k];
                    }

                    kref += kclus;
                    offset_buffer = 0;
                    for (k = 0; k < kabs; k++) {
                        offset_buffer += (start + nj[j]) * absoff[k];
                        if ( abstyp[k] > 0 ) {
                            if ( (rc = SF_sdata(kref + k,
                                                i + st_info->in1,
                                                (char *) (FE + offset_buffer))) ) goto exit;
                        }
                        else {
                            if ( (rc = SF_vdata(kref + k,
                                                i + st_info->in1,
                                                (ST_double *) (FE + offset_buffer))) ) goto exit;
                        }
                        offset_buffer += (st_info->N - start - nj[j]) * absoff[k];
                    }

                    if ( interval ) {
                        kref += kabs;
                        if ( (rc = SF_vdata(kref,
                                            i + st_info->in1,
                                            I + start + nj[j])) ) goto exit;
                    }

                    if ( (rc = SF_vdata(st_info->wpos,
                                        i + st_info->in1,
                                        w + start + nj[j])) ) goto exit;

                    nj[j]++;
                }
            }
        }
        else {
            for (stptr = index_st; stptr < index_st + st_info->Nread; stptr++, i++) {
                if ( *stptr ) {
                    j     = *stptr - 1;
                    start = st_info->info[j];
                    end   = st_info->info[j + 1];
                    kref  = st_info->kvars_by + 1;

                    if ( (rc = SF_vdata(kref,
                                        i + st_info->in1,
                                        y + start + nj[j])) ) goto exit;

                    kref += 1;
                    offset_buffer = (start + nj[j]) * kx;
                    for (k = 0; k < kv; k++) {
                        if ( (rc = SF_vdata(kref + k,
                                            i + st_info->in1,
                                            X + offset_buffer++)) ) goto exit;
                    }

                    if ( (rc = SF_vdata(st_info->wpos,
                                        i + st_info->in1,
                                        w + start + nj[j])) ) goto exit;

                    nj[j]++;
                }
            }
        }
    }
    else {
        if ( kclus || kabs || interval ) {
            for (stptr = index_st; stptr < index_st + st_info->Nread; stptr++, i++) {
                if ( *stptr ) {
                    j     = *stptr - 1;
                    start = st_info->info[j];
                    end   = st_info->info[j + 1];
                    kref  = st_info->kvars_by + 1;

                    if ( (rc = SF_vdata(kref,
                                        i + st_info->in1,
                                        y + start + nj[j])) ) goto exit;

                    kref += 1;
                    offset_buffer = (start + nj[j]) * kx;
                    for (k = 0; k < kv; k++) {
                        if ( (rc = SF_vdata(kref + k,
                                            i + st_info->in1,
                                            X + offset_buffer++)) ) goto exit;
                    }

                    kref += kv;
                    offset_buffer = (start + nj[j]) * bytesclus;
                    for (k = 0; k < kclus; k++) {
                        if ( clustyp[k] > 0 ) {
                            if ( (rc = SF_sdata(kref + k,
                                                i + st_info->in1,
                                                (char *) (G + offset_buffer))) ) goto exit;
                        }
                        else {
                            if ( (rc = SF_vdata(kref + k,
                                                i + st_info->in1,
                                                (ST_double *) (G + offset_buffer))) ) goto exit;
                        }
                        offset_buffer += clusoff[k];
                    }

                    kref += kclus;
                    offset_buffer = 0;
                    for (k = 0; k < kabs; k++) {
                        offset_buffer += (start + nj[j]) * absoff[k];
                        if ( abstyp[k] > 0 ) {
                            if ( (rc = SF_sdata(kref + k,
                                                i + st_info->in1,
                                                (char *) (FE + offset_buffer))) ) goto exit;
                        }
                        else {
                            if ( (rc = SF_vdata(kref + k,
                                                i + st_info->in1,
                                                (ST_double *) (FE + offset_buffer))) ) goto exit;
                        }
                        offset_buffer += (st_info->N - start - nj[j]) * absoff[k];
                    }

                    if ( interval ) {
                        kref += kabs;
                        if ( (rc = SF_vdata(kref,
                                            i + st_info->in1,
                                            I + start + nj[j])) ) goto exit;
                    }

                    nj[j]++;
                }
            }
        }
        else {
            for (stptr = index_st; stptr < index_st + st_info->Nread; stptr++, i++) {
                if ( *stptr ) {
                    j     = *stptr - 1;
                    start = st_info->info[j];
                    end   = st_info->info[j + 1];
                    kref  = st_info->kvars_by + 1;

                    if ( (rc = SF_vdata(kref,
                                        i + st_info->in1,
                                        y + start + nj[j])) ) goto exit;

                    kref += 1;
                    offset_buffer = (start + nj[j]) * kx;
                    for (k = 0; k < kv; k++) {
                        if ( (rc = SF_vdata(kref + k,
                                            i + st_info->in1,
                                            X + offset_buffer++)) ) goto exit;
                    }

                    nj[j]++;
                }
            }
        }
    }

    if ( st_info->gregress_cons && (kabs == 0) ) {
        for (xptr = X + kv; xptr < X + st_info->N * kx; xptr += kx) {
            *xptr = 1;
        }
    }

exit:
    free(index_st);

    return (rc);
}
