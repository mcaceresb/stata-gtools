*! version 0.1.0 18Aug2019 Mauricio Caceres Bravo, mauricio.caceres.bravo@gmail.com
*! Implementation of (rolling, grouped) regressions

cap program drop greg
program greg, rclass
    version 13.1

    local 00: copy local 0
    gregress `0'
    if ( ${GREG_RC} ) {
        global GREG_RC
        exit 0
    }
    local 0: copy local 00

    return local levels `"`r(levels)'"'
    return scalar N     = r(N)
    return scalar J     = r(J)
    return scalar minJ  = r(minJ)
    return scalar maxJ  = r(maxJ)
end
