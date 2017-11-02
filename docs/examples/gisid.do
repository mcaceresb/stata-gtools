sysuse auto, clear

gisid mpg // not an id
gisid make

replace make = "" in 1
gisid make // should never be missing
gisid make, missok

* gisid can also take a range, that is
gisid mpg in 1
gisid mpg if _n == 1
