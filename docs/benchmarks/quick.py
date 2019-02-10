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

# Results from ./quick.do

df = pd.DataFrame(
    [
        ['collapse\n(sum, mean)',     23.10,  1.65],
        ['collapse\n(sd, median)',    39.16,  1.39],
        ['reshape long',              100.85, 6.68],
        ['reshape wide',              110.06, 8.57],
        ['xtile\n(vs gquantiles)',    26.85,  1.25],
        ['pctile\n(vs gquantiles)',   21.82,  0.90],
        ['egen',                      32.41,  0.88],
        ['contract',                  8.25,   0.87],
        ['isid',                      44.12,  0.92],
        ['duplicates',                40.78,  1.10],
        ['levelsof',                  2.80,   0.50],
        ['distinct',                  30.24,  0.57],
        ['winsor2\n(vs gstats)',      19.93,  0.86],
    ],
    columns = [' ', 'Stata', 'gtools']
)

df = pd.DataFrame(
    [
        ['collapse\n(sum, mean)',     26.45,  4.65],
        ['collapse\n(sd, median)',    46.64,  4.29],
        ['reshape long',              124.15, 30.32],
        ['reshape wide',              190.20, 16.47],
        ['xtile\n(vs gquantiles)',    44.50,  2.06],
        ['pctile\n(vs gquantiles)',   18.28,  1.87],
        ['egen',                      29.35,  2.16],
        ['contract',                  12.20,  2.08],
        ['isid',                      58.17,  2.83],
        ['duplicates',                58.59,  3.87],
        ['levelsof',                  5.57,   1.17],
        ['distinct',                  30.99,  1.48],
        ['winsor2\n(vs gstats)',      19.31,  1.24],
    ],
    columns = [' ', 'Stata', 'gtools']
)

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
