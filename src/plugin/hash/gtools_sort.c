#include "gtools_sort.h"

/**
 * @brief Counting or radix sort on 64-bit hash with index
 *
 * Perform a counting or radix sort on an array of 64-bit integers. The radix
 * sort performs 64 / d passes of the counting sort, where the set of integers
 * is sorted d-bits at a time. In order to achiave this, we sort
 *
 *     kth bit chunk = (x[i] >> d * k) & 0xff
 *
 * The 0th d-bit chunk, then the 1st, and so on. We sort 16 bits at a time.
 * An 8-bit at a time version is also available.
 *
 * @param hash hash to sort
 * @param index Stata index of sort
 * @param N number of elements
 * @param verbose Print sorting info to Stata
 * @param hash_level whether we used a bijection (0) or a 128-bit hash (1)
 * @return stable sorted @hash, with @index sorted as well
 */
ST_retcode gf_sort_hash (
    uint64_t *hash,
    GT_size *index,
    GT_size N,
    GT_bool verbose,
    GT_size ctol)
{
    GT_size i;
    ST_retcode rc = 0;

    GTOOLS_MIN (hash, N, min, i)
    GTOOLS_MAX (hash, N, max, i)

    uint64_t range = max - min + 1;
    // uint64_t ctol  = pow(2, 24);

    if ( range < ctol ) {
        if ( (rc = gf_counting_sort (hash, index, N, min, max)) ) return(rc);
        if ( verbose ) {
            sf_printf("Counting sort on hash; min = "
                      GT_size_cfmt", max = "
                      GT_size_cfmt"\n", min, max);
        }
    }
    else if ( max < pow(2, 16) ) {
        if ( (rc = gf_radix_sort8_16 (hash, index, N)) ) return(rc);
        if ( verbose ) {
            sf_printf("Radix sort on 16-bit hash (8-bits at a time)\n");
        }
    }
    else if ( max < pow(2, 24) ) {
        if ( (rc = gf_radix_sort12_24 (hash, index, N)) ) return(rc);
        if ( verbose ) {
            sf_printf("Radix sort on 24-bit hash (12-bits at a time)\n");
        }
    }
    else if ( max < pow(2, 32) ) {
        if ( (rc = gf_radix_sort16_32 (hash, index, N)) ) return(rc);
        if ( verbose ) {
            sf_printf("Radix sort on 32-bit hash (16-bits at a time)\n");
        }
    }
    else {
        if ( (rc = gf_radix_sort16 (hash, index, N)) ) return(rc);
        if ( verbose ) {
            sf_printf("Radix sort on 64-bit hash (16-bits at a time)\n");
        }
    }

    return (rc);
}

/**
 * @brief Radix sort with index (8-bit)
 *
 * Perform radix sort, additionally storing data shuffle in index
 *
 * @param hash hash to sort
 * @param index Hash sort index
 * @param N number of elements
 * @return Radix sort on hash array.
 */
