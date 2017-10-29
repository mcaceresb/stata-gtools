ST_retcode sf_hashsort (struct StataInfo *st_info, int level);
 
ST_retcode sf_hashsort (struct StataInfo *st_info, int level)
{

    /*********************************************************************
     *                               Setup                               *
     *********************************************************************/

    GT_size i, j, sel, out, start, end;
    GT_size N     = st_info->N;
    GT_size J     = st_info->J;
    GT_size in1   = st_info->in1;
    GT_size kvars = st_info->kvars_by;
    GT_size ksort = kvars + st_info->kvars_group + 1;

    ST_retcode rc = 0;
    clock_t timer = clock();

    /*********************************************************************
     *                       Write back _sortindex                       *
     *********************************************************************/

    if ( st_info->biject ) {
        for (i = 0; i < N; i++) {
            if ( (rc = SF_vstore(ksort, i + in1, st_info->index[i] + 1)) ) goto exit;
        }

        if ( st_info->benchmark )
            sf_running_timer (&timer, "\tPlugin step 5: Wrote back _sortindex");
    }
    else {
        out = 1;
        for (j = 0; j < J; j++) {
            sel    = st_info->ix[j];
            start  = st_info->info[sel];
            end    = st_info->info[sel + 1];
            for (i = start; i < end; i++) {
                if ( (rc = SF_vstore(ksort, out, st_info->index[i] + 1)) ) return(rc);
                out++;
            }
        }

        if ( st_info->benchmark )
            sf_running_timer (&timer, "\tPlugin step 5: Wrote back _sortindex");
    }

exit:
    return (rc);
}

