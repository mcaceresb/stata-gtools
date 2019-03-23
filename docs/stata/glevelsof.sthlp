{smcl}
{* *! version 1.2.0  23Mar2019}{...}
{vieweralsosee "[P] glevelsof" "mansection P glevelsof"}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "[P] foreach" "help foreach"}{...}
{vieweralsosee "" "--"}{...}
{viewerjumpto "Syntax" "glevelsof##syntax"}{...}
{viewerjumpto "Description" "glevelsof##description"}{...}
{viewerjumpto "Options" "glevelsof##options"}{...}
{viewerjumpto "Remarks" "glevelsof##remarks"}{...}
{viewerjumpto "Stored results" "glevelsof##results"}{...}
{title:Title}

{p2colset 5 18 23 2}{...}
{p2col :{cmd:glevelsof} {hline 2}}Efficiently get levels of variable using C plugins{p_end}
{p2colreset}{...}

{pstd}
{it:Important}: Please run {stata gtools, upgrade} to update {cmd:gtools} to
the latest stable version.

{marker syntax}{...}
{title:Syntax}

{phang}
This is a fast option to Stata's {opt levelsof}. It can additionally take
multiple variables.
It is 3 to 13 times faster in Stata/IC and 2.5-7 times faster in MP

{p 8 17 2}
{cmd:glevelsof}
{varlist}
{ifin}
[{cmd:,} {it:options}]

{pstd}
Instead of {varlist}, it is possible to specify

{p 8 17 2}
[{cmd:+}|{cmd:-}]
{varname}
[[{cmd:+}|{cmd:-}]
{varname} {it:...}]

{pstd}
To change the sort order of the results.

{synoptset 25 tabbed}{...}
{marker table_options}{...}
{synopthdr}
{synoptline}
{syntab :Options}
{synopt:{opt c:lean}}display string values without compound double quotes{p_end}
{synopt:{opt l:ocal(macname)}}insert the list of values in the local macro {it:macname}{p_end}
{synopt:{opt miss:ing}}include missing values of {varlist} in calculation{p_end}
{synopt:{opt s:eparate(separator)}}separator to serve as punctuation for the values of returned list; default is a space{p_end}

{syntab:Extras}
{synopt:{opt nolocal:var}}Do not store the levels of {opt varlist} in a local macro.{p_end}
{synopt:{opt silent}}Do not display the levels of varlist. For use with {opt gen()} and {opt mata:save}{p_end}
{synopt:{opt mata:save}[{cmd:(}{it:str}{cmd:)}]}Save results in mata object (default name is {bf:GtoolsByLevels}){p_end}
{synopt:{opt gen([prefix], [replace])}}Store the levels of {it:varlist} in new varlist ({opt prefix}) or {opt replace} {it:varlist} with its levels{p_end}
{synopt:{opt cols:eparate(separator)}}separator to serve as punctuation for the columns of returned list; default is a pipe{p_end}
{synopt:{opth numfmt(format)}}Number format for numeric variables. Default is {opt %.16g} (or {opt %16.0g} with {opt matasave}).{p_end}
{synopt:{opt unsorted}}do not sort levels (ignored if inputs are integers){p_end}

{syntab:Gtools}
{synopt :{opt compress}}Try to compress strL to str#.
{p_end}
{synopt :{opt forcestrl}}Skip binary variable check and force gtools to read strL variables.
{p_end}
{synopt :{opt v:erbose}}Print info during function execution.
{p_end}
{synopt :{cmd:bench}[{cmd:(}{int}{cmd:)}]}Benchmark various steps of the plugin. Optionally specify depth level.
{p_end}
{synopt :{opth hash:method(str)}}Hash method (default, biject, or spooky). Intended for debugging.
{p_end}
{synopt :{opth oncollision(str)}}Collision handling (fallback or error). Intended for debugging.
{p_end}

{synoptline}
{p2colreset}{...}

{marker description}{...}
{title:Description}

{pstd}
{cmd:glevelsof} displays a sorted list of the distinct values of {varlist}.
It is meant to be a fast replacement of {cmd:levelsof}. Unlike {cmd:levelsof},
it can take a single variable or multiple variables.

{pstd}
{cmd:glevelsof} is part of the {manhelp gtools R:gtools} project.


{marker options}{...}
{title:Options}

{dlgtab:Options}

{phang}
{cmd:clean} displays string values without compound double quotes.
By default, each distinct string value is displayed within compound double
quotes, as these are the most general delimiters.  If you know that the
string values in {varlist} do not include embedded spaces or embedded
quotes, this is an appropriate option.  {cmd:clean} 
does not affect the display of values from numeric variables.

{phang}
{cmd:local(}{it:macname}{cmd:)} inserts the list of values in
local macro {it:macname} within the calling program's space.  Hence,
that macro will be accessible after {cmd:glevelsof} has finished.
This is helpful for subsequent use, especially with {helpb foreach}.

{phang}
{cmd:missing} specifies that missing values of {varlist}
should be included in the calculation.  The default is to exclude them.

{phang}
{cmd:separate(}{it:separator}{cmd:)} specifies a separator
to serve as punctuation for the values of the returned list.
The default is a space.  A useful alternative is a comma.

{phang}
{cmd:colseparate(}{it:separator}{cmd:)} specifies a separator
to serve as punctuation for the columns of the returned list.
The default is a pipe.  Specifying a {varlist} instead of a
{varname} is only useful for double loops or for use with
{helpb gettoken}.

{phang}
{opth numfmt(format)} Number format for printing. By default numbers
are printed to 16 digits of precision, but the user can specify
the number format here. By default, only "%.#g|f" and "%#.#g|f" are
accepted since this is formated internally in C. However, with option
{opt matasave} this is formated in mata and has to be a mata format.

