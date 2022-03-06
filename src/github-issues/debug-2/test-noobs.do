sysuse auto, clear
tempvar yy
tempname zz
gen `yy' = .
set tracedepth 1
* set trace on
* gegen `xx' = mean(price)  if `yy' == 1, by(foreign)

capture program drop cc
program cc
    sort foreign
    xtset foreign
    tempvar xx
    gegen `xx' = count(price), by(foreign) replace

end
frame put price foreign if `yy' == 1, into(`zz')
frame `zz' {
    cc
}
