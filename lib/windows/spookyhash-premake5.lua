#!lua

--
-- Centaurean SpookyHash
--
-- Copyright (c) 2015, Guillaume Voirin
-- All rights reserved.
--
-- Redistribution and use in source and binary forms, with or without
-- modification, are permitted provided that the following conditions are met:
--
--     1. Redistributions of source code must retain the above copyright notice, this
--        list of conditions and the following disclaimer.
--
--     2. Redistributions in binary form must reproduce the above copyright notice,
--        this list of conditions and the following disclaimer in the documentation
--        and/or other materials provided with the distribution.
--
--     3. Neither the name of the copyright holder nor the names of its
--        contributors may be used to endorse or promote products derived from
--        this software without specific prior written permission.
--
-- THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
-- AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
-- IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
-- DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
-- FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
-- DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
-- SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
-- CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
-- OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
-- OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
--
-- 2/05/15 23:04
--

-- Submodules update
os.execute("git submodule update --init --recursive")

solution "SpookyHash"
	configurations { "Release" }
	buildoptions { "-std=c99" }
	platforms { "x86_64" }
	flags { "OptimizeSpeed", "NoFramePointer", "LinkTimeOptimization" }

	project "spookyhash-static"
		targetname ("spookyhash")
		kind "StaticLib"
		language "C"
		files {
			"../src/*.h",
			"../src/*.c"
		}

	project "spookyhash-shared"
		targetname ("spookyhash")
		kind "SharedLib"
		language "C"
		files {
			"../src/*.h",
			"../src/*.c"
		}

	project "spookyhash-test"
		kind "ConsoleApp"
		language "C"
		files {
			"../test/libs/**.h",
			"../test/libs/**.c",
			"../test/src/*.h",
			"../test/src/*.c"
		}
		links { "spookyhash-static" }
