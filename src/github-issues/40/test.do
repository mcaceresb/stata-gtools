ssc install parallel

clear all
sysuse auto, clear

parallel setclusters 2, f
capture program drop pargegen
program pargegen
    version 13
    syntax varlist [if]
    marksample touse
    gegen test = sum(price)
    disp "`level'"
    reg `varlist' if `touse'
    drop test
end

parallel bs, reps(50) nodots: pargegen price weight foreign rep78
bs, reps(50) nodots: pargegen price weight foreign rep78
