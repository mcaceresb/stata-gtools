#include <sys/cdefs.h>
#include <stdlib.h>
#include <string.h>
#include "quicksort.c"

#define BaseCompareNum(a, b) ( ( (a) > (b) ) - ( (a) < (b) ) )
#define BaseCompareChar(a, b) ( strcmp(a, b) )

int MultiCompareChar (const void *a, const void *b, void *thunk);
int MultiCompareChar (const void *a, const void *b, void *thunk)
{
    int kstart = *(size_t *)thunk;
    // return BaseCompareChar(*((char **)a + kstart), *((char **)b + kstart));
    MixedUnion *aa = (MixedUnion *)a + kstart;
    MixedUnion *bb = (MixedUnion *)b + kstart;
    return BaseCompareChar(aa->cval, bb->cval);
}

int MultiCompareCharInvert (const void *a, const void *b, void *thunk);
int MultiCompareCharInvert (const void *a, const void *b, void *thunk)
{
    int kstart = *(size_t *)thunk;
    // return BaseCompareChar(*((char **)a + kstart), *((char **)b + kstart));
    MixedUnion *aa = (MixedUnion *)a + kstart;
    MixedUnion *bb = (MixedUnion *)b + kstart;
    return BaseCompareChar(bb->cval, aa->cval);
}

int MultiCompareNum (const void *a, const void *b, void *thunk);
int MultiCompareNum (const void *a, const void *b, void *thunk)
{
    int kstart = *(size_t *)thunk;
    MixedUnion *aa = (MixedUnion *)a + kstart;
    MixedUnion *bb = (MixedUnion *)b + kstart;
    return BaseCompareNum(aa->dval, bb->dval);
    // const double aa = *((double*)*((void **)a + kstart));
    // const double bb = *((double*)*((void **)b + kstart));
    // return BaseCompareNum(aa, bb);
}

int MultiCompareNumInvert (const void *a, const void *b, void *thunk);
int MultiCompareNumInvert (const void *a, const void *b, void *thunk)
{
    int kstart = *(size_t *)thunk;
    MixedUnion *aa = (MixedUnion *)a + kstart;
    MixedUnion *bb = (MixedUnion *)b + kstart;
    return BaseCompareNum(bb->dval, aa->dval);
    // const double aa = *((double*)*((void **)a + kstart));
    // const double bb = *((double*)*((void **)b + kstart));
    // return BaseCompareNum(aa, bb);
}

void MultiQuicksort (
    void *start,
    size_t N,
    size_t kstart,
    size_t kend,
    size_t elsize,
    int *ltypes,
    int *invert
);

void MultiQuicksort (
    void *start,
    size_t N,
    size_t kstart,
    size_t kend,
    size_t elsize,
    int *ltypes,
    int *invert)
{
    size_t j;
    short ischar;
    void *i, *end;

    quicksort_bsd (
        start,
        N,
        elsize,
        ( (ischar = (ltypes[kstart] > 0)) )?
        (invert[kstart]? MultiCompareCharInvert: MultiCompareChar):
        (invert[kstart]? MultiCompareNumInvert: MultiCompareNum),
        &kstart
    );

    if ( kstart >= kend )
        return;

    end = start + N * elsize;

loop:

    j = 1;
    if ( invert[kstart] ) {
        if ( ischar ) {
            for (i = start + elsize; i < end; i += elsize) {
                if ( MultiCompareCharInvert(i - elsize, i, &kstart) ) break;
                j++;
            }
        }
        else {
            for (i = start + elsize; i < end; i += elsize) {
                if ( MultiCompareNumInvert(i - elsize, i, &kstart) ) break;
                j++;
            }
        }
    }
    else {
        if ( ischar ) {
            for (i = start + elsize; i < end; i += elsize) {
                if ( MultiCompareChar(i - elsize, i, &kstart) ) break;
                j++;
            }
        }
        else {
            for (i = start + elsize; i < end; i += elsize) {
                if ( MultiCompareNum(i - elsize, i, &kstart) ) break;
                j++;
            }
        }
    }

    if ( j > 1 ) {
        MultiQuicksort (
            start,
            j,
            kstart + 1,
            kend,
            elsize,
            ltypes,
            invert
        );
    }

    if ( (kstart < kend) ) {
        start = i;
        if ( start < end )
            goto loop;
    }
}

/*********************************************************************
 *                              Testing                              *
 *********************************************************************/

int MultiCompareNum2 (const void *a, const void *b, void *thunk);
int MultiCompareNum2 (const void *a, const void *b, void *thunk)
{
    int kstart = *(size_t *)thunk;
    double aa = *((double *)a + kstart);
    double bb = *((double *)b + kstart);
    return BaseCompareNum(aa, bb);
}

int MultiCompareNum2Invert (const void *a, const void *b, void *thunk);
int MultiCompareNum2Invert (const void *a, const void *b, void *thunk)
{
    int kstart = *(size_t *)thunk;
    double aa = *((double *)a + kstart);
    double bb = *((double *)b + kstart);
    return BaseCompareNum(bb, aa);
}

