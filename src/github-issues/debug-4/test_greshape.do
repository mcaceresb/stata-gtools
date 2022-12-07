sysuse auto, clear
gen i = _n
greshape wide price mpg price, i(i) j(foreign) xi(drop)
greshape wide mpg price, i(i) j(foreign) xi(drop)

sysuse auto, clear
gen i = _n
gen mp0 = price
gen pr0 = price
rename price pr1
rename mpg   mp1
greshape long pr mp pr, i(i) j(j) xi(drop)
greshape long pr mp, i(i) j(j) xi(drop)

webuse reshape3, clear
greshape long inc([0-9]+).+ (ue)(.+)/2 inc([0-9]+).+, by(id) keys(year) match(regex)
greshape long inc([0-9]+).+ (ue)(.+)/2 inc(.+)r, by(id) keys(year) match(regex)
greshape long inc([0-9]+).+ (ue)(.+)/2 waff, by(id) keys(year) match(regex)
greshape long inc([0-9]+).+ (ue)(.+)/2, by(id) keys(year) match(regex)
