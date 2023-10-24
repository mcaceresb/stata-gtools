#!/usr/bin/env python
# -*- coding: utf-8 -*-

import argparse
from datetime import datetime, date

parser = argparse.ArgumentParser()
parser.add_argument('bump',
                    nargs    = 1,
                    type     = str,
                    metavar  = 'BUMP',
                    help     = "What to bump (major, minor, patch)")
parser.add_argument('--dry',
                    dest     = 'dry',
                    action   = 'store_true',
                    help     = "Dry run (do not run)",
                    required = False)
args = vars(parser.parse_args())

# ---------------------------------------------------------------------
# Config

config_version = "1.11.4"
config_date = date(2023, 10, 24)
config_files = [
    ('lib/bumpver.py',               'config_version = "{major}.{minor}.{patch}"'),
    ('lib/bumpver.py',               'config_date = date({date:%Y, %-m, %-d})'),
    ('README.md',                    '-v{major}.{minor}.{patch}'),
    ('docs/index.md',                '-v{major}.{minor}.{patch}'),
    ('docs/index.md',                'version {major}.{minor}.{patch} {date:%d%b%Y}'),
    ('docs/stata/gtools.sthlp',      'version {major}.{minor}.{patch} {date:%d%b%Y}'),
    ('src/ado/gtools.ado',           'version {major}.{minor}.{patch} {date:%d%b%Y}'),
    ('src/ado/_gtools_internal.ado', 'version {major}.{minor}.{patch} {date:%d%b%Y}'),
    ('src/plugin/gtools.c',          'Version: {major}.{minor}.{patch}'),
    ('src/plugin/gtools.c',          '@date {date:%d %b %Y}'),
    ('src/plugin/gtools.h',          'define GTOOLS_VERSION "{major}.{minor}.{patch}"'),
    ('src/test/gtools_tests.do',     'Version: {major}.{minor}.{patch}'),
    ('src/gtools.pkg',               'v {major}.{minor}.{patch}'),
    ('src/gtools.pkg',               'd Distribution-Date: {date:%Y%m%d}'),
    ('src/stata.toc',                'v {major}.{minor}.{patch}'),
    ('.appveyor.yml',                'generic-{major}.{minor}.{patch}')
]

# ---------------------------------------------------------------------
# Bump


def main(bump, dry = False):
    args = ['major', 'minor', 'patch']
    if bump not in args:
        msg = f"'{bump}' uknown; can only bump: {', '.join(args)}"
        raise Warning(msg)

    current_kwargs, update_kwargs = bump_kwargs(bump, config_version, config_date)
    for file, string in config_files:
        bump_file(file, string, current_kwargs, update_kwargs, dry)


def bump_file(file, string, current, update, dry = False):
    find = string.format(**current)
    with open(file, 'r') as fh:
        lines = fh.readlines()
        if find not in ''.join(lines):
            print(f'WARNING: nothing to bump in {file}')

        replace = string.format(**update)
        ulines = []
        for line in lines:
            if find in line:
                print(f'{file}: {find} -> {replace}')
                ulines += [line.replace(find, replace)]
            else:
                ulines += [line]

    if not dry:
        with open(file, 'w') as fh:
            fh.write(''.join(ulines))


def bump_kwargs(bump, config_version, config_date):
    today = datetime.now()
    major, minor, patch = config_version.split('.')
    umajor, uminor, upatch = bump_sever(bump, major, minor, patch)

    current_kwargs = {
        'major': major,
        'minor': minor,
        'patch': patch,
        'date': config_date
    }

    update_kwargs = {
        'major': umajor,
        'minor': uminor,
        'patch': upatch,
        'date': today
    }

    return current_kwargs, update_kwargs


def bump_sever(bump, major, minor, patch):
    if bump == 'major':
        return str(int(major) + 1), '0', '0'
    elif bump == 'minor':
        return major, str(int(minor) + 1), '0'
    elif bump == 'patch':
        return major, minor, str(int(patch) + 1)
    else:
        return major, minor, patch


if __name__ == "__main__":
    main(args['bump'][0], args['dry'])
