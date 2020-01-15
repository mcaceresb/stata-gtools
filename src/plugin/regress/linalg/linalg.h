#ifndef GREGRESS_LINALG
#define GREGRESS_LINALG

// Various Inverses
// ----------------

ST_double gf_regress_linalg_dsysv (ST_double *A, GT_size K, GT_bool *singular);

void gf_regress_linalg_dtrsv_colmajor       (ST_double *A, ST_double *B, GT_size N);
void gf_regress_linalg_dtrsvT_colmajor      (ST_double *A, ST_double *B, GT_size N);
void gf_regress_linalg_dtrsv_norm_colmajor  (ST_double *A, ST_double *B, GT_size N);
void gf_regress_linalg_dtrsvT_norm_colmajor (ST_double *A, ST_double *B, GT_size N);
void gf_regress_linalg_dtrans_colmajor      (ST_double *A, ST_double *B, GT_size k1, GT_size k2);

// Decompositions
// --------------

void gf_regress_printf_colmajor (ST_double *matrix, GT_size k1, GT_size k2, char *name);
void gf_regress_linalg_dsyqr    (ST_double *A, GT_size N, ST_double *QR, GT_size *colix, GT_bool *singular);
void gf_regress_linalg_dsylu    (ST_double *A, GT_size N, ST_double *QR, GT_size *colix, GT_bool *singular);
void gf_regress_linalg_dsyldu   (ST_double *A, GT_size N, ST_double *QR, GT_size *colix, GT_bool *singular);
void gf_regress_linalg_dsyhh    (ST_double *a, GT_size N, GT_size offset, ST_double *H);

ST_double gf_regress_linalg_ddot  (ST_double *a, GT_size N);
ST_double gf_regress_linalg_dnorm (ST_double *a, GT_size N);

// Naming convention _tries_ to follow BLAS notation
//
// https://www.gnu.org/software/gsl/doc/html/blas.html

// Column-major order!
// -------------------

void gf_regress_linalg_dgemm_colmajor     (ST_double *A, ST_double *B, ST_double *C, GT_size k1,   GT_size k2, GT_size k3);
void gf_regress_linalg_dsymm_colmajor     (ST_double *A, ST_double *B, ST_double *C, GT_size N,    GT_size K);
void gf_regress_linalg_dgemTv_colmajor    (ST_double *A, ST_double *b, ST_double *c, GT_size N,    GT_size K);
void gf_regress_linalg_dgemTm_colmajor    (ST_double *A, ST_double *B, ST_double *C, GT_size N,    GT_size k1, GT_size k2);
void gf_regress_linalg_dgemv_colmajor     (ST_double *A, ST_double *b, ST_double *c, GT_size N,    GT_size K);
void gf_regress_linalg_error_colmajor     (ST_double *y, ST_double *A, ST_double *b, ST_double *c, GT_size N,  GT_size K);

void gf_regress_linalg_dgemm_wcolmajor    (ST_double *A, ST_double *B, ST_double *C, ST_double *w, GT_size k1,   GT_size k2, GT_size k3);
void gf_regress_linalg_dsymm_wcolmajor    (ST_double *A, ST_double *B, ST_double *C, ST_double *w, GT_size N,    GT_size K);
void gf_regress_linalg_dsymm_w2colmajor   (ST_double *A, ST_double *B, ST_double *C, ST_double *w, GT_size N,    GT_size K);
void gf_regress_linalg_dsymm_we2colmajor  (ST_double *A, ST_double *B, ST_double *C, ST_double *e, ST_double *w, GT_size N,  GT_size K);
void gf_regress_linalg_dsymm_fwe2colmajor (ST_double *A, ST_double *B, ST_double *C, ST_double *e, ST_double *w, GT_size N,  GT_size K);
void gf_regress_linalg_dgemTv_wcolmajor   (ST_double *A, ST_double *b, ST_double *c, ST_double *w, GT_size N,    GT_size K);
void gf_regress_linalg_dgemTm_wcolmajor   (ST_double *A, ST_double *B, ST_double *C, ST_double *w, GT_size N,    GT_size k1, GT_size k2);
void gf_regress_linalg_error_wcolmajor    (ST_double *y, ST_double *A, ST_double *b, ST_double *w, ST_double *c, GT_size N,  GT_size K);

// Column-major order with index!
// ------------------------------

void gf_regress_linalg_dsymm_w2colmajor_ix   (ST_double *A, ST_double *B, ST_double *C,               ST_double *w, GT_size *colix, GT_size N, GT_size K);
void gf_regress_linalg_dsymm_we2colmajor_ix  (ST_double *A, ST_double *B, ST_double *C, ST_double *e, ST_double *w, GT_size *colix, GT_size N, GT_size K);
void gf_regress_linalg_dsymm_fwe2colmajor_ix (ST_double *A, ST_double *B, ST_double *C, ST_double *e, ST_double *w, GT_size *colix, GT_size N, GT_size K);

void gf_regress_linalg_dgemTv_colmajor_ix1   (ST_double *A, ST_double *b, ST_double *c, GT_size *colix, GT_size N, GT_size K);
void gf_regress_linalg_dgemTv_colmajor_ix2   (ST_double *A, ST_double *b, ST_double *c, GT_size *colix, GT_size N, GT_size K);

void gf_regress_linalg_dgemTv_wcolmajor_ix1  (ST_double *A, ST_double *b, ST_double *c, ST_double *w, GT_size *colix, GT_size N, GT_size K);
void gf_regress_linalg_dgemTv_wcolmajor_ix2  (ST_double *A, ST_double *b, ST_double *c, ST_double *w, GT_size *colix, GT_size N, GT_size K);

void gf_regress_linalg_dgemm_colmajor_ix1    (ST_double *A, ST_double *B, ST_double *C,               GT_size *colix, GT_size k1, GT_size k2, GT_size k3);
void gf_regress_linalg_dgemTm_colmajor_ix1   (ST_double *A, ST_double *B, ST_double *C,               GT_size *colix, GT_size N,  GT_size k1, GT_size k2);
void gf_regress_linalg_dgemTm_wcolmajor_ix1  (ST_double *A, ST_double *B, ST_double *C, ST_double *w, GT_size *colix, GT_size N,  GT_size k1, GT_size k2);

void gf_regress_linalg_error_colmajor_ix     (ST_double *y, ST_double *A, ST_double *b,               ST_double *c, GT_size *colix, GT_size N, GT_size K);
void gf_regress_linalg_error_wcolmajor_ix    (ST_double *y, ST_double *A, ST_double *b, ST_double *w, ST_double *c, GT_size *colix, GT_size N, GT_size K);

// Row-major order!
// ----------------

void gf_regress_linalg_dsymm_rowmajor   (ST_double *A, ST_double *B, ST_double *C, GT_size N,    GT_size K);
void gf_regress_linalg_dsymm_ixrowmajor (ST_double *A, ST_double *B, ST_double *C, GT_size *ix,  GT_size N,  GT_size K);
void gf_regress_linalg_dsymm_wrowmajor  (ST_double *A, ST_double *B, ST_double *C, ST_double *w, GT_size N,  GT_size K);

#endif
