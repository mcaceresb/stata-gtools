{smcl}
{* *! version 0.1.4  29Oct2017}{...}
{viewerdialog gunique "dialog gunique"}{...}
{vieweralsosee "[D] gunique" "mansection D gunique"}{...}
{viewerjumpto "Syntax" "gunique##syntax"}{...}
{viewerjumpto "Description" "gunique##description"}{...}
{viewerjumpto "Options" "gunique##options"}{...}
{title:Title}


{p2colset 5 18 23 2}{...}
{p2col :{cmd:gunique} {hline 2}}Unique values of a variable or group of variables.{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 13 2}
{cmd:gunique}
{varlist}
{ifin}
[{cmd:,}
{opt d:etail}]


{marker description}{...}
{title:Description}

{pstd}
{opt gunique} is a faster alternative to {help unique}. It reports the number
of unique values for the {it:varlist}. 


{marker options}{...}
{title:Options}

{phang}
{opt detail} request summary statistics on the number of records which are
present for unique values of the varlist.


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:gunique} stores the following in {cmd:r()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:r(N)     }} number of non-missing observations {p_end}
{synopt:{cmd:r(J)     }} number of groups {p_end}
{synopt:{cmd:r(unique)}} number of groups {p_end}
{synopt:{cmd:r(minJ)  }}largest group size {p_end}
{synopt:{cmd:r(maxJ)  }}smallest group size {p_end}
{p2colreset}{...}


{marker author}{...}
{title:Author}

{pstd}Mauricio Caceres{p_end}
{pstd}{browse "mailto:mauricio.caceres.bravo@gmail.com":mauricio.caceres.bravo@gmail.com }{p_end}
{pstd}{browse "https://mcaceresb.github.io":mcaceresb.github.io}{p_end}

{title:Website}

{pstd}{cmd:gunique} is maintained as part of {it:gtools} at {browse "https://github.com/mcaceresb/stata-gtools":github.com/mcaceresb/stata-gtools}{p_end}

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
