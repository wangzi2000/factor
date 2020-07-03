****Causal Inference IV***
***20200616 fqy

clear
set more off

cap n log close
cd "D:\方清源\北大学习\大二（下）\公共财政理论与政策\公共财政 Project\Terrorism Research\Code"

log using "Causal Inference.log",replace

***Some control variable
*i.region1 i.incomegroup landarea gGDP GDPpcap pop gpop urban_pop ref_asylum ref_origon FDI_out FDI_in export import internet claims_on_gov import_duty tax_revenue military gov_consumption confucian_region sorth_asia_region west_region Islam_region east_europe _region confucian_region sorth_asia_region west_region Islam_region east_europe_region

***Part1:数据整理 
***1985-2010
use .\Data_Version_0613\Data0613.dta,clear
	merge 1:1 CountryCode year using .\Data_Version_0613\TF_temp2.dta
	gen TR=stdNTI_1*1+stdNTI_2*0.5+stdDHP_1*3+stdDHP_2*0.5+stdDP*2
	drop _m stdNTI* stdDHP* stdDP CountryCode
	order TableName year TR TR_0_4 TR_1_5
	
	keep if year >= 1985
	keep if year <= 2017

	encode TableName, gen(tablename)
	encode Region,gen(region1)
	encode IncomeGroup,gen(incomegroup)

	gen confucian_region = (culture_segment == 1)
	gen sorth_asia_region = (culture_segment == 2)
	gen west_region = (culture_segment == 3)
	gen Islam_region = (culture_segment == 4)
	gen east_europe_region = (culture_segment == 5)

	gen gov_quality = icrg_corruption + icrg_law_order + icrg_bureaucracy_quality
	
	drop TR_0_4
	drop TableName Region IncomeGroup
	
	**文化心理要素
	order tablename year TR TR_1_5 d_OECD culture_segment confucian_region sorth_asia_region west_region Islam_region east_europe_region pdi idv mas uai ltowvs ivr
	
	**Economic Fundamental Control
	order region1 incomegroup landarea gGDP GDPpcap pop gpop urban_pop,a(ivr)
	
	**Country Openness control
	order ref_asylum ref_origon FDI_out FDI_in export import internet,a(urban_pop)
	
	** Income and expenditure of the government control
	order claims_on_gov import_duty tax_revenue military gov_consumption,a(internet)
	
	**Government capacity
	order gov_quality,a(cred_priv)
	order sfi effect legit seceff secleg poleff polleg ecoeff ecoleg soceff socleg, a(icrg_bureaucracy_quality)
	
	drop inverse_*
	drop KOF*
	drop nborder region nregion
	
**  region1 incomegroup landarea gGDP GDPpcap pop gpop urban_pop ref_asylum ref_origon FDI_out FDI_in export import internet claims_on_gov import_duty tax_revenue military gov_consumption 

	replace status="NF" if status =="NF "
	replace status="PF" if status =="PF "
	encode status, gen (status1)
	
	order status1,a(cl)
	drop status
	
save data_0617.dta,replace
	
