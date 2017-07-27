#!/usr/bin/env python
# -*- coding: utf-8 -*-

# -----------------------------------------------------------------------------
# Imports
# -----------------------------------------------------------------------------

from datetime import datetime
import matplotlib.pyplot as plt
from os import linesep, path
import matplotlib as mpl
import pandas as pd
import numpy as np

# -----------------------------------------------------------------------------
# Startup
# -----------------------------------------------------------------------------

pathMain = path.expanduser("~/code/stata-gtools/src/test/")
df1 = pd.read_csv(path.join(pathMain, "plots", "ftools_basic_mp.psv"),   sep = "|")
df2 = pd.read_csv(path.join(pathMain, "plots", "ftools_complex_mp.psv"), sep = "|")
df3 = pd.read_csv(path.join(pathMain, "plots", "ftools_alt_mp.psv"),     sep = "|")
df4 = pd.read_csv(path.join(pathMain, "plots", "gtools_N_mp.psv"),       sep = "|")
df5 = pd.read_csv(path.join(pathMain, "plots", "gtools_J_mp.psv"),       sep = "|")
df1["nid"] = range(1, df1.shape[0] + 1)
df2["nid"] = range(1, df2.shape[0] + 1)
df3["nid"] = range(1, df3.shape[0] + 1)
df4["nid"] = range(1, df4.shape[0] + 1)
df5["nid"] = range(1, df5.shape[0] + 1)

def comparePlot(which):
    width = 0.2
    kwargsRaw = {'linewidth': 1.5, 'alpha':0.75, 'width': width}

    fig, ax = plt.subplots(figsize = (12, 9))
    ax.bar(0 + df1.loc[which]["nid"] - width, df1.loc[which]["gcollapse"], color = "#4646ba", **kwargsRaw)
    ax.bar(0 + df1.loc[which]["nid"],         df1.loc[which]["fcollapse"], color = "#b24040", **kwargsRaw)
    ax.bar(0 + df1.loc[which]["nid"] + width, df1.loc[which]["collapse"],  color = "#45a545", **kwargsRaw)

    ax.bar(1 + df2.loc[which]["nid"] - width, df2.loc[which]["gcollapse"], color = "#4646ba", **kwargsRaw)
    ax.bar(1 + df2.loc[which]["nid"],         df2.loc[which]["fcollapse"], color = "#b24040", **kwargsRaw)
    ax.bar(1 + df2.loc[which]["nid"] + width, df2.loc[which]["collapse"],  color = "#45a545", **kwargsRaw)

    ax.bar(2 + df3.loc[which]["nid"] - width, df3.loc[which]["gcollapse"], color = "#4646ba", **kwargsRaw)
    ax.bar(2 + df3.loc[which]["nid"],         df3.loc[which]["fcollapse"], color = "#b24040", **kwargsRaw)
    ax.bar(2 + df3.loc[which]["nid"] + width, df3.loc[which]["collapse"],  color = "#45a545", **kwargsRaw)

    ax.bar(3 + df4.loc[which]["nid"] - width, df4.loc[which]["gcollapse"], color = "#4646ba", **kwargsRaw)
    ax.bar(3 + df4.loc[which]["nid"],         df4.loc[which]["fcollapse"], color = "#b24040", **kwargsRaw)
    ax.bar(3 + df4.loc[which]["nid"] + width, df4.loc[which]["collapse"],  color = "#45a545", **kwargsRaw)

    stats1 = ["J = 100", "y1-y15 ~ U(0, 1)", "sum"]
    stats2 = ["J = 100", "y1-y3 ~ U(0, 1)",  "mean median"]
    stats3 = ["J = 100", "y1-y6 ~ U(0, 1)",  "sum mean count min max"]
    stats4 = ["J = 10",  "x1 x2 ~ N(0, 1)",  "all stats"]

    ax.set_xticks([0 + df1["nid"].values[which],
                   1 + df2["nid"].values[which],
                   2 + df2["nid"].values[which],
                   3 + df2["nid"].values[which]])
    ax.xaxis.set_ticklabels([linesep.join(stats1),
                             linesep.join(stats2),
                             linesep.join(stats3),
                             linesep.join(stats4)])
    ax.margins(x = 0)

    note  = "'All stats' refers to: sum, mean, max, min, count, percent, first, last, firstnm, lastnm, median, iqr;"
    note += linesep + "in addition, p23 and p77 are also computed."
    ax.text(0, -0.19, note , ha = 'left', fontsize = 14, transform = ax.transAxes)

    figTitle = "Execution time of gcollapse vs collapse and fcollapse (N = {0})"
    fig.suptitle(figTitle.format(df1.loc[which]["N"]), fontsize = 24)

    ax.yaxis.set_label_text("Time in seconds", fontsize = 20)
    ax.grid(alpha = 0.25)

    ax.legend(["gcollapse", "fcollapse", "collapse"], fontsize = 18)

    for ticky in ax.yaxis.get_major_ticks():
        ticky.label.set_fontsize(16)

    for ticky in ax.xaxis.get_major_ticks():
        ticky.label.set_fontsize(16)

    figOutput = 'barComparisonTag{0}.png'.format(which)
    fig.savefig(path.join("plots", figOutput), bbox_inches = 'tight', dpi = 300)
    fig.clf()

def compareJ():
    width = 0.2
    kwargsRaw = {'linewidth': 1.5, 'alpha':0.75, 'width': width}

    fig, ax = plt.subplots(figsize = (12, 9))
    ax.bar(df5["nid"] - width / 2, df5["gcollapse"], color = "#4646ba", **kwargsRaw)
    ax.bar(df5["nid"] + width / 2, df5["fcollapse"], color = "#b24040", **kwargsRaw)

    ax.set_xticks(df5["nid"])
    ax.xaxis.set_ticklabels(df5["J"])
    ax.margins(x = 0)

    figTitle = "Execution time of gcollapse vs fcollapse (N = {0}, all stats)"
    fig.suptitle(figTitle.format("50,000,000"), fontsize = 24)

    ax.xaxis.set_label_text("Number of groups, J", fontsize = 20)
    ax.yaxis.set_label_text("Time in seconds", fontsize = 20)
    ax.grid(alpha = 0.25)

    note  = "'All stats' refers to: sum, mean, max, min, count, percent, first, last, firstnm, lastnm, median, iqr;"
    note += linesep + "in addition, p23 and p77 are also computed."
    ax.text(0, -0.17, note , ha = 'left', fontsize = 14, transform = ax.transAxes)

    ax.legend(["gcollapse", "fcollapse"], fontsize = 18)

    for ticky in ax.yaxis.get_major_ticks():
        ticky.label.set_fontsize(16)

    for ticky in ax.xaxis.get_major_ticks():
        ticky.label.set_fontsize(16)

    figOutput = 'barComparisonJ.png'
    fig.savefig(path.join("plots", figOutput), bbox_inches = 'tight', dpi = 300)
    fig.clf()

comparePlot(0)
comparePlot(1)
comparePlot(2)
compareJ()
