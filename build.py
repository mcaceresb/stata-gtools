#!/usr/bin/env python3
# -*- coding: utf-8 -*-

# ---------------------------------------------------------------------
# Program: build.py
# Author:  Mauricio Caceres Bravo <mauricio.caceres.bravo@gmail.com>
# Created: Sun Oct 15 10:26:39 EDT 2017
# Updated: Sun Dec 04 20:52:27 EST 2022
# Purpose: Main build file for gtools (copies contents into ./build and
#          puts a .zip file in ./releases)

from os import makedirs, path, linesep, chdir, system, remove, rename
from shutil import copy2, rmtree
from sys import platform
from tempfile import gettempdir
from zipfile import ZipFile
from re import search
import argparse

# ---------------------------------------------------------------------
# Aux programs

try:
    from shutil import which
except:
    def which(program):
        import os

        def is_exe(fpath):
            return path.isfile(fpath) and os.access(fpath, os.X_OK)

        fpath, fname = path.split(program)
        if fpath:
            if is_exe(program):
                return program
        else:
            for epath in os.environ["PATH"].split(os.pathsep):
                epath = epath.strip('"')
                exe_file = path.join(epath, program)
                if is_exe(exe_file):
                    return exe_file

        return None


def makedirs_safe(directory):
    try:
        makedirs(directory)
        return directory
    except OSError:
        if not path.isdir(directory):
            raise


# ---------------------------------------------------------------------
# Command line parsing

parser = argparse.ArgumentParser()
parser.add_argument('--stata',
                    nargs    = 1,
                    type     = str,
                    metavar  = 'STATA',
                    default  = None,
                    required = False,
                    help     = "Path to stata executable")
parser.add_argument('--stata-args',
                    nargs    = 1,
                    type     = str,
                    metavar  = 'STATA_ARGS',
                    default  = None,
                    required = False,
                    help     = "Arguments to pass to Stata executable")
parser.add_argument('--make-flags',
                    nargs    = 1,
                    type     = str,
                    metavar  = 'MAKE_FLAGS',
                    default  = None,
                    required = False,
                    help     = "Arguments to pass to make")
parser.add_argument('--clean',
                    dest     = 'clean',
                    action   = 'store_true',
                    help     = "Clean build",
                    required = False)
parser.add_argument('--no-compile',
                    dest     = 'no_compile',
                    action   = 'store_false',
                    help     = "do not re-compile",
                    required = False)
parser.add_argument('--replace',
                    dest     = 'replace',
                    action   = 'store_true',
                    help     = "Replace build",
                    required = False)
parser.add_argument('--test',
                    dest     = 'test',
                    action   = 'store_true',
                    help     = "Run tests",
                    required = False)
args = vars(parser.parse_args())

# ---------------------------------------------------------------------
# Relevant files

gtools_ssc = [
    "_gtools_internal.ado",
    "_gtools_internal.mata",
    "lgtools.mlib",
    "gcollapse.ado",
    "gcontract.ado",
    "gegen.ado",
    "gunique.ado",
    "gdistinct.ado",
    "glevelsof.ado",
    "gtop.ado",
    "gtoplevelsof.ado",
    "gisid.ado",
    "greshape.ado",
    "greg.ado",
    "gregress.ado",
    "givregress.ado",
    "gglm.ado",
    "gpoisson.ado",
    "gstats.ado",
    "gduplicates.ado",
    "gquantiles.ado",
    "fasterxtile.ado",
    "hashsort.ado",
    "gtools.ado",
    "gcollapse.sthlp",
    "gcontract.sthlp",
    "gegen.sthlp",
    "gunique.sthlp",
    "gdistinct.sthlp",
    "glevelsof.sthlp",
    "gtop.sthlp",
    "gtoplevelsof.sthlp",
    "gisid.sthlp",
    "greshape.sthlp",
    "greg.sthlp",
    "gregress.sthlp",
    "givregress.sthlp",
    "gglm.sthlp",
    "gstats.sthlp",
    "gstats_transform.sthlp",
    "gstats_range.sthlp",
    "gstats_moving.sthlp",
    "gstats_winsor.sthlp",
    "gstats_residualize.sthlp",
    "gstats_hdfe.sthlp",
    "gstats_tab.sthlp",
    "gstats_sum.sthlp",
    "gstats_summarize.sthlp",
    "gduplicates.sthlp",
    "gquantiles.sthlp",
    "fasterxtile.sthlp",
    "hashsort.sthlp",
    "gtools.sthlp",
]

