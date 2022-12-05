cap mata mata drop ahaRename()
mata
void function ahaRename(real scalar i)
{
    (void) st_addvar(st_vartype(i), st_local("revar"))
    if ( strpos(st_vartype(i), "str") ) {
        st_sstore(., st_local("revar"), st_sdata(., i))
    }
    else {
        st_store(., st_local("revar"), st_data(., i))
    }
    st_dropvar(i)
}
end

use /home/mauricio/bulk/data/ra/doyle/cms-ambulance/aha/aha-data-120617.dta, clear
    local i 0
    unab vars: _all
    foreach var of local vars {
        local ++i
        if strpos("`var'", ".") {
            disp "`var'"
            local revar: subinstr local var "." "_", all
            mata: ahaRename(`i')
            if (`=`i'-1') {
                order `revar', after(`cached')
                local cached `revar'
            }
            else {
                order `revar'
            }
        }
        else {
            local cached `var'
        }
    }

    rename abs_hcahps_cmp_yr3 satis
    rename abs_proc_cmp_yr3   process
    rename abs_mort_cmp_yr3   Hmort30
    rename abs_readm_cmp_yr3  Hreadm30
    rename mort_30_ami_yr3    AMImort30
    rename mort_30_pn_yr3     PNmort30
    rename mort_30_hf_yr3     HFmort30
    rename readm_30_ami_yr3   AMIreadm30
    rename readm_30_pn_yr3    PNreadm30
    rename readm_30_hf_yr3    HFreadm30
    rename hospbd             volume
    rename year               diag_year
    rename low_profit         lowpr
    rename high_profit        hipr
    desc teach forpr nonpr gov coth
    local keepvars satis process Hmort30 Hreadm30 AMImort30 PNmort30 HFmort30 AMIreadm30 PNreadm30 HFreadm30 volume teach forpr nonpr gov lowpr hipr coth

    rename provider_id prvnumgrp
    keep  `keepvars' prvnumgrp diag_year
    gcollapse (mean) `keepvars', by(prvnumgrp diag_year)

set varabbrev on
set more off
clear
set obs 10
gen aa = 0
gen bb = runiform()
gen cc = runiform()
gen dd = runiform()
gegen x = mean(b c), by(a d* e)
gen dz = runiform()
gegen x = mean(b c), by(a d e)
