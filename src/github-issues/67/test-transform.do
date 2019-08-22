clear all

capture program drop bench
program bench
    gettoken timer call: 0,    p(:)
    gettoken colon call: call, p(:)
    cap timer clear `timer'
    timer on `timer'
    `call'
    timer off `timer'
    qui timer list
    c_local r`timer' `=r(t`timer')'
end

clear
set obs 10000000
gen x = ceil(runiform() * 10000)
gen g = round(_n / 100)

bench 1:   egen double rankx_def1 = rank(x)
bench 2:  gegen double rankx_def2 = rank(x)

bench 3:   egen rankx_track1 = rank(x), track
bench 4:  gegen rankx_track2 = rank(x), ties(track)

bench 5:   egen rankx_field1 = rank(x), field
bench 6:  gegen rankx_field2 = rank(x), ties(field)

bench 7:   egen long rankx_uniq1 = rank(x), uniq
bench 8:  gegen long rankx_uniq2 = rank(x), ties(uniq)

gegen rankx_uniq3 = rank(x), ties(stable)

bench 11:  egen double rankx_group_def1 = rank(x), by(g)
bench 12: gegen double rankx_group_def2 = rank(x), by(g)

bench 13:  egen rankx_group_track1 = rank(x), by(g) track
bench 14: gegen rankx_group_track2 = rank(x), by(g) ties(track)

bench 15:  egen rankx_group_field1 = rank(x), by(g) field
bench 16: gegen rankx_group_field2 = rank(x), by(g) ties(field)

bench 17:  egen long rankx_group_uniq1 = rank(x), by(g) uniq
bench 18: gegen long rankx_group_uniq2 = rank(x), by(g) ties(uniq)

gegen rankx_group_uniq3 = rank(x), by(g) ties(stable)

assert (rankx_def1   == rankx_def2)
assert (rankx_track1 == rankx_track2)
assert (rankx_field1 == rankx_field2)

sort x, stable
assert rankx_uniq3 == _n

gisid rankx_uniq1
gisid rankx_uniq2

assert (rankx_group_def1   == rankx_group_def2)
assert (rankx_group_track1 == rankx_group_track2)
assert (rankx_group_field1 == rankx_group_field2)

cap drop ix
sort g x, stable
by g: gen long ix = _n
assert rankx_group_uniq3 == ix

gisid g rankx_group_uniq1
gisid g rankx_group_uniq2

local bench_table `"     Versus | Native | gtools | % faster "'
local bench_table `"`bench_table'"' _n(1) `" ---------- | ------ | ------ | -------- "'

local commands default track field unique
forvalues i = 1(2)7 {
    gettoken cmd commands: commands
    local pct      "`:disp %7.2f  100 * (`r`i'' - `r`=`i'+1'') / `r`i'''"
    local dnative  "`:disp %6.2f `r`i'''"
    local dgtools  "`:disp %6.2f `r`=`i'+1'''"
    local cmd      `"`:disp %10s "`cmd'"'"'
    local bench_table `"`bench_table'"' _n(1) `" `cmd' | `dnative' | `dgtools' | `pct'% "'
}

local bench_table `"`bench_table'"' _n(1) `" ---------- | ------ | ------ | -------- "'
local bench_table `"`bench_table'"' _n(1) `" by group                                "'
local bench_table `"`bench_table'"' _n(1) `" ---------- | ------ | ------ | -------- "'

local commands default track field unique
forvalues i = 11(2)17 {
    gettoken cmd commands: commands
    local pct      "`:disp %7.2f  100 * (`r`i'' - `r`=`i'+1'') / `r`i'''"
    local dnative  "`:disp %6.2f `r`i'''"
    local dgtools  "`:disp %6.2f `r`=`i'+1'''"
    local cmd      `"`:disp %10s "`cmd'"'"'
    local bench_table `"`bench_table'"' _n(1) `" `cmd' | `dnative' | `dgtools' | `pct'% "'
}
disp _n(1) `"`bench_table'"'
