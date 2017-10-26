#include "gtools_utils.h"

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
