gtop  (gtoplevelsof)
====================

Quickly tabulate most common levels of a variable list.

gtop (alias for gtoplevelsof) displays a table with the frequency
counts, percentages, and cummulative counts and %s of the most common
levels of varlist that occur in the data. It is similar to the
user-written group with the select otpion or to contract after keeping
only the largest frequency counts.

Unlike contract, it does not modify the original data and instead prints the
resulting table to the console. It also stores a matrix with the frequency
counts and stores the levels in the macro `r(levels)`.

!!! tip "Important"
    Run `gtools, upgrade` to update `gtools` to the latest stable version.

Syntax
------

<p><span class="codespan"><b><u>gtop</u>levelsof</b> varlist [if] [in] [weight] [, <a href="#options">options</a> ] </p>

Instead of varlist, it is possible to specify

```stata
[+|-] varname [[+|-] varname ...]
```

Note sort order is used to break ties, so this might affect the
levels displayed.

Weights
-------

aweight, fweight, and pweight are allowed, in which case the top
levels by weight are printed (see `help weight`)

Options
-------

### Summary Options

- `ntop(int)` Number of levels to display. This can be negative;  in that
            case, the smallest frequencies are displayed. Note cummulative
            percentages and counts are computed within each generated table, so
            for the smallest groups the table would display the cummulative count
            for those frequencies, in descending order. `.` displays every level
            from most to least frequent; `-.` displays every level from least to
            most frequent.

- `freqabove(int)` Skip frequencies below this level then determining the
            largest levels. So if this is 10, only frequencies above 10 will be
            displayed as part of the top frequencies.  If every frequency that
            would be displayed is above this level then this option has no
            effect.

- `pctabove(real)` Skip frequencies that are a smaller percentage of the data
            than pctabove. If this is 10, then only frequencies that represent at
            least 10% of all observations are displayed as part of the top
            frequencies.  If every frequency that would be displayed is at least
            this percentage of the data then this option has no effect.

- `matasave[(str)]` Save results in mata object (default name is GtoolsByLevels).
            See `GtoolsByLevels.desc()` for more. This object contains the raw
            variable levels in `numx` and `charx` (since mata does not allow
            matrices of mixed-type). The levels are saved as a string in `printed`
            (with value labels correctly applied) unless option `silent` is also
            specified. Last, the frequencies matrix is saved in `toplevels`.

### Toggles

- `missrow` Add row with count of missing values. By default, missing rows
            are treated as another group and will be displayed as part of the top
            levels. With multiple variables, only rows with all values missing
            are counted here unless groupmissing is also passed. If this option
            is specified then a row is printed after the top levels with the
            frequency count of missing rows.

- `groupmissing` This option specifies that a missing row is a row where any
            of the variables have a missing value. See missrow.

- `nomissing` Case-wise exclude rows with missing values from frequency
            count.  By default missing values are treated as another level.

- `noother` By default a row is printed after the top levels with the
            frequency count from groups not in the top levels and not counted as
            missing. This option toggles display of that row.

- `nongroups` By default the number of groups comprising the
            "Other" and "Missing" rows are printed as part of the "Other" and
            "Missing" row labels (should they appear; for the missing row this
            is only printed if more than 1 missing value type is present). This 
            option toggles display of the number of groups represented.

- `alpha`   Sort the top levels of varlist by variables instead
            of frequencies. Note that the top levels are still extracted; this
            just affects the final sort order. To sort in inverse order, just
            pass `gtop -var1 -var2 ...`

- `silent`  Do not display the top levels of varlist. With option
            `matasave` it also does not store the printed levels in a
            separate string matrix.

### Display Options

- `pctfmt(format)` Print format for percentage columns.

- `otherlabel(str)` Specify label for row with the count of the rest of the
            levels.

- `missrowlabel(str)` Specify the label for the row the count of the
            "missing" levels.

- `varabbrev(int)` Variables names are displayed above their groups. This
            option specifies that variables should be abbreviated to at most
            varabbrev characters. This is ignored if it is smaller than 5.

- `colmax(numlist)` Specify width limit for levels (can be single number of
            variable-specific).

- `colstrmax(numlist)` Specify width limit for string variables (can be
            single number of variable-specific). Ths overrides colmax for strings
            and allows the user to specify string and number widths sepparately.
            (Also see numfmt(format))

