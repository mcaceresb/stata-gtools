/**
 * @file st_gsltools.c
 * @version 0.2.0
 * @author Mauricio Caceres Bravo
 * @email <mauricio.caceres.bravo@gmail.com>
 * @date 20 Apr 2017
 * @brief Utility functions for Stata plugins to interact with the GNU Scientific Library (GSL)
 *
 * These are various wrappers to make it easier for Stata to interact
 * with the GNU Scientific Library and I have found them useful when
 * writing Stata plugins.
 *
 * Note because functions are for use by Stata C-based plugins they
 * must be used in conjunction with stplugin.c and stplugin.h (see
 * stata.com/plugins for more on Stata plugins). In particular, both
 * should exist in the same directory and your main file should have
 *
 *     #include "stplugin.h"
 *
 * as one of its include statements. Further note the printf functions
 * provided by this file depend on the more low-level print functions
 * defined in st_gentools.c.
 *
 *
 * @see st_gentools.c
 * @see http://www.stata.com/plugins for more on Stata plugins
 */

#include "st_gsltools.h"
#include "st_gentools.c"

/**
 * @brief Counting sort for GSL vector
 *
 * This only works if elements of G are natural numbers
 *
 * @param g vector of integers to sort
 * @return stable sorted @g
 */
void sf_gsl_csort(gsl_vector * g)
{
    const int N     = g->size;
    const int max   = gsl_vector_max(g);
    const int min   = gsl_vector_min(g);
    const int range = max - min + 1;

    gsl_vector * scratch = gsl_vector_alloc(N);
    gsl_vector_memcpy (scratch, g);

    int i, c; int count[range + 1];

    // Initialize to 0
    for (i = 0; i <= range; i++)
        count[i] = 0;

    // Set count[i]] to sum(x == i + min - 1) (pdf)
    for (i = 0; i < N; i++)
        count[c = gsl_vector_get(scratch, i) + 1 - min]++;

    // Running sum (cdf)
    for (i = 1; i < range; i++)
        count[i] += count[i - 1];

    // Copy back elements in stable sorted order
    for (i = 0; i < N; i++) {
        // Set ith entry in count[c - min]th position
        c = gsl_vector_get(scratch, i);
        // Increment count[c - min] to position of next element with same vaue
        gsl_vector_set(g, count[c - min]++, c);
    }

    gsl_vector_free (scratch);
}

/**
 * @brief Wrapper to apply scalar function to each vector element
 *
 * This only works for functions whose input and output is double
 *
 * @param x where to store the results; should be same shape as @v
 * @param v vector to apply the transformation to
 * @param fun function to apply to each element of @v
 * @return @x = @fun(@v)
 */
void sf_gsl_vapply(gsl_vector * x, const gsl_vector * v, double (*fun)(double)) {
    for (int i = 0; i < v->size; i++) {
        gsl_vector_set (x, i, (*fun)(gsl_vector_get(v, i)));
    }
}

/**
 * @brief Wrapper to apply scalar function to each matrix element
 *
 * This only works for functions whose input and output is double
 *
 * @param x where to store the results; should be same shape as @M
 * @param M matrix to apply the transformation to
 * @param fun function to apply to each element of @M
 * @return @x = @fun(@M)
 */
void sf_gsl_mapply(gsl_matrix * x, const gsl_matrix * M, double (*fun)(double)) {
    for (int i = 0; i < M->size1; i++) {
        for (int j = 0; j < M->size2; j++) {
            gsl_matrix_set (x, i, j, (*fun)(gsl_matrix_get(M, i, j)));
        }
    }
}

/**
 * @brief Wrapper to set vector elements according to an index
 *
 * Set the elements of x to y where index > 0
 *
 * @param x whose elements to set to y
 * @param index vector that indexes elements of x (<= 0, > 0)
 * @param y value for elements of x to swap
 * @return @x[@index] = @y
 */
