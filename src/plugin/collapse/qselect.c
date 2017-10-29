// Adapted from: http://stackoverflow.com/questions/42077009

#define SWAP(a, b)       \
do {                     \
    typeof (a) _a = (a); \
    (a) = (b);           \
    (b) = _a;            \
} while(0)

ST_double gf_qselect_range (ST_double *x, GT_size start, GT_size end, GT_size k);
void gf_qselect_range_partition (ST_double *x, GT_size start, GT_size end, GT_size *less_size, GT_size *equal_size);

ST_double gf_qselect_range(ST_double *x, GT_size start, GT_size end, GT_size k)
{
    if ( (end - start) == 1 ) {
        return (x[start]);
    }

    GT_size less_size;
    GT_size equal_size;

    gf_qselect_range_partition (x, start, end, &less_size, &equal_size);

    if ( k < less_size ) {
        // k lies in the less-than-pivot partition
        end = start + less_size;
    }
    else if ( k < less_size + equal_size ) {
        // k lies in the equals-to-pivot partition
        return x[end - 1];
    }
    else {
        // k lies in the greater-than-pivot partition
        start += less_size;
        end   -= equal_size;
        k     -= less_size + equal_size;
    }

    return (gf_qselect_range(x, start, end, k));
}

void gf_qselect_range_partition(ST_double *x, GT_size start, GT_size end, GT_size *less_size, GT_size *equal_size)
{

    // Modified median-of-three and pivot selection.
    GT_size nj     = end - start;
    GT_size first  = start;
    GT_size middle = start + floor(nj / 2);
    GT_size last   = end - 1 ;

    if ( x[first] > x[last]) {
        SWAP(x[first], x[last]);
    }
    if ( x[first] > x[middle] ) {
        SWAP(x[first], x[middle]);
    }
    if ( x[last] > x[middle] ) {
        SWAP(x[last], x[middle]);
    }
    const ST_double pivot_value = x[last];

    // Element swapping
    GT_size greater_idx = 0;
    GT_size equal_idx   = nj - 1;
    GT_size i = 0;
    while ( i < equal_idx ) {
        const ST_double elem_value = x[start + i];

        if ( elem_value < pivot_value ) {
            SWAP(x[start + greater_idx], x[start + i]);
            greater_idx++;
            i++;
        }
        else if ( elem_value == pivot_value ) {
            equal_idx--;
            SWAP(x[start + i], x[start + equal_idx]);
        }
        else { // elem_value > pivot_value
            i++;
        }
    }

    *less_size  = greater_idx;
    *equal_size = nj - equal_idx;
}
