gtools 
======

The gtools command is merely a wrapper for some high-level operations to do
with package maintenance. See the [introduction](index) for an overview of the
package and available commands.

Succintly, gtools is a Stata package that provides a fast implementation of
common group commands like collapse, egen, isid, levelsof, contract, distinct,
and so on using C plugins for a massive speed improvement.

This program helps the user manage their gtools installation.

!!! tip "Important"
    Run `gtools, upgrade` to update `gtools` to the latest stable version.

Syntax
------

```stata
gtools [, options]
```

See `gtools, examples` for examples of how to use available gtools functions.

Options
-------

- `upgrade` (alias `install_latest`) Upgrades gtools to the latest github version (default is master).

- `licenses` Prints the open source projects used in `gtools`

- `verbose` With `licenses`, prints the licenses of the open source projects used in `gtools`

- `examples` (alias `showcase`) Print examples of how to use available gtools functions.

- `test[(str)]` Run unit tests, optionally specifying which tests to run.  Tests
    available are: `dependencies`, `basic_checks`, `bench_test`,
    `comparisons`, `switches`, `bench_full`.  A good set of "small" tests
    which take 10-20 minutes are `dependencies basic_checks bench_test`.  By
    default, however, the first 5 tests are run, which take 1-3h. The bulk
    of that time is from `comparisons`, which compares the results from
    gtools to that of various native counterparts under several different
    conditions. `bench_full` is not run by default because this benchmarks
    gtools against stata using modestly-sized data (millions).  Some stata
    commands are very slow under some of the benchmarks, meaning this can
    take well over a day.

- `branch(str)` Github branch to use (default is master).