void sf_gsl_vector_set_index (gsl_vector * x, const gsl_vector * index, double y)
{
    for (int i = 0; i < index->size; i++) {
        if ( gsl_vector_get (index, i) > 0.0 ) gsl_vector_set (x, i, y);
    }
}

/**
 * @brief Wrapper to set matrix elements according to an index
 *
 * Set the elements of x to y where index > 0
 *
 * @param x whose elements to set to y
 * @param index vector that indexes elements of x (<= 0, > 0)
 * @param y value for elements of x to swap
 * @return @x[@index, ] = @y
 */
void sf_gsl_matrix_set_index (gsl_matrix * x, const gsl_vector * index, double y)
{
    for (int i = 0; i < x->size1; i++) {
        if ( gsl_vector_get (index, i) > 0.0 ) {
            for (int j = 0; j < x->size2; j++) {
                gsl_matrix_set (x, i, j, y);
            }
        }
    }
}

/**
 * @brief Get subvector view using info
 *
 * This mirrors Stata's mata function panelsubmatrix for working
 * with by groups. @info is a J x 2 matrix, where J is the number of
 * groups, containing in the ith row the position of the first and last
 * observation corresponding to the ith group in the data. Since Stata
 * counts data from row 1, we subtract 1 when using info to construct
 * GSL vector views.
 *
 * @param v GSL vector to get a view from
 * @param i Group to subset
 * @param info Information matrix containing the position of @i in @v
 * @return gsl_vector_view into the range containing the @i group
 */
gsl_vector_view sf_gsl_panelsubvector(gsl_vector * v, int i, const gsl_matrix * info)
{
    gsl_vector * info_i = gsl_vector_alloc (2);
    gsl_matrix_get_row (info_i, info, i);
    size_t in1 = gsl_vector_get(info_i, 0) - 1;
    size_t in2 = gsl_vector_get(info_i, 1) - in1;
    gsl_vector_free (info_i);
    return(gsl_vector_subvector(v, in1, in2));
}

/**
 * @brief Get submatrix view using info
 *
 * This mirrors Stata's mata function panelsubmatrix for working
 * with by groups. @info is a J x 2 matrix, where J is the number of
 * groups, containing in the ith row the position of the first and last
 * observation corresponding to the ith group in the data. Since Stata
 * counts data from row 1, we subtract 1 when using info to construct
 * GSL matrix views.
 *
 * @param v GSL matrix to get a view from
 * @param i Group to subset
 * @param info Information matrix containing the position of @i in @v
 * @return gsl_matrix_view into the range containing the @i group
 */
gsl_matrix_view sf_gsl_panelsubmatrix(gsl_matrix * M, int i, const gsl_matrix * info)
{
    gsl_vector * info_i = gsl_vector_alloc (2);
    gsl_matrix_get_row (info_i, info, i);
    size_t in1 = gsl_vector_get(info_i, 0) - 1;
    size_t in2 = gsl_vector_get(info_i, 1) - in1;
    size_t k   = M->size2;
    gsl_vector_free (info_i);
    return(gsl_matrix_submatrix(M, in1, 0, in2, k));
}

/**
 * @brief Parse variable into vector from Stata
 *
 * Loop through a variable's observations and parse it into a GSL
 * vector. If the plugin was called as
 *
 *     plugin call myplugin varlist `if' `in'
 *
 * Then the function can be used as
 *
 *     sf_gsl_get_variable (v, k, SF_in1(), SF_in2(), 1)
 *
 * However, the if and in statements can be ignored; if the data has
 * N observations, simply use
 *
 *     sf_gsl_get_variable (v, k, 1, N, 0)
 *
 * The two uses are equivalent when the plugin call is simply
 *
 *     plugin call myplugin varlist
 *
 * @v must be the length of the number of observations marked by `if'
 * `in' or of size N in case they are ignored/not used.
 *
 * @param v GSL vector to save into.
 * @param k Position of variable in varlist passed to C
 * @param in1 First observation to be read
 * @param in2 Last observation to be read
 * @param getif Whether to only get observations marked by `if' in Stata
 * @return Copies @k variable into @v
 *
 * @see sf_gsl_set_variable, sf_gsl_set_varlist, sf_gsl_get_varlist
 */
