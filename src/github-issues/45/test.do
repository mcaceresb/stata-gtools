* clear
* input long id1 int id2
* 1225800 179
* 1226197 162
* 1245415 167
* 1245415 204
* 1249196 158
* 1246805 226
* 1247361 189
* 1248872 203
* 1249196 158
* end
* tostring id1 id2, gen(sid1 sid2)
* cap noi gisid id1 id2, v
* assert _rc == 459
* cap noi gisid sid1 sid2, v
* assert _rc == 459
*
* clear
* input long id1 int id2
* 1 13
* 2 11
* 3 12
* 3 16
* 9 10
* 4 17
* 5 14
* 6 15
* 9 10
* end
* tostring id1 id2, gen(sid1 sid2)
* cap noi gisid id1 id2, v
* assert _rc == 459
* cap noi gisid sid1 sid2, v
* assert _rc == 459

clear
input long id1 int id2
3 6
3 7
9 1
4 1
9 1
end
gen id3 = _n
tostring id1 id2, gen(sid1 sid2)
cap noi gisid id1 id2, v
assert _rc == 459
cap noi gisid sid1 sid2, v
assert _rc == 459

sort id1 id2
cap noi gisid id1 id2, v
assert _rc == 459
sort sid1 sid2
cap noi gisid sid1 sid2, v
assert _rc == 459

gen sid3 = string(_n)
cap noi gisid id1 id2 id3, v
assert _rc == 0
cap noi gisid sid1 sid2 sid3, v
assert _rc == 0

/*
set obs 10000000
replace id1 = 10 + mod(_n, 123) in 6 / `=_N'
replace id2 = 10 + mod(_n, 543) in 6 / `=_N'
hashsort id3 id1 id2
gisid id1 id2, v
replace sid1 = string(id1)
replace sid2 = string(id2)
gisid sid1 sid2, v
hashsort id1 id2
gisid id1 id2, v
hashsort sid1 sid2
gisid sid1 sid2, v
*/
