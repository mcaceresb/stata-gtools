capture program drop checks_gstats
program checks_gstats
    sysuse auto, clear
    gstats winsor price, by(foreign) cuts(10 90)
    winsor2 price, by(foreign) s(w2) cuts(10 90)
    desc
    l price* foreign
    exit 12345

    gtools, upgrade branch(develop)
    clear
    set obs 1000000
    gen long id = int((_n-1) / 1000)
    gunique id
    gen double x = runiform()
    set rmsg on
    winsor2 x, by(id) s(_w1)
    gstats winsor x, by(id) s(_w2)
    desc
    assert abs(x_w1 - x_w2) < 1e-6
    exit 12345
end
