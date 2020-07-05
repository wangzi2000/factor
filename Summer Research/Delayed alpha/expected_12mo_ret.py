# -*- coding: utf-8 -*-
"""
Created on Mon Jun 27 2020

@author: Junjie Wang
"""

import pandas as pd
import os 
import sys

# read large datasets from dta files chunk by chunk
# performance optimized when chunk_size around 1e7
# referenced from csdn.net
def loadLargeDta(filepath):
    reader = pd.read_stata(filepath_or_buffer = filepath,
                           columns = ["permno", "date", "ncusip", "prc", "ret"],
                           iterator = True)
    df = pd.DataFrame()
    chunk_size = int(1e7)
    
    try:
        chunk = reader.get_chunk(chunk_size)
        while len(chunk) > 0:
            df = df.append(chunk, ignore_index = True)
            chunk = reader.get_chunk(chunk_size)
            print ('.')
            sys.stdout.flush()
    except (StopIteration, KeyboardInterrupt):
        pass
 
    print('\nloaded {} rows'.format(len(df)))
    return df

# read the daily stock datasets
path_stock1 = os.path.join(os.getcwd(), "Data/1999-2000.dta")
path_stock2 = os.path.join(os.getcwd(), "Data/2001-2010.dta")
path_stock3 = os.path.join(os.getcwd(), "Data/2011-2020.dta")

df_stock1 = pd.read_stata(filepath_or_buffer = path_stock1,
                          columns = ["permno", "date", "ncusip", "prc", "ret"],
                          iterator = False)
df_stock2 = loadLargeDta(path_stock2)
df_stock3 = loadLargeDta(path_stock3)
print("Daily stock datasets successfully loaded.")

df_stock = df_stock1.append(df_stock2).append(df_stock3)
print("Daily stock datasets successfully concatenated.")

# read the target price dataset
path_target = os.path.join(os.getcwd(), "updated_target.dta")
df_target = pd.read_stata(filepath_or_buffer = path_target,
                          columns = ["cusip", "date", "estimid", "alysnam", "value", "horizon"],
                          iterator = False)
print("Target price dataset successfully loaded.")

# merge two datasets
df_stock.rename(columns = {'ncusip': 'cusip'}, inplace = True)
df_target = df_target[df_target['horizon'] == '12']
df_merge = pd.merge(df_target, df_stock, on = ['cusip', 'date'], how = 'inner')

# compute expected 12-month return
df_merge['expret'] = df_merge['value'] / df_merge['prc'] * (1 + df_merge['ret']) - 1
df_out = df_merge[['permno', 'date', 'value', 'alysnam', 'estimid', 'expret']]
df_out.to_stata("expected_12mo_ret.dta")