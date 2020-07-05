# -*- coding: utf-8 -*-
"""
Created on Sat Jun 27 2020

@author: Junjie Wang
"""

import pandas as pd
import os 
import sys
import numpy as np

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
path_stock1 = os.path.join(os.getcwd(), "Data/1975-2000.dta")
path_stock2 = os.path.join(os.getcwd(), "Data/2001-2010.dta")
path_stock3 = os.path.join(os.getcwd(), "Data/2011-2020.dta")

df_stock1 = loadLargeDta(path_stock1)
df_stock2 = loadLargeDta(path_stock2)
df_stock3 = loadLargeDta(path_stock3)
print("Daily stock datasets successfully loaded.")

# extract trade dates into a set
set_trade_date1 = set(df_stock1['date'])
set_trade_date2 = set(df_stock2['date'])
set_trade_date3 = set(df_stock3['date'])

set_trade_date = set_trade_date1.union(set_trade_date2, set_trade_date3)
max_trade_date = max(set_trade_date)
min_trade_date = min(set_trade_date)
print("Trade dates successfully extracted.")

# read the target price dataset
path_target = os.path.join(os.getcwd(), "Data/price target.dta")
df_target = pd.read_stata(filepath_or_buffer = path_target,
                           columns = ["cusip", "anndats", "estimid", "alysnam", "value", "horizon"],
                           iterator = False)
df_target.reset_index(inplace = True)
print("Target price dataset successfully loaded.")
 
# find the proper trading day
def findTradeDate(series):
    print(series['index'])
    
    date = series['anndats']
    if (date > max_trade_date) or (date < min_trade_date - pd.Timedelta(days = 7)):
        return np.nan
    
    while (date not in set_trade_date):
        date = date + pd.Timedelta(days = 1)
        
    return date

df_target['date'] = df_target.apply(findTradeDate, axis = 1)
df_target.to_stata("updated_target.dta")