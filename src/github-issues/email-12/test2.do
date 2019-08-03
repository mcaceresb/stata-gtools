* Notes:
*
* You commented out select chunks untill you narrowed the memory leak
*
* The following are not freed on purpose because they are standing by for strL vars and such
*
* allocated: st_info->strL_bybytes
* allocated: st_info->strL_bytes
*
* This was the issue (they were not being freed):
*
* allocated: st_info->st_by_charx
* allocated: st_info->st_by_numx

clear all
set obs 1000000

gen x = rnormal()
gen n = round(_n/10)

gcollapse (max) maxx = x, by(n) merge forcemem v bench(3)
drop maxx
sleep 100

forvalues i = 1 / 100 {
    di "`i'"
    gcollapse (max) maxx = x, by(n) merge forcemem
    drop maxx
    sleep 100
}
