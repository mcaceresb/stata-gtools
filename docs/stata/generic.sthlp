{smcl}
{* *! version 1.0.2  23Jan2019}{...}
{viewerdialog g[command] "dialog g[command]"}{...}
{vieweralsosee "[R] g[command]" "mansection R g[command]"}{...}
{viewerjumpto "Syntax" "g[command]##syntax"}{...}
{viewerjumpto "Description" "g[command]##description"}{...}
{viewerjumpto "Options" "g[command]##options"}{...}
{viewerjumpto "Stored results" "gegen##results"}{...}
{title:Title}

{p2colset 5 18 23 2}{...}
{p2col :{cmd:g[command]} {hline 2}}[desciption] using C plugins.{p_end}
{p2colreset}{...}

{pstd}
{it:Important}: Please run {stata gtools, upgrade} to update {cmd:gtools} to
the latest stable version.

{marker syntax}{...}
{title:Syntax}

{phang}
This is a fast option to Stata's {opt [command]}.

{p 8 17 2}
{varlist}
{ifin}
[{cmd:,} {it:{help g[command]##table_options:options}}]

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
{syntab :Options}
{synopt :{opth xx(xx)}} [desc]
{p_end}
{synopt :{opt yy}} [desc]
{p_end}

{syntab:Extras}
{synopt :{opth xx(xx)}} [desc]
{p_end}
{synopt :{opt yy}} [desc]
{p_end}

{syntab:Switches}
{synopt :{opt zz}} [desc]
{p_end}

{syntab:Gtools}
{synopt :{opth compress}}Try to compress strL to str#.
{p_end}
{synopt :{opth forcestrl}}Skip binary variable check and force gtools to read strL variables.
{p_end}
{synopt :{opt v:erbose}}Print info during function execution.
{p_end}
{synopt :{opt bench[(int)]}}Benchmark various steps of the plugin. Optionally specify depth level.
{p_end}
{synopt :{opth hash:method(str)}}Hash method (default, biject, or spooky). Intended for debugging.
{p_end}
{synopt :{opth oncollision(str)}}Collision handling (fallback or error). Intended for debugging.
{p_end}

{synoptline}
{p2colreset}{...}
{p 4 6 2}

{marker description}{...}
{title:Description}

{pstd}
{opt g[command]} does things.

{pstd}
[depends] Weights are currently not supported.

{marker options}{...}
{title:Options}

{dlgtab:Options}

{phang}
{opth xx(xx)} [desc]

{phang}
{opt yy} [desc]

{dlgtab:Extras}

{phang}
{opth xx(xx)} [desc]

{phang}
{opt yy} [desc]

{dlgtab:Switches}

{phang}
{opt zz} [desc]

{dlgtab:Gtools}

{phang}
{opt verbose} prints some useful debugging info to the console.

{phang}
{opt benchmark} prints how long in seconds various parts of the program
take to execute.

{marker example}{...}
{title:Examples}

{pstd}
See the
{browse "https://github.com/mcaceresb/stata-gtools/blob/master/README.md#installation":README.md}
in the git repo.

{marker results}{...}
{title:Stored results}

{pstd}
{cmd:g[command]} stores the following in {cmd:r()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:r(N)   }} number of non-missing observations {p_end}
{synopt:{cmd:r(J)   }} number of groups {p_end}
{synopt:{cmd:r(minJ)}} largest group size {p_end}
{synopt:{cmd:r(maxJ)}} smallest group size {p_end}
{p2colreset}{...}


{marker author}{...}
{title:Author}

{pstd}Mauricio Caceres{p_end}
{pstd}{browse "mailto:mauricio.caceres.bravo@gmail.com":mauricio.caceres.bravo@gmail.com }{p_end}
{pstd}{browse "https://mcaceresb.github.io":mcaceresb.github.io}{p_end}

{title:Website}

{pstd}{cmd:g[command]} is maintained as part of {manhelp gtools R:gtools} at {browse "https://github.com/mcaceresb/stata-gtools":github.com/mcaceresb/stata-gtools}{p_end}

{marker acknowledgment}{...}
{title:Acknowledgment}

{pstd}
This help file was based on StataCorp's own help file
for {it:[command]} and Sergio Correia's help file for {it:f[command]}.
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
{help g[command]}, 
{help gtools};
{help f[command]} (if installed), 
{help ftools} (if installed)