int sf_gsl_get_variable(gsl_vector * v, size_t k, size_t in1, size_t in2, int getif)
{
    ST_retcode rc ;
    ST_double  z ;
    int l = 0;
    if ( in2 < in1 ) {
        sf_errprintf("data ending position %d < starting position %d", in2, in1);
        return(198);
    }
    if ( getif ) {
        for (int i = in1; i <= in2; i++) {
            // Get only on rows marked by `if'
            if (SF_ifobs(i)) {
                if ( (rc = SF_vdata(k, i, &z)) ) return(rc);
                gsl_vector_set (v, l, z);
                l++;
            }
        }
    }
    else {
        // Get data on every row from in1 to in2 regardless of `if'; in
        // case the plugin was not called with an `if' statement this is
        // equivalent to the above.
        for (int i = in1; i <= in2; i++) {
            if ( (rc = SF_vdata(k, i, &z)) ) return(rc);
            gsl_vector_set (v, i - in1, z);
        }
    }
    return(0);
}

/**
 * @brief Parse variable into Stata from GSL vector
 *
 * Loop through a vector and save it into a existing Stata variable.
 * If the plugin was called as
 *
 *     plugin call myplugin varlist `if' `in'
 *
 * Then the function can be used as
 *
 *     sf_gsl_set_variable (v, k, SF_in1(), SF_in2(), 1)
 *
 * However, the if and in statements can be ignored; if the data has
 * N observations, simply use
 *
 *     sf_gsl_set_variable (v, k, 1, N, 0)
 *
 * The two uses are equivalent when the plugin call is simply
 *
 *     plugin call myplugin varlist
 *
 * @param v GSL vector to save in Stata; must be of length @in2 - @in1 + 1
 * @param k Position of variable in varlist passed to C
 * @param in1 First observation to be read
 * @param in2 Last observation to be read
 * @param setif Whether to save only observations marked by `if' in Stata
 * @return Copies @v into @k variable
 *
 * @see sf_gsl_get_variable, sf_gsl_set_varlist, sf_gsl_get_varlist
 */
int sf_gsl_set_variable(gsl_vector * v, size_t k, size_t in1, size_t in2, int setif)
{
    ST_retcode rc ;
    if ( in2 < in1 ) {
        sf_errprintf("data ending position %d < starting position %d", in2, in1);
        return(198);
    }
    size_t nobs = in2 - in1 + 1;
    if ( v->size !=  nobs ) {
        sf_errprintf("vector length %d not equal to requested data length %d.", v->size, nobs);
        return(200);
    }
    if ( setif ) {
        // Save only on rows marked by `if'
        for (int i = in1; i <= in2; i++) {
            if ( SF_ifobs(i) ) {
                if ( (rc = SF_vstore(k, i, gsl_vector_get (v, i - in1))) ) {
                    return(rc);
                }
            }
        }
    }
    else {
        // Save on every row from in1 to in2 regardless of `if'; in case
        // the plugin was not called with an `if' statement this is
        // equivalent to the above.
        for (int i = in1; i <= in2; i++) {
            if ( (rc = SF_vstore(k, i, gsl_vector_get (v, i - in1))) ) {
                return(rc);
            }
        }
    }
    return(0);
}

