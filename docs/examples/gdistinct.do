* gdistinct can function as a drop-in replacement for distinct.

sysuse auto, clear
gdistinct
matrix list r(distinct)

gdistinct, max(10)

gdistinct make-headroom

gdistinct make-headroom, missing abbrev(6)

gdistinct foreign rep78, joint

gdistinct foreign rep78, joint missing
