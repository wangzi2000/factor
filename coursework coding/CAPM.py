# consider that mu = mu_bar and mu_bar changes
# reference to the CAPM-2.py

import pandas as pd
import cvxopt
from cvxopt import matrix, solvers
import math

df = pd.read_excel(r'/Users/wangjunjie/Desktop/private/比赛 & 调研 & 助研/RA/张英广老师/Strategy-python/HW3.xlsx')

data = dict()
mean_value = dict()
std_value = dict()

for i in range(1,6):
    data[i] = df[df["code"]=='Stock ' +str(i)]['return']
    data[i].index = range(0,len(data[i]))
    mean_value[i] = data[i].mean()
    std_value[i] = data[i].std()

for i in range(1,6):
    print(mean_value[i])

print("---------")

for i in range(1,6):
    print(std_value[i])

d = pd.DataFrame({"1":data[1]})

for i in range(2,6):
    d = d.join(pd.DataFrame({str(i):data[i]}))
Cov_data = d.cov()
print("---------")
print(Cov_data)

# cvxopt.solvers --> maximization tools
P = matrix(Cov_data.values)
#print(P)
q = matrix([0.0,0.0,0.0,0.0,0.0])

G = matrix([[-1.0,0.0,0.0,0.0,0.0],[0.0,-1.0,0.0,0.0,0.0],[0.0,0.0,-1.0,0.0,0.0],[0.0,0.0,0.0,-1.0,0.0],[0.0,0.0,0.0,0.0,-1.0]])
h = matrix([0.0,0.0,0.0,0.0,0.0])

A = matrix([[1.0, 0.024],[1.0, 0.016],[1.0, 0.006],[1.0, 0.034],[1.0, 0.0033]])
b = matrix([1.0,0.03])

result = solvers.qp(P, q, G, h, A, b)
print('x\n',result['x'])
#print(result['x'][0]+result['x'][1]+result['x'][2]+result['x'][3]+result['x'][4])

Erp = 0
sum = 0
for i in range(1,6):
    Erp = Erp + result['x'][i - 1]*mean_value[i]
    sum = sum + result['x'][i - 1]

print(math.sqrt(2*result['primal objective']))
print(Erp,sum)
print(2*result['primal objective'])
