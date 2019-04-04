#!/usr/bin/env python
# -*- coding: utf-8 -*-

import matplotlib.pyplot as plt
import pandas as pd
import numpy as np
import json

# 100-900, A100, A200, A400, A700
# red
# pink
# purple
# deep purple
# indigo
# blue
# light blue
# cyan
# teal
# green
# light green
# lime
# yellow
# amber
# orange
# deep orange
# brown
# gray

# General command benchmark
# -------------------------

df = pd.read_csv('bench_v2/gisid', delim = '|')
df['ix'] = np.arange(df.shape[0])
palette = json.loads(open('material.json').read())
df[' '] = df[' '].astype('category')

plt.rc('font', family = 'inconsolata')
# color  = 'green'  # 0.7, 200, 800
# color  = 'teal'   # 0.7, 200, 800
color  = 'light blue'  # 0.8, 200, 800
light  = '200'
dark   = '800'
fsizes = [22, 24, 24, 28]
fig, ax = plt.subplots(figsize = (13.5, 16))
df[::-1].plot.barh(
    ' ',
    ['gtools', 'Stata'],
    ax = ax,
    color = [palette[color][dark], palette[color][light]],
    fontsize = fsizes[1],
    alpha = 0.8,
    width = 0.75
)
ax.legend(fontsize = fsizes[1])
fig.suptitle(
    'Stata vs gtools',
    fontsize = fsizes[-1],
    # x = 0.4100,
    y = 0.95
)
plt.figtext(
    # 0.4100, 0.9,
    0.5, 0.9,
    'Time (seconds) with 10M obs and 1,000 groups',
    fontsize = fsizes[-2],
    ha = 'center'
)
plt.figtext(
    -0.07875, 0.0125,
    '\nBenchmarks conducted on a machine with Stata for Unix 15.1/MP (8 cores), a Xeon E5 CPU'
    '\n@ 3.30GHz, and an HDD in RAID0. Source data had 4 observations and was randomly sorted.'
    '\nThe grouping variable, if applicable, was long.',
    fontsize = fsizes[0],
    ha = 'left'
)

fig.savefig(
    'quick.png',
    dpi = 300,
    bbox_inches = 'tight',
    transparent = True
)
fig.clf()
