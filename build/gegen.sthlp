{smcl}
{* *! version 1.1.1 23Jan2019}{...}
{viewerdialog gegen "dialog gegen"}{...}
{vieweralsosee "[R] gegen" "mansection R gegen"}{...}
{viewerjumpto "Syntax" "gegen##syntax"}{...}
{viewerjumpto "Description" "gegen##description"}{...}
{viewerjumpto "Options" "gegen##options"}{...}
{viewerjumpto "Stored results" "gegen##results"}{...}
{title:Title}

{p2colset 5 18 23 2}{...}
{p2col :{cmd:gegen} {hline 2}}Efficient implementation of by-able egen functions using C.{p_end}
{p2colreset}{...}

{pstd}
{it:Important}: Please run {stata gtools, upgrade} to update {cmd:gtools} to
the latest stable version.

{marker syntax}{...}
{title:Syntax}

{p 8 14 2}
{cmd:gegen} {dtype} {newvar} {cmd:=} {it:fcn}({it:arguments}) {ifin}
[{it:{help gegen##weight:weight}}]
[{cmd:,}
{opt replace}
{it:fcn_options}
{help gegen##gtools_options:gtools_options}]

{synoptset 21 tabbed}{...}
{marker gtools_options}{...}
{synopthdr}
{synoptline}
{syntab:Gtools}
{synopt :{opt compress}}Try to compress strL to str#.
{p_end}
{synopt :{opt forcestrl}}Skip binary variable check and force gtools to read strL variables.
{p_end}
{synopt :{opt v:erbose}}Print info during function execution.
{p_end}
{synopt :{opt bench:mark}}Benchmark various steps of the plugin.
{p_end}
{synopt :{opt bench:marklevel(int)}}Benchmark various steps of the plugin.
{p_end}
{synopt :{opth hash:method(str)}}Hash method (default, biject, or spooky). Intended for debugging.
{p_end}
{synopt :{opth oncollision(str)}}Collision handling (fallback or error). Intended for debugging.
{p_end}
{synopt :{opth gtools_capture(str)}}The above options are captured and not passed to {opt egen} in case the requested function is not internally supported by gtools. You can pass extra arguments here if their names conflict with captured gtools options.
{p_end}
{synoptline}

{marker weight}{...}
{p 4 6 2}
{opt aweight}s, {opt fweight}s, {opt iweight}s, and {opt pweight}s are
allowed for the functions listed below and mimic {cmd:collapse} and
{cmd:gcollapse}; see {help weight} and {help collapse##weights:Weights (collapse)}.
{opt pweight}s may not be used with {opt sd}, {opt variance}, {opt cv}, {opt semean},
{opt sebinomial}, or {opt sepoisson}. {opt iweight}s may not be used
with {opt semean}, {opt sebinomial}, or {opt sepoisson}. {opt aweight}s
may not be used with {opt sebinomial} or {opt sepoisson}.{p_end}

{phang}
Functions not listed here hash the data and then call {opt egen} with
{opth by(varlist)} set to the hash, which is often faster than calling
{opt egen} directly, but not always. Natively supported functions should
always be faster, however. They are:

{phang2}
{opth group(varlist)} [{cmd:,} {opt m:issing} {opth counts(newvarname)} {opth fill(real)}]{p_end}
{pmore2}
may not be combined with {cmd:by}.  It creates one variable taking on
values 1, 2, ... for the groups formed by {it:varlist}.  {it:varlist} may
contain numeric variables, string variables, or a combination of the two.  The
order of the groups is the order in which {it:varlist} appears in the data.
However, the user can specify:

{pmore3}
[{cmd:+}|{cmd:-}]
{varname}
[[{cmd:+}|{cmd:-}]
{varname} {it:...}]

{pmore2}
And the order will be inverted for variables that have {cmd:-} prepended.
{opt missing} indicates that missing values in {it:varlist}
{bind:(either {cmd:.} or {cmd:""}}) are to be treated like any other value
when assigning groups, instead of as missing values being assigned to the
group missing.

{pmore2}
You can also specify {opt counts()} to generate a new variable with the number
of observations per group; by default all observations within a group are
filled with the count, but via {opt fill()} the user can specify the value
the variable will take after the first observation that appears within a
group. The user can also specify {opt fill(data)} to fill the first J{it:th}
observations with the count per group (in the sorted group order) or
{opt fill(group)} to keep the default behavior.

{phang2}
{opth tag(varlist)} [{cmd:,} {opt m:issing}]{p_end}
{pmore2}
may not be combined with {cmd:by}.  It tags just 1 observation in each
distinct group defined by {it:varlist}.  When all observations in a group have
the same value for a summary variable calculated for the group, it will be
sufficient to use just one value for many purposes.  The result will be 1 if
the observation is tagged and never missing, and 0 otherwise.

{pmore2}
Note values for any observations excluded by either {helpb if} or {helpb in}
are set to 0 (not missing).  Hence, if {opt tag} is the variable
produced by {cmd:egen tag =} {opt tag(varlist)}, the idiom {opt if tag}
is always safe.  {opt missing} specifies that missing values of {it:varlist}
may be included.

        {opth first|last|firstnm|lastnm(exp)}{right:(allows {help by:{bf:by} {it:varlist}{bf::}})  }
{pmore2}
creates a constant (within {it:varlist}) containing the first, last, first non-missing, and last non-missing
observation. The functions are analogous to those in {opt collapse} and {opt not} to those in {opt egenmore}.

        {opth count(exp)} {right:(allows {help by:{bf:by} {it:varlist}{bf::}})  }
{pmore2}
creates a constant (within {it:varlist}) containing the number of nonmissing
observations of {it:exp}.

        {opth nunique(exp)} {right:(allows {help by:{bf:by} {it:varlist}{bf::}})  }
{pmore2}
creates a constant (within {it:varlist}) containing the number of unique
observations of {it:exp}.

        {opth iqr(exp)}{right:(allows {help by:{bf:by} {it:varlist}{bf::}})  }
{pmore2}
creates a constant (within {it:varlist}) containing the interquartile range of
{it:exp}.  Also see {help gegen##pctile():{bf:pctile()}}.

        {opth max(exp)}{right:(allows {help by:{bf:by} {it:varlist}{bf::}})  }
{pmore2}
creates a constant (within {it:varlist}) containing the maximum value
of {it:exp}.

{marker mean()}{...}
        {opth mean(exp)}{right:(allows {help by:{bf:by} {it:varlist}{bf::}})  }
{pmore2}
creates a constant (within {it:varlist}) containing the mean of
{it:exp}.

{marker median()}{...}
        {opth median(exp)}{right:(allows {help by:{bf:by} {it:varlist}{bf::}})  }
{pmore2}
creates a constant (within {it:varlist}) containing the median of
{it:exp}.  Also see {help gegen##pctile():{bf:pctile()}}.

        {opth min(exp)}{right:(allows {help by:{bf:by} {it:varlist}{bf::}})  }
{pmore2}
creates a constant (within {it:varlist}) containing the minimum value
of {it:exp}.

        {opth range(exp)}{right:(allows {help by:{bf:by} {it:varlist}{bf::}})  }
{pmore2}
creates a constant (within {it:varlist}) containing the value range of {it:exp}.

{marker select()}{...}
        {opth select(exp)} {cmd:, n(}{it:#}|{it:-#}{cmd:)}{right:(allows {help by:{bf:by} {it:varlist}{bf::}})  }
{pmore2}
creates a constant (within {it:varlist}) containing the {it:#}th smallest
value of {it:exp}. To compute the {it:#}th largest
value, prefix a negative sign, {it:-#}. Note that without weights,
{opt n(1)} and {opt n(-1)} will give the same value as {opt min} and
{opt max}, respectively.

{marker pctile()}{...}
        {opth pctile(exp)} [{cmd:, p(}{it:#}{cmd:)}]{right:(allows {help by:{bf:by} {it:varlist}{bf::}})  }
{pmore2}
creates a constant (within {it:varlist}) containing the {it:#}th percentile
of {it:exp}.  If {opt p(#)} is not specified, 50 is assumed, meaning medians.
Also see {help gegen##median():{bf:median()}}.

        {opth sd(exp)}{right:(allows {help by:{bf:by} {it:varlist}{bf::}})  }
{pmore2}
creates a constant (within {it:varlist}) containing the standard
deviation of {it:exp}.  Also see {help gegen##mean():{bf:mean()}}.

        {opth variance(exp)}{right:(allows {help by:{bf:by} {it:varlist}{bf::}})  }
{pmore2}
creates a constant (within {it:varlist}) containing the variance
of {it:exp}.  Also see {help gegen##sd():{bf:sd()}}.

        {opth cv(exp)}{right:(allows {help by:{bf:by} {it:varlist}{bf::}})  }
{pmore2}
creates a constant (within {it:varlist}) containing the coefficient
of variation of {it:exp}; {opt sd/mean}.  Also see {help gegen##sd():{bf:sd()}} and
{help gegen##mean():{bf:mean()}}.

        {opth percent(exp)}{right:(allows {help by:{bf:by} {it:varlist}{bf::}})  }
{pmore2}
creates a constant (within {it:varlist}) containing the percent of
non-missing observations of {it:exp} in the group relative to the sample.

        {opth semean(exp)}{right:(allows {help by:{bf:by} {it:varlist}{bf::}})  }
{pmore2}
creates a constant (within {it:varlist}) containing the standard
error of the mean of {it:exp}, (sd/sqrt(n)).

        {opth sebinomial(exp)}{right:(allows {help by:{bf:by} {it:varlist}{bf::}})  }
{pmore2}
creates a constant (within {it:varlist}) containing the standard
error of the mean of {it:exp}, binomial (sqrt(p(1-p)/n)) (missing if
{it:exp} not 0, 1).

        {opth sepoisson(exp)}{right:(allows {help by:{bf:by} {it:varlist}{bf::}})  }
{pmore2}
creates a constant (within {it:varlist}) containing the standard
error of the mean of {it:exp}, Poisson (sqrt(mean / n)) (missing if
{it:exp} is negative; result rounded to nearest integer)

        {opth skewness(exp)}{right:(allows {help by:{bf:by} {it:varlist}{bf::}})  }
{pmore2}
creates a constant (within {it:varlist}) containing the skewness of {it:exp}

        {opth kurtosis(exp)}{right:(allows {help by:{bf:by} {it:varlist}{bf::}})  }
{pmore2}
creates a constant (within {it:varlist}) containing the kurtosis of {it:exp}

        {opth sum(exp)} [{cmd:,} {opt m:issing}] {right:(allows {help by:{bf:by} {it:varlist}{bf::}})  }
        {opth total(exp)} [{cmd:,} {opt m:issing}] {right:(allows {help by:{bf:by} {it:varlist}{bf::}})  }
{pmore2}
creates a constant (within {it:varlist}) containing the sum of {it:exp}
treating missing as 0.  If {opt missing} is specified and all values in
{it:exp} are missing, {it:newvar} is set to missing.  Also see
{help gegen##mean():{bf:mean()}}.

{marker description}{...}
{title:Description}

{pstd}
{cmd:gegen} creates {newvar} of the optionally specified storage type
equal to {it:fcn}{cmd:(}{it:arguments}{cmd:)}. Here {it:fcn}{cmd:()} is either
one of the internally supported commands above or a by-able function written
for {cmd:egen}, as documented above. Only {cmd:egen} functions or internally
supported functions may be used with {cmd:egen}.  If you want to generate
multiple summary statistics from a single variable it may be faster to use
{opt gcollapse} with the {opt merge} option.

{pstd}
Depending on {it:fcn}{cmd:()}, {it:arguments}, if present, refers to an
expression, {varlist}, or a {it:{help numlist}}, and the {it:options}
are similarly {it:fcn} dependent.

{marker memory}{...}
{title:Out of memory}

{pstd}
(See also Stata's own discussion: {help memory:help memory}.)

{pstd}
There are many reasons for why an OS may run out of memory. The best-case
scenario is that your system is running some other memory-intensive program.
This is specially likely if you are running your program on a server, where
memory is shared across all users. In this case, you should attempt to re-run
{it:gegen} once other memory-intensive programs finish.

{pstd}
If no memory-intensive programs were running concurrently, the second best-case
scenario is that your user has a memory cap that your programs can use. Again,
this is specially likely on a server, and even more likely on a computing grid.
If you are on a grid, see if you can increase the amount of memory your programs
can use (there is typically a setting for this). If your cap was set by a system
administrator, consider contacting them and asking for a higher memory cap.

{pstd}
If you have no memory cap imposed on your user, the likely scenario is that
your system cannot allocate enough memory for {it:gegen}. At this point you
have two options: One option is to try {it:fegen} or {it:egen}, which are
slower but using either should require a trivial one-letter change to the
code; another option is to re-write egen the data in segments (the easiest
way to do this would be to egen a portion of all rows at a time and
perform a series of append statements at the end.)

If you have no memory cap imposed on your user, the likely scenario is
that your system cannot allocate enough memory for {it:gegen}. At this
point you can try {it:fegen} or {it:egen}, which are slower but using
either should require a trivial one-letter change to the code.  Note,
however, that replacing {it:gegen} with {it:fegen} or plain {it:egen}
is not guaranteed to use less memory. I have not benchmarked memory use
very extensively, so {it:gegen} might use less memory (I doubt that is
the case in most scenarios, but it is possible).

{pstd}
You can also try to process the data by segments. However, if you are
doing group operations you would need to first sort the data and make
sure you are not splitting groups apart.

{marker example}{...}
{title:Examples}

{pstd}
See the
{browse "http://gtools.readthedocs.io/en/latest/usage/gegen/index.html#examples":online documentation}
for examples.


{marker author}{...}
{title:Author}

{pstd}Mauricio Caceres Bravo{p_end}
{pstd}{browse "mailto:mauricio.caceres.bravo@gmail.com":mauricio.caceres.bravo@gmail.com }{p_end}
{pstd}{browse "https://mcaceresb.github.io":mcaceresb.github.io}{p_end}

{title:Website}

{pstd}{cmd:gegen} is maintained as part of {manhelp gtools R:gtools} at {browse "https://github.com/mcaceresb/stata-gtools":github.com/mcaceresb/stata-gtools}{p_end}

{marker acknowledgment}{...}
{title:Acknowledgment}

{pstd}
This help file was based on StataCorp's own help file
for {it:egen}.
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
{help gcollapse},
{help gtools};
{help fegen} (if installed),
{help fcollapse} (if installed),
{help ftools} (if installed)
p_end}

