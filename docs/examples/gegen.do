sysuse auto, clear
gegen id    = group(foreign)
gegen tag   = group(foreign)
gegen sum   = sum(mpg), by(foreign)
gegen sum2  = sum(mpg rep78), by(foreign)
gegen p5    = pctile(mpg rep78), p(5) by(foreign)
gegen nuniq = nunique(mpg), by(foreign)

* The function can be any of the supported functions above.
* It can also be any function supported by egen:

webuse egenxmpl4, clear
gegen hsum = rowtotal(a b c)

sysuse auto, clear
gegen seq = seq(), by(foreign)
