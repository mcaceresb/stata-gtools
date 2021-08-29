Benchmarks
==========

!!! info "Note"
    Stata tours massive speed improvements to [sort and collapse](https://www.stata.com/new-in-stata/faster-stata-speed-improvements/)
    as of version 17. I do not have access to Stata 17 so I cannot
    test this myself, but please be aware the benchmarks below 
    are presumably outdated for `gcollapse` and `hashsort`.

Hardware
--------

Stata/MP benchmarks were run on a Linux setver with 8 cores.

```
Program:   Stata/MP 15.2 (8 cores)
OS:        x86_64 GNU/Linux
Processor: Intel(R) Xeon(R) CPU E5-2620 v3 @ 2.50GHz
Cores:     2 sockets with 6 cores per socket and 2 virtual threads per core.
Memory:    141GiB
Swap:      325GiB
```

Stata/IC benchmarks favor gtools more sharply, as do benchmarks on
Stata 14 and earlier.

Summary
-------

### Versus native equivalents

<!--

| Function     | Versus        | Speedup (IC)    | Speedup (MP) |
| ------------ | ------------- | --------------- | ------------ |
| gcollapse    | collapse      |  9 to 300       |  4 to 120    |
| gcontract    | contract      |  5 to 7         |  2.5 to 4    |
| gegen        | egen          |  9 to 26 (+)    |  4 to 9 (+)  |
| gisid        | isid          |  8 to 30        |  4 to 14     |
| glevelsof    | levelsof      |  3 to 13        |  2.5 to 7    |
| gquantiles   | xtile         |  10 to 30 (-)   | 13 to 25     |
|              | pctile        |  13 to 38 (-)   | 2.5 to 5.5   |
|              | \_pctile      |  25 to 40       | 3 to 5       |

<small>(+) Only 'egen group' was benchmarked.</small>

-->

<!-- 

<small>(-) Benchmarks computed 10 quantiles. When computing a large
number of quantiles (e.g. thousands) `pctile` and `xtile` are prohibitively
slow due to the way they are written; in that case gquantiles is hundreds
or thousands of times faster.</small>

In the case of gcollapse, the upper end of the speed improvements are for
quantiles (e.g. median, iqr, p90) and few groups. There `gcollapse` really can
be hundreds of times faster.

The reason is that Stata's algorithm for computing percentiles
sorts the source variables _every time_ a percentile is to
be computed. `gcollapse` (and `gegen`), by contrast, use
[quickselect](https://en.wikipedia.org/wiki/Quickselect), which is very
efficient. While its average complexity is O(N log N), like quicksort,
it can run in up to linear time, O(N). In practice it is much faster
than quicksort and, since it modifies the data in place, subsequent
calls to compute percentiles run much faster.

### Versus SSC/SJ equivalents

| Function     | Versus             | Speedup (IC)    | Speedup (MP)    |
| ------------ | ------------------ | --------------- | --------------- |
| fasterxtile  | fastxtile (SSC)    |  20 to 30       |  2.5 to 3.5     |
|              | egenmisc (SSC) (-) |  8 to 25        |  2.5 to 6       |
|              | astile (SSC) (-)   |  8 to 12        |  3.5 to 6       |
| gunique      | unique (SSC)       |  4 to 26        |  4 to 12        |
| gdistinct    | distinct (SJ)      |  4 to 26        |  4 to 12        |
| gtoplevelsof | gcontract (Gtools) |  1.5 to 6       |  2 to 6.5       |

<small>(-) `fastxtile` from egenmisc and `astile` were benchmarked against
`gquantiles, xtile` (`fasterxtile`) using `by()`.</small>

-->

<!-- 

`gtoplevelsof` does not quite have an equivalent in SSC/SJ. The command
`groups` with the `select` option is very similar, but it is dozens of
times slower then `gtoplevelsof` when the data is large (millions of
rows). This seems to be mainly because `groups` is not written as a way
to quickly see the top groups of a data set, and it offers relatively
different functionality (and more options).  Hence I felt the comparison
might be unfair.

Note that `fasterxtile` is merely an alias for `gquantiles, xtile`.

-->

### Versus ftools

!!! info "Note"
    Updated benchmarks against ftools are forthcomming. ftools is a very
    good speed improvement already, and if you are working largely in `mata`
    I heartily recommend its API. However, it is still slower than gtools by
    a factor of 2 to 10 (that is, gtools is 50% to 90% faster).

The commands here are also faster than the commands provided by `ftools`;
further, `gtools` commands take a mix of string and numeric variables, a
limitation of `ftools`.

<!--

| Gtools      | Ftools          | Speedup (IC) |
| ----------- | --------------- | ------------ |
| gcollapse   | fcollapse       | 2-9          |
| gegen       | fegen           | 2.5-4 (+)    |
| gisid       | fisid           | 4-14         |
| glevelsof   | flevelsof       | 1.5-13       |
| hashsort    | fsort           | 2.5-4        |

<small>(+) Only 'egen group' was benchmarked rigorously.</small>

-->

### Versus sort

I have implemented a hash-based sorting command, `hashsort`. This is
_**not**_ an official part of gtools because it is not always faster
than regular sort. It has its uses, however. Namely in Stata/IC it will
usually be faster than regular `sort`, and both in Stata/IC and in
Stata/MP it will also be faster than Stata's own `gsort`:

| Function    | Versis   | Speedup (IC) | Speedup (MP)   |
| ----------- | -------- | ------------ | -------------- |
| hashsort    | sort     | 2.5 to 4     |  0.7 to 0.9    |
|             | gsort    | 2 to 18      |  1 to 6        |

Random data used
----------------

We create a data set with the number of groups we want and expand it to
the number of observations we want. For instance, we create a dataset
with 10 observations and then expand it to 10M (via `expand 1000000`).
Each of the variable names should be indicative of what they are (`int1`
is an integer, `double1` is a double, and so on).

String variables were concatenated from a mix of arbitrary ascii
characters and random strings from the `ralpha` package. All variables
include missing values and all strings include some blanks.

```
Contains data
  obs:    10,000,000
 vars:            19
 size: 1,460,000,000
------------------------------------------------------------
              storage   display    value
variable name   type    format     label      variable label
------------------------------------------------------------
str_long        str5    %9s
str_mid         str3    %9s
str_short       str3    %9s
str_4           str11   %11s
str_12          str12   %12s
str_32          str32   %32s
int1            long    %12.0g
int2            double  %10.0g
int3            long    %12.0g
double1         double  %10.0g
double2         double  %10.0g
double3         double  %10.0g
runif_small_flt float   %9.0g
runif_small_dbl double  %10.0g
rnorm_small_flt float   %9.0g
rnorm_small_dbl double  %10.0g
runif_big_flt   float   %9.0g
runif_big_dbl   double  %10.0g
rnorm_big_flt   float   %9.0g
------------------------------------------------------------
Sorted by:
```

Stata/MP Benchmarks
-------------------

### gcollapse

Simple

Complex

### greshape

### gcontract

### gduplicates drop

### gegen group

### gisid

Non-unique

Unique

### glevelsof

!!! info "Note"
    Note `levelsof` a significant speed improvement for numeric levels in
    Stata 15, which is great. However, `glevelsof` is still at least twice
    as fast for numeric levels, and orders of magnitude faster for string
    levels. Furthermore, `glevelsof` takes multiple variables and can handle
    a very large number of groups more efficienty (it can also bypass the
    maximum macro length limit via the `gen()` and `matasave` options; see
    [here](usage/glevelsof#de-duplicating-a-variable-list))

### gquantiles

pctile

xtile

with by (vs astile)

### gstats summarize

### gstats tab

### gstats winsor

Without by

With by

### gunique

### gduplicates

### hashsort

VS sort

VS gsort