gtools_zip = [
    "changelog.md",
    "gtools.pkg",
    "stata.toc",
] + gtools_ssc

gtools_build = gtools_zip + [
    "gtools_tests.do"
]

# ---------------------------------------------------------------------
# Run the script

# Remove buld
# -----------

rc = 0
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

    if args['no_compile']:
        rc = system("make clean SPI=2.0 SPIVER=v2")
        rc = system("make clean SPI=3.0 SPIVER=v3")

    exit(0)

makedirs_safe(path.join("build", "gtools"))
makedirs_safe("releases")

# Stata executable
# ----------------

# I don't have stata on my global path, so to make the script portable
# I make it look for my local executable when Stata is not found.
if args['stata'] is not None:
    statadir = path.abspath(".")
    stataexe = args['stata'][0]
    statargs = "-b do" if args['stata_args'] is None else args['stata_args'][0]
    statado  = '"{0}" {1}'.format(stataexe, statargs)
elif which("stata") is None:
    statadir = path.expanduser("~/.local/stata13")
    stataexe = path.join(statadir, "stata")
    statargs = "-b do" if args['stata_args'] is None else args['stata_args']
    statado  = '"{0}" {1}'.format(stataexe, statargs)
else:
    statadir = path.abspath(".")
    stataexe = 'stata'
    statargs = "-b do" if args['stata_args'] is None else args['stata_args']
    statado  = '"{0}" {1}'.format(stataexe, statargs)

# Temporary files
# ---------------

maindir   = path.dirname(path.realpath(__file__))
tmpdir    = gettempdir()
tmpfile   = path.join(tmpdir, ".compile_lgtools.do")
tmpupdate = path.join(tmpdir, ".update_gtools.do")

# Compile mlib files
# ------------------

matafiles = [path.join("src", "ado", "_gtools_internal.mata")]
with open(path.join("build", "gtools", "gtools.mata"), 'w') as outfile:
    for mfile in matafiles:
        with open(mfile) as infile:
            outfile.write(infile.read())


if which(stataexe):
    with open(tmpfile, 'w') as f:
        f.write("global maindir {0}".format(maindir))
        f.write(linesep)
        f.write("mata: mata set matastrict on")
        f.write(linesep)
        f.write("mata: mata set mataoptimize on")
        f.write(linesep)
        f.write('cd "${maindir}/build/gtools"')
        f.write(linesep)
        f.write("do gtools.mata")
        f.write(linesep)
        f.write("mata")
        f.write(linesep)
        f.write('mata mlib create lgtools, dir("${maindir}/build/gtools") replace')
        f.write(linesep)
        f.write("mata mlib add lgtools Gtools*()")
        f.write(linesep)
        f.write("end")
        f.write(linesep)

    chdir(statadir)
    system(statado + " " + tmpfile)
    print("Compiled lgtools.mlib")
    chdir(maindir)

    copy2(
        path.join("build", "gtools", "lgtools.mlib"),
        path.join("lib",   "plugin", "lgtools.mlib")
    )
else:
    copy2(
        path.join("lib",   "plugin", "lgtools.mlib"),
        path.join("build", "gtools", "lgtools.mlib")
    )

if not path.isfile(path.join("build", "gtools", "lgtools.mlib")):
    print("ERROR: Failed to compile build/gtools/lgtools.mlib")
    exit(-1)
else:
    print("Found build/gtools/lgtools.mlib")

print("")


# Compile plugin files
# --------------------

if args['no_compile']:
    if platform in ["linux", "linux2", "win32", "cygwin", "darwin"]:
        print("Trying to compile plugins for -gtools-")
        make_flags = args['make_flags'][0] if args['make_flags'] is not None else ""
        rc = system("make all SPI=2.0 SPIVER=v2 {0}".format(make_flags))
        rc = system("make all SPI=3.0 SPIVER=v3 {0}".format(make_flags))
        print("Success!" if rc == 0 else "Failed.")
    else:
        print("Don't know platform '{0}'; compile manually.".format(platform))
        exit(198)

print("")

# Get unit test files
# -------------------

