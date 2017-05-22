#include <omp.h>

/**
 * @brief Min, max, and missing count for numeric by vars
 *
 * @return Computes min, max, and missing count in Stata
 */
int sf_numsetup()
{
    ST_retcode rc ;
    ST_double  z ;
    int i, k;

    int kvars_by_num = sf_get_vector_length("c_gtools_bymiss");
    if ( kvars_by_num < 0 ) return (198);

    double mins[kvars_by_num], maxs[kvars_by_num], miss[kvars_by_num];
    int nonmiss[kvars_by_num];
    size_t in1    = SF_in1();
    size_t in2    = SF_in2();
    size_t N      = in2 - in1 + 1;
    size_t start  = 0;

    for (k = 0; k < kvars_by_num; k++)
        mins[k] = maxs[k] = miss[k] = nonmiss[k] = 0;

    do {
        for (k = 0; k < kvars_by_num; k++) {
            if ( (rc = SF_vdata(k + 1, start + in1, &z)) ) return(rc);
            if ( SF_is_missing(z) ) {
                miss[k] = 1;
            }
            else {
                if ( nonmiss[k] == 0 ) {
                    nonmiss[k] = 1;
                    mins[k]    = z;
                    maxs[k]    = z;
                }
            }
        }
        ++start;
    } while ( (mf_sum_signed(nonmiss, kvars_by_num) < kvars_by_num) & (start < N) );

    int rct;
    int rcp = 0;
    double pmins[kvars_by_num], pmaxs[kvars_by_num], pmiss[kvars_by_num];
    #pragma omp parallel \
            private (    \
                k,       \
                z,       \
                pmiss,   \
                pmins,   \
                pmaxs,   \
                rc,      \
                rct      \
            )            \
            shared (     \
                miss,    \
                mins,    \
                maxs,    \
                rcp      \
            )
    {
        z   = 0;
        rc  = 0;
        rct = 0;
        for (k = 0; k < kvars_by_num; k++) {
            pmiss[k] = miss[k];
            pmins[k] = mins[k];
            pmaxs[k] = maxs[k];
        }

        #pragma omp for
        for (i = 0; i < N; i++) {
            for (k = 0; k < kvars_by_num; k++) {
                if ( (rc = SF_vdata(k + 1, i + in1, &z)) ) {
                    rct = rc;
                    continue;
                }
                if ( SF_is_missing(z) ) {
                    pmiss[k] = 1;
                }
                else {
                    if (pmins[k] > z) pmins[k] = z;
                    if (pmaxs[k] < z) pmaxs[k] = z;
                }
            }
        }

        #pragma omp critical
        {
            if ( rct ) rcp = rct;
            for (k = 0; k < kvars_by_num; k++) {
                miss[k] = MAX(miss[k], pmiss[k]);
                mins[k] = MIN(mins[k], pmins[k]);
                maxs[k] = MAX(maxs[k], pmaxs[k]);
            }
        }
    }
    if ( rcp ) return (rcp);

    for (k = 0; k < kvars_by_num; k++) {
        if ( (rc = SF_mat_store("c_gtools_bymiss", 1, k + 1, miss[k])) ) return(rc);
        if ( (rc = SF_mat_store("c_gtools_bymin",  1, k + 1, mins[k])) ) return(rc);
        if ( (rc = SF_mat_store("c_gtools_bymax",  1, k + 1, maxs[k])) ) return(rc);
    }

    return(0);
}
