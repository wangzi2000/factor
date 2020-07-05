* - creator：王俊杰
* - 计量经济学论文回归代码

gen log_REITs = log(reits_return + 1)
gen log_STOCk = log(stock_return + 1)
// use "/Users/wangjunjie/Desktop/大二下/大二下课程/计量经济学/term paper/data/data_final/REITs_analysis_data_1.dta"
xtset id_cal year
// 描述性统计作图
xtline log_REITs

// REITs_return Stock_return构造请见python代码
// 生成变量 （为调整数量级至合适范围，扩大一定倍数）
gen gdp_debt_rate = (housdebt / gdpmln_usd)*1000000
gen gdp_income_rate = (housinc / gdpmln_usd)*1000000



// PART1: 长短期宏观因子模型回归 
xtreg log_REITs ///
L.log_STOCK L10.log_STOCK L15.log_STOCK ///
L.housecostrent L10.housecostrent   ///
L.housecostnominal L10.housecostnominal  ///
 ///
L10.gdp_debt_rate ///
L10.gdp_income_rate ///
L7.ltint L15.ltint ///
L.gdp ///
L.cpi ///
,fe 
est store FE

xtreg log_REITs ///
L.log_STOCK L10.log_STOCK L15.log_STOCK ///
L.housecostrent L10.housecostrent   ///
L.housecostnominal L10.housecostnominal  ///
 ///
L10.gdp_debt_rate ///
L10.gdp_income_rate ///
L7.ltint L15.ltint ///
L.gdp ///
L.cpi ///
,fe r
est store FE_robust

xtreg log_REITs ///
L.log_STOCK L10.log_STOCK L15.log_STOCK ///
L.housecostrent L10.housecostrent   ///
L.housecostnominal L10.housecostnominal  ///
 ///
L10.gdp_debt_rate ///
L10.gdp_income_rate ///
L7.ltint L15.ltint ///
L.gdp ///
L.cpi ///
,re
est store RE

xtreg log_REITs ///
L.log_STOCK L10.log_STOCK L15.log_STOCK ///
L.housecostrent L10.housecostrent   ///
L.housecostnominal L10.housecostnominal  ///
 ///
L10.gdp_debt_rate ///
L10.gdp_income_rate ///
L7.ltint L15.ltint ///
gdp ///
cpi ///
,re r
est store RE_robust

* - Hausman test 认为使用随机效应
hausman FE RE,constant sigmamore

* - 展示回归结果并保存
esttab FE FE_robust RE RE_robust using result1.rtf,se r2 mtitle


// PART2: 事件冲击模型时间断点回归:1990,1998,2009
gen year_center_1990 = year - 1990
gen flag_1990 = (year >= 1990)
gen year_flag_1990 = year_center_1990*flag_1990
reg log_REITs year_center_1990 flag_1990 year_flag_1990

gen year_center_1998 = year - 1998
gen flag_1998 = (year >= 1998)
gen year_flag_1998 = year_center_1998*flag_1998
reg log_REITs year_center_1998 flag_1998 year_flag_1998

gen year_center_2009 = year - 2009
gen flag_2009 = (year >= 2009)
gen year_flag_2009 = year_center_2009*flag_2009
reg log_REITs year_center_2009 flag_2009 year_flag_2009

// 注意：需要导入rd包：ssc install rd, replace
rd log_REITs year,z0(1990) gr mbw(100)
est store test_1990

rd log_REITs year,z0(1998) gr mbw(100)
est store test_1998

rd log_REITs year,z0(2009) gr mbw(100)
est store test_2009

esttab test_1990 test_1998 test_2009 using result2.rtf,se r2 mtitle
