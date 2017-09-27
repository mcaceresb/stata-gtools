*! version 0.7.1 27Sep2017 Mauricio Caceres Bravo, mauricio.caceres.bravo@gmail.com
*! Program for managing the gtools package installation

capture program drop gtools
program gtools
    version 13
    if inlist("`c(os)'", "MacOSX") {
        di as err "Not available for `c(os)'."
        exit 198
    }

    syntax, [Dependencies Install_latest Upgrade replace dll hashlib(str)]
    local cwd `c(pwd)'
    local github https://raw.githubusercontent.com/mcaceresb/stata-gtools/master

    if ( "`dependencies'" == "dependencies" ) {
        local github_url      `github'/lib/windows
        local spookyhash_dll  spookyhash.dll
        cap confirm file `spookyhash_dll'
        if ( _rc ) local download `github_url'/`spookyhash_dll'
        else local download `c(pwd)'/`spookyhash_dll'
        cap mkdir `c(sysdir_plus)'s/
        cap cd `c(sysdir_plus)'s/
        if ( _rc ) {
            local url `github_url'/`spookyhash_dll'
            di as err `"Could not find directory '`c(sysdir_plus)'s/'"'
            di as err `"Please download {browse "`url'":`spookyhash_dll'} to your gtools installation."'
            cd `cwd'
            exit _rc
        }
        cap confirm file `spookyhash_dll'
        if ( (_rc == 0) & ("`replace'" == "") ) {
            di as txt "`spookyhash_dll' already installed; run with -replace- to replace."
            cd `cwd'
            exit 0
        }
        cap erase `spookyhash_dll'
        cap copy `download' `spookyhash_dll'
        if ( _rc ) {
            di as err "Unable to download `spookyhash_dll' from `download'."
            cd `cwd'
            exit _rc
        }
        cap confirm file `spookyhash_dll'
        if ( _rc ) {
            di as err "`spookyhash_dll' could not be installed. -gtools- programs may fail on Windows."
            cd `cwd'
            exit _rc
        }
        di as txt "Success!"
        cd `cwd'
        exit 0
    }

    if ( ("`install_latest'" == "install_latest") | ("`upgrade'" == "upgrade") ) {
       net install gtools, from(`github'/build) replace
       gtools, dependencies replace
       exit 0
    }

    if ( "`hashlib'" == "" ) {
        local hashlib `c(sysdir_plus)'s/spookyhash.dll
        local hashusr 0
    }
    else local hashusr 1
    if ( "`c(os)'" == "Windows" & (`hashusr' | ("`dll'" == "dll") ) ) {
        cap confirm file spookyhash.dll
        if ( _rc | `hashusr' ) {
            cap findfile spookyhash.dll
            if ( _rc | `hashusr' ) {
                cap confirm file `"`hashlib'"'
                if ( _rc ) {
                    local url https://raw.githubusercontent.com/mcaceresb/stata-gtools
                    local url `url'/master/spookyhash.dll
                    di as err `"'`hashlib'' not found."'
                    di as err "Download {browse "`url'":here} or run {opt gtools, dependencies}"'
                    exit _rc
                }
            }
            else local hashlib `r(fn)'

            mata: __gtools_hashpath = ""
            mata: __gtools_dll = ""
            mata: pathsplit(`"`hashlib'"', __gtools_hashpath, __gtools_dll)
            mata: st_local("__gtools_hashpath", __gtools_hashpath)
            mata: mata drop __gtools_hashpath
            mata: mata drop __gtools_dll
            local path: env PATH
            if inlist(substr(`"`path'"', length(`"`path'"'), 1), ";") {
                local path = substr("`path'"', 1, length(`"`path'"') - 1)
            }
            local __gtools_hashpath = subinstr("`__gtools_hashpath'", "/", "\", .)

            local newpath `"`path';`__gtools_hashpath'"'
            local truncate 2048
            if ( `:length local newpath' > `truncate' ) {
            local loops = ceil(`:length local newpath' / `truncate')
            mata: __gtools_pathpieces = J(1, `loops', "")
            mata: __gtools_pathcall   = ""
            mata: for(k = 1; k <= `loops'; k++) __gtools_pathpieces[k] = substr(st_local("newpath"), 1 + (k - 1) * `truncate', `truncate')
            mata: for(k = 1; k <= `loops'; k++) __gtools_pathcall = __gtools_pathcall + " `" + `"""' + __gtools_pathpieces[k] + `"""' + "' "
            mata: st_local("pathcall", __gtools_pathcall)
            mata: mata drop __gtools_pathcall __gtools_pathpieces
            cap plugin call env_set, PATH `pathcall'
            }
            else {
                cap plugin noi call env_set, PATH `"`path';`__gtools_hashpath'"'
            }

            if ( _rc ) {
                di as err "Unable to add '`__gtools_hashpath'' to system PATH."
                exit 198
            }
            else {
                di as txt "Added '`__gtools_hashpath'' to system PATH."
            }
        }
        else local hashlib spookyhash.dll
        exit 0
    }
    else {
        di as txt "-gtools, hashlib()- only on Windows."
        exit 0
    }

    display "Nothing to do. Specify: dependencies, dll (Windows), hasblib (Windows), upgrade."
end

cap program drop env_set
program env_set, plugin using("env_set_`:di lower("`c(os)'")'.plugin")
