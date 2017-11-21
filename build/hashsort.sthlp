{smcl}
{* *! version 0.5.2  21Nov2017}{...}
{viewerdialog hashsort "dialog sort, message(-hashsort-)"}{...}
{vieweralsosee "[D] hashsort" "mansection D hashsort"}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "[D] sort" "help sort"}{...}
{viewerjumpto "Syntax" "hashsort##syntax"}{...}
{viewerjumpto "Menu" "hashsort##menu"}{...}
{viewerjumpto "Description" "hashsort##description"}{...}
{viewerjumpto "Options" "hashsort##options"}{...}
{viewerjumpto "Examples" "hashsort##examples"}{...}
{title:Title}

{p2colset 5 18 23 2}{...}
{p2col :{cmd:hashsort} {hline 2}}{opt sort} and {opt gsort} using hashes and C-plugins{p_end}
{p2colreset}{...}


{pstd}
{it:Note for Windows users}: It may be necessary to run
{opt gtools, dependencies} at the start of your Stata session.


{marker syntax}{...}
{title:Syntax}

{p 8 14 2}
{cmd:hashsort}
[{cmd:+}|{cmd:-}]
{varname}
[[{cmd:+}|{cmd:-}]
{varname} {it:...}]
[{cmd:,} {it:{help hashsort##options:options}}]

{marker menu}{...}
{title:Menu}

{marker description}{...}
{title:Description}

{pstd}
{opt hashsort} uses C-plugins to implement a hash-based sort that is always
faster than {opt sort} for sorting groups and faster than {opt gsort} in
general. {opt hashsort} hashes the data and sorts the hash, and then it sorts
one observation per group. The fewer the number of gorups relative to the
number of observations, the larger the speed gain.

{pstd}
If the sort is expected to be unique or if the number of groups is large, then
this comes at a potentially large memory penalty and it may not be faster than
{opt sort} (the exception is when the sorting variables are all integers).

{pstd}
Each {varname} can be numeric or a string. The observations are placed in
ascending order of {it:varname} if {opt +} or nothing is typed in front of the
name and are placed in descending order if {opt -} is typed. {opt hashsort}
always produces a stable sort.

{pstd}
{opt hashsort} is part of the {manhelp gtools R:gtools} project.

{marker options}{...}
{title:Options}

{dlgtab:Options}

{phang}
{opth gen:enerate(varname)} Store group ID in {opt generate}.

{phang}
{opt sortgen} Set data sortby variable to {opt generate}.

{phang}
{opt replace} If {opt generate} exits, it is replaced.

{phang}
{opt skipcheck} Skip internal is sorted check.

{dlgtab:Gtools}

{phang}
{opt verbose} prints some useful debugging info to the console.

{phang}
{opt benchmark} prints how long in seconds various parts of the program
take to execute. The user can also pass {opth bench(int)} for finer control.
{opt bench(1)} is the same as benchmark but {opt bench(2)} 2 additionally
prints benchmarks for internal plugin steps.

{phang}
{opth hashlib(str)} On earlier versions of gtools Windows users had a problem
because Stata was unable to find {it:spookyhash.dll}, which is bundled with
gtools and required for the plugin to run correctly. The best thing a Windows
user can do is run {opt gtools, dependencies} at the start of their Stata
session, but if Stata cannot find the plugin the user can specify a path
manually here.


{marker examples}{...}
{title:Examples}

{pstd}
Also see the
{browse "http://gtools.readthedocs.io/en/latest/usage/hashsort/index.html#examples":online documentation}
for more examples.

    {hline}
    Setup
{phang2}{cmd:. sysuse auto}

{pstd}Place observations in ascending order of {cmd:price}{p_end}
{phang2}{cmd:. hashsort price}

{pstd}Same as above command{p_end}
{phang2}{cmd:. hashsort +price} 

{pstd}List the 10 lowest-priced cars in the data{p_end}
{phang2}{cmd:. list make price in 1/10}

{pstd}Place observations in descending order of {cmd:price}{p_end}
{phang2}{cmd:. hashsort -price}

{pstd}List the 10 highest-priced cars in the data{p_end}
{phang2}{cmd:. list make price in 1/10}

{pstd}Place observations in alphabetical order of {cmd:make}{p_end}
{phang2}{cmd:. hashsort make}

{pstd}List {cmd:make} in alphabetical order{p_end}
{phang2}{cmd:. list make}

{pstd}Place observations in reverse alphabetical order of {cmd:make}{p_end}
{phang2}{cmd:. hashsort -make}

{pstd}List {cmd:make} in reverse alphabetical order{p_end}
{phang2}{cmd:. list make}

    {hline}
    Setup
{phang2}{cmd:. webuse bp3}

{pstd}Place observations in ascending order of {cmd:time} within ascending
order of {cmd:id}{p_end}
{phang2}{cmd:. hashsort id time}

{pstd}List each patient's blood pressures in the order measurements were
taken{p_end}
{phang2}{cmd:. list id time bp}

{pstd}Place observations in descending order of {cmd:time} within ascending
order of {cmd:id}{p_end}
{phang2}{cmd:. hashsort id -time}

{pstd}List each patient's blood pressures in reverse-time order{p_end}
{phang2}{cmd:. list id time bp}{p_end}
    {hline}


{marker author}{...}
{title:Author}

{pstd}Mauricio Caceres{p_end}
{pstd}{browse "mailto:mauricio.caceres.bravo@gmail.com":mauricio.caceres.bravo@gmail.com }{p_end}
{pstd}{browse "https://mcaceresb.github.io":mcaceresb.github.io}{p_end}

{title:Website}

{pstd}{cmd:hashsort} is maintained as part of {manhelp gtools R:gtools} at {browse "https://github.com/mcaceresb/stata-gtools":github.com/mcaceresb/stata-gtools}{p_end}

{marker acknowledgment}{...}
{title:Acknowledgment}

{pstd}
This help file was based on StataCorp's own help file for {it:sort} and {it:gsort}.
{p_end}

{pstd}
This project was largely inspired by Sergio Correia's {it:ftools}:
{browse "https://github.com/sergiocorreia/ftools"}.
{p_end}

{pstd}
The OSX version of gtools was implemented with invaluable help from @fbelotti;
see {browse "https://github.com/mcaceresb/stata-gtools/issues/11"}.
{p_end}

{title:Also see}

{p 4 13 2}
help for 
{help gtools};
{help fsort} (if installed), 
{help ftools} (if installed)

