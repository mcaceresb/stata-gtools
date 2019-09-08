* Basic usage                                         
* -----------

* Syntax is largely analogous to `gcollapse`

sysuse auto, clear

gegen norm_price = normalize(price),   by(foreign)
gegen std_price  = standardize(price), by(foreign)
gegen dm_price   = demean(price),      by(foreign)
gegen rank_price = rank(price),        by(foreign)

local opts by(foreign) replace
gstats transform (standardize) std_price = price (demean) dm_mpg = mpg, `opts'
gstats transform (normalize) norm_mpg = mpg (rank) rank_price = price, `opts'
gstats transform (demean) mpg (normalize) price [w = rep78], `opts'
gstats transform (demean) mpg (normalize) xx = price, `opts' auto(#stat#_#source#)

* Range statistics
* ----------------

* This can be used to compute statistics within a specified range.
* It can also do rolling window statistics. This is similar to the
* user-written program `rangestat`:

webuse grunfeld, clear

gstats transform (range mean -3 0 year) x1 = invest
gstats transform (range mean -3 3 year) x2 = invest
gstats transform (range mean  . 3 year) x3 = invest
gstats transform (range mean -3 . year) x4 = invest

* These compute moving averages using a 3-year lag, a two-sided 3-year
* window, a 3-year lead recursive window (i.e. from a 3-year lead back
* until the first observation), and a 3-year lag reverse recursive
* window (i.e. from a 3-year lag until the last observation).

* You can also specify the boudns to be a summary statistic times a
* scalar. For example

gstats range (mean -0.5sd 0.5sd) x5 = invest

* computes the mean within half a standard deviation of invest (if we
* don't specify a range variable, then the source variable is used).
* Note that we used `gstats range` instead of `gstats transform`. This
* is simply an alias that assumes every subsequent statistic will
* be a range statistic. It is provided for ease of syntax.

* You can specify also different intervals per variable as well as a
* global interval used whenever a variable-specific interval is not
* used:

local i6 (range mean -3 0 year) x6 = invest
local i7 (range mean -0.5sd 2cv mvalue) x7 = invest
local i8 (range mean) x8 = mvalue x9 = kstock

local opts labelf(#stat:pretty#: #sourcelabel#)
gstats transform `i6' `i7' `i8', by(company) interval(-3 3 year) `opts'

* You can even exclude the current observation from the computation

gstats range (mean -3 0 year) x10 = invest, excludeself
gegen x11 = range_mean(invest), by(company) excludeself interval(-3 0 year)

* Or the bounds of the interval. For instance, you can sum all
* investments that are smaller than the current observation:

gstats range (sum . 0) x12 = invest, excludebounds

* Moving statistics
* -----------------

* Note the moving window is defined relative to the current observation.
* As with range, gstats moving is an alias:

clear
set obs 20
gen g = _n > 10
gen x = _n
gen w = mod(_n, 7)

gegen x1 = moving_mean(x), window(-2 2) by(g)
gstats transform (moving mean -1 3) x2 = x, by(g)
gstats moving (sd -4 .) x3 = x (p75) x4 = x (select3) x5 = x, by(g) window(-3 3)
l

drop x?
gegen x1 = moving_mean(x) [fw = w], window(-2 2) by(g)
gstats transform (moving mean -1 3) x2 = x [aw = w], by(g)
gstats moving (sd -4 .) x3 = x (p75) x4 = x [pw = w / 7], by(g) window(-3 3)
l

* Cummulative sum
* ---------------

* Note that when no cumsum order is specified, the variable is summed in
* the order it appears in the data. Further, the user can specify a sort
* variable. In our examples below, the cummulative sum of x is computed
* variously by the ascending or descending order of w and then x, or of
* r and then x.

clear
set obs 20
gen g = _n > 10
gen x = mod(_n, 17)
gen w = mod(_n, 7)
gen r = mod(_n, 5)

local c1 (cumsum -) x2 = x
local c2 (cumsum +) x3 = x
local c3 (cumsum - w) x4 = x
local c4 (cumsum + w) x5 = x
local c5 (cumsum) x6 = x

gegen x1 = cumsum(x), by(g)
gstats transform `c1' `c2' `c3' `c4' `c5', by(g) cumby(- r)
l, sepby(g)

* Naturally, if no sort variable is specified the cummulative sum is
* computed in ascending or descending order of x. Last, note that in all
* these examples, the cummulative sums were merged back correctly; that
* is, the data sort order was preserved.
