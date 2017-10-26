{smcl}
{* *! version 0.2.0  25Oct2017}{...}
{vieweralsosee "[P] glevelsof" "mansection P glevelsof"}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "[P] foreach" "help foreach"}{...}
{vieweralsosee "" "--"}{...}
{viewerjumpto "Syntax" "glevelsof##syntax"}{...}
{viewerjumpto "Description" "glevelsof##description"}{...}
{viewerjumpto "Options" "glevelsof##options"}{...}
{viewerjumpto "Remarks" "glevelsof##remarks"}{...}
{viewerjumpto "Stored results" "glevelsof##results"}{...}
{title:Title}

{p2colset 5 18 23 2}{...}
{p2col :{cmd:glevelsof} {hline 2}}Levels of variable using C plugins{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:glevelsof}
{varlist}
{ifin}
[{cmd:,} {it:options}]

{synoptset 21}{...}
{synopthdr}
{synoptline}
{synopt:{opt c:lean}}display string values without compound double quotes{p_end}
{synopt:{opt l:ocal(macname)}}insert the list of values in the local macro {it:macname}{p_end}
{synopt:{opt miss:ing}}include missing values of {varlist} in calculation{p_end}
{synopt:{opt silent}}Do not print the levels (useful when there are many levels){p_end}
{synopt:{opt s:eparate(separator)}}separator to serve as punctuation for the values of returned list; default is a space{p_end}
{synopt:{opt cols:eparate(separator)}}separator to serve as punctuation for the columns of returned list; default is a pipe{p_end}
{synoptline}
{p2colreset}{...}


{marker description}{...}
{title:Description}

{pstd}
{cmd:glevelsof} displays a sorted list of the distinct values of {varlist}.
It is meant to be a fast replacement of {cmd:levelsof}. Unlike {cmd:levelsof},
it can take a single variable or multiple variables.


{marker options}{...}
{title:Options}

{phang}
{cmd:clean} displays string values without compound double quotes.
By default, each distinct string value is displayed within compound double
quotes, as these are the most general delimiters.  If you know that the
string values in {varlist} do not include embedded spaces or embedded
quotes, this is an appropriate option.  {cmd:clean} 
does not affect the display of values from numeric variables.

{phang}
{cmd:local(}{it:macname}{cmd:)} inserts the list of values in
local macro {it:macname} within the calling program's space.  Hence,
that macro will be accessible after {cmd:glevelsof} has finished.
This is helpful for subsequent use, especially with {helpb foreach}.

{phang}
{cmd:missing} specifies that missing values of {varlist}
should be included in the calculation.  The default is to exclude them.

{phang}
{cmd:separate(}{it:separator}{cmd:)} specifies a separator
to serve as punctuation for the values of the returned list.
The default is a space.  A useful alternative is a comma.

{phang}
{cmd:colseparate(}{it:separator}{cmd:)} specifies a separator
to serve as punctuation for the columns of the returned list.
The default is a pipe.  Specifying a {varlist} instead of a
{varname} is only useful for double loops or for use with
{helpb gettoken}.


{marker remarks}{...}
{title:Remarks}

{pstd}
{cmd:glevelsof} serves two different functions.  First, it gives a
compact display of the distinct values of {it:varlist}.  More commonly, it is
useful when you desire to cycle through the distinct values of
{it:varlist} with (say) {cmd:foreach}; see {helpb foreach:[P] foreach}.
{cmd:glevelsof} leaves behind a list in {cmd:r(levels)} that may be used in a
subsequent command.

{pstd}
{cmd:glevelsof} may hit the {help limits} imposed by your Stata.  However,
it is typically used when the number of distinct values of
{it:varlist} is modest.


{marker examples}{...}
{title:Examples}

{phang}{cmd:. sysuse auto}

{phang}{cmd:. glevelsof rep78}{p_end}
{phang}{cmd:. display "`r(levels)'"}

{phang}{cmd:. glevelsof rep78, miss local(mylevs)}{p_end}
{phang}{cmd:. display "`mylevs'"}

{phang}{cmd:. glevelsof rep78, sep(,)}{p_end}
{phang}{cmd:. display "`r(levels)'"}

{phang}{cmd:. glevelsof foreign rep78, sep(,)}{p_end}
{phang}{cmd:. display "`r(levels)'"}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:glevelsof} stores the following in {cmd:r()}:

{synoptset 15 tabbed}{...}
{p2col 5 15 19 2: Macros}{p_end}
{synopt:{cmd:r(levels)}}list of distinct values{p_end}
{p2colreset}{...}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:r(N)   }} number of non-missing observations {p_end}
{synopt:{cmd:r(J)   }} number of groups {p_end}
{synopt:{cmd:r(minJ)}} largest group size {p_end}
{synopt:{cmd:r(maxJ)}} smallest group size {p_end}
{p2colreset}{...}


{marker author}{...}
{title:Author}

{pstd}Mauricio Caceres{p_end}
{pstd}{browse "mailto:mauricio.caceres.bravo@gmail.com":mauricio.caceres.bravo@gmail.com }{p_end}
{pstd}{browse "https://mcaceresb.github.io":mcaceresb.github.io}{p_end}

{title:Website}

{pstd}{cmd:glevelsof} is maintained as part of {it:gtools} at {browse "https://github.com/mcaceresb/stata-gtools":github.com/mcaceresb/stata-gtools}{p_end}

{marker acknowledgment}{...}
{title:Acknowledgment}

{pstd}
This help file was based on StataCorp's own help file for {it:levelsof}.
{p_end}

{pstd}
This project was largely inspired by Sergio Correia's {it:ftools}:
{browse "https://github.com/sergiocorreia/ftools"}.
{p_end}

{pstd}
The OSX version of gtools was implemented with invaluable help from @fbelotti;
see {browse "https://github.com/mcaceresb/stata-gtools/issues/11"}.
{p_end}
