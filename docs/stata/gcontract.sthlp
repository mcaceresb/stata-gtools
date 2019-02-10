{smcl}
{* *! version 1.0.2  23Jan2019}{...}
{viewerdialog gcontract "dialog gcontract"}{...}
{vieweralsosee "[R] gcontract" "mansection R gcontract"}{...}
{viewerjumpto "Syntax" "gcontract##syntax"}{...}
{viewerjumpto "Description" "gcontract##description"}{...}
{viewerjumpto "Options" "gcontract##options"}{...}
{viewerjumpto "Stored results" "gegen##results"}{...}
{title:Title}

{p2colset 5 18 23 2}{...}
{p2col :{cmd:gcontract} {hline 2}}Efficiently make dataset of frequencies and percentages using C plugins.{p_end}
{p2colreset}{...}

{pstd}
{it:Important}: Please run {stata gtools, upgrade} to update {cmd:gtools} to
the latest stable version.

{marker syntax}{...}
{title:Syntax}

{phang} This is a fast option to Stata's {opt contract}.
It is 5-7 times faster in Stata/IC and 2.5-4 times faster in MP

{p 8 17 2}
{cmd:gcontract}
{varlist}
{ifin}
[{it:{help gcontract##weight:weight}}]
[{cmd:,} {it:{help gcontract##table_options:options}}]

{pstd}
Instead of {varlist}, it is possible to specify

{p 8 17 2}
[{cmd:+}|{cmd:-}]
{varname}
[[{cmd:+}|{cmd:-}]
{varname} {it:...}]

{pstd}
This will not affect the results, but it will affect the sort order of the
final data.

{synoptset 18 tabbed}{...}
{marker table_options}{...}
{synopthdr}
{synoptline}
{synopt :{opth f:req(newvar)}}name of frequency variable; default is {opt _freq}{p_end}
{synopt :{opth cf:req(newvar)}}create cumulative frequency variable{p_end}
{synopt :{opth p:ercent(newvar)}}create percentage variable{p_end}
{synopt :{opth cp:ercent(newvar)}}create cumulative percentage variable{p_end}
{synopt :{opt float}}generate percentage variables as type {opt float}{p_end}
{synopt :{opth form:at(format)}}display format for new percentage variables; default is {cmd:format(%8.2f)}{p_end}
{synopt :{opt z:ero}}include combinations with frequency zero (VERY SLOW){p_end}
{synopt :{opt nomiss}}drop observations with missing values{p_end}

{syntab :Options}
{synopt :{opt unsorted}}Do not sort resulting dataset. Saves speed. {p_end}
{synopt :{opt fast}} Mirrors the same option in {opt collapse}. Do not preserve and restore the original dataset; saves speed but leaves the data in an unusable state shall the user press {hi:Break} {p_end}

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
{p 4 6 2}

{p 4 6 2}
{opt fweight}s are allowed; see {help weight}.
{p_end}

{marker description}{...}
{title:Description}

{pstd}
{opt gcontract} replaces the dataset in memory with a new dataset consisting
of all combinations of {varlist} that exist in the data and a new variable
that contains the frequency of each combination. The user can optionally request
percentages and cumulative counts and percentages.

{pstd}
{opt gcontract} is part of the {manhelp gtools R:gtools} project.

{marker options}{...}
{title:Options}

{dlgtab:Options}

{phang}
{opth freq(newvar)} specifies a name for the frequency
variable.  If not specified, {opt _freq} is used.

{phang}
{opth cfreq(newvar)} specifies a name for the
cumulative frequency variable.  If not specified, no cumulative frequency
variable is created.

{phang}
{opth percent(newvar)} specifies a name for the percentage variable.
If not specified, no percent variable is created.

{phang}
{opth cpercent(newvar)} specifies a name for the
cumulative percentage variable.  If not specified, no cumulative percentage
variable is created.

{phang}
{opt float} specifies that the percentage variables specified by
{opt percent()} and {opt cpercent()} will be stored as variables of type
{helpb data types:float}. This only affects the Stata storage type;
{opt gtools} does all computations internally in double precision. If
{opt float} is not specified, these variables will be generated as variables
of type {helpb double}.  All generated variables are compressed to the
smallest storage type possible without loss of precision; see {manhelp compress D}.

{phang}
{opth format(format)} specifies a
display format for the generated percentage variables specified
by {opt percent()} and {opt cpercent()}.  If {opt format()} is not specified,
these variables will have the display format {cmd:%8.2f}.

{phang}
{opt zero} specifies that combinations with frequency zero be included.
This is VERY slow.

{phang}
{opt nomiss} specifies that observations with missing values on any
variable in {varlist} be dropped.  If {opt nomiss} is not specified, all
observations possible are used.

{dlgtab:Extras}

{phang}
{opt fast} specifies that {opt gcollapse} not restore the original dataset
should the user press {hi:Break}.

{phang}
{opt unsorted} Do not sort resulting data set. Saves speed.

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

{marker example}{...}
{title:Examples}

{pstd}
See the
{browse "http://gtools.readthedocs.io/en/latest/usage/gcontract/index.html#examples":online documentation}
for examples.

{marker results}{...}
{title:Stored results}

{pstd}
{cmd:gcontract} stores the following in {cmd:r()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:r(N)   }} number of non-missing observations {p_end}
{synopt:{cmd:r(J)   }} number of groups {p_end}
{synopt:{cmd:r(minJ)}} largest group size {p_end}
{synopt:{cmd:r(maxJ)}} smallest group size {p_end}
{p2colreset}{...}


{marker author}{...}
{title:Author}

{pstd}Mauricio Caceres Bravo{p_end}
{pstd}{browse "mailto:mauricio.caceres.bravo@gmail.com":mauricio.caceres.bravo@gmail.com }{p_end}
{pstd}{browse "https://mcaceresb.github.io":mcaceresb.github.io}{p_end}

{title:Website}

{pstd}{cmd:gcontract} is maintained as part of {manhelp gtools R:gtools} at {browse "https://github.com/mcaceresb/stata-gtools":github.com/mcaceresb/stata-gtools}{p_end}

{marker acknowledgment}{...}
{title:Acknowledgment}

{pstd}
This help file was based on StataCorp's own help file for {it:contract}.
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
{help gcollapse}, 
{help gtools};
{help fcollapse} (if installed), 
{help ftools} (if installed)

