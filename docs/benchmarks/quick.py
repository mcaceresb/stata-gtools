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


def main():
    df = get_benchmark_data()
    make_plot(df, 'light', 'quick.png')
    make_plot(df, 'dark', 'quickdark.png')


def get_benchmark_data():
    # Results from ./quick.do

    # SE, laptop
    df = pd.DataFrame(
        [
            ['collapse\n(sum, mean)',            2.95,  1.44],
            ['collapse\n(sd, median)',           3.98,  1.47],
            ['reshape long',                    51.25,  6.76],
            ['reshape wide',                    81.92, 17.08],
            ['xtile\n(vs gquantiles)',          22.57,  1.40],
            ['pctile\n(vs gquantiles)',         45.18,  1.07],
            ['egen',                             2.92,  1.28],
            ['contract',                         8.10,  0.96],
            ['isid',                            28.75,  1.09],
            ['duplicates',                      16.31,  1.39],
            ['levelsof',                         3.02,  0.51],
            ['distinct',                        11.99,  0.76],
            ['winsor2\n(vs gstats)',            37.74,  0.92],
            ['summ, detail\n(vs gstats)',       39.91,  1.75],
            ['tabstat, 10 groups\n(vs gstats)', 16.47,  1.23],
            ['rangestat mean\n(vs gstats)',     72.61,  4.51],
        ],
        columns = [' ', 'Stata', 'gtools']
    )

    # SE, server
    df = pd.DataFrame(
        [
            ['collapse\n(sum, mean)',            2.50,  2.15],
            ['collapse\n(sd, median)',           3.07,  2.01],
            ['reshape long',                    46.31,  8.03],
            ['reshape wide',                    90.74, 14.60],
            ['xtile\n(vs gquantiles)',          25.18,  1.38],
            ['pctile\n(vs gquantiles)',         29.71,  1.06],
            ['egen',                             3.34,  1.23],
            ['contract',                         5.05,  1.32],
            ['isid',                            29.89,  2.00],
            ['duplicates',                      11.89,  1.33],
            ['levelsof',                         4.02,  0.75],
            ['distinct',                         7.47,  0.74],
            ['winsor2\n(vs gstats)',            23.69,  1.07],
            ['summ, detail\n(vs gstats)',       21.30,  1.69],
            ['tabstat, 10 groups\n(vs gstats)', 12.48,  1.15],
            ['rangestat mean\n(vs gstats)',     81.01,  4.74],
        ],
        columns = [' ', 'Stata', 'gtools']
    )

    # MP, laptop
    df = pd.DataFrame(
        [
            ['collapse\n(sum, mean)',            1.29,  1.50],
            ['collapse\n(sd, median)',           1.34,  1.33],
            ['reshape long',                    35.53,  5.94],
            ['reshape wide',                    55.29, 12.39],
            ['xtile\n(vs gquantiles)',          19.11,  1.24],
            ['pctile\n(vs gquantiles)',         19.57,  0.86],
            ['egen',                             2.51,  0.83],
            ['contract',                         6.62,  0.87],
            ['isid',                            20.88,  0.91],
            ['duplicates',                      13.57,  1.07],
            ['levelsof',                         2.58,  0.50],
            ['distinct',                        12.40,  0.49],
            ['winsor2\n(vs gstats)',            19.02,  1.27],
            ['summ, detail\n(vs gstats)',       19.09,  1.43],
            ['tabstat, 10 groups\n(vs gstats)', 16.38,  0.86],
            ['rangestat mean\n(vs gstats)',     66.53,  3.83],
        ],
        columns = [' ', 'Stata', 'gtools']
    )

    # MP, server
    df = pd.DataFrame(
        [
            ['collapse\n(sum, mean)',            0.95,  2.26],
            ['collapse\n(sd, median)',           1.08,  2.27],
            ['reshape long',                    33.39,  8.92],
            ['reshape wide',                    71.16, 12.91],
            ['xtile\n(vs gquantiles)',          19.70,  1.36],
            ['pctile\n(vs gquantiles)',          6.71,  1.02],
            ['egen',                             3.44,  1.36],
            ['contract',                         4.21,  1.73],
            ['isid',                            22.90,  2.45],
            ['duplicates',                       9.14,  1.58],
            ['levelsof',                         4.08,  0.94],
            ['distinct',                         7.10,  1.03],
            ['winsor2\n(vs gstats)',             6.81,  0.96],
            ['summ, detail\n(vs gstats)',        7.36,  1.53],
            ['tabstat, 10 groups\n(vs gstats)', 13.60,  0.88],
            ['rangestat mean\n(vs gstats)',     71.20,  4.37],
        ],
        columns = [' ', 'Stata', 'gtools']
    )

    df['ix'] = np.arange(df.shape[0])
    df[' ']  = df[' '].astype('category')

    return df


def make_plot(df, style = 'light', outfile = 'quick.png'):
    palette = json.loads(open('material.json').read())

    if style == 'dark':
        params = {
            "ytick.color": "w",
            "xtick.color": "w",
            "axes.labelcolor": "w",
            "axes.edgecolor": "w"
        }
    else:
        params = {}

    # plt.rc('font', family = 'Inconsolata')
    plt.rc('font', family = 'Ubuntu Mono')
    plt.rcParams.update(params)

    if style == 'dark':
        color  = 'teal'
        light  = '200'
        dark   = '800'
        alpha  = 1
    else:
        # color  = 'green'  # 0.7, 200, 800
        # color  = 'teal'   # 0.7, 200, 800
        color  = 'light blue'  # 0.8, 200, 800
        light  = '200'
        dark   = '800'
        alpha  = 0.8

    fsizes = [22, 24, 24, 28]
    fig, ax = plt.subplots(figsize = (13.5, 16))
    df[::-1].plot.barh(
        ' ',
        ['gtools', 'Stata'],
        ax = ax,
        color = [palette[color][dark], palette[color][light]],
        fontsize = fsizes[1],
        alpha = alpha,
        width = 0.75
    )
    ax.legend(fontsize = fsizes[1])
    fig.suptitle(
        'Stata vs gtools',
        fontsize = fsizes[-1],
        # x = 0.4100,
        y = 0.95,
        color = 'white' if style == 'dark' else 'black'
    )
    plt.figtext(
        # 0.4100, 0.9,
        0.5, 0.9,
        'Time (seconds) with 10M obs and 1,000 groups',
        fontsize = fsizes[-2],
        ha = 'center',
        color = 'white' if style == 'dark' else 'black'
    )
    plt.figtext(
        -0.07875, 0.0125,
        '\nBenchmarks conducted on a machine with Stata for Unix 17.0/MP (8 cores), a Xeon E5 CPU'
        '\n@ 3.30GHz, and an HDD in RAID0. Source data had 4 variables and was randomly sorted.'
        '\nThe grouping variable, if applicable, was long.',
        fontsize = fsizes[0],
        ha = 'left',
        color = 'white' if style == 'dark' else 'black'
    )

    fig.savefig(
        outfile,
        dpi = 300,
        bbox_inches = 'tight',
        transparent = True
    )
    fig.clf()


if __name__ == "__main__":
    main()
