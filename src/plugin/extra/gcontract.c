ST_retcode sf_contract (struct StataInfo *st_info, int level);

ST_retcode sf_contract (struct StataInfo *st_info, int level)
{

    /*********************************************************************
     *                           Step 1: Setup                           *
     *********************************************************************/

    ST_retcode rc = 0;
    ST_double z;
    GT_size j, k, l;
    GT_size cvars    = st_info->contract_vars;
    ST_double Ndbl   = (ST_double) st_info->N;
    clock_t timer    = clock();

    /*********************************************************************
     *                     Step 2: Sort group counts                     *
     *********************************************************************/

    st_info->output = calloc(cvars * st_info->J,  sizeof *st_info->output);
    if ( st_info->output == NULL ) sf_oom_error("sf_contract", "st_info->output");
    GTOOLS_GC_ALLOCATED("st_info->output")
    st_info->free = 9;

    k = 0;
    l = st_info->ix[0];
    st_info->output[k++] = z = st_info->info[l + 1] - st_info->info[l];

    if ( st_info->contract_which[1] ) {
        st_info->output[k++] = z;
    }

    if ( st_info->contract_which[2] ) {
        st_info->output[k++] = 100 * z / Ndbl;
    }

    if ( st_info->contract_which[3] ) {
        st_info->output[k++] = 100 * z / Ndbl;
    }

    for (j = 1; j < st_info->J; j++) {
        k  = 0;
        l  = st_info->ix[j];
        st_info->output[j * cvars + k++] = st_info->info[l + 1] - st_info->info[l];
        z += st_info->output[j * cvars];

        if ( st_info->contract_which[1] ) {
            st_info->output[j * cvars + k++] = z;
        }

        if ( st_info->contract_which[2] ) {
            st_info->output[j * cvars + k++] = 100 * st_info->output[j * cvars] / Ndbl;
        }

        if ( st_info->contract_which[3] ) {
            st_info->output[j * cvars + k++] = 100 * z / Ndbl;
        }
    }

    if ( st_info->benchmark > 1 )
        sf_running_timer (&timer, "\tPlugin step 5: Generated output array");

    return (rc);
}
