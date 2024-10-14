{smcl}
{* *! version 1.11.1 03Apr2023}{...}
{viewerdialog gglm "dialog gglm"}{...}
{vieweralsosee "[R] gglm" "mansection R gglm"}{...}
{viewerjumpto "Syntax" "gglm##syntax"}{...}
{viewerjumpto "Description" "gglm##description"}{...}
{viewerjumpto "Methods and Formulas" "gglm##methods_and_formulas"}{...}
{viewerjumpto "Examples" "gglm##examples"}{...}
{title:Title}

{p2colset 5 18 24 2}{...}
{p2col :{cmd:gglm} {hline 2}} GLM (via IRLS) by group with weights, clustering, and HDFE{p_end}
{p2colreset}{...}

{pstd}
{it:Important}: Please run {stata gtools, upgrade} to update {cmd:gtools} to
the latest stable version.

{pstd}
{it:Warning}: {opt gglm} is in beta and meant for testing; use in production {bf:NOT} recommended. (To enable beta features, define {cmd:global GTOOLS_BETA = 1}.)

{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{opt gglm}
{depvar}
{indepvars}
{ifin}
[{it:{help gglm##weight:weight}}]
[{cmd:,} {opth by(varlist)} {opth absorb(varlist)} {it:{help gglm##table_options:options}}]

{pstd}
Support for different link functions may be added in future releases.
At the moment only the cannonical link for each `family()` is available.

{pstd}
By default, results are saved into a mata class object named after the
model estimated: {opt GtoolsLogit} when the logit link is used (default
with {opt family(bonimial)}), {opt GtoolsPoisson} when the poisson link
is used (default with {opt family(poisson)}), etc.  For details, the 
{opt desc()} method is available, e.g. {opt mata GtoolsLogit.desc()}. 
The name and contents can be modified via the {opt mata()} option.  The
results can also be saved into variables via {opt gen()} or {opt prefix()}
(either can be combined with {opt mata()}, but not each other).

{pstd}
Run {opt mata GtoolsLogit.desc()} for details; the name and contents can be
modified via {opt mata()}. The results can also be saved into variables
via {opt gen()} or {opt prefix()} (either can be combined with {opt
mata()}, but not each other).

{pstd}
Note that extended varlist syntax is {bf:not} supported. Further,
{opt fweight}s behave differently that other weighting schemes; that
is, this assumes that the weight refers to the number of available
{it:observations}.

{marker options}{...}
{title:Options}

{synoptset 23 tabbed}{...}
{marker table_options}{...}
{synopthdr}
{synoptline}
{syntab :Save Results}
{synopt:{opt mata(name, [nob nose])}}Specify name of output mata object and whether to save {bf:b} and {bf:se}
{p_end}
{synopt:{opt gen(...)}}Specify any of {opth b(varlist)}, {opth se(varlist)}, and {opth hdfe(varlist)}. One per covariate is required ({opt hdfe()} also requires one for the dependent variable).
{p_end}
{synopt:{opt prefix(...)}}Specify any of {opth b(str)}, {opth se(str)}, and {opth hdfe(str)}. A single prefix is allowed.
{p_end}
{synopt:{opt replace}}Allow replacing existing variables.
{p_end}

{syntab :Options}
{synopt:{opth by(varname)}}Group statistics by variable.
{p_end}
{synopt:{opt robust}}Robust SE.
{p_end}
{synopt:{opth cluster(varlist)}}One-way or nested cluster SE.
{p_end}
{synopt:{opth absorb(varlist)}}Multi-way high-dimensional fixed effects.
{p_end}
{synopt:{opt alphas(varlist)}}One per absorb variable; save FE (normalized to be mean zero).
{p_end}
{synopt:{opt predict(varname)}}Save linear fit.
{p_end}
{synopt:{opt resid(varname)}}Save residuals.
{p_end}
{synopt:{opth hdfetol(real)}}Tolerance level for HDFE algoritm (default 1e-8).
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
{synopt:{opt noc:onstant}}Whether to add a constant (cannot be combined with {opt absorb()}).
{p_end}
{synopt:{opth glmtol(real)}}Tolerance level for IRLS algoritm (default 1e-8).
{p_end}
{synopt:{opth glmiter(int)}}Maximum number of iterations for IRLS (default 1000).
{p_end}

{syntab:Gtools}
{synopt:{opt compress}}Try to compress strL to str#.
{p_end}
{synopt:{opt forcestrl}}Skip binary variable check and force gtools to read strL variables.
{p_end}
{synopt:{opt v:erbose}}Print info during function execution.
{p_end}
{synopt:{cmd:bench}[{cmd:(}{int}{cmd:)}]}Benchmark various steps of the plugin. Optionally specify depth level.
{p_end}
{synopt:{opth hash:method(str)}}Hash method (default, biject, or spooky). Intended for debugging.
{p_end}
{synopt:{opth oncollision(str)}}Collision handling (fallback or error). Intended for debugging.
{p_end}

{synoptline}
{p2colreset}{...}
{p 4 6 2}

{marker weight}{...}
{p 4 6 2}
{opt aweight}s, {opt fweight}s, and {opt pweight}s are allowed.
{p_end}

{marker description}{...}
{title:Description}

{pstd}
{cmd:gglm} estimates GLM via IRLS, optionally weighted, by group, with
cluster SE, and/or with multi-way high-dimensional fixed effects.
The results are by default saved into a mata object (e.g.  {opt GtoolsLogit},
{opt GtoolsPoisson}, and so on; run {opt mata GtoolsLogit.desc()} for details).
The following data is stored:

        regression info
        ---------------

            string scalar caller
                model used; "glogit", "gpoisson", etc.

            real scalar kx
                number of (non-absorbed) covariates

            real scalar cons
                whether a constant was added automagically

            real scalar saveb
                whether b was stored

            real matrix b
                J by kx matrix with regression coefficients

            real scalar savese
                whether se was stored

            real matrix se
                J by kx matrix with corresponding standard errors

            string scalar setype
                type of SE computed (homoskedastic, robust, or cluster)

            real scalar absorb
                whether any FE were absorbed

            string colvector absorbvars
                variables absorbed as fixed effects

            string colvector njabsorb
                number of FE to be absorbed for each variaable and by level

            string colvector savenjabsorb
                whether njabsorb is stored

            string colvector clustervars
                cluster variables

            string colvector njcluster
                number of clusters per by level

            string colvector savenjcluster
                whether njcluster is stored

            real scalar by
                whether there were any grouping variables

            string rowvector byvars
                grouping variable names

            real scalar J
                number of levels defined by grouping variables

            class GtoolsByLevels ByLevels
                grouping variable levels; see GtoolsLogit.ByLevels.desc() for details

        variable levels (empty if without -by()-)
        -----------------------------------------

            real scalar ByLevels.anyvars
                1: any by variables; 0: no by variables

            real scalar ByLevels.anychar
                1: any string by variables; 0: all numeric by variables

            string rowvector ByLevels.byvars
                by variable names

            real scalar ByLevels.kby
                number of by variables

            real scalar ByLevels.rowbytes
                number of bytes in one row of the internal by variable matrix

            real scalar ByLevels.J
                number of levels

            real matrix ByLevels.numx
                numeric by variables

            string matrix ByLevels.charx
                string by variables

            real scalar ByLevels.knum
                number of numeric by variables

            real scalar ByLevels.kchar
                number of string by variables

            real rowvector ByLevels.lens
                > 0: length of string by variables; <= 0: internal code for numeric variables

            real rowvector ByLevels.map
                map from index to numx and charx

{marker methods_and_formulas}{...}
{title:Methods and Formulas}

See the
{browse "http://gtools.readthedocs.io/en/latest/usage/gglm/index.html#methods-and-formulas":online documentation}
for details.

{marker example}{...}
{title:Examples}

{pstd}
See the
{browse "http://gtools.readthedocs.io/en/latest/usage/gglm/index.html#examples":online documentation}
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

{marker references}{...}
{title:References}

{pstd}
See
{browse "http://gtools.readthedocs.io/en/latest/usage/gglm/index.html#references":online documentation}
for the list of references.

{title:Also see}

{pstd}
help for
{help gtools}
