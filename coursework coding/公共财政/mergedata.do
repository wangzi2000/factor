*** mergedata 0613
clear
set more off

cap n log close
cd "D:\方清源\北大学习\大二（下）\公共财政理论与政策\公共财政 Project\Terrorism Research\Data\Data_Version_0601"

log using "mergedata.log",replace

use GTD_TR.dta,clear
	drop CC
	order CountryCode year
	label var TR_0_4 "terrorism factor lag=0 to 4"
	label var TR_1_5 "terrorism factor lag=1 to 5"
	merge m:1 CountryCode using MOC.dta
	drop if _m!=3
	drop _m
	keep CountryCode year TR_0_4 TR_1_5 TableName Region IncomeGroup
	order TableName CountryCode year
	gen d_OECD=1 if TableName=="Australia"|TableName=="Austria"|TableName=="Belgium"|TableName=="Canada"|TableName=="Chile"|TableName=="Colombia"|TableName=="Czech Republic"|TableName=="Denmark"|TableName=="Estonia"|TableName=="Finland"|TableName=="France"|TableName=="Germany"|TableName=="Greece"|TableName=="Hungary"|TableName=="Iceland"|TableName=="Ireland"|TableName=="Israel"|TableName=="Italy"|TableName=="Japan"|TableName=="Korea, Rep."|TableName=="Latvia"|TableName=="Lithuania"|TableName=="Luxembourg"|TableName=="Mexico"|TableName=="Netherlands"|TableName=="New Zealand"|TableName=="Norway"|TableName=="Poland"|TableName=="Portugal"|TableName=="Slovak Republic"|TableName=="Slovenia"|TableName=="Spain"|TableName=="Sweden"|TableName=="Switzerland"|TableName=="Turkey"|TableName=="United Kingdom"|TableName=="United States"
	replace d_OECD=0 if d_OECD==.
	
	**WB_selected
	merge 1:1 CountryCode year using "WB_selected.dta"
	drop if year<1970 | year>2018
	drop if _m!=3
	drop _m
	
	**ICRG
	merge 1:1 TableName year using "ICRG.dta"
	drop if _m==2
	drop _m
	
	replace TableName="Cote d'Ivoire" if TableName=="Côte d'Ivoire"
	
	**culture segment
	merge m:1 TableName using culture_segment.dta
	replace culture_segment=0 if TableName=="Korea, Dem. People's Rep."
	drop if _m==2
	drop _m
	
	replace TableName="Côte d'Ivoire" if TableName=="Cote d'Ivoire"
	
	**FH
	merge 1:1 TableName year using FH.dta
	drop if _m==2
	drop _m
	
	**KOF
	merge 1:1 TableName year using KOF.dta
	drop if _m==2
	drop _m
	
	**MEPV
	merge 1:1 TableName year using MEPV.dta
	drop if _m==2
	drop _m
	
	**SFI 
	merge 1:1 CountryCode year using SFI.dta
	drop if _m==2
	drop _m
	
	**CSPcoups
	merge 1:1 TableName year using CSPcoups.dta
	drop if _m==2
	drop _m
	
	
	**Policy5
	merge 1:m CountryCode year using Polity5.dta
	drop if _m==2
	drop _m
	
	**6 dimensions
	merge m:1 CountryCode using 6_dimensions.dta
	drop if _m==2
	drop _m
	
	
	**GWF
	merge 1:1 CountryCode year using GWF_all.dta
	drop if _m==2
	drop _m
	
save Data0613.dta,replace

