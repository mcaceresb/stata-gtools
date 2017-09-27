{smcl}
{* *! version 0.7.1 27Sep2017}{...}
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

{phang}
{it:Note for Windows users}: Please run {opt gtools, dependencies}
before using any of the programs provided by gtools.

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
{p2col :{opt sd}}standard deviation{p_end}
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
{synopt :{opt verbose}}verbose printing (for debugging).
{p_end}
{synopt :{opt benchmark}}print performance time info for each step.
{p_end}
{synopt :{opt smart}}pre-index the data in Stata if it's already sorted.
{p_end}
{synopt :{opt merge}}merge collapsed results back to oroginal data.
{p_end}
{synopt :{opt forceio}}force using disk instead of memory for the collapsed results.
{p_end}
{synopt :{opt forcemem}}force using memory instead of disk for the collapsed results.
{p_end}
{synopt :{opt double}}store data in double precision.
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
{opt fast} specifies that {opt gcollapse} not restore the original dataset
should the user press {hi:Break}.

{phang}
{opt smart} pre-indexes the data in Stata if it is already sorted. If the
meta-data indicates the data is already sorted by the goruping variables,
then we can greate a tag for each group and use that to construct an index
in C much faster than via hashing.

{phang}
{opt verbose} prints some useful debugging info to the console.

{phang}
{opt benchmark} prints how long in seconds various parts of the program
take to execute.

{phang}
{opt merge} merges the collapsed data back to the original data set.
Note that if you want to keep the source variable(s) then you {it:need}
to assign a new name to it for each summary statistic. Otherwise it will
be overwritten.

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
memory or disk check involvesforceio some overhead, so if J is known to
be large {opt forcemem} will be faster.

{phang}
{opt double} stores data in double precision.

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
to the code; another option is to re-write collapse the data in segments (the
easiest way to do this would be to collapse a portion of all variables at a
time and perform a series of 1:1 merges at the end.)

{pstd}
Replacing {it:gcollapse} with {it:fcollapse} or plain {it:collapse} is
an option because {it:gcollapse} uses more memory. This is a consequence
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
