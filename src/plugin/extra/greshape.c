ST_retcode sf_reshape      (struct StataInfo *st_info, int level, char *fname);
ST_retcode sf_reshape_wide (struct StataInfo *st_info, int level, char *fname);
ST_retcode sf_reshape_long (struct StataInfo *st_info, int level, char *fname);
ST_retcode sf_reshape_read (struct StataInfo *st_info, int level, char *fname);

ST_retcode sf_reshape (struct StataInfo *st_info, int level, char *fname)
{
    if ( st_info->greshape_code == 1 ) {
        return (sf_reshape_long(st_info, level, fname));
    }
    else if ( st_info->greshape_code == 2 )  {
        return (sf_reshape_wide(st_info, level, fname));
    }
    else {
        return (198);
    }
}

ST_retcode sf_reshape_wide (struct StataInfo *st_info, int level, char *fname)
{
    sf_errprintf ("-greshape wide- not yet implemented");
    return (198);
}

ST_retcode sf_reshape_long (struct StataInfo *st_info, int level, char *fname)
{
    st_info->benchmark = 2;
    GT_bool debug = st_info->debug;
    if ( debug ) {
        sf_printf_debug("debug 1 (sf_reshape): Starting greshape.\n");
    }

    /*********************************************************************
     *                           Step 1: Setup                           *
     *********************************************************************/

    ST_retcode rc = 0;
    ST_double z;
    GT_size sel, i, j, k, l, m;
    GT_size *stptr;

    GT_size kvars    = st_info->kvars_by;
    GT_size kout     = st_info->greshape_kout;
    GT_size kxi      = st_info->greshape_kxi;
    GT_size klevels  = st_info->greshape_klvls;
    GT_size krow     = kvars + 1 + kout + kxi;
    GT_size Nread    = st_info->Nread;
    GT_size J        = st_info->J;
    clock_t timer    = clock();

    if ( debug ) {
        sf_printf_debug("\tkvars:   "GT_size_cfmt"\n",  kvars);
        sf_printf_debug("\tkout:    "GT_size_cfmt"\n",  kout);
        sf_printf_debug("\tkxi:     "GT_size_cfmt"\n",  kxi);
        sf_printf_debug("\tklevels: "GT_size_cfmt"\n",  klevels);
        sf_printf_debug("\tkrow:    "GT_size_cfmt"\n",  krow);
        sf_printf_debug("\tNread:   "GT_size_cfmt"\n",  Nread);
        sf_printf_debug("\tJ:       "GT_size_cfmt"\n",  J);
    }

    st_info->output = calloc(Nread * klevels * krow, sizeof st_info->output);
    if ( st_info->output == NULL ) return(sf_oom_error("sf_reshape_long", "st_info->output"));

    GTOOLS_GC_ALLOCATED("st_info->output")
    st_info->free = 9;

    st_info->greshape_maplevel = calloc((kout * klevels), sizeof(st_info->greshape_maplevel));
    if ( st_info->greshape_maplevel == NULL ) return(sf_oom_error("sf_reshape_long", "greshape_maplevel"));

    GT_size *index_st = calloc(Nread, sizeof *index_st);
    if ( index_st == NULL ) return(sf_oom_error("sf_reshape_long", "index_st"));

    ST_double *output   = st_info->output;
    GT_size   *maplevel = st_info->greshape_maplevel;

    /*********************************************************************
     *                      Step 2: Read in varlist                      *
     *********************************************************************/

    if ( debug ) {
        sf_printf_debug("debug 2 (sf_reshape): Index Stata order.\n");
    }

    // TODO: Change so that this is read from a text file...!
    for (i = 0; i < kout; i++) {
        for (j = 0; j < klevels; j++) {
            if ( (rc = SF_mat_el("__gtools_greshape_maplevel", i + 1, j + 1, &z)) )
                return (rc);
            maplevel[klevels * i + j] = z > 0? (GT_size) z + kvars: 0;
        }
    }

    for (i = 0; i < Nread; i++)
        index_st[i] = 0;

    for (j = 0; j < J; j++) {
        l = st_info->ix[j];
        index_st[st_info->info[l]] = l + 1;
    }

    if ( st_info->benchmark > 1 )
        sf_running_timer (&timer, "\treshape long step 1: Indexed in stata order");

    /*********************************************************************
     *                       Step 3: Reshape long                        *
     *********************************************************************/

    // Example
    // -------
    //
    // reshape long x z, i(i)
    //
    // xij       x z
    // xij_names x1 x2 z10 z20 z15
    // levels    1 2 10 15 20
    //
    // maplevel  1 2 0 0 0
    //           0 0 3 4 5

    if ( debug ) {
        sf_printf_debug("debug 3 (sf_reshape): Reshape long\n");
    }

    // for (k = 0; k < kout; k++) {
    //     for (j = 0; j < klevels; j++) {
    //         sf_printf_debug("\t%ld", maplevel[k * klevels + j]);
    //     }
    // }

    i = 0;
    for (stptr = index_st; stptr < index_st + Nread; stptr++, i++) {
        if ( *stptr ) {
            m = st_info->info[*stptr - 1];
            for (j = 0; j < klevels; j++) {
                sel = m * krow * klevels + j * krow;

                // TODO: Replace with st_info->st_by_charx, st_info->st_by_numx
                output[sel + 0] = i;

                // TODO: Replace with st_info->greshape_levels[j]
                output[sel + 1] = j;

                for (k = 0; k < kout; k++) {
                    if ( (l = maplevel[k * klevels + j]) > 0 ) {
                        if ( (rc = SF_vdata(l, i + st_info->in1, &z)) ) goto exit;
                        output[sel + 2 + k] = z;
                    }
                    else {
                        output[sel + 2 + k] = SV_missval;
                    }
                }
            }
        }
    }

    if ( st_info->benchmark > 1 )
        sf_running_timer (&timer, "\treshape long step 2: transposed data");

    /*********************************************************************
     *                       Step 4: Copy to disk                        *
     *********************************************************************/

    if ( (rc = SF_scal_save ("__gtools_greshape_nrows",
                             (ST_double) Nread * klevels)) ) goto exit;

    if ( (rc = SF_scal_save ("__gtools_greshape_ncols",
                             (ST_double) krow)) ) goto exit;

    FILE *fhandle;
    fhandle = fopen(fname, "wb");
    fwrite (output, sizeof(output), Nread * klevels * krow, fhandle);
    fclose (fhandle);

    if ( st_info->benchmark > 1 )
        sf_running_timer (&timer, "\treshape long step 3: copied reshaped data to disk");

exit:
    free (st_info->greshape_maplevel);
    free (index_st);

    return (rc);
}

