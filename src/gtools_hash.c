#include "gtools_hash.h"
#include "spookyhash/src/spookyhash_api.h"

int sf_get_variable_hash (
    uint64_t h1[],
    uint64_t h2[],
    size_t k,
    size_t in1,
    size_t in2,
    int strlen)
{

    if ( in2 < in1 ) {
        sf_errprintf("data ending position %d < starting position %d", in2, in1);
        return(198);
    }

    ST_retcode rc ;
    ST_double  z ;
    size_t N = in2 - in1 + 1;
    char s[strlen + 1];
    spookyhash_context sc;

    // Get data on every row from in1 to in2 regardless of `if'; in case
    // the plugin was not called with an `if' statement this will not
    // work, so subset before starting the plugin. The if condition is
    // so we do not have multiple ifs within the long for loop.

    if ( strlen > 0 ) {
        for (int i = 0; i < N; i++) {
            if ( (rc = SF_sdata(k, i + in1, s)) ) return(rc);
            spookyhash_context_init(&sc, 1, 2);
            spookyhash_update(&sc, &s, strlen);
            spookyhash_final(&sc, &h1[i], &h2[i]);
            // sf_printf ("Obs %9d = %s, %21lu, %21lu\n", i, s, h1[i], h2[i]);
        }
    }
    else {
        for (int i = 0; i < N; i++) {
            if ( (rc = SF_vdata(k, i + in1, &z)) ) return(rc);
            spookyhash_context_init(&sc, 1, 2);
            spookyhash_update(&sc, &z, 8);
            spookyhash_final(&sc, &h1[i], &h2[i]);
            // sf_printf ("Obs %9d = %.1f, %21lu, %21lu\n", i, z, h1[i], h2[i]);
        }
    }
    return(0);
}

int sf_get_varlist_hash (
    uint64_t h1[],
    uint64_t h2[],
    size_t k1,
    size_t k2,
    size_t in1,
    size_t in2,
    int karr[])
{

    if ( k2 < k1 ) {
        sf_errprintf("requested variables %d to %d; must request varlist in order\n", k1, k2);
        return(198);
    }

    if ( in2 < in1 ) {
        sf_errprintf("data ending position %d < starting position %d\n", in2, in1);
        return(198);
    }

    ST_retcode rc ;
    ST_double  z ;
    size_t N = in2 - in1 + 1;
    size_t K = k2 - k1 + 1;
    int kmax = mf_max_signed(karr, K);
    int kmin = mf_min_signed(karr, K);
    char s[kmax + 1];
    spookyhash_context sc;
    int i, k;

    // Get data on every row from in1 to in2 regardless of `if'; in
    // case the plugin was not called with an `if' statement this will
    // not work, so subset before starting the plugin. All the if
    // statements are so we have fewer if conditions inside long loops

    if (kmax > 0) {
        if (kmin > 0) {
            for (i = 0; i < N; i++) {
                spookyhash_context_init(&sc, 1, 2);

                for (k = 0; k < K; k++) {
                    if ( (rc = SF_sdata(k + k1, i + in1, s)) ) return(rc);
                    spookyhash_update(&sc, &s, kmax);
                }

                spookyhash_final(&sc, &h1[i], &h2[i]);
                // sf_printf ("Obs %9d, %21lu, %21lu\n", i, h1[i], h2[i]);
            }
        }
        else {
            for (i = 0; i < N; i++) {
                spookyhash_context_init(&sc, 1, 2);

                for (k = 0; k < K; k++) {
                    if (karr[k] > 0) {
                        if ( (rc = SF_sdata(k + k1, i + in1, s)) ) return(rc);
                        spookyhash_update(&sc, &s, kmax);
                    }
                    else {
                        if ( (rc = SF_vdata(k + k1, i + in1, &z)) ) return(rc);
                        spookyhash_update(&sc, &z, 8);
                    }
                }

                spookyhash_final(&sc, &h1[i], &h2[i]);
                // sf_printf ("Obs %9d, %21lu, %21lu\n", i, h1[i], h2[i]);
            }
        }
    }
    else {
        for (i = 0; i < N; i++) {
            spookyhash_context_init(&sc, 1, 2);

            for (k = 0; k < K; k++) {
                if ( (rc = SF_vdata(k + k1, i + in1, &z)) ) return(rc);
                spookyhash_update(&sc, &z, 8);
            }

            spookyhash_final(&sc, &h1[i], &h2[i]);
            // sf_printf ("Obs %9d, %21lu, %21lu\n", i, h1[i], h2[i]);
        }
    }
    return(0);
}

