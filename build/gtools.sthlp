{smcl}
{* *! version 1.10.1 05Dec2022}{...}
{viewerdialog gtools "dialog gtools"}{...}
{vieweralsosee "[R] gtools" "mansection R gtools"}{...}
{viewerjumpto "Syntax" "gtools##syntax"}{...}
{viewerjumpto "Description" "gtools##description"}{...}
{viewerjumpto "Options" "gtools##options"}{...}
{viewerjumpto "Examples" "gtools##examples"}{...}
{title:Title}

{p2colset 5 18 23 2}{...}
{p2col :{cmd:gtools} {hline 2}}Manage {opt gtools} package installation.{p_end}
{p2colreset}{...}

{pstd}
{it:Important}: Please run {stata gtools, upgrade} to update
{cmd:gtools} to the latest stable version.

{pstd}
{opt gtools} is a suite of commands that use hashes for a speedup
over traditional stata commands. Syntax is largely analogous to each
command's Stata counterparts. The following are available as part of
gtools (also see the {help gtools##examples:examples} below):

{p 8 17 2}
{manhelp gcollapse R:gcollapse} and {manhelp gcontract R:gcontract} as {opt collapse} and {opt contract} replacements. {p_end}

{p 8 17 2}
{manhelp gquantiles R:gquantiles} as {opt pctile}, {opt xtile}, and {opt _pctile} replacements. {manhelp fasterxtile R:fasterxtile} is also provided as an alias
{p_end}

{p 8 17 2}
{manhelp gegen R:gegen} as a {opt egen} alternative. {p_end}

{p 8 17 2}
{manhelp gisid R:gisid} as an {opt isid} replacement. {p_end}

{p 8 17 2}
{manhelp gduplicates R:gduplicates} as a {opt duplicates} replacement. {p_end}

{p 8 17 2}
{manhelp glevelsof R:glevelsof} as a {opt levelsof} replacement. {p_end}

{p 8 17 2}
{manhelp gtoplevelsof R:gtoplevelsof} ({opt gtop}): Frequency count of top levels of a {opt varlist}. {p_end}

{p 8 17 2}
{manhelp gunique R:gunique} and {manhelp gdistinct R:gdistinct}: Count unique levels of a set of variables. {p_end}

{p 8 17 2}
{manhelp gstats R:gstats}: Wrapper for several statistical functions and transformations. {p_end}

{p 8 17 2}
{manhelp hashsort R:hashsort}: (Experimental) Hash-based sorting. {p_end}

{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:gtools}
[{cmd:,} {it:{help gtools##table_options:options}}]

{synoptset 15 tabbed}{...}
{marker table_options}{...}
{synopthdr}
{synoptline}
{syntab :Options}
{synopt :{opt u:pgrade}}Install latest version from Github.
{p_end}
{synopt :{opt i:nstall_latest}}Alias for {opt upgrade}.
{p_end}
{synopt :{opt license:s}}Prints the open source projects used in gtools
{p_end}
{synopt :{opt v:erbose}}With {opt licenses}, prints the licenses of the open source projects used in gtools
{p_end}
{synopt :{opt examples}}Print examples of how to use various gtools functions.
{p_end}
{synopt :{opt showcase}}Alias for {opt examples}.
{p_end}
{synopt :{bf:test[({it:tests})]}}Run unit tests, optionally specifying which tests to run.
{p_end}
{synopt :{opth branch(str)}}Github branch to use (defualt is master).
{p_end}


{synoptline}
{p2colreset}{...}
{p 4 6 2}

{marker description}{...}
{title:Description}

{pstd}
{opt gtools} is a Stata package that provides a fast implementation of
common commands like collapse, egen, xtile, isid, levelsof, contract,
distinct, and so on using C plugins for a massive speed improvement.

{pstd}
This program helps the user manage their gtools installation. While
unnecessary in Linux or OSX, when trying to compile the plugin on Windows
it became apparent that I would need to include a DLL with the package
(in particular the DLL for the hash library). While I try to do this
automatically, I ran into enough problems while developing the plugin that I
felt compelled to include this program.

{marker options}{...}
{title:Options}

{phang}
{opt upgrade} Upgrades {opt gtools} to the latest github version.

{phang}
{opt install_latest} Alias for {opt upgrade}.

{phang}
{opt license} Prints the open source projects used in {cmd gtools}. With
{opt verbose} it also prints the licenses.

{phang}
{opt examples} (alias {opt showcase}) prints examples of how to use
various gtools functions.

{phang}
{bf:test[({it:tests})]} Run unit tests, optionally specifying which tests
to run.  Tests available are: dependencies, basic_checks, bench_test,
comparisons, switches, bench_full.  A good set of "small" tests which
take 10-20 minutes are {cmd: dependencies basic_checks bench_test}.
By default, however, the first 5 tests are run, which take 1-3h. The
bulk of that time is from {bf:comparisons}, which compares the results
from gtools to that of various native counterparts under several
different conditions. {bf:bench_full} is not run by default because this
benchmarks gtools against stata using modestly-sized data (millions).
Some stata commands are very slow under some of the benchmarks, meaning
this can take well over a day.

{phang}
{opth branch(str)} Github branch to use (defualt is master).

{marker examples}{...}
{title:Examples}

{p 4 4 2}{stata sysuse auto, clear}{p_end}

{p 4 4 2}{it:gstats {sum|tab} varlist [if] [in] [weight], [by(varlist) options]}{p_end}

{p 8 4 2}{stata gstats sum price [pw = gear_ratio / 4]                         }{p_end}
{p 8 4 2}{stata gstats tab price mpg, by(foreign) matasave                     }{p_end}

{p 4 4 2}{it:gquantiles [newvarname =] exp [if] [in] [weight], {_pctile|xtile|pctile} [options]}{p_end}

{p 8 4 2}{stata gquantiles 2 * price, _pctile nq(10)                                }{p_end}
{p 8 4 2}{stata gquantiles p10 = 2 * price, pctile nq(10)                           }{p_end}
{p 8 4 2}{stata gquantiles x10 = 2 * price, xtile nq(10) by(rep78)                  }{p_end}
{p 8 4 2}{stata fasterxtile xx = log(price) [w = weight], cutpoints(p10) by(foreign)}{p_end}

{p 4 4 2}{it:gstats winsor varlist [if] [in] [weight], [by(varlist) cuts(# #) options]}{p_end}

{p 8 4 2}{stata gstats winsor price gear_ratio mpg, cuts(5 95) s(_w1)                 }{p_end}
{p 8 4 2}{stata gstats winsor price gear_ratio mpg, cuts(5 95) by(foreign) s(_w2)     }{p_end}

{p 4 4 2}{it:hashsort varlist, [options]                        }{p_end}

{p 8 4 2}{stata hashsort -make                                  }{p_end}
{p 8 4 2}{stata hashsort foreign -rep78, benchmark verbose mlast}{p_end}

{p 4 4 2}{it:gegen target = stat(source) [if] [in] [weight], by(varlist) [options]}{p_end}

{p 8 4 2}{stata gegen tag = tag(foreign)                                          }{p_end}
{p 8 4 2}{stata gegen group = tag(-price make)                                    }{p_end}
{p 8 4 2}{stata gegen p2_5 = pctile(price) [w = weight], by(foreign) p(2.5)       }{p_end}

{p 4 4 2}{it:gisid varlist [if] [in], [options]                                   }{p_end}

{p 8 4 2}{stata gisid make, missok                                                }{p_end}
{p 8 4 2}{stata gisid price in 1 / 2                                              }{p_end}

{p 4 4 2}{it:gduplicates varlist [if] [in], [options gtools(gtools_options)]      }{p_end}

{p 8 4 2}{stata gduplicates report foreign                                        }{p_end}
{p 8 4 2}{stata gduplicates report rep78 if foreign, gtools(bench(3))             }{p_end}

{p 4 4 2}{it:glevelsof varlist [if] [in], [options]                                                     }{p_end}
          
{p 8 4 2}{stata glevelsof rep78, local(levels) sep(" | ")                                               }{p_end}
{p 8 4 2}{stata glevelsof foreign mpg if price < 4000, loc(lvl) sep(" | ") colsep(", ")                 }{p_end}
{p 8 4 2}{stata glevelsof foreign mpg in 10 / 70, gen(uniq_) nolocal                                    }{p_end}
          
{p 4 4 2}{it:gtop varlist [if] [in] [weight], [options]                                                 }{p_end}
{p 4 4 2}{it:gtoplevelsof varlist [if] [in] [weight], [options]                                         }{p_end}
          
{p 8 4 2}{stata gtoplevelsof foreign rep78                                                              }{p_end}
{p 8 4 2}{stata gtop foreign rep78 [w = weight], ntop(5) missrow groupmiss pctfmt(%6.4g) colmax(3)      }{p_end}
          
{p 4 4 2}{it:gcollapse (stat) out = src [(stat) out = src ...] [if] [if] [weight], by(varlist) [options]}{p_end}
          
{p 8 4 2}{stata gen h1 = headroom                                                                       }{p_end}
{p 8 4 2}{stata gen h2 = headroom                                                                       }{p_end}
{p 8 4 2}{stata pretty# #sourcelabel#)                                                                  }{p_end}

{p 8 4 2}{stata gcollapse (mean) mean = price (median) p50 = gear_ratio, by(make) merge v               }{p_end}
{p 8 4 2}{stata disp "`:var label mean', `:var label p50'"                                              }{p_end}
{p 8 4 2}{stata gcollapse (iqr) irq? = h? (nunique) turn (p97.5) mpg, by(foreign rep78) bench(2) wild   }{p_end}

{p 4 4 2}{it:gcontract varlist [if] [if] [fweight], [options]}{p_end}

{p 8 4 2}{stata gcontract foreign [fw = turn], freq(f) percent(p)}{p_end}

{p 4 4 2}{it:greshape subcommand list, i(i) j(j) [options]}{p_end}

{p 8 4 2}{stata gen j = _n                                }{p_end}
{p 8 4 2}{stata greshape wide f p, i(foreign) j(j)        }{p_end}
{p 8 4 2}{stata greshape long f p, i(foreign) j(j)        }{p_end}
{p 8 4 2}{stata greshape spread f p, j(j)                 }{p_end}
{p 8 4 2}{stata greshape gather f? p?, j(j) value(fp)     }{p_end}

{marker author}{...}
{title:Author}

{pstd}Mauricio Caceres Bravo{p_end}
{pstd}{browse "mailto:mauricio.caceres.bravo@gmail.com":mauricio.caceres.bravo@gmail.com }{p_end}
{pstd}{browse "https://mcaceresb.github.io":mcaceresb.github.io}{p_end}

{title:Website}

{pstd}{cmd:gtools} is maintained at {browse "https://github.com/mcaceresb/stata-gtools":github.com/mcaceresb/stata-gtools}{p_end}


{marker acknowledgment}{...}
{title:Acknowledgment}

{pstd}
This project was largely inspired by Sergio Correia's {it:ftools}:
{browse "https://github.com/sergiocorreia/ftools"}.
{p_end}

{pstd}
The OSX version of gtools was implemented with invaluable help from @fbelotti;
see {browse "https://github.com/mcaceresb/stata-gtools/issues/11"}.
{p_end}
