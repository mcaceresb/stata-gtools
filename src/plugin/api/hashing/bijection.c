void GtoolsHashCheckBijection (
    struct GtoolsHash *GtoolsHashInfo,
    GT_int  *maxs,
    GT_int  *mins,
    GT_bool *allMiss,
    GT_bool *anyMiss)
{

    if ( GtoolsHashInfo->allNumeric == 0 && GtoolsHashInfo->allInteger == 0 ) {
        GtoolsHashInfo->bijectOK = 0;
        return;
    }

    GT_size i, k, worst, range;
    ST_double z, *dblptr;

    GT_bool bijectOK = 1;

    ST_double *dmaxs = calloc(GtoolsHashInfo->kvars, sizeof *dmaxs);
    ST_double *dmins = calloc(GtoolsHashInfo->kvars, sizeof *dmins);

    // if ( dmaxs == NULL ) return (17902);
    // if ( dmins == NULL ) return (17902);

    for (k = 0; k < GtoolsHashInfo->kvars; k++) {
        allMiss[k] = anyMiss[k] = dmaxs[k] = maxs[k] = mins[k] = 0;
    }

    if ( GtoolsHashInfo->allInteger ) {

        // Check whether bijection is OK with all integers
        dblptr = (ST_double *) GtoolsHashInfo->x;
        for (i = 0; i < GtoolsHashInfo->nobs; i++) {
            for (k = 0; k < GtoolsHashInfo->kvars; k++, dblptr++) {
                z = *dblptr;
                if ( z > SV_missval ) {
                    bijectOK = 0;
                    goto exit;
                }
                else if ( z < SV_missval ) {
                    if ( allMiss[k] ) {
                        dmins[k] = z;
                        dmaxs[k] = z;
                        allMiss[k] = 0;
                    }
                    else {
                        if ( z < dmins[k] ) dmins[k] = z;
                        if ( z > dmaxs[k] ) dmaxs[k] = z;
                    }
                }
                else {
                    anyMiss[k] = 1;
                }
            }
        }
    }
    else if ( GtoolsHashInfo->allNumeric ) {

        // Check whether all doubles are integers
        dblptr = (ST_double *) GtoolsHashInfo->x;
        for (i = 0; i < GtoolsHashInfo->nobs; i++) {
            for (k = 0; k < GtoolsHashInfo->kvars; k++, dblptr++) {
                z = *dblptr;
                if ( (ceil(z) != z) || (z > SV_missval) ) {
                    bijectOK = 0;
                    goto exit;
                }
                else if ( z < SV_missval ) {
                    if ( allMiss[k] ) {
                        dmins[k] = z;
                        dmaxs[k] = z;
                        allMiss[k] = 0;
                    }
                    else {
                        if ( z < dmins[k] ) dmins[k] = z;
                        if ( z > dmaxs[k] ) dmaxs[k] = z;
                    }
                }
                else {
                    anyMiss[k] = 1;
                }
            }
        }
    }
    else {
        goto exit;
    }

    // Check bijection would not exceed integer limits
    if ( bijectOK ) {
        for (k = 0; k < GtoolsHashInfo->kvars; k++) {
            mins[k] = (GT_int) (dmins[k]);
            maxs[k] = (GT_int) (dmaxs[k] + anyMiss[k]);
        }

        range = 1;
        worst = maxs[0] - mins[0] + 1;
        for (k = 0; k < (GtoolsHashInfo->kvars - 1); k++) {
            if ( worst > (GTOOLS_BIJECTION_LIMIT / range)  ) {
                bijectOK = 0;
                goto exit;
            }
            else {
                worst *= range;
                range  = maxs[k + 1] - mins[k + 1] + 1;
            }
        }

        if ( worst > (GTOOLS_BIJECTION_LIMIT / range)  ) {
            bijectOK = 0;
            goto exit;
        }
    }

exit:
    free (dmaxs);
    free (dmins);

    GtoolsHashInfo->bijectOK = bijectOK;
}

void GtoolsHashBijection (
    struct GtoolsHash *GtoolsHashInfo,
    GT_int  *maxs,
    GT_int  *mins,
    GT_bool *allMiss,
    GT_bool *anyMiss)
{

    ST_double z, *dblptr;
    GT_size i, k, l;

    GT_size offset = 1;
    GT_size *offsets = calloc(GtoolsHashInfo->kvars, sizeof *offsets);

    offsets[0] = 0;
    for (k = 0; k < GtoolsHashInfo->kvars - 1; k++) {
        l = GtoolsHashInfo->kvars - (k + 1);
        offset *= (maxs[l] - mins[l] + 1);
        offsets[k + 1] = offset;
    }

    // Construct bijection to whole numbers (we index missing vaues to the
    // largest number plus 1 as a convention; note we set the maximum to
    // the actual max + 1 from Stata so the offsets are correct)
    //
    // NOTE(mauricio): Checking missing values by comparing to SV_missval is
    // not correct; it only works here because whenever there are extended
    // missing values, I use the spooky hash.

    dblptr = (ST_double *) GtoolsHashInfo->x;
    for (i = 0; i < GtoolsHashInfo->nobs; i++, dblptr += GtoolsHashInfo->kvars) {
        l = GtoolsHashInfo->kvars - (0 + 1);
        z = *(dblptr + l);
        if ( z == SV_missval ) {
            z = maxs[l];
        }

        if ( GtoolsHashInfo->invert[l] ) {
            GtoolsHashInfo->hash1[i] = (maxs[l] - (GT_int) z + 1);
        }
        else {
            GtoolsHashInfo->hash1[i] = ((GT_int) z - mins[l] + 1);
        }

        for (k = 1; k < GtoolsHashInfo->kvars; k++) {
            l = GtoolsHashInfo->kvars - (k + 1);
            z = *(dblptr + l);
            if ( z == SV_missval ) {
                z = maxs[l];
            }

            if ( GtoolsHashInfo->invert[l] ) {
                GtoolsHashInfo->hash1[i] += (maxs[l] - (GT_int) z) * offsets[k];
            }
            else {
                GtoolsHashInfo->hash1[i] += ((GT_int) z - mins[l]) * offsets[k];
            }
        }
    }

    free (offsets);
}
