/**
 * @file st_gentools.c
 * @version 0.3.0
 * @author Mauricio Caceres Bravo
 * @email <mauricio.caceres.bravo@gmail.com>
 * @date 25 Jul 2017
 * @brief General-purpose utility functions for writing Stata plugins
 *
 * These are various wrappers to make it easier to write Stata plugins.
 * At the moment it only contains printf function wrappers to print
 * formatted statements to the Stata console, but I plan to expand the
 * utilities in future versions.
 *
 * Note because functions are for use by Stata C-based plugins they
 * must be used in conjunction with stplugin.c and stplugin.h (see
 * stata.com/plugins for more on Stata plugins). In particular, both
 * should exist in the same directory and your main file should have
 *
 *     #include "stplugin.h"
 *
 * as one of its include statements.
 *
 * @see st_gsltools.c
 * @see http://www.stata.com/plugins for more on Stata plugins
 */

#include <time.h>
#include <sys/types.h>
/* #include "st_print.c" */
#include "st_gentools.h"

/*********************************************************************
 *                         Generic utilities                         *
 *********************************************************************/

#define CHAR(cvar, len) \
    char *(cvar) = malloc(sizeof(char) * (len)); \
    memset ((cvar), '\0', sizeof(char) * (len))

#define MF_MIN(x, N, min, _i)                 \
    typeof (*x) (min) = *x;                   \
    for (_i = 1; _i < N; ++_i) {              \
        if (min > *(x + _i)) min = *(x + _i); \
    }                                         \

#define MF_MAX(x, N, max, _i)                 \
    typeof (*x) (max) = *x;                   \
    for (_i = 1; _i < N; ++_i) {              \
        if (max < *(x + _i)) max = *(x + _i); \
    }                                         \

#define MF_MINMAX(x, N, min, max, _i)         \
    typeof (*x) (min) = *x;                   \
    typeof (*x) (max) = *x;                   \
    for (_i = 1; _i < N; ++_i) {              \
        if (min > *(x + _i)) min = *(x + _i); \
        if (max < *(x + _i)) max = *(x + _i); \
    }                                         \

/**
 * @brief Read scalar into integer
 *
 * @param st_scalar name of Stata scalar
 * @param sval Scalar value
 * @return Read scalar into size_t variable
 */
size_t sf_scalar_int (char *st_scalar, size_t *sval)
{
    ST_retcode rc = 0;
    ST_double _double;
    if ( (rc = SF_scal_use(st_scalar, &_double)) ) {
        return (rc);
    }
    else {
        *sval = (size_t) _double;
    }
    return (rc);
}

/**
 * @brief Get length of Stata vector
 *
 * @param st_matrix name of Stata vector (1xN or Nx1)
 * @return Return number of rows or cols.
 */
int sf_get_vector_length (char *st_matrix)
{
    int ncol = SF_col(st_matrix);
    int nrow = SF_row(st_matrix);
    if ( (ncol > 1) & (nrow > 1) ) {
        sf_errprintf("tried to get the length a %d by %d matrix\n", nrow, ncol);
        return (-1);
    }
    return ( ncol > nrow? ncol: nrow );
}

/**
 * @brief Parse stata vector into C array
 *
 * @param st_matrix name of stata matrix to get
 * @param v array where to store the vector
 * @return Store min and max of @x
 */
int sf_get_vector (char *st_matrix, double *v)
{
    ST_retcode rc = 0;

    int i;
    int ncol = SF_col(st_matrix);
    int nrow = SF_row(st_matrix);
    if ( (ncol > 1) & (nrow > 1) ) {
        sf_errprintf("tried to read a %d by %d matrix into an array\n", nrow, ncol);
        return(198);
    }

    if ( ncol > 1 ) {
        for (i = 0; i < ncol; i++) {
            if ( (rc = SF_mat_el(st_matrix, 1, i + 1, v + i)) )
                return(rc);
        }
    }
    else {
        for (i = 0; i < nrow; i++) {
            if ( (rc = SF_mat_el(st_matrix, i + 1, 1, v + i)) )
                return(rc);
        }
    }

    return (rc);
}

