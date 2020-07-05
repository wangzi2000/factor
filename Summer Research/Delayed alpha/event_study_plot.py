# -*- coding: utf-8 -*-
"""
Created on Mon Jun 27 2020

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
                           columns = ["permno", "date", "ret"],
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
                          columns = ["permno", "date", "ret"],
                          iterator = False)
df_stock2 = loadLargeDta(path_stock2)
df_stock3 = loadLargeDta(path_stock3)
print("Daily stock datasets successfully loaded.")

df_stock = df_stock1.append(df_stock2).append(df_stock3).reset_index()
print("Daily stock datasets successfully concatenated.")

# read the target price dataset
path_target = os.path.join(os.getcwd(), "expected_12mo_ret.dta")
df_target = pd.read_stata(filepath_or_buffer = path_target,
                          columns = ["permno", "date", "expret"],
                          iterator = False)
print("Target price dataset successfully loaded.")

# read the market index dataset
path_market = os.path.join(os.getcwd(), "Data/stock market indexes-daily.dta")
df_market = pd.read_stata(filepath_or_buffer = path_market,
                          columns = ["date", "ewretd"],
                          iterator = False)
print("Market index dataset successfully loaded.")

# compute the cumulative market-adjusted return
def cumAdjReturn(series):
    print(series['index'])
    ix = df_stock['permno'] == series['permno']
    df = df_stock[ix].reset_index()
    
    # check if the timespan is wide enough
    if (len(df) < 281 or
           df['date'].iloc[10] > series['date'] or
           df['date'].iloc[-271] < series['date']):
        return np.nan
    
    # find the index of each target price date
    ix_target = df[df['date'] == series['date']].index.tolist()[0]
    ix_market = df_market[df_market.date == series['date']].index.tolist()[0]
    
    df1 = df.iloc[(ix_target-10):(ix_target+271)]
    df2 = df_market.iloc[(ix_market-10):(ix_market+271)]
    
    # compute cumulative returns into an array  
    df_cum_ret = np.exp(np.log(df1['ret'] + 1).cumsum()).reset_index(drop = True)
    df_mkt_ret = np.exp(np.log(df2['ewretd'] + 1).cumsum()).reset_index(drop = True)
    return  df_cum_ret - df_mkt_ret

# randomly pick a chunk of data to generate plot
# chunk size is in discretion
def randomPlot(size):
    df_sample = df_target.sample(size).reset_index(drop = True)
    df_cumret = df_sample.reset_index().apply(cumAdjReturn, axis = 1)
    df_sample = pd.concat([df_sample, df_cumret], axis = 1)
    
    #df_sample['cumret'] = df_sample.reset_index().apply(cumAdjReturn, axis = 1)

    df_sample.sort_values(by = ['expret'], inplace = True)
    df_sample.dropna(axis = 0, how = "any", inplace = True)
    df_sample = df_sample.reset_index(drop = True).reset_index()
    df_sample['group'] = df_sample['index'] // (len(df_sample) / 8)
    #df_avgret = df_sample.groupby('group')['cumret'].apply(np.mean)
    df_avgret = df_sample.iloc[:,4:].groupby('group').agg(np.nanmean)
    
    df_plot = pd.DataFrame(columns = range(0,281), index = range(1,9))
    for i in range(0,8): df_plot.iloc[i] = df_avgret.iloc[i]
    df_plot.columns = range(-10,271)
    plot = df_plot.T.plot(figsize = (20,16))
    plot.get_figure().savefig("rand_" + str(size) + ".png")
    print("rand_" + str(size) + ".png successfully saved.")
    
randomPlot(10000)


    

    
    
    