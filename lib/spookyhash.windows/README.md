SpookyHash
==========

SpookyHash is a very fast non cryptographic hash function, [designed by Bob Jenkins](http://burtleburtle.net/bob/hash/spooky.html).

It produces well-distributed 128-bit hash values for byte arrays of any length.
It can produce 64-bit and 32-bit hash values too, at the same speed, just use the bottom n bits. Long keys hash in 3 bytes per cycle, short keys take about 1 byte per cycle, and there is a 30 cycle startup cost. Keys can be supplied in fragments.
The function allows a 128-bit seed. It's named SpookyHash because it was released on Halloween.

Centaurean's release of SpookyHash integrates support for big endian platforms and multithreading via context variables.

Branch | Linux | Windows
--- | --- | ---
Master | [![Build Status](https://travis-ci.org/centaurean/spookyhash.svg?branch=master)](https://travis-ci.org/centaurean/spookyhash) | [![Build status](https://ci.appveyor.com/api/projects/status/d3w4v68a5ws27g73/branch/master?svg=true)](https://ci.appveyor.com/project/gpnuma/spookyhash/branch/master)
Dev | [![Build Status](https://travis-ci.org/centaurean/spookyhash.svg?branch=dev)](https://travis-ci.org/centaurean/spookyhash) | [![Build status](https://ci.appveyor.com/api/projects/status/d3w4v68a5ws27g73/branch/dev?svg=true)](https://ci.appveyor.com/project/gpnuma/spookyhash/branch/dev)

Why use SpookyHash ?
--------------------

* It's fast. For short keys it's 1 byte per cycle, with a 30 cycle startup cost. For long keys, well, it would be 3 bytes per cycle, and that only occupies one core. Except you'll hit the limit of how fast uncached memory can be read, which on my home machines is less than 2 bytes per cycle.
* It's good. It achieves avalanche for 1-bit and 2-bit inputs. It works for any type of key that can be made to look like an array of bytes, or list of arrays of bytes. It takes a seed, so it can produce many different independent hashes for the same key.
* It can produce up to 128-bit results. Large systems should consider using 128-bit checksums nowadays. A library with 4 billion documents is expected to have about 1 colliding 64-bit checksum no matter how good the hash is. Libraries using 128-bit checksums should expect 1 collision once they hit 16 quintillion documents. (Due to limited hardware, I can only verify SpookyHash is as good as a good 73-bit checksum. It might be better, I can't tell.)
* When NOT to use it: if you have an opponent. This is not cryptographic. Given a message, a resourceful opponent could write a tool that would produce a modified message with the same hash as the original message. Once such a tool is written, a not-so-resourceful opponent could borrow the tool and do the same thing.
* Another case not to use it: CRCs have a nice property that you can split a message up into pieces arbitrarily, calculate the CRC all the pieces, then afterwards combine the CRCs for the pieces to find the CRC for the concatenation of all those pieces. SpookyHash can't. If you could deterministically choose what the pieces were, though, you could compute the hashes for pieces with SpookyHash (or CityHash or any other hash), then treat those hash values as the raw data, and do CRCs on top of that.

Build
-----
To build a static and dynamic library, as well as a test binary of SpookyHash on Windows, Linux or Mac OSX,

1) Download [premake 5](http://premake.github.io/) and make it available in your path

2) Run the following from the command line

    cd build
    premake5 gmake
    make

or alternatively, on windows for example :

    premake5.exe vs2013

Quick start
-----------
```C
#include "spookyhash_api.h"

void hash(void* data, size_t data_length) {
    uint64_t c, d, seed1 = 1, seed2 = 2;
    uint32_t seed32 = 3;
    
    // Direct use example
    spookyhash_128(data, data_length, &c, &d);                          // c and d now contain the resulting 128-bit hash in two uint64_t parts
    uint64_t hash64 = spookyhash_64(data, data_length, seed1);          // Produce 64-bit hash
    uint32_t hash32 = spookyhash_32(data, data_length, seed32);         // Produce 32-bit hash
    
    // Stream use example
    spookyhash_context context;                                         // Create a context variable
    spookyhash_context_init(&context, seed1, seed2);                    // Initialize the context
    spookyhash_update(&context, data, data_length);                     // Add data to hash, use this function repeatedly
    spookyhash_final(&context, &c, &d);                                 // c and d now contain the resulting 128-bit hash in two uint64_t parts
}