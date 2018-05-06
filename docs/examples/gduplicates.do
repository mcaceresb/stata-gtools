* Setup
sysuse auto
keep make price mpg rep78 foreign
expand 2 in 1/2

* Report duplicates
gduplicates report

* List one example for each group of duplicated observations
sort mpg
gduplicates examples
gduplicates examples, sorted

* List all duplicated observations
gduplicates list

* Create variable dup containing the number of duplicates (0 if
* observation is unique)
gduplicates tag, generate(dup)

* List the duplicated observations
list if dup == 1

* Drop all but the first occurrence of each group of duplicated
* observations
gduplicates drop

* List all duplicated observations
gduplicates list

