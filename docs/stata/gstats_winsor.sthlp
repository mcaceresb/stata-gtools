{smcl}
{* *! version 0.1.4  23Jan2019}{...}
{viewerdialog gstats_winsor "dialog gstats_winsor"}{...}
{vieweralsosee "[R] gstats_winsor" "mansection R gstats_winsor"}{...}
{viewerjumpto "Syntax" "gstats_winsor##syntax"}{...}
{viewerjumpto "Description" "gstats_winsor##description"}{...}
{title:Title}

{p2colset 5 22 34 2}{...}
{p2col :{cmd:gstats winsor} {hline 2}} Winsorize data using C for speed {p_end}
{p2colreset}{...}

{pstd}
{it:Important}: Please run {stata gtools, upgrade} to update {cmd:gtools} to
the latest stable version.

{marker syntax}{...}
{title:Syntax}

{pstd}
{it:gstats winsor} was written as a fast {opt winsor2} alternative. It
additionally accepts weights. {p_end}

{p 8 17 2}
{cmd:gstats winsor}
{varlist}
{ifin}
[{it:{help gstats##weight:weight}}]
[{cmd:,} {opth by(varlist)} {it:{help gstats##table_options:options}}]

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
{synopt :{opt nomiss:ing}} With {opt by()}, ignore groups with missing entries.
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
{it:gstats winsor} winsorizes or trims (if the trim option is specified)
the variables in varlist at particular percentiles specified by option
{opt cuts(#1 #2)}. By defult, new variables will be generated with a
suffix "_w" or "_tr", respectively. The user can control this via the
{opt suffix()} option.  The replace option replaces the variables with
their winsorized or trimmed ones.

{error}{dlgtab:Difference between winsorizing and trimming}{text}

{pstd}
{it:Important}: This section is nearly verbatim from the equivalent help
section from {help winsor2}.

{pstd}
Winsorizing is not equivalent to simply excluding data, which is
a simpler procedure, called trimming or truncation.  In a trimmed
estimator, the extreme values are discarded; in a Winsorized estimator,
the extreme values are instead replaced by certain percentiles,
specified by option cuts(# #). For details, see {help winsor} (if
installed), and {help trimmean} (if installed).

{pstd}
For example, you type the following commands to get the 1st and 99th 
percentiles of the variable wage, 1.930993 and 38.70926.

{phang2} {bf: . sysuse nlsw88, clear} {p_end}
{phang2} {bf: . sum wage, detail} {p_end}

{pstd}
By default, {cmd:gstats winsor} winsorizes wage at 1st and 99th percentiles,
 
{phang2} {bf: . gstats winsor wage, replace cuts(1 99)} {p_end}

{pstd}
which can be done by hand:

{phang2} {bf: . replace wage=1.930993 if wage<1.930993} {p_end}
{phang2} {bf: . replace wage=38.70926 if wage>38.70926} {p_end}

{pstd}

Note that, values smaller than the 1st percentile are repalced by that
value, and similarly with values above the 99th percentile. When the
-{bf:trim}- option is specified, those values are set to missing instead
(which are discarded by most commands):

{phang2} {bf: . gstats winsor wage, replace cuts(1 99) trim} {p_end}

{pstd}
which can also be done by hand:

{phang2} {bf: . replace wage=. if wage<1.930993} {p_end}
{phang2} {bf: . replace wage=. if wage>38.70926} {p_end}

{pstd}
In this case, we discard values smaller than 1th percentile or greater
than 99th percentile. This is trimming.

{marker example}{...}
{title:Examples}

{pstd}
See the
{browse "http://gtools.readthedocs.io/en/latest/usage/gstats_winsor/index.html#examples":online documentation}
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
{opt gstats winsor} was written largely to follow {opt winsor2} by Lian
(Arlion) Yujun.  The command's options and this helpfile borrow heavily
from {opt winsor2}.
{p_end}

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
{help gtools};
{help winsor2} (if installed)
