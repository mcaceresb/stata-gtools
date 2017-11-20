* Debugging issue 29:
* https://github.com/mcaceresb/stata-gtools/issues/29?_pjax=%23js-repo-pjax-container

* The problem was that the stats get computed in the wrong order with
* forceio or the switching code. In that case, two copies of the source
* variable list is passed, but there is no reason to expect the source
* variable list to be identical in the target list (i.e. if the sources
* are "a b" there is no reason to expect the targets to be "a b ...";
* they could be "a ... b ..." and in that case gcollapse gave the wrong
* answer).

capture program drop mimic
program mimic
    syntax anything, min(real) max(real) [nmissing(real 0) int]
    tempname range
    scalar `range' = `max' - `min'
    if ( "`int'" != "" ) {
        gen `anything' = int(runiform() * scalar(`range') + `min')
    }
    else {
        gen `anything' = runiform() * scalar(`range') + `min'
    }
    if ( `nmissing' > 0 ) {
        tempvar rsort
        gen `rsort' = runiform()
        sort `rsort'
        replace `anything' = . in 1 / `nmissing'
    }
end


* Here we can see that the sources are:
*
*     price price foreign foreign
*
* but their order for the targets is
*
*     price foreign price foreign
*
* And this causes a problem

sysuse auto, clear
preserve
collapse (min) mp = price (max) xp = price xf = foreign (mean) mf = foreign 
l
restore, preserve
gcollapse (min) mp = price (max) xp = price xf = foreign (mean) mf = foreign , forceio
l
restore

* . collapse (min) mp = price (max) xp = price xf = foreign (mean) mf = foreign 
* . l
*
*      +-------------------------------+
*      |    mp       xp   xf        mf |
*      |-------------------------------|
*   1. | 3,291   15,906    1   .297297 |
*      +-------------------------------+
*
* . gcollapse (min) mp = price (max) xp = price xf = foreign (mean) mf = foreign , forceio
* . l
*
*      +---------------------------+
*      |    mp   xp   xf        mf |
*      |---------------------------|
*   1. | 3,291    1    .   .297297 |
*      +---------------------------+

