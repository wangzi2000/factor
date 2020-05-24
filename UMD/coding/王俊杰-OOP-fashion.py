# -*- coding: utf-8 -*-
"""
UMD factor according to Ken. French
Implemented in an OOP fashion
Created on 13-05-2020
@author: coding group      
"""

import os
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt

class MomentumUS(object):
    # initialize by loading data and keeping the 3 main exchanges
    def __init__(self, path_crsp):
        self.__df_crsp_data = pd.read_csv(path_crsp,
                                          usecols = ['PERMNO', 'date', 'EXCHCD', 'DLSTCD', 'DLRET', 'PRC', 'RET', 'SHROUT'])
        
        # use the main 3 exchange and fill the datetime in a right manner
        EXCHCD = self.__df_crsp_data['EXCHCD']
        self.__df_crsp_data = self.__df_crsp_data[np.logical_or(np.logical_and(EXCHCD >= 1, EXCHCD <= 3),
                                                                np.logical_and(EXCHCD >= 31, EXCHCD <= 33))]
        # we include the 31,32,33, but we set them as NaN to aviod using the data
        self.__df_crsp_data.loc[np.logical_and(EXCHCD >= 31, EXCHCD <= 33), "RET"] = np.nan
        
    # compute prior returns    
    def __PriorReturn(self):
        # first replace all non-numeric RET with NA
        self.__df_crsp_data['RET'] = pd.to_numeric(self.__df_crsp_data['RET'], errors='coerce')
        
        # then group the data by PERMNO and compute the prior monthly returns on a rolling basis
        def RollingPrior(ret):
            log_ret = np.log(ret + 1)
            log_priorret = log_ret.shift(2).rolling(window = 11).sum() 
            return log_priorret 
        self.__df_crsp_data['PRIORRET'] = self.__df_crsp_data.groupby('PERMNO')['RET'].transform(RollingPrior)
    
    
    # deal with delisting stocks
    def __DelistReturn(self):
        # first replace all non-numeric DLRET with NA
        DLRET = pd.to_numeric(self.__df_crsp_data["DLRET"], errors = 'coerce')
    
        #notice that DLRET has 362 values as -1
        self.__df_crsp_data.loc[np.logical_and(~pd.isnull(DLRET), DLRET != -1), 'RET'] = DLRET
    

    # compute market equity
    def __MarketEquity(self):
        # first replace all non-numeric PRC or SHROUT with NA
        self.__df_crsp_data['PRC'] = pd.to_numeric(self.__df_crsp_data['PRC'], errors='coerce')
        self.__df_crsp_data['SHROUT'] = pd.to_numeric(self.__df_crsp_data['SHROUT'], errors='coerce')
       
        # then compute market equity by doing multiplication
        # taking absolute values of PRC in case that some prices are derived from bid-and-ask
        self.__df_crsp_data['ME'] = abs(self.__df_crsp_data['PRC']) * self.__df_crsp_data['SHROUT']
        
    
    # compute market equity of the last month
    def __LastME(self):
        # group the data by PERMNO and compute market equity of the last month        
        def LastME(me):
            return me.shift(1) 
        self.__df_crsp_data['LASTME'] = self.__df_crsp_data.groupby('PERMNO')['ME'].transform(LastME)
        
    # derive breakpoints according to size and prior returns of NYSE stocks
    def __BreakPoint(self):
        # first extract the group of NYSE stocks
        df_group_NYSE = self.__df_crsp_data.groupby('EXCHCD').get_group(1)
        
        # next derive the breakpoints of size and assign to the CRSP dataframe
        # for the convenience of assigning breakpoints, set date as index
        self.__df_crsp_data.set_index('date', inplace = True)
        self.__df_size_breakpoint = df_group_NYSE.groupby('date')['LASTME'].median()
        self.__df_crsp_data['MEBPT'] = self.__df_size_breakpoint.reset_index().set_index('date')
        
        # then derive the breakpoints of prior returns and assign to the CRSP dataframe
        # like above set date as index to speed up the process of assignment
        self.__df_lowret_breakpoint = df_group_NYSE.groupby('date')['PRIORRET'].quantile(.3)
        self.__df_highret_breakpoint = df_group_NYSE.groupby('date')['PRIORRET'].quantile(.7) 
        self.__df_crsp_data['LoRETBPT'] = self.__df_lowret_breakpoint.reset_index().set_index('date')
        self.__df_crsp_data['HiRETBPT'] = self.__df_highret_breakpoint.reset_index().set_index('date')
        
        # at last reset index and get back the column of date
        self.__df_crsp_data.reset_index(inplace = True)
    
    
    # form 4 different portfolios using breakpoints
    def __Portfolio(self):
        # first form 4 different stock groups
        LASTME = self.__df_crsp_data['LASTME']
        MEBPT = self.__df_crsp_data['MEBPT']
        PRIORRET = self.__df_crsp_data['PRIORRET']
        LoRETBPT = self.__df_crsp_data['LoRETBPT']
        HiRETBPT = self.__df_crsp_data['HiRETBPT']
        self.__df_small_high = self.__df_crsp_data[np.logical_and(LASTME <= MEBPT, PRIORRET > HiRETBPT)]
        self.__df_big_high = self.__df_crsp_data[np.logical_and(LASTME > MEBPT, PRIORRET > HiRETBPT)]
        self.__df_small_low = self.__df_crsp_data[np.logical_and(LASTME <= MEBPT, PRIORRET < LoRETBPT)]
        self.__df_big_low = self.__df_crsp_data[np.logical_and(LASTME > MEBPT, PRIORRET < LoRETBPT)]
    
    
    # compute porfolio returns with either value weight or equal weight
    # use the value-weight indicator to choose between two methods of averaging
    def __PortfolioReturn(self, value_weight):
        # a function to compute weighted average following a given rule
        def WeightedAverage(df_portfolio, value_weight):
            df_group_date = df_portfolio.groupby('date')
            if(value_weight):
                return df_group_date.apply(lambda x: (100 * x['RET'] * x['LASTME']).sum() / x['LASTME'].sum())
            else:
                return df_group_date.apply(lambda x: 100 * x['RET'].mean())
        
        self.__ret_small_high = WeightedAverage(self.__df_small_high, value_weight)
        self.__ret_big_high = WeightedAverage(self.__df_big_high, value_weight)
        self.__ret_small_low = WeightedAverage(self.__df_small_low, value_weight)
        self.__ret_big_low = WeightedAverage(self.__df_big_low, value_weight)
      
        
    # use equal weight to compute the momentum factor    
        
    # plot the time series of factors
    # please ensure the dataframe fed has the only 2 columns needed
    # feed a path for saving the plot
    def __PlotFactor(self, df_factor, factor_name, date_format, path_figure = False):
        # create a temporary dataframe to work on
        df_plot_factor = df_factor
        # convert the date column to the format of datetime
        df_plot_factor['date'] = pd.to_datetime(df_plot_factor['date'].apply(str), format = date_format)
        df_plot_factor.set_index('date', inplace = True)
        plot_factor = df_plot_factor.plot(figsize = (12, 8), legend = False)
        plot_factor.set_xlabel('Date')
        plot_factor.set_ylabel(factor_name)
        
        # save the plot if a file path is fed
        if(path_figure):
            plt.savefig(path_figure)
            print("The plot of {} is saved as {}".format(factor_name, path_figure))    
        
        plt.show()
    
    
    # below are public or getter functions of the class    
    # apply functions defined above to derive the eventual momentum factor
    def FormPortfolio(self):
        #self.__RemoveLowPrice()
        self.__DelistReturn()
        self.__PriorReturn()
        self.__MarketEquity()
        # last ME is not very helpful in improving correlation
        # but we use lastME for the reason of rationality
        self.__LastME()
        self.__BreakPoint()
        self.__Portfolio()
    
    
    # return the processed dataframe
    def GetDetail(self):
        return self.__df_crsp_data
    
    
    # return the breakpoints
    def GetBreakPoints(self):
        return [self.__df_size_breakpoint, self.__df_lowret_breakpoint, self.__df_highret_breakpoint]
    
    
    # return the momentum factors in a dataframe indexed by date
    # use value weight to compute porfolio return by default
    def GetMomentumFactor(self, value_weight = True):
        self.__PortfolioReturn(value_weight)
        self.__momentum_factor = (self.__ret_small_high + self.__ret_big_high - self.__ret_small_low - self.__ret_big_low) / 2
        return self.__momentum_factor  
        
        
    # plot the time series of momentum factors
    def PlotMomentumFactor(self, path_figure = False):
        self.__PlotFactor(self.__momentum_factor.reset_index(), "Momentum Factor", "%Y%m%d", path_figure)
        
    
    # read F-F factor from csv and print the correlation
    # please make sure the time spans match
    def PrintCorrelation(self, path_ff, path_figure = False):
        self.__df_ff_factor = pd.read_csv(path_ff)
        self.__PlotFactor(self.__df_ff_factor, "F-F UMD Factor", "%Y%m", path_figure)
        try:
            correlation = np.corrcoef(self.__momentum_factor, self.__df_ff_factor['factor'])[0,1]
            print("The correlation with F-F UMD factor is %.3f\n" % correlation)
        except ValueError:
            print("The time spans of the two factor series don't match, and correlation cannot be computed\n")
            print(len(self.__momentum_factor))
            print(len(self.__df_ff_factor['factor']))
        
    
    # return the value-weighted portfolio returns
    def GetPortfolioReturn(self):
        return [self.__ret_small_high, self.__ret_big_high, self.__ret_small_low, self.__ret_big_low]

