#include "glevelsof.h"

int sf_levelsof (struct StataInfo *st_info)
{

    /*********************************************************************
     *                           Step 1: Setup                           *
     *********************************************************************/

    ST_retcode rc ;
    int j, k;
    size_t kvars, sel, offset_bystr, start;
    clock_t timer = clock();

    /*********************************************************************
     *                     Step 2: Memory allocation                     *
     *********************************************************************/

    MixedUnion *st_dtax;
    double *output;
    double *st_numx;

    kvars = (st_info->kvars_by + st_info->kvars_targets);
    if ( st_info->read_dtax ) {
        st_dtax = st_info->st_dtax;
        output  = st_info->output;
        st_numx = st_info->st_numx;
    }
    else {
        if ( st_info->kvars_by_str > 0 ) {
            // If there are string variables, use a mixed type container
            st_dtax = calloc(kvars * st_info->J, sizeof *st_dtax);
            if ( st_dtax == NULL ) return (sf_oom_error("sf_levelsof", "st_dtax"));

            // In this case, you need to allocate time for all the strings
            for (j = 0; j < st_info->J; j++) {
                for (k = 0; k < st_info->kvars_by_str; k++) {
                    sel = j * kvars + (st_info->pos_str_byvars[k] - 1);
                    offset_bystr = st_info->byvars_lens[st_info->pos_str_byvars[k] - 1];
                    if ( offset_bystr > 0 ) {
                        st_dtax[sel].cval = malloc((offset_bystr + 1) * sizeof(char));
                        if ( st_dtax[sel].cval == NULL ) return (sf_oom_error("sf_levelsof", "st_dtax[sel].cval"));
                        memset (st_dtax[sel].cval, '\0', offset_bystr + 1);
                    }
                    else {
                        sf_errprintf ("Unable to parse string lengths from Stata.\n");
                        return (198);
                    }
                }
            }
            st_numx = malloc(sizeof(double));
            output  = malloc(sizeof(double));
        }
        else {
            // If only numbers, just allocate a double array
            st_dtax = malloc(sizeof(MixedUnion));
            output  = malloc(sizeof(double));
            st_numx = calloc(kvars * st_info->J, sizeof *st_numx);
            if ( st_numx  == NULL ) return(sf_oom_error("sf_levelsof", "st_numx"));
        }
    }

    /*********************************************************************
     *                   Step 3: Read in by variables                    *
     *********************************************************************/


    if ( !st_info->read_dtax ) {

        // Read in first entry of each group variable
        // ------------------------------------------

        if ( st_info->kvars_by_str > 0 ) {

            // Collapse B: Mixed string and number array
            // -----------------------------------------

            for (j = 0; j < st_info->J; j++) {
                start = st_info->info[j];
                for (k = 0; k < st_info->kvars_by; k++) {
                    sel = j * kvars + k;
                    if ( st_info->byvars_lens[k] > 0 ) {
                        if ( (rc = SF_sdata(k + 1, st_info->index[start] + st_info->in1, st_dtax[sel].cval)) ) return(rc);
                    }
                    else {
                        if ( (rc = SF_vdata(k + 1, st_info->index[start] + st_info->in1, &(st_dtax[sel].dval))) ) return(rc);
                    }
                }
            }
        }
        else {

            // Collapse C: Number only array
            // -----------------------------

            for (j = 0; j < st_info->J; j++) {
                start = st_info->info[j];
                for (k = 0; k < st_info->kvars_by; k++) {
                    if ( (rc = SF_vdata(k + 1, st_info->index[start] + st_info->in1, &(st_numx[j * kvars + k]))) ) return(rc);
                }
            }
        }
        if ( st_info->benchmark ) sf_running_timer (&timer, "\tPlugin step 5.1: Read by variables");
    }

    // Sort in memory
    // --------------

    if ( st_info->sort_memory ) {
        if ( st_info->kvars_by_str > 0 ) {
            MultiQuicksort (st_dtax, st_info->J, 0, st_info->kvars_by - 1,
                            kvars * sizeof(*st_dtax), st_info->byvars_lens, st_info->invert);
        }
        else {
            MultiQuicksort2 (st_numx, st_info->J, 0, st_info->kvars_by - 1,
                             kvars * sizeof(*st_numx), st_info->byvars_lens, st_info->invert);
        }
        if ( st_info->benchmark ) sf_running_timer (&timer, "\tPlugin step 5.2: Sorted variable levels");
    }

    /*********************************************************************
     *                Step 6: Copy output back into Stata                *
     *********************************************************************/

    // 18446744073709551615 is the largest unsigned integer, so we allocate
    // 20 per number (-levelsof- prints 15 significant digits otherwise, so
    // 20 should be enough; note that scientific notation also requires 20).

    char *macrobuffer;
    size_t bufferlen;

    char *colsep = malloc((st_info->colsep_len + 1) * sizeof(char));
    char *sep    = malloc((st_info->sep_len    + 1) * sizeof(char));

    if ( colsep == NULL ) return (sf_oom_error("sf_levelsof", "colsep"));
    if ( sep    == NULL ) return (sf_oom_error("sf_levelsof", "sep"));

    memset (colsep, '\0', (st_info->colsep_len + 1) * sizeof(char));
    memset (sep,    '\0', (st_info->sep_len    + 1) * sizeof(char));

    if ( (rc = SF_macro_use("_colsep", colsep, st_info->colsep_len + 1)) ) return (rc);
    if ( (rc = SF_macro_use("_sep",    sep,    st_info->sep_len    + 1))    ) return (rc);

    char *sprintfmt    = st_info->clean_str? strdup("%s"): strdup("`\"%s\"'");
    size_t sprintextra = st_info->clean_str? 0: 4;
    size_t totalseplen = (st_info->J - 1) * st_info->sep_len + st_info->J * st_info->colsep_len * (st_info->kvars_by - 1);
    if ( st_info->kvars_by_str > 0 ) {
        bufferlen   = totalseplen + 1;
        bufferlen  += st_info->J * (sprintextra * st_info->kvars_by_str) + st_info->strbuffer;
        bufferlen  += st_info->J * (st_info->kvars_by_num * 20);
        macrobuffer = malloc(bufferlen * sizeof(char));
    }
    else {
        bufferlen   = totalseplen + 1;
        bufferlen  += st_info->J * (st_info->kvars_by_num * 20);
        macrobuffer = malloc(bufferlen * sizeof(char));
    }

    if ( macrobuffer == NULL ) return (sf_oom_error("sf_levelsof", "macrobuffer"));
    memset (macrobuffer, '\0', bufferlen * sizeof(char));

    char *strpos = macrobuffer;
    if ( st_info->kvars_by > 1 ) {
        if ( st_info->kvars_by_str > 0 ) {
            for (j = 0; j < st_info->J; j++) {
                if ( j > 0 ) strpos += sprintf(strpos, "%s", sep);
                for (k = 0; k < st_info->kvars_by; k++) {
                    if ( k > 0 ) strpos += sprintf(strpos, "%s", colsep);
                    sel = j * kvars + k;
                    if ( st_info->byvars_lens[k] > 0 ) {
                        strpos += sprintf(strpos, sprintfmt, st_dtax[sel].cval);
                    }
                    else {
                        if ( SF_is_missing(st_dtax[sel].dval) )
                            strpos += sprintf(strpos, ".");
                        else
                            strpos += sprintf(strpos, "%.15g", st_dtax[sel].dval);
                    }
                }
            }
        }
        else {
            for (j = 0; j < st_info->J; j++) {
                if ( j > 0 ) strpos += sprintf(strpos, "%s", sep);
                for (k = 0; k < st_info->kvars_by; k++) {
                    if ( k > 0 ) strpos += sprintf(strpos, "%s", colsep);
                    sel = j * kvars + k;
                    if ( SF_is_missing(st_numx[sel]) )
                        strpos += sprintf(strpos, ".");
                    else
                        strpos += sprintf(strpos, "%.15g", st_numx[sel]);
                }
            }
        }
    }
    else {
        if ( st_info->kvars_by_str > 0 ) {
            if ( st_info->missing ) {
                start = 0;
            }
            else {
                start = 1;
                if ( strcmp(st_dtax[0].cval, "") ) {
                    strpos += sprintf(strpos, sprintfmt, st_dtax[0].cval);
                    strpos += sprintf(strpos, "%s", sep);
                }
            }
            for (j = start; j < st_info->J; j++) {
                if ( j > start ) strpos += sprintf(strpos, "%s", sep);
                sel = j * kvars;
                strpos += sprintf(strpos, sprintfmt, st_dtax[sel].cval);
            }
        }
        else {
            for (j = 0; j < st_info->J - 1; j++) {
                if ( j > 0 ) strpos += sprintf(strpos, "%s", sep);
                sel = j * kvars;
                strpos += sprintf(strpos, "%.15g", st_numx[sel]);
            }
            sel = (st_info->J - 1) * kvars;
            if ( st_info->J > 1 ) strpos += sprintf(strpos, "%s", sep);
            if ( SF_is_missing(st_numx[sel]) & st_info->missing )
                strpos += sprintf(strpos, ".");
            else
                strpos += sprintf(strpos, "%.15g", st_numx[sel]);
        }
    }

    if ( (rc = SF_macro_save("_vals", macrobuffer)) ) return (rc);
    if ( st_info->benchmark ) sf_running_timer (&timer, "\tPlugin step 5.3: Wrote levels to Stata macro");

    if ( st_info->kvars_by_str > 0 ) {
        for (j = 0; j < st_info->J; j++) {
            for (k = 0; k < st_info->kvars_by_str; k++) {
                sel = j * kvars + (st_info->pos_str_byvars[k] - 1);
                free(st_dtax[sel].cval);
            }
        }
    }

    free (sprintfmt);
    free (output);
    free (st_dtax);
    free (st_numx);

    free (sep);
    free (colsep);
    free (macrobuffer);

    return (0);
}