ST_retcode gf_radix_sort8 (
    uint64_t *hash,
    GT_size *index,
    GT_size N)
{
	radixCounts8 counts;
	memset (&counts, 0, 256 * 8 * sizeof(uint32_t));

    GT_size i;
	uint64_t *hcopy  = (uint64_t *) calloc(N, sizeof(uint64_t));
	uint64_t *ixcopy = (uint64_t *) calloc(N, sizeof(uint64_t));

    if ( hcopy  == NULL ) return (sf_oom_error("radixSort", "hcopy"));
    if ( ixcopy == NULL ) return (sf_oom_error("radixSort", "ixcopy"));

	uint32_t byte8,
             byte7,
             byte6,
             byte5,
             byte4,
             byte3,
             byte2,
             byte1;

    uint32_t offset8 = 0,
             offset7 = 0,
             offset6 = 0,
             offset5 = 0,
             offset4 = 0,
             offset3 = 0,
             offset2 = 0,
             offset1 = 0;

	// calculate counts
	// ----------------

	for(i = 0; i < N; i++) {
		byte8 =  hash[i]        & 0xff;
		byte7 = (hash[i] >> 8)  & 0xff;
		byte6 = (hash[i] >> 16) & 0xff;
		byte5 = (hash[i] >> 24) & 0xff;
		byte4 = (hash[i] >> 32) & 0xff;
		byte3 = (hash[i] >> 40) & 0xff;
		byte2 = (hash[i] >> 48) & 0xff;
		byte1 = (hash[i] >> 56) & 0xff;

		counts.c8[byte8]++;
		counts.c7[byte7]++;
		counts.c6[byte6]++;
		counts.c5[byte5]++;
		counts.c4[byte4]++;
		counts.c3[byte3]++;
		counts.c2[byte2]++;
		counts.c1[byte1]++;
	}

	// convert counts to offsets
	// -------------------------

	for(i = 0; i < 256; i++) {
		byte8 = offset8 + counts.c8[i];
		byte7 = offset7 + counts.c7[i];
		byte6 = offset6 + counts.c6[i];
		byte5 = offset5 + counts.c5[i];
		byte4 = offset4 + counts.c4[i];
		byte3 = offset3 + counts.c3[i];
		byte2 = offset2 + counts.c2[i];
		byte1 = offset1 + counts.c1[i];

		counts.c8[i] = offset8;
		counts.c7[i] = offset7;
		counts.c6[i] = offset6;
		counts.c5[i] = offset5;
		counts.c4[i] = offset4;
		counts.c3[i] = offset3;
		counts.c2[i] = offset2;
		counts.c1[i] = offset1;

		offset8 = byte8;
		offset7 = byte7;
		offset6 = byte6;
		offset5 = byte5;
		offset4 = byte4;
		offset3 = byte3;
		offset2 = byte2;
		offset1 = byte1;
	}

	// radix
	// -----

	for(i = 0; i < N; i++) {
		byte8 = hash[i] & 0xff;
		hcopy[counts.c8[byte8]]  = hash[i];
		ixcopy[counts.c8[byte8]] = index[i];
		counts.c8[byte8]++;
	}

	for(i = 0; i < N; i++) {
		byte7 = (hcopy[i] >> 8) & 0xff;
		hash[counts.c7[byte7]]  = hcopy[i];
		index[counts.c7[byte7]] = ixcopy[i];
		counts.c7[byte7]++;
	}

	for(i = 0; i < N; i++) {
		byte6 = (hash[i] >> 16) & 0xff;
		hcopy[counts.c6[byte6]]  = hash[i];
		ixcopy[counts.c6[byte6]] = index[i];
		counts.c6[byte6]++;
	}

	for(i = 0; i < N; i++) {
		byte5 = (hcopy[i] >> 24) & 0xff;
		hash[counts.c5[byte5]]  = hcopy[i];
		index[counts.c5[byte5]] = ixcopy[i];
		counts.c5[byte5]++;
	}

	for(i = 0; i < N; i++) {
		byte4 = (hash[i] >> 32) & 0xff;
		hcopy[counts.c4[byte4]]  = hash[i];
		ixcopy[counts.c4[byte4]] = index[i];
		counts.c4[byte4]++;
	}

	for(i = 0; i < N; i++) {
		byte3 = (hcopy[i] >> 40) & 0xff;
		hash[counts.c3[byte3]]  = hcopy[i];
		index[counts.c3[byte3]] = ixcopy[i];
		counts.c3[byte3]++;
	}

	for(i = 0; i < N; i++) {
		byte2 = (hash[i] >> 48) & 0xff;
		hcopy[counts.c2[byte2]]  = hash[i];
		ixcopy[counts.c2[byte2]] = index[i];
		counts.c2[byte2]++;
	}

	for(i = 0; i < N; i++) {
		byte1 = (hcopy[i] >> 56) & 0xff;
		hash[counts.c1[byte1]]  = hcopy[i];
		index[counts.c1[byte1]] = ixcopy[i];
		counts.c1[byte1]++;
	}

	free(hcopy);
	free(ixcopy);

    return (0);
}

/**
 * @brief Radix sort with index (16-bit)
 *
 * Perform radix sort, additionally storing data shuffle in index
 *
 * @param hash hash to sort
 * @param index Hash sort index
 * @param N number of elements
 * @return Radix sort on hash array.
 */
