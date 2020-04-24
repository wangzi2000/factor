import numpy as np
import pandas as pd
import warnings
warnings.filterwarnings('ignore')

#导入文件
file = pd.read_csv('e658fe9354eaef36.csv', sep=',')
df = pd.DataFrame(file)
#df1 = df.head(30000)
df1 = df

dict_date = list(set((df1['date'].values)))
dict_date.sort()

#df为可用数据集 -- 未处理缺失值
df2 = df1[['date','PRC','PERMNO',"RET","SHROUT"]].set_index('date')

#价格为正
df2['PRC_real'] = abs(df2['PRC'])
df2['date_real'] = abs(df2.index)

#计算市值
df2["market_cap"] = df2['PRC_real']*df2["SHROUT"]

#删掉PRC行
df3 = df2.drop('PRC',axis = 1)

# 删除RET中有字母的行,,df0为准备好的数据

df0 = df3[~df3['RET'].str.contains("[a-zA-Z]").fillna(False)]

##主程序

mom_eq = {}
mom_w  = {}


for k in range(22,60):
    #第k月
    target_date = dict_date[k]
    df_target_date = df0.loc[target_date]
    df_target_date['avg_return'] = np.nan
    df_target_date = df_target_date[~(df_target_date['RET'].isnull())]
    df_target_date = df_target_date[~(df_target_date['PRC_real'].isnull())]
    for stk in df_target_date["PERMNO"].values:
        return_avg_12 = 1
        for i in range(2,14):
            flag = 0
            tip = 0
            if (k - i >= 0):
                # bug: 如果有些股票不存在对应的天数怎么办？
                # 例如13653股票没有19591130的条目
                if np.any(np.array(df0[df0.PERMNO == stk].index) == dict_date[k - i]):
                    if  (df0[df0.PERMNO == stk].RET[dict_date[k - i]] != np.nan):
                        return_avg_12 = return_avg_12*(float(df0[df0.PERMNO == stk].RET[dict_date[k - i]])+ 1)
                    else:
                        flag = 1
            if flag == 0:
                df_target_date.loc[df_target_date.PERMNO == stk, 'avg_return' ]  = return_avg_12 - 1

    # #按照return排序
    p_30 = int(len(df_target_date)*0.3)
    df_L = df_target_date.sort_values(by = 'avg_return').head(p_30)
    df_H = df_target_date.sort_values(by = 'avg_return').tail(p_30)

    #按照市值排列，取中位数
    p_50 = int(len(df_target_date)/2)
    df_S = df_target_date.sort_values(by = 'market_cap').head(p_50)
    n_left = len(df_target_date) - p_50
    df_B = df_target_date.sort_values(by = 'market_cap').tail(n_left)      

    # 构建四个portfolio： SL，SH，BL，BH
    df_SL = pd.merge(df_S, df_L)
    df_SH = pd.merge(df_S, df_H, how = 'inner').drop_duplicates()
    df_BL = pd.merge(df_B, df_L, how = 'inner').drop_duplicates()
    df_BH = pd.merge(df_B, df_H, how = 'inner').drop_duplicates()

    #若portfolio里面没有资产，默认return = 0
    #把RET为nan的都去掉

    df_BH =df_BH[~(df_BH['RET'].isnull())]
    df_BL =df_BL[~(df_BL['RET'].isnull())]
    df_SH =df_SH[~(df_SH['RET'].isnull())]
    df_SL =df_SL[~(df_SL['RET'].isnull())]

    #等权重法
    return_BH_eq = 0
    if len(df_BH) == 0:
        return_BH_eq = 0
    else:       
        for stk in df_BH['PERMNO'].values:
            if np.any(np.array(df0[df0.PERMNO == stk].index) == dict_date[k - 1]):
                 if pd.isnull((float(df0[df0.PERMNO == stk].RET[dict_date[k - 1]]))) == False :
                #print(float(df0[df0.PERMNO == stk].RET[dict_date[k - 1]]))
                    return_BH_eq = return_BH_eq + float(df0[df0.PERMNO == stk].RET[dict_date[k - 1]])
                    #print(return_BH_eq)
                    #print(float(df0[df0.PERMNO == stk].RET[dict_date[k - 1]]))
    return_BH_eq = return_BH_eq/len(df_BH)

    return_BL_eq = 0
    if len(df_BL) == 0:
        return_BL_eq = 0
    else:       
        for stk in df_BL['PERMNO'].values:
            if np.any(np.array(df0[df0.PERMNO == stk].index) == dict_date[k - 1]):     
                if pd.isnull((float(df0[df0.PERMNO == stk].RET[dict_date[k - 1]]))) == False :
                    return_BL_eq = return_BL_eq + float(df0[df0.PERMNO == stk].RET[dict_date[k - 1]])
    return_BL_eq = return_BL_eq/len(df_BL)


    return_SL_eq = 0
    if len(df_SL) == 0:
        return_SL_eq = 0
    else:       
        for stk in df_SL['PERMNO'].values:
            if np.any(np.array(df0[df0.PERMNO == stk].index) == dict_date[k - 1]): 
                if pd.isnull((float(df0[df0.PERMNO == stk].RET[dict_date[k - 1]]))) == False :
                    return_SL_eq = return_SL_eq + float(df0[df0.PERMNO == stk].RET[dict_date[k - 1]])
    return_SL_eq = return_SL_eq/len(df_SL)


    return_SH_eq = 0
    if len(df_SH) == 0:
        return_SH_eq = 0
    else:       
        for stk in df_SH['PERMNO'].values:
            if np.any(np.array(df0[df0.PERMNO == stk].index) == dict_date[k - 1]):     
                if pd.isnull((float(df0[df0.PERMNO == stk].RET[dict_date[k - 1]]))) == False :
                    return_SH_eq = return_SH_eq + float(df0[df0.PERMNO == stk].RET[dict_date[k - 1]])
    return_SH_eq = return_SH_eq/len(df_SH)


    #加权法
    return_BH_w = 0
    tot_mark_cap = 0

    for stk in df_BH['PERMNO'].values:
        tot_mark_cap = tot_mark_cap + float(df0[df0.PERMNO == stk].market_cap[dict_date[k]])
    if len(df_BH) == 0:
        return_BH_eq = 0
    else:
        for stk in df_BH['PERMNO'].values:
            if np.any(np.array(df0[df0.PERMNO == stk].index) == dict_date[k - 1]):     
                if pd.isnull((float(df0[df0.PERMNO == stk].RET[dict_date[k - 1]]))) == False :
                    return_BH_w = return_BH_w + (float(df0[df0.PERMNO == stk].RET[dict_date[k - 1]]))*(float(df0[df0.PERMNO == stk].market_cap[dict_date[k]])/tot_mark_cap)
                    #print(float(df0[df0.PERMNO == stk].RET[dict_date[k - 1]]))

    return_SH_w = 0
    tot_mark_cap = 0
    for stk in df_SH['PERMNO'].values:
        tot_mark_cap = tot_mark_cap + float(df0[df0.PERMNO == stk].market_cap[dict_date[k]])

    if len(df_SH) == 0:
        return_SH_eq = 0
    else:
        for stk in df_SH['PERMNO'].values:
            if np.any(np.array(df0[df0.PERMNO == stk].index) == dict_date[k - 1]):    
                if pd.isnull((float(df0[df0.PERMNO == stk].RET[dict_date[k - 1]]))) == False :
                    return_SH_w = return_SH_w + (float(df0[df0.PERMNO == stk].RET[dict_date[k - 1]]))*(float(df0[df0.PERMNO == stk].market_cap[dict_date[k]])/tot_mark_cap)

    return_SL_w = 0
    tot_mark_cap = 0
    for stk in df_SL['PERMNO'].values:
        tot_mark_cap = tot_mark_cap + float(df0[df0.PERMNO == stk].market_cap[dict_date[k]])

    if len(df_SL) == 0:
        return_SL_eq = 0
    else:
        for stk in df_SL['PERMNO'].values:
            if np.any(np.array(df0[df0.PERMNO == stk].index) == dict_date[k - 1]):     
                if pd.isnull((float(df0[df0.PERMNO == stk].RET[dict_date[k - 1]]))) == False :
                    return_SL_w = return_SL_w + (float(df0[df0.PERMNO == stk].RET[dict_date[k - 1]]))*(float(df0[df0.PERMNO == stk].market_cap[dict_date[k]])/tot_mark_cap)

    return_BL_w = 0
    tot_mark_cap = 0
    for stk in df_BL['PERMNO'].values:
        tot_mark_cap = tot_mark_cap + float(df0[df0.PERMNO == stk].market_cap[dict_date[k]])

    if len(df_BL) == 0:
        return_BL_eq = 0
    else:
        for stk in df_BL['PERMNO'].values:
            if np.any(np.array(df0[df0.PERMNO == stk].index) == dict_date[k - 1]):    
                if pd.isnull((float(df0[df0.PERMNO == stk].RET[dict_date[k - 1]]))) == False :
                    return_BL_w = return_BL_w + (float(df0[df0.PERMNO == stk].RET[dict_date[k - 1]]))*(float(df0[df0.PERMNO == stk].market_cap[dict_date[k]])/tot_mark_cap)

    mom_eq[dict_date[k]] = 0.5*((return_SH_eq - return_BH_eq) - 0.5*(return_SL_eq - return_BL_eq)) 
    mom_w[dict_date[k]]  = 0.5*((return_SH_w - return_BH_w) - 0.5*(return_SL_w - return_BL_w))
    print(mom_eq)
    print(mom_w)
