* Basic usage                                         
* -----------

* Syntax is largely analogous to `gcollapse`

sysuse auto, clear

gegen norm_price = normalize(price),   by(foreign)
gegen std_price  = standardize(price), by(foreign)
gegen dm_price   = demean(price),      by(foreign)

local opts by(foreign) replace
gstats transform (normalize) norm_mpg = mpg (demean) dm_mpg = mpg, `opts'
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

* We can specify also different intervals per variable as well as a
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
