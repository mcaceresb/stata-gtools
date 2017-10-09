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

    double *mins = calloc(kvars_by_num, sizeof *mins);
    double *maxs = calloc(kvars_by_num, sizeof *maxs);
    double *miss = calloc(kvars_by_num, sizeof *miss);
    int *nonmiss = calloc(kvars_by_num, sizeof *nonmiss);

    if ( mins    == NULL ) return(sf_oom_error("sf_numsetup", "mins"));
    if ( maxs    == NULL ) return(sf_oom_error("sf_numsetup", "maxs"));
    if ( miss    == NULL ) return(sf_oom_error("sf_numsetup", "miss"));
    if ( nonmiss == NULL ) return(sf_oom_error("sf_numsetup", "nonmiss"));

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

    for (i = 0; i < N; i++) {
        for (k = 0; k < kvars_by_num; k++) {
            if ( (rc = SF_vdata(k + 1, i + in1, &z)) ) return(rc);
            if ( SF_is_missing(z) ) {
                miss[k] = 1;
            }
            else {
                if (mins[k] > z) mins[k] = z;
                if (maxs[k] < z) maxs[k] = z;
            }
        }
    }

    for (k = 0; k < kvars_by_num; k++)
        sf_printf ("%.4f \t %.4f \t %.4f \n", mins[k], maxs[k], miss[k]);

    for (k = 0; k < kvars_by_num; k++) {
        if ( (rc = SF_mat_store("c_gtools_bymiss", 1, k + 1, miss[k])) ) return(rc);
        if ( (rc = SF_mat_store("c_gtools_bymin",  1, k + 1, mins[k])) ) return(rc);
        if ( (rc = SF_mat_store("c_gtools_bymax",  1, k + 1, maxs[k])) ) return(rc);
    }

    free (mins);
    free (maxs);
    free (miss);
    free (nonmiss);

    return(0);
}

/**
 * @brief Check if in returns at least some observations
 *
 * @return 1 if at least 1 obs; 0 otherwise
 */
int sf_anyobs_sel()
{
    int i;
    for (i = SF_in1(); i <= SF_in2(); i++)
        if ( SF_ifobs(i) ) return(1);
    return (0);
}
