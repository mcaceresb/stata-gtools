{smcl}
{* *! version 0.1.0  14Mar2022}{...}
{viewerdialog gstats_hdfe "dialog gstats_hdfe"}{...}
{vieweralsosee "[R] gstats_hdfe" "mansection R gstats_hdfe"}{...}
{viewerjumpto "Syntax" "gstats_hdfe##syntax"}{...}
{viewerjumpto "Description" "gstats_hdfe##description"}{...}
{viewerjumpto "Statistics" "gstats_hdfe##statistics"}{...}
{title:Title}

{p2colset 5 20 23 2}{...}
{p2col :{cmd:gstats hdfe} {hline 2}} Absorb HDFE (residualize variables) {p_end}
{p2colreset}{...}

{pstd}
{it:Important}: Please run {stata gtools, upgrade} to update {cmd:gtools} to
the latest stable version.

{pstd}
{it:Warning}: {opt gstats hdfe} is in beta; see {help gstats hdfe##missing:missing features}.
(To enable beta, define {cmd:global GTOOLS_BETA = 1}.)

{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:gstats hdfe}
{varlist}
{ifin}
[{it:{help gstats hdfe##weight:weight}}]
[
{cmd:,} {opth absorb(varlist)}
{c -(}{opth gen(newvarlist)}{c |}{opt prefix(str)}{c |}{cmd:replace}{c )-}
{it:{help gstats hdfe##table_options:options}}
]

{pstd} If none of {cmd:gen()}, {cmd:prefix()}, or {cmd:replace} are
specified then {it:target}{cmd:=}{it:source} syntax must be supplied
instead of {varlist}:

{p 8 17 2}
{it:target_var}{cmd:=}{varname}
    [{it:target_var}{cmd:=}{varname} {it:...}]

{pstd}
{cmd:gstats hdfe} (alias {cmd:gstats residualize}) provides a fast way of 
absorbing high-dimensional fixed effects (HDFE). It saves the number of levels
in each absorbed variable, accepts weights, and optionally takes {opt by()}
as an argument (in this case ancillary information is not saved by
default and must be accessed via {opt mata()}). Missing values in the
source and absorb variables are skipped row-size (the latter can be
optionally retained via {opt absorbmissing}).

{synoptset 23 tabbed}{...}
{marker table_options}{...}
{synopthdr}
{synoptline}
{syntab :Specify Targets}
{synopt:{opth pre:fix(str)}}Generate all variables with prefix (e.g. residualized {it:x} saved to {it:prefix_x}, etc).
{p_end}
{synopt:{opth gen:erate(newvarlist)}}List of targets; must specify one per source.
{p_end}
{synopt:{opt replace}}Replace variables as applicable. (If no targets are specified, this replaces the sources.)
{p_end}
{synopt:{opt wild:parse}}Allow rename-style syntax if {it:target}{cmd:=}{it:source} is specified (e.g. {it:x*}{cmd:=}{it:prefix_x*}).
{p_end}

{syntab :HDFE Options}
{synopt:{opth by(varlist)}}Group by variables.
{p_end}
{synopt:{opt mata:save}[{cmd:(}{it:str}{cmd:)}]}Save {opt by()} info (and absorb info by group) in mata object (default name is {bf:GtoolsByLevels})
{p_end}
{synopt:{opt absorbmi:ssing}}Treat missing absorb levels as a group instead of dropping them.
{p_end}
{synopt:{opth algorithm(str)}}Algorithm used to absorb HDFE: CG (conjugate gradient), MAP (alternating projections), SQUAREM (squared extrapolation), IT (Irons and Tuck).
{p_end}
{synopt:{opth maxiter(int)}}Maximum number of algorithm iterations (default 100,000). Pass {it:.} for unlimited iterations.
{p_end}
{synopt:{opth tol:erance(real)}}Convergence tolerance (default 1e-8).
{p_end}
{synopt:{opth trace:iter}}Trace algorithm iterations.
{p_end}
{synopt:{opth stan:dardize}}Standardize variables before algorithm.
{p_end}

{syntab:Gtools Options}
{synopt :{opt compress}}Try to compress strL {cmd:by()} variables to str#.
{p_end}
{synopt :{opt forcestrl}}Skip binary {cmd:by()} variables check and force gtools to read strL {cmd:by()} variables.
{p_end}
{synopt :{opt v:erbose}}Print info during function execution.
{p_end}
{synopt :{opt bench}{it:[(int)]}}Benchmark various steps of the plugin. Optionally specify depth level.
{p_end}
{synopt :{opth hash:method(str)}}Hash method for {cmd:by()} variables (default, biject, or spooky). Intended for debugging.
{p_end}
{synopt :{opth oncollision(str)}}Collision handling (fallback or error). Intended for debugging.
{p_end}

{synoptline}
{p2colreset}{...}
{p 4 6 2}

{marker weight}{...}
{p 4 6 2}
{opt aweight}s, {opt fweight}s, and {opt pweight}s are
allowed (see {manhelp weight U:11.1.6 weight} for more on the way Stata
uses weights).

{marker description}{...}
{title:Description}

{pstd}
{opt gstats hdfe} (alias {opt gstats residualize}) is designed as a
utility to embed in programs that require absorbing high-dimensional
fixed effects, optionally taking in weights. The number of non-missing
observations and the number of levels in each absorb variable are
returned (see {it:{help gstats hdfe##results:stored results}}).

{pstd}
Mainly as a side-effect of being a {cmd:gtools} program, {opt by()} is
also allowed. In this case, the fixed effects are absorbed sepparately
for each group defined by {opt by()}. Note in this case the number of
non-missing observations and the number of absorb levels varies by group.
This is {bf:NOT} saved by default. The user can optionally specify
{opt mata:save}[{cmd:(}{it:str}{cmd:)}] to save information on the by levels,
including the number of non-missing rows per level and the number of
levels per absorb variable per level.

{pstd}
{opt mata:save}[{cmd:(}{it:str}{cmd:)}] by default is stored in
{opt GtoolsByLevels} but the user may specify any name desired.
Run {opt mata GtoolsByLevels.desc()} for details on the stored
objects (also see {it:{help gstats hdfe##results:stored results}} below).

{marker examples}{...}
{title:Examples}

{pstd}
See the
{browse "http://gtools.readthedocs.io/en/latest/usage/gstats_hdfe/index.html#examples":online documentation}
for examples.

{marker results}{...}
{title:Stored results}

{pstd}
{cmd:gstats hdfe} stores the following in {cmd:r()}:

{synoptset 15 tabbed}{...}
{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:r(algorithm)}} algorithm used for HDFE absorption{p_end}
{p2colreset}{...}

{synoptset 15 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:r(N)    }} number of non-missing observations {p_end}
{synopt:{cmd:r(J)    }} number of {opt by()} groups {p_end}
{synopt:{cmd:r(minJ) }} largest {opt by()} group size {p_end}
{synopt:{cmd:r(maxJ) }} smallest {opt by()} group size {p_end}
{synopt:{cmd:r(iter) }} (without {opt by()}) iterations of absorption algorithm {p_end}
{synopt:{cmd:r(feval)}} (without {opt by()}) function evaluations in absorption algorithm {p_end}
{p2colreset}{...}

{synoptset 15 tabbed}{...}
{p2col 5 20 24 2: Matrices}{p_end}
{synopt:{cmd:r(nabsorb)}} (without {opt by()}) vector with number of levels in each absorb variable{p_end}
{p2colreset}{...}

{pstd}
With {opt mata:save}[{cmd:(}{it:str}{cmd:)}], the following data is
stored in the mata object:

        string matrix nj
            non-missing observations in each -by- group

        string matrix njabsorb
            number of absorbed levels in each -by- group by each absorb variable

        real scalar anynum
            1: any numeric by variables; 0: all string by variables

        real scalar anychar
            1: any string by variables; 0: all numeric by variables

        string rowvector byvars
            by variable names

        real scalar kby
            number of by variables

        real scalar rowbytes
            number of bytes in one row of the internal by variable matrix

        real scalar J
            number of levels

        real matrix numx
            numeric by variables

        string matrix charx
            string by variables

        real scalar knum
            number of numeric by variables

        real scalar kchar
            number of string by variables

        real rowvector lens
            > 0: length of string by variables; <= 0: internal code for numeric variables

        real rowvector map
            map from index to numx and charx

        real rowvector charpos
            position of kth character variable

        string matrix printed
            formatted (printf-ed) variable levels (not with option -silent-)

{marker missing}{...}
{title:Missing Features}

{pstd}
Check whether it's mathematically OK to apply SQUAREM. In general it's meant
for contractions but my understanding is that it can be applied to any 
monotonically convergent algorithm.

{pstd}
Improve convergence criterion. Current criterion may not be sensible.

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
{browse "https://github.com/sergiocorreia/ftools"}, and this specific
function was inspired by Sergio Correia's {it:reghdfe}:
{browse "https: //github.com/sergiocorreia/reghdfe"}.
{p_end}

{pstd}
The OSX version of gtools was implemented with invaluable help from @fbelotti;
see {browse "https://github.com/mcaceresb/stata-gtools/issues/11"}.
{p_end}

{marker references}{...}
{title:References}

{pstd}
See
{browse "http://gtools.readthedocs.io/en/latest/usage/gstats_hdfe/index.html#references":online documentation}
for the list of references.

{title:Also see}

{pstd}
help for
{help gtools}
