* Computing many quantiles
* ------------------------

* Stata's _pctile caps the number of quantiles to 1001. pctile uses
* _pctile internally, so to compute more than 1001 percentiles it needs
* to loop over various runs of _pctile in a very inefficient way.  This
* inefficiency carries over to xtile because that command uses pctile
* internally. (Presumably this is the reason for the limit in the user-written
* fastxtile).

* The following executes with no errors in a reasonable amount of time

clear
set obs 1000000
gen x = runiform()
_pctile x, nq(1001)
pctile p1 = x, nq(1001)
gquantiles p2 = x, pctile nq(1001)

* However, if you increase `nq` the runtimes become excessive:

drop p*
timer clear

timer on 90
pctile p1 = x, nq(5001)
timer off 90

timer on 10
gquantiles p2 = x, pctile nq(5001)
timer off 10

assert p1 == p2
timer list

* 61 seconds for only 1,00,000 observations! This is in Stata/MP with 8 cores.
* gquantiles scales nicely, by contrast:

drop p*
timer clear

timer on 10
gquantiles p2 = x, pctile nq(`=_N + 1')
timer off 10

clear
set obs 100000000
gen x = runiform() * 100

timer on 20
gquantiles p2 = x, pctile nq(`=_N + 1')
timer off 20

timer list

* That's right, gquantiles computed 100M quantiles for 100M observations in 36
* seconds, faster than pctile could compute 5,000 quantiles for 1M obsevations.
* As a side-note, using mata can afford a massive speedup, obviating the need to
* call C in case gquantiles does not do something you want. Consider:

clear all
timer clear

mata:
void function mata_pctile (string scalar newvar,
                           string scalar sourcevar,
                           real scalar nq)
{
    real scalar N
    real colvector X, quantiles, qpositions, qties, qtiesix, Q, Qties

    X = st_data(., sourcevar)
    N = rows(X)
    _sort(X, 1)
    quantiles  = ((1::(nq - 1)) * N / nq)
    qpositions = ceil(quantiles)
    qties      = (qpositions :== quantiles)
    Q          = X[qpositions]

    if ( any(qties) ) {
        qtiesix = selectindex(qties)
        Qties = X[qpositions[qtiesix] :+ 1]
        Q[qtiesix] = (Q[qtiesix] + Qties) / 2
    }

    st_addvar("`:set type'", newvar)
    st_store((1::(nq - 1)), newvar, Q)
}
end

set obs 1000000
gen x = runiform()

timer on 80
mata: mata_pctile("p0", "x", 5001)
timer off 80

timer on 90
pctile p1 = x, nq(5001)
timer off 90

timer on 10
gquantiles p2 = x, pctile nq(5001)
timer off 10

assert p0 == p1
assert p1 == p2
timer list

* Just by using mata we speeded up Stata 50 times! The mata solution does not
* scale as well as gquantiles, however:

clear
timer clear
set obs 10000000
gen x = runiform()

timer on 80
mata: mata_pctile("p0", "x", 5001)
timer off 80

timer on 10
gquantiles p2 = x, pctile nq(5001)
timer off 10

timer list

* With just 10M observations, gquantiles is still a 5x improvement over mata
* when computing many quantiles.

* Computation methods
* -------------------

* Computing quantiles involves selecting elements from an unordered two
* ways: Using a selection algorithm on the unsorted variable or sorting and
* then selecting elements of the sorted varaible.

* The internal selection algorithm of gquantiles is very fast and on average
* will run in linear O(N) time (see quickselect) The sorting algorithm runs in
* O(N log(N)) time (see quicksort).  Clearly, with few quantiles we can see
* the selection algorithm will be faster.  However, with a large number of
* quantiles running multiple iterations of the selection algorithm is clearly
* slower than doing a single sort.

clear
timer clear

set obs 10000000
gen x = rnormal() * 100

timer on 10
gquantiles p1 = x, pctile nq(2) method(1)
timer off 10

timer on 20
gquantiles p2 = x, pctile nq(2) method(2)
timer off 20

assert p1 == p2
timer list

* We can see that method 2 was more than 3 times faster for a single quantile.

timer clear

timer on 10
gquantiles p1 = x, pctile nq(10) method(1) replace
timer off 10

timer on 20
gquantiles p2 = x, pctile nq(10) method(2) replace
timer off 20

timer list

* While method 2 was still faster, computing 10 quantiles took twice the
* time it took to compute 1. By contrast, method 1 took essentially the same
* time. This is because after sorting the data, selecting elements is nearly
* instantaneous.

timer clear

timer on 10
gquantiles p1 = x, pctile nq(100) method(1) replace
timer off 10

timer on 20
gquantiles p2 = x, pctile nq(100) method(2) replace
timer off 20

timer list

* With 100 quantiles we can see that the performance of method 2 is now much
* worse than method 1. Internally, gquantiles will try to switch between the
* two methods based on the nubmer of observations and the number of quantiles.
* You might be tempted to always specify method 2 for few quantiles, but there
* is a second way in which it is slower than sorting:

timer clear
replace x = int(x)

timer on 10
gquantiles p1 = x, pctile nq(10) method(1) replace
timer off 10

timer on 20
gquantiles p2 = x, pctile nq(10) method(2) replace
timer off 20

timer list

* What happened? While both commands are faster, now method 1 is faster than
* method 2, whereas before it was 50% slower. This is because the specific
* sorting algorithm I use handles duplicates better than the selection
* algorithm.

timer clear

timer on 10
gquantiles p1 = x, pctile nq(100) method(1) replace
timer off 10

timer on 20
gquantiles p2 = x, pctile nq(100) method(2) replace
timer off 20

timer list

* Again, both are faster with duplicates, but method 1 is much faster.

* Multiple subcommands
* --------------------

* gquantiles allows the user to compute several things at once:

sysuse auto, clear
gquantiles price, _pctile xtile(x1) pctile(p1) binfreq nq(10)
matrix list r(quantiles_binfreq)
l price x1 p1 in 1/10

* Specifying quantiles and cutoffs
* --------------------------------

* gquantiles allows for several ways to specify cutoffs

sysuse auto, clear

gquantiles price, _pctile p(10(10)99)
matrix p0 = r(quantiles_used)

gquantiles p1 = price, pctile nq(10) genp(g1) xtile(x1)
gquantiles x2 = price, xtile cutpoints(p1)
gquantiles x3 = price, xtile cutquantiles(g1)

qui glevelsof p1
gquantiles x4 = price, xtile cutoffs(`r(levels)')

qui glevelsof g1
gquantiles x5 = price, xtile quantiles(`r(levels)')

matrix list p0
l p1 g1 x? in 1/10
