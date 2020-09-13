{smcl}
{* *! version 0.2.1  30Jan2020}{...}
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

{p2colset 9 28 30 2}{...}
{p2col :{opt demean}}subtract the mean (default){p_end}
{p2col :{opt demedian}}subtract the median{p_end}
{p2col :{opt normalize}}(x - mean) / sd{p_end}
{p2col :{opt standardize}}same as {opt normalize}{p_end}
{p2col :{opt moving stat [# #]}}moving statistic {it:stat}; # specify the relative bounds ({help gstats transform##moving_format:see below}){p_end}
{p2col :{opt range stat [...]}}range statistic {it:stat} for observations within specified interval ({help gstats transform##interval_format:see below}){p_end}
{p2col :{opt cumsum [+/- [varname]]}}cumulative sum, optionally ascending (+) or descending (-) (optionally +/- by varname){p_end}
{p2col :{opt shift [[+/-]#]}}lags (-#) and leads (+#); unsigned numbers are positive (i.e. leads){p_end}
{p2col :{opt rank}}rank observations; use option {opt ties()} to specify how ties are handled{p_end}
{p2colreset}{...}

{p 4 4 2} Some of the above transformations allow specifying various
options as part of their name. This is done to allow the user to request
various versions of the same transformation. However, this is not
required.  The user can specify a global option that will be used for
all the corresponding transformations:

{p2colset 9 28 30 2}{...}
{p2col :{opt moving stat}}{opt window()}{p_end}
{p2col :{opt range stat}}{opt interval()}{p_end}
{p2col :{opt cumsum}}{opt cumby()}{p_end}
{p2col :{opt shift}}{opt shiftby()}{p_end}
{p2colreset}{...}

{p 4 4 2} Note {cmd:gstats moving} and {cmd:gstats range} are aliases
for {cmd:gstats transform}. In this case all the requested statistics
are assumed to be moving or range statistics, respectively. Finally,
{cmd:moving} and {bf:range} may be combined with any one of the
folloing:{p_end}

{p2colset 9 22 24 2}{...}
{p2col :{opt mean}}means (default){p_end}
{p2col :{opt geomean}}geometric mean (missing if var has any negative values){p_end}
{p2col :{opt count}}number of nonmissing observations{p_end}
{p2col :{opt nmissing}}number of missing observations{p_end}
{p2col :{opt sum}}sums{p_end}
{p2col :{opt rawsum}}sums, ignoring optionally specified weights ({bf:note}: zero-weighted obs are still excluded){p_end}
{p2col :{opt nansum}}sum; returns . instead of 0 if all entries are missing{p_end}
{p2col :{opt rawnansum}}rawsum; returns . instead of 0 if all entries are missing{p_end}
{p2col :{opt median}}medians (same as {opt p50}){p_end}
{p2col :{opt p#.#}}arbitrary quantiles{p_end}
{p2col :{opt p1}}1st percentile{p_end}
{p2col :{opt p2}}2nd percentile{p_end}
{p2col :{it:...}}3rd{hline 1}49th percentiles{p_end}
{p2col :{opt p50}}50th percentile (same as {cmd:median}){p_end}
{p2col :{it:...}}51st{hline 1}97th percentiles{p_end}
{p2col :{opt p98}}98th percentile{p_end}
{p2col :{opt p99}}99th percentile{p_end}
{p2col :{opt iqr}}interquartile range{p_end}
{p2col :{opt sd}}standard deviation{p_end}
{p2col :{opt var:iance}}variance{p_end}
{p2col :{opt cv}}coefficient of variation ({cmd:sd/mean}){p_end}
{p2col :{opt select#}}#th smallest{p_end}
{p2col :{opt select-#}}#th largest{p_end}
{p2col :{opt rawselect#}}#th smallest, ignoring weights{p_end}
{p2col :{opt rawselect-#}}#th largest, ignoring weights{p_end}
{p2col :{opt max}}maximums{p_end}
{p2col :{opt min}}minimums{p_end}
{p2col :{opt range}}range = {opt max} - {opt min}{p_end}
{p2col :{opt first}}first value{p_end}
{p2col :{opt last}}last value{p_end}
{p2col :{opt firstnm}}first nonmissing value{p_end}
{p2col :{opt lastnm}}last nonmissing value{p_end}
{p2col :{opt sem:ean}}standard error of the mean ({cmd:sd/sqrt(n)}){p_end}
{p2col :{opt seb:inomial}}standard error of the mean, binomial ({cmd:sqrt(p(1-p)/n)}) (missing if source not 0, 1){p_end}
{p2col :{opt sep:oisson}}standard error of the mean, Poisson ({cmd:sqrt(mean / n)}) (result rounded to nearest integer){p_end}
{p2col :{opt skewness}}Skewness{p_end}
{p2col :{opt kurtosis}}Kurtosis{p_end}
{p2col :{opt gini}}Gini coefficient (negative truncated to 0){p_end}
{p2col :{opt gini dropneg}}Gini coefficient (negative values dropped){p_end}
{p2col :{opt gini keepneg}}Gini coefficient (negative values kept; the user is responsible for the interpretation of the Gini in this case){p_end}
{p2colreset}{...}

{marker interval_format}{...}
{dlgtab:Interval format}

{pstd}
{cmd:range stat} must specify an interval or use the {opt interval(...)}
option. The interval must be of the form

{p 8 17 2}
{bf:#}[{it:statlow}] {bf:#}[{it:stathigh}] [{it:var}]

{pstd}
This computes, for each observation {it:i}, the summary statistic {it:stat}
among all observations {it:j} of the source variable such that

{p 8 17 2}
var[i] + # * statlow(var) <= var[j] <= var[i] + # * stathigh(var)

{pstd}
if {it:var} is not specified, it is taken to be the source variable itself.
{it:statlow} and {it:stathigh} are summary statistics computed based on
{it:every} value of {it:var}. If they are not specified, then {bf:#} is used by
itself to construct the bounds, but {bf:#} may be missing ({bf:.}) to mean no
upper or lower bound. For example, given some variable {it:x} with {it:N} observations,
we have{p_end}

            Input      ->  Meaning
            {hline 55}
            -2 2 time  ->  j: time[i] - 2 <= time[j] <= time[i] + 2
                           i.e. {it:stat} within a 2-period time window

            -sd sd     ->  j: x[i] - sd(x) <= x[j] <= x[i] + sd(x)
                           i.e. {it:stat} for obs within a standard dev

{marker moving_format}{...}
{dlgtab:Moving window format}

{pstd}{bf:moving stat} must specify a relative range or use the {opt window(# #)}
option. The relative range uses a window defined by the {it:observations}. This
would be equivalent to computing time series rolling window statistics
using the time variable set to {it:_n}. For example, given some variable
{it:x} with {it:N} observations, we have{p_end}

            Input  ->  Range
            {hline 31}
            -3  3  ->  x[i - 3] to x[i + 3]
            -3  .  ->  x[i - 3] to x[N]
             .  3  ->  x[1]     to x[i + 3]
            -3 -1  ->  x[i - 3] to x[i - 1]
            -3  0  ->  x[i - 3] to x[i]
             5 10  ->  x[i + 5] to x[i + 10]

{pstd}and so on. If the observation is outside of the admisible range
(e.g. {it:-10 10} but {it:i = 5}) the output is set to missing. If you
don't specify a range in ({it:moving stat}) then the range in {opt:window(# #)}
is used.

{marker options}{...}
{title:Options}

{synoptset 23 tabbed}{...}
{marker table_options}{...}
{synopthdr}
{synoptline}
{syntab :Common Options}
{synopt:{opth by(varlist)}}Group statistics by variable.
{p_end}
{synopt:{opt replace}}Allow replacing existing variables.
{p_end}
{synopt :{opt wild:parse}}Allow rename-style syntax in target naming.
{p_end}
{synopt:{opt labelf:ormat}}Custom label engine: {bf:(#stat#) #sourcelabel#} is the default.
{p_end}
{synopt:{opth labelp:rogram(str)}}Program to parse {opt labelformat} (see examples).
{p_end}
{synopt :{opth auto:rename}[{cmd:(}{str}{cmd:)}]}Automatically name targets based on requested stats. Default is {it:#source#_#stat#}.
{p_end}
{synopt:{opt nogreedy}}Use slower but memory-efficient (non-greedy) algorithm.
{p_end}
{synopt:{opth type:s(str)}}Override variable types for targets ({bf:use with caution}).
{p_end}

{syntab :Command Options}
{synopt:{opt window(lower upper)}}With {it:moving stat}. Relative observation range for moving statistics (if not specified in call). E.g. {opt window(-3 1)} means from 3 lag to 1 lead. {opt window(. #)} and {opt window(# .)} mean from the start and through the end.
{p_end}
{synopt:{opt interval(#[stat] #[stat] [var])}}With {it:range stat}. Interval for range statistics that don't specify their own interval.
{p_end}
{synopt:{opt cumby([+/- [varname]])}}With {it:cumsum}. Sort options for cumsum variables that don't specify their own.
{p_end}
{synopt:{opt shiftby([+/-]#)}}With {it:shift}. Lag or lead when to use {bf:shift} is requested without specifying a number.
{p_end}
{synopt:{opt ties(str)}}With {it:rank}. How to break ties for {opt rank}. {opt d:efault} assigns the average rank; {opt u:nique} breaks ties arbitrarily; {opt stableunique} breaks ties using the order values appear in the data; {opt f:ield} counts the number of values greater than; {opt t:rack} counts the number of values less than.
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
{cmd:gegen}. Further, note that while not every function will use weights
in their computations (e.g. {it:shift} ignores weights in the actual
transformation), if weights are specified they will be used to flag
acceptable observations (i.e. missing, zero, and, except for {opt iweights},
negative observations get excluded).

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
