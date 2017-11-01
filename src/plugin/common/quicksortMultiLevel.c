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
    GT_size N,
    GT_size kstart,
    GT_size kend,
    GT_size elsize,
    GT_size *invert
);

void MultiQuicksortDbl (
    void *start,
    GT_size N,
    GT_size kstart,
    GT_size kend,
    GT_size elsize,
    GT_size *invert)
{
    GT_size j;
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
    GT_size N,
    GT_size kstart,
    GT_size kend,
    GT_size elsize,
    GT_size *ltypes,
    GT_size *invert,
    GT_size *positions
);

void MultiQuicksortMC (
    void *start,
    GT_size N,
    GT_size kstart,
    GT_size kend,
    GT_size elsize,
    GT_size *ltypes,
    GT_size *invert,
    GT_size *positions)
{
    GT_size j;
    GT_bool ischar;
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
    GT_size N,
    GT_size kstart,
    GT_size kend,
    GT_size elsize
);

void MultiQuicksortSpooky (
    void *start,
    GT_size N,
    GT_size kstart,
    GT_size kend,
    GT_size elsize)
{
    GT_size j;
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

int gf_is_sorted (void *a, GT_size n, GT_size es, cmp_t *cmp, void *thunk);
int gf_is_sorted (void *a, GT_size n, GT_size es, cmp_t *cmp, void *thunk)
{
	char *pm;
    for (pm = (char *)a + es; pm < (char *)a + n * es; pm += es) {
        if ( cmp(pm - es, pm, thunk) > 0 ) return (0);
    }
    return (1);
}

int MultiSortCheckMC (
    void *start,
    GT_size N,
    GT_size kstart,
    GT_size kend,
    GT_size elsize,
    GT_size *ltypes,
    GT_size *invert,
    GT_size *positions
);

int MultiSortCheckMC (
    void *start,
    GT_size N,
    GT_size kstart,
    GT_size kend,
    GT_size elsize,
    GT_size *ltypes,
    GT_size *invert,
    GT_size *positions)
{
    GT_size j;
    GT_bool ischar;
    void *i, *end;

    if ( gf_is_sorted (
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
    GT_size N,
    GT_size kstart,
    GT_size kend,
    GT_size elsize,
    GT_size *invert
);

int MultiSortCheckDbl (
    void *start,
    GT_size N,
    GT_size kstart,
    GT_size kend,
    GT_size elsize,
    GT_size *invert)
{
    GT_size j;
    void *i, *end;

    if ( gf_is_sorted (
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

/*********************************************************************
 *                               Is ID                               *
 *********************************************************************/

int gf_isid_sorted (void *a, GT_size n, GT_size es, cmp_t *cmp, void *thunk);
int gf_isid_sorted (void *a, GT_size n, GT_size es, cmp_t *cmp, void *thunk)
{
    int rc;
	char *pm;
    for (pm = (char *)a + es; pm < (char *)a + n * es; pm += es) {
        if ( (rc = cmp(pm, pm - es, thunk)) <= 0 ) return (rc);
    }
    return (1);
}

int MultiIsIDCheckMC (
    void *start,
    GT_size N,
    GT_size kstart,
    GT_size kend,
    GT_size elsize,
    GT_size *ltypes,
    GT_size *invert,
    GT_size *positions
);

int MultiIsIDCheckMC (
    void *start,
    GT_size N,
    GT_size kstart,
    GT_size kend,
    GT_size elsize,
    GT_size *ltypes,
    GT_size *invert,
    GT_size *positions)
{
    int rc;
    GT_size j;
    GT_bool ischar;
    void *i, *end;

    if ( (rc = gf_isid_sorted (
        start,
        N,
        elsize,
        ( (ischar = (ltypes[kstart] > 0)) )?
        (invert[kstart]? AltCompareCharInvert: AltCompareChar):
        (invert[kstart]? AltCompareNumInvert: AltCompareNum),
        &(positions[kstart])
    )) < 0 ) return (rc);

    if ( kstart >= kend )
        return (rc);

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
        if ( (rc = MultiIsIDCheckMC (
            start,
            j,
            kstart + 1,
            kend,
            elsize,
            ltypes,
            invert,
            positions
        )) < 0) return (rc);
    }

    if ( kstart < kend ) {
        start = i;
        if ( start < end )
            goto loop;
    }

    return (rc);
}

int MultiIsIDCheckDbl (
    void *start,
    GT_size N,
    GT_size kstart,
    GT_size kend,
    GT_size elsize,
    GT_size *invert
);

int MultiIsIDCheckDbl (
    void *start,
    GT_size N,
    GT_size kstart,
    GT_size kend,
    GT_size elsize,
    GT_size *invert)
{
    int rc;
    GT_size j;
    void *i, *end;

    if ( (rc = gf_isid_sorted (
        start,
        N,
        elsize,
        invert[kstart]? MultiCompareNum2Invert: MultiCompareNum2,
        &kstart
    )) < 0 ) return (rc);

    if ( kstart >= kend )
        return (rc);

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
        if ( (rc = MultiIsIDCheckDbl (
            start,
            j,
            kstart + 1,
            kend,
            elsize,
            invert
        )) < 0) return (rc);
    }

    if ( kstart < kend ) {
        start = i;
        if ( start < end )
            goto loop;
    }

    return (rc);
}
