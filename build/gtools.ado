*! version 1.5.1 24Mar2019 Mauricio Caceres Bravo, mauricio.caceres.bravo@gmail.com
*! Program for managing the gtools package installation

capture program drop gtools
program gtools
    version 13.1

    if ( inlist("`c(os)'", "MacOSX") | strpos("`c(machine_type)'", "Mac") ) local c_os_ macosx
    else local c_os_: di lower("`c(os)'")

    syntax, [          ///
        LICENSEs       ///
        Verbose        ///
        Install_latest ///
        Upgrade        ///
        showcase       ///
        examples       ///
        test           ///
        TESTs(str)     ///
        branch(str)    ///
    ]

    if ( `"`branch'"' == "" ) local branch master
    if !inlist(`"`branch'"', "develop", "master") {
        disp as err "{bf:Warning}: Branch `branch' is not intended for normal use."
        * exit 198
    }

    local cwd `c(pwd)'
    local github https://raw.githubusercontent.com/mcaceresb/stata-gtools/`branch'

    if ( "`licenses'" == "licenses" ) {
        disp `"gtools is {browse "https://github.com/mcaceresb/stata-gtools/blob/master/LICENSE":MIT-licensed }"'
        disp ""
        disp `"The GNU C library is GPL-licensed. See the {browse "http://www.gnu.org/licenses/":GNU lesser GPL for more details}."'
        disp ""
        disp `"The implementation of quicksort used is authored by the FreeBSD project and is BSD3-licensed."'
        disp ""
        disp `"The implementation of spookyhash used is authored by Guillaume Voirin and is {browse "https://github.com/centaurean/spookyhash/blob/master/LICENSE.md":BSD3-licensed}."'

        if ( "`verbose'" != "" ) {
            gtools_licenses
        }

        if ( `"`install_latest'`upgrade'`showcase'`examples'`test'`tests'"' == `""' ) {
            exit 0
        }
    }

    if ( ("`install_latest'" == "install_latest") | ("`upgrade'" == "upgrade") ) {
        cap net uninstall gtools
        net install gtools, from(`github'/build) replace
        if ( `"`showcase'`examples'`test'`tests'"' == `""' ) {
            exit 0
        }
    }

    if ( "`showcase'`examples'" != "" ) {
        gtools_showcase
        if ( "`test'`tests'" == "" ) {
            exit 0
        }
    }

    if ( `"`test'`tests'"' != "" ) {
        local t_hours comparisons
        local t_days  bench_full
        local t_known dependencies basic_checks comparisons switches bench_test bench_full
        local t_extra: list tests - t_known

        if ( `:list sizeof t_extra' ) {
            disp `"(uknown tests detected: `t_extra'; will try to run anyway)"'
        }

        if ( `"`tests'"' == "" ) {
            disp as txt "{bf:WARNING:} Default unit tests from branch `branch' can take several"
            disp as txt "hours. See {help gtools:help gtools} for details on unit testing."
        }
        else if ( `:list t_hours in tests' ) {
            disp as txt "{bf:WARNING:} Unit tests"
            disp as txt _n(1) "    `tests'" _n(1)
            disp as txt "from branch master can take several hours. See {help gtools:help gtools} for details."
        }
        else if ( `:list t_days in tests' ) {
            disp as txt "{bf:WARNING:} Unit tests"
            disp as txt _n(1) "    `tests'" _n(1)
            disp as txt "from branch master can take more than a day. See {help gtools:help gtools} for details."
        }
        else {
            disp as txt "{bf:Note:} Unit tests '`tests'' from branch `branch'."
        }
        disp as txt "Are you sure you want to run them? (yes/no)", _request(GTOOLS_TESTS)
        if inlist(`"${GTOOLS_TESTS}"', "y", "yes") {
            global GTOOLS_TESTS
            cap noi do `github'/build/gtools_tests.do `tests'
            exit _rc
        }
        else {
            global GTOOLS_TESTS
            exit 0
        }
    }

    display "Nothing to do. See {stata help gtools} or {stata gtools, examples} for usage. Version info:"
    which gtools
    cap noi _gtools_internal _check
    if ( _rc ) {
        disp as err "({bf:warning}: gtools_plugin internal check failed)"
    }
end

