#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <math.h>
#include <inttypes.h>
#include <sys/types.h>
#include "RadixSort.c"

// gcc -Wall -O3 -funroll-loops -o RadixSortTesting RadixSortTesting.c  && ./RadixSortTesting
// gcc -Wall -O2 -funroll-loops -o RadixSortTesting RadixSortTesting.c  && ./RadixSortTesting

void print_array_int(int64_t *a, uint64_t N);
void print_array_dbl(double *array, uint64_t N);
void print_array_flt(float *array, uint64_t N);
void print_array_int32(int32_t *a, uint64_t N);
void print_array_int16(int16_t *a, uint64_t N);
void print_array_int8(int8_t *a, uint64_t N);
void print_array_str(char *array, uint64_t N, uint64_t bytes);
void sf_running_timer (clock_t *timer, const char *msg);

int main(int argc, char *argv[])
{
    uint64_t i;
    uint64_t N = 14863778;
    // uint64_t N = 10000000;
    // uint64_t N = 12;
    clock_t timer = clock();

    // printf("debug %lu\n", time(NULL));
    // srand();

    int64_t *shuffle = calloc(N, sizeof(shuffle));

    char *teststr = calloc(N, 5 * sizeof(char));
    memset(teststr, '\0', 5 * sizeof(char) * N);
    strcpy(teststr + 0 * 5, "ss");
    strcpy(teststr + 1 * 5, "fee");
    strcpy(teststr + 2 * 5, "xxz");
    strcpy(teststr + 3 * 5, "bbz");
    strcpy(teststr + 4 * 5, "abaf");
    strcpy(teststr + 5 * 5, "cre");
    strcpy(teststr + 6 * 5, "xas");
    strcpy(teststr + 7 * 5, "cas");
    strcpy(teststr + 8 * 5, "cas");
    strcpy(teststr + 9 * 5, "cre");

    // strcpy(teststr + 0 * 4, "CAS");
    // strcpy(teststr + 1 * 4, "CAS");
    // strcpy(teststr + 2 * 4, "CAS");
    // strcpy(teststr + 3 * 4, "CAS");
    // strcpy(teststr + 4 * 4, "Cre");
    // strcpy(teststr + 5 * 4, "CRE");
    // strcpy(teststr + 6 * 4, "XAS");
    // strcpy(teststr + 7 * 4, "CAS");
    // strcpy(teststr + 8 * 4, "CAS");
    // strcpy(teststr + 9 * 4, "Cre");

    // strcpy(teststr + 0 * 4, "VTS");
    // strcpy(teststr + 1 * 4, "DDS");
    // strcpy(teststr + 2 * 4, "DDS");
    // strcpy(teststr + 3 * 4, "VTS");
    // strcpy(teststr + 4 * 4, "CMT");
    // strcpy(teststr + 5 * 4, "DDS");
    // strcpy(teststr + 6 * 4, "VTS");
    // strcpy(teststr + 7 * 4, "Cre");
    // strcpy(teststr + 8 * 4, "VTS");
    // strcpy(teststr + 9 * 4, "VTS");

    double *testdbl = calloc(N, sizeof *testdbl);
    for(i = 0; i < N; i++) {
        testdbl[i] = 2.0 * ((double) rand() / RAND_MAX) - 1.0;
    }

    float *testflt = calloc(N, sizeof *testflt);
    for(i = 0; i < N; i++) {
        testflt[i] = 2.0 * ((float) rand() / RAND_MAX) - 1.0;
    }

    int8_t *testint8 = calloc(N, sizeof *testint8);
    for(i = 0; i < N; i++) {
        testint8[i] = rand() - RAND_MAX / 2;
        // testint8[i] = testint[i];
    }

    int16_t *testint16 = calloc(N, sizeof *testint16);
    for(i = 0; i < N; i++) {
        testint16[i] = rand() - RAND_MAX / 2;
        // testint16[i] = testint[i];
        // testint16[i] = testint8[i];
    }

    int32_t *testint32 = calloc(N, sizeof *testint32);
    for(i = 0; i < N; i++) {
        testint32[i] = rand() - RAND_MAX / 2;
        // testint32[i] = testint[i];
        // testint32[i] = testint8[i];
    }

    int64_t *testint = calloc(N, sizeof *testint);
    for(i = 0; i < N; i++) {
        testint[i] = (int64_t) 4 * (rand() - RAND_MAX / 2);
        // testint[i] = (int32_t) (rand() - RAND_MAX / 2);
        // testint[i] = (int16_t) (rand() - RAND_MAX / 2);
        // testint[i] = (int8_t) (rand() - RAND_MAX / 2);
        // testint[i] = testint8[i];
    }

sf_running_timer(&timer, "init arrays");

    print_array_str(teststr, N, 5);
    RadixSortString(teststr, N, 5);
    print_array_str(teststr, N, 5);

sf_running_timer(&timer, "string sort");

    print_array_dbl(testdbl, N);
    RadixSortDouble(testdbl, N);
    print_array_dbl(testdbl, N);

sf_running_timer(&timer, "double sort");

    print_array_flt(testflt, N);
    RadixSortFloat(testflt, N);
    print_array_flt(testflt, N);

sf_running_timer(&timer, "float sort");

    print_array_int(testint, N);
    RadixSortInteger64(testint, N, 8);
    print_array_int(testint, N);

sf_running_timer(&timer, "int sort");

    print_array_int32(testint32, N);
    RadixSortInteger32(testint32, N);
    print_array_int32(testint32, N);

sf_running_timer(&timer, "int32 sort");

    print_array_int16(testint16, N);
    RadixSortInteger16(testint16, N);
    print_array_int16(testint16, N);

sf_running_timer(&timer, "int16 sort");

    print_array_int8(testint8, N);
    RadixSortInteger8(testint8, N);
    print_array_int8(testint8, N);

sf_running_timer(&timer, "int8 sort");

    free(testdbl);
    free(testflt);
    free(testint);
    free(testint32);
    free(testint16);
    free(testint8);
    return(0);
}

