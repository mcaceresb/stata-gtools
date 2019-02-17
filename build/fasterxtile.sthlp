{smcl}
{* *! version 1.0.2  23Jan2019}{...}
{viewerdialog gquantiles "dialog gquantiles"}{...}
{vieweralsosee "[R] gquantiles" "mansection R gquantiles"}{...}
{viewerjumpto "Syntax" "gquantiles##syntax"}{...}
{viewerjumpto "Description" "gquantiles##description"}{...}
{viewerjumpto "Options" "gquantiles##options"}{...}
{viewerjumpto "Stored results" "gegen##results"}{...}
{title:Title}

{p2colset 5 19 23 2}{...}
{p2col :{cmd:gquantiles} {hline 2}}Efficiently compute percentiles (quantiles), categories, and frequencies.{p_end}
{p2colreset}{...}

{pstd}
{it:Important}: Please run {stata gtools, upgrade} to update {cmd:gtools} to
the latest stable version.

{marker syntax}{...}
{title:Syntax}

{pstd}
gquantiles can function as a fast, by-able, alternative to {cmd:xtile},
{cmd:pctile}, and {cmd:_pctile}, though it offers more functionality
that those Stata commands (e.g. this function accepts {opth by(varlist)}
with {cmd:xtile[()]} and {cmd:pctile[()]}, it can compute arbitrary
quantiles and an arbitrary number in a reasonable amount of time, 
it computes frequencies, and more).

{phang}
Create variable containing percentiles (equivalent to {cmd:pctile})

