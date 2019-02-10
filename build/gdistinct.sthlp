{smcl}
{* *! version 1.0.2  23Jan2019}{...}
{viewerdialog gdistinct "dialog gdistinct"}{...}
{vieweralsosee "[D] gdistinct" "mansection D gdistinct"}{...}
{viewerjumpto "Syntax" "gdistinct##syntax"}{...}
{viewerjumpto "Description" "gdistinct##description"}{...}
{viewerjumpto "Options" "gdistinct##options"}{...}
{title:Title}


{p2colset 5 18 23 2}{...}
{p2col :{cmd:gdistinct} {hline 2}}Efficiently report number(s) of distinct observations or values{p_end}
{p2colreset}{...}

{pstd}
{it:Important}: Please run {stata gtools, upgrade} to update {cmd:gtools} to
the latest stable version.

{marker syntax}{...}
{title:Syntax}

{phang}
This is a fast option to the user command {help distinct},
additionally storing the results in a matrix.
It is 4 to 26 times faster in Stata/IC and 4-12 times faster in MP

{p 8 17 2}{cmd:gdistinct} [{varlist}]
{ifin}
[{cmd:,} {opt miss:ing}
{opt a:bbrev(#)}
{opt j:oint}
{opt min:imum(#)}
{opt max:imum(#)}
]


{marker description}{...}
{title:Description}

{pstd}
{opt gdistinct} is a faster alternative to {help distinct}.  It displays the
number of distinct observations with respect to the variables in {varlist}.
By default, each variable is considered separately (excluding missing values)
so that the number of distinct observations for each variable is reported and
in this case the results are stored in a matrix.

{pstd}
The number of distinct observations is the same as the number of distinct
values.  Optionally, variables can be considered jointly so that the number
of distinct groups defined by the values of variables in {it:varlist} is
reported.

{pstd}
{opt gdistinct} is part of the {manhelp gtools R:gtools} project.

{marker options}{...}
{title:Options}

{dlgtab:Options}

{p 4 4 2}{cmd:missing} specifies that missing values are to be included
in counting distinct observations.

{p 4 4 2}{opt abbrev(#)} specifies that variable names are to be
displayed abbreviated to at most {it:#} characters.  This option has no
effect with {cmd:joint}.

{p 4 4 2}{cmd:joint} specifies that distinctness is to be determined
jointly for the variables in {it:varlist}.

{p 4 4 2}{opt minimum(#)} specifies that numbers of distinct values are to be displayed only if they are
equal to or greater than a specified minimum.

{p 4 4 2}{opt maximum(#)} specifies that numbers of distinct values are to be displayed only if they are
less than or equal to a specified maximum.

{dlgtab:Gtools}

{phang}
{opt compress} Try to compress strL to str#. The Stata Plugin Interface
has only limited support for strL variables. In Stata 13 and earlier
(version 2.0) there is no support, and in Stata 14 and later (version
3.0) there is read-only support. The user can try to compress strL
variables using this option.

{phang} 
{opt forcestrl} Skip binary variable check and force gtools to read strL
variables (14 and above only). {opt Gtools gives incorrect results when there is binary data in strL variables}.
This option was included because on some windows systems Stata detects
binary data even when there is none. Only use this option if you are
sure you do not have binary data in your strL variables.

{phang}
{opt verbose} prints some useful debugging info to the console.

{phang}
{opt bench:mark} and {opt bench:marklevel(int)} print how long in
seconds various parts of the program take to execute. The user can also
pass {opth bench(int)} for finer control. {opt bench(1)} is the same
as benchmark but {opt bench(2)} and {opt bench(3)} additionally print
benchmarks for internal plugin steps.

{phang}
{opth hashmethod(str)} Hash method to use. {opt default} automagically
chooses the algorithm. {opt biject} tries to biject the inputs into the
natural numbers. {opt spooky} hashes the data and then uses the hash.

{phang}
{opth oncollision(str)} How to handle collisions. A collision should never
happen but just in case it does {opt gtools} will try to use native commands.
The user can specify it throw an error instead by passing {opt oncollision(error)}.

{marker examples}{...}
{title:Examples}

{p 4 4 2}{cmd:. sysuse auto}{p_end}
{p 4 4 2}{cmd:. gdistinct} {p_end}
{p 4 4 2}{cmd:. gdistinct, max(10)} {p_end}
{p 4 4 2}{cmd:. gdistinct make-headroom}{p_end}
{p 4 4 2}{cmd:. gdistinct make-headroom, missing abbrev(6)}{p_end}
{p 4 4 2}{cmd:. gdistinct foreign rep78, joint}{p_end}
{p 4 4 2}{cmd:. gdistinct foreign rep78, joint missing}

{pstd}
See the
{browse "http://gtools.readthedocs.io/en/latest/usage/gdistinct/index.html#examples":online documentation}
for more examples.

{marker results}{...}
{title:Stored results}

{pstd}
{cmd:gdistinct} stores the following in {cmd:r()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:r(N)        }} number of non-missing observations (last variable or joint) {p_end}
{synopt:{cmd:r(J)        }} number of groups (last variable or joint) {p_end}
{synopt:{cmd:r(ndistinct)}} number of groups (last variable or joint) {p_end}
{synopt:{cmd:r(minJ)     }}largest group size (last variable or joint) {p_end}
{synopt:{cmd:r(maxJ)     }}smallest group size (last variable or joint) {p_end}
{p2colreset}{...}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Matrices}{p_end}
{synopt:{cmd:r(ndistinct)}}number of non-missing observations (one row per variable or joint){p_end}
{p2colreset}{...}


{marker author}{...}
{title:Author}

{pstd}Mauricio Caceres Bravo{p_end}
{pstd}{browse "mailto:mauricio.caceres.bravo@gmail.com":mauricio.caceres.bravo@gmail.com }{p_end}
{pstd}{browse "https://mcaceresb.github.io":mcaceresb.github.io}{p_end}

{title:Website}

{pstd}{cmd:gdistinct} is maintained as part of {manhelp gtools R:gtools} at {browse "https://github.com/mcaceresb/stata-gtools":github.com/mcaceresb/stata-gtools}{p_end}

{marker acknowledgment}{...}
{title:Acknowledgment}

{pstd}
This help file was based on the help file for {it:distinct}.
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
{help gunique}, 
{help gtools};
{help distinct} (if installed)

