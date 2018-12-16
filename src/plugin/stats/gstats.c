#include "gstats.h"
#include "winsor.c"

ST_retcode sf_stats (struct StataInfo *st_info, int level)
{
    
    if ( st_info->gstats_code == 1 ) {
        return (sf_stats_winsor(st_info, level));
    }
    else {
        sf_errprintf("Unknown gstats code; error in sf_stats.");
        return (198);
    }
} 
