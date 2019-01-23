{smcl}
{* *! version 0.1.4  23Jan2019}{...}
{viewerdialog gstats "dialog gstats"}{...}
{vieweralsosee "[R] gstats" "mansection R gstats"}{...}
{viewerjumpto "Syntax" "gstats##syntax"}{...}
{viewerjumpto "Description" "gstats##description"}{...}
{title:Title}

{p2colset 5 18 23 2}{...}
{p2col :{cmd:gstats} {hline 2}} Various statistical fucntions and transformations. {p_end}
{p2colreset}{...}

{pstd}
{it:Important}: Please run {stata gtools, upgrade} to update {cmd:gtools} to
the latest stable version.

{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:gstats}
{it:subcommand}
{varlist}
{ifin}
[{it:{help gstats##weight:weight}}]
[{cmd:,} {opth by(varlist)} {it:{help gstats##table_options:subcommand_options}}]

{phang}
{opt gstats} is a wrapper for various statistical functions and
transformations, including:

{p 8 17 2}
{it:gstats winsor} as a fast {opt winsor2} alternative (accepts weights). {p_end}

{synoptset 19 tabbed}{...}
{marker table_options}{...}
{synopthdr}
{synoptline}
{syntab :Winsor Options}
{synopt :{opth p:refix(str)}} Generate targets as {it:prefix}source (default empty).
{p_end}
{synopt :{opth s:uffix(str)}}  Generate targets as source{it:suffix} (default {it:_w} with cut and {it:_tr} with {opt trim}).
{p_end}
{synopt :{opth gen:erate(namelist)}} Named targets to generate; one per source.
{p_end}
{synopt :{opt c:uts(#.# #.#)}} Cut points (detault 1.0 and 99.0 for 1st and 99th percentiles).
{p_end}
{synopt :{opt t:rim}} Trim instead of Winsorize (i.e. replace outliers with missing values).
{p_end}
{synopt :{opt l:abel}} Add Winsorized/trimming note to target labels.
{p_end}
{synopt :{opt replace}} Replace targets if they exist.
{p_end}

{syntab:Gtools Options}
{synopt :{opt compress}}Try to compress strL to str#.
{p_end}
{synopt :{opt forcestrl}}Skip binary variable check and force gtools to read strL variables.
{p_end}
{synopt :{opt v:erbose}}Print info during function execution.
{p_end}
{synopt :{opt bench}{it:[(int)]}}Benchmark various steps of the plugin. Optionally specify depth level.
{p_end}
{synopt :{opth hash:method(str)}}Hash method (default, biject, or spooky). Intended for debugging.
{p_end}
{synopt :{opth oncollision(str)}}Collision handling (fallback or error). Intended for debugging.
{p_end}

{synoptline}
{p2colreset}{...}
{p 4 6 2}

{marker weight}{...}
{p 4 6 2}
{opt aweight}s, {opt fweight}s, {opt iweight}s, and {opt pweight}s are
allowed (see {manhelp weight U:11.1.6 weight} for more on the way Stata
uses weights).

{marker description}{...}
{title:Description}

{pstd}
{opt gstats} is a wrapper to several statistical fucntions and
transformations. In theory {opt gegen} would be the place to expand
{opt gtools}; however, {opt gegen}'s internally implemented functions
were written with two assumptions: first, the output is unique at the
group level; second, there is always a target variable. {opt gstats}
is written to be more flexible and allow arbitrary functions and
transformations.

{pstd}
Weights are supported for the following subcommands: {it:winsor}.

{marker example}{...}
{title:Examples}

{pstd}
See the
{browse "http://gtools.readthedocs.io/en/latest/usage/gstats/index.html#examples":online documentation}
for examples.

{marker author}{...}
{title:Author}

{pstd}Mauricio Caceres{p_end}
{pstd}{browse "mailto:mauricio.caceres.bravo@gmail.com":mauricio.caceres.bravo@gmail.com }{p_end}
{pstd}{browse "https://mcaceresb.github.io":mcaceresb.github.io}{p_end}

{title:Website}

{pstd}{cmd:gstats} is maintained as part of the {manhelp gtools R:gtools} project at {browse "https://github.com/mcaceresb/stata-gtools":github.com/mcaceresb/stata-gtools}{p_end}

{marker acknowledgment}{...}
{title:Acknowledgment}

{pstd}
{opt gtools} was largely inspired by Sergio Correia's {it:ftools}:
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
{help winsor2} (if installed)