***Part2 IV estimation
use data_0617.dta,clear
	xtset tablename year
	*drop if year<2001
	
	gen govqu_pr = gov_quality*pr
	gen govqu_cl = gov_quality*cl
	gen govqu_democ = gov_quality*democ
	gen govqu_autoc = gov_quality*autoc

	gen cre_pr = cred_priv*pr
	gen cre_cl = cred_priv*cl
	gen cre_democ = cred_priv*democ
	gen cre_autoc = cred_priv*autoc
	
	*gen democsq=democ^2
	*gen autocsq=autoc^2
	
	keep if year<2011
	*drop if year<1985
	
	replace gwf_regimetype=gwf_nonautocracy if gwf_regimetype=="NA"
	
	drop if gwf_regimetype==""
	replace gwf_prior="None" if gwf_prior==""
	
	***生成需要的dummy
	gen gwf=gwf_regimetype
	gen gwf_p=gwf_prior
	
	drop if gwf=="provisional"
	
	replace gwf="d" if gwf=="democracy"
	replace gwf="m" if gwf=="foreign-occupied" | gwf=="indirect military" |gwf=="military" |gwf=="warlord"|gwf=="warlord/foreign-occupied"
	replace gwf="o" if gwf=="oligarchy" | gwf=="monarchy" |gwf=="personal"
	replace gwf="p" if gwf=="party"
	replace gwf="m_o" if gwf=="military-personal"
	replace gwf="p_m" if gwf=="party-military" 
	replace gwf="p_m_o" if gwf=="party-military-personal"
	replace gwf="p_o" if gwf=="party-personal"

	drop if gwf_p=="not-independent" | gwf_p=="provisional"| gwf_p=="tthreat"
	replace gwf_p="d" if gwf_p=="democracy"
	replace gwf_p="m" if gwf_p=="foreign-occupied" | gwf_p=="indirect military" |gwf_p=="military" |gwf_p=="warlord"|gwf_p=="warlord/foreign-occupied"
	replace gwf_p="o" if gwf_p=="oligarchy" | gwf_p=="monarchy" |gwf_p=="personal"
	replace gwf_p="p" if gwf_p=="party"
	replace gwf_p="m_o" if gwf_p=="military-personal"|gwf_p=="milpersonal"
	replace gwf_p="p_m" if gwf_p=="party-military" |gwf_p=="spmilitary"
	replace gwf_p="p_m_o" if gwf_p=="party-military-personal"
	replace gwf_p="p_o" if gwf_p=="party-personal"|gwf_p=="sppersonal"
	tab gwf_p
	tab gwf
	
	**形成交叉项 
	gen d_dm = 1 if (gwf=="d") & (gwf_p=="m"|gwf_p=="m_o" | gwf_p=="p_m_o"| gwf_p=="p_m")
	gen d_md = 1 if (gwf=="m" |gwf == "p_m_o" |gwf=="m_o"|gwf=="p_m") & (gwf_p=="d")
	
	gen d_do=1 if (gwf=="d") & (gwf_p=="o"|gwf_p=="m_o" | gwf_p=="p_m_o"| gwf_p=="p_o")
	gen d_od = 1 if (gwf=="o" |gwf == "p_m_o" |gwf=="m_o"|gwf=="p_o") & (gwf_p=="d")
	
	gen d_dp = 1 if (gwf=="d") & (gwf_p=="p" | gwf_p=="p_o" | gwf_p=="p_m_o"| gwf_p=="p_m")
	gen d_pd = 1 if (gwf=="p" |gwf == "p_m_o" |gwf=="p_o"|gwf=="p_m") & (gwf_p=="d")
	
	gen d_po = 1 if (gwf=="p" |gwf == "p_m_o" |gwf=="p_o"|gwf=="p_m") & (gwf_p=="o"|gwf_p=="m_o" | gwf_p=="p_m_o"| gwf_p=="p_o")
	gen d_op = 1 if (gwf=="o" |gwf == "p_m_o" |gwf=="p_o"|gwf=="m_o") & (gwf_p=="p"|gwf_p=="p_o" | gwf_p=="p_m_o"| gwf_p=="p_m")
	
	gen d_pm = 1 if (gwf=="p" |gwf == "p_m_o" |gwf=="p_o"|gwf=="p_m") & (gwf_p=="m"|gwf_p=="m_o" | gwf_p=="p_m_o"| gwf_p=="p_m")
	gen d_mp = 1 if (gwf=="m" |gwf == "p_m_o" |gwf=="m_o"|gwf=="p_m") & (gwf_p=="p"|gwf_p=="p_o" | gwf_p=="p_m_o"| gwf_p=="p_m")
	
	gen d_om = 1 if (gwf=="o" |gwf == "p_m_o" |gwf=="p_o"|gwf=="m_o") & (gwf_p=="m"|gwf_p=="m_o" | gwf_p=="p_m_o"| gwf_p=="p_m")
	gen d_mo = 1 if (gwf=="m" |gwf == "p_m_o" |gwf=="m_o"|gwf=="p_m") & (gwf_p=="o"|gwf_p=="m_o" | gwf_p=="p_m_o"| gwf_p=="p_o")
	
	gen d_dN = 1 if (gwf=="d") & (gwf_p=="None")
	gen d_oN = 1 if (gwf=="o" |gwf == "p_m_o" |gwf=="p_o"|gwf=="m_o") & (gwf_p=="None")
	gen d_mN = 1 if (gwf=="m" |gwf == "p_m_o" |gwf=="m_o"|gwf=="p_m") & (gwf_p=="None")
	gen d_pN = 1 if (gwf=="p" |gwf == "p_m_o" |gwf=="p_o"|gwf=="p_m") & (gwf_p=="None")
	