- `numfmt(format)` Format for numeric variables. Default is %.8g (or `%16.0g` with
            `matasave`). By default number levels are formatted in C, so this must
            be a valid format for the C internal printf. The syntax is very similar
            to mata's printf.  Some examples are: %.2f, %10.6g, %5.0f, and so on.
            With option `matasave` these are formatted in mata, and the format can
            be any mata number format.

- `colseparate(separator)` Column separator; default is double blank " ".

- `novaluelabels` Do not replace numeric variables with their value labels.
            Value label widths are governed by colmax and NOT colstrmax.

- `hidecontlevels` If a level is repeated in the subsequent row, display a
            blank. This is only done if both observations are within the same
            outer level.

### levelsof Options

- `local(macname)` inserts the list of levels in local macro macname within
            the calling program's space. Hence, that macro will be accessible
            after gtoplevelsof has finished.  This is helpful for subsequent use.
            Note this uses colseparate to sepparate columns. The default is " "
            so be careful when parsing! Rows are enclosed in double quotes (`""')
            so parsing is possible, just not trivial.

- `separate(separator)` specifies a separator to serve as punctuation for the
            values of the returned list.  The default is a space.  A useful
            alternative is a comma.

### Gtools options

(Note: These are common to every gtools command.)

- `compress` Try to compress strL to str#. The Stata Plugin Interface has
            only limited support for strL variables. In Stata 13 and
            earlier (version 2.0) there is no support, and in Stata 14
            and later (version 3.0) there is read-only support. The user
            can try to compress strL variables using this option.

- `forcestrl` Skip binary variable check and force gtools to read strL variables
            (14 and above only). __Gtools gives incorrect results when there is
            binary data in strL variables__. This option was included because on
            some windows systems Stata detects binary data even when there is none.
            Only use this option if you are sure you do not have binary data in your
            strL variables.

- `verbose` prints some useful debugging info to the console.

- `benchmark` or `bench(level)` prints how long in seconds various parts of the
            program take to execute. Level 1 is the same as `benchmark`. Levels
            2 and 3 additionally prints benchmarks for internal plugin steps.

- `hashmethod(str)` Hash method to use. `default` automagically chooses the
            algorithm. `biject` tries to biject the inputs into the
            natural numbers. `spooky` hashes the data and then uses the
            hash.

- `oncollision(str)` How to handle collisions. A collision should never happen
            but just in case it does `gtools` will try to use native
            commands. The user can specify it throw an error instead by
            passing `oncollision(error)`.

Stored results
--------------

gtoplevelsof stores the following in r():

    Macros

        r(levels)       list of top (most common) levels (rows); not with -matasave-
        r(matalevels)   name of GtoolsByLevels mata object; only with -matasave-

    Scalars

        r(N)            number of non-missing observations
        r(J)            number of groups
        r(minJ)         largest group size
        r(maxJ)         smallest group size
        r(ntop)         number of top levels
        r(nrows)        number of rows in toplevels
        r(alpha)        sorted by levels intead of frequencies

    Matrices

        r(toplevels)    Table with frequency counts and percentages.

The missing and other rows are stored in the matrix with IDs 2 and 3,
respectively.  With `matasave`, the following data is stored in `GtoolsByLevels`:

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

Remarks
-------

gtoplevelsof has the main function of displaying the most common levels
of varlist. While tab is great, it cannot handle a large number of
levels, and it prints ALL the levels in alphabetical order.

Very often when exploring data I just want to have a quick look at the
largest levels of a variable that may have thousands of levels in a data
set with millions of rows. gcontract and gcollapse are great but they
modify the original data and doing a lot of subsequent preserve, sort,
restore gets very slow very fast.

I have found this command extremely helpful when exploring big data.
Specially if a string is not clean, then having a look at the largest
values or the largest values that match a pattern is very helpful.

Examples
--------

You can download the raw code for the examples below
[here  <img src="https://upload.wikimedia.org/wikipedia/commons/6/64/Icon_External_Link.png" width="13px"/>](https://raw.githubusercontent.com/mcaceresb/stata-gtools/master/docs/examples/gtoplevelsof.do)

```stata
. sysuse auto, clear
. sysuse auto, clear
(1978 automobile data)

. 
. gtoplevelsof rep78

   rep78 |    N  Cum   Pct (%)   Cum Pct (%) 
 --------------------------------------------
       3 |   30   30      40.5          40.5 
       4 |   18   48      24.3          64.9 
       5 |   11   59      14.9          79.7 
       2 |    8   67      10.8          90.5 
       . |    5   72       6.8          97.3 
       1 |    2   74       2.7         100.0 


. 
. gtop rep78 [fw = weight]

   rep78 |       W      Cum   Pct (%)   Cum Pct (%) 
 ---------------------------------------------------
       3 |  98,970   98,970      44.3          44.3 
       4 |  51,660  150,630      23.1          67.4 
       2 |  26,830  177,460      12.0          79.4 
       5 |  25,550  203,010      11.4          90.9 
       . |  14,230  217,240       6.4          97.2 
       1 |   6,200  223,440       2.8         100.0 


. 
. gtop rep78 [w = gear_ratio]
(analytic weights assumed)

   rep78 |     W   Cum   Pct (%)   Cum Pct (%) 
 ----------------------------------------------
       3 |  86.1  86.1      38.6          38.6 
       4 |  57.2   143      25.6          64.2 
       5 |  36.3   180      16.3          80.5 
       2 |  21.5   201       9.6          90.2 
       . |  16.1   217       7.2          97.4 
       1 |  5.81   223       2.6         100.0 


. 
. gtop rep78,   missrow

    rep78 |    N  Cum   Pct (%)   Cum Pct (%) 
 ---------------------------------------------
        3 |   30   30      40.5          40.5 
        4 |   18   48      24.3          64.9 
        5 |   11   59      14.9          79.7 
        2 |    8   67      10.8          90.5 
        1 |    2   69       2.7          93.2 
 ---------------------------------------------
  Missing |    5   74       6.8         100.0 
                                              


. 
. gtop rep78,   colsep(", ")

   rep78 |    N  Cum   Pct (%)   Cum Pct (%) 
 --------------------------------------------
       3 |   30   30      40.5          40.5 
       4 |   18   48      24.3          64.9 
       5 |   11   59      14.9          79.7 
       2 |    8   67      10.8          90.5 
       . |    5   72       6.8          97.3 
       1 |    2   74       2.7         100.0 


. 
. gtop rep78,   pctfmt(%7.3f)

   rep78 |    N  Cum   Pct (%)   Cum Pct (%) 
 --------------------------------------------
       3 |   30   30    40.541        40.541 
       4 |   18   48    24.324        64.865 
       5 |   11   59    14.865        79.730 
       2 |    8   67    10.811        90.541 
       . |    5   72     6.757        97.297 
       1 |    2   74     2.703       100.000 


. 
. gtop mpg,     numfmt(%7.3f)

                mpg |    N  Cum   Pct (%)   Cum Pct (%) 
 -------------------------------------------------------
             18.000 |    9    9      12.2          12.2 
             19.000 |    8   17      10.8          23.0 
             14.000 |    6   23       8.1          31.1 
             21.000 |    5   28       6.8          37.8 
             22.000 |    5   33       6.8          44.6 
             25.000 |    5   38       6.8          51.4 
             16.000 |    4   42       5.4          56.8 
             17.000 |    4   46       5.4          62.2 
             24.000 |    4   50       5.4          67.6 
             20.000 |    3   53       4.1          71.6 
 -------------------------------------------------------
  Other (11 groups) |   21   74      28.4         100.0 
                                                        


. 
. gtop foreign

   foreign |    N  Cum   Pct (%)   Cum Pct (%) 
 ----------------------------------------------
  Domestic |   52   52      70.3          70.3 
   Foreign |   22   74      29.7         100.0 


. 
. gtop foreign, colmax(3)

  foreign |    N  Cum   Pct (%)   Cum Pct (%) 
 ---------------------------------------------
   Dom... |   52   52      70.3          70.3 
   For... |   22   74      29.7         100.0 


. 
. gtop foreign, novaluelab

  foreign |    N  Cum   Pct (%)   Cum Pct (%) 
 ---------------------------------------------
        0 |   52   52      70.3          70.3 
        1 |   22   74      29.7         100.0 


. 
. gtop foreign rep78, ntop(4) missrow colstrmax(2)

   foreign   rep78 |    N  Cum   Pct (%)   Cum Pct (%) 
 ------------------------------------------------------
  Domestic       3 |   27   27      36.5          36.5 
  Domestic       4 |    9   36      12.2          48.6 
   Foreign       4 |    9   45      12.2          60.8 
   Foreign       5 |    9   54      12.2          73.0 
 ------------------------------------------------------
  Other (6 groups) |   20   74      27.0         100.0 
                                                       


. 
. gtop foreign rep78, ntop(4) missrow groupmiss

           foreign   rep78 |    N  Cum   Pct (%)   Cum Pct (%) 
 --------------------------------------------------------------
          Domestic       3 |   27   27      36.5          36.5 
          Domestic       4 |    9   36      12.2          48.6 
           Foreign       4 |    9   45      12.2          60.8 
           Foreign       5 |    9   54      12.2          73.0 
 --------------------------------------------------------------
  Missing (any) (2 groups) |    5   59       6.8          79.7 
          Other (4 groups) |   15   74      20.3         100.0 
                                                               


. 
. gtop foreign rep78, ntop(4) missrow groupmiss noother

           foreign   rep78 |    N  Cum   Pct (%)   Cum Pct (%) 
 --------------------------------------------------------------
          Domestic       3 |   27   27      36.5          36.5 
          Domestic       4 |    9   36      12.2          48.6 
           Foreign       4 |    9   45      12.2          60.8 
           Foreign       5 |    9   54      12.2          73.0 
 --------------------------------------------------------------
  Missing (any) (2 groups) |    5   59       6.8          79.7 
                                                               


. 
. gtop foreign rep78, cols(<<) missrow("I am missing") matrix(lvl)

   foreign<< rep78 |    N  Cum   Pct (%)   Cum Pct (%) 
 ------------------------------------------------------
  Domestic<<     3 |   27   27      36.5          36.5 
  Domestic<<     4 |    9   36      12.2          48.6 
   Foreign<<     4 |    9   45      12.2          60.8 
   Foreign<<     5 |    9   54      12.2          73.0 
  Domestic<<     2 |    8   62      10.8          83.8 
  Domestic<<     . |    4   66       5.4          89.2 
   Foreign<<     3 |    3   69       4.1          93.2 
  Domestic<<     1 |    2   71       2.7          95.9 
  Domestic<<     5 |    2   73       2.7          98.6 
   Foreign<<     . |    1   74       1.4         100.0 


. matrix list lvl

lvl[10,5]
            ID          N        Cum        Pct     PctCum
 r1          1         27         27  36.486486  36.486486
 r2          1          9         36  12.162162  48.648649
 r3          1          9         45  12.162162  60.810811
 r4          1          9         54  12.162162  72.972973
 r5          1          8         62  10.810811  83.783784
 r6          1          4         66  5.4054054  89.189189
 r7          1          3         69  4.0540541  93.243243
 r8          1          2         71  2.7027027  95.945946
 r9          1          2         73  2.7027027  98.648649
r10          1          1         74  1.3513514        100

. 
. gtop foreign rep78, mata(lvl) ntop(3)

   foreign   rep78 |    N  Cum   Pct (%)   Cum Pct (%) 
 ------------------------------------------------------
  Domestic       3 |   27   27      36.5          36.5 
  Domestic       4 |    9   36      12.2          48.6 
   Foreign       4 |    9   45      12.2          60.8 
 ------------------------------------------------------
  Other (7 groups) |   29   74      39.2         100.0 
                                                       

(note: raw levels saved in lvl; see mata lvl.desc())

. mata lvl.desc()

    lvl is a class object with group levels

        | object    |        value | description                           | 
        | --------- | ------------ | ------------------------------------- | 
        | byvars    |        1 x 2 | by variable names                     | 
        | J         |            3 | number of levels                      | 
        | knum      |            2 | # numeric by variables                | 
        | numx      | 3 x 2 matrix | numeric by var levels                 | 
        | kchar     |            0 | # of string by variables              | 
        | charx     |      [empty] | character by var levels               | 
        | map       | 1 x 1 vector | map by vars index to numx and charx   | 
        | lens      | 1 x 1 vector | if string, > 0; if numeric, <= 0      | 
        | charpos   | 1 x 1 vector | position of kth character variable    | 
        | printed   | 3 x 2 vector | formatted (printf-ed) variable levels | 
        | toplevels | 4 x 5 vector | frequencies of top levels             | 

    toplevels value key (column 1):

        1 = top level(s) frequency
        2 = missing level(s) frequency
        3 = frequency for all other levels


. mata lvl.printed
              1          2
    +-----------------------+
  1 |  Domestic          3  |
  2 |  Domestic          4  |
  3 |   Foreign          4  |
    +-----------------------+

. mata lvl.toplevels
                 1             2             3             4             5
    +-----------------------------------------------------------------------+
  1 |            1            27            27   36.48648649   36.48648649  |
  2 |            1             9            36   12.16216216   48.64864865  |
  3 |            1             9            45   12.16216216   60.81081081  |
  4 |            3            29            74   39.18918919           100  |
    +-----------------------------------------------------------------------+

```