ST_retcode gf_radix_sort16 (
    uint64_t *hash,
    GT_size *index,
    GT_size N)
{
    GT_size size = 65536;

    // Allocate space for index and hash copies
    // ----------------------------------------

    GT_size i;
	uint64_t *hcopy  = (uint64_t *) calloc(N, sizeof(uint64_t));
	uint64_t *ixcopy = (uint64_t *) calloc(N, sizeof(uint64_t));

    if ( hcopy  == NULL ) return (sf_oom_error("radixSort", "hcopy"));
    if ( ixcopy == NULL ) return (sf_oom_error("radixSort", "ixcopy"));

	uint32_t byte4,
             byte3,
             byte2,
             byte1;

    uint32_t offset4 = 0,
             offset3 = 0,
             offset2 = 0,
             offset1 = 0;

    // Initialize counts to 0
    // ----------------------

    struct radixCounts16 *counts = malloc(sizeof(*counts));
	counts->c4 = calloc(size, sizeof(uint32_t));
	counts->c3 = calloc(size, sizeof(uint32_t));
	counts->c2 = calloc(size, sizeof(uint32_t));
	counts->c1 = calloc(size, sizeof(uint32_t));

    for (i = 0; i < size; i++) {
        counts->c4[0] = 0;
        counts->c3[0] = 0;
        counts->c2[0] = 0;
        counts->c1[0] = 0;
    }

	// Calculate counts
	// ----------------

	for(i = 0; i < N; i++) {
		byte4 =  hash[i]        & 0xffff;
		byte3 = (hash[i] >> 16) & 0xffff;
		byte2 = (hash[i] >> 32) & 0xffff;
		byte1 = (hash[i] >> 48) & 0xffff;

		counts->c4[byte4]++;
		counts->c3[byte3]++;
		counts->c2[byte2]++;
		counts->c1[byte1]++;
	}

	// Convert counts to offsets
	// -------------------------

	for(i = 0; i < size; i++) {
		byte4 = offset4 + counts->c4[i];
		byte3 = offset3 + counts->c3[i];
		byte2 = offset2 + counts->c2[i];
		byte1 = offset1 + counts->c1[i];

		counts->c4[i] = offset4;
		counts->c3[i] = offset3;
		counts->c2[i] = offset2;
		counts->c1[i] = offset1;

		offset4 = byte4;
		offset3 = byte3;
		offset2 = byte2;
		offset1 = byte1;
	}

	// Radix bit
	// ---------

	for(i = 0; i < N; i++) {
		byte4 = hash[i] & 0xffff;
		hcopy[counts->c4[byte4]]  = hash[i];
		ixcopy[counts->c4[byte4]] = index[i];
		counts->c4[byte4]++;
	}

	for(i = 0; i < N; i++) {
		byte3 = (hcopy[i] >> 16) & 0xffff;
		hash[counts->c3[byte3]]  = hcopy[i];
		index[counts->c3[byte3]] = ixcopy[i];
		counts->c3[byte3]++;
	}

	for(i = 0; i < N; i++) {
		byte2 = (hash[i] >> 32) & 0xffff;
		hcopy[counts->c2[byte2]]  = hash[i];
		ixcopy[counts->c2[byte2]] = index[i];
		counts->c2[byte2]++;
	}

	for(i = 0; i < N; i++) {
		byte1 = (hcopy[i] >> 48) & 0xffff;
		hash[counts->c1[byte1]]  = hcopy[i];
		index[counts->c1[byte1]] = ixcopy[i];
		counts->c1[byte1]++;
	}

	free(counts->c1);
	free(counts->c2);
	free(counts->c3);
	free(counts->c4);
	free(counts);
	free(hcopy);
	free(ixcopy);

    return (0);
}

/**
 * @brief Radix sort with index (16-bit for up to 32-bit integers)
 *
 * Perform radix sort, additionally storing data shuffle in index
 *
 * @param hash integer to sort (max 32-bit)
 * @param index Hash sort index
 * @param N number of elements
 * @return Radix sort on integer array (up to 32 bits).
 */
