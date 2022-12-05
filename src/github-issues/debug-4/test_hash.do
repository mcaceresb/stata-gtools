clear
set obs 100000
gen x = ceil(runiform() * 10)
gen y = char(32 + ceil(runiform() * 96)) + char(32 + ceil(runiform() * 96))
gegen `c(obs_t)' z1 = group(x y), hash(1)
gegen `c(obs_t)' z2 = group(x y), hash(2)
gegen `c(obs_t)' z3 = group(x y), hash(3)
sort x y z1
gen `c(obs_t)' id = (x != x[_n-1]) | (y != y[_n-1])
replace id = sum(id)
assert id == z1
assert z1 == z2
assert z2 == z3

clear
set obs 100000
gen x = ceil(runiform() * 10)
gen y = char(32 + ceil(runiform() * 96)) + char(32 + ceil(runiform() * 96))
gegen `c(obs_t)' z1 = group(y x), hash(1)
gegen `c(obs_t)' z2 = group(y x), hash(2)
gegen `c(obs_t)' z3 = group(y x), hash(3)
sort y x z1
gen `c(obs_t)' id = (x != x[_n-1]) | (y != y[_n-1])
replace id = sum(id)
assert id == z1
assert z1 == z2
assert z2 == z3
