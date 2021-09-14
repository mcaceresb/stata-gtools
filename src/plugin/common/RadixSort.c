#include "RadixSortGeneric.c"
#include "RadixSortTyped.c"

#define RADIX_MINMAX(x, N, min, max, _i)     \
    typeof (*x) (min) = *x;                   \
    typeof (*x) (max) = *x;                   \
    for (_i = 1; _i < N; ++_i) {              \
        if (min > *(x + _i)) min = *(x + _i); \
        if (max < *(x + _i)) max = *(x + _i); \
    }                                         \

// Float, Double, and Integer32 are hard-coded to have an even number of
// passes, so the original array is overwritten by the internals.

void RadixSortString(char *array, uint64_t N, uint64_t bytes);
void RadixSortFloat(float *array, uint64_t N);
void RadixSortDouble(double *array, uint64_t N);
void RadixSortInteger8(int8_t *array, uint64_t N);
void RadixSortInteger16(int16_t *array, uint64_t N);
void RadixSortInteger32(int32_t *array, uint64_t N);
void RadixSortInteger64(int64_t *array, uint64_t N, uint64_t groupLength);

// Assume last byte is null (i.e. null-terminated)
void RadixSortString(char *array, uint64_t N, uint64_t bytes) {
    uint64_t bitLength = bytes * 8 * sizeof(char);
    uint64_t groupLength = 8 * sizeof(char);
    char *acopy = calloc(N, bytes * sizeof(char));
    // RadixSortInternal(array, N, groupLength, bitLength, acopy, 0, NULL, 0, bytes);
    RadixSortInternalCh(array, N, groupLength, bitLength, acopy, bytes);
    if ( ((bitLength / groupLength) - 1) % 2 ) {
        memcpy(array, acopy, N * bytes * sizeof(char));
    }

    free(acopy);
}

void RadixSortFloat(float *array, uint64_t N) {
    uint64_t _i;
    float   *_aptr = array;
    int32_t *acast = calloc(N, sizeof *acast);
    int32_t *acopy = calloc(N, sizeof *acopy);

    for (_i = 0; _i < N; _i++, _aptr++) {
        acast[_i] = *(int32_t *) _aptr;
    }

    // RadixSortInternal(acast, N, 8, 32, acopy, -1, array, 32, 0);
    // RadixSortInternal32(acast, N, 8, 32, acopy, -1, array);
    RadixSortInternalGeneric(acast, N, 8, 32, acopy, -1, array);
}

void RadixSortDouble(double *array, uint64_t N) {
    uint64_t _i;
    double  *_aptr = array;
    int64_t *acast = calloc(N, sizeof *acast);
    int64_t *acopy = calloc(N, sizeof *acopy);

    for (_i = 0; _i < N; _i++, _aptr++) {
        acast[_i] = *(int64_t *) _aptr;
    }

    // RadixSortInternal(acast, N, 8, 64, acopy, -1, array, 64, 0);
    // RadixSortInternal64(acast, N, 8, 64, acopy, -1, array);
    RadixSortInternalGeneric(acast, N, 8, 64, acopy, -1, array);
}

void RadixSortInteger8(int8_t *array, uint64_t N)
{
    int8_t *acopy = calloc(N, sizeof *acopy);
    // RadixSortInternal(array, N, 8, 8, acopy, 1, NULL, 8, 0);
    // RadixSortInternal8(array, N, 8, 8, acopy, 1);
    RadixSortInternalGeneric(array, N, 8, 8, acopy, 1, NULL);
    memcpy(array, acopy, N * sizeof(int8_t));
    free(acopy);
}

void RadixSortInteger16(int16_t *array, uint64_t N)
{
    int16_t *acopy = calloc(N, sizeof *acopy);
    // RadixSortInternal(array, N, 8, 16, acopy, 1, NULL, 16, 0);
    // RadixSortInternal16(array, N, 8, 16, acopy, 1);
    RadixSortInternalGeneric(array, N, 8, 16, acopy, 1, NULL);
    free(acopy);
}

void RadixSortInteger32(int32_t *array, uint64_t N)
{
    int32_t *acopy = calloc(N, sizeof *acopy);
    // RadixSortInternal(array, N, 8, 32, acopy, 1, NULL, 32, 0);
    // RadixSortInternal32(array, N, 8, 32, acopy, 1, NULL);
    RadixSortInternalGeneric(array, N, 8, 32, acopy, 1, NULL);
    free(acopy);
}

void RadixSortInteger64(int64_t *array, uint64_t N, uint64_t _groupLength)
{
    uint64_t _i, flip = 0; int64_t range;
    if ( _groupLength == 0 ) {
        RADIX_MINMAX(array, N, min, max, _i)
        _groupLength = 8;
        range = max - min + 1;
    }
    else {
        range = -1;
    }

    int64_t *acopy = calloc(N, sizeof *acopy);
    if ( (range > 0) && (range < ((int64_t) pow(2, 8))) ) {
        // printf("debug 64: 8\n");
        // RadixSortInternal(array, N, _groupLength, 8, acopy, 1, NULL, 64, 0);
        // RadixSortInternal64(array, N, _groupLength, 8, acopy, 1, NULL);
        RadixSortInternalGeneric(array, N, _groupLength, 8, acopy, 1, NULL);
        flip = (8 / _groupLength) % 2;
    }
    else if ( (range > 0) && (range < ((int64_t) pow(2, 16))) ) {
        // printf("debug 64: 16\n");
        // RadixSortInternal(array, N, _groupLength, 16, acopy, 1, NULL, 64, 0);
        // RadixSortInternal64(array, N, _groupLength, 16, acopy, 1, NULL);
        RadixSortInternalGeneric(array, N, _groupLength, 16, acopy, 1, NULL);
        flip = (16 / _groupLength) % 2;
    }
    else if ( (range > 0) && (range < ((int64_t) pow(2, 32))) ) {
        // printf("debug 64: 32\n");
        // RadixSortInternal(array, N, _groupLength, 32, acopy, 1, NULL, 64, 0);
        // RadixSortInternal64(array, N, _groupLength, 32, acopy, 1, NULL);
        RadixSortInternalGeneric(array, N, _groupLength, 32, acopy, 1, NULL);
        flip = (32 / _groupLength) % 2;
    }
    else if ( range ) {
        // printf("debug 64: 64\n");
        // RadixSortInternal(array, N, _groupLength, 64, acopy, 1, NULL, 64, 0);
        // RadixSortInternal64(array, N, _groupLength, 64, acopy, 1, NULL);
        RadixSortInternalGeneric(array, N, _groupLength, 64, acopy, 1, NULL);
        flip = (64 / _groupLength) % 2;
    }

    if ( flip ) {
        memcpy(array, acopy, N * sizeof(int64_t));
    }

    free(acopy);
}