use Data0613.dta,clear

	**rename and label variables
	ren AG_LND_TOTL_K2 landarea
	ren BM_KLT_DINV_WD_GD_ZS FDI_out
	ren BX_KLT_DINV_WD_GD_ZS FDI_in
	ren FS_AST_CGOV_GD_ZS claims_on_gov
	ren FS_AST_PRVT_GD_ZS cred_priv
	ren GC_TAX_IMPT_ZS import_duty
	ren GC_TAX_TOTL_GD_ZS tax_revenue
	ren IT_NET_USER_ZS internet
	ren MS_MIL_XPND_GD_ZS military
	ren NE_CON_GOVT_ZS gov_consumption
	ren NE_EXP_GNFS_ZS export
	ren NE_IMP_GNFS_ZS import
	ren NY_GDP_MKTP_KD_ZG gGDP
	ren NY_GDP_PCAP_CD GDPpcap
	ren SM_POP_REFG ref_asylum
	ren SM_POP_REFG_OR ref_origon
	ren SP_POP_GROW gpop
	ren SP_POP_TOTL pop
	ren SP_URB_TOTL_IN_ZS urban_pop
	order TableName CountryCode year TR_0_4 TR_1_5 Region IncomeGroup d_OECD landarea gGDP GDPpcap pop gpop urban_pop ref_asylum ref_origon FDI_out FDI_in export import internet
	label var culture_segment "文化圈"
	
	**文化方面
	label var idv "Individualism"
	label var pdi "Power Distance"
	label var mas "Masculinity"
	label var uai "Uncertainty Avoidance"
	label var ltowvs "Long-term Orientation"
	label var ivr " Indulgence"
	
	**MEPV
	label var ind "indipendent state"
	label var intind "warfare, in order to gain independence for the state"
	label var intviol "international violence"
	label var intwar "international warfare"
	label var civviol "civil violence"
	label var civwar "civil warfare"
	label var ethviol "ethnic violence"
	label var ethwar "ethnic warfare"
	label var inttot "interstate=INTVIOL + INTWAR"
	label var civtot "societal=CIVVIOL + CIVWAR + ETHVIOL +ETHWAR"
	label var actotal "total magnitudes=INTTOT + CIVTOT"
	label var nborder "number of neighboring states sharing a border"
	label var region "0-9 参见Codebook P6"
	label var nregion "Number of states in the designated geopolitical region."
	
	**SFI
	label var sfi "State Fragility Index=effect+legit"
	label var effect "Effectiveness Score"
	label var legit "Legitimacy Score"
	label var seceff "Security Effectiveness"
	label var secleg "Security Legitimacy"
	label var poleff "Political Effectiveness"
	label var polleg "Political Legitimacy"
	label var ecoeff "Economic Effectiveness"
	label var ecoleg "Economic Legitimacy"
	label var soceff "Social Effectiveness"
	label var socleg "Social Legitimacy"
	
	**CSPcoups
	label var scoup1 "Successful Coups"
	label var atcoup2 "Attempted Coups"
	label var pcoup3 "Coup Plots reported by government officials"
	label var apcoup4 "Alleged Coup Plots announced by government officials"
	label var agcoup "Auto-Coups:subversion of the constitutional order and imposition of an autocratic regime"
	label var foroutex "Ouster of Leadership by Foreign Forces:" 
	label var reboutex "Ouster of Leadership by Rebel Forces"
	label var assassex "Assassination of Executive:"
	label var resignex "Resignation of Executive Due to Poor Performance and/or Loss of Authority"
	
	**Polity5
	label var p5 "Polity5 Case Indicator"
	label var flag "Tentative Coding，编码的置信程度"
	label var fragment "Polity Fragmentation"
	label var democ "Institutionalized Democracy"
	label var autoc "Institutionalized Autocracy"
	label var polity "Combined Polity Score"
	label var polity2 "Revised Combined Polity Score"
	label var durable "Regime Durability"
	label var xrreg "Regulation of Chief Executive Recruitment"
	label var xrcomp "Competitiveness of Executive Recruitment"
	label var xropen "Openness of Executive Recruitment"
	label var xconst "Executive Constraints (Decision Rules)"
	label var parreg "Regulation of Participation"
	label var parcomp "The Competitiveness of Participation"
	label var exrec "Executive Recruitment Concept"
	label var exconst "Executive Constraints Concept"
	label var polcomp "Political Competition Concept"
	label var prior "Prior Polity Code"
	
	drop eday
	drop emonth
	drop eprec
	drop bday
	drop bmonth
	drop bprec
	
	label var eyear "Polity End Year"
	label var interim "Interim Polity Code" 
	
	label var byear "Polity Begin Year"
	label var post "Post Polity Code"
	label var change "Total change in POLITY value"  
	label var d5 "Regime Transition Completed"
	label var sf "State Failure"
	label var regtrans "Regime Transition"
	
	**GWF
	label var gwf_casename "Autocratic regime case name (country name and years);"
	label var gwf_regimetype "Autocratic regime type" 
	label var gwf_next "next regimetype"
	label var gwf_prior "previous regimetype"
	label var gwf_spell "Time-invariant duration of autocratic regime"
	label var gwf_duration "Time-varying duration of autocratic regime up to time t"
	label var gwf_fail "Binary indicator of autocratic regime failure"
	label var gwf_party "是否为party"
	label var gwf_military "是否为military"
	label var gwf_monarchy "是否为monarchy"
	label var gwf_personal "是否为personal"
	label var gwf_nonautocracy "是否为nonautocracy"
	drop gwf_disagree

save Data0613.dta,replace

log close