clear
set obs 8975
set seed 1729
gen double x = rnormal() * 5 + 10
expand 10
pctile double p = x, nq(500) altdef
xtile tile = x, cutpoints(p)

preserve
    contract tile
    tab _freq
restore


mata
nq = 500
N  = `=_N'
X  = st_data(., "x")
N  = rows(X)
_sort(X, 1)

quantiles = ((1::(nq - 1)) * (N + 1) / nq)
qpos_i    = floor(quantiles)
qpos_i1   = qpos_i :+ 1
qdiff     = (quantiles - qpos_i)

zeros = selectindex(qpos_i :== 0)
if ( rows(zeros) > 0 ) {
    qpos_i[zeros] = J(rows(zeros), 1, 1)
}

Ns = selectindex(qpos_i1 :== (N + 1))
if ( rows(Ns) > 0 ) {
    qpos_i1[Ns] = J(rows(Ns), 1, N)
}

X_i  = X[qpos_i]
X_i1 = X[qpos_i1]
P    = X_i :+ qdiff :* (X_i1 :- X_i)

st_addvar("double", "pmata")
st_store((1::(nq - 1)), "pmata", P)
end

xtile tmata = x, cutpoints(pmata)
preserve
    contract tmata
    tab _freq
restore


pctile double p2 = x, nq(500)
xtile tile2 = x, cutpoints(p2)

preserve
    contract tile2
    tab _freq
restore



***********************************************************************
*                             Not posted                              *
***********************************************************************

gquantiles gtile = x, xtile nq(500) altdef
preserve
    contract gtile
    tab _freq
restore


gen double perc = 100 * _n / 500 in 1/499
mata
N = `=_N'
X = st_data(., "x")
N = rows(X)
_sort(X, 1)

perc      = st_data(1::499, "perc")
quantiles = (N + 1) :* perc :/ 100
qpos_i    = floor(quantiles)
qpos_i1   = qpos_i :+ 1
qdiff     = (quantiles - qpos_i)

zeros = selectindex(qpos_i :== 0)
if ( rows(zeros) > 0 ) {
    qpos_i[zeros] = J(rows(zeros), 1, 1)
}

Ns = selectindex(qpos_i1 :== (N + 1))
if ( rows(Ns) > 0 ) {
    qpos_i1[Ns] = J(rows(Ns), 1, N)
}

X_i     = X[qpos_i]
X_i1    = X[qpos_i1]
literal = (1 :- qdiff) :* X_i :+ qdiff :* X_i1
precise = X_i :+ qdiff :* (X_i1 :- X_i)

max(abs(literal :- P))
max(abs(precise :- P))
max(abs(literal :- precise))



qprecise = round(quantiles)
rounderrors = selectindex((qprecise :* 100 :/ N) :== perc)
if ( rows(rounderrors) > 0 ) {
    precise[rounderrors] = X[qprecise[rounderrors]]
}
end





cap mata: mata drop literal_pctile_altdef()
cap mata: mata drop precise_pctile_altdef()

mata
real scalar function literal_pctile_altdef(
    string scalar varname,
    real scalar perc)
{
    N = `=_N'
    X = st_data(., varname)
    N = rows(X)
    _sort(X, 1)

    quant = (perc * (N + 1) / 100)
    qpos  = floor(quant)
    qnext = qpos == N? qpos: qpos + 1
    qdiff = (quant - qpos)
    if ( qpos  == 0 ) qpos  = 1
    return ((1 - qdiff) * X[qpos] + qdiff * X[qnext])
}

real scalar function precise_pctile_altdef(
    string scalar varname,
    real scalar perc)
{
    N = `=_N'
    X = st_data(., varname)
    N = rows(X)
    _sort(X, 1)

    quant    = (perc * (N + 1) / 100)
    qpos     = floor(quant)
    qnext    = (qpos == N)? qpos: qpos + 1
    qprecise = round(quant)
    if ( qpos  == 0 ) qpos = 1

    if ( (qprecise * 100 / N) == perc ) {
        return (X[qprecise])
    }
    else if ( X[qpos] == X[qnext] ){
        return (X[qpos])
    }
    else {
        qdiff = (quant - qpos)
        return (X[qpos] + qdiff * (X[qnext] - X[qpos]))
    }
}
end

qui {
    gen double perc          = 100 * _n / 500 in 1/499
    gen double invert_pctile = .
    gen double invert_mata1  = .
    gen double invert_mata2  = .

    forvalues i = 1 / 499 {
        _pctile x, p(`=perc[`i']') altdef
        replace invert_pctile = `=r(r1)' in `i'
        mata: st_numscalar("mata_r1", literal_pctile_altdef("x", `=perc[`i']'))
        replace invert_mata1  = `=scalar(mata_r1)' in `i'
        mata: st_numscalar("mata_r1", precise_pctile_altdef("x", `=perc[`i']'))
        replace invert_mata2  = `=scalar(mata_r1)' in `i'
    }
}

count if invert_pctile != p
count if invert_mata1  != pmata
count if invert_mata2  != pmata

foreach invert of varlist invert_* {
    disp "`invert'"
    xtile x`invert' = x, cutpoints(`invert')
    preserve
        contract x`invert'
        tab _freq
    restore
}
