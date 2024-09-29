est clear

cap program drop mmsave100

program define mmsave100
	matrix T = r(table)
    capture matrix drop b
    capture matrix drop se
	matrix b 	= T[1,1...] * 100
	matrix se 	= T[2,1...] * 100
	ereturn post b
    quietly estadd matrix se
end

cap program drop mmsave1000

program define mmsave1000
	matrix T = r(table)
    capture matrix drop b
    capture matrix drop se
	matrix b 	= T[1,1...] * 1000
	matrix se 	= T[2,1...] * 1000
	ereturn post b
    quietly estadd matrix se
end

cap cd "D:\Drives\Google Drive\Res\BRFSS\data"
cap cd "/Users/ortsang/Library/CloudStorage/GoogleDrive-kei.czeng@gmail.com/我的云端硬盘/Res/BRFSS/data"

* loading state tempfile
tempfile abb
import delimited "stateabb.csv", varnames(1) clear 
replace state = upper(state)
save `abb', replace

use BRFSS1119, clear
merge m:1 state using `abb', nogen

merge m:1 state year using ./policy/LGBT/leader/leader
drop if _merge== 2
drop _merge

merge m:1 state year using "./policy/LGBT/gaycommunity/Damron events panel 2012-2019.dta"
keep if _merge == 3
drop _merge

egen evt_all = rowtotal(Breast_Cancer_Benefits-unclassified)

merge m:1 state using "./policy/LGBT/gaycommunity/Gay guide 2019.dta"
keep if _merge == 3
drop _merge

egen gui_all = rowtotal(Accommodations-Websites)

egen leader_all = rowtotal(dem_state_leg rep_state_leg dem_state_exe all_local_exe dem_local_leg other_local_leg rep_local_leg)
egen lrepub_all = rowtotal(rep_state_leg rep_local_leg)
egen ldemoc_all = rowtotal(dem_state_leg dem_state_exe dem_local_leg)
egen leader_pre_all = rowtotal(pre_dem_state_leg pre_rep_state_leg pre_dem_state_exe pre_all_local_exe pre_dem_local_leg pre_other_local_leg pre_rep_local_leg)

merge m:1 state year using "./HCD/hcspecific.dta"
drop if _merge == 2
drop _merge

rename (Raceethnicity-Genderidentity) (hc_=)

rename (numadult-hivtst6 racec drnkany5 droccdy_) _= //change name ind charatertics 
recode _menthlth _physhlth _poorhlth _income2 (77 99 = .) (88 = 0)
drop if _sex > 2

replace _numadult = 10 if _numadult >= 10

label define _ghlthl 1 "Excellent" 2 "Very good" 3 "Good" 4 "Fair" 5 "Poor"
label values _genhlth _ghlthl	

recode _hlthplan (2 7 9 = 0)

recode _racec (5 6 7 8 9 = 5)
label define _racel 1 "White" 2 "Black" 3 "Hispanic" 4 "Asian" 5 "Others"
label values _racec _racel	

