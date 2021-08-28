global GTOOLS_BETA = 1
sysuse auto, clear
drop _hdfe_*
gglm foreign price, family(binomial) absorb(rep78) mata(GLM) prefix(hdfe(_hdfe_))

sysuse auto, clear
gtop rep78 if mi(rep78), by(foreign) gen(a)
