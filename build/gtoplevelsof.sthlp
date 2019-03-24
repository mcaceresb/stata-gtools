{smcl}
{* *! version 1.2.0  20Mar2019}{...}
{vieweralsosee "[P] gtoplevelsof" "mansection P gtoplevelsof"}{...}
{viewerjumpto "Syntax" "gtoplevelsof##syntax"}{...}
{viewerjumpto "Description" "gtoplevelsof##description"}{...}
{viewerjumpto "Options" "gtoplevelsof##options"}{...}
{viewerjumpto "Remarks" "gtoplevelsof##remarks"}{...}
{viewerjumpto "Stored results" "gtoplevelsof##results"}{...}
{title:Title}

{p2colset 5 23 23 2}{...}
{p2col :{cmd:gtoplevelsof} {hline 2}}Quickly tabulate most common levels of variable list.{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{opt gtop:levelsof}
{varlist}
{ifin}
[{it:{help gtoplevelsof##weight:weight}}]
[{cmd:,} {it:options}]

{synoptset 24 tabbed}{...}
{synopthdr}
{synoptline}
{syntab :Summary Options}
{synopt:{opth ntop(int)}} Display {opt ntop} most common levels (negative shows least common; {opt .} shows every level).{p_end}
{synopt:{opth freqabove(int)}} Only count freqs above this level.{p_end}
{synopt:{opth pctabove(real)}} Only count freqs that represent at least % of the total.{p_end}
{synopt:{opt mata:save}[{cmd:(}{it:str}{cmd:)}]}Save results in mata object (default name is {bf:GtoolsByLevels}){p_end}

{syntab :Toggles}
{synopt:{opt missrow}} Add row with count of missing values.{p_end}
{synopt:{opt groupmiss:ing}} Count rows with any variable missing as missing.{p_end}
{synopt:{opt nomiss:ing}} Case-wise exclude rows with missing values from frequency count.{p_end}
{synopt:{opt nooth:er}} Do not group rest of levels into "other" row.{p_end}
{synopt:{opt alpha}} Sort the top levels of varlist by variables instead of frequencies.{p_end}
{synopt:{opt silent}} Do not display the top levels of varlist.{p_end}

{syntab :Display Options}
{synopt:{opth pctfmt(format)}} Format for percentages.{p_end}
{synopt:{opth oth:erlabel(str)}} Specify label for row with "other" count.{p_end}
{synopt:{opth missrow:label(str)}} Specify the label for the row with "missing" count.{p_end}
{synopt:{opth varabb:rev(int)}} Abbreviate variables (which are displayed as a header to their levels) .{p_end}
{synopt:{opth colmax(numlist)}} Specify width limit for levels (can be single number of variable-specific).{p_end}
{synopt:{opth colstrmax(numlist)}} Specify width limit for string variables (can be single number of variable-specific).{p_end}
{synopt:{opt cols:eparate(separator)}} Column separator; default is double blank "  ".{p_end}
{synopt:{opth numfmt(format)}} Format for numeric variables. Default is {opt %.8g} (or {opt %16.0g} with {opt matasave}).{p_end}
{synopt:{opt novaluelab:els}} Do not replace numeric variables with their value labels.{p_end}
{synopt:{opt hidecont:levels}} If a level is repeated in the subsequent row, display a blank.{p_end}

{syntab :levelsof Options}
{synopt:{opt l:ocal(macname)}}insert top levels in the local macro {it:macname}{p_end}
{synopt:{opt s:eparate(separator)}}separator for the values of returned list; default is a space{p_end}

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

{marker weight}{...}
{p 4 6 2}
{opt aweight}s, {opt fweight}s, and {opt pweight}s are allowed, in which
case the top levels by weight are printed (see {manhelp weight U:11.1.6 weight})
{p_end}


{marker description}{...}
{title:Description}

{pstd}
{cmd:gtoplevelsof} (alias {cmd:gtop}) displays a table with the
frequency counts, percentages, and cummulative counts and %s of the
most common levels of {varlist} that occur in the data.  It is similar
to the user-written {cmd:group} with the {opt select} otpion or to
{opt contract} after keeping only the largest frequency counts.

{pstd}
Unlike contract, it does not modify the original data and instead prints the
resulting table to the console. It also stores a matrix with the frequency
counts and stores the levels in the macro {opt r(levels)}.

{pstd}
{opt gcontract} is part of the {manhelp gtools R:gtools} project.


{marker options}{...}
{title:Options}

{dlgtab:Summary Options}

{phang}
{opth ntop(int)} Number of levels to display. This can be negative;
in that case, the smallest frequencies are displayed. Note cummulative
percentages and counts are computed within each generated table,
so for the smallest groups the table would display the cummulative
count for those frequencies, in descending order.  {opt .} displays
every level from most to least frequent; {opt -.} displays every level
from least to most frequent.

{phang}
{opth freqabove(int)} Skip frequencies below this level then determining the
largest levels. So if this is 10, only frequencies above 10 will be displayed
as part of the top frequencies.  If every frequency that would be displayed is
above this level then this option has no effect.

{phang}
{opth pctabove(real)} Skip frequencies that are a smaller percentage of the
data than {opt pctabove}. If this is 10, then only frequencies that represent
at least 10% of all observations are displayed as part of the top frequencies.
If every frequency that would be displayed is at least this percentage of the
data then this option has no effect.

{phang}
{opt mata:save}[{cmd:(}{it:str}{cmd:)}]Save results in mata object (default
name is {bf:GtoolsByLevels}). See {opt GtoolsByLevels.desc()} for more.
This object contains the raw variable levels in {opt numx} and {opt charx}
(since mata does not allow matrices of mixed-type). The levels are saved
as a string in {opt printed} (with value labels correctly applied) unless
option {opt silent} is also specified.  Last, the frequencies matrix is saved
in {opt toplevels}.

{dlgtab:Toggles}

{phang}{opt missrow} Add row with count of missing values. By default,
missing rows are treated as another group and will be displayed as part
of the top levels. With multiple variables, only rows with all values
missing are counted here unless {opt groupmissing} is also passed. If
this option is specified then a row is printed after the top levels
with the frequency count of missing rows.

{phang}{opt groupmissing} This option specifies that a missing row is a
row where any of the variables have a missing value. See {opt missrow}.

{phang}{opt nomissing} Case-wise exclude rows with missing values from
frequency count.  By default missing values are treated as another level.

{phang}{opt noother} By default a row is printed after the top levels
with the frequency count from groups not in the top levels and not
counted as missing. This option toggles display of that row.

{phang}{opt alpha} Sort the top levels of varlist by variables instead
of frequencies. Note that the top levels are still extracted; this just
affects the final sort order. To sort in inverse order, just pass
{opt gtop -var1 -var2 ...}.

{phang}{opt silent} Do not display the top levels of varlist. With
option {opt matasave} it also does not store the printed levels in a
separate string matrix.

{dlgtab:Display Options}

{phang}{opth pctfmt(format)} Print format for percentage columns.

{phang}{opth otherlabel(str)} Specify label for row with the count of the
rest of the levels.

{phang}{opth missrowlabel(str)} Specify the label for the row the count of
the "missing" levels.

{phang}{opth varabbrev(int)} Variables names are displayed above their
groups. This option specifies that variables should be abbreviated to at
most {opt varabbrev} characters. This is ignored if it is smaller than 5.

{phang}{opth colmax(numlist)} Specify width limit for levels (can be single
number of variable-specific).

{phang}{opth colstrmax(numlist)} Specify width limit for string variables (can
be single number of variable-specific). Ths overrides {opt colmax} for strings
and allows the user to specify string and number widths sepparately. (Also see
{opth numfmt(format)})

{phang}{opth numfmt(format)} Format for numeric variables. Default is {opt %.8g}
(or {opt %16.0g} with {opt matasave}). By default the number levels are formatted
in C, so this must be a valid format for the C internal {opt printf}.  The syntax
is very similar to mata's {opt printf}. Some examples are: %.2f, %10.6g, %5.0f, and
so on.  With option {opt matasave} these are formatted in mata, and the format can
be any mata number format.

{phang}{opt colseparate(separator)} Column separator; default is double blank "  ".

{phang}{opt novaluelabels} Do not replace numeric variables with their value
labels.  Value label widths are governed by colmax and NOT colstrmax.

{phang}{opt hidecontlevels} If a level is repeated in the subsequent row,
display a blank. This is only done if both observations are within the same
outer level.

{dlgtab:levelsof Options}

{phang}
{cmd:local(}{it:macname}{cmd:)} inserts the list of levels in local macro
{it:macname} within the calling program's space. Hence, that macro will
be accessible after {cmd:gtoplevelsof} has finished.  This is helpful for
subsequent use. Note this uses {opt colseparate} to sepparate columns. The
default is " " so be careful when parsing! Rows are enclosed in double quotes
(`""') so parsing is possible, just not trivial.

{phang}
{cmd:separate(}{it:separator}{cmd:)} specifies a separator
to serve as punctuation for the values of the returned list.
The default is a space.  A useful alternative is a comma.

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


{marker remarks}{...}
{title:Remarks}

{pstd}
{cmd:gtoplevelsof} has the main function of displaying the most common levels
of {it:varlist}. While {opt tab} is great, it cannot handle a large number
of levels, and it prints ALL the levels in alphabetical order.

{pstd}
Very often when exploring data I just want to have a quick look at the largest
levels of a variable that may have thousands of levels in a data set with
millions of rows. {opt gcontract} and {opt gcollapse} are great but they
modify the original data and doing a lot of subsequent preserve, sort, restore
gets very slow very fast.

{pstd}
I have found this command extremely helpful when exploring big data.
Specially if a string is not clean, then having a look at the largest
values or the largest values that match a pattern is very helpful.


{marker examples}{...}
{title:Examples}

{pstd}
See the
{browse "http://gtools.readthedocs.io/en/latest/usage/gtoplevelsof/index.html#examples":online documentation}
for more examples.

{phang}{cmd:. sysuse auto}{p_end}
{phang}{cmd:. gtoplevelsof rep78}{p_end}
{phang}{cmd:. gtoplevelsof rep78, missrow local(toplevels)}{p_end}
{phang}{cmd:. gtop rep78, colsep(", ")}{p_end}
{phang}{cmd:. gtop foreign rep78, ntop(3) missrow}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:gtoplevelsof} stores the following in {cmd:r()}:

{synoptset 15 tabbed}{...}
{p2col 5 15 19 2: Macros}{p_end}
{synopt:{cmd:r(levels)}}list of top (most common) levels (rows); not with {opt matasave}{p_end}
{synopt:{cmd:r(matalevels)}}name of GtoolsByLevels mata object; only with {opt matasave}{p_end}
{p2colreset}{...}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:r(N)    }} number of non-missing observations {p_end}
{synopt:{cmd:r(J)    }} number of groups {p_end}
{synopt:{cmd:r(minJ) }} largest group size {p_end}
{synopt:{cmd:r(maxJ) }} smallest group size {p_end}
{synopt:{cmd:r(ntop) }} number of top levels {p_end}
{synopt:{cmd:r(nrows)}} number of rows in {opt toplevels} {p_end}
{synopt:{cmd:r(alpha)}} sorted by levels intead of frequencies {p_end}
{p2colreset}{...}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Matrices}{p_end}
{synopt:{cmd:r(toplevels)}}Table with frequency counts and percentages.{p_end}
{p2colreset}{...}

{pstd} The missing and other rows are stored in the matrix with IDs 2 and 3,
respectively. With {opt matasave}, the following data is stored in {opt GtoolsByLevels}:

    real scalar anyvars
        1: any by variables; 0: no by variables

    real scalar anychar
        1: any string by variables; 0: all numeric by variables

    real scalar anynum
        1: any numeric by variables; 0: all string by variables

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

    real matrix toplevels
        frequencies of top levels; missing and other rows stored with ID 2 and 3.

{marker author}{...}
{title:Author}

{pstd}Mauricio Caceres Bravo{p_end}
{pstd}{browse "mailto:mauricio.caceres.bravo@gmail.com":mauricio.caceres.bravo@gmail.com }{p_end}
{pstd}{browse "https://mcaceresb.github.io":mcaceresb.github.io}{p_end}

{title:Website}

{pstd}{cmd:gtoplevelsof} is maintained as part of {it:gtools} at {browse "https://github.com/mcaceresb/stata-gtools":github.com/mcaceresb/stata-gtools}{p_end}

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


{title:Also see}

{p 4 13 2}
help for
{help gcontract},
{help glevelsof},
{help gtools};
{help flevelsof} (if installed),
{help ftools} (if installed)