ST_retcode gf_radix_sort16_32(
    uint64_t *hash,
    GT_size *index,
    GT_size N)
{
    GT_size size = 65536;

    // Allocate space for index and hash copies
    // ----------------------------------------

    GT_size i;
	uint64_t *hcopy  = (uint64_t *) calloc(N, sizeof(uint64_t));
	uint64_t *ixcopy = (uint64_t *) calloc(N, sizeof(uint64_t));

    if ( hcopy  == NULL ) return (sf_oom_error("radixSort", "hcopy"));
    if ( ixcopy == NULL ) return (sf_oom_error("radixSort", "ixcopy"));

	uint32_t byte2,
             byte1;

    uint32_t offset2 = 0,
             offset1 = 0;

    // Initialize counts to 0
    // ----------------------

    struct radixCounts16_32 *counts = malloc(sizeof(*counts));
	counts->c2 = calloc(size, sizeof(uint32_t));
	counts->c1 = calloc(size, sizeof(uint32_t));

    for (i = 0; i < size; i++) {
        counts->c2[0] = 0;
        counts->c1[0] = 0;
    }

	// Calculate counts
	// ----------------

	for(i = 0; i < N; i++) {
		byte2 =  hash[i]        & 0xffff;
		byte1 = (hash[i] >> 16) & 0xffff;

		counts->c2[byte2]++;
		counts->c1[byte1]++;
	}

	// Convert counts to offsets
	// -------------------------

	for(i = 0; i < size; i++) {
		byte2 = offset2 + counts->c2[i];
		byte1 = offset1 + counts->c1[i];

		counts->c2[i] = offset2;
		counts->c1[i] = offset1;

		offset2 = byte2;
		offset1 = byte1;
	}

	// Radix bit
	// ---------

	for(i = 0; i < N; i++) {
		byte2 = hash[i] & 0xffff;
		hcopy[counts->c2[byte2]]  = hash[i];
		ixcopy[counts->c2[byte2]] = index[i];
		counts->c2[byte2]++;
	}

	for(i = 0; i < N; i++) {
		byte1 = (hcopy[i] >> 16) & 0xffff;
		hash[counts->c1[byte1]]  = hcopy[i];
		index[counts->c1[byte1]] = ixcopy[i];
		counts->c1[byte1]++;
	}

	free(counts->c1);
	free(counts->c2);
	free(counts);
	free(hcopy);
	free(ixcopy);

    return (0);
}

/**
 * @brief Radix sort with index (12-bit for up to 24-bit integers)
 *
 * Perform radix sort, additionally storing data shuffle in index
 *
 * @param hash integer to sort (max 24-bit)
 * @param index Hash sort index
 * @param N number of elements
 * @return Radix sort on integer array (up to 24 bits).
 */
ST_retcode gf_radix_sort12_24(
    uint64_t *hash,
    GT_size *index,
    GT_size N)
{
    GT_size size = 4096;

    // Allocate space for index and hash copies
    // ----------------------------------------

    GT_size i;
    uint64_t *hcopy  = (uint64_t *) calloc(N, sizeof(uint64_t));
    uint64_t *ixcopy = (uint64_t *) calloc(N, sizeof(uint64_t));

    if ( hcopy  == NULL ) return (sf_oom_error("radixSort", "hcopy"));
    if ( ixcopy == NULL ) return (sf_oom_error("radixSort", "ixcopy"));

    uint32_t byte2,
             byte1;

    uint32_t offset2 = 0,
             offset1 = 0;

    // Initialize counts to 0
    // ----------------------

    struct radixCounts12_24 *counts = malloc(sizeof(*counts));
    counts->c2 = calloc(size, sizeof(uint32_t));
    counts->c1 = calloc(size, sizeof(uint32_t));

    for (i = 0; i < size; i++) {
        counts->c2[0] = 0;
        counts->c1[0] = 0;
    }

    // Calculate counts
    // ----------------

    for(i = 0; i < N; i++) {
        byte2 =  hash[i]        & 0xfff;
        byte1 = (hash[i] >> 12) & 0xfff;

        counts->c2[byte2]++;
        counts->c1[byte1]++;
    }

    // Convert counts to offsets
    // -------------------------

	for(i = 0; i < size; i++) {
		byte2 = offset2 + counts->c2[i];
		byte1 = offset1 + counts->c1[i];

		counts->c2[i] = offset2;
		counts->c1[i] = offset1;

		offset2 = byte2;
		offset1 = byte1;
	}

    // Radix bit
    // ---------

    for(i = 0; i < N; i++) {
        byte2 = hash[i] & 0xfff;
        hcopy[counts->c2[byte2]]  = hash[i];
        ixcopy[counts->c2[byte2]] = index[i];
        counts->c2[byte2]++;
    }

    for(i = 0; i < N; i++) {
        byte1 = (hcopy[i] >> 12) & 0xfff;
        hash[counts->c1[byte1]]  = hcopy[i];
        index[counts->c1[byte1]] = ixcopy[i];
        counts->c1[byte1]++;
    }

    free(counts->c1);
    free(counts->c2);
    free(counts);
    free(hcopy);
    free(ixcopy);

    return (0);
}

/**
 * @brief Radix sort with index (8-bit for up to 16-bit integers)
 *
 * Perform radix sort, additionally storing data shuffle in index
 *
 * @param hash integer to sort (max 16-bit)
 * @param index Hash sort index
 * @param N number of elements
 * @return Radix sort on integer array (up to 16 bits).
 */
