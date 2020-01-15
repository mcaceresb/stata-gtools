/**
 * @brief Computes the transpose of a matrix B = A'
 *
 * @A k1 x k2 matrix to be transposed
 * @B k2 x k1 transpose of A
 * @k1 Number of rows in A
 * @k2 Number of columns in A
 * @return Store A' in @B
 */
void gf_regress_linalg_dtrans_colmajor (ST_double *A, ST_double *B, GT_size k1, GT_size k2)
{
    GT_size i, j;
    for (j = 0; j < k2; j++) {
        for (i = 0; i < k1; i++) {
            B[j * k2 + i] = A[i * k2 + j];
        }
    }
}

/**
 * @brief Print matrix A
 *
 * @A k1 x k2 matrix to be printed
 * @k1 Number of rows in A
 * @k2 Number of columns in A
 * @return Prints entries of matrix A
 */
void gf_regress_printf_colmajor (
    ST_double *matrix,
    GT_size k1,
    GT_size k2,
    char *name)
{
    GT_size i, j;
    sf_printf_debug("%s\n", name);
    for (j = 0; j < k2; j++) {
        for (i = 0; i < k1; i++) {
            sf_printf_debug("%9.4f\t", matrix[j + k2 * i]);
        }
            sf_printf_debug("\n");
    }
            sf_printf_debug("\n");
}
