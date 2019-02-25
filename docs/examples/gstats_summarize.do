***************
*  Summarize  *
***************

* Basic usage
sysuse auto, clear
gstats sum price
gstats sum price [pw = gear_ratio / 5]
gstats sum price mpg, f

* In the style of tabstat
gstats sum price mpg, tab nod
gstats sum price mpg, tab meanonly
gstats sum price mpg, by(foreign) tab
gstats sum price mpg, by(foreign) nod
gstats sum price mpg, by(foreign) meanonly

* Pool inputs
gstats sum price *, nod
gstats sum price *, nod pool

*************
*  Tabstat  *
*************

* Basic usage
gstats tab price
gstats tab price, s(mean sd min max) by(foreign)
gstats tab price, by(foreign rep78)

* Custom printing
gstats tab price mpg, s(p5 q p95 select7 select-3) pretty
gstats tab price mpg, s(p5 q p95 select7 select-3) col(var)
gstats tab price mpg, s(p5 q p95 select7 select-3) col(stat)

* Mata API
gen strvar = "string" + string(rep78)
gstats tab price mpg, by(foreign strvar) matasave

mata
GstatsOutput.getf(1, 1, .)
GstatsOutput.getnum(., 1)
GstatsOutput.getchar((2, 5, 6), .)

GstatsOutput.getOutputRow(1)
GstatsOutput.getOutputCol(1)
GstatsOutput.getOutputVar("price")
GstatsOutput.getOutputVar("mpg")
GstatsOutput.getOutputGroup(1)

GstatsOutput.output
end

* The mata APi is specially useful for a large number of groups

clear
set obs 100000
gen g = mod(_n, 10000)
gen x = runiform()
gstats tab x, by(g) noprint matasave 
mata GstatsOutput.J
mata GstatsOutput.getOutputGroup(13)