clear
set obs 124350
mimic       id, nmissing(`=_N - 124350') min( 1000010)  max( 1898440) int
mimic        P, nmissing(`=_N - 124350') min(     .01)  max(     444)
mimic        Q, nmissing(`=_N - 124350') min(      10)  max(6.00e+07)
mimic        T, nmissing(`=_N - 124350') min(1.78e+12)  max(1.81e+12)
mimic     date, nmissing(`=_N - 124350') min(   20577)  max(   20937) int
mimic        o, nmissing(`=_N -  51237') min(       1)  max(    1363)
mimic        v, nmissing(`=_N -  51237') min(    16.5)  max(4.52e+08)
mimic      PTa, nmissing(`=_N - 124350') min(     .01)  max(     444)
mimic    Phh10, nmissing(`=_N - 108096') min(     .01)  max(     444)
mimic    Phh14, nmissing(`=_N -  52086') min(     .01)  max(     444)
mimic    qhh10, nmissing(`=_N -  16254') min(      30)  max(1.37e+09)
mimic    qhh14, nmissing(`=_N -  72264') min(      10)  max(8.39e+09)
mimic      obu, nmissing(`=_N -  51237') min(       0)  max(    1363)
mimic      obe, nmissing(`=_N -  51237') min(       0)  max(     586)
mimic     obbu, nmissing(`=_N -  51237') min(       0)  max(    1363)
mimic     obbe, nmissing(`=_N -  51237') min(       0)  max(     586)
mimic      vbu, nmissing(`=_N -  51237') min(       0)  max(1.61e+08)
mimic      vbe, nmissing(`=_N -  51237') min(       0)  max(1.30e+08)
mimic     vbbu, nmissing(`=_N -  51237') min(       0)  max(1.61e+08)
mimic     vbbe, nmissing(`=_N -  51237') min(       0)  max(1.30e+08)
mimic     omax, nmissing(`=_N - 124350') min(       1)  max(    1363)
mimic       oo, nmissing(`=_N - 124350') min(       1)  max(   51802)
mimic       vv, nmissing(`=_N - 124350') min(     182)  max(9.28e+09)
mimic     oobu, nmissing(`=_N - 124350') min(       0)  max(    4606)
mimic     oobe, nmissing(`=_N - 124350') min(       0)  max(    5608)
mimic    oobbu, nmissing(`=_N - 124350') min(       0)  max(    3231)
mimic    oobbe, nmissing(`=_N - 124350') min(       0)  max(    3820)
mimic     vvbu, nmissing(`=_N - 124350') min(       0)  max(1.22e+09)
mimic     vvbe, nmissing(`=_N - 124350') min(       0)  max(8.81e+08)
mimic    vvbbu, nmissing(`=_N - 124350') min(       0)  max(9.02e+08)
mimic    vvbbe, nmissing(`=_N - 124350') min(       0)  max(6.41e+08)
mimic   phomax, nmissing(`=_N -    265') min(     .01)  max(     444)
mimic   plomax, nmissing(`=_N -    265') min(     .01)  max(     444)

set varabbrev off
sort id date

preserve
collapse (first) po=PTa (last) pc=PTa (max) ph=P (min) pl=P (firstnm) phomax=phomax (firstnm) plomax=plomax (firstnm) phh10=Phh10 (firstnm) phh14=Phh14  (sum) q=Q (p25) p25=P (p50) p50=P (p75) p75=P (lastnm) qhh10=qhh10 (lastnm) qhh14=qhh14 (firstnm) oo=oo (firstnm) omax=omax (firstnm) vv=vv (firstnm) oobu=oobu (firstnm) oobe=oobe (firstnm) vvbu=vvbu (firstnm) vvbe=vvbe (firstnm) oobbu=oobbu (firstnm) vvbbu=vvbbu (firstnm) oobbe=oobbe (firstnm) vvbbe=vvbbe, by(id date)
su
restore
gcollapse (first) po=PTa (last) pc=PTa (max) ph=P (min) pl=P (firstnm) phomax=phomax (firstnm) plomax=plomax (firstnm) phh10=Phh10 (firstnm) phh14=Phh14  (sum) q=Q (p25) p25=P (p50) p50=P (p75) p75=P (lastnm) qhh10=qhh10 (lastnm) qhh14=qhh14 (firstnm) oo=oo (firstnm) omax=omax (firstnm) vv=vv (firstnm) oobu=oobu (firstnm) oobe=oobe (firstnm) vvbu=vvbu (firstnm) vvbe=vvbe (firstnm) oobbu=oobbu (firstnm) vvbbu=vvbbu (firstnm) oobbe=oobbe (firstnm) vvbbe=vvbbe, by(id date) verbose forceio
su 

* This mimics the exampe that was given to report the bug.
*
* collapse ...
* . su
*
*     Variable |       Obs        Mean    Std. Dev.       Min        Max
* -------------+--------------------------------------------------------
*           id |    124319     1449513    259231.7    1000016    1898439
*         date |    124319    20756.54    103.9555      20577      20936
*           po |    124319     222.055    128.3964   .0130482   443.9976
*           pc |    124319     222.043     128.389   .0130482   443.9976
*           ph |    124319    222.1953    128.4511   .0106641   443.9995
* -------------+--------------------------------------------------------
*           pl |    124319    222.1607    128.4453   .0106641   443.9995
*       phomax |       265    219.6184    127.8087   .6756181    441.539
*       plomax |       265     223.752    125.6091   4.327056   442.5381
*        phh10 |    108073    222.4026    127.7358   .0161043   443.9921
*        phh14 |     52081    222.3903    128.2465   .0109131   443.9984
* -------------+--------------------------------------------------------
*            q |    124319    3.00e+07    1.73e+07   1281.381   1.09e+08
*          p25 |    124319    222.1607    128.4453   .0106641   443.9995
*          p50 |    124319     222.178     128.441   .0106641   443.9995
*          p75 |    124319    222.1953    128.4511   .0106641   443.9995
*        qhh10 |     16254    6.86e+08    3.97e+08   56054.97   1.37e+09
* -------------+--------------------------------------------------------
*        qhh14 |     72252    4.20e+09    2.42e+09   185200.9   8.39e+09
*           oo |    124319    25858.07    14933.73   1.548082   51801.97
*         omax |    124319     681.713    392.7737   1.022591   1362.999
*           vv |    124319    4.65e+09    2.68e+09   47740.47   9.28e+09
*         oobu |    124319    2301.508    1331.517   .0500497   4605.934
* -------------+--------------------------------------------------------
*         oobe |    124319    2804.711    1619.164   .0028778   5607.911
*         vvbu |    124319    6.09e+08    3.52e+08   4025.604   1.22e+09
*         vvbe |    124319    4.41e+08    2.54e+08   21811.43   8.81e+08
*        oobbu |    124319    1619.332    932.2608   .0501557   3230.987
*        vvbbu |    124319    4.51e+08    2.61e+08   3526.542   9.02e+08
* -------------+--------------------------------------------------------
*        oobbe |    124319    1909.387    1103.151     .02453   3819.982
*        vvbbe |    124319    3.21e+08    1.85e+08   1569.753   6.41e+08
*
* gcollapse ...
* . su 
*
*     Variable |       Obs        Mean    Std. Dev.       Min        Max
* -------------+--------------------------------------------------------
*           id |    124319     1449513    259231.7    1000016    1898439
*         date |    124319    20756.54    103.9555      20577      20936
*           po |    124319     222.055    128.3964   .0130482   443.9976
*           pc |    124319    4.41e+08    2.54e+08   21811.43   8.81e+08
*           ph |    124319     222.043     128.389   .0130482   443.9976
* -------------+--------------------------------------------------------
*           pl |    124319    1619.332    932.2608   .0501557   3230.987
*       phomax |    124319    222.1953    128.4511   .0106641   443.9995
*       plomax |    124319    222.1607    128.4453   .0106641   443.9995
*        phh10 |       265    219.6184    127.8087   .6756181    441.539
*        phh14 |       265     223.752    125.6091   4.327056   442.5381
* -------------+--------------------------------------------------------
*            q |    108073    222.4026    127.7358   .0161043   443.9921
*          p25 |    124319    4.51e+08    2.61e+08   3526.542   9.02e+08
*          p50 |    124319    1909.387    1103.151     .02453   3819.982
*          p75 |    124319    3.21e+08    1.85e+08   1569.753   6.41e+08
*        qhh10 |     52081    222.3903    128.2465   .0109131   443.9984
* -------------+--------------------------------------------------------
*        qhh14 |    124319    3.00e+07    1.73e+07   1281.381   1.09e+08
*           oo |    124319    222.1607    128.4453   .0106641   443.9995
*         omax |    124319     222.178     128.441   .0106641   443.9995
*           vv |    124319    222.1953    128.4511   .0106641   443.9995
*         oobu |     16254    6.86e+08    3.97e+08   56054.97   1.37e+09
* -------------+--------------------------------------------------------
*         oobe |     72252    4.20e+09    2.42e+09   185200.9   8.39e+09
*         vvbu |    124319    25858.07    14933.73   1.548082   51801.97
*         vvbe |    124319     681.713    392.7737   1.022591   1362.999
*        oobbu |    124319    4.65e+09    2.68e+09   47740.47   9.28e+09
*        vvbbu |    124319    2301.508    1331.517   .0500497   4605.934
* -------------+--------------------------------------------------------
*        oobbe |    124319    2804.711    1619.164   .0028778   5607.911
*        vvbbe |    124319    6.09e+08    3.52e+08   4025.604   1.22e+09
