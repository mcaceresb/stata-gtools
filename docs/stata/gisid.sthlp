{smcl}
{* *! version 1.1.1  23Jan2019}{...}
{viewerdialog gisid "dialog gisid"}{...}
{vieweralsosee "[D] gisid" "mansection D gisid"}{...}
{viewerjumpto "Syntax" "gisid##syntax"}{...}
{viewerjumpto "Description" "gisid##description"}{...}
{viewerjumpto "Options" "gisid##options"}{...}
{title:Title}


{p2colset 5 18 23 2}{...}
{p2col :{cmd:gisid} {hline 2}}Efficiently check for unique identifiers using C plugins.{p_end}
{p2colreset}{...}

{pstd}
{it:Important}: Please run {stata gtools, upgrade} to update {cmd:gtools} to
the latest stable version.

{marker syntax}{...}
{title:Syntax}

{phang}
This is a fast option to Stata's {opt isid}.
It is 8 to 30 times faster in Stata/IC and 4-14 times faster in MP

{p 8 13 2}
{cmd:gisid}
{varlist}
{ifin}
[{cmd:,}
{opt m:issok}]


{marker description}{...}
{title:Description}

{pstd}
{opt gisid} is a faster alternative to {help isid}. It can check for an ID in
a subset of the data, but it can't do it for an external dataset or sort the data.

{pstd}
{opt gisid} is part of the {manhelp gtools R:gtools} project.


{marker options}{...}
{title:Options}

{phang}{opt missok} indicates that missing values are permitted in {varlist}.

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

{pstd}
See {help isid##examples} or the
{browse "http://gtools.readthedocs.io/en/latest/usage/gisid/index.html#examples":online documentation}
for examples.


{marker author}{...}
{title:Author}

{pstd}Mauricio Caceres Bravo{p_end}
{pstd}{browse "mailto:mauricio.caceres.bravo@gmail.com":mauricio.caceres.bravo@gmail.com }{p_end}
{pstd}{browse "https://mcaceresb.github.io":mcaceresb.github.io}{p_end}


{title:Website}

{pstd}{cmd:gisid} is maintained as part of {manhelp gtools R:gtools} at {browse "https://github.com/mcaceresb/stata-gtools":github.com/mcaceresb/stata-gtools}{p_end}


{marker acknowledgment}{...}
{title:Acknowledgment}

{pstd}
This help file was based on StataCorp's own help file
for {it:isid} and Sergio Correia's help file for {it:fisid}.
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
{help gisid}, 
{help gtools};
{help fisid} (if installed), 
{help ftools} (if installed)

