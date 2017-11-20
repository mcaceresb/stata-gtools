GT_size gf_xtile_clean (
    ST_double *x,
    GT_size lsize,
    GT_bool dropmiss,
    GT_bool dedup)
{
    GT_size i, _lsize;
    GT_bool sortme, dedupcheck;

    if ( lsize > 1 ) {
        _lsize = lsize;
        sortme = 0;

        for (i = 1; i < lsize; i++) {
            if ( x[i] < x[i - 1] ) {
                sortme = 1;
                break;
            }
            else if ( x[i] == x[i - 1] ) {
                dedupcheck = 1;
            }
        }

        if ( sortme ) {
            quicksort_bsd (
                x,
                lsize,
                sizeof(x),
                xtileCompare,
                NULL
            );
            dedupcheck = 1;
            sortme     = 0;
        }

        if ( dedup & dedupcheck ) {
            _lsize = 0;
            if ( dropmiss ) {
                if ( SF_is_missing(x[0]) ) return (0);
                for (i = 1; i < lsize; i++) {
                    if ( SF_is_missing(x[i]) ) break;
                    else if ( x[_lsize] == x[i] ) continue;
                    x[++_lsize] = x[i];
                }
            }
            else {
                for (i = 1; i < lsize; i++) {
                    if ( x[_lsize] == x[i] ) continue;
                    x[++_lsize] = x[i];
                }
            }
            _lsize++;
        }
        else if ( dropmiss ) {
            for (i = 0; i < lsize; i++) {
                if ( SF_is_missing(x[i]) ) return (i);
            }
        }

        return (_lsize);
    }
    else if ( (lsize == 1) & dropmiss ) {
        if ( SF_is_missing(x[0]) ) return (0);
        return (lsize);
    }
    else {
        return (lsize);
    }
}
