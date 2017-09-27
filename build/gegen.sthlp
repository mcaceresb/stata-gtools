{smcl}
{* *! version 0.7.1 27Sep2017}{...}
{viewerdialog gegen "dialog gegen"}{...}
{vieweralsosee "[R] gegen" "mansection R gegen"}{...}
{viewerjumpto "Syntax" "gegen##syntax"}{...}
{viewerjumpto "Description" "gegen##description"}{...}
{viewerjumpto "Options" "gegen##options"}{...}
{title:Title}

{p2colset 5 18 23 2}{...}
{p2col :{cmd:gegen} {hline 2}}Efficient implementation of by-able egen functions using C.{p_end}
{p2colreset}{...}

{marker syntax}{...}
{title:Syntax}

{phang}
{it:Note for Windows users}: Please run {opt gtools, dependencies}
before using any of the programs provided by gtools.

{p 8 14 2}
{cmd:gegen} {dtype} {newvar} {cmd:=} {it:fcn}({it:arguments}) {ifin} 
[{cmd:,} {it:options}]

{phang}
Unlike {it:egen}, {cmd:by} is required in this case, except for {opt tag}
or {opt group}, as noted below. The available functions are:

        {opth count(exp)} {right:(allows {help by:{bf:by} {it:varlist}{bf::}})  }
{pmore2}
creates a constant (within {it:varlist}) containing the number of nonmissing
observations of {it:exp}.

{phang2}
{opth group(varlist)} [{cmd:,} {opt m:issing}]{p_end}
{pmore2}
may not be combined with {cmd:by}.  It creates one variable taking on
values 1, 2, ... for the groups formed by {it:varlist}.  {it:varlist} may
contain numeric variables, string variables, or a combination of the two.  The
order of the groups is the order in which {it:varlist} appears in the data.  {opt missing}
indicates that missing values in {it:varlist}
{bind:(either {cmd:.} or {cmd:""}}) are to be treated like any other value
when assigning groups, instead of as missing values being assigned to the
group missing. 

        {opth iqr(exp)}{right:(allows {help by:{bf:by} {it:varlist}{bf::}})  }
{pmore2}
creates a constant (within {it:varlist}) containing the interquartile range of
{it:exp}.  Also see {help egen##pctile():{bf:pctile()}}.

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
{it:exp}.  Also see {help egen##pctile():{bf:pctile()}}.

        {opth min(exp)}{right:(allows {help by:{bf:by} {it:varlist}{bf::}})  }
{pmore2}
creates a constant (within {it:varlist}) containing the minimum value
of {it:exp}.

{marker pctile()}{...}
        {opth pctile(exp)} [{cmd:, p(}{it:#}{cmd:)}]{right:(allows {help by:{bf:by} {it:varlist}{bf::}})  }
{pmore2}
creates a constant (within {it:varlist}) containing the {it:#}th percentile
of {it:exp}.  If {opt p(#)} is not specified, 50 is assumed, meaning medians.
Also see {help egen##median():{bf:median()}}.

        {opth sd(exp)}{right:(allows {help by:{bf:by} {it:varlist}{bf::}})  }
{pmore2}
creates a constant (within {it:varlist}) containing the standard
deviation of {it:exp}.  Also see {help egen##mean():{bf:mean()}}.

{phang2}
{opth tag(varlist)} [{cmd:,} {opt m:issing}]{p_end}
{pmore2}
may not be combined with {cmd:by}.  It tags just 1 observation in each
distinct group defined by {it:varlist}.  When all observations in a group have
the same value for a summary variable calculated for the group, it will be
sufficient to use just one value for many purposes.  The result will be 1 if
the observation is tagged and never missing, and 0 otherwise.  Values
for any observations excluded by either {helpb if} or {helpb in}
are set to 0 (not missing).  Hence, if {opt tag} is the variable
produced by {cmd:egen tag =} {opt tag(varlist)}, the idiom {opt if tag}
is always safe.  {opt missing} specifies that missing values of {it:varlist}
may be included.

        {opth total(exp)} [{cmd:,} {opt m:issing}] {right:(allows {help by:{bf:by} {it:varlist}{bf::}})  }
{pmore2}
creates a constant (within {it:varlist}) containing the sum of {it:exp}
treating missing as 0.  If {opt missing} is specified and all values in
{it:exp} are missing, {it:newvar} is set to missing.  Also see
{help egen##mean():{bf:mean()}}.

{marker description}{...}
{title:Description}

{pstd}
{cmd:egen} creates {newvar} of the optionally specified storage type equal
to {it:fcn}{cmd:(}{it:arguments}{cmd:)}. Here {it:fcn}{cmd:()} is a by-able
function specifically written for {cmd:egen}, as documented above. Only
{cmd:egen} functions may be used with {cmd:egen}. Note that if you want
to generate multiple summary statistics from a single variable it may be
faster to use {opt gcollapse} with the {opt merge} option.

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

{pstd}
Replacing {it:gegen} with {it:fegen} or plain {it:egen} is not guaranteed to
work. I have not benchmarked memory use very extensively, but it is possible
that the latter use less memory. If all fail, you will have to perform the
task on segments of the data.

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

{pstd}{cmd:gegen} is maintained as part of {it:gtools} at {browse "https://github.com/mcaceresb/stata-gtools":github.com/mcaceresb/stata-gtools}{p_end}

{marker acknowledgment}{...}
{title:Acknowledgment}

{pstd}
This project was largely inspired by Sergio Correia's {it:ftools}:
{browse "https://github.com/sergiocorreia/ftools":github.com/sergiocorreia/ftools}.
{p_end}