void print_array_dbl(double *array, uint64_t N) {
    if ( N > 20 ) return;
    uint64_t i;
    for(i = 0; i < N; i++) {
        printf("%lu: %.5f\n", i, array[i]);
    }
    printf("----\n");
}

void print_array_flt(float *array, uint64_t N) {
    if ( N > 20 ) return;
    uint64_t i;
    for(i = 0; i < N; i++) {
        printf("%lu: %.5f\n", i, array[i]);
    }
    printf("----\n");
}

void print_array_int(int64_t *a, uint64_t N) {
    if ( N > 20 ) return;
    uint64_t i;
    for(i = 0; i < N; i++) {
        printf("%lu: %ld\n", i, a[i]);
    }
    printf("----\n");
}

void print_array_int32(int32_t *a, uint64_t N) {
    if ( N > 20 ) return;
    uint64_t i;
    for(i = 0; i < N; i++) {
        printf("%lu: %d\n", i, a[i]);
    }
    printf("----\n");
}

void print_array_int16(int16_t *a, uint64_t N) {
    if ( N > 20 ) return;
    uint64_t i;
    for(i = 0; i < N; i++) {
        printf("%lu: %d\n", i, a[i]);
    }
    printf("----\n");
}

void print_array_int8(int8_t *a, uint64_t N) {
    if ( N > 20 ) return;
    uint64_t i;
    for(i = 0; i < N; i++) {
        printf("%lu: %d\n", i, a[i]);
    }
    printf("----\n");
}

void print_array_str(char *a, uint64_t N, uint64_t bytes) {
    if ( N > 20 ) return;
    uint64_t i;
    for(i = 0; i < N; i++) {
        printf("%lu: %s\n", i, a + bytes * i);
    }
    printf("----\n");
}

void sf_running_timer (clock_t *timer, const char *msg)
{
    double diff = (double) (clock() - *timer) / CLOCKS_PER_SEC;
    printf(msg);
    printf(" (%.3f seconds).\n", diff);
    *timer = clock();
}