void MultiQuicksort2 (
    void *start,
    size_t N,
    size_t kstart,
    size_t kend,
    size_t elsize,
    int *ltypes,
    int *invert
);

void MultiQuicksort2 (
    void *start,
    size_t N,
    size_t kstart,
    size_t kend,
    size_t elsize,
    int *ltypes,
    int *invert)
{
    size_t j;
    void *i, *end;

    quicksort_bsd (
        start,
        N,
        elsize,
        invert[kstart]? MultiCompareNum2Invert: MultiCompareNum2,
        &kstart
    );

    if ( kstart >= kend )
        return;

    end = start + N * elsize;

loop:

    j = 1;
    if ( invert[kstart] ) {
        for (i = start + elsize; i < end; i += elsize) {
            if ( MultiCompareNum2Invert(i - elsize, i, &kstart) ) break;
            j++;
        }
    }
    else {
        for (i = start + elsize; i < end; i += elsize) {
            if ( MultiCompareNum2(i - elsize, i, &kstart) ) break;
            j++;
        }
    }

    if ( j > 1 ) {
        MultiQuicksort (
            start,
            j,
            kstart + 1,
            kend,
            elsize,
            ltypes,
            invert
        );
    }

    if ( (kstart < kend) ) {
        start = i;
        if ( start < end )
            goto loop;
    }
}

/*********************************************************************
 *                              Testing                              *
 *********************************************************************/

int AltCompareChar (const void *a, const void *b, void *thunk);
int AltCompareChar (const void *a, const void *b, void *thunk)
{
    int kstart = *(size_t *)thunk;
    char *aa = (char *)(a + kstart);
    char *bb = (char *)(b + kstart);
// printf("%s vs %s\n", aa, bb);
    return BaseCompareChar(aa, bb);
}

int AltCompareCharInvert (const void *a, const void *b, void *thunk);
int AltCompareCharInvert (const void *a, const void *b, void *thunk)
{
    int kstart = *(size_t *)thunk;
    char *aa = (char *)(a + kstart);
    char *bb = (char *)(b + kstart);
// printf("\t%s vs %s\n", aa, bb);
    return BaseCompareChar(bb, aa);
}

int AltCompareNum (const void *a, const void *b, void *thunk);
int AltCompareNum (const void *a, const void *b, void *thunk)
{
    int kstart = *(size_t *)thunk;
    double aa = *(double *)(a + kstart);
    double bb = *(double *)(b + kstart);
// printf("\t%.4f vs %.4f\n", aa, bb);
    return BaseCompareNum(aa, bb);
}

int AltCompareNumInvert (const void *a, const void *b, void *thunk);
int AltCompareNumInvert (const void *a, const void *b, void *thunk)
{
    int kstart = *(size_t *)thunk;
    double aa = *(double *)(a + kstart);
    double bb = *(double *)(b + kstart);
// printf("\t%.4f vs %.4f\n", aa, bb);
    return BaseCompareNum(bb, aa);
}


void MultiQuicksort3 (
    void *start,
    size_t N,
    size_t kstart,
    size_t kend,
    size_t elsize,
    int *ltypes,
    int *invert,
    size_t *positions)
{
    size_t j;
    short ischar;
    void *i, *end;

    quicksort_bsd (
        start,
        N,
        elsize,
        ( (ischar = (ltypes[kstart] > 0)) )?
        (invert[kstart]? AltCompareCharInvert: AltCompareChar):
        (invert[kstart]? AltCompareNumInvert: AltCompareNum),
        &(positions[kstart])
    );

    if ( kstart >= kend )
        return;

    end = start + N * elsize;

loop:

    j = 1;
    if ( invert[kstart] ) {
        if ( ischar ) {
            for (i = start + elsize; i < end; i += elsize) {
                if ( AltCompareCharInvert(i - elsize, i, &(positions[kstart])) ) break;
                j++;
            }
        }
        else {
            for (i = start + elsize; i < end; i += elsize) {
                if ( AltCompareNumInvert(i - elsize, i, &(positions[kstart])) ) break;
                j++;
            }
        }
    }
    else {
        if ( ischar ) {
            for (i = start + elsize; i < end; i += elsize) {
                if ( AltCompareChar(i - elsize, i, &(positions[kstart])) ) break;
                j++;
            }
        }
        else {
            for (i = start + elsize; i < end; i += elsize) {
                if ( AltCompareNum(i - elsize, i, &(positions[kstart])) ) break;
                j++;
            }
        }
    }

    if ( j > 1 ) {
        MultiQuicksort3 (
            start,
            j,
            kstart + 1,
            kend,
            elsize,
            ltypes,
            invert,
            positions
        );
    }

    if ( (kstart < kend) ) {
        start = i;
        if ( start < end )
            goto loop;
    }
}
