#ifndef GTOOLSGROUPBYAPI
#define GTOOLSGROUPBYAPI

void GtoolsGroupByTransform (
    struct GtoolsHash *GtoolsHashInfo,
    ST_double *statCodes,
    GT_size   *statMaps,
    ST_double *sources,
    ST_double *weights,
    ST_double *targets,
    GT_size   ktargets
);

void GtoolsGroupByTransformUnweighted (
    struct GtoolsHash *GtoolsHashInfo,
    ST_double *statCodes,
    GT_size   *statMaps,
    ST_double *sources,
    ST_double *weights,
    ST_double *targets,
    GT_size   ktargets
);

void GtoolsGroupByTransformWeighted (
    struct GtoolsHash *GtoolsHashInfo,
    ST_double *statCodes,
    GT_size   *statMaps,
    ST_double *sources,
    ST_double *weights,
    ST_double *targets,
    GT_size   ktargets
);

/*********************************************************************
 *                             Transform                             *
 *********************************************************************/

void GtoolsTransformIndex (
    ST_double *source,
    ST_double *target,
    GT_size   *index,
    GT_size   N,
    ST_double statcode
);

void GtoolsTransformDeMeanIndex (
    ST_double *source,
    ST_double *target,
    GT_size   *index,
    GT_size   N
);

void GtoolsTransformIndexWeighted (
    ST_double *source,
    ST_double *weights,
    ST_double *target,
    GT_size   *index,
    GT_size   N,
    ST_double statcode
);

void GtoolsTransformDeMeanIndexWeighted (
    ST_double *source,
    ST_double *weights,
    ST_double *target,
    GT_size   *index,
    GT_size   N
);

void GtoolsTransformBiasedStandardizeVector (ST_double *source, ST_double *target, ST_double *weights,            GT_size N, ST_double *sd);
void GtoolsTransformBiasedStandardizeMatrix (ST_double *source, ST_double *target, ST_double *weights, GT_size K, GT_size N, ST_double *sd);

void GtoolsTransformScaleVector (ST_double *source, ST_double *target,            GT_size N, ST_double scale);
void GtoolsTransformScaleMatrix (ST_double *source, ST_double *target, GT_size K, GT_size N, ST_double *scale);

/*********************************************************************
 *                               Stats                               *
 *********************************************************************/

ST_double GtoolsStatsIndex         (ST_double *source, GT_size *index, GT_size N, ST_double statcode);
ST_double GtoolsStatsSumIndex      (ST_double *source, GT_size *index, GT_size N);
ST_double GtoolsStatsMeanIndex     (ST_double *source, GT_size *index, GT_size N);
ST_double GtoolsStatsQuantileIndex (ST_double *source, GT_size *index, GT_size N);

ST_double GtoolsStatsIndexWeighted         (ST_double *source, ST_double *weights, GT_size *index, GT_size N, ST_double statcode);
ST_double GtoolsStatsSumIndexWeighted      (ST_double *source, ST_double *weights, GT_size *index, GT_size N);
ST_double GtoolsStatsMeanIndexWeighted     (ST_double *source, ST_double *weights, GT_size *index, GT_size N);
ST_double GtoolsStatsQuantileIndexWeighted (ST_double *source, ST_double *weights, GT_size *index, GT_size N);

ST_double GtoolsStatsDivide    (ST_double a, ST_double b);
ST_double GtoolsStatsMin       (ST_double *source, GT_size N);
ST_double GtoolsStatsMax       (ST_double *source, GT_size N);
ST_double GtoolsStatsAbsMin    (ST_double *source, GT_size N);
ST_double GtoolsStatsAbsMax    (ST_double *source, GT_size N);
ST_double GtoolsStatsSignedMin (ST_double *source, GT_size N);
ST_double GtoolsStatsSignedMax (ST_double *source, GT_size N);

ST_double GtoolsStatsDot            (ST_double *v1, ST_double *v2, GT_size N, ST_double *weights);
ST_double GtoolsStatsSS             (ST_double *source, GT_size N, ST_double *weights);
ST_double GtoolsStatsMean           (ST_double *source, GT_size N, ST_double *weights);
ST_double GtoolsStatsNorm           (ST_double *source, GT_size N, ST_double *weights);
ST_double GtoolsStatsBiasedStd      (ST_double *source, GT_size N, ST_double *weights);
ST_double GtoolsStatsBiasedVariance (ST_double *source, GT_size N, ST_double *weights);

ST_double GtoolsStatsDotUnweighted            (ST_double *v1, ST_double *v2, GT_size N);
ST_double GtoolsStatsSSUnweighted             (ST_double *source, GT_size N);
ST_double GtoolsStatsMeanUnweighted           (ST_double *source, GT_size N);
ST_double GtoolsStatsStdUnweighted            (ST_double *source, GT_size N);
ST_double GtoolsStatsVarianceUnweighted       (ST_double *source, GT_size N);
ST_double GtoolsStatsBiasedStdUnweighted      (ST_double *source, GT_size N);
ST_double GtoolsStatsBiasedVarianceUnweighted (ST_double *source, GT_size N);
ST_double GtoolsStatsNormUnweighted           (ST_double *source, GT_size N);

ST_double GtoolsStatsDotWeighted            (ST_double *v1, ST_double *v2, GT_size N, ST_double *weights);
ST_double GtoolsStatsSSWeighted             (ST_double *source, GT_size N, ST_double *weights);
ST_double GtoolsStatsMeanWeighted           (ST_double *source, GT_size N, ST_double *weights);
ST_double GtoolsStatsBiasedStdWeighted      (ST_double *source, GT_size N, ST_double *weights);
ST_double GtoolsStatsBiasedVarianceWeighted (ST_double *source, GT_size N, ST_double *weights);
ST_double GtoolsStatsNormWeighted           (ST_double *source, GT_size N, ST_double *weights);

