1.0.6
-----
*June 26, 2015*

* Switched to premake 5
* Updated API definitions
* Added version information access in the API
* Added build statuses

1.0.5
-----
*May 4, 2015*

* Switched to premake as build system
* Now using builtin memory functions (memcpy, memset) when available
* Added a test executable pretty much identical to the original author's
* Disabled unaligned reads by default to avoid undefined behaviors

1.0.4
-----
*April 3, 2015*

* Removed memory allocation casts

1.0.3
-----
*March 24, 2015*

* Fixed string.h include problem
* Improved compilation switches speed-wise

1.0.2
-----
*February 6, 2015*

* Now using single Makefile

1.0.1
-----
*February 4, 2015*

* Added inlining for all functions
* Reverted to using uintN_t instead of uint_fastN_t due to bitwise shift problems
* Defined rotate function as macro
* Added makefiles

1.0.0
-----
*February 2, 2015*

* Support for big endian platforms
* Support for multi-threaded environments