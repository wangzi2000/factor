# creator：王俊杰
# 计量经济学论文数据处理

import pandas as pd
import numpy as np
df = pd.read_stata('/Users/wangjunjie/Desktop/private/比赛 & 调研 & 助研/RA/张英广老师/第一周工作/Ziman REIT Monthly Indices_for_py.dta')

# 累积计算年收益率
df['tret_add'] = np.log(df['tret'] + 1) 
df_year =  pd.DataFrame(df.groupby(['year','id']).sum())
df_year = df.groupby(['year','id'])['tret_add'].sum()

# add index for later
df_year = pd.DataFrame(df_year)
df_year['id_cal'] = df_year.index.get_level_values('id').values

df_year['reits_return'] = np.exp(df_year['tret_add']) - 1
df_year = df_year.drop('tret_add',axis = 1)

# 整合CRSP数据
df_CSP = pd.read_stata("/Users/wangjunjie/Desktop/大二下/大二下课程/公共财政/小组文件/project/Data_Version_0508/CSPCUBE.dta")
df_CSP_USA = df_CSP[df_CSP['country'] == 'United States']

df_data_2 = pd.merge(df_data_1, df_CSP_USA, on  = ['year'])
df_data_2_form = df_data_2.groupby(['year','id_cal']).sum()


# 整合利息率数据
df_int = pd.read_excel(r'/Users/wangjunjie/Desktop/大二下/大二下课程/计量经济学/term paper/data/interest_data.xlsx')
df_int['year'] = df_int['TIME']
df_data_3 = pd.merge(df_data_2, df_int, on  = ['year'])

# 整合劳动数据
# df_data_4为最终数据
df_emp = pd.read_stata(r'/Users/wangjunjie/Desktop/大二下/大二下课程/小组文件/project/Data_Version_0508/OECD_employment.dta')
df_emp_USA = df_emp[df_emp['country'] == 'United States']
df_data_4 = pd.merge(df_data_3, df_emp_USA, on  = ['year'],how = 'outer')
