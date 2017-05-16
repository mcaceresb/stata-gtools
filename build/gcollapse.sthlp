{smcl}
{* *! version 0.1.0 16May2017}{...}
{viewerdialog gcollapse "dialog gcollapse"}{...}
{vieweralsosee "[R] gcollapse" "mansection R gcollapse"}{...}
{viewerjumpto "Syntax" "gcollapse##syntax"}{...}
{viewerjumpto "Description" "gcollapse##description"}{...}
{viewerjumpto "Options" "gcollapse##options"}{...}
{title:Title}

{p2colset 5 18 23 2}{...}
{p2col :{cmd:gcollapse} {hline 2}}Efficiently
make dataset of summary statistics using C.{p_end}
{p2colreset}{...}

{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:gcollapse}
{it:clist}
{ifin}
[{cmd:,} {it:{help gcollapse##table_options:options}}]

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
{p2col :{opt mean}}means (default){p_end}
{p2col :{opt median}}medians{p_end}
{p2col :{opt p1}}1st percentile{p_end}
{p2col :{opt p2}}2nd percentile{p_end}
{p2col :{it:...}}3rd{hline 1}49th percentiles{p_end}
{p2col :{opt p50}}50th percentile (same as {cmd:median}){p_end}
{p2col :{it:...}}51st{hline 1}97th percentiles{p_end}
{p2col :{opt p98}}98th percentile{p_end}
{p2col :{opt p99}}99th percentile{p_end}
{p2col :{opt p1-99.#}}arbitrary quantiles{p_end}
{p2col :{opt sum}}sums{p_end}
{p2col :{opt count}}number of nonmissing observations{p_end}
{p2col :{opt percent}}percentage of nonmissing observations{p_end}
{p2col :{opt max}}maximums{p_end}
{p2col :{opt min}}minimums{p_end}
{p2col :{opt iqr}}interquartile range{p_end}
{p2col :{opt first}}first value{p_end}
{p2col :{opt last}}last value{p_end}
{p2col :{opt firstnm}}first nonmissing value{p_end}
{p2col :{opt lastnm}}last nonmissing value{p_end}
{p2colreset}{...}

{synoptset 15 tabbed}{...}
{marker table_options}{...}
{synopthdr}
{synoptline}
{syntab :Options}
{synopt :{opth by(varlist)}}groups over which {it:stat} is to be calculated
{p_end}
{synopt :{opt cw}}casewise deletion instead of all possible observations
{p_end}
{synopt :{opt fast}}do not preserve and restore the original dataset;
saves speed but leaves the data in an unusable state shall the
user press {hi:Break}
{p_end}
{synopt :{opt smart}}invoke {cmd:collapse} if the data is already sorted.
{p_end}
{synopt :{opt unsorted}}do not sort the final data.
Saves speed but leaves resulting collapse unsorted.
{p_end}

{synoptline}
{p2colreset}{...}
{p 4 6 2}

{marker description}{...}
{title:Description}

{pstd}
{opt gcollapse} converts the dataset in memory into a dataset of means,
sums, medians, etc. {it:clist} can refer to numeric and string variables
although string variables are only supported by a few functions (first,
last, firstnm, lastnm).

{pstd}
Weights are currently not supported.

{marker options}{...}
{title:Options}

{dlgtab:Options}

{phang}
{opth by(varlist)} specifies the groups over which the means, etc., are
to be calculated. It can contain any mix of string or numeric variables.

{phang}
{opt cw} specifies casewise deletion.  If {opt cw} is not specified, all
possible observations are used for each calculated statistic.

{phang}
{opt fast} specifies that {opt fcollapse} not restore the original dataset
should the user press {hi:Break}.

{phang}
{opt smart} calls collapse if the data is already sorted.

{phang}
{opt unsorted} does not sort the resulting data.

{marker example}{...}
{title:Example: Adding your own aggregation functions}

{pstd}
Pending...

{marker author}{...}
{title:Author}

{pstd}Mauricio Caceres{p_end}
{pstd}{browse "mailto:mauricio.caceres.bravo@gmail.com":mauricio.caceres.bravo@gmail.com }{p_end}
{pstd}{browse "https://mcaceresb.github.io":mcaceresb.github.io}{p_end}

{title:Website}

{pstd}{cmd:gcollapse} is maintained as part of {it:gtools} at {browse "https://github.com/mcaceresb/stata-gtools":github.com/mcaceresb/stata-gtools}{p_end}

{marker acknowledgment}{...}
{title:Acknowledgment}

{pstd}
This help file was based on StataCorp's own help file
for {it:collapse} and Sergio Correia's help file for {it:fcollapse}.
{p_end}

{pstd}
This project was largely inspired by Sergio Correia's {it:ftools}:
{browse "https://github.com/sergiocorreia/ftools"}.
{p_end}

