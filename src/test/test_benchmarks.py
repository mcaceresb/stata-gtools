#!/usr/bin/env python
# -*- coding: utf-8 -*-

# import matplotlib.pyplot as plt
import pandas as pd
# import numpy as np
import json

palette = json.loads(open('bench_v2/material.json').read())
df = pd.read_csv('bench_v2/gisid', delimiter = '|')

# df['ix'] = np.arange(df.shape[0])
# df[' '] = df[' '].astype('category')

# int1
# int1 int2
# double1
# double1 double2
# str_short
# str_short str_long
# int1 double1 str_mid
