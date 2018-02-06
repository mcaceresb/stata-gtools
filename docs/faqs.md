FAQs
====

### Have weights been implemented yet?

Yes for `gcollapse`, which can match all the weight options in
`collapse`, as well as `gegen`, which can do weights for internally
impemented functions (`egen` does not take weights, so functions that
are not internally implemented cannot do weights either).

However, weights have not been implemented for `gquantiles`.

### My computer has a 32-bit CPU

This uses 128-bit hashes split into 2 64-bit parts. As far as I know, it
will not work with a 32-bit processor. If you try to force it to run,
you will see integer overflows and pretty bad errors.

### Why use platform-dependent plugins?

C is fast! When optimizing stata, there are three options:

- Mata (already implemented)
- Java plugins (I don't like Java)
- C and C++ plugins

Sergio Correia's `ftools` tests the limits of mata and achieves excellent
results, but Mata cannot compare to the raw speed a low level language like
C would afford. The only question is whether the overhead reading and writing
data to and from C compensates the speed gain, and in this case it does.

### Why no multi-threading?

Multi-threading is really difficult to support, specially because I could
not figure out a cross-platform way to implement multi-threading. Perhaps if
I had access to physical Windows and OSX hardware I would be able to do it,
but I only have access to Linux hardware. And even then the multi-threading
implementation that worked on my machine broke the plugin on older systems.

Basically my version of OpenMP, which is what I'd normally use, does not play
nice with Stata's plugin interface or with older Linux versions.  Perhaps
I will come back to multi-threading in the future, but for now only the
single-threaded version is available, and that is already a massive speedup!

### How can this be faster?

As I understand it, many of Stata's underpinnings are already compiled C
code. However, there are two explanations why this is faster than Stata's
native commands:

1. Hashing: I hash the data using a 128-bit hash and sort on this hash
   using a radix sort (a counting sort that sorts large integers X-bits
   at a time; I choose X to be 16). Sorting on a single integer is much
   faster than sorting on a collection of variables with arbitrary data.
   With a 128-bit hash you shouldn't have to worry about collisions
   (unless you're working with groups in the quintillions—that's
   10^18). Hashing here is also faster than hashing in Sergio Correia's
   `ftools`, which uses a 32-bit hash and will run into collisions just
   with levels in the thousands, so he has to resolve collisions.

2. Efficiency: While Stata's buit-in commands are not necessarily inefficient,
   the fact is many of its commands are ado files written in an add-hoc manner.
   For instance, collapse loops through each statistic, computing them in
   turn. This amounts to one individual call per statistic to `by`, which
   is slow. Similar inefficiencies are found in egen, isid, levelsof, contract,
   and so on. While they are fast enough for even modestly-sized data, when
   there are several million rows they begin to falter.

### How does hashing work?

The point of using a hash is straightforward: Sorting a single integer
variable is much faster than sorting multiple variables with arbitrary
data. In particular I use a counting sort, which asymptotically performs
in `O(n)` time compared to `O(n log n)` for the fastest general-purpose
sorting algorithms. (Note with a 128-bit algorithm using a counting sort is
prohibitively expensive; gtools commands does 4 passes of a counting
sort, each sorting 16 bits at a time; if the groups are not unique after
sorting on the first 64 bits we sort on the full 128 bits.)

Given `K` by variables, `by_1` to `by_K`, where `by_k` belongs the set `B_k`,
the general problem is to devise a function `f` such that `f:  B_1 x ... x
B_K -> N`, where `N` are the natural (whole) numbers. Given `B_k` can be
integers, floats, and strings, the natural way of doing this is to use a
hash: A function that takes an arbitrary sequence of data and outputs data of
fixed size.

In particular I use the [Spooky Hash](http://burtleburtle.net/bob/hash/spooky.html)
devised by Bob Jenkins, which is a 128-bit hash. Stata caps observations
at 20 billion or so, meaning a 128-bit hash collision is _de facto_ impossible.
Nevertheless, the code is written to fall back on native commands should
it encounter a collision.

An internal mechanism for resolving potential collisions is in the works. See
[issue 2](https://github.com/mcaceresb/stata-gtools/issues/2) for a
discussion.

### Memory management with gcollapse

C cannot create or drop variables. This creates a problem for `gcollapse` when
N is large and the number of groups J is small. For examplle, N = 100M means
about 800MiB per variable and J = 1,000 means barely 8KiB per variable. Adding
variables after the collapse is trivial and before the collapse it may take
several seconds.

The function tries to be smart about this: Variables are only created if the
source variable cannot be replaced with the target. This conserves memory and
speeds up execution time. (However, the function currently recasts unsuitably
typed source variables, which saves memory but may slow down execution time.)

If there are more targets than sources, however, there are two options:

1. Create the extra target variables in Stata before collapsing.
2. Write the extra targets, collapsed, to disk and read them back later.

Ideally I could create the variables in Stata after collapsing and read
them back from memory, but that is not possible. Hence we must choose
one of the two options above, and it is not always obvious which will be
faster.

Clearly for very large N and very small J, option 2 is faster. However,
as J grows relative to N the trade-off is not obvious. First, variables
still have to be created in Stata. So disk operations have to be faster
than (N - J) / N of the time it takes for Stata to the variables. In our
example, disk operations on 8KiB per variable should be instantaneous
and will almost surely be faster than operations on 720MiB per variable
in memory.

But what if J is 10M? Is operating on ~80MiB on disk faster than ~720MiB
on memory? The answer may well be no. What if J = 50M? Then the answer
is almost surely no. For this reason, the code tries to benchmark how
long it will take to collapse to disk and read back the data from disk
versus creating the variables in memory and simply collapsing to memory.

This has a small overhead, so `gcollapse` will only try the swtich when
there are at least 4 additional targets to create. In testing, the
overhead has been ~10% of the total runtime. If the user expects J to be
large, they can turn off this check via `forcemem`. If the user expects
J to be small, they can force collapsing to disk via `forceio`.

