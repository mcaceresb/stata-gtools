#define BaseCompareNum(a, b) ( ( (a) > (b) ) - ( (a) < (b) ) )
#define BaseCompareChar(a, b) ( strcmp(a, b) )

/*********************************************************************
 *                        Check if is sorted                         *
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


int gf_isid_sorted (void *a, GT_size n, GT_size es, cmp_t *cmp, void *thunk);
int gf_isid_sorted (void *a, GT_size n, GT_size es, cmp_t *cmp, void *thunk)
{
    int sorted = -1, strict = 1;
	char *pm;
    for (pm = (char *)a + es; pm < (char *)a + n * es; pm += es) {
        // If -1, then it is for sure not sorted; if 1 then it is sorted
        // in strict order. If 0 then it might be sorted in weak order.
        if ( (sorted = cmp(pm, pm - es, thunk)) && (sorted < 0) ) {
            return (sorted);
        }
        else {
            strict = 0;
        }
    }
    // If the function exited, then rc >= 0 for all i, which means
    // that it is either strictly or weakly sorted.
    return (strict && sorted);
}

/*********************************************************************
 *                              Doubles                              *
 *********************************************************************/

int MultiCompareNum2 (const void *a, const void *b, void *thunk);
int MultiCompareNum2 (const void *a, const void *b, void *thunk)
{
    GT_size kstart = *(GT_size *)thunk;
    ST_double aa   = *((ST_double *)a + kstart);
    ST_double bb   = *((ST_double *)b + kstart);
    return BaseCompareNum(aa, bb);
}

int MultiCompareNum2Invert (const void *a, const void *b, void *thunk);
int MultiCompareNum2Invert (const void *a, const void *b, void *thunk)
{
    GT_size kstart = *(GT_size *)thunk;
    ST_double aa   = *((ST_double *)a + kstart);
    ST_double bb   = *((ST_double *)b + kstart);
    return BaseCompareNum(bb, aa);
}

int MultiCompareNum2InvertMlast (const void *a, const void *b, void *thunk);
int MultiCompareNum2InvertMlast (const void *a, const void *b, void *thunk)
{
    GT_size kstart = *(GT_size *)thunk;
    ST_double aa   = *((ST_double *)a + kstart);
    ST_double bb   = *((ST_double *)b + kstart);

    if ( SF_is_missing(aa) == SF_is_missing(bb) ) {
        return BaseCompareNum(bb, aa);
    }
    else {
        return BaseCompareNum(aa, bb);
    }
}

/*********************************************************************
 *                       Mixed Character Array                       *
 *********************************************************************/

int AltCompareChar (const void *a, const void *b, void *thunk);
int AltCompareChar (const void *a, const void *b, void *thunk)
{
    GT_size kstart = *(GT_size *)thunk;
    char *aa = (char *)(a + kstart);
    char *bb = (char *)(b + kstart);
// printf("\tcmp(%s, %s) = %d\n", aa, bb, BaseCompareChar(aa, bb));
    return BaseCompareChar(aa, bb);
}

int AltCompareCharInvert (const void *a, const void *b, void *thunk);
int AltCompareCharInvert (const void *a, const void *b, void *thunk)
{
    GT_size kstart = *(GT_size *)thunk;
    char *aa = (char *)(a + kstart);
    char *bb = (char *)(b + kstart);
// printf("cmp(%s, %s) = %d\n", bb, aa, BaseCompareChar(bb, aa));
    return BaseCompareChar(bb, aa);
}

int AltCompareNum (const void *a, const void *b, void *thunk);
int AltCompareNum (const void *a, const void *b, void *thunk)
{
    GT_size kstart = *(GT_size *)thunk;
    ST_double aa   = *(ST_double *)(a + kstart);
    ST_double bb   = *(ST_double *)(b + kstart);
// printf("\tcmp(%.4f, %.4f) = %d\n", aa, bb, BaseCompareNum(aa, bb));
    return BaseCompareNum(aa, bb);
}

int AltCompareNumInvert (const void *a, const void *b, void *thunk);
int AltCompareNumInvert (const void *a, const void *b, void *thunk)
{
    GT_size kstart = *(GT_size *)thunk;
    ST_double aa   = *(ST_double *)(a + kstart);
    ST_double bb   = *(ST_double *)(b + kstart);
// printf("\tcmp(%.4f, %.4f) = %d\n", bb, aa, BaseCompareNum(bb, aa));
    return BaseCompareNum(bb, aa);
}

int AltCompareNumInvertMlast (const void *a, const void *b, void *thunk);
int AltCompareNumInvertMlast (const void *a, const void *b, void *thunk)
{
    GT_size kstart = *(GT_size *)thunk;
    ST_double aa   = *(ST_double *)(a + kstart);
    ST_double bb   = *(ST_double *)(b + kstart);
// printf("\tcmp(%.4f, %.4f) = %d\n", bb, aa, BaseCompareNum(bb, aa));

    if ( SF_is_missing(aa) == SF_is_missing(bb) ) {
        return BaseCompareNum(bb, aa);
    }
    else {
        return BaseCompareNum(aa, bb);
    }
}

/*********************************************************************
 *                  Hashed 64-bit array with index                   *
 *********************************************************************/

int CompareSpooky (const void *a, const void *b, void *thunk);
int CompareSpooky (const void *a, const void *b, void *thunk)
{
    GT_size kstart = *(GT_size *)thunk;
    uint64_t aa = *(uint64_t *)(a + kstart);
    uint64_t bb = *(uint64_t *)(b + kstart);
    return BaseCompareNum(aa, bb);
    // return BaseCompareNum(*(uint64_t *)a, *(uint64_t *)b);
}

/*********************************************************************
 *                               xtile                               *
 *********************************************************************/

int xtileCompare (const void *a, const void *b, void *thunk);
int xtileCompare (const void *a, const void *b, void *thunk)
{
    ST_double aa = *((ST_double *)a);
    ST_double bb = *((ST_double *)b);
    return BaseCompareNum(aa, bb);
}

int xtileCompareIndex (const void *a, const void *b, void *thunk);
int xtileCompareIndex (const void *a, const void *b, void *thunk)
{
    ST_double aa = *((ST_double *)a + 1);
    ST_double bb = *((ST_double *)b + 1);
    return BaseCompareNum(aa, bb);
}

int xtileCompareInvert (const void *a, const void *b, void *thunk);
int xtileCompareInvert (const void *a, const void *b, void *thunk)
{
    ST_double aa = *((ST_double *)a);
    ST_double bb = *((ST_double *)b);
    return BaseCompareNum(bb, aa);
}
