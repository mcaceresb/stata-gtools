*! version 0.1.0 18Aug2019 Mauricio Caceres Bravo, mauricio.caceres.bravo@gmail.com
*! Implementation of grouped poisson regressions with HDFE

cap program drop gpoisson
program gpoisson, rclass
    version 13.1

    local 00: copy local 0
    if ( strpos(`"`0'"', ",") > 0 ) {
        local comma
    }
    else {
        local comma ,
    }
    gregress `0' `comma' poisson
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