ST_retcode sf_reshape_read (struct StataInfo *st_info, int level, char *fname)
{
    st_info->benchmark = 2;
    GT_bool debug = st_info->debug;
    if ( debug ) {
        sf_printf_debug("debug 3 (sf_reshape): Reading back reshaped data.\n");
    }

    /*********************************************************************
     *                           Step 1: Setup                           *
     *********************************************************************/

    ST_retcode rc = 0;
    // ST_double z;
    GT_size i, k;

    GT_size kvars    = st_info->kvars_by;
    GT_size kout     = st_info->greshape_kout;
    GT_size kxi      = st_info->greshape_kxi;
    GT_size krow     = kvars + 1 + kout + kxi;
    GT_size N        = st_info->N;
    clock_t timer    = clock();

    if ( debug ) {
        sf_printf_debug("\tkvars:   "GT_size_cfmt"\n", kvars);
        sf_printf_debug("\tkout:    "GT_size_cfmt"\n", kout);
        sf_printf_debug("\tkxi:     "GT_size_cfmt"\n", kxi);
        sf_printf_debug("\tkrow:    "GT_size_cfmt"\n", krow);
        sf_printf_debug("\tN:       "GT_size_cfmt"\n", N);
    }

    ST_double *output = calloc(N * krow, sizeof *output);
    if ( output == NULL ) return(sf_oom_error("sf_reshape_read", "output"));

    if ( st_info->benchmark > 1 )
        sf_running_timer (&timer, "\treshape long step 5: copied reshaped data back to mem");

    /*********************************************************************
     *                      Step 2: Read in varlist                      *
     *********************************************************************/

    FILE *fhandle = fopen(fname, "rb");
    fread (output, sizeof(output), krow * N, fhandle);
    fclose(fhandle);

    for (i = 0; i < N; i++) {
        for (k = 0; k < krow; k++) {
            if ( (rc = SF_vstore(k + 1, i + 1, output[i * krow + k])) ) goto exit;
        }
    }

    if ( st_info->benchmark > 1 )
        sf_running_timer (&timer, "\treshape long step 6: copied reshaped data to stata");

exit:
    free (output);
    return (rc);

}
