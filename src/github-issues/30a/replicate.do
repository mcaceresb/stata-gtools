program test
    syntax, q(numlist)
    disp "`q'"
    if ( (`q' - 0.1234567890123456789) == 0 ) {
        display "Stuff here should be executed"
    }
    else {
        display "Stuff here should not be executed"
    }
end

produces

. test, q(0.1234567890123456789)
.1234567890123
Stuff here should not be executed

Is it possible to avoid this behavior? Naturally I am using numlist in my program because I would also be able to pass things like `q(0/10)` and so on. So, for example, the real-world problem that I had was something like this:

foreach qq of numlist `=100 * 9090 / 100001'(`=100/100001')`=100 * 9092 / 100001' {
    if ( (floor(`qq' * 99990 / 100) - `qq' * 99990 / 100) == 0 ) {
        display "Stuff here should be executed if = to 0"
    }
}

which displayes nothing. However, this is incorrect.

scalar s1 = `=100 * 9090 / 100001'
scalar s2 = `=100 * 9091 / 100001'
scalar s3 = `=100 * 9092 / 100001'

scalar comp1 = (floor(`=scalar(s1)' * 99990 / 100) - `=scalar(s1)' * 99990 / 100)
scalar comp2 = (floor(`=scalar(s2)' * 99990 / 100) - `=scalar(s2)' * 99990 / 100)
scalar comp3 = (floor(`=scalar(s3)' * 99990 / 100) - `=scalar(s3)' * 99990 / 100)

if ( `=scalar(comp1)' == 0 ) display "execute if comp1 == 0"
if ( `=scalar(comp2)' == 0 ) display "execute if comp2 == 0"
if ( `=scalar(comp3)' == 0 ) display "execute if comp3 == 0"

Which rightly shows

execute if comp2 == 0

The reason numlist fails where using scalars succeeds is because (100 * 9091 / 100001) is 9.09... repeating, and NOT 9.090909090909, which is what numlist sees (13 significant digits). We can see that:

foreach qq of numlist `=100 * 9091 / 100001' {
    disp %18.15f `qq'
}
disp %18.15f 9.090909090909
disp %18.15f (100 * 9091 / 100001)

Produces

 9.090909090908999
 9.090909090908999
 9.090909090909092

And the third number (which is the one what I want) is different from the other 2.


***********************************************************************
*                            Full problem                             *
***********************************************************************

* I have the following problem:

    scalar p = 100 * 9091 / 100001
    assert (`=scalar(p)' * 99990 / 100) == 9090

    program test
        syntax, q(numlist)
        foreach qq of numlist `q' {
            assert (`qq' * 99990 / 100) == 9090
        }
    end
    test, q(`=scalar(p)')

* The first assertion goes through fine but the second assertion gives an error. Now, I know that it is impossible to represent (100 * 9091 / 100001) in double precision exactly. The actual result is 9.090909... I handle this internally in my application and it works just fine if the inputs come from a variable.

* However, I also need to pass inputs via numlist, and in that case it fails. The reason is that the number that is passed via q(numlist) is a different number, so it makes sense that it gives a different result:

    cap program drop test
    program test
        syntax, q(numlist)
        foreach qq of numlist `q' {
            disp %20.16f `qq'
            disp %20.13f `qq' * 99990 / 100
        }
        disp "`q'"
    end
    test, q(`=scalar(p)')
    test, q(9.0909090909090917)

    cap program drop test
    program test
        syntax, q(str)
        foreach qq of local q {
            disp %20.16f `qq'
            disp %20.13f `qq' * 99990 / 100
        }
        disp "`q'"
    end
    test, q(`=scalar(p)')
    test, q(9.0909090909090917)


    scalar p = 100 * 9091 / 100001
    foreach qq of numlist `=scalar(p)' {
        disp %20.16f `qq'
        disp %20.13f `qq' * 99990 / 100
    }

    foreach qq of numlist 1.1234567890123456789 {
        disp "`qq'"
        disp `qq' - 1.1234567890123456789
    }

    foreach qq of numlist 9.0909090909090917 {
        disp "`qq'"
        disp %20.16f `qq'
        disp %20.13f `qq' * 99990 / 100
    }
    disp %20.16f `=scalar(p)'

* This produces

  9.0909090909089993
  9089.9999999999091
.         disp %20.16f `=scalar(p)'
  9.0909090909090917

* The way to approximate 9.09... repeating is 9.0909090909090917... and NOT 9.0909090909089993... We can see the latter number is the double-precision floating point approximation of 9.0909090909090, which is not what I want.

foreach qq of numlist `=scalar(p)' {
    disp %20.16f `qq'
    disp %20.13f `qq' * 99990 / 100
}

foreach qq of numlist 9.0909090909090917 {
    disp %20.16f `qq'
    disp %20.13f `qq' * 99990 / 100
}
