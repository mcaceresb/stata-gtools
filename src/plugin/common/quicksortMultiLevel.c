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
    GT_bool checkok = 0;
    GT_bool ischar;
    void *i, *end;

    // Check if range is sorted.  If it is not in weakly ascending order, it
    // is not sorted.


    if ( (rc = gf_isid_sorted (
        start,
        N,
        elsize,
        ( (ischar = (ltypes[kstart] > 0)) )?
        (invert[kstart]? AltCompareCharInvert: AltCompareChar):
        (invert[kstart]? AltCompareNumInvert: AltCompareNum),
        &(positions[kstart])
    )) < 0 ) return (rc);

    // If it is sorted in strictly ascending order, then it is sorted.
    //
    //     1. If there are more levels but the highest level is strictly
    //        ascending then this must ba an ID.
    //     2. If this is a recursive call, then this will tell the outer
    //        call that this level is sorted.

    if ( rc > 0 )
        return (rc);

    // If this is weakly sorted, exit only if this is the deepest level.  If
    // this is not the deepest level, there may be a deeper level that is
    // sorted, so go to the loop to check.

    if ( kstart >= kend )
        return (rc);

    end = start + N * elsize;

loop:

    // The function should only enter the loop if this is not the deepest
    // level and the level is weakly sorted. Hence there is at least one group
    // defined by this level. If the loop does not find at least one group
    // then something is off. Assume the data is not sorted in this case and
    // resume execution normally.

    // First, get the ending point for this grouping. We count the number
    // of elements that are the same, so the end is simply start + j

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

    // If this is a group for this level and not a unique observation,
    // recursively check if everything from the next level onward is an ID
    // within this group. Note that this code will be run at least once.

    if ( j > 1 ) {
        checkok = 1;

        // If everything is sorted strictly, then this is an ID and we can
        // move on to checking the next group in this level, should any
        // exist. However, if this is sorted weakly or not sorted then exit.

        if ( (rc = MultiIsIDCheckMC (
            start,
            j,
            kstart + 1,
            kend,
            elsize,
            ltypes,
            invert,
            positions
        )) <= 0) return (rc);

        // Note that in the recursive call we exit if the return code is <= 0,
        // not just < 0 (i.e. if it is unsorted or weakly sorted). Why?
        //
        // There are two scenarios to consider:
        //    1. Level k + 1 weakly sorted but a deeper level is strictly sorted
        //    2. Every level deeper than k is weakly sortd
        //
        // We want the function to return 1 in the first case and 0 in the second.
        // Note the recursive call will end if one of two things happens:
        //
        //    1. The data is is strictly sorted by some deeper level
        //       or combination thereof.
        //    2. The data is not strictly sorted for at least 2 rows.
        //
        // rc <= 0 means at least one deeper level was not strictly sorted,
        // which makes this not sorted or not an ID.
    }

    if ( kstart < kend ) {
        start = i;
        if ( start < end )
            goto loop;
    }

    // For some reason the loop executed but no groups were found. This should
    // never happen, so we exit as if the data was not sorted.

    if ( checkok ) {
        return (rc);
    }

    return (-1);
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
    GT_bool checkok = 0;
    void *i, *end;

    // Check if range is sorted.  If it is not in weakly ascending order, it
    // is not sorted.

    if ( (rc = gf_isid_sorted (
        start,
        N,
        elsize,
        invert[kstart]? MultiCompareNum2Invert: MultiCompareNum2,
        &kstart
    )) < 0 ) return (rc);

    // If it is sorted in strictly ascending order, then it is sorted.
    //
    //     1. If there are more levels but the highest level is strictly
    //        ascending then this must ba an ID.
    //     2. If this is a recursive call, then this will tell the outer
    //        call that this level is sorted.

    if ( rc > 0 )
        return (rc);

    // If this is weakly sorted, exit only if this is the deepest level.  If
    // this is not the deepest level, there may be a deeper level that is
    // sorted, so go to the loop to check.

    if ( kstart >= kend )
        return (rc);

    end = start + N * elsize;

loop:

    // The function should only enter the loop if this is not the deepest
    // level and the level is weakly sorted. Hence there is at least one group
    // defined by this level. If the loop does not find at least one group
    // then something is off. Assume the data is not sorted in this case and
    // resume execution normally.

    // First, get the ending point for this grouping. We count the number
    // of elements that are the same, so the end is simply start + j

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

    // If this is a group for this level and not a unique observation,
    // recursively check if everything from the next level onward is an ID
    // within this group. Note that this code will be run at least once.

    if ( j > 1 ) {
        checkok = 1;

        // If everything is sorted strictly, then this is an ID and we can
        // move on to checking the next group in this level, should any
        // exist. However, if this is sorted weakly or not sorted then it is
        // not an ID.

        if ( (rc = MultiIsIDCheckDbl (
            start,
            j,
            kstart + 1,
            kend,
            elsize,
            invert
        )) <= 0) return (rc);

        // Note that in the recursive call we exit if the return code is <= 0,
        // not just < 0 (i.e. if it is unsorted or weakly sorted). Why?
        //
        // There are two scenarios to consider:
        //    1. Level k + 1 weakly sorted but a deeper level is strictly sorted
        //    2. Every level deeper than k is weakly sortd
        //
        // We want the function to return 1 in the first case and 0 in the second.
        // Note the recursive call will end if one of two things happens:
        //
        //    1. The data is is strictly sorted by some deeper level
        //       or combination thereof.
        //    2. The data is not strictly sorted for at least 2 rows.
        //
        // rc <= 0 means at least one deeper level was not strictly sorted,
        // which makes this not sorted or not an ID.
    }

    if ( kstart < kend ) {
        start = i;
        if ( start < end )
            goto loop;
    }

    // For some reason the loop executed but no groups were found. This should
    // never happen, so we exit as if the data was not sorted.

    if ( checkok ) {
        return (rc);
    }

    return (-1);
}
