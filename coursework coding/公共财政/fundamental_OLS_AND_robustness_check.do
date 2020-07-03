**** Basic regression OLS****
**** Creator: Junjie Wang 202006 ****

clear
set more off

keep if year >= 1998
keep if year <= 2017

encode TableName, gen(tablename)
encode Region,gen(region1)
encode IncomeGroup,gen(incomegroup)

xtset tablename year

// 文化圈dummy构造
gen confucian_region = (culture_segment == 1)
gen sorth_asia_region = (culture_segment == 2)
gen west_region = (culture_segment == 3)
gen Islam_region = (culture_segment == 4)
gen east_europe_region = (culture_segment == 5)

// 政府质量变量构造
gen gov_quality = icrg_corruption + icrg_law_order + icrg_bureaucracy_quality

// 控制变量group

local base_controls gGDP GDPpcap pop gpop urban_pop landarea
local openness FDI_out FDI_in export import

// 交互项构造
gen govqu_pr = gov_quality*pr
gen govqu_cl = gov_quality*cl
gen govqu_democ = gov_quality*democ
gen govqu_autoc = gov_quality*autoc

gen cre_pr = cred_priv*pr
gen cre_cl = cred_priv*cl
gen cre_democ = cred_priv*democ
gen cre_autoc = cred_priv*autoc

local gov_cross govqu_pr govqu_cl govqu_democ govqu_autoc
local cred_cross cre_pr cre_cl cre_democ cre_autoc 


// gov_quality（-） cred_priv（-） cl（+） democ（+） autoc（-）显著，方向与预测相符
// PART1: 基础回归：
reg TR_1_5 gov_quality cred_priv pr cl democ autoc  `base_controls' `openness' `culture_dummy' i.region1 i.incomegroup,r

// PART2: 交叉项回归

// 1. gov_qual
reg TR_1_5 gov_quality cred_priv pr cl democ autoc `gov_cross' `base_controls' `openness' `culture_dummy' i.region1 i.incomegroup,r
// 2. cred
reg TR_1_5 gov_quality cred_priv pr cl democ autoc `cred_cross' `base_controls' `openness' `culture_dummy' i.region1 i.incomegroup,r


// PART4：robustness check
// 1. 重新定义openness -- 检验通过

local openness2 KOFEcGI KOFTrGI KOFFiGI KOFSoGI KOFIpGI KOFInGI KOFCuGI KOFPoGI 
reg TR_1_5 gov_quality cred_priv pr cl democ autoc `gov_cross' `base_controls' `openness2' `culture_dummy' i.region1 i.incomegroup,r

// 2. 时间段选择：1998--2001，2001--2017
// 2001--2017与原回归相似
reg TR_1_5 gov_quality cred_priv pr cl democ autoc `gov_cross' `base_controls' `openness' i.region1 i.incomegroup if year >= 2001 ,r
reg TR_1_5 gov_quality cred_priv pr cl democ autoc `gov_cross' `base_controls' `openness' i.region1 i.incomegroup if year < 2001 ,r

// 3. 地区选择：OECD国家，非OECD国家
reg TR_1_5 gov_quality cred_priv pr cl democ autoc `gov_cross' `base_controls' `openness' i.region1 i.incomegroup if d_OECD == 1,r
reg TR_1_5 gov_quality cred_priv pr cl democ autoc `gov_cross' `base_controls' `openness' i.region1 i.incomegroup if d_OECD == 0,r


