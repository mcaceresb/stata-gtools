clear all
program test1, plugin using(test1.plugin)
plugin call test1
syntax, [foo(cilevel)]
disp "`foo'"

program test2, plugin using(test2.plugin)
plugin call test2
syntax, [foo(cilevel)]
disp "`foo'"

global GTOOLS_CALLER ghash
_gtools_internal
syntax, [foo(cilevel)]
disp "`foo'"
