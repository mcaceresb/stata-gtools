#include <sys/cdefs.h>
#include <stdlib.h>
#include <string.h>
#include "quicksort.c"
#include "quicksortComparators.c"

/*********************************************************************
 *                              Doubles                              *
 *********************************************************************/

void MultiQuicksortDbl (
    void *start,
    size_t N,
    size_t kstart,
    size_t kend,
    size_t elsize,
    size_t *invert
);

void MultiQuicksortDbl (
    void *start,
    size_t N,
    size_t kstart,
    size_t kend,
    size_t elsize,
    size_t *invert)
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
        MultiQuicksortDbl (
            start,
            j,
            kstart + 1,
            kend,
            elsize,
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
 *                       Mixed Character Array                       *
 *********************************************************************/

void MultiQuicksortMC (
    void *start,
    size_t N,
    size_t kstart,
    size_t kend,
    size_t elsize,
    size_t *ltypes,
    size_t *invert,
    size_t *positions
);

void MultiQuicksortMC (
    void *start,
    size_t N,
    size_t kstart,
    size_t kend,
    size_t elsize,
    size_t *ltypes,
    size_t *invert,
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
        MultiQuicksortMC (
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

/*********************************************************************
 *                      Spooky Hash with Index                       *
 *********************************************************************/

void MultiQuicksortSpooky (
    void *start,
    size_t N,
    size_t kstart,
    size_t kend,
    size_t elsize
);

void MultiQuicksortSpooky (
    void *start,
    size_t N,
    size_t kstart,
    size_t kend,
    size_t elsize)
{
    size_t j;
    void *i, *end;

    quicksort_bsd (
        start,
        N,
        elsize,
        CompareSpooky,
        &kstart
    );

    if ( kstart >= kend )
        return;

    end = start + N * elsize;

loop:

    j = 1;
    for (i = start + elsize; i < end; i += elsize) {
        if ( CompareSpooky(i - elsize, i, &kstart) ) break;
        j++;
    }

    if ( j > 1 ) {
        MultiQuicksortSpooky (
            start,
            j,
            kstart + 1,
            kend,
            elsize
        );
    }

    if ( (kstart < kend) ) {
        start = i;
        if ( start < end )
            goto loop;
    }
}

/*********************************************************************
 *                             Is sorted                             *
 *********************************************************************/

int mf_is_sorted (void *a, size_t n, size_t es, cmp_t *cmp, void *thunk);
int mf_is_sorted (void *a, size_t n, size_t es, cmp_t *cmp, void *thunk)
{
	char *pm;
    for (pm = (char *)a + es; pm < (char *)a + n * es; pm += es) {
        if ( cmp(pm - es, pm, thunk) > 0 ) return (0);
    }
    return (1);
}

int MultiSortCheckMC (
    void *start,
    size_t N,
    size_t kstart,
    size_t kend,
    size_t elsize,
    size_t *ltypes,
    size_t *invert,
    size_t *positions
);

int MultiSortCheckMC (
    void *start,
    size_t N,
    size_t kstart,
    size_t kend,
    size_t elsize,
    size_t *ltypes,
    size_t *invert,
    size_t *positions)
{
    size_t j;
    short ischar;
    void *i, *end;

    if ( mf_is_sorted (
        start,
        N,
        elsize,
        ( (ischar = (ltypes[kstart] > 0)) )?
        (invert[kstart]? AltCompareCharInvert: AltCompareChar):
        (invert[kstart]? AltCompareNumInvert: AltCompareNum),
        &(positions[kstart])
    ) == 0 ) return (0);

    if ( kstart >= kend )
        return (1);

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
        if ( MultiSortCheckMC (
            start,
            j,
            kstart + 1,
            kend,
            elsize,
            ltypes,
            invert,
            positions
        ) == 0) return (0);
    }

    if ( kstart < kend ) {
        start = i;
        if ( start < end )
            goto loop;
    }

    return (1);
}

int MultiSortCheckDbl (
    void *start,
    size_t N,
    size_t kstart,
    size_t kend,
    size_t elsize,
    size_t *invert
);

int MultiSortCheckDbl (
    void *start,
    size_t N,
    size_t kstart,
    size_t kend,
    size_t elsize,
    size_t *invert)
{
    size_t j;
    void *i, *end;

    if ( mf_is_sorted (
        start,
        N,
        elsize,
        invert[kstart]? MultiCompareNum2Invert: MultiCompareNum2,
        &kstart
    ) == 0 ) return (0);

    if ( kstart >= kend )
        return (1);

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
        if ( MultiSortCheckDbl (
            start,
            j,
            kstart + 1,
            kend,
            elsize,
            invert
        ) == 0) return(0);
    }

    if ( kstart < kend ) {
        start = i;
        if ( start < end )
            goto loop;
    }

    return (1);
}
