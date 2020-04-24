import pandas as pd
import numpy as np

df = pd.read_csv('e658fe9354eaef36.csv')

df.insert(10, 'Value', abs(df['PRC']) * df['SHROUT'], True)
df.insert(11, 'original value', df['Value'])
df['Value'] = df['Value'].shift(1)
coerce = pd.to_numeric(df['RET'], errors = 'coerce')
df.insert(12, 'Mean_RET', (coerce.rolling(13).sum() - coerce.rolling(2).sum()) / 11)
df.insert(13, 'Is_Valid', pd.Series(df['PERMNO'].rolling(13).mean() == df['PERMNO']))
df.insert(14, 'Coerced_RET', coerce)

dates = np.unique(df['date'])

UMD = []

for i in range(12, len(dates) - 1):
    indx = np.where(df['date'] == dates[i])[0][:]
    dd_stock = df.iloc[indx, :] # stocks on dd
    ret_valid_indx = np.where(df['Is_Valid'] == True)[0][:]
    sample_indx = np.where((df['EXCHCD'] == 1.0) | 
                           (df['EXCHCD'] == 2.0) |
                           (df['EXCHCD'] == 3.0) |
                           (df['EXCHCD'] == 31.0) |
                           (df['EXCHCD'] == 32.0) |
                           (df['EXCHCD'] == 33.0))[0][:] # sample stocks' index (exchange)
    sample_dd_stock = dd_stock.loc[dd_stock.index.intersection(sample_indx), :] # sample stocks on dd 
    sample_dd_stock = sample_dd_stock.loc[sample_dd_stock.index.intersection(ret_valid_indx), :]  # valid sample stocks on dd 

    NYSE_indx = np.where((df['EXCHCD'] == 1.0) |
                         (df['EXCHCD'] == 31.0))[0][:] # NYSE stocks' index (used for benchmark)
    NYSE_dd_stock = dd_stock.loc[dd_stock.index.intersection(NYSE_indx), :] # NYSE stocks on dd
    NYSE_dd_stock = NYSE_dd_stock.loc[NYSE_dd_stock.index.intersection(ret_valid_indx), :]  # valid NYSE stocks on dd 
    
    ret_C_indx = np.where(df['RET'] == 'C')[0][:]
    value_nan_indx = np.where(np.isnan(df['Value']))[0][:]
    mean_return_nan_indx = np.where(np.isnan(df['Mean_RET']))[0][:]
    mean_return_invalid_indx = np.where(np.isnan(df['Is_Valid'] == False))[0][:]
    sample_value_dropna = sample_dd_stock.drop(index = np.intersect1d(value_nan_indx,
                                                                      sample_dd_stock.index)) # sample stocks drop NAN Value
    #sample_value_dropna = sample_value_dropna.drop(index = np.intersect1d(ret_C_indx, 
    #                                                                      sample_value_dropna.index)) # sample stocks drop C
    sample_value_dropna = sample_value_dropna.drop(index = np.intersect1d(mean_return_nan_indx, 
                                                                          sample_value_dropna.index)) # sample stocks drop NAN mean RET
    sample_value_dropna = sample_value_dropna.drop(index = np.intersect1d(mean_return_invalid_indx, 
                                                                          sample_value_dropna.index)) # sample stocks drop invalid mean RET
    NYSE_value_dropna = NYSE_dd_stock.drop(index = np.intersect1d(value_nan_indx,
                                                                  NYSE_dd_stock.index)) # NYSE stocks drop NAN Value
    #NYSE_value_dropna = NYSE_value_dropna.drop(index = np.intersect1d(ret_C_indx, 
    #                                                                  NYSE_value_dropna.index)) # NYSE stocks drop C
    NYSE_value_dropna = NYSE_value_dropna.drop(index = np.intersect1d(mean_return_nan_indx, 
                                                                      NYSE_value_dropna.index)) # NYSE stocks drop NAN mean RET
    NYSE_value_dropna = NYSE_value_dropna.drop(index = np.intersect1d(mean_return_invalid_indx, 
                                                                      NYSE_value_dropna.index)) # NYSE stocks drop invalid mean RET
    median_size = np.median(NYSE_value_dropna['Value']) # median of NYSE
    np_Bindx = np.where(pd.DataFrame(sample_value_dropna['Value'] > median_size)['Value'] == True)[0][:]
    B_indx = sample_value_dropna.iloc[np_Bindx].index # index of big in dd (original df index)
    np_Sindx = np.where(pd.DataFrame(sample_value_dropna['Value'] > median_size)['Value'] == False)[0][:]
    S_indx = sample_value_dropna.iloc[np_Sindx].index # index of small in dd (original df index)
    
    percentile_30 = np.percentile(NYSE_value_dropna['Mean_RET'], 30) # 30th percentile of NYSE
    percentile_70 = np.percentile(NYSE_value_dropna['Mean_RET'], 70) # 70th percentile of NYSE
    np_Hindx = np.where(pd.DataFrame(sample_value_dropna['Mean_RET'] > percentile_70)['Mean_RET'] == True)[0][:]
    H_indx = sample_value_dropna.iloc[np_Hindx].index # index of large in dd (original df index)
    np_Lindx = np.where(pd.DataFrame(sample_value_dropna['Mean_RET'] > percentile_30)['Mean_RET'] == False)[0][:]
    L_indx = sample_value_dropna.iloc[np_Lindx].index # index of large in dd (original df index)
    
    SH_indx = np.intersect1d(S_indx, H_indx)
    BH_indx = np.intersect1d(B_indx, H_indx)
    SL_indx = np.intersect1d(S_indx, L_indx)
    BL_indx = np.intersect1d(B_indx, L_indx)
    
    SH_value = df['original value'].loc[SH_indx] / np.nansum(df['original value'].loc[SH_indx])
    BH_value = df['original value'].loc[BH_indx] / np.nansum(df['original value'].loc[BH_indx])
    SL_value = df['original value'].loc[SL_indx] / np.nansum(df['original value'].loc[SL_indx])
    BL_value = df['original value'].loc[BL_indx] / np.nansum(df['original value'].loc[BL_indx])    
    
    SH_ret = np.nansum(np.array(SH_value.loc[SH_indx]) * np.array(df['Coerced_RET'].loc[SH_indx]))
    BH_ret = np.nansum(np.array(BH_value.loc[BH_indx]) * np.array(df['Coerced_RET'].loc[BH_indx]))
    SL_ret = np.nansum(np.array(SL_value.loc[SL_indx]) * np.array(df['Coerced_RET'].loc[SL_indx]))
    BL_ret = np.nansum(np.array(BL_value.loc[BL_indx]) * np.array(df['Coerced_RET'].loc[BL_indx]))
    
    ret = (0.5 * (SH_ret + BH_ret) - 0.5 * (SL_ret + BL_ret))
    UMD.append(ret)
    print(ret)
    
UMD = pd.Series(UMD)
UMD.to_excel('UMD_weighted.xls')
