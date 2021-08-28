*! version 1.2.0 23Mar2019 Mauricio Caceres Bravo, mauricio.caceres.bravo@gmail.com
*! Calculate the top groups by count of a varlist (jointly).

cap program drop gtop
program gtop, rclass
    version 13.1

    local 00 `0'
    gtoplevelsof `0'
    if ( ${GTOP_RC} ) {
        global GTOP_RC
        exit 0
    }
    local 0 `00'

    qui syntax [anything] [if] [in] [aw fw pw], [LOCal(str) MATrix(str) *]
    if ( "`local'"  != "" ) c_local `local' `"`r(levels)'"'
    if ( "`matrix'" != "" ) matrix  `matrix' = r(toplevels)
    return local levels `"`r(levels)'"'
    return scalar N     = r(N)
    return scalar J     = r(J)
    return scalar minJ  = r(minJ)
    return scalar maxJ  = r(maxJ)
    return scalar alpha = r(alpha)
    return scalar ntop  = r(ntop)
    return scalar nrows = r(nrows)

    if ( `"`r(matalevels)'"' == "" ) {
        tempname gmat
        matrix `gmat' = r(toplevels)
        return matrix toplevels = `gmat'
    }
    else {
        return local matalevels = `"`r(matalevels)'"'
    }
end
