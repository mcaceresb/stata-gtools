{smcl}
{* *! version 0.2.0  25Feb2019}{...}
{viewerdialog gstats "dialog gstats"}{...}
{vieweralsosee "[R] gstats" "mansection R gstats"}{...}
{viewerjumpto "Syntax" "gstats##syntax"}{...}
{viewerjumpto "Description" "gstats##description"}{...}
{title:Title}

{p2colset 5 15 23 2}{...}
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
{help gstats winsor:{bf:winsor}}
as a fast {opt winsor2} alternative (accepts weights). {p_end}

{p 8 17 2}
{help gstats summarize:{bf:gstats {ul:sum}marize}} and
{help gstats summarize:{bf:gstats {ul:tab}stat}} are fast,
by-able alternatives to {opt summarize, detail} and {opt tabtsat} (accept weights). {p_end}

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
Weights are supported for the following subcommands: {it:winsor}, {it:summarize}.

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
{help gtools}
