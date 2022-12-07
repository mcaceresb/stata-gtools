{smcl}
{* *! version 1.2.1 30Jan2020}{...}
{viewerdialog gcollapse "dialog gcollapse"}{...}
{vieweralsosee "[R] gcollapse" "mansection R gcollapse"}{...}
{viewerjumpto "Syntax" "gcollapse##syntax"}{...}
{viewerjumpto "Description" "gcollapse##description"}{...}
{viewerjumpto "Options" "gcollapse##options"}{...}
{viewerjumpto "Stored results" "gegen##results"}{...}
{title:Title}

{p2colset 5 18 23 2}{...}
{p2col :{cmd:gcollapse} {hline 2}}Efficiently
make dataset of summary statistics using C.{p_end}
{p2colreset}{...}

{pstd}
{it:Important}: Please run {stata gtools, upgrade} to update {cmd:gtools} to
the latest stable version.

{pstd}
{it:Note}: Stata 17+, MP version, introduced significant speed improvements
to the native {cmd:collapse} command, specially with many cores. Depending
on the collapse, it can be up to twice as fast than {cmd:gcollapse}; however,
it remained slower for some use cases. YMMV.

{marker syntax}{...}
{title:Syntax}

{phang}
This is a fast option to Stata's {opt collapse} (9-300 times faster
in IC and 4-120 times faster in MP), with several additions.

