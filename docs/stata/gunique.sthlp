{smcl}
{* *! version 1.0.2  23Jan2019}{...}
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
{it:Important}: Please run {stata gtools, upgrade} to update {cmd:gtools} to
the latest stable version.

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
slighly different options. For example, this supports the {opth by(varlist)}
option that also appears in the {opt unique} command, but does not support
computing the number of unique values for variables individually.

{pstd}
{opt gunique} is part of the {manhelp gtools R:gtools} project.

{marker options}{...}
{title:Options}

{phang}
{opth by(varlist)} counts unique values within levels of {it:varlist} and
stores them in a new variable named {bf:_Unique}. The user can specify the
name of the new variable via the option {opth gen:erate(varname)}.

{phang}
{opth gen:erate(varname)} supplies an alternative name for the new variable
created by {bf:by}.

{phang}
{opt replace} replaces {bf:_Unique} or the variable specified via {opt
generate}, if it exists.

{phang}
{opt detail} request summary statistics on the number of records which are
present for unique values of the varlist. With {opt by()}, it also prints
the levels with the most unique values.

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

{pstd}Mauricio Caceres Bravo{p_end}
{pstd}{browse "mailto:mauricio.caceres.bravo@gmail.com":mauricio.caceres.bravo@gmail.com }{p_end}
{pstd}{browse "https://mcaceresb.github.io":mcaceresb.github.io}{p_end}

{title:Website}

{pstd}{cmd:gunique} is maintained as part of {manhelp gtools R:gtools} at {browse "https://github.com/mcaceresb/stata-gtools":github.com/mcaceresb/stata-gtools}{p_end}

{marker acknowledgment}{...}
{title:Acknowledgment}

{pstd}
{cmd:gunique} was written largely to mimic the functionality of the community-contributed command {cmd:unique},
written by

{p 8 8 2}
Michael Hills, retired{break} 

{p 8 8 2}
Tony Brady, Sealed Envelope Ltd, UK (tony@sealedenvelope.com)

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

