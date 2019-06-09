sysuse auto, clear
estpost gtabstat price mpg rep78, statistics(mean sd)
esttab ., cells("price mpg rep78")
estpost gtabstat price mpg rep78, statistics(mean sd) columns(statistics)
esttab ., cells("mean(fmt(a3)) sd")
estpost gtabstat price mpg rep78, by(foreign) statistics(mean sd) columns(variables)
estpost gtabstat price mpg rep78, by(foreign) statistics(mean sd) columns(statistics)
esttab ., main(mean) aux(sd) nostar unstack noobs nonote label

estpost gtabstat price, by(foreign) statistics(mean sd) columns(variables)
estpost gtabstat price, by(foreign) statistics(mean sd) columns(statistics)

estpost gtabstat price, statistics(mean sd) columns(variables)
estpost gtabstat price, statistics(mean sd) columns(statistics)