testfile = open(path.join("src", "test", "gtools_tests.do")).readlines()
files    = [path.join("src", "test", "test_gcollapse.do"),
            path.join("src", "test", "test_gcontract.do"),
            path.join("src", "test", "test_gquantiles.do"),
            path.join("src", "test", "test_gquantiles_by.do"),
            path.join("src", "test", "test_gegen.do"),
            path.join("src", "test", "test_gunique.do"),
            path.join("src", "test", "test_glevelsof.do"),
            path.join("src", "test", "test_gtoplevelsof.do"),
            path.join("src", "test", "test_gisid.do"),
            path.join("src", "test", "test_greshape.do"),
            path.join("src", "test", "test_gregress.do"),
            path.join("src", "test", "test_gstats.do"),
            path.join("src", "test", "test_gduplicates.do"),
            path.join("src", "test", "test_hashsort.do")]

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

copy2(path.join("src", "gtools.pkg"),         gdir)
copy2(path.join("src", "stata.toc"),          gdir)

copy2(
    path.join("docs", "stata", "gtoplevelsof.sthlp"),
    path.join("docs", "stata", "gtop.sthlp")
)

copy2(
    path.join("docs", "stata", "gstats_hdfe.sthlp"),
    path.join("docs", "stata", "gstats_residualize.sthlp")
)

copy2(
    path.join("docs", "stata", "gquantiles.sthlp"),
    path.join("docs", "stata", "fasterxtile.sthlp")
)

copy2(
    path.join("docs", "stata", "gregress.sthlp"),
    path.join("docs", "stata", "greg.sthlp")
)

copy2(
    path.join("docs", "stata", "gstats_summarize.sthlp"),
    path.join("docs", "stata", "gstats_sum.sthlp")
)

copy2(
    path.join("docs", "stata", "gstats_summarize.sthlp"),
    path.join("docs", "stata", "gstats_tab.sthlp")
)

copy2(
    path.join("docs", "stata", "gstats_transform.sthlp"),
    path.join("docs", "stata", "gstats_range.sthlp")
)

copy2(
    path.join("docs", "stata", "gstats_transform.sthlp"),
    path.join("docs", "stata", "gstats_moving.sthlp")
)

copy2(path.join("docs", "stata", "gcollapse.sthlp"),          gdir)
copy2(path.join("docs", "stata", "gcontract.sthlp"),          gdir)
copy2(path.join("docs", "stata", "gegen.sthlp"),              gdir)
copy2(path.join("docs", "stata", "gunique.sthlp"),            gdir)
copy2(path.join("docs", "stata", "gdistinct.sthlp"),          gdir)
copy2(path.join("docs", "stata", "glevelsof.sthlp"),          gdir)
copy2(path.join("docs", "stata", "gtop.sthlp"),               gdir)
copy2(path.join("docs", "stata", "gtoplevelsof.sthlp"),       gdir)
copy2(path.join("docs", "stata", "gisid.sthlp"),              gdir)
copy2(path.join("docs", "stata", "greshape.sthlp"),           gdir)
copy2(path.join("docs", "stata", "greg.sthlp"),               gdir)
copy2(path.join("docs", "stata", "gregress.sthlp"),           gdir)
copy2(path.join("docs", "stata", "givregress.sthlp"),         gdir)
copy2(path.join("docs", "stata", "gglm.sthlp"),               gdir)
copy2(path.join("docs", "stata", "gstats.sthlp"),             gdir)
copy2(path.join("docs", "stata", "gstats_transform.sthlp"),   gdir)
copy2(path.join("docs", "stata", "gstats_range.sthlp"),       gdir)
copy2(path.join("docs", "stata", "gstats_moving.sthlp"),      gdir)
copy2(path.join("docs", "stata", "gstats_winsor.sthlp"),      gdir)
copy2(path.join("docs", "stata", "gstats_residualize.sthlp"), gdir)
copy2(path.join("docs", "stata", "gstats_hdfe.sthlp"),        gdir)
copy2(path.join("docs", "stata", "gstats_summarize.sthlp"),   gdir)
copy2(path.join("docs", "stata", "gstats_sum.sthlp"),         gdir)
copy2(path.join("docs", "stata", "gstats_tab.sthlp"),         gdir)
copy2(path.join("docs", "stata", "gduplicates.sthlp"),        gdir)
copy2(path.join("docs", "stata", "gquantiles.sthlp"),         gdir)
copy2(path.join("docs", "stata", "fasterxtile.sthlp"),        gdir)
copy2(path.join("docs", "stata", "hashsort.sthlp"),           gdir)
copy2(path.join("docs", "stata", "gtools.sthlp"),             gdir)

