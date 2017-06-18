*! version 0.1.0 17Jun2017 Mauricio Caceres Bravo, mauricio.caceres.bravo@gmail.com
*! Program for managing the gtools package installation

capture program drop gtools
program gtools
    syntax, [Dependencies Install_latest Upgrade replace]
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

    display "Nothing to do. Specify: dependencies, upgrade."
end