/**
 * @brief Parse varlist into matrix from Stata
 *
 * Loop through a set of variables' observations and parse it into a GSL
 * matrix. If the plugin was called as
 *
 *     plugin call myplugin varlist `if' `in'
 *
 * Then the function can be used as
 *
 *     sf_gsl_get_varlist (M, k1, k2, SF_in1(), SF_in2(), 1)
 *
 * However, the if and in statements can be ignored; if the data has
 * N observations, simply use
 *
 *     sf_gsl_get_varlist (M, k1, k2, 1, N, 0)
 *
 * The two uses are equivalent when the plugin call is simply
 *
 *     plugin call myplugin varlist
 *
 * @M must be the length of the number of observations marked by `if'
 * `in' or of size N in case they are ignored/not used.
 *
 * @param M GSL matrix to save into
 * @param k1 First variable in varlist passed to C
 * @param k2 Last variable in varlist passed to C
 * @param in1 First observation to be read
 * @param in2 Last observation to be read
 * @param getif Whether to only get observations marked by `if' in Stata
 * @return Copies variables @k1 to @k2 into @M
 *
 * @see sf_gsl_get_variable, sf_gsl_set_variable, sf_gsl_set_varlist
 */
int sf_gsl_get_varlist(gsl_matrix * M, size_t k1, size_t k2, size_t in1, size_t in2, int getif)
{
    ST_retcode rc ;
    ST_double  z ;
    int l = 0;
    if ( in2 < in1 ) {
        sf_errprintf("data ending position %d < starting position %d", in2, in1);
        return(198);
    }
    if ( k2 < k1 ) {
        sf_errprintf("varlist ending position %d < starting position %d", k2, k1);
        return(198);
    }
    if ( getif ) {
        // Get only on rows marked by `if'
        for (int i = in1; i <= in2; i++) {
            if (SF_ifobs(i)) {
                for (int j = k1; j <= k2; j++) {
                    if ( (rc = SF_vdata(j, i, &z)) ) return(rc);
                    gsl_matrix_set (M, l, j - k1, z);
                }
                l++;
            }
        }
    }
    else {
        // Get data on every row from in1 to in2 regardless of `if'; in
        // case the plugin was not called with an `if' statement this is
        // equivalent to the above.
        for (int i = in1; i <= in2; i++) {
            for (int j = k1; j <= k2; j++) {
                if ( (rc = SF_vdata(j, i, &z)) ) return(rc);
                gsl_matrix_set (M, i - in1, j - k1, z);
            }
        }
    }
    return(0);
}

/**
 * @brief Parse GSL matrix into Stata varlist
 *
 * Loop through a set of matrix observations and save it into a Stata
 * varlist. If the plugin was called as
 *
 *     plugin call myplugin varlist `if' `in'
 *
 * Then the function can be used as
 *
 *     sf_gsl_set_varlist (M, k1, k2, SF_in1(), SF_in2(), 1)
 *
 * However, the if and in statements can be ignored; if the data has
 * N observations, simply use
 *
 *     sf_gsl_set_varlist (M, k1, k2, 1, N, 0)
 *
 * The two uses are equivalent when the plugin call is simply
 *
 *     plugin call myplugin varlist
 *
 * @M must be (in2 - in1 + 1) x (k2 - k1 + 1) the shape of the data that
 * it's being saved into.
 *
 * @param M GSL matrix to save into
 * @param k1 First variable in varlist passed to C
 * @param k2 Last variable in varlist passed to C
 * @param in1 First observation to be read
 * @param in2 Last observation to be read
 * @param getif Whether to only save observations marked by `if' in Stata
 * @return Copies matrix @M into variables @k1 to @k2
 *
 * @see sf_gsl_get_variable, sf_gsl_set_variable, sf_gsl_get_varlist
 */