foreach var in d_dN d_mN d_oN d_pN d_dm  d_md d_do d_od d_dp d_pd d_mo d_om d_mp d_pm d_op d_po{
	replace `var' =0 if `var'==.
}
	
	***对政府能力的影响
	/*areg gov_quality d_dN d_mN d_oN d_pN d_dm  d_md d_do d_od d_dp d_pd d_mo d_om d_mp d_pm d_op d_po i.region1 i.incomegroup landarea gGDP GDPpcap pop gpop urban_pop FDI_out FDI_in export import confucian_region sorth_asia_region west_region Islam_region east_europe_region, a(year) r
	
	areg cred_priv d_dN d_mN d_oN d_pN d_dm  d_md d_do d_od d_dp d_pd d_mo d_om d_mp d_pm d_op d_po i.region1 i.incomegroup landarea gGDP GDPpcap pop gpop urban_pop FDI_out FDI_in export import confucian_region sorth_asia_region west_region Islam_region east_europe_region, a(year) r*/
	
	***对民主程度的影响
	/*areg pr d_dN d_mN d_oN d_pN d_dm  d_md d_do d_od d_dp d_pd d_mo d_om d_mp d_pm d_op d_po i.region1 i.incomegroup landarea gGDP GDPpcap pop gpop urban_pop FDI_out FDI_in export import confucian_region sorth_asia_region west_region Islam_region east_europe_region, a(year) r
	areg cl d_dN d_mN d_oN d_pN d_dm  d_md d_do d_od d_dp d_pd d_mo d_om d_mp d_pm d_op d_po i.region1 i.incomegroup landarea gGDP GDPpcap pop gpop urban_pop FDI_out FDI_in export import confucian_region sorth_asia_region west_region Islam_region east_europe_region, a(year) r

	areg autoc d_dN d_mN d_oN d_pN d_dm  d_md d_do d_od d_dp d_pd d_mo d_om d_mp d_pm d_op d_po i.region1 i.incomegroup landarea gGDP GDPpcap pop gpop urban_pop FDI_out FDI_in export import confucian_region sorth_asia_region west_region Islam_region east_europe_region if autoc>-10, a(year) r
	areg democ d_dN d_mN d_oN d_pN d_dm  d_md d_do d_od d_dp d_pd d_mo d_om d_mp d_pm d_op d_po i.region1 i.incomegroup landarea gGDP GDPpcap pop gpop urban_pop FDI_out FDI_in export import confucian_region sorth_asia_region west_region Islam_region east_europe_region if democ>-10, a(year) r*/
	
	**以政权更替作为IV
	ivregress 2sls TR_1_5 i.region1 i.incomegroup i.year landarea gGDP GDPpcap pop gpop urban_pop FDI_out FDI_in export import confucian_region sorth_asia_region west_region Islam_region east_europe_region (gov_quality cred_priv pr cl = d_dN d_mN d_oN d_pN d_dm  d_md d_do d_od d_dp d_pd d_mo d_om d_mp d_pm d_op d_po), r first
	
	ivregress 2sls TR_1_5 i.region1 i.incomegroup i.year landarea gGDP GDPpcap pop gpop urban_pop FDI_out FDI_in export import confucian_region sorth_asia_region west_region Islam_region east_europe_region (gov_quality cred_priv pr cl autoc democ = d_dN d_mN d_oN d_pN d_dm  d_md d_do d_od d_dp d_pd d_mo d_om d_mp d_pm d_op d_po) if (autoc>-10 & democ >-10), r first
	
	**考虑交乘项
	
	ivregress 2sls TR_1_5 i.region1 i.incomegroup i.year landarea gGDP GDPpcap pop gpop urban_pop FDI_out FDI_in export import confucian_region sorth_asia_region west_region Islam_region east_europe_region (c.gov_quality##c.pr c.gov_quality##c.cl  cred_priv = d_dN d_mN d_oN d_pN d_dm  d_md d_do d_od d_dp d_pd d_mo d_om d_mp d_pm d_op d_po), r first
	
	ivregress 2sls TR_1_5 i.region1 i.incomegroup i.year landarea gGDP GDPpcap pop gpop urban_pop FDI_out FDI_in export import confucian_region sorth_asia_region west_region Islam_region east_europe_region (c.gov_quality##c.pr c.gov_quality##c.cl c.gov_quality##c.autoc c.gov_quality##c.democ cred_priv = d_dN d_mN d_oN d_pN d_dm  d_md d_do d_od d_dp d_pd d_mo d_om d_mp d_pm d_op d_po) if (autoc>-10 & democ >-10), r first

	ivregress 2sls TR i.region1 i.incomegroup i.year landarea gGDP GDPpcap pop gpop urban_pop FDI_out FDI_in export import confucian_region sorth_asia_region west_region Islam_region east_europe_region (c.gov_quality##c.autoc c.gov_quality##c.democ cred_priv pr cl = d_dN d_mN d_oN d_pN d_dm  d_md d_do d_od d_dp d_pd d_mo d_om d_mp d_pm d_op d_po) if (autoc>-10 & democ >-10), r first

log close