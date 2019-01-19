#ifndef GTOOLS_SORT
#define GTOOLS_SORT

typedef union {
	struct {
		uint32_t c8[256];
		uint32_t c7[256];
		uint32_t c6[256];
		uint32_t c5[256];
		uint32_t c4[256];
		uint32_t c3[256];
		uint32_t c2[256];
		uint32_t c1[256];
	};
	uint32_t counts[256 * 8];
} radixCounts8;

struct radixCounts16 {
    uint32_t *c4;
    uint32_t *c3;
    uint32_t *c2;
    uint32_t *c1;
};

struct radixCounts16_32 {
    uint32_t *c2;
    uint32_t *c1;
};

struct radixCounts12_24 {
    uint32_t *c2;
    uint32_t *c1;
};

struct radixCounts8_16 {
    uint32_t *c2;
    uint32_t *c1;
};

ST_retcode gf_sort_hash       (uint64_t *hash, GT_size *index, GT_size N, GT_bool verbose, GT_size ctol);
ST_retcode gf_radix_sort8     (uint64_t *hash, GT_size *index, GT_size N);
ST_retcode gf_radix_sort16    (uint64_t *hash, GT_size *index, GT_size N);
ST_retcode gf_radix_sort16_32 (uint64_t *hash, GT_size *index, GT_size N);
ST_retcode gf_radix_sort12_24 (uint64_t *hash, GT_size *index, GT_size N);
ST_retcode gf_radix_sort8_16  (uint64_t *hash, GT_size *index, GT_size N);
ST_retcode gf_counting_sort   (uint64_t *hash, GT_size *index, GT_size N, uint64_t min, uint64_t max);

#endif
