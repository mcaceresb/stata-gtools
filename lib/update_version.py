#!/usr/bin/env python3
# -*- coding: utf-8 -*-

from datetime import datetime
from re import search, sub, findall
from sys import argv
from os import path

import argparse
parser = argparse.ArgumentParser()
parser.add_argument('set',
                    nargs    = '*',
                    type     = str,
                    metavar  = 'SET',
                    default  = "main",
                    help     = "Sets of files to update")
parser.add_argument('--major',
                    dest     = 'major',
                    action   = 'store_true',
                    help     = "Major version",
                    required = False)
parser.add_argument('--minor',
                    dest     = 'minor',
                    action   = 'store_true',
                    help     = "Minor version",
                    required = False)
parser.add_argument('--patch',
                    dest     = 'patch',
                    action   = 'store_true',
                    help     = "Patch version",
                    required = False)
parser.add_argument('--dry-run',
                    dest     = 'dry_run',
                    action   = 'store_true',
                    help     = "Dry run",
                    required = False)
args = vars(parser.parse_args())

if not args['major'] and not args['minor'] and not args['patch']:
    print("Nothing to do.")
    exit(0)
else:
    major = int(args['major'])
    minor = int(args['minor'])
    patch = int(args['patch'])

main = [path.join("src", "gtools.pkg"),
        path.join("src", "stata.toc"),
        path.join("src", "ado", "gtools.ado"),
        path.join("doc", "gtools.sthlp"),
        path.join("src", "ado", "gcollapse.ado"),
        path.join("doc", "gcollapse.sthlp"),
        path.join("src", "ado", "gegen.ado"),
        path.join("doc", "gegen.sthlp"),
        path.join("src", "ado", "hashsort.ado"),
        path.join("doc", "hashsort.sthlp"),
        path.join("src", "ado", "gisid.ado"),
        path.join("doc", "gisid.sthlp"),
        path.join("src", "ado", "glevelsof.ado"),
        path.join("doc", "glevelsof.sthlp"),
        path.join("README.md")]
test = [path.join("src", "test", "gtools_tests.do")]
plug = [path.join("src", "plugin", "collapse", "gcollapse.c"),
        path.join("src", "plugin", "collapse", "gcollapse_multi.c"),
        path.join("src", "plugin", "egen", "gegen.c"),
        path.join("src", "plugin", "egen", "gegen_multi.c"),
        path.join("src", "plugin", "gtools.c")]

callok = False
todo   = main
if "main" in args['set']:
    callok = True

if "test" in args['set']:
    todo += test
    callok = True

if "plug" in args['set']:
    todo  += casc + cdsc
    callok = True

if "all" in args['set']:
    todo = main + test + plug
    callok = True

if not callok:
    msg = "Don't know '{0}'".format(', '.join(args['set']))
    print(msg + "; specify any of 'main, test, plug, all'.")
    print("Will ignore; updating main files only.")
else:
    print("Will update version in files:")

months = ["Jan",
          "Feb",
          "Mar",
          "Apr",
          "May",
          "Jun",
          "Jul",
          "Aug",
          "Sep",
          "Oct",
          "Nov",
          "Dec"]
remonths = "(" + '|'.join(months) + ")"

for fname in todo:
    print("\t" + fname)
    with open(fname, 'r') as fhandle:
        flines = fhandle.readlines()

    with open(fname, 'w') as fhandle:
        for line in flines:
            if search('^d.+Distribution.+(\d{8,8})', line):
                today = datetime.strftime(datetime.now(), "%Y%m%d")
                oline = sub("\d{8,8}", today, line)
                print("\t\t" + line)
                print("\t\t" + oline)
                if args['dry_run']:
                    fhandle.write(line)
                else:
                    fhandle.write(oline)

                continue

            v = search('(^v|[Vv]ersion).+(\d+\.?){3,3}', line)
            s = search('Stata version', line)
            if v and not s:
                try:
                    res = findall('(\d+)(\.| |$)', line)
                    new_major = int(res[0][0]) + major
                    new_minor = 0 if major else int(res[1][0]) + minor
                    new_patch = 0 if major or minor else int(res[2][0]) + patch
                    new = "{0}.{1}.{2}".format(new_major, new_minor, new_patch)
                    oline = sub('(\d+\.?)+', new, line, 1)
                    if search("\d+" + remonths + "\d\d+", line):
                        today_day   = datetime.strftime(datetime.now(), "%d")
                        today_month = datetime.strftime(datetime.now(), "%B")
                        today_year  = datetime.strftime(datetime.now(), "%Y")
                        today = today_day + today_month[:3] + today_year
                        oline = sub("\d+" + remonths + "\d\d+", today, oline)

                    print("\t\t" + line)
                    print("\t\t" + oline)
                    if args['dry_run']:
                        fhandle.write(line)
                    else:
                        fhandle.write(oline)
                except:
                    fhandle.write(line)
            else:
                fhandle.write(line)