ST_retcode gf_radix_sort8_16(
    uint64_t *hash,
    GT_size *index,
    GT_size N)
{
    GT_size size = 256;

    // Allocate space for index and hash copies
    // ----------------------------------------

    GT_size i;
    uint64_t *hcopy  = (uint64_t *) calloc(N, sizeof(uint64_t));
    uint64_t *ixcopy = (uint64_t *) calloc(N, sizeof(uint64_t));

    if ( hcopy  == NULL ) return (sf_oom_error("radixSort", "hcopy"));
    if ( ixcopy == NULL ) return (sf_oom_error("radixSort", "ixcopy"));

    uint32_t byte2,
             byte1;

    uint32_t offset2 = 0,
             offset1 = 0;

    // Initialize counts to 0
    // ----------------------

    struct radixCounts8_16 *counts = malloc(sizeof(*counts));
    counts->c2 = calloc(size, sizeof(uint32_t));
    counts->c1 = calloc(size, sizeof(uint32_t));

    for (i = 0; i < size; i++) {
        counts->c2[0] = 0;
        counts->c1[0] = 0;
    }

    // Calculate counts
    // ----------------

    for(i = 0; i < N; i++) {
        byte2 =  hash[i]       & 0xff;
        byte1 = (hash[i] >> 8) & 0xff;

        counts->c2[byte2]++;
        counts->c1[byte1]++;
    }

    // Convert counts to offsets
    // -------------------------

	for(i = 0; i < size; i++) {
		byte2 = offset2 + counts->c2[i];
		byte1 = offset1 + counts->c1[i];

		counts->c2[i] = offset2;
		counts->c1[i] = offset1;

		offset2 = byte2;
		offset1 = byte1;
	}

    // Radix bit
    // ---------

    for(i = 0; i < N; i++) {
        byte2 = hash[i] & 0xff;
        hcopy[counts->c2[byte2]]  = hash[i];
        ixcopy[counts->c2[byte2]] = index[i];
        counts->c2[byte2]++;
    }

    for(i = 0; i < N; i++) {
        byte1 = (hcopy[i] >> 8) & 0xff;
        hash[counts->c1[byte1]]  = hcopy[i];
        index[counts->c1[byte1]] = ixcopy[i];
        counts->c1[byte1]++;
    }

    free(counts->c1);
    free(counts->c2);
    free(counts);
    free(hcopy);
    free(ixcopy);

    return (0);
}

/**
 * @brief Counting sort with index
 *
 * Perform counting sort, additionally storing data shuffle
 * in index variable.
 *
 * @param hash hash to sort
 * @param index Hash sort index
 * @param N number of elements
 * @param min Smallest hash
 * @param max Largest hash
 * @return Counting sort on hash array.
 */
ST_retcode gf_counting_sort (
    uint64_t *hash,
    GT_size *index,
    GT_size N,
    uint64_t min,
    uint64_t max)
{

    GT_size i, j, offset = 0;
    uint64_t range = max - min + 1;

    // Allocate space for x, index copies, and freq
    // --------------------------------------------

    uint64_t *xcopy = calloc(N, sizeof *xcopy);
    GT_size  *icopy = calloc(N, sizeof *icopy);
    GT_size  *count = calloc(range + 1, sizeof *count);

    if ( xcopy == NULL ) return(sf_oom_error("gf_counting_sort_hash", "xcopy"));
    if ( icopy == NULL ) return(sf_oom_error("gf_counting_sort_hash", "icopy"));
    if ( count == NULL ) return(sf_oom_error("gf_counting_sort_hash", "count"));

    uint64_t *xptr;
    uint64_t *hptr;
    GT_size  *iptr;
    GT_size  *cptr;

    // Counting sort
    // -------------

    // Initialize count as 0s
    for (i = 0; i < range + 1; i++)
        count[i] = 0;

    // Copy hash, index
    memcpy(xcopy, hash,  N * sizeof(uint64_t));
    memcpy(icopy, index, N * sizeof(uint64_t));

    // Frequency count of hash
    for (hptr = hash; hptr < hash + N; hptr++)
        count[*hptr + 1 - min]++;

    // Sort the hash
    cptr = count + 1;
    for (i = 0; i < range; i++, cptr++) {
        if ( *cptr ) {
            for (j = 0; j < *cptr; j++, offset++) {
                hash[offset] = i + min;
            }
            *cptr = offset;
        }
    }

    // Copy the shuffled index
    xptr = xcopy;
    iptr = icopy;
    for (i = 0; i < N; i++, xptr++, iptr++)
        index[count[*xptr - min]++] = *iptr;

    // Free space
    free (count);
    free (xcopy);
    free (icopy);

    return (0);
}
