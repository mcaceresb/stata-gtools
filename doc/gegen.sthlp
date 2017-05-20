{smcl}
{* *! version 0.3.0 20May2017}{...}
{viewerdialog gegen "dialog gegen"}{...}
{vieweralsosee "[R] gegen" "mansection R gegen"}{...}
{viewerjumpto "Syntax" "gegen##syntax"}{...}
{viewerjumpto "Description" "gegen##description"}{...}
{viewerjumpto "Options" "gegen##options"}{...}
{title:Title}

{p2colset 5 18 23 2}{...}
{p2col :{cmd:gegen} {hline 2}}Efficient implementation of by-able egen functions using C.{p_end}
{p2colreset}{...}

{marker syntax}{...}
{title:Syntax}

{p 8 14 2}
{cmd:gegen} {dtype} {newvar} {cmd:=} {it:fcn}({it:arguments}) {ifin} 
[{cmd:,} {it:options}]

{phang}
Unlike {it:egen}, {cmd:by} is required in this case, except for {opt
tag} or {group}, as noted below.

{marker description}{...}
{title:Description}

{pstd}
Pending...

{marker example}{...}
{title:Examples}

{pstd}
Pending...

{marker author}{...}
{title:Author}

{pstd}Mauricio Caceres{p_end}
{pstd}{browse "mailto:mauricio.caceres.bravo@gmail.com":mauricio.caceres.bravo@gmail.com }{p_end}
{pstd}{browse "https://mcaceresb.github.io":mcaceresb.github.io}{p_end}

{title:Website}

{pstd}{cmd:gcollapse} is maintained as part of {it:gtools} at {browse "https://github.com/mcaceresb/stata-gtools":github.com/mcaceresb/stata-gtools}{p_end}

{marker acknowledgment}{...}
{title:Acknowledgment}

{pstd}
This project was largely inspired by Sergio Correia's {it:ftools}:
{browse "https://github.com/sergiocorreia/ftools"}.
{p_end}
