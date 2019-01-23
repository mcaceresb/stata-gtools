{smcl}
{* *! version 1.0.2  23Jan2019}{...}
{viewerdialog gduplicates "dialog gduplicates"}{...}
{vieweralsosee "[D] gduplicates" "mansection D gduplicates"}{...}
{viewerjumpto "Syntax" "gduplicates##syntax"}{...}
{viewerjumpto "Description" "gduplicates##description"}{...}
{viewerjumpto "Commands" "gduplicates##commands"}{...}
{viewerjumpto "Options" "gduplicates##options"}{...}
{title:Title}


{p2colset 5 23 25 2}{...}
{p2col :{cmd:gduplicates} {hline 2}}Efficiently report, tag, or drop duplicate observations using C plugins.{p_end}

{p2colreset}{...}

{pstd}
{it:Important}: Please run {stata gtools, upgrade} to update {cmd:gtools} to
the latest stable version.

{marker syntax}{...}
{title:Syntax}

{phang}
This is a fast option to Stata's {opt duplicates}.
It is XX to XX times faster in Stata/IC and XX to XX times faster in MP


{phang}
Report duplicates

{p 8 10 2}
{cmd:gduplicates} {opt r:eport} [{varlist}] {ifin} 


{phang}
List one example for each group of duplicates

