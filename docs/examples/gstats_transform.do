sysuse auto, clear

gegen norm_price = normalize(price),   by(foreign)
gegen std_price  = standardize(price), by(foreign)
gegen dm_price   = demean(price),      by(foreign)

gstats transform (normalize) norm_mpg = mpg (demean) dm_mpg = mpg, by(foreign) replace
gstats transform (demean) mpg (normalize) price, by(foreign) replace
