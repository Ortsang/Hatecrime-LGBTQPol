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

keep if _numadult == 2

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
replace _physhlth = 0 if _physhlth == .

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
	_employ == . | _educa == . | _hlthplan == . | hc_crntyr == . | hc_prvsyr == . | ///
	_menthlth == .
	
global covariates i._age_g i._sex i._genhlth i._racec ///
	i._hlthplan i._income2 i._employ i._educa ///
	agencies pop highschool malefemaleratio unemployment ///
	enroll i.acaexpan c.gui_all c.evt_all 

*************************************************
* 		Hate crime -> physical health 		
*************************************************

qui logit _physhlth_d c.hc_crntyr c.hc_prvsyr ///
	$covariates	i.nstate i.year#i.month, vce(cluster nstate)
	
margins, dydx(c.hc_crntyr) post
mmsave100
eststo ph_ext
	
qui logit _physhlthexm_d c.hc_crntyr c.hc_prvsyr ///
	$covariates	i.nstate i.year#i.month, vce(cluster nstate)
	
margins, dydx(c.hc_crntyr) post
mmsave100
eststo ph_eext

qui ppmlhdfe _physhlth c.hc_crntyr c.hc_prvsyr ///
	$covariates, absorb(i.nstate i.year#i.month) vce(cluster nstate) d

margins, dydx(c.hc_crntyr) noestimcheck post
mmsave1000
eststo ph_int

/*******************************************************
* 		Hate crime -> poor health (physicialXmental)
*******************************************************

qui logit  _poorhlth_d  c.hc_crntyr c.hc_prvsyr ///
	$covariates	i.nstate i.year#i.month, vce(cluster nstate)
	
margins, dydx(c.hc_crntyr) post
mmsave100
eststo poh_ext
	
qui logit _poorhlthexm_d c.hc_crntyr c.hc_prvsyr ///
	$covariates	i.nstate i.year#i.month, vce(cluster nstate)
	
margins, dydx(c.hc_crntyr) post
mmsave100
eststo poh_eext

qui ppmlhdfe _poorhlth c.hc_crntyr c.hc_prvsyr ///
	$covariates, absorb(i.nstate i.year#i.month) vce(cluster nstate) d

margins, dydx(c.hc_crntyr) noestimcheck post
mmsave1000
eststo por_int
*/

esttab * using "../output/PubHealth/tab4/tab4_physical.csv", replace ///
	se noomit nobase ///
	star(* 0.10 ** 0.05 *** 0.01) ///
	b(%9.4f) se(%9.4f) mtitles 
	
est clear

* drinking
*drop if inlist(_alcday5,777,999)

gen 	drinking = 0*(_alcday5==888)
replace drinking = (_alcday5-100)*4 if inrange(_alcday5,101,107)
replace drinking = (_alcday5-200)	if inrange(_alcday5,201,230)

foreach v of varlist drinking {
	
	gen `v'_d 		= `v'>0
	
	cap drop quartile
	egen quartile = xtile(`v'), by(year) n(4)
	gen `v'exm_d 	= quartile==4
	
}

qui logit  drinking_d  c.hc_crntyr c.hc_prvsyr ///
	$covariates	i.nstate i.year#i.month, vce(cluster nstate)
	
margins, dydx(c.hc_crntyr) post
mmsave100
eststo drk_ext
	
qui logit drinkingexm_d c.hc_crntyr c.hc_prvsyr ///
	$covariates	i.nstate i.year#i.month, vce(cluster nstate)
	
margins, dydx(c.hc_crntyr) post
mmsave100
eststo drk_eext

qui ppmlhdfe drinking c.hc_crntyr c.hc_prvsyr ///
	$covariates, absorb(i.nstate i.year#i.month) vce(cluster nstate) d

margins, dydx(c.hc_crntyr) noestimcheck post
mmsave1000
eststo drk_int

/** smoke100
gen 	smoke100 = (_smoke100==1)
replace smoke100 = . if inlist(_smoke100,7,9)

qui logit  smoke100  c.hc_crntyr c.hc_prvsyr ///
	$covariates	i.nstate i.year#i.month, vce(cluster nstate)
	
margins, dydx(c.hc_crntyr) post
mmsave100
eststo smk100
*/

* smoke
gen 	smoke = inlist(_smokday2,1,2)

qui logit smoke c.hc_crntyr c.hc_prvsyr ///
	$covariates	i.nstate i.year#i.month, vce(cluster nstate)
	
margins, dydx(c.hc_crntyr) post
mmsave100
eststo smk

esttab * using "../output/PubHealth/tab4/tab4_drinkingnsmoking.csv", replace ///
	se noomit nobase ///
	star(* 0.10 ** 0.05 *** 0.01) ///
	b(%9.4f) se(%9.4f) mtitles 