/**
 * @brief Parse stata vector into C array
 *
 * @param st_matrix name of stata matrix to get
 * @param v array where to store the vector
 * @return Store min and max of @x
 */
int sf_get_vector_int (char *st_matrix, size_t *v)
{
    ST_double z;
    ST_retcode rc = 0;

    int i;
    int ncol = SF_col(st_matrix);
    int nrow = SF_row(st_matrix);
    if ( (ncol > 1) & (nrow > 1) ) {
        sf_errprintf("tried to read a %d by %d matrix into an array\n", nrow, ncol);
        return (198);
    }
    else if ( (ncol == 0) & (nrow == 0) ) {
        sf_errprintf("tried to read a %d by %d matrix into an array\n", nrow, ncol);
        return (198);
    }

    if ( ncol > 1 ) {
        for (i = 0; i < ncol; i++) {
            if ( (rc = SF_mat_el(st_matrix, 1, i + 1, &z)) ) return(rc);
            v[i] = (size_t) z;
        }
    }
    else {
        for (i = 0; i < nrow; i++) {
            if ( (rc = SF_mat_el(st_matrix, i + 1, 1, &z)) ) return(rc);
            v[i] = (size_t) z;
        }
    }

    return (rc);
}

/*
// #define MF_GEN_SUM(type)                    \
//     type mf_sum_##type (type x[], size_t N) \
//     {                                       \
//         size_t i;                           \
//         type sum = x[0];                    \
//         for (i = 1; i < N; i++)             \
//             sum += x[i];                    \
//                                             \
//         return (sum);                       \
//     }
//
// MF_GEN_SUM(double)
//
// MF_GEN_SUM(int)
//
// MF_GEN_SUM(size_t)
//
// MF_GEN_SUM(uint64_t)
//
*/

/*********************************************************************
 *                           Stata helpers                           *
 *********************************************************************/

/**
 * @brief Wrapper for OOM error exit message
 */
int sf_oom_error (char * step_desc, char * obj_desc)
{
    sf_errprintf("%s: Unable to allocate memory for object '%s'.\n", step_desc, obj_desc);
    SF_display ("See {help gcollapse##memory:help gcollapse (Out of memory)}.\n");
    return (42002);
}

/*********************************************************************
 *                          Stata utilities                          *
 *********************************************************************/

/**
 * @brief Update a running timer and print a message to satata console
 *
 * Prints a messasge to Stata that the running timer @timer was last set
 * @diff seconds ago. It then updates the timer to the current time.
 *
 * @param timer clock object containing time since last udpate
 * @param msg message to print before # of seconds
 * @return Print time since last update to Stata console
 */
void sf_running_timer (clock_t *timer, const char *msg)
{
    double diff  = (double) (clock() - *timer) / CLOCKS_PER_SEC;
    sf_printf (msg);
    sf_printf ("; %.3f seconds.\n", diff);
    *timer = clock();
}

/**
 * @brief Check if in returns at least some observations
 *
 * @return 1 if at least 1 obs; 0 otherwise
 */
size_t sf_anyobs_sel()
{
    size_t i;
    for (i = SF_in1(); i <= SF_in2(); i++)
        if ( SF_ifobs(i) ) return(i);

    return (0);
}

/*********************************************************************
 *                               Misc                                *
 *********************************************************************/

#ifdef __APPLE__
#else
/**
 * @brief Implement memcpy as a dummy function for memset (not on OSX)
 *
 * Stata requires plugins to be compied as shared executables. Since
 * this is being compiled on a relatively new linux system (by 2017
 * standards), some of the dependencies set in this way cannot be
 * fulfilled by older Linux systems. In particular, using memcpy as
 * provided by my system creates a dependency to Glib 2.14, which cannot
 * be fulfilled on some older systems (notably the servers where I
 * intend to use the plugin; hence I implement memcpy and get rid of
 * that particular dependency).
 *
 * @param dest pointer to place in memory to copy @src
 * @param src pointer to place in memory that is source of data
 * @param n how many bytes to copy
 * @return move @src to @dest
 */
void * memcpy (void *dest, const void *src, size_t n)
{
    return memmove(dest, src, n);
}
#endif
