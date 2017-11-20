Stata's `altdef` formula in `pctile` gives the wrong result for certain certain numbers in IC and SE (this will also affect `xtile` one the bug with `altdef` there is fixed).

clear
set obs 89750
gen double x = 7.2439548890446011

pctile fp = x, nq(500) altdef
pctile double dp = x, nq(500) altdef
_pctile x, nq(500) altdef

assert (x[1] == fp) | mi(fp)
assert (x[1] == dp) | mi(dp)

The above assertions should be true, or at least the second one, but both fail. (Note that in Stata/MP, the second assertion goes through; at least that was the case for me in testing). We can see that

. levelsof fp
7.243954658508301

. levelsof dp
7.2439548890446 7.243954889044601 7.243954889044602

This happens because `altdef` takes an average. The formula is:

scalar perc = 100 * 148 / 500
scalar ith  = (_N + 1) * perc / 100
scalar i    = floor(ith)
scalar h    = ith - i
scalar q    = (1 - h) * x[i] + h * x[i + 1]

assert x[i] == x[i - 1]
assert q == dp[148]
assert q == x[i]

The first two assertions succeeded but the third fails. Stata's `pctile` fails to recognize that `x[i]` is equal to `x[i - 1]`.

(Note: Naturally my actual use case involved a variable that had different values, but one of them was `7.2439548890446011` and that caused the problem.)
