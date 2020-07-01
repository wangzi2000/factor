// PART1: TFP与行业进入退出率的关系
// 结果


// 使用更稳健的xtgls
xtgls tfp ///
exit_rate entry_rate ///
E_E ///
mean_invest mean_fix_assets acc_receivable_indus ass_indus ///
income_indus cost_indus material_indus ///
entry_sunk_cost ///

est store TFP

// PART2: 什么决定了行业的进入与退出率
// 

// 1. 行业内部
// 退出率与行业内进入率（+）、TFP（-）
// 平均投资（+）、平均应收款（-）、平均资产（+）
// 平均工资（-）显著相关

xtgls exit_rate ///
tfp entry_rate ///
mean_invest mean_fix_assets acc_receivable_indus ass_indus ///
income_indus cost_indus material_indus ///
entry_sunk_cost ///
wage wage_emp ///

est store EXIT_indus

// 进入率与行业内退出率（+）、TFP（+）
// 平均应收款（-）、平均主营业务收入（+）、平均中间品价格（-）
// 进入沉没成本（-）
// 平均工资（-）、平均雇员（+）

xtgls entry_rate ///
tfp exit_rate ///
mean_invest mean_fix_assets acc_receivable_indus ass_indus ///
income_indus cost_indus material_indus ///
entry_sunk_cost ///
wage wage_emp, ///

est store ENTRY_indus

// 2.宏观市场

// 退出率与行业总体进入率（+）
// 平均固定成本（+）、平均应收款（+）
// 平均主营业务收入（-）、平均主营业务费用（+）
// 平均工资（-）、平均雇员（+）

xtgls exit_rate ///
tfp entry_rate ///
invest_mean_all fix_invest_mean_all acc_receivable_indus_all ass_all ///
income_indus_all cost_main_al material_indus_all ///
entry_sunk_cost ///
wage wage_emp, ///


est store EXIT_all

// 进入率与行业总体所有指标显著相关

xtgls entry_rate ///
tfp exit_rate ///
invest_mean_all fix_invest_mean_all acc_receivable_indus_all ass_all ///
income_indus_all cost_main_al material_indus_all ///
entry_sunk_cost ///
wage wage_emp ///

est store ENTRY_all

esttab TFP,se ar2 mtitle
esttab EXIT_indus EXIT_all ENTRY_indus ENTRY_all, se ar2 mtitle

// esttab TFP using tfp.rtf,se ar2 mtitle
esttab EXIT_indus ENTRY_indus , se ar2 mtitle
esttab EXIT_all ENTRY_all , se ar2 mtitle

esttab EXIT_indus ENTRY_indus using exit_entry_1.rtf, se ar2 mtitle
esttab EXIT_all ENTRY_all using exit_entry_2.rtf, se ar2 mtitle
