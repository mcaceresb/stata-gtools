sysuse auto, clear
gstats transform (moving  mean -6 .) x=rep78, excludeself replace
gstats transform (range  mean -6 .) x=rep78, excludeself replace
gstats transform (range  mean -6 .) x=rep78, replace
gstats transform (moving  mean -6 .) x=rep78 (range  mean -6 6) y=rep78, excludeself replace
