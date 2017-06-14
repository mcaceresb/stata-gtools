#!/usr/bin/env python3
# -*- coding: utf-8 -*-

# ---------------------------------------------------------------------
# Program: build.py
# Author:  Mauricio Caceres Bravo <mauricio.caceres.bravo@gmail.com>
# Created: Tue May 16 06:12:25 EDT 2017
# Updated: Sat May 20 16:57:01 EDT 2017
# Purpose: Main build file for gtools (copies contents into ./build and
#          puts a .zip file in ./releases)

from os import makedirs, path, linesep, chdir, system, remove, rename
from shutil import copy2, which, rmtree
from sys import platform
from tempfile import gettempdir
from zipfile import ZipFile
from re import search

import argparse
parser = argparse.ArgumentParser()
parser.add_argument('--stata',
                    nargs    = 1,
                    type     = str,
                    metavar  = 'STATA',
                    default  = None,
                    required = False,
                    help     = "Path to stata executable")
parser.add_argument('--clean',
                    dest     = 'clean',
                    action   = 'store_true',
                    help     = "Clean build",
                    required = False)
parser.add_argument('--replace',
                    dest     = 'replace',
                    action   = 'store_true',
                    help     = "Replace build",
                    required = False)
args = vars(parser.parse_args())

def makedirs_safe(directory):
    try:
        makedirs(directory)
        return directory
    except OSError:
        if not path.isdir(directory):
            raise

gtools_ssc = [
    "gcollapse.ado",
    "gcollapse.sthlp",
    "gegen.ado",
    "gegen.sthlp"
]

gtools_zip = [
    "changelog.md",
    "gtools.pkg",
    "stata.toc"
] + gtools_ssc

gtools_build = gtools_zip + [
    "gtools_tests.do"
]

# Remove buld
# -----------

if args['clean']:
    print("Removing build files")
    for bfile in gtools_build:
        try:
            remove(path.join("build", bfile))
            print("\tdeleted " + bfile)
        except:
            try:
                remove(path.join("build", "gtools", bfile))
                print("\tdeleted " + bfile)
            except:
                print("\t" + bfile + " not found")

    rc = system("make clean")
    exit(0)

makedirs_safe(path.join("build", "gtools"))
makedirs_safe("releases")

# Stata executable
# ----------------

# I don't have stata on my global path, so to make the script portable
# I make it look for my local executable when Stata is not found.
if args['stata'] is not None:
    statadir = path.abspath(".")
    stataexe = args['stata']
    statado  = stataexe + " -b do"
elif which("stata") is None:
    statadir = path.expanduser("~/.local/stata13")
    stataexe = path.join(statadir, "stata")
    statado  = stataexe + " -b do"
else:
    statadir = path.abspath(".")
    stataexe = 'stata'
    statado  = stataexe + " -b do"

# Temporary files
# ---------------

maindir   = path.dirname(path.realpath(__file__))
tmpdir    = gettempdir()
tmpupdate = path.join(tmpdir, ".update_gtools.do")

# Compile plugin files
# --------------------

if platform in ["linux", "linux2", "win32", "cygwin", "darwin"]:
    print("Trying to compile plugins for -gtools-")
    rc = system("make")
    print("Success!" if rc == 0 else "Failed.")
else:
    print("Don't know platform '{0}'; compile manually.".format(platform))
    exit(198)

print("")

# Get unit test files
# -------------------

testfile = open(path.join("src", "test", "gtools_tests.do")).readlines()
files    = [path.join("src", "test", "test_gcollapse.do"),
            path.join("src", "test", "test_gegen.do"),
            path.join("src", "test", "bench_gcollapse.do"),
            path.join("src", "test", "bench_gcollapse_fcoll.do"),
            path.join("src", "test", "bench_gcollapse_gcoll.do")]

with open(path.join("build", "gtools_tests.do"), 'w') as outfile:
    outfile.writelines(testfile[:-4])

with open(path.join("build", "gtools_tests.do"), 'a') as outfile:
    for fname in files:
        with open(fname) as infile:
            outfile.write(infile.read())

    outfile.writelines(testfile[-5:])

# Copy files to ./build
# ---------------------

gdir = path.join("build", "gtools")
copy2("changelog.md", gdir)
copy2(path.join("src", "gtools.pkg"), gdir)
copy2(path.join("src", "stata.toc"), gdir)
copy2(path.join("src", "ado", "gcollapse.ado"), gdir)
copy2(path.join("src", "ado", "gegen.ado"), gdir)
copy2(path.join("doc", "gcollapse.sthlp"), gdir)
copy2(path.join("doc", "gegen.sthlp"), gdir)

# Copy files to .zip folder in ./releases
# ---------------------------------------

# Get stata version
with open(path.join("src", "ado", "gcollapse.ado"), 'r') as f:
    line    = f.readline()
    version = search('(\d+\.?)+', line).group(0)

chdir("build")
print("Compressing build files for gtools-{0}".format(version))
if rc == 0:
    plugins = ["gtools.plugin", "gtools_multi.plugin"]
    gtools_zip += plugins
    for plug in plugins:
        rename(path.join(plug), path.join("gtools", plug))
else:
    print("WARNING: Failed to build plugins. Will exit.")
    exit(-1)

outzip = path.join(maindir, "releases", "gtools-{0}.zip".format(version))
with ZipFile(outzip, 'w') as zf:
    for zfile in gtools_zip:
        zf.write(path.join("gtools", zfile))
        print("\t" + path.join("gtools", zfile))
        rename(path.join("gtools", zfile), zfile)

chdir(maindir)
copy2(outzip, path.join("releases", "gtools-latest.zip"))
rmtree(path.join("build", "gtools"))

# Copy files to send to SSC
# -------------------------

print("")
print("Compressing build files for gtools-ssc.zip")
if rc == 0:
    gtools_ssc += plugins
else:
    print("WARNING: Failed to build plugins. Will exit.")
    exit(-1)

chdir("build")
outzip = path.join(maindir, "releases", "gtools-ssc.zip")
with ZipFile(outzip, 'w') as zf:
    for zfile in gtools_ssc:
        zf.write(zfile)
        print("\t" + zfile)

# chdir(path.join(maindir, "src"))
# with ZipFile(outzip, 'a') as zf:
#     zf.write("README")
#     print("\tREADME")

# Replace package in ~/ado/plus
# -----------------------------

chdir(maindir)
if args["replace"]:
    if which(stataexe):
        with open(tmpupdate, 'w') as f:
            f.write("global builddir {0}".format(path.join(maindir, "build")))
            f.write(linesep)
            f.write("cap net uninstall gtools")
            f.write(linesep)
            f.write("net install gtools, from($builddir)")
            f.write(linesep)

        chdir(statadir)
        system(statado + " " + tmpupdate)
        remove(tmpupdate)
        print(linesep + "Replaced gtools in ~/ado/plus")
        chdir(maindir)
