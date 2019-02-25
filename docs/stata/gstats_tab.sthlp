{smcl}
{* *! version 0.2.0  25Feb2019}{...}
{viewerdialog gstats_summarize "dialog gstats_summarize"}{...}
{vieweralsosee "[R] gstats_summarize" "mansection R gstats_summarize"}{...}
{viewerjumpto "Syntax" "gstats_summarize##syntax"}{...}
{viewerjumpto "Description" "gstats_summarize##description"}{...}
{viewerjumpto "Statistics" "gstats_summarize##statistics"}{...}
{title:Title}

{p2colset 5 25 28 2}{...}
{p2col :{cmd:gstats summarize} {hline 2}} Summary statistics by group using C for speed {p_end}
{p2colreset}{...}

{pstd}
{it:Important}: Please run {stata gtools, upgrade} to update {cmd:gtools} to
the latest stable version.

{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:gstats {ul:sum}marize}
{varlist}
{ifin}
[{it:{help gstats##weight:weight}}]
[{cmd:,} {opth by(varlist)} {it:{help gstats##table_options:options}}]

{p 8 17 2}
{cmd:gstats {ul:tab}stat}
{varlist}
{ifin}
[{it:{help gstats##weight:weight}}]
[{cmd:,} {opth by(varlist)} {it:{help gstats##table_options:options}}]

{pstd}
{cmd:gstats {ul:tab}stat} and {cmd:gstats {ul:sum}marize} are fast, by-able
alternatives to {opt tabstat} and {opt summarize, detail}.
If {cmd:gstats summarize} is called with {opt by()} or {opt tab}, a table
in the style of {opt tabstat} is produced that inclues all the summary
statistics included by default in {opt summarize, detail}.

{pstd}
Note the {it:prefixes} {cmd:by}, {cmd:rolling}, {cmd:statsby} are
{cmd:{it:not}} supported. To compute a table of statistics by a group
use the option {opt by()}. With {op by()}, {opt gstats tab} is also
faster than {cmd:gcollapse}.

{synoptset 23 tabbed}{...}
{marker table_options}{...}
{synopthdr}
{synoptline}
{syntab :Tabstat Options}
{synopt:{opth by(varname)}}Group statistics by variable.
{p_end}
{synopt:{cmdab:s:tatistics:(}{it:{help gstats_summarize##statname:stat}} [{it:...}]{cmd:)}}Report
specified statistics; default for {opt tabstat} is count, sum, mean, sd, min, max.
{p_end}
{synopt:{opt col:umns(stat|var)}}Columns are statistics (default) or variables.
{p_end}
{synopt:{opt pretty:stats}}Pretty statistic header names
{p_end}
{synopt:{opth labelw:idth(int)}}Max by variable label/value width.
{p_end}
{synopt:{opt f:ormat}[{cmd:(%}{it:{help format:fmt}}{cmd:)}]}
Use format to display summary stats; default %9.0g
{p_end}

{syntab :Summarize Options}
{synopt:{opt nod:etail}}Do not display the full set of statistics.
{p_end}
{synopt:{opt mean:only}}Calculate only the count, sum, mean, min, max.
{p_end}
{synopt:{opth by(varname)}}Group by variable; all stats are computed but output is in the style of tabstat.
{p_end}
{synopt:{opt sep:arator(#)}}Draw separator line after every {it:#} variables; default is {cmd:separator(5)}.
{p_end}
{synopt:{opt tab:stat}}Compute and display statistics in the style of {opt tabstat}.
{p_end}

{syntab :Common Options}
{synopt:{opt mata:save}[{cmd:(}{it:str}{cmd:)}]}Save results in mata object (default name is {bf:GstatsOutput})
{p_end}
{synopt:{opt pool:ed}}Pool varlist
{p_end}
{synopt:{opt noprint}}Do not print
{p_end}
{synopt:{opt f:ormat}}Use variable's display format.
{p_end}
{synopt:{opt nomiss:ing}}With {opt by()}, ignore groups with missing entries.
{p_end}

{syntab:Gtools Options}
{synopt :{opt compress}}Try to compress strL to str#.
{p_end}
{synopt :{opt forcestrl}}Skip binary variable check and force gtools to read strL variables.
{p_end}
{synopt :{opt v:erbose}}Print info during function execution.
{p_end}
{synopt :{opt bench}{it:[(int)]}}Benchmark various steps of the plugin. Optionally specify depth level.
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
{opt aweight}s, {opt fweight}s, {opt iweight}s, and {opt pweight}s are
allowed (see {manhelp weight U:11.1.6 weight} for more on the way Stata
uses weights).

{marker description}{...}
{title:Description}

{pstd}
{opt gstats tab} and {opt gstats sum} are mainly designed to report
statistics by group. It does not modify the data in memory,
so it is a nice alternative to {opt gcollapse} when there are few
groups and you want to compute summary stats more quickly.

{pstd}
{opt gstats sum} by default computes the staistics that are reported by
{opt sum, detail} and without {opt by()} it is anywhere from 5 to 40
times faster. The lower end of the speed gains are for Stata/MP, but
{opt sum, detail} is very slow in versions of Stata that are not multi-threaded.
The behavior of plain {opt summarize} and {opt summarize, meanonly}
can be recovered via options {opt nodetail} and {opt meanonly}, but Stata
is not specially slow in this case. Hence they are mainly included for
use with {opt by()}, where {opt gstats sum} is again faster.

{pstd}
{opt gstats tab} should be faster than {opt tabstat} even without
groups, but the speed gains are largest with even a modest number of
levels in {opt by()}. Furthermore, an arbitrary number of grouping
variables are allowed. Note that with a very large numer of groups,
{opt tabstat}'s runtime seems to scale non-linearly, while {opt gstats tab}
will execute in a reasonable time.

{pstd}
{opt gstata tab} does not store results in {opt r()}. Rather, the option {opt matasave}
is provided to store the full set of summary statistics and the by variable
levels in a mata class object called {opt statsOutput} (the name of the object
can be changed via {opt matasave(name)}). Run {opt mata GstatsOutput.desc()}
after {opt gstats tab, matasave} for details. The following helper functions are provided:

        string scalar getf(j, l, maxlbl)
            get formatted (j, l) entry from by variables up to maxlbl characters

        real matrix getnum(j, l)
            get (j, l) numeric entry from by variables

        string matrix getchar(j, l,| raw)
            get (j, l) numeric entry from by variables; raw controls whether to null-pad entries

        real rowvector getOutputRow(j)
            get jth output row

        real colvector getOutputCol(j)
            get jth output column by position

        real matrix getOutputVar(var)
            get jth output var by name

        real matrix getOutputGroup(j)
            get jth output group

{pstd}
The following data is stored {opt GstatsOutput}:

        summary statistics
        ------------------

            real matrix output
                matrix with output statistics; J x kstats x kvars

            real scalar colvar
                1: columns are variables, rows are statistics; 0: the converse

            real scalar ksources
                number of variable sources (0 if pool is true)

            real scalar kstats
                number of statistics

            real matrix tabstat
                1: used tabstat; 0: used summarize

            string rowvector statvars
                variables summarized

            string rowvector statnames
                statistics computed

            real rowvector scodes
                internal code for summary statistics

            real scalar pool
                pooled source variables

        variable levels (empty if without -by()-)
        -----------------------------------------

            real scalar anyvars
                1: any by variables; 0: no by variables

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

        printing options
        ----------------

            void printOutput()
                print summary table

            real scalar maxlbl
                max by variable label/value width

            real scalar pretty
                print pretty statistic names

            real scalar usevfmt
                use variable format for printing

            string scalar dfmt
                fallback printing format

            real scalar maxl
                maximum column length

            void readDefaults()
                reset printing defaults

{marker statistics}{...}
{title:Statistics}

{phang}
{cmd:statistics(}{it:statname} [{it:...}]{cmd:)}
   specifies the statistics to be displayed; the default with {opt tabstat}
   is equivalent to specifying {cmd:statistics(mean)}. ({opt stats()}
   is a synonym for {opt statistics()}.) Multiple statistics
   may be specified and are separated by white space, such as
   {cmd:statistics(mean sd)}. Available statistics are

{marker statname}{...}
{synoptset 17}{...}
{synopt:{space 4}{it:statname}}Definition{p_end}
{space 4}{synoptline}
{synopt:{space 4}{opt me:an}} mean{p_end}
{synopt:{space 4}{opt co:unt}} count of nonmissing observations{p_end}
{synopt:{space 4}{opt n}} same as {cmd:count}{p_end}
{synopt:{space 4}{opt nmiss:ing}} number of missing observations{p_end}
{synopt:{space 4}{opt perc:ent}} percentage of nonmissing observations{p_end}
{synopt:{space 4}{opt nuniq:ue}} number of unique elements{p_end}
{synopt:{space 4}{opt su:m}} sum{p_end}
{synopt:{space 4}{opt rawsu:m}} sum, ignoring optionally specified weights ({bf:note}: zero-weighted obs are still excluded){p_end}
{synopt:{space 4}{opt nansu:m}} sum; returns . instead of 0 if all entries are missing{p_end}
{synopt:{space 4}{opt rawnansu:m}} rawsum; returns . instead of 0 if all entries are missing{p_end}
{synopt:{space 4}{opt med:ian}} median (same as {opt p50}){p_end}
{synopt:{space 4}{opt p#.#}} arbitrary quantiles{p_end}
{synopt:{space 4}{opt p1}} 1st percentile{p_end}
{synopt:{space 4}{opt p2}} 2nd percentile{p_end}
{synopt:{space 4}{it:...}} 3rd-49th percentiles{p_end}
{synopt:{space 4}{opt p50}} 50th percentile (same as {opt median}){p_end}
{synopt:{space 4}{it:...}} 51st-97th percentiles{p_end}
{synopt:{space 4}{opt p98}} 98th percentile{p_end}
{synopt:{space 4}{opt p99}} 99th percentile{p_end}
{synopt:{space 4}{opt iqr}} interquartile range = {opt p75} - {opt p25}{p_end}
{synopt:{space 4}{opt q}} equivalent to specifying {cmd:p25 p50 p75}{p_end}
{synopt:{space 4}{opt sd}} standard deviation{p_end}
{synopt:{space 4}{opt v:ariance}} variance{p_end}
{synopt:{space 4}{opt cv}} coefficient of variation ({cmd:sd/mean}){p_end}
{synopt:{space 4}{opt select#}} #th smallest{p_end}
{synopt:{space 4}{opt select-#}} #th largest{p_end}
{synopt:{space 4}{opt mi:n}} minimum (same as {opt select1}){p_end}
{synopt:{space 4}{opt ma:x}} maximum (same as {opt select-1}){p_end}
{synopt:{space 4}{opt r:ange}} range = {opt max} - {opt min}{p_end}
{synopt:{space 4}{opt first}} first value{p_end}
{synopt:{space 4}{opt last}} last value{p_end}
{synopt:{space 4}{opt firstnm}} first nonmissing value{p_end}
{synopt:{space 4}{opt lastnm}} last nonmissing value{p_end}
{synopt:{space 4}{opt sem:ean}} standard error of mean ({cmd:sd/sqrt(n)}){p_end}
{synopt:{space 4}{opt seb:inomial}} standard error of the mean, binomial ({cmd:sqrt(p(1-p)/n)}){p_end}
{synopt:{space 4}{opt sep:oisson}} standard error of the mean, Poisson ({cmd:sqrt(mean)}){p_end}
{synopt:{space 4}{opt sk:ewness}} skewness{p_end}
{synopt:{space 4}{opt k:urtosis}} kurtosis{p_end}
{space 4}{synoptline}
{p2colreset}{...}

{marker example}{...}
{title:Examples}

{pstd}
See the
{browse "http://gtools.readthedocs.io/en/latest/usage/gstats_summarize/index.html#examples":online documentation}
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
{help summarize};
{help tabstat};
{help gtools}
