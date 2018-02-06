ST_retcode gf_array_nunique_range (
    ST_double *output,
    void *x,
    const GT_size N,
    const GT_bool hmethod,
    uint64_t *h1,
    uint64_t *h2,
    uint64_t *h3,
    uint64_t *ix,
    uint64_t *xcopy
);

ST_retcode gf_counting_sort_noix (
    uint64_t *hash, GT_size N,
    uint64_t range,
    uint64_t *xcopy
);

ST_retcode gf_array_nunique_range (
    ST_double *output,
    void *x,
    const GT_size N,
    const GT_bool hmethod,
    uint64_t *h1,
    uint64_t *h2,
    uint64_t *h3,
    uint64_t *ix,
    uint64_t *xcopy)
{
    spookyhash_context context;
    ST_double *v = (ST_double *) x;

    GT_size nunique = 1;
    GT_size ctol    = pow(2, 24);

    GT_bool biject, anymiss, allmiss, rsort;
    GT_size i, j, range, npos;
    ST_double min = 0, max = 0;

    ST_double z;
    ST_retcode rc;

    GT_bool sorted = gf_array_dsorted_range(v, 0, N);

    if ( hmethod || sorted ) {
        biject  = 0;
        anymiss = 1;
        allmiss = 1;
    }
    else {
        biject  = 1;
        anymiss = 0;
        allmiss = 1;
    }

    if ( biject ) {
        for (i = 0; i < N; i++) {
            z = v[i];
            if ( (ceil(z) != z) || (z > SV_missval) ) {
                biject = 0;
                break;
            }
            else if ( z < SV_missval ) {
                if ( allmiss ) {
                    min = z;
                    max = z;
                    allmiss = 0;
                }
                else {
                    if ( z < min ) min = z;
                    if ( z > max ) max = z;
                }
            }
            else {
                // All missing should be handled in the call (i.e. all
                // missing forces spooky hash)
                anymiss = 1;
            }
        }
    }

    if ( sorted ) {
        rsort = 3;
    }
    else {
        if ( biject ) {
            range = ((GT_int) max - (GT_int) min + anymiss + 1);
            rsort = range < ctol? 0: 1;
            for (i = 0; i < N; i++) {
                if ( (z = v[i]) == SV_missval ) z = max + 1;
                h1[i] = ((GT_int) z - min);
            }
        }
        else {
            rsort = 2;
            for (i = 0; i < N; i++) {
                // spookyhash_128(v + i, sizeof(ST_double), h1 + i, h2 + i);
                spookyhash_context_init(&context, 0, 1);
                spookyhash_update(&context, v + i, sizeof(ST_double));
                spookyhash_final(&context, h1 + i, h2 + i);
            }
        }

        if ( rsort ) {
            // This has to be indexed because of h2
            for (i = 0; i < N; i++)
                ix[i] = i;

            if ( (rc = gf_radix_sort16 (h1, ix, N)) ) return (rc);

            for (i = 0; i < N; i++)
                h3[i] = h2[ix[i]];

        }
        else {
            if ( (rc = gf_counting_sort_noix (h1, N, range, xcopy)) ) return(rc);
        }
        sorted = 1;
    }

    if ( (rsort == 0) || (rsort == 1) ) {
        npos = 0;
        for (i = 1; i < N; i++) {
            if ( h1[npos] == h1[i] ) continue;
            npos = i;
            nunique++;
        }
    }
    else if ( rsort == 2 ) {
        // Unique count using h1, h3, ix
        npos = 0;
        for (i = 1; i < N; i++) {
            if ( h1[npos] == h1[i] ) continue;

            if ( i > npos + 1 ) {
                for (j = npos + 1; j < i; j++) {
                    if ( h3[npos] != h3[j] ) break;
                }

                if ( j < i ) {
                    if ( (rc = gf_radix_sort16 (h3, ix, i - npos)) ) return (rc);
                    for (j = npos + 1; j < i; j++) {
                        if ( h3[npos] == h3[j] ) {
                            if ( v[ix[npos]] != v[ix[j]] ) return (17999);
                            continue;
                        }
                        npos = j;
                        nunique++;
                    }
                }
                else {
                    for (j = npos + 1; j < i; j++) {
                        if ( v[ix[npos]] != v[ix[j]] ) return (17999);
                    }
                }
            }

            npos = i;
            nunique++;
        }
    }
    else if ( rsort == 3 ) {
        npos = 0;
        for (i = 1; i < N; i++) {
            if ( v[npos] == v[i] ) continue;
            npos = i;
            nunique++;
        }
    }

    *output = ((ST_double) nunique);

    return (0);
}

// Assumes normalized array (i.e. each element - min)
ST_retcode gf_counting_sort_noix (uint64_t *hash, GT_size N, uint64_t range, uint64_t *xcopy)
{

    GT_size *count = calloc(range + 1, sizeof *count);
    if ( count == NULL ) return(sf_oom_error("gf_counting_sort_noix", "count"));

    uint64_t *xptr;
    uint64_t *hptr;
    GT_size *cptr;

    // Initialize count as 0s
    for (cptr = count; cptr < count + range + 1; cptr++)
        *cptr = 0;

    // Freq count of hash
    xptr = xcopy;
    for (hptr  = hash; hptr < hash + N; hptr++, xptr++)
        count[ *xptr = (*hptr + 1) ]++;

    // Cummulative freq count (position in output)
    for (cptr = count + 1; cptr < count + range; cptr++)
        *cptr += *(cptr - 1);

    // Copy back in stable sorted order
    xptr = xcopy;
    for (hptr = hash; hptr < hash + N; hptr++, xptr++) {
        hash[count[*xptr - 1]++] = *xptr - 1;
    }

    // Free space
    free (count);

    return (0);
}