{p 8 15 2}
{cmd:gquantiles}
{newvar} {cmd:=} {it:{help exp}}
{ifin}
[{it:{help gquantiles##weight:weight}}]
{cmd:,}
pctile
[{opth nquantiles(int)}
{opth genp(newvarname)}
{opt altdef}]

{phang}
Create variable containing quantile categories (equivalent to {cmd:xtile})

{p 8 15 2}
{cmd:gquantiles}
{newvar} {cmd:=} {it:{help exp}}
{ifin}
[{it:{help gquantiles##weight:weight}}]
{cmd:,}
xtile
[{opth nquantiles(int)}
{opth cutpoints(varname)}
{opt altdef}]

{p 8 15 2}
{cmd:fasterxtile}
{newvar} {cmd:=} {it:{help exp}}
{ifin}
[{it:{help gquantiles##weight:weight}}]
{cmd:,}
[{opth nquantiles(int)}
{opth cutpoints(varname)}
{opt altdef}]

{phang}
Compute percentiles and store them in r() (equivalent to {cmd:_pctile})

{p 8 15 2}
{cmd:gquantiles}
{it:{help exp}}
{ifin}
[{it:{help gquantiles##weight:weight}}]
{cmd:,}
_pctile
[{opth nquantiles(int)}
{opth percentiles(numlist)}
{opt altdef}]

{pstd}
The full syntax, however, is

{p 8 15 2}
{cmd:gquantiles}
[{newvar} {cmd:=}] {it:{help exp}}
{ifin}
[{it:{help gquantiles##weight:weight}}]
{cmd:,}
{c -(}{cmd:pctile}{c |}{cmd:xtile}{c |}{cmd:_pctile}{c )-}
{it:{help gquantiles##quantiles_method:quantiles_method}}
[{it:{help gquantiles##gquantiles_options:gquantiles_options}}]

{synoptset 22 tabbed}{...}
{marker quantiles_method}{...}
{synopthdr}
{synoptline}
{syntab :Quantiles method (choose only one)}

{synopt :{opt n:quantiles(#)}}number of quantiles; default is {cmd:nquantiles(2)}
{p_end}
{synopt :{opth p:ercentiles(numlist)}}calculate percentiles corresponding to the specified percentages
{p_end}
{synopt :{opth c:utpoints(varname)}}use values of {it:varname} as cutpoints
{p_end}
{synopt :{opth cutoffs(numlist)}}use values of {it:numlist} as cutpoints
{p_end}
{synopt :{opth cutquantiles(numlist)}}calculate percentiles corresponding to the values of {it:varname}
{p_end}
{synopt :{opth quantmatrix(matrix)}}use values of {it:matrix} as quantiles
{p_end}
{synopt :{opth cutmatrix(matrix)}}use values of {it:matrix} as cutpoints
{p_end}

{synoptset 18 tabbed}{...}
{marker gquantiles_options}{...}
{synopthdr}
{synoptline}
{syntab :Options}

{synopt :{opth g:enp(newvar:newvarp)}}generate {it:newvarp} variable containing percentages
{p_end}
{synopt :{opt alt:def}}use alternative formula for calculating percentiles
{p_end}

{syntab:Extras}
{synopt :{opth by(varlist)}}Compute quantiles by groups ({cmd:pctile} and {cmd:xtile} only).
{p_end}
{synopt :{opth groupid(varname)}}Store group ID in {it:varname}.
{p_end}
{synopt :{opt _pctile}}(Not with by.) Do the computation in the style of {cmd:_pctile}
{p_end}
{synopt :{cmd:pctile}[{cmd:(}{newvar}{cmd:)}]}Store percentiles in {it:newvar}. If {it:newvar} is not specified, then this indicates to do the computations in the style of {cmd:pctile}.
{p_end}
{synopt :{cmd:xtile}[{cmd:(}{newvar}{cmd:)}]}Store quantile categories in {it:newvar}. If {it:newvar} is not specified, then this indicates to do the computations in the style of {cmd:xtile}.
{p_end}
{synopt :{cmd:binfreq}[{cmd:(}{newvar}{cmd:)}]}Store the frequency counts of the source variable in the quantile categories in {it:newvar}. If {it:newvar} is not specified (not with by), this is stored in {hi:r(quantiles_bincount)} or {hi:r(cutoffs_bincount)}
{p_end}

{syntab:Switches}
{synopt :{opt method(#)}}(Not with by.) Algorithm to use to compute quantiles.
{p_end}
{synopt :{opt dedup}}Drop duplicate values of variables specified via {opth cutpoints} or {opth cutquantiles}
{p_end}
{synopt :{opt cutifin}}Exclude values outside {ifin} of variables specified via {opth cutpoints} or {opth cutquantiles}
{p_end}
{synopt :{opt cutby}}Use {opth cutquantiles()} or {opth cutpoints()} by group.
{p_end}
{synopt :{opt returnlimit(#)}}Maximum return values that can be set via {opt _pctile}
{p_end}
{synopt :{opt strict}}Without by, exit with error when the number of quantiles requested exceeds the number non-missing. With by, skip groups where this happens.
{p_end}
{synopt :{opt minmax}}(Not with by.) Additionally store the min and max in {hi:r(min)} and {hi:r(max)}
{p_end}
{synopt :{opt replace}}Replace targets, should they exist.
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
{opt aweight}s, {opt fweight}s, and {opt pweight}s are allowed (see
{manhelp weight U:11.1.6 weight}), except with option {opt altdef}, in
which case no weights are allowed.
{p_end}

{marker description}{...}
{title:Description}

{pstd}
{cmd:gquantiles} replaces {cmd:xtile}, {cmd:pctile}, and {cmd:_pctile}.
gquantiles offers several additional options above the three built-in
Stata commands: an arbitrary number of quantiles, arbitrary cutoffs,
frequency counts of the xtile categories, computing {cmd:pctile} and
{cmd:xtile} at the same time, and so on.

{pstd}
gquantiles is also faster than the user-written fastxtile, so an alias,
fasterxtile, is provided.

{pstd}
{opt gquantiles} is part of the {manhelp gtools R:gtools} project.

{marker options}{...}
{title:Options}

{dlgtab:Quantiles method}

{phang}
{opt n:quantiles(#)} specifies the number of quantiles.
It computes percentiles corresponding to percentages 100*k/m
for k=1, 2, ..., m-1, where m={it:#}.  For example, {cmd:nquantiles(10)}
requests that the 10th, 20th, ..., 90th percentiles be computed.  The default
is {cmd:nquantiles(2)}; that is, the median is computed.

{phang}
{opth p:ercentiles(numlist)} requests
percentiles corresponding to the specified percentages.  For example,
{cmd:percentiles(10(20)90)} requests that the 10th, 30th, 50th, 70th, and 90th
percentiles be computed. With {opt _pctile} these are placed into {cmd:r(r1)},
{cmd:r(r2)}, {cmd:r(r3)}, {cmd:r(r4)}, and {cmd:r(r5)} up to 1,001. With
{opt xtile} these are the quantiles that define the categories and with
{opt pctile} these are the quantiles to compute.

{phang}
{opth c:utpoints(varname)} requests that the values of {it:varname}
be used to define the categories, rather than quantiles. This is natural
to use with {opt xtile}. With {opt pctile} and {opt _pctile} this is
redindant unless you also request {cmd:binfreq}[{cmd:(}{newvar}{cmd:)}].
By default, all values of {it:varname} are used, regardless of any {opt if}
or {opt in} restriction. You can specify {opt cutifin} to obey the
restrictions and {opt dedup} to exclude duplicates.

{phang}
{opth cutoffs(numlist)} Use values of {it:numlist} as cutpoints.

{phang}
{opth cutquantiles(numlist)} Calculate percentiles corresponding to the values of
{it:varname}. This is an alternative to {opth percentiles()}.

{phang}
{opth quantmatrix(matrix)}
Requests percentiles (quantiles) corresponding to the entries of the
matrix. This must be a column vector or a row vector. The behavior of
gquantiles using this option is otherwise equivalent to its behavior
when passing {opth quantiles()}.

{phang}
{opth cutmatrix(matrix)}
Requests cutoffs corresponding to the entries of the matrix. This must
be a column vector or a row vector. The behavior of gquantiles using
this option is otherwise equivalent to its behavior when passing
{opth cutoffs()}.

{dlgtab:Standard Options}

{phang}{opth genp(newvar)}
specifies a new variable to be generated
containing the percentages corresponding to the percentiles.

{phang}{opt altdef} uses an alternative formula for calculating percentiles
(not with weights).
The default method is to invert the empirical distribution function by using
averages, where the function is flat (the default is the same method used by
{cmd:summarize}; see {manhelp summarize R}).
The alternative formula uses an interpolation method.  See
{mansection D pctileMethodsandformulas:{it:Methods and formulas}} in
{bf:[D] pctile}.

{dlgtab:Extras}

{phang}
{opth by(varlist)}
Compute quantiles by group. {cmd:pctile[()]} requires option
{cmd:strict}, which has the effect of ignoring groups where the number
of quantiles requested is larger than the number of non-missing
observations within the group. {opth by()} is most useful with option
{opth groupid(varname)}.

{phang}
{opth groupid(varname)} Store group ID in {it:varname}. This
is equivalent to {cmd:gegen, group}

{phang}
{opt _pctile} (Not with by.) Do the computation in the style of {cmd:_pctile}. It
stores return values in r(1), r(2), and so on, as wll as a matrix called
{hi:r(quantiles_used)} or {hi:r(cutoffs_used)} in case quantiles or cutoffs
are requested. This can be combined with other options listed in this section.

{phang}
{cmd:pctile}[{cmd:(}{newvar}{cmd:)}] Store percentiles in {it:newvar}. If
{it:newvar} is not specified, then this indicates to do the computations in
the style of {cmd:pctile}.  This can be combined with other options listed in
this section.

{phang}
{cmd:xtile}[{cmd:(}{newvar}{cmd:)}] Store quantile categories in
{it:newvar}. If {it:newvar} is not specified, then this indicates to do the
computations in the style of {cmd:xtile}. This can be combined with other
options listed in this section.

{phang}
{cmd:binfreq}[{cmd:(}{newvar}{cmd:)}] Store the frequency counts of
the source variable in the quantile categories in {it:newvar}. When
weights are specified, this stores the sum of the weights within
that category. If {it:newvar} is not specified, this is stored in
{hi:r(quantiles_bincount)} or {hi:r(cutoffs_bincount)}. This can be
combined with other options listed in this section.

{dlgtab:Switches}

{phang}
{opt method(#)} (Not with by.) Algorithm to use to compute quantiles.  If you have many
duplicates or are computing many quantiles, you should specify {opt
method(1)}. If you have few duplicates or are computing few quantiles you
should specify {opt method(2)}. By default, {cmd:gquantiles} tries to guess
which method will run faster.

{phang}
{opt dedup} Drop duplicate values of variables specified via {opth
cutpoints()} or {opth cutquantiles()}. For instance, if the user asks for
quantiles 1, 90, 10, 10, and 1, then quantiles 1, 1, 10, 10, and 90 are
used. With this option only 1, 10, and 90 would be used.

{phang}
{opt cutifin} Exclude values outside {ifin} of variables specified via 
{opth cutpoints()} or {opth cutquantiles()}. The restriction that all
values are used is artificial (the option was originally written to
allow {cmd:xtile} to use {cmd:pctile} internally).

{phang}
{opt cutby} By default all values of the variable requested via {opth cutpoints()}
or {opth cutquantiles()} are used. With this option, each group uses a different
set of quantiles or cutoffs (note this automatically sets option {cmd:cutifin})

{phang}
{opt returnlimit(#)} Maximum return values that can be set via {opt _pctile}.
Since {cmd:gquantiles} can compute a large number of quantiles very quickly,
the function allows the user to request an arbitrary number. But setting
1,000s of return values is computationally infeasible. Consider {opt pctile}
in this case.

{phang}
{opt strict} Without {opth by()}, exit with error if the number of quantiles
is greater than the number of non-missing observations plus one.  With 
{opth by()}, skip groups where this  happens. This restriction for {opt pctile}
is sensible, but for {opt xtile} it is artificial. It exists because it uses
{opt pctile} internally, but {cmd:gquantiles} does not have this issue.

{phang}
{opt minmax} (Not with by.) Additionally store the min and max in {hi:r(min)} and {hi:r(max)}

{phang}
{opt replace} Replace targets, should they exist.

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

{marker example}{...}
{title:Examples}

{pstd}
See the
{browse "http://gtools.readthedocs.io/en/latest/usage/gquantiles/index.html#examples":online documentation}
for examples.

{marker results}{...}
{title:Stored results}

{pstd}
{cmd:gquantiles} stores the following in {cmd:r()}:

{synoptset 22 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:r(N)           }}Number of observations                     {p_end}
{synopt:{cmd:r(min)         }}Min (only if minmax was requested)         {p_end}
{synopt:{cmd:r(max)         }}Max (only if minmax was requested)         {p_end}
{synopt:{cmd:r(nqused)      }}Number of quantiles/cutoffs                {p_end}
{synopt:{cmd:r(method_ratio)}}Rule used to decide between methods 1 and 2{p_end}

{synopt:{cmd:r(nquantiles)     }}Number of quantiles (only w nquantiles())  {p_end}
{synopt:{cmd:r(ncutpoints)     }}Number of cutpoints (only w cutpoints())   {p_end}
{synopt:{cmd:r(nquantiles_used)}}Number of quantiles (only w quantiles())   {p_end}
{synopt:{cmd:r(nquantpoints)   }}Number of quantiles (only w cutquantiles()){p_end}
{synopt:{cmd:r(ncutoffs_used)  }}Number of cutoffs (only w cutoffs())       {p_end}

{synopt:{cmd:r(r#)}}The #th quantile requested (only w _pctile){p_end}
{p2colreset}{...}

{synoptset 22 tabbed}{...}
{p2col 5 15 19 2: Macros}{p_end}
{synopt:{cmd:r(quantiles)}}Quantiles used (only w percentiles() or quantiles()){p_end}
{synopt:{cmd:r(cutoffs)  }}Cutoffs used (only w option cutoffs())              {p_end}
{p2colreset}{...}

{synoptset 22 tabbed}{...}
{p2col 5 20 24 2: Matrices}{p_end}
{synopt:{cmd:r(quantiles_used)   }}With _pctile or with quantiles()               {p_end}
{synopt:{cmd:r(quantiles_binfreq)}}With option binfreq and any quantiles requested{p_end}

{synopt:{cmd:r(cutoffs_used)   }}With _pctile or with cutoffs()               {p_end}
{synopt:{cmd:r(cutoffs_binfreq)}}With option binfreq and any cutoffs requested{p_end}
{p2colreset}{...}


{marker author}{...}
{title:Author}

{pstd}Mauricio Caceres Bravo{p_end}
{pstd}{browse "mailto:mauricio.caceres.bravo@gmail.com":mauricio.caceres.bravo@gmail.com }{p_end}
{pstd}{browse "https://mcaceresb.github.io":mcaceresb.github.io}{p_end}

{title:Website}

{pstd}{cmd:gquantiles} is maintained as part of {manhelp gtools R:gtools} at {browse "https://github.com/mcaceresb/stata-gtools":github.com/mcaceresb/stata-gtools}{p_end}

{marker acknowledgment}{...}
{title:Acknowledgment}

{pstd}
This help file was based on StataCorp's own help file for {it:pctile}
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
{help pctile}, 
{help gtools};
{help fastxtile} (if installed),
{help ftools} (if installed)