int sf_gsl_set_varlist(gsl_matrix * M, size_t k1, size_t k2, size_t in1, size_t in2, int getif)
{
    ST_retcode rc ;
    if ( in2 < in1 ) {
        sf_errprintf("data ending position %d < starting position %d", in2, in1);
        return(198);
    }
    if ( k2 < k1 ) {
        sf_errprintf("varlist ending position %d < starting position %d", k2, k1);
        return(198);
    }
    size_t nobs  = in2 - in1 + 1;
    size_t nvars = k2  - k1  + 1;
    if ( M->size1 !=  nobs ) {
        sf_errprintf("matrix length %d not equal to requested data length %d.", M->size1, nobs);
        return(200);
    }
    if ( M->size2 !=  nvars ) {
        sf_errprintf("matrix width %d not equal to requested # variables %d.", M->size2, nvars);
        return(200);
    }
    if ( getif ) {
        // Save only on rows marked by `if'
        for (int i = in1; i <= in2; i++) {
            if (SF_ifobs(i)) {
                for (int k = k1; k <= k2; k++) {
                    if ( (rc = SF_vstore(k, i, gsl_matrix_get (M, i - in1, k - k1))) ) {
                        return(rc);
                    }
                }
            }
        }
    }
    else {
        // Save data on every row from in1 to in2 regardless of `if'; in
        // case the plugin was not called with an `if' statement this is
        // equivalent to the above.
        for (int i = in1; i <= in2; i++) {
            for (int k = k1; k <= k2; k++) {
                if ( (rc = SF_vstore(k, i, gsl_matrix_get (M, i - in1, k - k1))) ) {
                    return(rc);
                }
            }
        }
    }
    return(0);
}

/**
 * @brief Get column/row vector from Stata
 *
 * Loop through a column/row vector in Stata and save it in v
 * Stata does not have vectors and matrices, only matrices. So
 *
 *     matrix row = 1, 2, 3
 *
 * is a row vector and not the same as
 *
 *     matrix col = 1 \ 2 \ 3
 *
 * which is a column vector. We would read them as
 *
 *     sf_gsl_get_vector("row", v, 1)
 *     sf_gsl_get_vector("col", v, 0)
 *
 * @param st_matrix Name of Stata column/row vector
 * @param v GSL vector to save into
 * @param byrow Whether to get a rowvector (1) or column vector (0)
 * @return Copies vector @st_matrix into @v
 *
 * @see sf_gsl_get_matrix
 */
int sf_gsl_get_vector(char * st_matrix, gsl_vector * v, int byrow)
{
    ST_retcode rc ;
    ST_double  z ;
    if ( byrow ) {
        for (int i = 0; i < v->size; i++) {
            if ( (rc = SF_mat_el(st_matrix, 1, i + 1, &z)) ) return(rc);
            gsl_vector_set (v, i, z);
        }
    }
    else {
        for (int i = 0; i < v->size; i++) {
            if ( (rc = SF_mat_el(st_matrix, i + 1, 1, &z)) ) return(rc);
            gsl_vector_set (v, i, z);
        }
    }
    return(0);
}

/**
 * @brief Get matrix from Stata
 *
 * Loop through a matrix in Stata and save it in M
 *
 * @param st_matrix Name of Stata coumn vector
 * @param M GSL vector to save into
 * @return Copies vector @st_matrix into @M
 *
 * @see sf_gsl_get_vector
 */
int sf_gsl_get_matrix(char * st_matrix, gsl_matrix * M)
{
    ST_retcode rc ;
    ST_double  z ;
    for (int i = 0; i < M->size1; i++) {
        for (int j = 0; j < M->size2; j++) {
            if ( (rc = SF_mat_el(st_matrix, i + 1, j + 1, &z)) ) return(rc);
            gsl_matrix_set (M, i, j, z);
        }
    }
    return(0);
}

/**
 * @brief Print gsl vector into Stata
 *
 * @param v gsl vector to print
 * @param fmt printf format
 *
 * @see sf_gsl_printf_matrix
 */
void sf_gsl_printf_vector(const char * fmt, const gsl_vector * v)
{
    for (int i = 0; i < v->size; i++) {
        sf_printf(fmt, gsl_vector_get(v, i));
    }
}

/**
 * @brief Print gsl matrix into Stata (rows are ended with "\n")
 *
 * @param M gsl matrix to print
 * @param fmt printf format
 *
 * @see sf_gsl_printf_vector
 */
void sf_gsl_printf_matrix(const char * fmt, const gsl_matrix * M)
{
    for (int i = 0; i < M->size1; i++) {
        for (int j = 0; j < M->size2; j++) {
            sf_printf(fmt, gsl_matrix_get(M, i, j));
        }
        sf_printf("\n");
    }
}
