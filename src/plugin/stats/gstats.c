#include "gstats.h"
#include "winsor.c"
#include "summarize.c"
#include "transform.c"

ST_retcode sf_stats (struct StataInfo *st_info, int level, char *fname)
{

    if ( st_info->gstats_code == 1 ) {
        return (sf_stats_winsor(st_info, level));
    }
    else if ( st_info->gstats_code == 2 ) {
        return (sf_stats_summarize(st_info, level, fname));
    }
    else if ( st_info->gstats_code == 3 ) {
        return (sf_stats_transform(st_info, level));
    }
    else {
        sf_errprintf("Unknown gstats code; error in sf_stats.");
        return (198);
    }
}
