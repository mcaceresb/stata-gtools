#include "gtools_utils.h"

/**
 * @brief Benchmark I/O
 *
 * @return Time to read/write 1MiB to disk
 */
ST_double gf_benchmark (char *fname)
{
    GT_size k, j;
    GT_size KiB  = 1024;
    GT_size k1   = 2;
    GT_size k2   = 4;
    GT_size kw   = k2 - k1;
    GT_size J    = 64 * KiB;
    srand (time(NULL));

    ST_double *A = malloc(J * k2 * sizeof(ST_double));
    ST_double *B = malloc(J * kw * sizeof(ST_double));
    for (j = 0; j < J; j++) {
        for (k = 0; k < k2; k++)
            A[k2 * j + k] = (ST_double) rand() / RAND_MAX;
    }

    clock_t timer = clock(); ST_double iops;
    gf_write_collapsed (fname, A, k1, k2, J);
    gf_read_collapsed (fname, B, kw, J);
    iops = (ST_double) (clock() - timer) / CLOCKS_PER_SEC;

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
void gf_write_collapsed(
    char *collapsed_file,
    ST_double *collapsed_data,
    GT_size kstart,
    GT_size kend,
    GT_size J)
{
    GT_size j;
    GT_size knum = kend - kstart;
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
void gf_read_collapsed(
    char *collapsed_file,
    ST_double *collapsed_data,
    GT_size knum,
    GT_size J)
{
    FILE *collapsed_handle = fopen(collapsed_file, "rb");
    GT_size ret = fread (collapsed_data, sizeof(collapsed_data), knum * J, collapsed_handle);
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
void gf_split_path_file(char** p, char** f, char *pf) {
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
ST_double gf_query_free_space (char *fname)
{
    struct statvfs finfo;
    char *filepath = malloc((strlen(fname) + 1) * sizeof(char));
    char *filename = malloc((strlen(fname) + 1) * sizeof(char));
    memset (filepath, '\0', (strlen(fname) + 1) * sizeof(char));
    memset (filename, '\0', (strlen(fname) + 1) * sizeof(char));

    // char rpath [PATH_MAX+1];
    // char *rc = realpath (fname, rpath);
    // gf_split_path_file (&filepath, &filename, rpath);
    gf_split_path_file (&filepath, &filename, fname);
    statvfs (filepath, &finfo);
    ST_double mib_free = ((ST_double) finfo.f_bsize * finfo.f_bfree) / 1024 / 1024;

    free (filepath);
    free (filename);

    return (mib_free);
}
