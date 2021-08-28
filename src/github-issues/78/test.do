sysuse auto
gdistinct make if !strpos(make, ")")
gunique make if !strpos(make, ")")
gegen x = group(foreign) if !strpos(make, "x)")
