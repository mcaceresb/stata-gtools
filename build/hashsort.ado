*! version 0.2.0 24Oct2017 Mauricio Caceres Bravo, mauricio.caceres.bravo@gmail.com
*! implementation of -sort- and -gsort- using C-plugins

capture program drop hashsort
program define hashsort, rclass
    version 13

    global GTOOLS_CALLER hashsort
    syntax anything,          ///
    [                         ///
        Verbose               /// debugging
        Benchmark             /// print benchmark info
        hashlib(passthru)     /// path to hash library (Windows)
        oncollision(passthru) /// On collision, fall back or error
                              ///
        GENerate(str)         ///
        group(str)            ///
        tag(passthru)         ///
        counts(passthru)      ///
        replace               ///
                              ///
                              /// Unused sort options
                              /// -------------------
        stable                ///
        Mfirst                ///
    ]

    if ( "`stable'" != "" ) {
        di as txt "hashsort is always -stable-"
    }
    if ( "`mfirst'" != "" ) {
        di as err "Option -mfirst- is set automatically"
    }
    else if ( strpos("`anything'", "-") > 0 ) {
        di as txt "(note: option -mfirst- is set automatically)"
    }

    local  opts `verbose' `benchmark' `hashlib' `oncollision'
    local gopts sortindex(`generate') gen(`group') `tag' `counts' `replace'
    cap noi _gtools_internal `anything', missing `opts' `gopts' gfunction(sort)
    global GTOOLS_CALLER ""
    local rc = _rc

    if ( `rc' == 41999 ) {
        if regexm("`anything'", "[\+\-]") {
            gsort `anything', gen(`generate') mfirst
            exit 0
        }
        else {
            sort `anything'
            exit 0
        }
    }
    else if ( `rc' ) exit `rc'

    cap return scalar N      = `r(N)'
    cap return scalar J      = `r(J)'
    cap return scalar minJ   = `r(minJ)'
    cap return scalar maxJ   = `r(maxJ)'
end
