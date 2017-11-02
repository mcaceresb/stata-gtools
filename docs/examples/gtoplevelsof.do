sysuse auto, clear

gtoplevelsof rep78

gtoplevelsof rep78,   missrow

gtoplevelsof rep78,   colsep(", ")

gtoplevelsof rep78,   pctfmt(%7.3f)

gtoplevelsof mpg,     numfmt(%7.3f)

gtoplevelsof foreign

gtoplevelsof foreign, colmax(3)

gtoplevelsof foreign, novaluelab

gtoplevelsof foreign rep78, ntop(4) missrow colstrmax(2)

gtoplevelsof foreign rep78, ntop(4) missrow groupmiss

gtoplevelsof foreign rep78, ntop(4) missrow groupmiss noother

gtoplevelsof foreign rep78, cols(<<) missrow("I am missing") matrix(lvl)

matrix list lvl
