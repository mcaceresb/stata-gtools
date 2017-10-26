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

struct  radixCounts16 {
    uint32_t *c4;
    uint32_t *c3;
    uint32_t *c2;
    uint32_t *c1;
};

int mf_sort_hash     (uint64_t *hash, size_t *index, size_t N, short verbose);
int mf_radix_sort8   (uint64_t *hash, size_t *index, size_t N);
int mf_radix_sort16  (uint64_t *hash, size_t *index, size_t N);
int mf_counting_sort (uint64_t *hash, size_t *index, size_t N, uint64_t min, uint64_t max);


#endif
