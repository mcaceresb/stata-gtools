#include "hashsort.h"

int sf_hashsort(struct StataInfo *st_info)
{
    // Setup
    // -----

    int i, j, k, out, start, end;
    size_t N     = st_info->N;
    size_t J     = st_info->J;
    size_t in1   = st_info->in1;
    size_t ksort = st_info->kvars_by;
    size_t kvars = st_info->kvars_by + 1;

    // Variable lengths; 0 are double, > 0 are string lengths
    int *ltypes = calloc(ksort, sizeof(*ltypes));
    if ( ltypes == NULL ) return (sf_oom_error("sf_hashsort", "ltypes"));

    int ilen;
    size_t rowbytes = 0;
    for (k = 0; k < ksort; k++) {
        ilen = st_info->byvars_lens[k];
        if ( ilen > 0 ) {
            ltypes[k] = ilen;
            rowbytes += ((ltypes[k] + 1) * sizeof(char));
        }
        else {
            ltypes[k] = 0;
            rowbytes += sizeof(double);
        }
    }
    rowbytes += sizeof(int);

    /*********************************************************************
     *                          Allocate space                           *
     *********************************************************************/

    ST_retcode rc ;
    ST_double z ;
    int sel;
    clock_t timer = clock();

    /*********************************************************************
     *                         Read in the data                          *
     *********************************************************************/

    if ( st_info->integers_ok ) {

        // Integers are bijected to the natural numbers
        // --------------------------------------------

        size_t *st_bijection = calloc(N, sizeof(*st_bijection));
        size_t *st_index     = calloc(N, sizeof(*st_index));
        if ( st_bijection == NULL ) return (sf_oom_error("sf_hashsort", "st_bijection"));
        if ( st_index     == NULL ) return (sf_oom_error("sf_hashsort", "st_index"));

        int l;
        size_t offset = 1;
        size_t offsets[ksort];
        offsets[0] = 0;
        for (k = 0; k < ksort - 1; k++) {
            l = ksort - (k + 1);
            offset *= (st_info->byvars_maxs[l] - st_info->byvars_mins[l] + 1);
            offsets[k + 1] = offset;
        }

        // Read in the sort variables, which we know are integers
        for (i = 0; i < N; i++) {

            // If only one variable, it will just get adjusted by its range
            l = ksort - (0 + 1);
            if ( (rc = SF_vdata(1 + l, i + in1, &z)) ) return(rc);
            if ( st_info->invert[l] ) {
                if ( SF_is_missing(z) )
                    st_bijection[i] = 1;
                else
                    st_bijection[i] = st_info->byvars_maxs[l] - z + 1;
            }
            else {
                if ( SF_is_missing(z) )
                    st_bijection[i] = st_info->byvars_maxs[l] - st_info->byvars_mins[l] + 1;
                else
                    st_bijection[i] = z - st_info->byvars_mins[l] + 1;
            }

            // If multiple integers, they'll get mapped recursively
            for (k = 1; k < ksort; k++) {
                l   = ksort - (k + 1);
                if ( (rc = SF_vdata(1 + l, i + in1, &z)) ) return(rc);
                if ( st_info->invert[l] ) {
                    if ( SF_is_missing(z) )
                        st_bijection[i] += 0;
                    else
                        st_bijection[i] += (st_info->byvars_maxs[l] - z) * offsets[k];
                }
                else {
                    if ( SF_is_missing(z) )
                        st_bijection[i] += (st_info->byvars_maxs[l] - st_info->byvars_mins[l]) * offsets[k];
                    else
                        st_bijection[i] += (z - st_info->byvars_mins[l]) * offsets[k];
                }
            }
        }
        if ( st_info->benchmark ) sf_running_timer (&timer, "\tPlugin step (2): Bijected sort integers to natural numbers");

        // Radix Sort
        // ----------

        if ( (rc = RadixSortIndex ( st_bijection, st_index, N, 16, 0, st_info->verbose)) ) return(rc);
        if ( st_info->benchmark ) sf_running_timer (&timer, "\tPlugin step (3): Sorted bijection");
        free (st_bijection);

        for (i = 0; i < N; i++) {
            if ( (rc = SF_vstore(kvars, i + in1, st_index[i] + 1)) ) return(rc);
        }
        if ( st_info->benchmark ) sf_running_timer (&timer, "\tPlugin step (4): Wrote back _sortindex");
        free (st_index);
    }
    else {

        if ( st_info->kvars_by_str == 0 ) {

            // Read in double sort vars and sort
            // ---------------------------------

            MultiQuicksort2 (st_info->st_numx, J, 0, ksort - 1, kvars * sizeof(st_info->st_numx), ltypes, st_info->invert);
            if ( st_info->benchmark ) sf_running_timer (&timer, "\tPlugin step (5.1): Sorted numeric array");

            out = 1;
            for (j = 0; j < J; j++) {
                sel    = (int) st_info->st_numx[j * kvars + ksort];
                start  = st_info->info[sel];
                end    = st_info->info[sel + 1];
                for (i = start; i < end; i++) {
                    if ( (rc = SF_vstore(kvars, out, st_info->index[i] + in1)) ) return(rc);
                    out++;
                }
            }

            free (st_info->st_numx);
            if ( st_info->benchmark ) sf_running_timer (&timer, "\tPlugin step (5.2): Wrote back _sortindex");
        }
        else {

            /*********************************************************************
             *                              Testing                              *
             *********************************************************************/

            size_t *positions = calloc(kvars, sizeof(*positions));
            if ( positions == NULL ) return (sf_oom_error("sf_hashsort", "positions"));

            positions[0] = 0;
            for (k = 1; k < kvars; k++) {
                ilen = st_info->byvars_lens[k - 1];
                if ( ilen > 0 ) {
                    positions[k] = positions[k - 1] + (ilen + 1);
                }
                else {
                    positions[k] = positions[k - 1] + sizeof(double);
                }
            }

            MultiQuicksort3 (st_info->st_charx, J, 0, ksort - 1, rowbytes * sizeof(char), ltypes, st_info->invert, positions);
            if ( st_info->benchmark ) sf_running_timer (&timer, "\tPlugin step (5.1): Sorted mixed array");

            out = 1;
            for (j = 0; j < J; j++) {
                sel    = *(int *)(st_info->st_charx + (j * rowbytes + positions[ksort]));
                start  = st_info->info[sel];
                end    = st_info->info[sel + 1];
                for (i = start; i < end; i++) {
                    if ( (rc = SF_vstore(kvars, out, st_info->index[i] + in1)) ) return(rc);
                    out++;
                }
            }

            free(positions);
            free(st_info->st_charx);
            if ( st_info->benchmark ) sf_running_timer (&timer, "\tPlugin step (5.2): Wrote back _sortindex");
        }
    }

    free (ltypes);

    return (0);
}

