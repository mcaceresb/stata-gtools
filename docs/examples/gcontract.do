* The options here are essentially the same as Stata's contract,
* save for the standard gtools options.

sysuse auto, clear
gen long id = _n * 1000
expand id
gcontract rep78, verbose

l


* You can add frequencies, percentages, and so on:
sysuse auto, clear
gen long id = _n * 1000
expand id
gcontract rep78, freq(f) cfreq(cf) percent(p) cpercent(cp) bench

l


* Last, with multiple variables you can "fill in" missing groups. This option
* has not been implemented internally and as such is very slow:

sysuse auto, clear
gen long id = _n * 1000
expand id
gcontract foreign rep78, ///
    freq(f) cfreq(cf) percent(p) cpercent(cp) bench(3) zero

l

* You will note a few levels have 0 frequency, which means they did
* not appear in the full data.
