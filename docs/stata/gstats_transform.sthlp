{smcl}
{* *! version 0.1.0  08Jun2019}{...}
{viewerdialog gstats_transform "dialog gstats_transform"}{...}
{vieweralsosee "[R] gstats_transform" "mansection R gstats_transform"}{...}
{viewerjumpto "Syntax" "gstats_transform##syntax"}{...}
{viewerjumpto "Description" "gstats_transform##description"}{...}
{viewerjumpto "Statistics" "gstats_transform##statistics"}{...}
{title:Title}

{p2colset 5 25 28 2}{...}
{p2col :{cmd:gstats transform} {hline 2}} Apply statistical functions by group using C for speed {p_end}
{p2colreset}{...}

{pstd}
{it:Important}: Please run {stata gtools, upgrade} to update {cmd:gtools} to
the latest stable version.

{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:gstats transform}
{it:clist}
{ifin}
[{it:{help gstats transform##weight:weight}}]
[{cmd:,}
{it:{help gstats transform##table_options:options}}]

{pstd}where {it:clist} is either

{p 8 17 2}
[{opt (stat)}]
{varlist}
[ [{opt (stat)}] {it:...} ]{p_end}

{p 8 17 2}
[{opt (stat)}] {it:target_var}{cmd:=}{varname}
        [{it:target_var}{cmd:=}{varname} {it:...}]
        [ [{opt (stat)}] {it:...}]

{p 4 4 2}or any combination of the {it:varlist} or {it:target_var} forms, and
{it:stat} is one of{p_end}

{p2colset 9 22 24 2}{...}
{p2col :{opt demean}}subtract the mean (default){p_end}
{p2col :{opt demedian}}subtract the median{p_end}
{p2col :{opt normalize}}(x - mean) / sd{p_end}
{p2col :{opt standardize}}same as {opt normalize}{p_end}
{p2colreset}{...}

{synoptset 23 tabbed}{...}
{marker table_options}{...}
{synopthdr}
{synoptline}
{syntab :Options}
{synopt:{opth by(varname)}}Group statistics by variable.
{p_end}
{synopt:{opt replace}}Allow replacing existing variables.
{p_end}
{synopt :{opt wild:parse}}Allow rename-style syntax in target naming.
{p_end}
{synopt:{opt labelf:ormat}}Custom label engine: {bf:(#stat#) #sourcelabel#} is the default.
{p_end}
{synopt:{opth labelp:rogram(str)}}Program to parse {opt labelformat} (see examples).
{p_end}
{synopt:{opt nogreedy}}Use slower but memory-efficient (non-greedy) algorithm.
{p_end}
{synopt:{opth type:s(str)}}Override variable types for targets ({bf:use with caution}).
{p_end}

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

{marker weight}{...}
{p 4 6 2}
{opt aweight}s, {opt fweight}s, {opt iweight}s, and {opt pweight}s
are allowed.
{p_end}

{marker description}{...}
{title:Description}

{pstd}
{cmd:gstats transform} applies various statistical transformations
to input data. It is similar to {cmd:gcollapse, merge} or {cmd:gegen} but
for individual-level transformations. That is, {cmd:gcollapse} takes an
input variable and procudes a single statistic; {cmd:gstats transform}
applies a function to each element of the input variable. For example,
subtracting the mean.

{pstd}
Every function available to {cmd:gstats transform} can be called via
{cmd:gegen}.

{marker example}{...}
{title:Examples}

{pstd}
See the
{browse "http://gtools.readthedocs.io/en/latest/usage/gstats_transform/index.html#examples":online documentation}
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

{pstd}
help for
{help gegen};
{help gcollapse};
{help gtools}
