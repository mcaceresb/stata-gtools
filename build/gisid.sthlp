{smcl}
{* *! version 0.8.1  02May2018}{...}
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
{it:Note for Windows users}: It may be necessary to run
{opt gtools, dependencies} at the start of your Stata session.

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
See {help isid##examples} or the
{browse "http://gtools.readthedocs.io/en/latest/usage/gisid/index.html#examples":online documentation}
for examples.


{marker author}{...}
{title:Author}

{pstd}Mauricio Caceres{p_end}
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

