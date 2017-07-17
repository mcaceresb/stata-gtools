{smcl}
{* *! version 0.6.6 17Jul2017}{...}
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
{opth group(varlist)} [{cmd:,} {opt m:issing}
{opt l:abel} {opt lname}{cmd:(}{it:name}{cmd:)}
{opt t:runcate}{cmd:(}{it:num}{cmd:)}]{p_end}
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

{pstd}
If your system runs out of memory, it will start to use its swap space (*nix)
or its pagefile (Windows). If it then runs out of swap space or if the
pagefile size is not large enough, it will not be able to allocate any more
memory. If the program does not take this into account, it will attempt to use
more memory than is actually physically available and crash.

{pstd}
Stata is written so that when the system cannot allocate any more memory, it
will not crash. I do not know what it does, exactly, but I suspect it falls
back on free disk space by using temporary files. The current iteration of
{it:gegen}, however, is not robust enough to fall back on free disk space when
it can no longer allocate memory. Instead, it will simply exit with error.

{pstd}
If this happens, the user should fall back on {it:fegen}, if available,
or plain {it:egen}. Feel free to pester me about building a fallback
directly into {it:gegen} (file an issue on {browse "https://github.com/mcaceresb/stata-gtools/issues/new":the project's github page}),
but I think other features are more important at the moment (as of v0.6.5).

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