int sf_get_variable_ashash (
    uint64_t h1[],
    size_t k,
    size_t in1,
    size_t in2,
    int min)
{

    if ( in2 < in1 ) {
        sf_errprintf("data ending position %d < starting position %d", in2, in1);
        return(198);
    }

    ST_retcode rc ;
    ST_double  z ;
    size_t N = in2 - in1 + 1;

    // Get data on every row from in1 to in2 regardless of `if'; in case
    // the plugin was not called with an `if' statement this will not
    // work, so subset before starting the plugin. The if condition is
    // so we do not have multiple ifs within the long for loop.

    for (int i = 0; i < N; i++) {
        if ( (rc = SF_vdata(k, i + in1, &z)) ) return(rc);
        h1[i] = z - min + 1;
        // sf_printf ("Obs %9d = %.1f, %21lu\n", i, z, h1[i]);
    }

    return(0);
}

// If we have only integers, you want a function f f: Z^K -> N. In this
// case, the function we use is as follows (using 1-based indexing):
//
// offset = 1
// hash   = z[, 1] - min(z[, 1]) + 1
// for k = 2 to K
//     offset *= (zmax[k - 1] - zmin[k - 1] + 1)
//     hash   += ( z[, k] - min(z[, k]) ) * offset
//
// What is happening is that we are fisrt mapping
//
//     var1 -> 1 to range of var1
//
// Call this vmap1. Then we are mapping
//
//     Smallest # of var2 -> vmap1
//     2-smallest # of var2 -> vmap1 + range of vmap1
//     ...
//     ith-smallest # of var2 -> vmap1 + range of vmap1
//
// Call this vmap2. Then we do
//
//     Smallest # of vark -> vmap(k - 1)
//     2-smallest # of vark -> vmap(k - 1) + range of vmap(k - 1)
//     ...
//     ith-smallest # of vark -> vmap(k - 1) + range of vmap(k - 1)

int sf_get_varlist_bijection (
    uint64_t h1[],
    size_t k1,
    size_t k2,
    size_t in1,
    size_t in2,
    int mins[],
    int maxs[])
{

    if ( k2 < k1 ) {
        sf_errprintf("requested variables %d to %d; must request varlist in order\n", k1, k2);
        return(198);
    }

    if ( in2 < in1 ) {
        sf_errprintf("data ending position %d < starting position %d\n", in2, in1);
        return(198);
    }

    ST_retcode rc ;
    ST_double  z ;
    size_t N = in2 - in1 + 1;
    size_t K = k2 - k1 + 1;
    size_t offset = 1;
    size_t offsets[K];
    int i, k;

    for (k = 0; k < K - 1; k++) {
        offset *= maxs[k] - mins[k] + 1;
        offsets[k + 1] = offset;
    }

    for (i = 0; i < N; i++) {
        if ( (rc = SF_vdata(1, i + in1, &z)) ) return(rc);
        h1[i] = z - mins[0] + 1;
        for (k = 1; k < K; k++) {
            if ( (rc = SF_vdata(k + k1, i + in1, &z)) ) return(rc);
            h1[i] += (z - mins[k]) * offsets[k];
        }
        // sf_printf ("Obs %9d = %21lu\n", i, h1[i]);
    }

    return (0);
}
