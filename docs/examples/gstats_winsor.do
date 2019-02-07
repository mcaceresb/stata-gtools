* _Note_: These examples are taken verbatim from `help winsor2`.

* winsor at (p1 p99), get new variable "wage_w"
sysuse nlsw88, clear
gstats winsor wage

* winsor 3 variables at 0.5th and 99.5th percentiles, and overwrite the
* old variables

gstats winsor wage age hours, cuts(0.5 99.5) replace

* winsor 3 variables at (p1 p99), gen new variables with suffix _win,
* and add variable labels

gstats winsor wage age hours, suffix(_win) label

* left-winsorizing only, at 1th percentile

cap noi gstats winsor wage, cuts(1 100)
gstats winsor wage, cuts(1 100) s(_w2)

* right-trimming only, at 99th percentile

gstats winsor wage, cuts(0 99) trim

* winsor variables at (p1 p99) by (industry), overwrite the old
* variables

gstats winsor wage hours, replace by(industry)
