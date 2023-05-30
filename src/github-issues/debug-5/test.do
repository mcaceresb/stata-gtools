global GTOOLS_BETA=1
global GTOOLS_GREGTABLE=1
sysuse auto, clear
greg price mpg rep78
matlist e(V)
reg price mpg rep78
matlist e(V)
