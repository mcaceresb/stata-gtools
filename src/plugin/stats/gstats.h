#ifndef GSTATS
#define GSTATS

ST_retcode sf_stats (struct StataInfo *st_info, int level, char *fname);
ST_retcode sf_stats_winsor (struct StataInfo *st_info, int level);
ST_retcode sf_stats_summarize (struct StataInfo *st_info, int level, char *fname);
ST_retcode sf_stats_summarize_p (struct StataInfo *st_info, int level, char *fname);
ST_retcode sf_stats_summarize_w (struct StataInfo *st_info, int level, char *fname);
 
#endif
