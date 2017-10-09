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
    int min = x[0]; size_t i;
    for (i = 1; i < N; ++i) {
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
    int max = x[0]; size_t i;
    for (i = 1; i < N; ++i) {
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
    uint64_t min = x[0]; size_t i;
    for (i = 1; i < N; ++i) {
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
    uint64_t max = x[0]; size_t i;
    for (i = 1; i < N; ++i) {
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
    *min = *max = x[0]; size_t i;
    for (i = 1; i < N; ++i) {
        if (*min > x[i]) *min = x[i];
        if (*max < x[i]) *max = x[i];
    }
}

/*
 * @brief Minimum for unsigned integer array
 *
 * @param x vector of integers to get the min
 * @param N number of elements in @x
 * @return Smallest integer in @x
 */
size_t mf_min_unsigned(size_t x[], size_t N)
{
    size_t min = x[0]; size_t i;
    for (i = 1; i < N; ++i) {
        if (min > x[i]) min = x[i];
    }
    return (min);
}

/**
 * @brief Maximum for unsigned integer array
 *
 * @param x vector of integers to get the max
 * @param N number of elements in @x
 * @return Smallest integer in @x
 */
size_t mf_max_unsigned(size_t x[], size_t N)
{
    size_t max = x[0]; size_t i;
    for (i = 1; i < N; ++i) {
        if (max < x[i]) max = x[i];
    }
    return (max);
}

/**
 * @brief Sum for an unsigned array
 *
 * @return Sum of unsigned array
 */
size_t mf_sum_unsigned(size_t x[], size_t N)
{
    size_t sum = x[0]; size_t i;
    for (i = 1; i < N; i++)
        sum += x[i];
    return (sum);
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
 * @brief Sum for an integer array
 *
 * @return Sum of integers array
 */
int mf_sum_signed(int x[], size_t N)
{
    int sum = x[0]; size_t i;
    for (i = 1; i < N; i++)
        sum += x[i];
    return (sum);
}

/**
 * @brief Benchmark I/O
 *
 * @return Time to read/write 1MiB to disk
 */
double mf_benchmark (char *fname)
{
    int k, j;
    size_t KiB  = 1024;
    size_t k1   = 2;
    size_t k2   = 4;
    size_t kw   = k2 - k1;
    size_t J    = 64 * KiB;
    srand (time(NULL));

    double *A = malloc(J * k2 * sizeof(double));
    double *B = malloc(J * kw * sizeof(double));
    for (j = 0; j < J; j++) {
        for (k = 0; k < k2; k++)
            A[k2 * j + k] = (double) rand() / RAND_MAX;
    }

    clock_t timer = clock(); double iops;
    mf_write_collapsed (fname, A, k1, k2, J);
    mf_read_collapsed (fname, B, kw, J);
    iops = (double) (clock() - timer) / CLOCKS_PER_SEC;

    for (j = 0; j < 20; j++) {
        for (k = 0; k < kw; k++)
            if ( A[k2 * j + k1 + k] != B[kw * j + k] ) return(-1);
    }

    free (A);
    free (B);

    return (iops);
}

/**
 * @brief Write collapsed summary stats to binary file
 *
 * Saves the collapsed data to file. The collapsed data is
 * in a manualy indexed vector using row-major order. So for
 * a J by k set of collapsed summary stats, we have
 *
 *     [(0, 0) (0, 1) ... (0, k) (1, 0) ... (J, 0) ... (J, k)]
 *
 * And we save 0 to @J from @kstart to @kend in each row.
 *
 * @param collapsed_file File where to save collapsed stats
 * @param collapsed_data Vector of doubles with collapsed stats
 * @param kstart First position of data in each row.
 * @param kend Last position of data in each row.
 * @param J Number of rows.
 * @return Writes @collapsed_data to disk.
 */
void mf_write_collapsed(
    char *collapsed_file,
    double *collapsed_data,
    size_t kstart,
    size_t kend,
    size_t J)
{
    int j;
    size_t knum = kend - kstart;
    FILE *collapsed_handle = fopen(collapsed_file, "wb");
    for (j = 0; j < J; j++) {
        fwrite (collapsed_data + j * kend + kstart, sizeof(collapsed_data), knum, collapsed_handle);
    }
    fclose(collapsed_handle);
}

/**
 * @brief Read collapsed summary stats from binary file
 *
 * Reads collapsed data from file. The collapsed data is
 * in a manualy indexed vector using row-major order. So for
 * a J by k set of collapsed summary stats, we have
 *
 *     [(0, 0) (0, 1) ... (0, k) (1, 0) ... (J, 0) ... (J, k)]
 *
 * And we read @knum entries for @J rows.
 *
 * @param collapsed_file File where to save collapsed stats
 * @param collapsed_data Vector of doubles with collapsed stats
 * @param knum Number of entries in each row.
 * @param J Number of rows.
 * @return Reads @collapsed_data from disk.
 */
void mf_read_collapsed(
    char *collapsed_file,
    double *collapsed_data,
    size_t knum,
    size_t J)
{
    FILE *collapsed_handle = fopen(collapsed_file, "rb");
    size_t ret = fread (collapsed_data, sizeof(collapsed_data), knum * J, collapsed_handle);
    if ( ret == 0 ) printf(" "); // So it doesn't nag about ret unused...
    fclose(collapsed_handle);
}

/**
 * @brief Read collapsed summary stats from binary file
 *
 * See https://stackoverflow.com/questions/1575278
 * function-to-split-a-filepath-into-path-and-file
 *
 * @param p malloc p to file path.
 * @param f malloc f to file name.
 * @param pf pf is pointer to path + file.
 * @return Splits @pf into @p path and @f file.
 */
void mf_split_path_file(char** p, char** f, char *pf) {
    char *slash = pf, *next;
    while ((next = strpbrk(slash + 1, "\\/"))) slash = next;
    if (pf != slash) slash++;
    *p = strndup(pf, slash - pf);
    *f = strdup(slash);
}

/**
 * @brief Query free space on root path of fname (MiB)
 *
 * @param fname (relative) path to file
 * @return Returns free space in path to @fname in MiB
 */
double mf_query_free_space (char *fname)
{
    struct statvfs finfo;
    char *filepath = malloc((strlen(fname) + 1) * sizeof(char));
    char *filename = malloc((strlen(fname) + 1) * sizeof(char));
    memset (filepath, '\0', (strlen(fname) + 1));
    memset (filename, '\0', (strlen(fname) + 1));

    // char rpath [PATH_MAX+1];
    // char *rc = realpath (fname, rpath);
    // mf_split_path_file (&filepath, &filename, rpath);
    mf_split_path_file (&filepath, &filename, fname);
    statvfs (filepath, &finfo);
    double mib_free = ((double) finfo.f_bsize * finfo.f_bfree) / 1024 / 1024;

    free (filepath);
    free (filename);

    return (mib_free);
}

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

/*********************************************************************
 *                          Stata utilities                          *
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

    int i;
    int ncol = SF_col(st_matrix);
    int nrow = SF_row(st_matrix);
    if ( (ncol > 1) & (nrow > 1) ) {
        sf_errprintf("tried to read a %d by %d matrix into an array\n", nrow, ncol);
        return(198);
    }
    if ( ncol > 1 ) {
        for (i = 0; i < ncol; i++) {
            if ( (rc = SF_mat_el(st_matrix, 1, i + 1, &z)) ) return(rc);
            v[i] = z;
        }
    }
    else {
        for (i = 0; i < nrow; i++) {
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
 * @brief Check if variable requested is integer in disguise
 *
 * @return Stores __gtools_is_int in Stata with result
 */
int sf_isint()
{
    ST_retcode rc ;
    ST_double  z ;
    size_t i;

    for (i = SF_in1(); i <= SF_in2(); i++) {
        if ( (rc = SF_vdata(1, i, &z)) ) return (rc);
        if ( ceilf(z) == z ) continue;
        else {
            if ( (rc = SF_scal_save ("__gtools_is_int", (double) 0)) ) return (rc);
            sf_printf ("(not an integer)\n");
            return (0);
        }
    }

    if ( (rc = SF_scal_save ("__gtools_is_int", (double) 1)) ) return (rc);
    sf_printf ("(an integer in disguise!)\n");
    return(0);
}
