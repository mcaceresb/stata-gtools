GT_int GtoolsHashSort (struct GtoolsHash *GtoolsHashInfo)
{
    if ( GtoolsHashInfo->max1 < 65536 ) {
        if ( gf_radix_sort8_16  (GtoolsHashInfo->h1ptr, GtoolsHashInfo->index, GtoolsHashInfo->nobs) ) return (17902);
    }
    else if ( GtoolsHashInfo->max1 < 16777216 ) {
        if ( gf_radix_sort12_24 (GtoolsHashInfo->h1ptr, GtoolsHashInfo->index, GtoolsHashInfo->nobs) ) return (17902);
    }
    else if ( GtoolsHashInfo->max1 < 4294967296 ) {
        if ( gf_radix_sort16_32 (GtoolsHashInfo->h1ptr, GtoolsHashInfo->index, GtoolsHashInfo->nobs) ) return (17902);
    }
    else {
        if ( gf_radix_sort16    (GtoolsHashInfo->h1ptr, GtoolsHashInfo->index, GtoolsHashInfo->nobs) ) return (17902);
    }
    return (0);
}

GT_int GtoolsHashPanelBijection (struct GtoolsHash *GtoolsHashInfo)
{
    GT_size i = 0;
    GT_size l = 0;
    uint64_t el = GtoolsHashInfo->h1ptr[i++];

    GT_size *info_largest = calloc(GtoolsHashInfo->nobs + 1, sizeof *info_largest);
    if ( info_largest == NULL ) return (17902);

    info_largest[l++] = 0;
    if ( GtoolsHashInfo->nobs > 1 ) {
        do {
            if (GtoolsHashInfo->h1ptr[i] != el) {
                info_largest[l++] = i;
                el  = GtoolsHashInfo->h1ptr[i];
            }
            i++;
        } while( i < GtoolsHashInfo->nobs );
    }
    info_largest[l] = GtoolsHashInfo->nobs;
    GtoolsHashInfo->nlevels = l;

    GtoolsHashInfo->info = calloc(l + 1, sizeof GtoolsHashInfo->info);
    if ( GtoolsHashInfo->info == NULL ) return (17902);
    GtoolsHashInfo->allocInfo = 1;

    for (i = 0; i < l + 1; i++)
        GtoolsHashInfo->info[i] = info_largest[i];

    free (info_largest);
    return (0);
}

GT_int GtoolsHashPanel128 (struct GtoolsHash *GtoolsHashInfo)
{

    GT_int rc  = 0;
    GT_size i  = 0;
    GT_size i2 = 0;
    GT_size l  = 0;
    GT_size start_l;
    GT_size range_l;

    uint64_t el = GtoolsHashInfo->h1ptr[i++];
    uint64_t el2;

    GT_size  *ix_l;
    uint64_t *h2_l;

    GT_size *info_largest = calloc(GtoolsHashInfo->nobs + 1, sizeof *info_largest);
    if ( info_largest == NULL ) return (17902);

    info_largest[l++] = 0;
    if ( GtoolsHashInfo->nobs > 1 ) {
        do {
            if ( GtoolsHashInfo->h1ptr[i] != el ) {

                // The 128-bit hash is stored in 2 64-bit parts; almost
                // surely sorting by one of them is sufficient, but in case
                // it is not, sort by the other, and that should be enough.
                //
                // Sorting by both keys all the time is time-consuming,
                // whereas sorting by only one key is fast. Since we only
                // expect about 1 collision every 4 billion groups, it
                // should be very rare to have to use both keys. (Stata caps
                // observations at 20 billion anyway, and there's one hash
                // per *group*, not row).
                //
                // Still, if the 64-bit hashes are not enough, use the full
                // 128-bit hashes, wehere we don't expect a collision until
                // we have 16 quintillion groups in our data.
                //
                // See burtleburtle.net/bob/hash/spooky.html for details.

                if ( !GtoolsHashCheckEqual(GtoolsHashInfo->h2ptr + info_largest[l - 1], i) ) {
                    start_l = info_largest[l - 1];
                    range_l = i - start_l;

                    ix_l = GtoolsHashInfo->index + start_l;
                    h2_l = GtoolsHashInfo->h2ptr + start_l;

                    if ( (rc = gf_radix_sort16 (h2_l, ix_l, range_l)) ) goto exit;

                    // Now that the hash and index are sorted, add to
                    // info_largest based on h2_l
                    el2 = h2_l[i2++];
                    while ( i2 < range_l ) {
                        if ( h2_l[i2] != el2 ) {
                            info_largest[l++] = start_l + i2;
                            el2 = h2_l[i2];
                        }
                        i2++;
                    }
                    i2 = 0;
                }

                info_largest[l++] = i;
                el = GtoolsHashInfo->h1ptr[i];
            }
            i++;
        } while( i < GtoolsHashInfo->nobs );
    }
    info_largest[l] = GtoolsHashInfo->nobs;
    GtoolsHashInfo->nlevels = l;

    GtoolsHashInfo->info = calloc(l + 1, sizeof GtoolsHashInfo->info);
    if ( GtoolsHashInfo->info == NULL ) return (17902);
    GtoolsHashInfo->allocInfo = 1;

    for (i = 0; i < l + 1; i++)
        GtoolsHashInfo->info[i] = info_largest[i];

exit:
    free (info_largest);
    return (rc);
}

GT_int GtoolsHashPanelSorted (struct GtoolsHash *GtoolsHashInfo)
{
    GT_size i;

    GT_size *info_largest = calloc(GtoolsHashInfo->nobs + 1, sizeof *info_largest);
    if ( info_largest == NULL ) return (17902);

    if ( GtoolsHashInfo->allNumeric ) {
        GtoolsHashInfo->nlevels = MultiSortPanelSetupDbl (
            (ST_double *) GtoolsHashInfo->xptr,
            GtoolsHashInfo->nobs,
            0,
            GtoolsHashInfo->kvars - 1,
            GtoolsHashInfo->rowbytes,
            (GT_size *) GtoolsHashInfo->invert,
            info_largest,
            0
        );
    }
    else {
        GtoolsHashInfo->nlevels = MultiSortPanelSetupMC (
            (char *) GtoolsHashInfo->xptr,
            GtoolsHashInfo->nobs,
            0,
            GtoolsHashInfo->kvars - 1,
            GtoolsHashInfo->rowbytes,
            GtoolsHashInfo->sizes,
            (GT_size *) GtoolsHashInfo->invert,
            GtoolsHashInfo->positions,
            info_largest,
            0
        );
    }
    info_largest[GtoolsHashInfo->nlevels] = GtoolsHashInfo->nobs;

    GtoolsHashInfo->info = calloc(GtoolsHashInfo->nlevels + 1, sizeof GtoolsHashInfo->info);
    if ( GtoolsHashInfo->info == NULL ) return (17902);
    GtoolsHashInfo->allocInfo = 1;

    for (i = 0; i < GtoolsHashInfo->nlevels + 1; i++)
        GtoolsHashInfo->info[i] = info_largest[i];

    free(info_largest);
    return (0);
}
