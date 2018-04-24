sysuse auto, clear
gcollapse (sum) price mpg (mean) m1 = price m2 = mpg if !mi(rep78), by(foreign)
l

* You can call multiple names per statistic in any order, optionally
* specifying the target name. Further, weights can be selectively
* applied to each target.

sysuse auto, clear
gcollapse (mean) price praw = price [fw = rep78], by(foreign) rawstat(praw)
l

* Note, however, that rows with missing or 0 values of rep78 are
* excluded regardless when selectively applying weights.

*******************
*  Unique Counts  *
*******************

sysuse auto, clear
gcollapse (nunique) rep78 mpg turn, by(foreign)
l

******************
*  Wild Parsing  *
******************

clear
set obs 10
gen x1 = _n
gen x2 = _n^2
gen x3 = _n^3

gcollapse mean_x* = x*, wildparse
l

***************
*  Quantiles  *
***************

* gcollapse allows the user to specify arbitrary quantiles:

sysuse auto, clear
gcollapse (p2.5) p2_5 = price (p97.5) p97_5 = price, by(foreign)
l

* This is useful if you have a large number of observations per group:

clear
set obs 1000
gen long id = _n
gcollapse              ///
    (p2)    p2    = id ///
    (p2.5)  p2_5  = id ///
    (p3)    p3    = id ///
    (p96)   p96   = id ///
    (p97.5) p97_5 = id ///
    (p98)   p98   = id
l


*******************
*  Label outputs  *
*******************

* The default label for collapsed stats is "(stat) source label".  I find this
* format ugly, so I have implemented a very basic engine to label outputs:

sysuse auto, clear
gcollapse (mean) price, labelformat(#stat#: #sourcelabel#)
disp _n(1) "`:var label price'"


* The following placeholder options are available in the engine:
*
* - `#stat#`, `#Stat#`, and `#STAT#` are replaced with the lower-, title-, and
*   upper-case name of the summary stat.
*
* - `#sourcelabel#`, `#sourcelabel:start:numchars#` are replaced with the
*   source label, optionally extracting `numchars` characters from `start`
*   (`numchars` can be `.` to denote all characters from `start`).
*
* - `#stat:pretty#` replces each stat name with a nicer version (mean to Mean,
*   sd to St Dev., and so on). The user can specify a their own custom pretty
*   program via `labelprogram()`. The program MUST be an rclass program
*   and return `prettystat`. For example

capture program drop my_pretty_stat
program my_pretty_stat, rclass
         if ( `"`0'"' == "sum"  ) local prettystat "Total"
    else if ( `"`0'"' == "mean" ) local prettystat "Average"
    else {
        local prettystat "#default#"
    }
    return local prettystat = `"`prettystat'"'
end

sysuse auto, clear
gcollapse               ///
    (mean) mean = price ///
    (sum)  sum = price  ///
    (sd)   sd = price,  ///
    freq(obs)           ///
    labelformat(#stat:pretty# #sourcelabel#) labelp(my_pretty_stat)

disp _n(1) "`:var label mean'" ///
     _n(1) "`:var label sum'"  ///
     _n(1) "`:var label sd'"   ///
     _n(1) "`:var label obs'"

* We can see that `mean` and `sum` were set to the custom label, while `sd`
* was set to the default. You can also specify a different label format for
* each variable if you put the stat palceholder in the variable label.

sysuse auto, clear
gen mean = price
gen sum  = price

label var mean  "Price (#stat#)"
label var sum   "Price #stat:pretty#"
label var price "`:var label price' #stat:pretty#"

gcollapse               ///
    (mean) mean         ///
    (sum)  sum          ///
    (sd)   sd = price,  ///
    labelformat(#sourcelabel#) labelp(my_pretty_stat)

disp _n(1) "`:var label mean'" ///
     _n(1) "`:var label sum'"  ///
     _n(1) "`:var label sd'"


***********
*  Merge  *
***********

* You can merge summary stats back to the main data with gcollapse. This is
* equivalent to a sequence of `egen` statements or to `collapse` followed by
* merge. That is, if you want to create bulk summary statistics, you might
* want to do:

sysuse auto, clear
qui {
    preserve
    collapse (mean) m_pr = price (sum) s_gr = gear_ratio, by(rep78)
    tempfile bulk
    save `bulk'
    restore
    merge m:1 rep78 using `bulk', assert(3) nogen
}


* But with gcollapse this is simplified to
sysuse auto, clear
gcollapse (mean) m_pr = price (sum) s_gr = gear_ratio, by(rep78) merge


* If you wish to replace the source variables, you can do
sysuse auto, clear
gcollapse (mean) price (sum) gear_ratio, by(rep78) merge replace


*************************
*  Using I/O vs memory  *
*************************

* gcollapse tries to determine whether using memory or using
* your disk's temporary drive is better. For example:

sysuse auto, clear
gen long id = _n * 1000
expand id
replace id = _n
tempfile io
save `io'

local call (sum)  s1 = id ///
           (mean) s2 = id ///
           (max)  s3 = id ///
           (min)  s4 = id ///
           (sd)   s5 = id

gcollapse `call', by(foreign) v


* Foreign has 2 levels, and we can see that `gcollapse` determines that
* collapsing to disk would save time.  However, we can skip this check if we
* know a variable has few levels:

use `io', clear
gcollapse `call', by(foreign) verbose forceio bench


* We can see that `gcollapse` skipped the check but that it read the collapsed
* targets from disk after the collapse. We can also force `gcollapse` to use
* memory:

use `io', clear
gcollapse `call', by(foreign) verbose forcemem bench

* Again, it skipped the check but this time but we can see it generated the
* targets before the collapse.