{phang}
{opth unsorted} Do not sort levels. This option is experimental and
only affects the output when the input is not an integer (for integers,
the levels are sorted internally regardless; the user would request the
spooky hash method via {opt hash()}, which obeys the {opt unsorted}
option, but this is intended for debugging). While not sorting the
levels is faster, {cmd:glevelsof} is typically used when the number
of levels is small (10s, 100s, 1000s) and thus speed savings will be
minimal.

{phang}
{opt nolocalvar}Do not store the levels of {opt varlist} in a local macro.
This is specially useful with option {opt gen()}.

{phang}
{opt silent}Do not display the levels of varlist. Mainly for use with
{opt gen()} and {opt mata:save}. With {opt mata:save}, the levels are
not sepparately stored as a string matrix, but the raw levels {it:are}
kept.

{phang}
{opt mata:save}[{cmd:(}{it:str}{cmd:)}]Save results in mata object (default
name is {bf:GtoolsByLevels}). See {opt GtoolsByLevels.desc()} for more.
This object contains the raw variable levels in {opt numx} and {opt charx}
(since mata does not allow matrices of mixed-type). The levels are saved
as a string in {opt printed} (with value labels correctly applied) unless
option {opt silent} is also specified.

{phang}
{opt gen([prefix], [replace])} Store the levels of {it:varlist} in new
varlist ({opt prefix}) or {opt replace} {it:varlist} with its levels.
These options are mutually exclusive.

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


{marker remarks}{...}
{title:Remarks}

{pstd}
{cmd:glevelsof} serves two different functions.  First, it gives a
compact display of the distinct values of {it:varlist}.  More commonly, it is
useful when you desire to cycle through the distinct values of
{it:varlist} with (say) {cmd:foreach}; see {helpb foreach:[P] foreach}.
{cmd:glevelsof} leaves behind a list in {cmd:r(levels)} that may be used in a
subsequent command.

{pstd}
{cmd:glevelsof} may hit the {help limits} imposed by your Stata.  However,
it is typically used when the number of distinct values of
{it:varlist} is modest. If you have many levels in varlist then
an alternative may be {help gtoplevelsof}, which shows the largest or smallest
levels of a varlist by their frequency count.


{marker examples}{...}
{title:Examples}

{phang}{cmd:. sysuse auto}

{phang}{cmd:. glevelsof rep78}{p_end}
{phang}{cmd:. display "`r(levels)'"}{p_end}

{phang}{cmd:. glevelsof rep78, miss local(mylevs)}{p_end}
{phang}{cmd:. display "`mylevs'"}{p_end}

{phang}{cmd:. glevelsof rep78, sep(,)}{p_end}
{phang}{cmd:. display "`r(levels)'"}{p_end}

{phang}{cmd:. glevelsof foreign rep78, sep(,)}{p_end}
{phang}{cmd:. display `"`r(levels)'"'}{p_end}

{phang}{cmd:. glevelsof foreign rep78, gen(uniq_) nolocal}{p_end}
{phang}{cmd:. desc uniq_*}{p_end}
{phang}{cmd:. glevelsof foreign rep78, mata(uniq) nolocal}{p_end}
{phang}{cmd:. mata uniq.desc()}{p_end}

{pstd}
See the
{browse "http://gtools.readthedocs.io/en/latest/usage/glevelsof/index.html#examples":online documentation}
for more examples.

{marker results}{...}
{title:Stored results}

{pstd}
{cmd:glevelsof} stores the following in {cmd:r()}:

{synoptset 15 tabbed}{...}
{p2col 5 15 19 2: Macros}{p_end}
{synopt:{cmd:r(levels)}}list of distinct values{p_end}
{p2colreset}{...}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:r(N)   }} number of non-missing observations {p_end}
{synopt:{cmd:r(J)   }} number of groups {p_end}
{synopt:{cmd:r(minJ)}} largest group size {p_end}
{synopt:{cmd:r(maxJ)}} smallest group size {p_end}
{p2colreset}{...}

{pstd}
With {opt matasave}, the following data is stored in {opt GtoolsByLevels}:

    real scalar anyvars
        1: any by variables; 0: no by variables

    real scalar anychar
        1: any string by variables; 0: all numeric by variables

    real scalar anynum
        1: any numeric by variables; 0: all string by variables

    string rowvector byvars
        by variable names

    real scalar kby
        number of by variables

    real scalar rowbytes
        number of bytes in one row of the internal by variable matrix

    real scalar J
        number of levels

    real matrix numx
        numeric by variables

    string matrix charx
        string by variables

    real scalar knum
        number of numeric by variables

    real scalar kchar
        number of string by variables

    real rowvector lens
        > 0: length of string by variables; <= 0: internal code for numeric variables

    real rowvector map
        map from index to numx and charx

    real rowvector charpos
        position of kth character variable

    string matrix printed
        formatted (printf-ed) variable levels (not with option -silent-)

{marker author}{...}
{title:Author}

{pstd}Mauricio Caceres Bravo{p_end}
{pstd}{browse "mailto:mauricio.caceres.bravo@gmail.com":mauricio.caceres.bravo@gmail.com }{p_end}
{pstd}{browse "https://mcaceresb.github.io":mcaceresb.github.io}{p_end}

{title:Website}

{pstd}{cmd:glevelsof} is maintained as part of {manhelp gtools R:gtools} at {browse "https://github.com/mcaceresb/stata-gtools":github.com/mcaceresb/stata-gtools}{p_end}

{marker acknowledgment}{...}
{title:Acknowledgment}

{pstd}
This help file was based on StataCorp's own help file for {it:levelsof}.
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
{help gtoplevelsof}, 
{help gtools};
{help flevelsof} (if installed), 
{help ftools} (if installed)

