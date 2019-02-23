{smcl}
{* *! version 0.1.0  22Jan2019}{...}
{viewerdialog gstats_summarize "dialog gstats_summarize"}{...}
{vieweralsosee "[R] gstats_summarize" "mansection R gstats_summarize"}{...}
{viewerjumpto "Syntax" "gstats_summarize##syntax"}{...}
{viewerjumpto "Description" "gstats_summarize##description"}{...}
{viewerjumpto "Statistics" "gstats_summarize##statistics"}{...}
{title:Title}

{p2colset 5 25 28 2}{...}
{p2col :{cmd:gstats summarize} {hline 2}} Summary statistics using C for speed {p_end}
{p2colreset}{...}

{pstd}
{it:Important}: Please run {stata gtools, upgrade} to update {cmd:gtools} to
the latest stable version.

{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:gstats {ul:sum}marize}
{varlist}
{ifin}
[{it:{help gstats##weight:weight}}]
[{cmd:,} {opth by(varlist)} {it:{help gstats##table_options:options}}]

{pstd}
{cmd:gstats {ul:sum}marize} is a fast, by-able alternative to
{opt tabtsat} and {opt summarize, detail}. By default it will compute
the equivalent of {opt summarize, detail}. If called with {opt by()},
a table in the style of {opt tabstat} is produced that inclues all the
summary statistics included by default in {opt summarize, detail}.

{pstd}
The user can switch the output behavior via the {opt tab:stat} or
{opt s:tatistics()} options, which will mimic the default behavior
of {opt tabstat}. In addition, an alias is provided:

{p 8 17 2}
{cmd:gstats {ul:tab}stat}
{varlist}
{ifin}
[{it:{help gstats##weight:weight}}]
[{cmd:,} {opth by(varlist)} {it:{help gstats##table_options:options}}]

{pstd}
Note the {it:prefixes} {cmd:by}, {cmd:rolling}, {cmd:statsby} are
{cmd:{it:not}} supported. To compute a table of statistics by a group you
must use the option {opt by()}. Last, the display options of {opt tabstat}
and {opt summarize} are not currently supported but limited support for
some of their display options is planned for a future release.

{synoptset 23 tabbed}{...}
{marker table_options}{...}
{synopthdr}
{synoptline}
{syntab :Summarize Options}
{synopt:{opt nod:etail}}Do not display the full set of statistics.
{p_end}
{synopt:{opt mean:only}}Calculate only the count, sum, mean, min, max.
{p_end}
{synopt:{opth by(varname)}}Group by variable; all stats are computed but output is in the style of tabstat.
{p_end}
{synopt:{opt sep:arator(#)}}draw separator line after every {it:#} variables; default is {cmd:separator(5)}.
{p_end}
{synopt:{opt f:ormat}}use variable's display format.
{p_end}

{syntab :Tabstat Options}
{synopt:{opt tab:stat}}Compute and display statistics in the style of {opt tabstat}.
{p_end}
{synopt:{opth by(varname)}}Group statistics by variable.
{p_end}
{synopt:{cmdab:s:tatistics:(}{it:{help tabstat##statname:stat}} [{it:...}]{cmd:)}}Report
specified statistics; default for {opt tabstat} is count, sum, mean, sd, min, max.
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
Note that {opt summarize} by itself (or with option {opt meanonly}) is
not specially slow. If you do not need to use {opt by()}, {opt detail},
or {opt tabstat}, then you are better off using plain {opt summarize}.
However, with any of those options {cmd:gstats} is orders of magnitude faster
than the built-in equivalents.

{pstd}
This also means that the {opt nod:etail} and {opt meanonly} options are
mainly useful when combined with {opt by()} as short-hand for computing
the basic summarize or meanonly statistics by group.

{pstd}
Last, I will note that when computing statistics for multiple variables,
{cmd:gstats} tries to saves the results in a matrix (if this is not feasible
because there are too many variables or by groups, the results will be saved
in mata objects). This might be another reason to prefer {opt gstats}, but
your milage may vary on this point.

{marker statistics}{...}
{title:Statistics}

{phang}
{cmd:statistics(}{it:statname} [{it:...}]{cmd:)}
   specifies the statistics to be displayed; the default with {opt tabstat}
   is equivalent to specifying {cmd:statistics(mean)}. ({opt stats()}
   is a synonym for {opt statistics()}.) Multiple statistics
   may be specified and are separated by white space, such as
   {cmd:statistics(mean sd)}. Available statistics are

{marker statname}{...}
{synoptset 17}{...}
{synopt:{space 4}{it:statname}}Definition{p_end}
{space 4}{synoptline}
{synopt:{space 4}{opt me:an}} mean{p_end}
{synopt:{space 4}{opt co:unt}} count of nonmissing observations{p_end}
{synopt:{space 4}{opt n}} same as {cmd:count}{p_end}
{synopt:{space 4}{opt nmiss:ing}} number of missing observations{p_end}
{synopt:{space 4}{opt perc:ent}} percentage of nonmissing observations{p_end}
{synopt:{space 4}{opt nuniq:ue}} number of unique elements{p_end}
{synopt:{space 4}{opt su:m}} sum{p_end}
{synopt:{space 4}{opt rawsu:m}} sum, ignoring optionally specified weights ({bf:note}: zero-weighted obs are still excluded){p_end}
{synopt:{space 4}{opt nansu:m}} sum; returns . instead of 0 if all entries are missing{p_end}
{synopt:{space 4}{opt rawnansu:m}} rawsum; returns . instead of 0 if all entries are missing{p_end}
{synopt:{space 4}{opt med:ian}} median (same as {opt p50}){p_end}
{synopt:{space 4}{opt p#.#}} arbitrary quantiles{p_end}
{synopt:{space 4}{opt p1}} 1st percentile{p_end}
{synopt:{space 4}{opt p2}} 2nd percentile{p_end}
{synopt:{space 4}{it:...}} 3rd-49th percentiles{p_end}
{synopt:{space 4}{opt p50}} 50th percentile (same as {opt median}){p_end}
{synopt:{space 4}{it:...}} 51st-97th percentiles{p_end}
{synopt:{space 4}{opt p98}} 98th percentile{p_end}
{synopt:{space 4}{opt p99}} 99th percentile{p_end}
{synopt:{space 4}{opt iqr}} interquartile range = {opt p75} - {opt p25}{p_end}
{synopt:{space 4}{opt q}} equivalent to specifying {cmd:p25 p50 p75}{p_end}
{synopt:{space 4}{opt sd}} standard deviation{p_end}
{synopt:{space 4}{opt v:ariance}} variance{p_end}
{synopt:{space 4}{opt cv}} coefficient of variation ({cmd:sd/mean}){p_end}
{synopt:{space 4}{opt select#}} #th smallest{p_end}
{synopt:{space 4}{opt select-#}} #th largest{p_end}
{synopt:{space 4}{opt mi:n}} minimum (same as {opt select1}){p_end}
{synopt:{space 4}{opt ma:x}} maximum (same as {opt select-1}){p_end}
{synopt:{space 4}{opt r:ange}} range = {opt max} - {opt min}{p_end}
{synopt:{space 4}{opt first}} first value{p_end}
{synopt:{space 4}{opt last}} last value{p_end}
{synopt:{space 4}{opt firstnm}} first nonmissing value{p_end}
{synopt:{space 4}{opt lastnm}} last nonmissing value{p_end}
{synopt:{space 4}{opt sem:ean}} standard error of mean ({cmd:sd/sqrt(n)}){p_end}
{synopt:{space 4}{opt seb:inomial}} standard error of the mean, binomial ({cmd:sqrt(p(1-p)/n)}){p_end}
{synopt:{space 4}{opt sep:oisson}} standard error of the mean, Poisson ({cmd:sqrt(mean)}){p_end}
{synopt:{space 4}{opt sk:ewness}} skewness{p_end}
{synopt:{space 4}{opt k:urtosis}} kurtosis{p_end}
{space 4}{synoptline}
{p2colreset}{...}

{marker example}{...}
{title:Examples}

{pstd}
See the
{browse "http://gtools.readthedocs.io/en/latest/usage/gstats_summarize/index.html#examples":online documentation}
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
{help gtools};
{help winsor2} (if installed)
