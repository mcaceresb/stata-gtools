capture program drop test
program test
    sysuse auto, clear
    level1 if !strpos(make, ")")
end

capture program drop level1
program level1
    syntax [if]
    macro dir _if
    level2 `if' in 1/10
end

capture program drop level2
program level2
    syntax [if] [in]
    macro dir _if
    mata st_local("ifin", st_local("if") + " " + st_local("in"))
    macro dir _ifin
    local ifin: copy local ifin
    level3 `ifin', ifin(`ifin') ifintest(`ifin')
end

capture program drop level3
program level3
    syntax [if] [in], ifin(str asis) ifintest(str)
    macro dir _if
    macro dir _in
    macro dir _ifin
    macro dir _ifintest
end

test
