{smcl}
{* *! version 0.2.1  26Oct2017}{...}
{viewerdialog gisid "dialog gisid"}{...}
{vieweralsosee "[D] gisid" "mansection D gisid"}{...}
{viewerjumpto "Syntax" "gisid##syntax"}{...}
{viewerjumpto "Description" "gisid##description"}{...}
{viewerjumpto "Options" "gisid##options"}{...}
{title:Title}


{p2colset 5 18 23 2}{...}
{p2col :{cmd:gisid} {hline 2}}Check for unique identifiers using C plugins.{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 13 2}
{cmd:gisid}
{varlist}
{ifin}
[{cmd:,}
{opt m:issok}]


{marker description}{...}
{title:Description}

{pstd}
{opt gisid} is a faster alternative to {help isid}. It can check for an ID in
a subset of the data, but it can't do it for an external dataset or sort the data.


{marker options}{...}
{title:Options}

{phang}{opt missok} indicates that missing values are permitted in {varlist}.


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:gisid} stores the following in {cmd:r()}:

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

{pstd}{cmd:gisid} is maintained as part of {it:gtools} at {browse "https://github.com/mcaceresb/stata-gtools":github.com/mcaceresb/stata-gtools}{p_end}

{marker acknowledgment}{...}
{title:Acknowledgment}

{pstd}
This help file was based on StataCorp's own help file for {it:isid}.
{p_end}

{pstd}
This project was largely inspired by Sergio Correia's {it:ftools}:
{browse "https://github.com/sergiocorreia/ftools"}.
{p_end}

{pstd}
The OSX version of gtools was implemented with invaluable help from @fbelotti;
see {browse "https://github.com/mcaceresb/stata-gtools/issues/11"}.
{p_end}
