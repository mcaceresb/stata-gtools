// Adapted from: http://stackoverflow.com/questions/42077009

#define SWAP(a, b)       \
do {                     \
    typeof (a) _a = (a); \
    (a) = (b);           \
    (b) = _a;            \
} while(0)

double mf_qselect_range (double *x, size_t start, size_t end, size_t k);
void mf_qselect_range_partition (double *x, size_t start, size_t end, size_t *less_size, size_t *equal_size);

double mf_qselect_range(double *x, size_t start, size_t end, size_t k)
{
    if ( (end - start) == 1 ) {
        return (x[start]);
    }

    size_t less_size;
    size_t equal_size;

    mf_qselect_range_partition (x, start, end, &less_size, &equal_size);

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

    return (mf_qselect_range(x, start, end, k));
}

void mf_qselect_range_partition(double *x, size_t start, size_t end, size_t *less_size, size_t *equal_size)
{

    // Modified median-of-three and pivot selection.
    size_t nj     = end - start;
    size_t first  = start;
    size_t middle = start + floor(nj / 2);
    size_t last   = end - 1 ;

    if ( x[first] > x[last]) {
        SWAP(x[first], x[last]);
    }
    if ( x[first] > x[middle] ) {
        SWAP(x[first], x[middle]);
    }
    if ( x[last] > x[middle] ) {
        SWAP(x[last], x[middle]);
    }
    const double pivot_value = x[last];

    // Element swapping
    size_t greater_idx = 0;
    size_t equal_idx   = nj - 1;
    size_t i = 0;
    while ( i < equal_idx ) {
        const double elem_value = x[start + i];

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
