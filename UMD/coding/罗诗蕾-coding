import pandas as pd
import numpy as np

# crsp_df为原始全数据集
crsp_df = pd.read_csv('CRSP.csv',header=0)
crsp_df = crsp_df.sort_values(by=['date','PERMNO'])
# 计算ME
crsp_df['ME'] = np.abs(crsp_df['PRC'])*np.array(crsp_df['SHROUT'])
# 向df中加入月份和股票代码两列
df = crsp_df[['date','EXCHCD','PERMNO','ME']]

# 月份列表
monthlist = list(df['date'].drop_duplicates())

# 将str转换为float，若无法转换，保留原值
def to_float(n):
    try:
        n = float(n)
    except ValueError:
        pass
    return n

# 向df中加入转换为float的RET列
df['RET'] = crsp_df['RET'].apply(to_float)
# 判断是否为字符串
def is_str(n):
    return isinstance(n,str)
# RET中非法字符
ilRET = list(filter(is_str,list(df['RET'].drop_duplicates())))
# print(ilRET)
# Calculate prior return 
df = df.set_index(['date'])
df['RET'] = df['RET'].replace(['B','C'],np.nan)
df['logRET']=df['RET'].apply(lambda x : np.log(1+x))
umd = df.groupby(['PERMNO'])['logRET'].rolling(12, min_periods=12).sum()
umd = umd.reset_index(drop = False) # 解除分组
umd = umd.sort_values(by=['date','PERMNO']).set_index(['date']) # 按月份、股票重排
# 获得 t-12 ~ t-2 期的compound return
umd[['RET','ME','EXCHCD']] = df[['RET','ME','EXCHCD']]
umd['cumlogRET'] = umd['logRET'] - df['logRET']
umd['priorRET']= np.exp(umd['cumlogRET'])-1
umd = umd.drop(['logRET','cumlogRET'],1)
# print(umd)

umd = umd.dropna(axis=0, subset=['ME'])
umd = umd.dropna(axis=0, subset=['priorRET'])
umd = umd.reset_index(drop = False) # 解除分组


# 将df按日期分为若干个小df，形成字典键值对
dfdict = {}
for month in monthlist:
    dfdict[month] = umd[umd['date'].isin([month])]

def split1(x,median):
    if x < median:
        return 'Small'
    else:
        return 'Big'

def sizesplit(data):
    breakpoint = data[data['EXCHCD'].isin([1])]['ME'].median()
    data['size'] = data.apply(lambda x:split1(x['ME'],breakpoint),axis=1)
    return data

def split2(x,q1,q2):
    if x <= q1:
        return 'Low'
    elif x < q2:
        return 'Middle'
    else:
        return 'High'

def RETsplit(data):
    breakpoint1 = data[data['EXCHCD'].isin([1])]['priorRET'].quantile(q=0.3)
    breakpoint2 = data[data['EXCHCD'].isin([1])]['priorRET'].quantile(q=0.7)
    data['return'] = data.apply(lambda x:split2(x['priorRET'],breakpoint1,breakpoint2),axis=1)
    return data

def EqualWeighted(data):
    return data['RET'].mean()

def ValueWeighted(data):
    totalME = data['ME'].sum()
    data['weight'] = data['ME']/totalME
    weightedRET = np.dot(np.array(data['weight']),np.array(data['RET']))
    return weightedRET

VW = [monthlist,[]]
EW = [monthlist,[]]
for month in monthlist:
    if dfdict[month].empty:
        VW[1].append(np.nan) 
        EW[1].append(np.nan) 
        continue
    df1 = dfdict[month]
    subumd = RETsplit(sizesplit(df1))
    Small_High = subumd[subumd['return'].isin(['High'])&subumd['size'].isin(['Small'])]
    Small_Low = subumd[subumd['return'].isin(['Low'])&subumd['size'].isin(['Small'])]
    Big_High = subumd[subumd['return'].isin(['High'])&subumd['size'].isin(['Big'])]
    Big_Low = subumd[subumd['return'].isin(['Low'])&subumd['size'].isin(['Big'])]
    VWmom = (ValueWeighted(Small_High)+ValueWeighted(Big_High))/2-\
        (ValueWeighted(Small_Low)+ValueWeighted(Big_Low))/2
    VW[1].append(VWmom*100) 
    EWmom = (EqualWeighted(Small_High)+EqualWeighted(Big_High))/2-\
        (EqualWeighted(Small_Low)+EqualWeighted(Big_Low))/2
    EW[1].append(EWmom*100) 

VWdf=pd.DataFrame(VW).T
VWdf.rename(columns={0:'Month',1:'MOM'},inplace=True)
VWdf = VWdf.dropna(axis=0, subset=['MOM'])
VWdf.to_csv('ValueWeightedMOM.csv')
EWdf=pd.DataFrame(EW).T
EWdf.rename(columns={0:'Month',1:'MOM'},inplace=True)
EWdf = EWdf.dropna(axis=0, subset=['MOM'])
EWdf.to_csv('EqualWeightedMOM.csv')
