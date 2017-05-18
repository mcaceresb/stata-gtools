#ifndef QUICKSELECT
#define QUICKSELECT

// double mf_quickselect (double *A, int left, int right, int k);
double mf_quickselect (double *A, int left, int right, int k);
int mf_quickselect_partition (double *A, int left, int right);
void _mf_swap (double *a, double *b);

#endif
