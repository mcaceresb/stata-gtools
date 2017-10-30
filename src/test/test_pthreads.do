version 13
clear all
set more off
set varabbrev off
set seed 1729
set linesize 255

if ( inlist("`c(os)'", "MacOSX") | strpos("`c(machine_type)'", "Mac") ) {
    local c_os_ macosx
}
else {
    local c_os_: di lower("`c(os)'")
}
log using gtools_pthreads_`c_os_'.log, text replace name(gtools_pthreads)

set obs 1000
gen rand = runiform()
expand 20000

global GTOOLS_FORCE_PARALLEL = 1
gunique rand, b
log close gtools_pthreads
