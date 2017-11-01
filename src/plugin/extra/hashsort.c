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

    if ( st_info->invertix ) {
        GT_size *sortindex = calloc(N, sizeof *sortindex);
        if ( sortindex == NULL ) sf_oom_error("sf_hashsort", "sortindex");
        GTOOLS_GC_ALLOCATED("sortindex")

        if ( st_info->biject ) {
            for (i = 0; i < N; i++)
                sortindex[i] = i;
        }
        else {
            out = 0;
            for (j = 0; j < J; j++) {
                sel    = st_info->ix[j];
                start  = st_info->info[sel];
                end    = st_info->info[sel + 1];
                for (i = start; i < end; i++) {
                    sortindex[i] = out;
                    out++;
                }
            }
        }

        GT_size min  = 0;
        GT_size max  = N - 1;
        GT_size ctol = pow(2, 24);

        if ( N < ctol ) {
            if ( (rc = gf_counting_sort (st_info->index, sortindex, N, min, max)) )
                goto error;
        }
        else {
            if ( (rc = gf_radix_sort16 (st_info->index, sortindex, N)) )
                goto error;
        }

        for (i = 0; i < N; i++) {
            if ( (rc = SF_vstore(ksort, i + in1, sortindex[i] + 1)) )
                goto error;
        }

error:
        free (sortindex);
        GTOOLS_GC_FREED("sortindex")
    }
    else {
        if ( st_info->biject ) {
            for (i = 0; i < N; i++) {
                if ( (rc = SF_vstore(ksort, i + in1, st_info->index[i] + 1)) ) goto exit;
            }
        }
        else {
            out = 1;
            for (j = 0; j < J; j++) {
                sel    = st_info->ix[j];
                start  = st_info->info[sel];
                end    = st_info->info[sel + 1];
                for (i = start; i < end; i++) {
                    if ( (rc = SF_vstore(ksort, out, st_info->index[i] + 1)) ) goto exit;
                    out++;
                }
            }
        }
    }

    if ( st_info->benchmark )
        sf_running_timer (&timer, "\tPlugin step 5: Wrote back _sortindex");

exit:
    return (rc);
}

/*
index
0
1
2
3
4
5
6
7
8
9

index (hash order)
2 | 0
6 |
  | 2

0 | 2
1 |
3 |
5 |
7 |
8 |
9 |
  | 9

4 | 9
  | 10

ix (sort order)
1
2
0

index (sort order)
0 | 2
1 |
3 |
5 |
7 |
8 |
9 |
  | 9

4 | 9
  | 10

2 | 0
6 |
  | 2

mata: invorder(st_data(., "ix"))

sort index

0
1
8
2
7
3
9
4
5
6
 */
