*! version 0.1.1 14Apr2020 Mauricio Caceres Bravo, mauricio.caceres.bravo@gmail.com
*! Estimate IV regression via 2SLS by group and with HDFE

cap program drop givregress
program givregress, rclass
    version 13.1

    local 00: copy local 0
    if ( strpos(`"`0'"', ",") > 0 ) {
        local comma
    }
    else {
        local comma ,
    }
    gregress `0' `comma' ivregress
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
