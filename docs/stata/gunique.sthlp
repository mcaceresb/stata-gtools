{smcl}
{* *! version 0.2.0  31Oct2017}{...}
{viewerdialog gunique "dialog gunique"}{...}
{vieweralsosee "[D] gunique" "mansection D gunique"}{...}
{viewerjumpto "Syntax" "gunique##syntax"}{...}
{viewerjumpto "Description" "gunique##description"}{...}
{viewerjumpto "Options" "gunique##options"}{...}
{title:Title}


{p2colset 5 18 23 2}{...}
{p2col :{cmd:gunique} {hline 2}}Efficiently calculate unique values of a variable or group of variables.{p_end}
{p2colreset}{...}

{pstd}
{it:Note for Windows users}: It may be necessary to run
{opt gtools, dependencies} at the start of your Stata session.

{marker syntax}{...}
{title:Syntax}

{phang}
This is a fast option to the user written {opt unique}.
It is 4 to 26 times faster in Stata/IC and 4-12 times faster in MP

{p 8 13 2}
{cmd:gunique}
{varlist}
{ifin}
[{cmd:,}
{opt d:etail}]


{marker description}{...}
{title:Description}

{pstd}
{opt gunique} is a faster alternative to {help unique}. It reports the number
of unique values for the {it:varlist}. At the moment, its main difference from
{opt distinct} is that it always considers the variables jointly. It also has
slighly different options. A future release will include {opt by(varlist)} in
order to compute the number of rows of {varlist} by the groups specified in
{opt by}. This feature is not yeat available, however.

{pstd}
{opt gunique} is part of the {manhelp gtools R:gtools} project.

{marker options}{...}
{title:Options}

{phang}
{opt detail} request summary statistics on the number of records which are
present for unique values of the varlist.

{phang}
{opt verbose} prints some useful debugging info to the console.

{phang}
{opt benchmark} prints how long in seconds various parts of the program
take to execute.

{phang}
{opth hashlib(str)} On earlier versions of gtools Windows users had a problem
because Stata was unable to find {it:spookyhash.dll}, which is bundled with
gtools and required for the plugin to run correctly. The best thing a Windows
user can do is run {opt gtools, dependencies} at the start of their Stata
session, but if Stata cannot find the plugin the user can specify a path
manually here.


{marker example}{...}
{title:Examples}

{p 4 4 2}{cmd:. sysuse auto}{p_end}
{p 4 4 2}{cmd:. gunique *} {p_end}
{p 4 4 2}{cmd:. gunique *, miss} {p_end}
{p 4 4 2}{cmd:. gunique make-headroom}{p_end}
{p 4 4 2}{cmd:. gunique make-headroom, d}{p_end}

{pstd}
See the
{browse "http://gtools.readthedocs.io/en/latest/usage/gunique/index.html#examples":online documentation}
for more examples.

{marker results}{...}
{title:Stored results}

{pstd}
{cmd:gunique} stores the following in {cmd:r()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:r(N)     }} number of non-missing observations {p_end}
{synopt:{cmd:r(J)     }} number of groups {p_end}
{synopt:{cmd:r(unique)}} number of groups {p_end}
{synopt:{cmd:r(minJ)  }}largest group size {p_end}
{synopt:{cmd:r(maxJ)  }}smallest group size {p_end}
{p2colreset}{...}


{marker author}{...}
{title:Author}

{pstd}Mauricio Caceres{p_end}
{pstd}{browse "mailto:mauricio.caceres.bravo@gmail.com":mauricio.caceres.bravo@gmail.com }{p_end}
{pstd}{browse "https://mcaceresb.github.io":mcaceresb.github.io}{p_end}

{title:Website}

{pstd}{cmd:gunique} is maintained as part of {manhelp gtools R:gtools} at {browse "https://github.com/mcaceresb/stata-gtools":github.com/mcaceresb/stata-gtools}{p_end}

{marker acknowledgment}{...}
{title:Acknowledgment}

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
{help gdistinct}, 
{help gtools};
{help unique} (if installed), 
{help ftools} (if installed)