foreach v of varlist _menthlth _physhlth _genhlth _poorhlth {
	
	gen `v'_d 		= `v'>0
	
	cap drop quartile
	egen quartile = xtile(`v'), by(year) n(4)
	gen `v'exm_d 	= quartile==4
	
}

gen lgbt = (_numadult == 2 & (_nummen == 2 | _numwomen == 2))
gen cisf = (_numadult == 2 & (_nummen == 1 & _numwomen == 1))

encode state, g(nstate)

gen _quarter = 1 		if month<4
replace _quarter = 2 	if month<7 	& _quarter==.
replace _quarter = 3 	if month<10 & _quarter==.
replace _quarter = 4	if _quarter==.

replace _menthlth = 0 if _menthlth == .

*** yearly
egen hc_crntyr	= rowtotal(quarter1 quarter2 quarter3 quarter4)

tempfile hc
preserve
keep statefip year hc_crntyr quarter4
replace year = year + 1
rename (hc_crntyr quarter4) (hc_prvsyr quarter4_pyear)
duplicates drop statefip year, force
save `hc', replace
restore

merge m:1 statefip year using `hc'
drop if _merge == 2
drop _merge

keep if _age_g >= 2 // keeping only age above 16
keep if _numadult == 2

keep if (lgbt==1 | cisf==1)
drop if _income2 == . | _racec == . | agencies == . | _genhlth == . | ///
	_employ == . | _educa == . | _hlthplan == . | hc_crntyr == . | hc_prvsyr == .
	
global covariates i._age_g i._sex i._genhlth i._racec ///
	i._income2 i._employ i._educa ///
	agencies pop highschool malefemaleratio unemployment ///
	enroll i.acaexpan c.gui_all c.evt_all 

* run reg-leaders first

gen LSSM = 0
replace LSSM = 1 if strpos(stateab, "MA")>0 & year >= 2004
replace LSSM = 1 if strpos(stateab, "CT")>0 & year >= 2009
replace LSSM = 1 if inlist(stateab, "DC","IA","VT","NH") & year >= 2010
replace LSSM = 1 if inlist(stateab, "NY") & year >= 2012
replace LSSM = 1 if inlist(stateab, "ME","WA") & year >= 2013
replace LSSM = 1 if inlist(stateab, "CA","DE","HI","MD","MN","NJ","NM","RI") & year >= 2014
replace LSSM = 1 if inlist(stateab, "AK","AZ","CO","FL","ID","IN","IL","MT") & year >= 2015
replace LSSM = 1 if inlist(stateab, "NC","NV","OK","OR","PA","SC","UT","VA") & year >= 2015
replace LSSM = 1 if inlist(stateab, "WV","WI","WY") & year >= 2015
replace LSSM = 1 if year >= 2016

*************************************************
* 		Hate crime X All Leaders				*
*************************************************

logit _menthlth_d c.hc_crntyr##(c.leader_all c.leader_pre_all) c.hc_prvsyr ///
	$covariates i.nstate i.year#i.month, vce(cluster nstate)
	
margins, dydx(c.leader_all) post
mmsave100
eststo ht_ext_all
	
qui logit _menthlthexm_d c.hc_crntyr##(c.leader_all c.leader_pre_all) c.hc_prvsyr ///
	$covariates i.nstate i.year#i.month, vce(cluster nstate)
	
margins, dydx(c.leader_all) post
mmsave100
eststo ht_eext_all

qui ppmlhdfe _menthlth c.hc_crntyr##(c.leader_all c.leader_pre_all) c.hc_prvsyr ///
	$covariates, absorb(i.nstate i.year#i.month) vce(cluster nstate) d

margins, dydx(c.leader_all) noestimcheck post
mmsave1000
eststo ht_int_all

*************************************************
* 		Hate crime X Dem Leaders			
*************************************************

qui logit _menthlth_d c.hc_crntyr##(c.ldemoc_all c.leader_pre_all) c.hc_prvsyr ///
	$covariates i.nstate i.year#i.month, vce(cluster nstate)
	
margins, dydx(c.ldemoc_all) post
mmsave100
eststo ht_ext_dem
	
qui logit _menthlthexm_d c.hc_crntyr##(c.ldemoc_all c.leader_pre_all) c.hc_prvsyr ///
	$covariates i.nstate i.year#i.month, vce(cluster nstate)
	
margins, dydx(c.ldemoc_all) post
mmsave100
eststo ht_eext_dem

qui ppmlhdfe _menthlth c.hc_crntyr##(c.ldemoc_all c.leader_pre_all) c.hc_prvsyr ///
	$covariates, absorb(i.nstate i.year#i.month) vce(cluster nstate) d

margins, dydx(c.ldemoc_all) noestimcheck post
mmsave1000
eststo ht_int_dem

*************************************************
* 		Hate crime X Rep Leaders			
*************************************************

qui logit _menthlth_d c.hc_crntyr##(c.lrepub_all c.leader_pre_all) c.hc_prvsyr ///
	$covariates i.nstate i.year#i.month, vce(cluster nstate)
	
margins, dydx(c.lrepub_all) post
mmsave100
eststo ht_ext_rep
	
qui logit _menthlthexm_d c.hc_crntyr##(c.lrepub_all c.leader_pre_all) c.hc_prvsyr ///
	$covariates i.nstate i.year#i.month, vce(cluster nstate)
	
margins, dydx(c.lrepub_all) post
mmsave100
eststo ht_eext_rep

qui ppmlhdfe _menthlth c.hc_crntyr##(c.lrepub_all c.leader_pre_all) c.hc_prvsyr ///
	$covariates, absorb(i.nstate i.year#i.month) vce(cluster nstate) d

margins, dydx(c.lrepub_all) noestimcheck post
mmsave1000
eststo ht_int_rep

esttab ht* using "../output/PubHealth/tab3/tab3_baseline.csv", replace ///
	se noomit nobase ///
	star(* 0.10 ** 0.05 *** 0.01) ///
	b(%9.4f) se(%9.4f) mtitles 
	
est clear

*********************************************
* 		Hate crime X All Leaders X SSH
*********************************************

qui logit _menthlth_d c.hc_crntyr##(c.leader_all c.leader_pre_all)##i.lgbt c.hc_prvsyr ///
	$covariates i.nstate i.year#i.month, vce(cluster nstate)
	
margins, dydx(c.leader_all) over(lgbt) post
mmsave100
eststo ht_ext_all_ssh
	
qui logit _menthlthexm_d c.hc_crntyr##(c.leader_all c.leader_pre_all)##i.lgbt c.hc_prvsyr ///
	$covariates i.nstate i.year#i.month, vce(cluster nstate)
	
margins, dydx(c.leader_all) over(lgbt) post
mmsave100
eststo ht_eext_all_ssh

qui ppmlhdfe _menthlth c.hc_crntyr##(c.leader_all c.leader_pre_all)##i.lgbt c.hc_prvsyr ///
	$covariates, absorb(i.nstate i.year#i.month) vce(cluster nstate) d

margins, dydx(c.leader_all) over(lgbt) noestimcheck post
mmsave1000
eststo ht_int_all_ssh

*********************************************
* 	Hate crime X Democrate Leaders X SSH ****
*********************************************

qui logit _menthlth_d c.hc_crntyr##(c.ldemoc_all c.leader_pre_all)##i.lgbt c.hc_prvsyr ///
	$covariates i.nstate i.year#i.month, vce(cluster nstate)

margins, dydx(c.ldemoc_all) over(lgbt) post
mmsave100
eststo ht_ext_dem_ssh
	
qui logit _menthlthexm_d c.hc_crntyr##(c.ldemoc_all c.leader_pre_all)##i.lgbt c.hc_prvsyr ///
	$covariates i.nstate i.year#i.month, vce(cluster nstate)
	
margins, dydx(c.ldemoc_all) over(lgbt) post
mmsave100
eststo ht_eext_dem_ssh

qui ppmlhdfe _menthlth c.hc_crntyr##(c.ldemoc_all c.leader_pre_all)##i.lgbt c.hc_prvsyr ///
	$covariates, absorb(i.nstate i.year#i.month) vce(cluster nstate) d

margins, dydx(c.ldemoc_all) over(lgbt) post noestimcheck
mmsave1000
eststo ht_int_dem_ssh

*********************************************
* 	Hate crime X Republican Leaders X SSH ****
*********************************************

qui logit _menthlth_d c.hc_crntyr##(c.lrepub_all c.leader_pre_all)##i.lgbt c.hc_prvsyr ///
	$covariates i.nstate i.year#i.month, vce(cluster nstate)
	
margins, dydx(c.lrepub_all) over(lgbt) post
mmsave100
eststo ht_ext_rep_ssh
	
qui logit _menthlthexm_d c.hc_crntyr##(c.lrepub_all c.leader_pre_all)##i.lgbt c.hc_prvsyr ///
	$covariates i.nstate i.year#i.month, vce(cluster nstate)
	
margins, dydx(c.lrepub_all) over(lgbt) post
mmsave100
eststo ht_eext_rep_ssh

qui ppmlhdfe _menthlth c.hc_crntyr##(c.lrepub_all c.leader_pre_all)##i.lgbt c.hc_prvsyr ///
	$covariates, absorb(i.nstate i.year#i.month) vce(cluster nstate) d

margins, dydx(c.lrepub_all) over(lgbt) post noestimcheck
mmsave1000
eststo ht_int_rep_ssh

esttab ht* using "../output/PubHealth/tab3/tab3_baseline_SSH.csv", replace ///
	se noomit nobase ///
	star(* 0.10 ** 0.05 *** 0.01) ///
	b(%9.4f) se(%9.4f) mtitles 
	
est clear	
	
*************************************************
* 		Hate crime X All Leaders X income	*****			
*************************************************

qui logit _menthlth_d c.hc_crntyr##(c.leader_all c.leader_pre_all)##i._income2 c.hc_prvsyr ///
	$covariates i.nstate i.year#i.month, vce(cluster nstate)
	
margins, dydx(c.leader_all) over(_income2) post
mmsave100
eststo ht_ext_all
	
qui logit _menthlthexm_d c.hc_crntyr##(c.leader_all c.leader_pre_all)##i._income2 c.hc_prvsyr ///
	$covariates i.nstate i.year#i.month, vce(cluster nstate)
	
margins, dydx(c.leader_all) over(_income2) post 
mmsave100
eststo ht_eext_all

qui ppmlhdfe _menthlth c.hc_crntyr##(c.leader_all c.leader_pre_all)##i._income2 c.hc_prvsyr ///
	$covariates, absorb(i.nstate i.year#i.month) vce(cluster nstate) d

margins, dydx(c.leader_all) noestimcheck over(_income2) post
mmsave1000
eststo ht_int_all

*************************************************
* 		Hate crime X Dem Leaders X income 		*			
*************************************************

qui logit _menthlth_d c.hc_crntyr##(c.ldemoc_all c.leader_pre_all)##i._income2 c.hc_prvsyr ///
	$covariates i.nstate i.year#i.month, vce(cluster nstate)
	
margins, dydx(c.ldemoc_all) over(_income2) post
mmsave100
eststo ht_ext_dem
	
qui logit _menthlthexm_d c.hc_crntyr##(c.ldemoc_all c.leader_pre_all)##i._income2 c.hc_prvsyr ///
	$covariates i.nstate i.year#i.month, vce(cluster nstate)
	
margins, dydx(c.ldemoc_all) over(_income2) post
mmsave100
eststo ht_eext_dem

qui ppmlhdfe _menthlth c.hc_crntyr##(c.ldemoc_all c.leader_pre_all)##i._income2 c.hc_prvsyr ///
		$covariates, absorb(i.nstate i.year#i.month) vce(cluster nstate) d

margins, dydx(c.ldemoc_all) noestimcheck over(_income2) post
mmsave1000
eststo ht_int_dem

*************************************************
* 		Hate crime X Rep Leaders X income 		*			
*************************************************

qui logit _menthlth_d c.hc_crntyr##(c.lrepub_all c.leader_pre_all)##i._income2 c.hc_prvsyr ///
	$covariates i.nstate i.year#i.month, vce(cluster nstate)
	
margins, dydx(c.lrepub_all) over(_income2) post
mmsave100
eststo ht_ext_rep
	
qui logit _menthlthexm_d c.hc_crntyr##(c.lrepub_all c.leader_pre_all)##i._income2 c.hc_prvsyr ///
	$covariates i.nstate i.year#i.month, vce(cluster nstate)
	
margins, dydx(c.lrepub_all) over(_income2) post
mmsave100
eststo ht_eext_rep

qui ppmlhdfe _menthlth c.hc_crntyr##(c.lrepub_all c.leader_pre_all)##i._income2 c.hc_prvsyr ///
	$covariates, absorb(i.nstate i.year#i.month) vce(cluster nstate) d

margins, dydx(c.lrepub_all) noestimcheck over(_income2) post
mmsave1000
eststo ht_int_rep

********************************************************
* 		Hate crime X All Leaders X lgbt X income	****
********************************************************

qui logit _menthlth_d c.hc_crntyr##(c.leader_all c.leader_pre_all)##i.lgbt##i._income2 c.hc_prvsyr ///
	$covariates i.nstate i.year#i.month, vce(cluster nstate)
	
margins, dydx(c.leader_all) over(lgbt _income2) post
mmsave100
eststo ht_ext_all_ssh
	
qui logit _menthlthexm_d c.hc_crntyr##(c.leader_all c.leader_pre_all)##i.lgbt##i._income2 c.hc_prvsyr ///
	$covariates i.nstate i.year#i.month, vce(cluster nstate)
	
margins, dydx(c.leader_all) over(lgbt _income2) post
mmsave100
eststo ht_eext_all_ssh

qui ppmlhdfe _menthlth c.hc_crntyr##(c.leader_all c.leader_pre_all)##i.lgbt##i._income2 c.hc_prvsyr ///
	$covariates, absorb(i.nstate i.year#i.month) vce(cluster nstate) d

margins, dydx(c.leader_all) over(lgbt _income2) noestimcheck post
mmsave1000
eststo ht_int_all_ssh

*****************************************************
* 	Hate crime X Democrate Leaders X SSH Xincome ****
*****************************************************

qui logit _menthlth_d c.hc_crntyr##(c.ldemoc_all c.leader_pre_all)##i.lgbt##i._income2 c.hc_prvsyr ///
	$covariates i.nstate i.year#i.month, vce(cluster nstate)

margins, dydx(c.ldemoc_all) over(lgbt _income2) post
mmsave100
eststo ht_ext_dem_ssh
	
qui logit _menthlthexm_d c.hc_crntyr##(c.ldemoc_all c.leader_pre_all)##i.lgbt##i._income2 c.hc_prvsyr ///
	$covariates i.nstate i.year#i.month, vce(cluster nstate)
	
margins, dydx(c.ldemoc_all) over(lgbt _income2) post
mmsave100
eststo ht_eext_dem_ssh

qui ppmlhdfe _menthlth c.hc_crntyr##(c.ldemoc_all c.leader_pre_all)##i.lgbt##i._income2 c.hc_prvsyr ///
	$covariates, absorb(i.nstate i.year#i.month) vce(cluster nstate) d

margins, dydx(c.ldemoc_all) over(lgbt _income2) post noestimcheck
mmsave1000
eststo ht_int_dem_ssh


******************************************************
* 	Hate crime X Republican Leaders X SSH Xincome ****
******************************************************

qui logit _menthlth_d c.hc_crntyr##(c.lrepub_all c.leader_pre_all)##i.lgbt##i._income2 c.hc_prvsyr ///
	$covariates i.nstate i.year#i.month, vce(cluster nstate)
	
margins, dydx(c.lrepub_all) over(lgbt _income2) post
mmsave100
eststo ht_ext_rep_ssh
	
qui logit _menthlthexm_d c.hc_crntyr##(c.lrepub_all c.leader_pre_all)##i.lgbt##i._income2 c.hc_prvsyr ///
	$covariates i.nstate i.year#i.month, vce(cluster nstate)
	
margins, dydx(c.lrepub_all) over(lgbt _income2) post
mmsave100
eststo ht_eext_rep_ssh

qui ppmlhdfe _menthlth c.hc_crntyr##(c.lrepub_all c.leader_pre_all)##i.lgbt##i._income2 c.hc_prvsyr ///
	$covariates, absorb(i.nstate i.year#i.month) vce(cluster nstate) d
	
margins, dydx(c.lrepub_all) over(lgbt _income2) post noestimcheck
mmsave1000
eststo ht_int_rep_ssh

esttab ht* using "../output/PubHealth/tab3/tab3_baselineXincome.csv", replace ///
	se noomit nobase ///
	star(* 0.10 ** 0.05 *** 0.01) ///
	b(%9.4f) se(%9.4f) mtitles 
	
est clear
	
*************************************************
* 		Hate crime X All Leaders X age 			*
*************************************************

logit _menthlth_d c.hc_crntyr##(c.leader_all c.leader_pre_all)##i._age_g c.hc_prvsyr ///
	$covariates i.nstate i.year#i.month, vce(cluster nstate)
	
margins, dydx(c.leader_all) over(_age_g) post
mmsave100
eststo ht_ext_all
	
logit _menthlthexm_d c.hc_crntyr##(c.leader_all c.leader_pre_all)##i._age_g c.hc_prvsyr ///
	$covariates i.nstate i.year#i.month, vce(cluster nstate)
	
margins, dydx(c.leader_all) over(_age_g) post
mmsave100
eststo ht_eext_all

ppmlhdfe _menthlth c.hc_crntyr##(c.leader_all c.leader_pre_all)##i._age_g c.hc_prvsyr ///
	$covariates, absorb(i.nstate i.year#i.month) vce(cluster nstate) d

margins, dydx(c.leader_all) over(_age_g) noestimcheck post
mmsave1000
eststo ht_int_all

*************************************************
* 		Hate crime X Dem Leaders X age 			*		
*************************************************

qui logit _menthlth_d c.hc_crntyr##(c.ldemoc_all c.leader_pre_all)##i._age_g c.hc_prvsyr ///
	$covariates i.nstate i.year#i.month, vce(cluster nstate)
	
margins, dydx(c.ldemoc_all) over(_age_g) post
mmsave100
eststo ht_ext_dem
	
qui logit _menthlthexm_d c.hc_crntyr##(c.ldemoc_all c.leader_pre_all)##i._age_g c.hc_prvsyr ///
	$covariates i.nstate i.year#i.month, vce(cluster nstate)
	
margins, dydx(c.ldemoc_all) over(_age_g) post
mmsave100
eststo ht_eext_dem

qui ppmlhdfe _menthlth c.hc_crntyr##(c.ldemoc_all c.leader_pre_all)##i._age_g c.hc_prvsyr ///
	$covariates, absorb(i.nstate i.year#i.month) vce(cluster nstate) d

margins, dydx(c.ldemoc_all) over(_age_g) noestimcheck post
mmsave1000
eststo ht_int_dem

*************************************************
* 		Hate crime X Rep Leaders X age 			*			
*************************************************

qui logit _menthlth_d c.hc_crntyr##(c.lrepub_all c.leader_pre_all)##i._age_g c.hc_prvsyr ///
	$covariates i.nstate i.year#i.month, vce(cluster nstate)
	
margins, dydx(c.lrepub_all) over(_age_g) post
mmsave100
eststo ht_ext_rep
	
qui logit _menthlthexm_d c.hc_crntyr##(c.lrepub_all c.leader_pre_all)##i._age_g c.hc_prvsyr ///
	$covariates i.nstate i.year#i.month, vce(cluster nstate)
	
margins, dydx(c.lrepub_all) over(_age_g) post
mmsave100
eststo ht_eext_rep

qui ppmlhdfe _menthlth c.hc_crntyr##(c.lrepub_all c.leader_pre_all)##i._age_g c.hc_prvsyr ///
	$covariates, absorb(i.nstate i.year#i.month) vce(cluster nstate) d

margins, dydx(c.lrepub_all) over(_age_g) noestimcheck post
mmsave1000
eststo ht_int_rep

*****************************************************
* 		Hate crime X All Leaders X SSH X age		*
*****************************************************

qui logit _menthlth_d c.hc_crntyr##(c.leader_all c.leader_pre_all)##i.lgbt##i._age_g c.hc_prvsyr ///
	$covariates i.nstate i.year#i.month, vce(cluster nstate)
	
margins, dydx(c.leader_all) over(lgbt _age_g) post
mmsave100
eststo ht_ext_all_ssh
	
qui logit _menthlthexm_d c.hc_crntyr##(c.leader_all c.leader_pre_all)##i.lgbt##i._age_g c.hc_prvsyr ///
	$covariates i.nstate i.year#i.month, vce(cluster nstate)
	
margins, dydx(c.leader_all) over(lgbt _age_g) post
mmsave100
eststo ht_eext_all_ssh

qui ppmlhdfe _menthlth c.hc_crntyr##(c.leader_all c.leader_pre_all)##i.lgbt##i._age_g c.hc_prvsyr ///
	$covariates, absorb(i.nstate i.year#i.month) vce(cluster nstate) d

margins, dydx(c.leader_all) over(lgbt _age_g) noestimcheck post
mmsave1000
eststo ht_int_all_ssh

***************************************************
* 	Hate crime X Democrate Leaders X SSH X age ****
***************************************************

qui logit _menthlth_d c.hc_crntyr##(c.ldemoc_all c.leader_pre_all)##i.lgbt##i._age_g c.hc_prvsyr ///
	$covariates i.nstate i.year#i.month, vce(cluster nstate)

margins, dydx(c.ldemoc_all) over(lgbt _age_g) post
mmsave100
eststo ht_ext_dem_ssh
	
qui logit _menthlthexm_d c.hc_crntyr##(c.ldemoc_all c.leader_pre_all)##i.lgbt##i._age_g c.hc_prvsyr ///
	$covariates i.nstate i.year#i.month, vce(cluster nstate)
	
margins, dydx(c.ldemoc_all) over(lgbt _age_g) post
mmsave100
eststo ht_eext_dem_ssh

qui ppmlhdfe _menthlth c.hc_crntyr##(c.ldemoc_all c.leader_pre_all)##i.lgbt##i._age_g c.hc_prvsyr ///
	$covariates, absorb(i.nstate i.year#i.month) vce(cluster nstate) d

margins, dydx(c.ldemoc_all) over(lgbt _age_g) post noestimcheck
mmsave1000
eststo ht_int_dem_ssh

****************************************************
* 	Hate crime X Republican Leaders X SSH X age ****
****************************************************

qui logit _menthlth_d c.hc_crntyr##(c.lrepub_all c.leader_pre_all)##i.lgbt##i._age_g c.hc_prvsyr ///
	$covariates i.nstate i.year#i.month, vce(cluster nstate)
	
margins, dydx(c.lrepub_all) over(lgbt _age_g) post
mmsave100
eststo ht_ext_rep_ssh
	
qui logit _menthlthexm_d c.hc_crntyr##(c.lrepub_all c.leader_pre_all)##i.lgbt##i._age_g c.hc_prvsyr ///
	$covariates i.nstate i.year#i.month, vce(cluster nstate)
	
margins, dydx(c.lrepub_all) over(lgbt _age_g) post
mmsave100
eststo ht_eext_rep_ssh

qui ppmlhdfe _menthlth c.hc_crntyr##(c.lrepub_all c.leader_pre_all)##i.lgbt##i._age_g c.hc_prvsyr ///
	$covariates, absorb(i.nstate i.year#i.month) vce(cluster nstate) d

margins, dydx(c.lrepub_all) over(lgbt _age_g) post noestimcheck
mmsave1000
eststo ht_int_rep_ssh

esttab ht* using "../output/PubHealth/tab3/tab3_baselineXage.csv", replace ///
	se noomit nobase ///
	star(* 0.10 ** 0.05 *** 0.01) ///
	b(%9.4f) se(%9.4f) mtitles 
