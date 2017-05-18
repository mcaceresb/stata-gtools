// Quickselect is adapted from http://ideone.com/Bkaglb
// Note to self: You implemented this in mata once. The idea is:
//     - Choose a pivot
//     - Place data larger than the pivot in back
//     - Place data smaller in front
//     - Iterate until your pivot is in the kth position
//  Future implementations should consider a median of medians strategy,
//  which has worst-case performance O (n log n) instead of O(n^2), which
//  is the worst-case performance of quickselect.

#include "quickselect.h"

// double mf_quickselect (double *A, int left, int right, int k)
// {
//     // p is position of pivot in the partitioned array
//     int p = mf_quickselect_partition(A, left, right);
//
//     // k equals pivot; got lucky
//     if ( p == k - 1 ) {
//         return (A[p]);
//     }
//     // k less than pivot
//     else if ( k - 1 < p ) {
//         // right -= 1;
//         right = p - 1;
//         return (mf_quickselect(A, left, right, k));
//     }
//     // k greater than pivot
//     else {
//         // left += 1;
//         left = p + 1;
//         return (mf_quickselect(A, left, right, k));
//     }
// }

double mf_quickselect (double *A, int left, int right, int k)
{
    int p;
    while ( 1 ) {
        // If left and right are the same, we're done
        if ( left == right ) {
            return (A[left]);
        }

        // p is position of pivot in the partitioned array
        p = mf_quickselect_partition(A, left, right);

        // If the pivot is what we want, also done
        if ( p == k - 1 ) {
            return (A[p]);
        }
        // k less than pivot
        else if ( k - 1 < p ) {
            right = p - 1;
        }
        // k greater than pivot
        else {
            left  = p + 1;
        }
    }
}

int mf_quickselect_partition (double *A, int left, int right)
{
    int i = left, x;
    double pivot = A[right];
    for (x = left; x < right; x++){
        if (A[x] <= pivot) {
            _mf_swap (&A[i], &A[x]);
            i++;
        }
    }
    _mf_swap (&A[i], &A[right]);
    return (i);
}

void _mf_swap (double *a, double *b)
{
    double temp = *a;
    *a = *b;
    *b = temp;
}
