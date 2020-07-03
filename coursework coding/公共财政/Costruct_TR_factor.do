***New Data clean mission 20200531
** fqy
clear
set more off 

cap n log close

log using cleaning0521.log, replace
cd "D:\方清源\北大学习\大二（下）\公共财政理论与政策\公共财政 Project\Terrorism Research\Data\Cleaned Data_0521"

*** Construct TF 
use GTD_0526.dta,clear
	keep year CountryCode success nkill nwound propvalue
	replace propvalue=0 if propvalue==-99
	
	sort CountryCode year
	ren success NTI_1
	gen NTI_2=1 if NTI_1==0
	replace NTI_2=0 if NTI_2==.
	lab var NTI_2 fail
	replace propvalue=0 if propvalue==.
	ren nkill DHP_1
	ren nwound DHP_2
	ren propvalue DP
	collapse (sum) NTI_1 NTI_2 DHP_1 DHP_2 DP ,by (CountryCode year)
save TF_temp.dta,replace

	keep CountryCode
	duplicates drop	
	cross using year_70_18.dta
	sort CountryCode year
	
	merge 1:1 CountryCode year using TF_temp.dta
	drop _m
	sort CountryCode year
	replace NTI_1=0 if NTI_1==.
	replace NTI_2=0 if NTI_2==.
	replace DHP_1=0 if DHP_1==.
	replace DHP_2=0 if DHP_2==.
	replace DP=0 if DP==.
	
	egen stdNTI_1 = std(NTI_1) 
	egen stdNTI_2 = std(NTI_2) 
	egen stdDHP_1 = std(DHP_1)
	egen stdDHP_2 = std(DHP_2)
	egen stdDP=std(DP)
	
	drop NTI_1 NTI_2 DHP_1 DHP_2 DP
save TF_temp2.dta,replace
	encode CountryCode, gen(CC)
	
	order CC year CountryCode
	
	**转化为面板数据
	xtset CC year,y
	
	**设置滞后项
	gen L1_stdNTI_1=L.stdNTI_1
	gen L2_stdNTI_1=L.L1_stdNTI_1
	gen L3_stdNTI_1=L.L2_stdNTI_1
	gen L4_stdNTI_1=L.L3_stdNTI_1
	gen L5_stdNTI_1=L.L4_stdNTI_1
	
	gen L1_stdNTI_2=L.stdNTI_2
	gen L2_stdNTI_2=L.L1_stdNTI_2
	gen L3_stdNTI_2=L.L2_stdNTI_2
	gen L4_stdNTI_2=L.L3_stdNTI_2
	gen L5_stdNTI_2=L.L4_stdNTI_2
	
	gen L1_stdDHP_1=L.stdDHP_1
	gen L2_stdDHP_1=L.L1_stdDHP_1
	gen L3_stdDHP_1=L.L2_stdDHP_1
	gen L4_stdDHP_1=L.L3_stdDHP_1
	gen L5_stdDHP_1=L.L4_stdDHP_1
	
	gen L1_stdDHP_2=L.stdDHP_2
	gen L2_stdDHP_2=L.L1_stdDHP_2
	gen L3_stdDHP_2=L.L2_stdDHP_2
	gen L4_stdDHP_2=L.L3_stdDHP_2
	gen L5_stdDHP_2=L.L4_stdDHP_2
	
	gen L1_stdDP=L.stdDP
	gen L2_stdDP=L.L1_stdDP
	gen L3_stdDP=L.L2_stdDP
	gen L4_stdDP=L.L3_stdDP
	gen L5_stdDP=L.L4_stdDP
	
	gen mean_NTI_1_04=(stdNTI_1+L1_stdNTI_1 +L2_stdNTI_1+L3_stdNTI_1+L4_stdNTI_1)/5
	gen mean_NTI_1_15=(L1_stdNTI_1 +L2_stdNTI_1+L3_stdNTI_1+L4_stdNTI_1+L5_stdNTI_1)/5
	
	gen mean_NTI_2_04=(stdNTI_2+L1_stdNTI_2 +L2_stdNTI_2+L3_stdNTI_2+L4_stdNTI_2)/5
gen mean_NTI_2_15=(L1_stdNTI_2 +L2_stdNTI_2+L3_stdNTI_2+L4_stdNTI_2+L5_stdNTI_2)/5

	gen mean_DHP_1_04=(stdDHP_1+L1_stdDHP_1 +L2_stdDHP_1+L3_stdDHP_1+L4_stdDHP_1)/5
gen mean_DHP_1_15=(L1_stdDHP_1 +L2_stdDHP_1+L3_stdDHP_1+L4_stdDHP_1+L5_stdDHP_1)/5

	gen mean_DHP_2_04=(stdDHP_2+L1_stdDHP_2 +L2_stdDHP_2+L3_stdDHP_2+L4_stdDHP_2)/5
gen mean_DHP_2_15=(L1_stdDHP_2 +L2_stdDHP_2+L3_stdDHP_2+L4_stdDHP_2+L5_stdDHP_2)/5

	gen mean_DP_04=(stdDP+L1_stdDP +L2_stdDP+L3_stdDP+L4_stdDP)/5
	gen mean_DP_15=(L1_stdDP +L2_stdDP+L3_stdDP+L4_stdDP+L5_stdDP)/5
	
	gen TR_0_4=mean_NTI_1_04+mean_NTI_2_04*0.5+mean_DHP_1_04*3+mean_DHP_2_04*0.5+mean_DP_04*2
	gen TR_1_5=mean_NTI_1_15+mean_NTI_2_15*0.5+mean_DHP_1_15*3+mean_DHP_2_15*0.5+mean_DP_15*2
	
	keep CC year CountryCode TR_0_4 TR_1_5
	
save GTD_TR.dta,replace

log close