capture program drop gtools_licenses
program gtools_licenses
    disp _n(1) `"{hline 79}"'                                                                     ///
         _n(1) `"gtools license"'                                                                 ///
         _n(1) `""'                                                                               ///
         _n(1) `"MIT License"'                                                                    ///
         _n(1) `""'                                                                               ///
         _n(1) `"Copyright (c) 2017 Mauricio Caceres Bravop"'                                     ///
         _n(1) `""'                                                                               ///
         _n(1) `"Permission is hereby granted, free of charge, to any person obtaining a copy"'   ///
         _n(1) `"of this software and associated documentation files (the "Software"), to"'       ///
         _n(1) `"deal in the Software without restriction, including without limitation the"'     ///
         _n(1) `"rights to use, copy, modify, merge, publish, distribute, sublicense, and/or"'    ///
         _n(1) `"sell copies of the Software, and to permit persons to whom the Software is"'     ///
         _n(1) `"furnished to do so, subject to the following conditions:"'                       ///
         _n(1) `""'                                                                               ///
         _n(1) `"The above copyright notice and this permission notice shall be included in all"' ///
         _n(1) `"copies or substantial portions of the Software."'                                ///
         _n(1) `""'                                                                               ///
         _n(1) `"THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR"'     ///
         _n(1) `"IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,"'       ///
         _n(1) `"FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL"'        ///
         _n(1) `"THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER"'     ///
         _n(1) `"LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,"'  ///
         _n(1) `"OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE"'  ///
         _n(1) `"SOFTWARE."'                                                                      ///
         _n(1) `""'                                                                               ///
         _n(1) `"{hline 79}"'                                                                     ///
         _n(1) `"spookyhash license"'                                                             ///
         _n(1) `""'                                                                               ///
         _n(1) `"Copyright (c) 2015, Guillaume Voirin"'                                           ///
         _n(1) `""'                                                                               ///
         _n(1) `"All rights reserved."'                                                           ///
         _n(1) `""'                                                                               ///
         _n(1) `"Redistribution and use in source and binary forms, with or without"'             ///
         _n(1) `"modification, are permitted provided that the following conditions are met:"'    ///
         _n(1) `""'                                                                               ///
         _n(1) `"1. Redistributions of source code must retain the above copyright notice, this"' ///
         _n(1) `"   list of conditions and the following disclaimer."'                            ///
         _n(1) `""'                                                                               ///
         _n(1) `"2. Redistributions in binary form must reproduce the above copyright notice,"'   ///
         _n(1) `"   this list of conditions and the following disclaimer in the documentation"'   ///
         _n(1) `"   and/or other materials provided with the distribution."'                      ///
         _n(1) `""'                                                                               ///
         _n(1) `"3. Neither the name of the copyright holder nor the names of its"'               ///
         _n(1) `"   contributors may be used to endorse or promote products derived from"'        ///
         _n(1) `"   this software without specific prior written permission."'                    ///
         _n(1) `""'                                                                               ///
         _n(1) `"THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS""'    ///
         _n(1) `"AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE"'      ///
         _n(1) `"IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE"' ///
         _n(1) `"DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE"'   ///
         _n(1) `"FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL"'     ///
         _n(1) `"DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR"'     ///
         _n(1) `"SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER"'     ///
         _n(1) `"CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,"'  ///
         _n(1) `"OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE"'  ///
         _n(1) `"OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE."'           ///
         _n(1) `""'                                                                               ///
         _n(1) `"{hline 79}"'                                                                     ///
         _n(1) `"quicksort license"'                                                              ///
         _n(1) `""'                                                                               ///
         _n(1) `"Copyright (c) 1992, 1993"'                                                       ///
         _n(1) `" The Regents of the University of California.  All rights reserved."'            ///
         _n(1) `""'                                                                               ///
         _n(1) `"Redistribution and use in source and binary forms, with or without"'             ///
         _n(1) `"modification, are permitted provided that the following conditions"'             ///
         _n(1) `"are met:"'                                                                       ///
         _n(1) `"1. Redistributions of source code must retain the above copyright"'              ///
         _n(1) `"   notice, this list of conditions and the following disclaimer."'               ///
         _n(1) `"2. Redistributions in binary form must reproduce the above copyright"'           ///
         _n(1) `"   notice, this list of conditions and the following disclaimer in the"'         ///
         _n(1) `"   documentation and/or other materials provided with the distribution."'        ///
         _n(1) `"4. Neither the name of the University nor the names of its contributors"'        ///
         _n(1) `"   may be used to endorse or promote products derived from this software"'       ///
         _n(1) `"   without specific prior written permission."'                                  ///
         _n(1) `""'                                                                               ///
         _n(1) `"THIS SOFTWARE IS PROVIDED BY THE REGENTS AND CONTRIBUTORS ``AS IS'' AND"'        ///
         _n(1) `"ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE"'          ///
         _n(1) `"IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE"'     ///
         _n(1) `"ARE DISCLAIMED.  IN NO EVENT SHALL THE REGENTS OR CONTRIBUTORS BE LIABLE"'       ///
         _n(1) `"FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL"'     ///
         _n(1) `"DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS"'        ///
         _n(1) `"OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)"'          ///
         _n(1) `"HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT"'     ///
         _n(1) `"LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY"'      ///
         _n(1) `"OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF"'         ///
         _n(1) `"SUCH DAMAGE."'                                                                   ///
         _n(1) `""'                                                                               ///
         _n(1) `"{hline 79}"'                                                                     ///
         _n(1) `"GNU C library license"'                                                          ///
         _n(1) `""'                                                                               ///
         _n(1) `"                   GNU LESSER GENERAL PUBLIC LICENSE"'                           ///
         _n(1) `"                       Version 3, 29 June 2007"'                                 ///
         _n(1) `""'                                                                               ///
         _n(1) `" Copyright (C) 2007 Free Software Foundation, Inc. <https://fsf.org/>"'          ///
         _n(1) `" Everyone is permitted to copy and distribute verbatim copies"'                  ///
         _n(1) `" of this license document, but changing it is not allowed."'                     ///
         _n(1) `""'                                                                               ///
         _n(1) `""'                                                                               ///
         _n(1) `"  This version of the GNU Lesser General Public License incorporates"'           ///
         _n(1) `"the terms and conditions of version 3 of the GNU General Public"'                ///
         _n(1) `"License, supplemented by the additional permissions listed below."'              ///
         _n(1) `""'                                                                               ///
         _n(1) `"  0. Additional Definitions."'                                                   ///
         _n(1) `""'                                                                               ///
         _n(1) `"  As used herein, "this License" refers to version 3 of the GNU Lesser"'         ///
         _n(1) `"General Public License, and the "GNU GPL" refers to version 3 of the GNU"'       ///
         _n(1) `"General Public License."'                                                        ///
         _n(1) `""'                                                                               ///
         _n(1) `"  "The Library" refers to a covered work governed by this License,"'             ///
         _n(1) `"other than an Application or a Combined Work as defined below."'                 ///
         _n(1) `""'                                                                               ///
         _n(1) `"  An "Application" is any work that makes use of an interface provided"'         ///
         _n(1) `"by the Library, but which is not otherwise based on the Library."'               ///
         _n(1) `"Defining a subclass of a class defined by the Library is deemed a mode"'         ///
         _n(1) `"of using an interface provided by the Library."'                                 ///
         _n(1) `""'                                                                               ///
         _n(1) `"  A "Combined Work" is a work produced by combining or linking an"'              ///
         _n(1) `"Application with the Library.  The particular version of the Library"'           ///
         _n(1) `"with which the Combined Work was made is also called the "Linked"'               ///
         _n(1) `"Version"."'                                                                      ///
         _n(1) `""'                                                                               ///
         _n(1) `"  The "Minimal Corresponding Source" for a Combined Work means the"'             ///
         _n(1) `"Corresponding Source for the Combined Work, excluding any source code"'          ///
         _n(1) `"for portions of the Combined Work that, considered in isolation, are"'           ///
         _n(1) `"based on the Application, and not on the Linked Version."'                       ///
         _n(1) `""'                                                                               ///
         _n(1) `"  The "Corresponding Application Code" for a Combined Work means the"'           ///
         _n(1) `"object code and/or source code for the Application, including any data"'         ///
         _n(1) `"and utility programs needed for reproducing the Combined Work from the"'         ///
         _n(1) `"Application, but excluding the System Libraries of the Combined Work."'          ///
         _n(1) `""'                                                                               ///
         _n(1) `"  1. Exception to Section 3 of the GNU GPL."'                                    ///
         _n(1) `""'                                                                               ///
         _n(1) `"  You may convey a covered work under sections 3 and 4 of this License"'         ///
         _n(1) `"without being bound by section 3 of the GNU GPL."'                               ///
         _n(1) `""'                                                                               ///
         _n(1) `"  2. Conveying Modified Versions."'                                              ///
         _n(1) `""'                                                                               ///
         _n(1) `"  If you modify a copy of the Library, and, in your modifications, a"'           ///
         _n(1) `"facility refers to a function or data to be supplied by an Application"'         ///
         _n(1) `"that uses the facility (other than as an argument passed when the"'              ///
         _n(1) `"facility is invoked), then you may convey a copy of the modified"'               ///
         _n(1) `"version:"'                                                                       ///
         _n(1) `""'                                                                               ///
         _n(1) `"   a) under this License, provided that you make a good faith effort to"'        ///
         _n(1) `"   ensure that, in the event an Application does not supply the"'                ///
         _n(1) `"   function or data, the facility still operates, and performs"'                 ///
         _n(1) `"   whatever part of its purpose remains meaningful, or"'                         ///
         _n(1) `""'                                                                               ///
         _n(1) `"   b) under the GNU GPL, with none of the additional permissions of"'            ///
         _n(1) `"   this License applicable to that copy."'                                       ///
         _n(1) `""'                                                                               ///
         _n(1) `"  3. Object Code Incorporating Material from Library Header Files."'             ///
         _n(1) `""'                                                                               ///
         _n(1) `"  The object code form of an Application may incorporate material from"'         ///
         _n(1) `"a header file that is part of the Library.  You may convey such object"'         ///
         _n(1) `"code under terms of your choice, provided that, if the incorporated"'            ///
         _n(1) `"material is not limited to numerical parameters, data structure"'                ///
         _n(1) `"layouts and accessors, or small macros, inline functions and templates"'         ///
         _n(1) `"(ten or fewer lines in length), you do both of the following:"'                  ///
         _n(1) `""'                                                                               ///
         _n(1) `"   a) Give prominent notice with each copy of the object code that the"'         ///
         _n(1) `"   Library is used in it and that the Library and its use are"'                  ///
         _n(1) `"   covered by this License."'                                                    ///
         _n(1) `""'                                                                               ///
         _n(1) `"   b) Accompany the object code with a copy of the GNU GPL and this license"'    ///
         _n(1) `"   document."'                                                                   ///
         _n(1) `""'                                                                               ///
         _n(1) `"  4. Combined Works."'                                                           ///
         _n(1) `""'                                                                               ///
         _n(1) `"  You may convey a Combined Work under terms of your choice that,"'              ///
         _n(1) `"taken together, effectively do not restrict modification of the"'                ///
         _n(1) `"portions of the Library contained in the Combined Work and reverse"'             ///
         _n(1) `"engineering for debugging such modifications, if you also do each of"'           ///
         _n(1) `"the following:"'                                                                 ///
         _n(1) `""'                                                                               ///
         _n(1) `"   a) Give prominent notice with each copy of the Combined Work that"'           ///
         _n(1) `"   the Library is used in it and that the Library and its use are"'              ///
         _n(1) `"   covered by this License."'                                                    ///
         _n(1) `""'                                                                               ///
         _n(1) `"   b) Accompany the Combined Work with a copy of the GNU GPL and this license"'  ///
         _n(1) `"   document."'                                                                   ///
         _n(1) `""'                                                                               ///
         _n(1) `"   c) For a Combined Work that displays copyright notices during"'               ///
         _n(1) `"   execution, include the copyright notice for the Library among"'               ///
         _n(1) `"   these notices, as well as a reference directing the user to the"'             ///
         _n(1) `"   copies of the GNU GPL and this license document."'                            ///
         _n(1) `""'                                                                               ///
         _n(1) `"   d) Do one of the following:"'                                                 ///
         _n(1) `""'                                                                               ///
         _n(1) `"       0) Convey the Minimal Corresponding Source under the terms of this"'      ///
         _n(1) `"       License, and the Corresponding Application Code in a form"'               ///
         _n(1) `"       suitable for, and under terms that permit, the user to"'                  ///
         _n(1) `"       recombine or relink the Application with a modified version of"'          ///
         _n(1) `"       the Linked Version to produce a modified Combined Work, in the"'          ///
         _n(1) `"       manner specified by section 6 of the GNU GPL for conveying"'              ///
         _n(1) `"       Corresponding Source."'                                                   ///
         _n(1) `""'                                                                               ///
         _n(1) `"       1) Use a suitable shared library mechanism for linking with the"'         ///
         _n(1) `"       Library.  A suitable mechanism is one that (a) uses at run time"'         ///
         _n(1) `"       a copy of the Library already present on the user's computer"'            ///
         _n(1) `"       system, and (b) will operate properly with a modified version"'           ///
         _n(1) `"       of the Library that is interface-compatible with the Linked"'             ///
         _n(1) `"       Version."'                                                                ///
         _n(1) `""'                                                                               ///
         _n(1) `"   e) Provide Installation Information, but only if you would otherwise"'        ///
         _n(1) `"   be required to provide such information under section 6 of the"'              ///
         _n(1) `"   GNU GPL, and only to the extent that such information is"'                    ///
         _n(1) `"   necessary to install and execute a modified version of the"'                  ///
         _n(1) `"   Combined Work produced by recombining or relinking the"'                      ///
         _n(1) `"   Application with a modified version of the Linked Version. (If"'              ///
         _n(1) `"   you use option 4d0, the Installation Information must accompany"'             ///
         _n(1) `"   the Minimal Corresponding Source and Corresponding Application"'              ///
         _n(1) `"   Code. If you use option 4d1, you must provide the Installation"'              ///
         _n(1) `"   Information in the manner specified by section 6 of the GNU GPL"'             ///
         _n(1) `"   for conveying Corresponding Source.)"'                                        ///
         _n(1) `""'                                                                               ///
         _n(1) `"  5. Combined Libraries."'                                                       ///
         _n(1) `""'                                                                               ///
         _n(1) `"  You may place library facilities that are a work based on the"'                ///
         _n(1) `"Library side by side in a single library together with other library"'           ///
         _n(1) `"facilities that are not Applications and are not covered by this"'               ///
         _n(1) `"License, and convey such a combined library under terms of your"'                ///
         _n(1) `"choice, if you do both of the following:"'                                       ///
         _n(1) `""'                                                                               ///
         _n(1) `"   a) Accompany the combined library with a copy of the same work based"'        ///
         _n(1) `"   on the Library, uncombined with any other library facilities,"'               ///
         _n(1) `"   conveyed under the terms of this License."'                                   ///
         _n(1) `""'                                                                               ///
         _n(1) `"   b) Give prominent notice with the combined library that part of it"'          ///
         _n(1) `"   is a work based on the Library, and explaining where to find the"'            ///
         _n(1) `"   accompanying uncombined form of the same work."'                              ///
         _n(1) `""'                                                                               ///
         _n(1) `"  6. Revised Versions of the GNU Lesser General Public License."'                ///
         _n(1) `""'                                                                               ///
         _n(1) `"  The Free Software Foundation may publish revised and/or new versions"'         ///
         _n(1) `"of the GNU Lesser General Public License from time to time. Such new"'           ///
         _n(1) `"versions will be similar in spirit to the present version, but may"'             ///
         _n(1) `"differ in detail to address new problems or concerns."'                          ///
         _n(1) `""'                                                                               ///
         _n(1) `"  Each version is given a distinguishing version number. If the"'                ///
         _n(1) `"Library as you received it specifies that a certain numbered version"'           ///
         _n(1) `"of the GNU Lesser General Public License "or any later version""'                ///
         _n(1) `"applies to it, you have the option of following the terms and"'                  ///
         _n(1) `"conditions either of that published version or of any later version"'            ///
         _n(1) `"published by the Free Software Foundation. If the Library as you"'               ///
         _n(1) `"received it does not specify a version number of the GNU Lesser"'                ///
         _n(1) `"General Public License, you may choose any version of the GNU Lesser"'           ///
         _n(1) `"General Public License ever published by the Free Software Foundation."'         ///
         _n(1) `""'                                                                               ///
         _n(1) `"  If the Library as you received it specifies that a proxy can decide"'          ///
         _n(1) `"whether future versions of the GNU Lesser General Public License shall"'         ///
         _n(1) `"apply, that proxy's public statement of acceptance of any version is"'           ///
         _n(1) `"permanent authorization for you to choose that version for the"'                 ///
         _n(1) `"Library."'
end

capture program drop gtools_showcase
program gtools_showcase
    * preserve
    gtools_cmd  sysuse auto, clear

    gtools_head gstats {sum|tab} varlist [if] [in] [weight], [by(varlist) options]
    gtools_cmd  gstats sum price [pw = gear_ratio / 4]
    gtools_cmd  gstats tab price mpg, by(foreign) matasave

    gtools_head gquantiles [newvarname =] exp [if] [in] [weight], {_pctile|xtile|pctile} [options]
    gtools_cmd  gquantiles 2 * price, _pctile nq(10)
    gtools_cmd  gquantiles p10 = 2 * price, pctile nq(10)
    gtools_cmd  gquantiles x10 = 2 * price, xtile nq(10) by(rep78)
    gtools_cmd  fasterxtile xx = log(price) [w = weight], cutpoints(p10) by(foreign)

    gtools_head gstats winsor varlist [if] [in] [weight], [by(varlist) cuts(# #) options]
    gtools_cmd  gstats winsor price gear_ratio mpg, cuts(5 95) s(_w1)
    gtools_cmd  gstats winsor price gear_ratio mpg, cuts(5 95) by(foreign) s(_w2)

    gtools_head hashsort varlist, [options]
    gtools_cmd  hashsort -make
    gtools_cmd  hashsort foreign -rep78, benchmark verbose mlast

    gtools_head gegen target = stat(source) [if] [in] [weight], by(varlist) [options]
    gtools_cmd  gegen tag   = tag(foreign)
    gtools_cmd  gegen group = tag(-price make)
    gtools_cmd  gegen p2_5  = pctile(price) [w = weight], by(foreign) p(2.5)

    gtools_head gisid varlist [if] [in], [options]
    gtools_cmd  gisid make, missok
    gtools_cmd  gisid price in 1 / 2

    gtools_head gduplicates varlist [if] [in], [options gtools(gtools_options)]
    gtools_cmd  gduplicates report foreign
    gtools_cmd  gduplicates report rep78 if foreign, gtools(bench(3))

    gtools_head glevelsof varlist [if] [in], [options]
    gtools_cmd  glevelsof rep78, local(levels) sep(" | ")
    gtools_cmd  glevelsof foreign mpg if price < 4000, loc(lvl) sep(" | ") colsep(", ")
    gtools_cmd  glevelsof foreign mpg in 10 / 70, gen(uniq_) nolocal

    gtools_head gtop varlist [if] [in] [weight], [options]
    disp        "gtoplevelsof varlist [if] [in] [weight], [options]" _n(1)
    gtools_cmd  gtoplevelsof foreign rep78
    gtools_cmd  gtop foreign rep78 [w = weight], ntop(5) missrow groupmiss pctfmt(%6.4g) colmax(3)

    gtools_head gcollapse (stat) out = src [(stat) out = src ...] [if] [if] [weight], by(varlist) [options]
    gtools_cmd  gen h1 = headroom
    gtools_cmd  gen h2 = headroom
    gtools_cmd  local lbl labelformat(#stat:pretty# #sourcelabel#)
    gtools_cmd
    gtools_cmd  gcollapse (mean) mean = price (median) p50 = gear_ratio, by(make) merge v `lbl'
    disp        `"disp "\`:var label mean', \`:var label p50'""'
    gtools_cmd  gcollapse (iqr) irq? = h? (nunique) turn (p97.5) mpg, by(foreign rep78) bench(2) wild

    gtools_head gcontract varlist [if] [if] [fweight], [options]
    gtools_cmd  gcontract foreign [fw = turn], freq(f) percent(p)
    * restore

    gtools_head greshape subcommand list, i(i) j(j) [options]
    disp        "    greshape wide varlist,    i(i) j(j) [options]"
    disp        "    greshape long prefixlist, i(i) [j(j) string options]" _n(1)
    disp        "    greshape spread varlist, j(j) [options]"
    disp        "    greshape gather varlist, j(j) value(value) [options]" _n(1)

    gtools_cmd  gen j = _n
    gtools_cmd  greshape wide f p, i(foreign) j(j)
    gtools_cmd  greshape long f p, i(foreign) j(j)
    gtools_cmd
    gtools_cmd  greshape spread f p, j(j)
    gtools_cmd  greshape gather f? p?, j(j) value(fp)
end

capture program drop gtools_head
program gtools_head
    gettoken cmd _: 0
    disp _n(1) `"`cmd'"' _n(1) `"{hline `=length(`"`cmd'"')'}"' _n(2) `"`0'"' _n(1)
end

capture program drop gtools_cmd
program gtools_cmd
    disp `"`0'"'
    * disp `"{stata `0'}"'
    * `0'
    * disp ""
end

if ( inlist("`c(os)'", "MacOSX") | strpos("`c(machine_type)'", "Mac") ) local c_os_ macosx
else local c_os_: di lower("`c(os)'")

if ( `c(stata_version)' < 14.1 ) local spiver v2
else local spiver v3
