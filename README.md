Faster Stata for Group Operations
---------------------------------

This package was inspired by Sergio Correia's `ftools`, who extensively
uses mata in order to provide faster alternatives to `egen`, `collapse`,
`sort`, and `merge`.

This package uses Stata plugins written in C to implement faster,
multi-threaded versions of `egen` and `collapse`, named `gegen` and
`gcollapse`. A full speed comparison is provided below.

Currently this is only available for Unix.

[ ] collapse
[ ] egen

In ftools:
    mean
    median
    sd
    sum
    count
    percent
    max
    min
    iqr
    first
    last
    firstnm
    lastnm
    percentiles (p\d+) <- What happens if I pass 3-digits?

Not in ftools:
    semean
    sebinomial
    sepoisson
    rawsum
    quantiles (p\d{1,2}(.\d+)?)

FAQs
----

### How can this be faster?

In theory, C shouldn't be faster than Stata native commands because,
as I understand it, many of Stata's underpinnings are compiled C code.
However, there are two possible explanations why this is faster than
Stata's native commands:

1. Efficiency: It is possible that Stata's algorithms are not particularly
   efficient (this is, for example, the explanation given for why `ftools`
   is faster than Stata even though Mata should not be particularly fast).

2. Multi-threading: Stata charges per core (#profit). When you implement
   multi-threading in C, however, it uses all the cores it finds. This
   package is ripe for parallelism because it implements alternatives
   to programs that oeprate on groups, and each group can be processed
   independent of other groups.

### Why use platform-dependent plugins?

C is platform dependent and I don't have access to Stata on Windows or
OSX. Sorry! I use Linux on my personal computer and on all the servers
where I do my work. If anyone is willing to try compiling the plugins
out on Windows and OSX, I'd be happy to take pull requests!

NOTE:

This is intented as a proof-of-concept at the moment and is very alpha.
The code has not been optimized at all and several features area missing:

- I ignore types and do all operations using double precision
- I sort using Stata
- It is only available in Unix
- It is very memory hungry
- The C implementation is very crude and relatively inefficient (e.g. no multithreading)
- It does not sort the output data by default

Despite this, it has some advantages over gtools
- It's up to 4-6x faster than fcollapse, but that's not a fair comparison because it does not sort the collapse data by default. I have not implemented sorting an arbitrary number of variables of mixed type in C. If I sort using stata, it's only just over 3 times faster. I expect that sorting in C would result in a speedup north of 4x over fcollapse.
- fcollapse requires the by variables be all numeric or all strings, whereas there is no such limitation here

gcollapse's improvement over fcollapse is not strict:

Improvements over fcollapse:
- Can have any mix of numeric and string variables as grouping variables, as in Stata
- Percentiles are computed to match Stata's (fcollapse uses a quantile function from moremata that does not necessarily match collapse's percentile function)
- Can have quantiles not just percentiles (e.g. p2.5 and p.97.5 would be valid stat calls in gcollapse )

Things it does worse than fcollapse
- Memory management is worse
- Computing quantiles is MASSIVELY inefficient: Though the definition
  is slightly different than Stata's, moremata's implementation of the
  quantile function is leaps and bounds more efficient than what I'm
  doing (sort and select, and yes I did try quickselect algorithms and
  they were slower than C's built-in qsort). If you have groups in
  the order of millions and need to compute quantiles, fcollapse may
  actually be faster.