{p 8 17 2}
{cmd:gcollapse}
{it:clist}
{ifin}
[{it:{help gcollapse##weight:weight}}]
[{cmd:,}
{it:{help gcollapse##table_options:options}}]

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
{p2col :{opt geomean}}geometric mean (missing if var has any negative values){p_end}
{p2col :{opt count}}number of nonmissing observations{p_end}
{p2col :{opt nmissing}}number of missing observations{p_end}
{p2col :{opt percent}}percentage of nonmissing observations{p_end}
{p2col :{opt nunique}}number of unique elements{p_end}
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

{synoptset 18 tabbed}{...}
{marker table_options}{...}
{synopthdr}
{synoptline}
{syntab :Options}
{synopt :{opth by(varlist)}}groups over which {it:stat} is to be calculated. Prepend "-" to invert final sort order.
{p_end}
{synopt :{opt cw}}Drop ocase-wise bservations where sources are missing.
{p_end}
{synopt :{opt fast}}do not preserve and restore the original dataset;
saves speed but leaves the data in an unusable state shall the
user press {hi:Break}
{p_end}

{syntab:Extras}
{synopt :{opth rawstat(varlist)}}Sequence of target names for which to ignore weights.
{p_end}
{synopt :{opt merge}}Merge statistics back to original data, replacing if applicable.
{p_end}
{synopt :{opt wild:parse}}Allow rename-style syntax in target naming
{p_end}
{synopt :{opt replace}}Allow replacing existing variables with output with {opt merge}.
{p_end}
{synopt :{opth freq(varname)}}Include frequency count with observations per group in {opt freq}.
{p_end}
{synopt :{opt labelf:ormat}}Custom label engine: {bf:(#stat#) #sourcelabel#} is the default.
{p_end}
{synopt :{opth labelp:rogram(str)}}Program to parse {opt labelformat} (see examples).
{p_end}
{synopt :{opt unsorted}}Do not sort resulting dataset. Saves speed.
{p_end}

{syntab:Switches}
{synopt :{opt forceio}}Use disk temp drive for writing/reading collapsed data.
{p_end}
{synopt :{opt forcemem}}Use memory for writing/reading collapsed data.
{p_end}
{synopt :{opt double}}Generate all targets as doubles.
{p_end}
{synopt :{opt sumcheck}}Check whether byte, int, or long sum will overflow.
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
are allowed and mimic {cmd:collapse}; see {help weight} and
{help collapse##weights:Weights (collapse)}. {opt pweight}s may not be used
with {opt sd}, {opt variance}, {opt cv}, {opt semean}, {opt sebinomial}, or {opt sepoisson}. 
{opt iweight}s may not be used with {opt semean}, {opt sebinomial}, or 
{opt sepoisson}. {opt aweight}s may not be used with {opt sebinomial} or
{opt sepoisson}.{p_end}

{marker description}{...}
{title:Description}

{pstd}
{opt gcollapse} converts the dataset in memory into a dataset of means,
sums, medians, etc. {it:clist} can refer only to numeric variables.

{pstd}
first, last, firstnm, lastnm for string variables are not supported.

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
{opt fast} specifies that {opt gcollapse} not restore the original dataset
should the user press {hi:Break}.

{dlgtab:Extras}

{phang}
{opth rawstat(varlist)}Sequence of target names for which to ignore
weights, except observations with a weight of zero or missing, which are
excluded. This is a generalization of {opt rawsum}, but it is specified
for each individual target (if no target is specified, the source
variable name is what we call target).

{phang}
{opt merge} merges the collapsed data back to the original data set.
Note that if you want to replace the source variable(s) then you need
to specify {opt replace}.

{phang}
{opt wildparse} specifies that the function call should be parsed
assuming targets are named using rename-stle syntax. For example,
{cmd:gcollapse (sum) s_x* = x*, wildparse}

{phang}
{opt replace} Replace allows replacing existing variables with {opt merge}.

{phang}
{opth freq(varname)} stores the group frequency count in {opt freq}. It
differs from count because it merely stores the number of occurrences of
the group in the data, rather than the non-missing count. Hence it is
equivalent to summing a dummy variable equal to 1 everywhere.

{phang}
{opth freq(varname)} Specifies that the row count of each group be stored
in {opt freq} after the collapse.

{phang}
{opth labelformat(str)} Specifies the label format of the output. #stat#
is replaced with the statistic: #Stat# for titlecase, #STAT#
for uppercase, #stat:pretty# for a custom replacement; #sourcelabel#
for the source label and #sourcelabel:start:nchars# to extract a substring
from the source label. The default is (#stat#) #sourcelabel#. #stat#
palceholders in the source label are also replaced.

{phang}
{opth labelprogram(str)} Specifies the program to use with #stat:pretty#.
This is an {opt rclass} that must set {opt prettystat} as a return value. The
program must specify a value for each summary stat or return #default# to
use the default engine. The programm is passed the requested stat by {opt gcollapse}.

{phang}
{opt unsorted} Do not sort resulting data set. Saves speed.

{dlgtab:Switches}

{phang}
{opt forceio} By default, when there are more than 3 additional targets
(i.e. the number of targets is greater than the number of source
variables plus 3) the function tries to be smart about whether adding
empty variables in Stata before the collapse is faster or slower than
collapsing the data to disk and reading them back after keeping only the
first J observations (assuming J is the number of groups). For J small
relative to N, collapsing to disk will be faster. This check involves
some overhead, however, so if J is known to be small {opt forceio} will
be faster.

{phang}
{opt forcemem} The opposite of {opt forceio}. The check for whether to use
memory or disk check involves some overhead, so if J is known to
be large {opt forcemem} will be faster.

{phang}
{opt double} stores data in double precision.

{phang}
{opt sumcheck} Check whether byte, int, or long sum will overflow.  By
default sum targets are double; in this case, sum targets check the
smallest integer type that will be suitable and only assigns a double if
the sum would overflow.

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

{marker memory}{...}
{title:Out of memory}

{pstd}
(See also Stata's own discussion in {help memory:help memory}.)

{pstd}
There are many reasons for why an OS may run out of memory. The best-case
scenario is that your system is running some other memory-intensive program.
This is specially likely if you are running your program on a server, where
memory is shared across all users. In this case, you should attempt to re-run
{it:gcollapse} once other memory-intensive programs finish.

{pstd}
If no memory-intensive programs were running concurrently, the second best-case
scenario is that your user has a memory cap that your programs can use. Again,
this is specially likely on a server, and even more likely on a computing grid.
If you are on a grid, see if you can increase the amount of memory your programs
can use (there is typically a setting for this). If your cap was set by a system
administrator, consider contacting them and asking for a higher memory cap.

{pstd}
If you have no memory cap imposed on your user, the likely scenario is that
your system cannot allocate enough memory for {it:gcollapse}. At this point
you have two options: One option is to try {it:fcollapse} or {it:collapse},
which are slower but using either should require a trivial one-letter change
to the code; another option is to re-write the code to collapse the data in
segments (the easiest way to do this would be to collapse a portion of all
variables at a time and perform a series of 1:1 merges at the end).

{pstd}
Replacing {it:gcollapse} with {it:fcollapse} or plain {it:collapse} is an
option because {it:gcollapse} often uses more memory. This is a consequence
of Stata's inability to create variables via C plugins. This forces
{it:gcollapse} to create variables before collapsing, meaning that if there
are {it:J} groups and {it:N} observations, {it:gcollapse} uses {it:N} - {it:J}
more rows than the ideal collapse program, per variable.

{pstd}
{it:gcollapse} was written with this limitation in mind and tries to save
memory in various ways (for example, if {it:J} is small relative to {it:N},
gcollapse will use free disk space instead of memory, which not only saves
memory but is also much faster). Nevertheless, it is possible that your system
will allocate enough memory for {it:fcollapse} or {it:collapse} in situations
where it cannot allocate enough memory for {it:gcollapse}.

{marker example}{...}
{title:Examples}

{pstd}
See {help collapse##examples} or the
{browse "http://gtools.readthedocs.io/en/latest/usage/gcollapse/index.html#examples":online documentation}
for examples.

{marker results}{...}
{title:Stored results}

{pstd}
{cmd:gcollapse} stores the following in {cmd:r()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:r(N)   }} number of non-missing observations {p_end}
{synopt:{cmd:r(J)   }} number of groups {p_end}
{synopt:{cmd:r(minJ)}} largest group size {p_end}
{synopt:{cmd:r(maxJ)}} smallest group size {p_end}
{p2colreset}{...}


{marker author}{...}
{title:Author}

{pstd}Mauricio Caceres Bravo{p_end}
{pstd}{browse "mailto:mauricio.caceres.bravo@gmail.com":mauricio.caceres.bravo@gmail.com }{p_end}
{pstd}{browse "https://mcaceresb.github.io":mcaceresb.github.io}{p_end}

{title:Website}

{pstd}{cmd:gcollapse} is maintained as part of {manhelp gtools R:gtools} at {browse "https://github.com/mcaceresb/stata-gtools":github.com/mcaceresb/stata-gtools}{p_end}

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

{pstd}
The OSX version of gtools was implemented with invaluable help from @fbelotti;
see {browse "https://github.com/mcaceresb/stata-gtools/issues/11"}.
{p_end}

{title:Also see}

{p 4 13 2}
help for 
{help gcontract}, 
{help gtoplevelsof}, 
{help gtools};
{help fcollapse} (if installed), 
{help ftools} (if installed)

