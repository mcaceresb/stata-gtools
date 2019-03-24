sysuse auto, clear

gtoplevelsof rep78

gtop rep78 [fw = weight]

gtop rep78 [w = gear_ratio]

gtop rep78,   missrow

gtop rep78,   colsep(", ")

gtop rep78,   pctfmt(%7.3f)

gtop mpg,     numfmt(%7.3f)

gtop foreign

gtop foreign, colmax(3)

gtop foreign, novaluelab

gtop foreign rep78, ntop(4) missrow colstrmax(2)

gtop foreign rep78, ntop(4) missrow groupmiss

gtop foreign rep78, ntop(4) missrow groupmiss noother

gtop foreign rep78, cols(<<) missrow("I am missing") matrix(lvl)
matrix list lvl

gtop foreign rep78, mata(lvl) ntop(3)
mata lvl.desc()
mata lvl.printed
mata lvl.toplevels
