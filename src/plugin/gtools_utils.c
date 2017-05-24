#include "gtools_utils.h"

/**
 * @brief Minimum for signed integer array
 *
 * @param x vector of integers to get the min
 * @param N number of elements in @x
 * @return Smallest integer in @x
 */
int mf_min_signed(int x[], size_t N)
{
    int min = x[0];
    for (size_t i = 1; i < N; ++i) {
        if (min > x[i]) min = x[i];
    }
    return (min);
}

/**
 * @brief Maximum for signed integer array
 *
 * @param x vector of integers to get the max
 * @param N number of elements in @x
 * @return Smallest integer in @x
 */
int mf_max_signed(int x[], size_t N)
{
    int max = x[0];
    for (size_t i = 1; i < N; ++i) {
        if (max < x[i]) max = x[i];
    }
    return (max);
}

/**
 * @brief Minimum for unsigned 64-bit integer array
 *
 * @param x vector of integers to get the min
 * @param N number of elements in @x
 * @return Smallest integer in @x
 */
uint64_t mf_min(uint64_t x[], size_t N)
{
    uint64_t min = x[0];
    for (size_t i = 1; i < N; ++i) {
        if (min > x[i]) min = x[i];
    }
    return (min);
}

/**
 * @brief Maximum for unsigned 64-bit integer array
 *
 * @param x vector of integers to get the max
 * @param N number of elements in @x
 * @return Smallest integer in @x
 */
uint64_t mf_max(uint64_t x[], size_t N)
{
    uint64_t max = x[0];
    for (size_t i = 1; i < N; ++i) {
        if (max < x[i]) max = x[i];
    }
    return (max);
}

/**
 * @brief Min and max for unsigned 64-bit integer array
 *
 * @param x vector of integers to get the max
 * @param N number of elements in @x
 * @param min where to store min value
 * @param max where to store max value
 * @return Store min and max of @x
 */
void mf_minmax(uint64_t x[], size_t N, uint64_t * min, uint64_t * max)
{
    *min = *max = x[0];
    for (size_t i = 1; i < N; ++i) {
        if (*min > x[i]) *min = x[i];
        if (*max < x[i]) *max = x[i];
    }
}

/**
 * @brief Simple wrapper to compere a string
 *
 * I parse the relevant statistics to compute from a Stata local into an
 * array of character arrays. I don't understand C-pointers well-enough
 * to do this properly, but using this wrapper works.
 *
 * @param fname Function name
 * @param compare Comparison string
 * @return 1 if they are the same, 0 otherwise.
 */
int mf_strcmp_wrapper (char * fname, char *compare) {
    return ( strcmp (fname, compare)  == 0 );
}

/**
 * @brief Implement memcpy as a dummy function for memset
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

/*********************************************************************
 *                          Stata utilities                          *
 *********************************************************************/

/**
 * @brief Get length of Stata vector
 *
 * @param st_matrix name of Stata vector (1xN or Nx1)
 * @return Return number of rows or cols.
 */
int sf_get_vector_length(char * st_matrix)
{
    int ncol = SF_col(st_matrix);
    int nrow = SF_row(st_matrix);
    if ( (ncol > 1) & (nrow > 1) ) {
        sf_errprintf("tried to get the length a %d by %d matrix\n", nrow, ncol);
        return(-1);
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
int sf_get_vector(char * st_matrix, double v[])
{
    ST_retcode rc ;
    ST_double  z ;
    int ncol = SF_col(st_matrix);
    int nrow = SF_row(st_matrix);
    if ( (ncol > 1) & (nrow > 1) ) {
        sf_errprintf("tried to read a %d by %d matrix into an array\n", nrow, ncol);
        return(198);
    }
    if ( ncol > 1 ) {
        for (int i = 0; i < ncol; i++) {
            if ( (rc = SF_mat_el(st_matrix, 1, i + 1, &z)) ) return(rc);
            v[i] = z;
        }
    }
    else {
        for (int i = 0; i < nrow; i++) {
            if ( (rc = SF_mat_el(st_matrix, i + 1, 1, &z)) ) return(rc);
            v[i] = z;
        }
    }
    return(0);
}

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
 * @brief Sum for an integer array
 * 
 * @return Sum of integers array
 */
int mf_sum_signed(int x[], size_t N)
{
    int sum = x[0];
    for (size_t i = 1; i < N; i++)
        sum += x[i];
    return (sum);
}
