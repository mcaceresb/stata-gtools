#include "stplugin.h"

int main()
{
    return(0);
}

int WinMain()
{
    return(0);
}

STDLL stata_call(int argc, char *argv[])
{
    SF_display("Hello World\n") ;
    return(0) ;
}

/*

    cd /home/mauricio/code/stata-gtools/src/github-issues/35/
    !gcc -Wall -shared -fPIC -DSYSTEM=OPUNIX -o test1.plugin stplugin.c test1.c
    capture program drop test1
    program test1, plugin using(test1.plugin)
    plugin call test1

*/