if __name__ == '__main__':
    # initialize and form the portfolios
    # notice that you should implement the path!
    path_crsp = os.path.join(os.getcwd(), "e658fe9354eaef36.csv")
    momentum_factor = MomentumUS(path_crsp)
    momentum_factor.FormPortfolio()
    
    # get the details of deriving the factor, including market equity, size and breakpoints, etc.
    df_crsp_detail = momentum_factor.GetDetail()
    # get the list of 3 different types of breakpoints
    l_breakpoint = momentum_factor.GetBreakPoints()
    
    # use value weight returns to derive factor
    # get the momentum factor for each month
    print("Below is summary of value weight momentum factor")
    df_value_weight_factor = momentum_factor.GetMomentumFactor()
    # plot the time series of momentum factor and save the image
    path_plot_value_weight = os.path.join(os.getcwd(), "value_weight_momentum_factor.png")
    momentum_factor.PlotMomentumFactor(path_plot_value_weight)
    # print the correlation with F-F factors and save the plot of F-F factors
    # notice that you should implement the path! and the first data of F-F should not be included because we
    # use the last term market value in calculating.
    path_ff = os.path.join(os.getcwd(), "F-F_Momentum_Factor.csv")
    path_plot_ff = os.path.join(os.getcwd(), "F-F_momentum_factor.png")
    momentum_factor.PrintCorrelation(path_ff, path_plot_ff)
    # get the list of returns of 4 portfolios
    l_value_weight_return = momentum_factor.GetPortfolioReturn()
    
    # use equal weight returns to derive factor
    # get the momentum factor for each month
    print("Below is summary of equal weight momentum factor")
    df_equal_weight_factor = momentum_factor.GetMomentumFactor(value_weight = False)
    # plot the time series of momentum factor and save the image
    path_plot_equal_weight = os.path.join(os.getcwd(), "equal_weight_momentum_factor.png")
    momentum_factor.PlotMomentumFactor(path_plot_equal_weight)
    # print the correlation with F-F factors
    momentum_factor.PrintCorrelation(path_ff)
    # get the list of returns of 4 portfolios
    l_equal_weight_return = momentum_factor.GetPortfolioReturn()  
