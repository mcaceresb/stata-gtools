#ifndef ST_GSLTOOLS
#define ST_GSLTOOLS

void sf_gsl_csort(gsl_vector * g);

void sf_gsl_vector_set_index (gsl_vector * x, const gsl_vector * index, double y);
void sf_gsl_matrix_set_index (gsl_matrix * x, const gsl_vector * index, double y);

void sf_gsl_vapply(gsl_vector * x, const gsl_vector * v, double (*fun)(double));
void sf_gsl_mapply(gsl_matrix * x, const gsl_matrix * M, double (*fun)(double));

gsl_vector_view sf_gsl_panelsubvector(gsl_vector * v, int i, const gsl_matrix * info);
gsl_matrix_view sf_gsl_panelsubmatrix(gsl_matrix * M, int i, const gsl_matrix * info);


int sf_gsl_get_variable(gsl_vector * v, size_t k, size_t in1, size_t in2, int getif);
int sf_gsl_set_variable(gsl_vector * v, size_t k, size_t in1, size_t in2, int setif);

int sf_gsl_get_varlist(gsl_matrix * M, size_t k1, size_t k2, size_t in1, size_t in2, int getif);
int sf_gsl_set_varlist(gsl_matrix * M, size_t k1, size_t k2, size_t in1, size_t in2, int getif);


int sf_gsl_get_vector(char * st_matrix, gsl_vector * v, int byrow);
int sf_gsl_get_matrix(char * st_matrix, gsl_matrix * M);

void sf_gsl_printf_vector(const char * fmt, const gsl_vector * v);
void sf_gsl_printf_matrix(const char * fmt, const gsl_matrix * M);

#endif
