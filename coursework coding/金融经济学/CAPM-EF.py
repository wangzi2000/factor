# consider that mu = mu_bar and mu_bar changes
# reference to the CAPM-2.py
# plt the efficient frontier

import pandas as pd
import cvxopt
from cvxopt import matrix, solvers
import math
import numpy as np
import matplotlib.pyplot as plt

#help(cvxopt.solvers)

df = pd.read_excel(r'/Users/wangjunjie/Desktop/private/比赛 & 调研 & 助研/RA/张英广老师/Strategy-python/HW3.xlsx')
print(df.columns)
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

#Erp = 0
#for i in range(1,6):
#    Erp = Erp + result['x'][i - 1]*mean_value[i]

#print(math.sqrt(2*result['primal objective']))
#print(Erp)

def cal(i):
    P = matrix(Cov_data.values)
    q = matrix([0.0, 0.0, 0.0, 0.0, 0.0])
    G = matrix(
        [[-1.0, 0.0, 0.0, 0.0, 0.0], [0.0, -1.0, 0.0, 0.0, 0.0], [0.0, 0.0, -1.0, 0.0, 0.0], [0.0, 0.0, 0.0, -1.0, 0.0],
         [0.0, 0.0, 0.0, 0.0, -1.0]])
    h = matrix([0.0, 0.0, 0.0, 0.0, 0.0])
    A = matrix([[1.0, 0.024308], [1.0, 0.01576], [1.0, 0.006028], [1.0, 0.0340],
                [1.0, 0.003185]])
    b = matrix([1.0, i])
    result = solvers.qp(P, q, G, h, A, b)
    return math.sqrt(2*result['primal objective'])

s = np.arange(0.02,0.035,0.0005)

sol_list = []
residual = []

mu = []
thita = []
for i in s:
    thita.append(cal(i))
    mu.append(i)

# plt the efficient frontier
plt.plot(thita,mu)
plt.xlabel("thita")
plt.ylabel("mu")
plt.show()
