{smcl}
{* *! version 0.1.3  29Oct2017}{...}
{viewerdialog gdistinct "dialog gdistinct"}{...}
{vieweralsosee "[D] gdistinct" "mansection D gdistinct"}{...}
{viewerjumpto "Syntax" "gdistinct##syntax"}{...}
{viewerjumpto "Description" "gdistinct##description"}{...}
{viewerjumpto "Options" "gdistinct##options"}{...}
{title:Title}


{p2colset 5 18 23 2}{...}
{p2col :{cmd:gdistinct} {hline 2}}Report number(s) of distinct observations or values{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}{cmd:gdistinct} [{varlist}]
{ifin}
[{cmd:,} {opt miss:ing}
{opt a:bbrev(#)} 
{opt j:oint}
{opt min:imum(#)}
{opt max:imum(#)}
]  


{marker description}{...}
{title:Description}

{pstd}
{opt gdistinct} is a faster alternative to {help distinct}.
It displays the number of distinct observations with respect to the variables
in {varlist}. By default, each variable is considered separately so that the
number of distinct observations for each variable is reported; the number
of distinct observations is the same as the number of distinct values.
Optionally, variables can be considered jointly so that the number of distinct
groups defined by the values of variables in {it:varlist} is reported.


{p 4 4 2}By default, missing values are not counted.  {it:varlist} may
contain both numeric and string variables.  


{marker options}{...}
{title:Options}

{p 4 4 2}{cmd:missing} specifies that missing values are to be included
in counting distinct observations. 

{p 4 4 2}{opt abbrev(#)} specifies that variable names are to be
displayed abbreviated to at most {it:#} characters.  This option has no
effect with {cmd:joint}. 

{p 4 4 2}{cmd:joint} specifies that distinctness is to be determined
jointly for the variables in {it:varlist}. 

{p 4 4 2}{opt minimum(#)} specifies that numbers of distinct values are to be displayed only if they are 
equal to or greater than a specified minimum. 

{p 4 4 2}{opt maximum(#)} specifies that numbers of distinct values are to be displayed only if they are 
less than or equal to a specified maximum. 


{marker examples}{...}
{title:Examples}

{p 4 4 2}{cmd:. sysuse auto}{p_end}
{p 4 4 2}{cmd:. gdistinct} {p_end}
{p 4 4 2}{cmd:. gdistinct, max(10)} {p_end}
{p 4 4 2}{cmd:. gdistinct make-headroom}{p_end}
{p 4 4 2}{cmd:. gdistinct make-headroom, missing abbrev(6)}{p_end}
{p 4 4 2}{cmd:. gdistinct foreign rep78, joint}{p_end}
{p 4 4 2}{cmd:. gdistinct foreign rep78, joint missing}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:gdistinct} stores the following in {cmd:r()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:r(N)        }} number of non-missing observations (last variable or joint) {p_end}
{synopt:{cmd:r(J)        }} number of groups (last variable or joint) {p_end}
{synopt:{cmd:r(ndistinct)}} number of groups (last variable or joint) {p_end}
{synopt:{cmd:r(minJ)     }}largest group size (last variable or joint) {p_end}
{synopt:{cmd:r(maxJ)     }}smallest group size (last variable or joint) {p_end}
{p2colreset}{...}


{marker author}{...}
{title:Author}

{pstd}Mauricio Caceres{p_end}
{pstd}{browse "mailto:mauricio.caceres.bravo@gmail.com":mauricio.caceres.bravo@gmail.com }{p_end}
{pstd}{browse "https://mcaceresb.github.io":mcaceresb.github.io}{p_end}

{title:Website}

{pstd}{cmd:gdistinct} is maintained as part of {it:gtools} at {browse "https://github.com/mcaceresb/stata-gtools":github.com/mcaceresb/stata-gtools}{p_end}

{marker acknowledgment}{...}
{title:Acknowledgment}

{pstd}
This help file was based on the help file for {it:distinct}.
{p_end}

{pstd}
This project was largely inspired by Sergio Correia's {it:ftools}:
{browse "https://github.com/sergiocorreia/ftools"}.
{p_end}

{pstd}
The OSX version of gtools was implemented with invaluable help from @fbelotti;
see {browse "https://github.com/mcaceresb/stata-gtools/issues/11"}.
{p_end}