{p 8 10 2}
{cmd:gduplicates} {opt e:xamples} [{varlist}] {ifin}
[{cmd:,} sorted {it:{help gduplicates##options:options}}]


{phang}
List all duplicates

{p 8 10 2}
{cmd:gduplicates} {opt l:ist} [{varlist}] {ifin}
[{cmd:,} sorted {it:{help gduplicates##options:options}}]

{pstd}
Option {opt sorted} is required to fully mimic {opt duplicates};
otherwise, {opt gduplicates} will not sort the list of examples or the
full list of duplicates. This default behavior improves performance but
may be harder to read.


{phang}
Tag duplicates

{p 8 10 2}
{cmd:gduplicates} {opt t:ag} [{varlist}] {ifin}
{cmd:,} {opth g:enerate(newvar)}


{phang}
Drop duplicates

{p 8 10 2}
{cmd:gduplicates} {opt drop} {ifin}

{p 8 10 2}
{cmd:gduplicates} {opt drop} {varlist} {ifin}
{cmd:, force}


{synoptset 23 tabbed}{...}
{marker options}{...}
{synopthdr}
{synoptline}
{syntab :Main}
{synopt :{opt c:ompress}}compress width of columns in both table and display formats{p_end}
{synopt :{opth forcestrl}}Skip binary variable check and force gtools to read strL variables.{p_end}
{synopt :{opt noc:ompress}}use display format of each variable{p_end}
{synopt :{opt fast}}synonym for {opt nocompress}; no delay in output of large datasets{p_end}
{synopt :{opt ab:breviate(#)}}abbreviate variable names to {it:#} characters; default is {cmd:ab(8)}{p_end}
{synopt :{opt str:ing(#)}}truncate string variables to {it:#} characters; default is {cmd:string(10)}{p_end}

{syntab :Options}
{synopt :{opt t:able}}force table format{p_end}
{synopt :{opt d:isplay}}force display format{p_end}
{synopt :{opt h:eader}}display variable header once; default is table mode{p_end}
{synopt :{opt noh:eader}}suppress variable header{p_end}
{synopt :{opt h:eader(#)}}display variable header every {it:#} lines{p_end}
{synopt :{opt clean}}force table format with no divider or separator lines{p_end}
{synopt :{opt div:ider}}draw divider lines between columns{p_end}
{synopt :{opt sep:arator(#)}}draw a separator line every {it:#} lines; default is {cmd:separator(5)}{p_end}
{synopt :{opth sepby(varlist)}}draw a separator line whenever {it:varlist} values change{p_end}
{synopt :{opt nol:abel}}display numeric codes rather than label values{p_end}

{syntab :Summary}
{synopt :{opt mean}[{cmd:(}{varlist}{cmd:)}]}add line reporting the mean for each of the (specified) variables{p_end}
{synopt :{opt sum}[{cmd:(}{varlist}{cmd:)}]}add line reporting the sum for each of the (specified) variables{p_end}
{synopt :{opt N}[{cmd:(}{varlist}{cmd:)}]}add line reporting the number of nonmissing values for each of the (specified) variables{p_end}
{synopt :{opth lab:var(varname)}}substitute {opt Mean}, {opt Sum}, or {opt N} for {it:varname} in last row of table{p_end}

{syntab :Advanced}
{synopt :{opt con:stant}[{cmd:(}{varlist}{cmd:)}]}separate and list variables that are constant only once{p_end}
{synopt :{opt notr:im}}suppress string trimming{p_end}
{synopt :{opt abs:olute}}display overall observation numbers when using {opt by} {varlist}{cmd::}{p_end}
{synopt :{opt nodotz}}display numerical values equal to {opt .z} as field of blanks{p_end}
{synopt :{opt subvar:name}}substitute characteristic for variable name in header{p_end}
{synopt :{opt line:size(#)}}columns per line; default is {cmd:linesize(79)}{p_end}
{synoptline}
{p2colreset}{...}



{marker description}{...}
{title:Description}

{pstd}
{opt gduplicates} is a faster alternative to {help duplicates}. It can
replicate every sub-command of {opt duplicates}; that is, it reports,
displays, lists, tags, or drops duplicate observations, depending on
the subcommand. Duplicates are observations with identical values
either on all variables if no {varlist} is specified or on a specified
{it:varlist}.

{pstd}
Note that for sub-commands {opt examples} and {opt list} the output is
{opt NOT} sorted by default. To mimic {opt duplicates} entirely, pass
option {opt sorted} when using those sub-commands.

{pstd}
{opt gduplicates} is part of the {manhelp gtools R:gtools} project.
In order to pass {opt gtools} options, use {opth gtools(str)}.

{marker commands}{...}
{title:Commands}

{pstd}
{cmd:gduplicates report} produces a table showing observations
that occur as one or more copies and indicating how many observations are
"surplus" in the sense that they are the second (third, ...) copy of the first
of each group of duplicates.

{pstd}
{cmd:gduplicates examples} lists one example for each group of
duplicated observations.  Each example represents the first occurrence of each
group in the dataset.

{pstd}
{cmd:gduplicates list} lists all duplicated observations.

{pstd}
{cmd:gduplicates tag} generates a variable representing the number of
duplicates for each observation.  This will be 0 for all
unique observations.

{pstd}
{cmd:gduplicates drop} drops all but the first occurrence of each group
of duplicated observations.  The word {opt drop} may not be abbreviated.

{pstd}
Any observations that do not satisfy specified {opt if} and/or {opt in}
conditions are ignored when you use {opt report}, {opt examples}, {opt list},
or {opt drop}.  The variable created by {opt tag} will have
missing values for such observations.


{marker options_duplicates_examples}{...}
{title:Options for duplicates examples and duplicates list}

{phang}{opt sort:ed} Sort the output list. By default the list is left
unsorted to improve performance.

{dlgtab:Main}

{phang}
{opt compress}, {opt nocompress}, {opt fast}, {opt abbreviate(#)}, 
{opt string(#)}; see {manhelp list D}.

{dlgtab:Options}

{phang}
{opt table}, {opt display}, {opt header}, {opt noheader}, {opt header(#)}, 
{opt clean}, {opt divider}, {opt separator(#)}, {opth sepby(varlist)}, 
{opt nolabel}; see {manhelp list D}.

{dlgtab:Summary}

{phang}
{opt mean}[{cmd:(}{varlist}{cmd:)}], {opt sum}[{cmd:(}{it:varlist}{cmd:)}],
{opt N}[{cmd:(}{it:varlist}{cmd:)}], {opt labvar(varname)}; see
{manhelp list D}.

{dlgtab:Advanced}

{phang}
{opt constant}[{cmd:(}{varlist}{cmd:)}], {opt notrim}, {opt absolute}, {opt nodotz}, {opt subvarname}, {opt linesize(#)}; see {manhelp list D}.


{marker option_duplicates_tag}{...}
{title:Option for duplicates tag}

{phang}
{opth generate(newvar)} is required and specifies the name of a new variable
that will tag duplicates.


{marker option_duplicates_drop}{...}
{title:Option for duplicates drop}

{phang}
{opt force} specifies that observations duplicated with respect to a named
{varlist} be dropped.  The {cmd:force} option is required when such
a {it:varlist} is given as a reminder that information may be lost by dropping
observations, given that those observations may differ on any variable
not included in {it:varlist}.


{marker examples}{...}
{title:Examples}

{pstd}
See {help duplicates##examples} or the
{browse "http://gtools.readthedocs.io/en/latest/usage/gduplicates/index.html#examples":online documentation}
for examples.


{marker author}{...}
{title:Author}

{pstd}Mauricio Caceres Bravo{p_end}
{pstd}{browse "mailto:mauricio.caceres.bravo@gmail.com":mauricio.caceres.bravo@gmail.com }{p_end}
{pstd}{browse "https://mcaceresb.github.io":mcaceresb.github.io}{p_end}


{title:Website}

{pstd}{cmd:gduplicates} is maintained as part of {manhelp gtools R:gtools} at {browse "https://github.com/mcaceresb/stata-gtools":github.com/mcaceresb/stata-gtools}{p_end}


{marker acknowledgment}{...}
{title:Acknowledgment}

{pstd}
This help file was based on StataCorp's own help file for {it:duplicates}
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
{help gduplicates}, 
{help gisid}, 
{help gtools}

