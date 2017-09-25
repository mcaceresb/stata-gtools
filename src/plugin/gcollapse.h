#ifndef GCOLLAPSE
#define GCOLLAPSE

typedef union {
    double dval;
    char *cval;
} MixedUnion;

int sf_collapse (struct StataInfo *st_info, int action, char *fname);

#endif