/**********************************************************************
 *                            HDFE Solvers                            *
 **********************************************************************/

typedef GT_int (*GtoolsAlgorithmHDFE)(
    struct GtoolsHash *,
    GT_size,
    ST_double *,
    ST_double *,
    ST_double *,
    GT_size,
    ST_double
);

GT_int GtoolsAlgorithmMAP (
    struct GtoolsHash *GtoolsHashInfo,
    GT_size   khashes,
    ST_double *sources,
    ST_double *weights,
    ST_double *targets,
    GT_size   ktargets,
    ST_double tol
);

GT_int GtoolsAlgorithmCG(
    struct GtoolsHash *GtoolsHashInfo,
    GT_size   khashes,
    ST_double *sources,
    ST_double *weights,
    ST_double *targets,
    GT_size   ktargets,
    ST_double tol
);

GT_int GtoolsAlgorithmSQUAREM(
    struct GtoolsHash *GtoolsHashInfo,
    GT_size   khashes,
    ST_double *sources,
    ST_double *weights,
    ST_double *targets,
    GT_size   ktargets,
    ST_double tol
);

GT_int GtoolsAlgorithmIronsTuck(
    struct GtoolsHash *GtoolsHashInfo,
    GT_size   khashes,
    ST_double *sources,
    ST_double *weights,
    ST_double *targets,
    GT_size   ktargets,
    ST_double tol
);

GT_int GtoolsAlgorithmBergeIronsTuck(
    struct GtoolsHash *GtoolsHashInfo,
    GT_size   khashes,
    ST_double *sources,
    ST_double *weights,
    ST_double *targets,
    GT_size   ktargets,
    ST_double tol
);

/**********************************************************************
 *                           HDFE Internals                           *
**********************************************************************/

ST_double GtoolsAbsorbHalperin(
    struct GtoolsHash *GtoolsHashInfo,
    GT_size   khashes,
    ST_double *sources,
    ST_double *weights,
    ST_double *targets,
    GT_size   ktargets,
    ST_double tol 
);

ST_double GtoolsAbsorbHalperinUnweighted(
    struct GtoolsHash *GtoolsHashInfo,
    GT_size   khashes,
    ST_double *sources,
    ST_double *weights,
    ST_double *targets,
    GT_size   ktargets,
    ST_double tol 
);

ST_double GtoolsAbsorbHalperinWeighted(
    struct GtoolsHash *GtoolsHashInfo,
    GT_size   khashes,
    ST_double *sources,
    ST_double *weights,
    ST_double *targets,
    GT_size   ktargets,
    ST_double tol
);

ST_double GtoolsAbsorbHalperinBuffer(
    struct GtoolsHash *GtoolsHashInfo,
    GT_size   khashes,
    ST_double *sources,
    ST_double *weights,
    ST_double *targets,
    GT_size   ktargets,
    ST_double tol,
    ST_double *allbuffer
);

ST_double GtoolsAbsorbHalperinBufferUnweighted(
    struct GtoolsHash *GtoolsHashInfo,
    GT_size   khashes,
    ST_double *sources,
    ST_double *weights,
    ST_double *targets,
    GT_size   ktargets,
    ST_double tol,
    ST_double *allbuffer
);

ST_double GtoolsAbsorbHalperinBufferWeighted(
    struct GtoolsHash *GtoolsHashInfo,
    GT_size   khashes,
    ST_double *sources,
    ST_double *weights,
    ST_double *targets,
    GT_size   ktargets,
    ST_double tol,
    ST_double *allbuffer
);

ST_double GtoolsAbsorbHalperinSymm(
    struct GtoolsHash *GtoolsHashInfo,
    GT_size   khashes,
    ST_double *sources,
    ST_double *weights,
    ST_double *targets,
    GT_size   ktargets,
    ST_double tol,
    ST_double *allbuffer
);

ST_double GtoolsAbsorbHalperinSymmUnweighted(
    struct GtoolsHash *GtoolsHashInfo,
    GT_size   khashes,
    ST_double *sources,
    ST_double *weights,
    ST_double *targets,
    GT_size   ktargets,
    ST_double tol,
    ST_double *allbuffer
);

ST_double GtoolsAbsorbHalperinSymmWeighted(
    struct GtoolsHash *GtoolsHashInfo,
    GT_size   khashes,
    ST_double *sources,
    ST_double *weights,
    ST_double *targets,
    GT_size   ktargets,
    ST_double tol,
    ST_double *allbuffer
);

void GtoolsOptimizeOrder(struct GtoolsHash *GtoolsHashInfo, GT_size khashes, GT_size *order);

ST_double GtoolsAbsorbBerge(
    struct GtoolsHash *GtoolsHashInfo,
    GT_size   khashes,
    ST_double *sources,
    ST_double *weights,
    ST_double *targets,
    GT_size   ktargets,
    ST_double tol,
    ST_double *allbuffer
);

ST_double GtoolsAbsorbBergeUnweighted(
    struct GtoolsHash *GtoolsHashInfo,
    GT_size   khashes,
    ST_double *sources,
    ST_double *weights,
    ST_double *targets,
    GT_size   ktargets,
    ST_double tol,
    ST_double *allbuffer
);

ST_double GtoolsAbsorbBergeWeighted(
    struct GtoolsHash *GtoolsHashInfo,
    GT_size   khashes,
    ST_double *sources,
    ST_double *weights,
    ST_double *targets,
    GT_size   ktargets,
    ST_double tol,
    ST_double *allbuffer
);

#endif