copy2(path.join("src", "ado", "_gtools_internal.ado"),  gdir)
copy2(path.join("src", "ado", "_gtools_internal.mata"), gdir)
copy2(path.join("src", "ado", "gcollapse.ado"),         gdir)
copy2(path.join("src", "ado", "gcontract.ado"),         gdir)
copy2(path.join("src", "ado", "gegen.ado"),             gdir)
copy2(path.join("src", "ado", "gunique.ado"),           gdir)
copy2(path.join("src", "ado", "gdistinct.ado"),         gdir)
copy2(path.join("src", "ado", "glevelsof.ado"),         gdir)
copy2(path.join("src", "ado", "gtop.ado"),              gdir)
copy2(path.join("src", "ado", "gtoplevelsof.ado"),      gdir)
copy2(path.join("src", "ado", "gisid.ado"),             gdir)
copy2(path.join("src", "ado", "greshape.ado"),          gdir)
copy2(path.join("src", "ado", "greg.ado"),              gdir)
copy2(path.join("src", "ado", "gregress.ado"),          gdir)
copy2(path.join("src", "ado", "givregress.ado"),        gdir)
copy2(path.join("src", "ado", "gglm.ado"),              gdir)
copy2(path.join("src", "ado", "gpoisson.ado"),          gdir)
copy2(path.join("src", "ado", "gstats.ado"),            gdir)
copy2(path.join("src", "ado", "gduplicates.ado"),       gdir)
copy2(path.join("src", "ado", "gquantiles.ado"),        gdir)
copy2(path.join("src", "ado", "fasterxtile.ado"),       gdir)
copy2(path.join("src", "ado", "hashsort.ado"),          gdir)
copy2(path.join("src", "ado", "gtools.ado"),            gdir)

# Copy files to .zip folder in ./releases
# ---------------------------------------

# Get stata version
with open(path.join("src", "ado", "gtools.ado"), 'r') as f:
    line    = f.readline()
    version = search('(\d+\.?)+', line).group(0)

plugins = [
    "gtools_unix_v2.plugin",
    "gtools_windows_v2.plugin",
    "gtools_macosx_v2.plugin",
    "gtools_unix_v3.plugin",
    "gtools_windows_v3.plugin",
    "gtools_macosx_v3.plugin"
]

plugbak = plugins[:]
for plug in plugbak:
    if not path.isfile(path.join("build", plug)):
        alt = path.join("lib", "plugin", plug)
        if path.isfile(alt):
            copy2(alt, "build")
        else:
            print("Could not find '{0}'".format(plug))

chdir("build")
print("Compressing build files for gtools-{0}".format(version))
if rc == 0:
    gtools_anyplug = False
    for plug in plugbak:
        if path.isfile(plug):
            gtools_anyplug = True
            rename(path.join(plug), path.join("gtools", plug))
        else:
            plugins.remove(plug)
            print("\t'{0}' not found; skipping.".format(plug))

    if not gtools_anyplug:
        print("WARNING: Could not find plugins despite build exit with 0 status.")
        exit(-1)

    gtools_zip += plugins
else:
    print("WARNING: Failed to build plugins. Will exit.")
    exit(-1)

outzip = path.join(maindir, "releases", "gtools-latest.zip".format(version))
with ZipFile(outzip, 'w') as zf:
    for zfile in gtools_zip:
        zf.write(path.join("gtools", zfile))
        print("\t" + path.join("gtools", zfile))
        rename(path.join("gtools", zfile), zfile)

chdir(maindir)
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
            f.write("net install gtools, from($builddir) replace")
            f.write(linesep)

        chdir(statadir)
        system(statado + " " + tmpupdate)
        remove(tmpupdate)
        # print(linesep + "Replaced gtools in ~/ado/plus")
        chdir(maindir)
    else:
        print("Could not find Stata executable '{0}'.".format(stataexe))
        exit(-1)

# Run tests
# ---------

if args['test']:
    print("Running tests (see build/gtools_tests.log for output)")
    chdir("build")
    system(statado + " gtools_tests.do")
    chdir(maindir)
