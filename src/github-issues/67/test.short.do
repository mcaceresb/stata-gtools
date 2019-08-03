* Create simulated data
clear all
set obs 1000000
gen x = ceil(runiform() * 1000)
qui gunique x
assert r(J) < r(N)

tempvar N
gegen `N' = count(1), by(x)
local nonmi = `r(N)'
fasterxtile rankTrack = x, nq(`nonmi')
gen rankField = `nonmi' - rankTrack - `N' + 2
gen rankDefault = rankTrack + `N' / 2 - 0.5

egen _rankDefault = rank(x)
egen _rankTrack = rank(x), track
egen _rankField = rank(x), field

assert (_rankDefault == rankDefault)
assert (_rankTrack   == rankTrack)
assert (_rankField   == rankField)
