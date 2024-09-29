* Adding table1 - hate crime to mental health
* adding table2 - hate crime to LGBTQ leaders

est clear

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
drop if _m == 2
drop _m

merge m:1 state year using "./policy/LGBT/gaycommunity/Damron events panel 2012-2019.dta"
keep if _m == 3
drop _m

egen evt_all = rowtotal(Breast_Cancer_Benefits-unclassified)

merge m:1 state using "./policy/LGBT/gaycommunity/Gay guide 2019.dta"
keep if _m == 3
drop _m

egen gui_all = rowtotal(Accommodations-Websites)

egen lstate_all = rowtotal(dem_state_leg rep_state_leg dem_state_exe)
egen leader_all = rowtotal(dem_local_leg dem_state_exe dem_state_leg other_local_leg rep_local_leg rep_state_leg)
egen lrepub_all = rowtotal(rep_state_leg rep_local_leg)
egen ldemoc_all = rowtotal(dem_state_leg dem_state_exe dem_local_leg)
egen leader_pre_all = rowtotal(pre_all_local_exe pre_dem_local_leg pre_dem_state_exe pre_dem_state_leg pre_other_local_leg pre_rep_local_leg pre_rep_state_leg)

merge m:1 state year using "./HCD/hcspecific.dta"
drop if _m == 2
drop _m

rename (Raceethnicity-Genderidentity) (hc_=)

rename (numadult-hivtst6 racec drnkany5 droccdy_) _= //change name ind charatertics 
recode _menthlth _physhlth _poorhlth _income2 (77 99 = .) (88 = 0)
drop if _sex > 2

replace _numadult = 10 if _numadult >= 15

label define _ghlthl 1 "Excellent" 2 "Very good" 3 "Good" 4 "Fair" 5 "Poor"
label values _genhlth _ghlthl	

recode _hlthplan (2 7 9 = 0)

recode _racec (5 6 7 8 9 = 5)
label define _racel 1 "White" 2 "Black" 3 "Hispanic" 4 "Asian" 5 "Others"
label values _racec _racel	

foreach v of varlist _menthlth _physhlth _poorhlth {
	gen `v'_d 		= `v'>0
	qui su `v', d
	gen `v'exm_d 	= `v'>r(p75)
}

gen lgbt = (_numadult == 2 & (_nummen == 2 | _numwomen == 2))
gen cisf = (_numadult == 2 & (_nummen == 1 & _numwomen == 1))
gen familycat = (lgbt==1)
replace familycat = 2 if cisf==1

encode state, g(nstate)

gen _quarter = 1 		if month<4
replace _quarter = 2 	if month<7 	& _quarter==.
replace _quarter = 3 	if month<10 & _quarter==.
replace _quarter = 4	if _quarter==.

tempfile hc
preserve
keep statefip year quarter* hc_*
replace year = year + 1
rename (quarter*) (quarter*_pyear)
rename (hc_*) (hc_*_pyear)
duplicates drop statefip year, force
save `hc', replace
restore

merge m:1 statefip year using `hc'
drop if _merge == 2
drop _merge

gen hc_prvsqrt 	= (_quarter==1)*quarter4_pyear + ///
					(_quarter==2)*quarter1 + ///
					(_quarter==3)*quarter2 + ///
					(_quarter==4)*quarter3
					
gen hc_crntqrt 	= (_quarter==1)*quarter1 + ///
					(_quarter==2)*quarter2 + ///
					(_quarter==3)*quarter3 + ///
					(_quarter==4)*quarter4	
					
egen hc_year = rowtotal(hc_Raceethnicity-hc_Genderidentity)
egen hc_pyear = rowtotal(hc_Raceethnicity_pyear-hc_Genderidentity_pyear)
					
bysort statefip: egen hc_median = median(hc_crntqrt)
*egen quartile = xtile(hc_crntqrt), by(statefip) n(4)

gen hcexm_crntqrt 	= hc_crntqrt > hc_median

bysort statefip year: egen hc_qrt_median = median(hc_crntqrt)
forvalues x = 1/4{
	gen exm_quarter`x' = quarter`x' > hc_qrt_median
}

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
keep if _age_g >= 2 // keeping only age above 16
keep if _numadult == 2

keep if (lgbt==1 | cisf==1)
drop if _income2 == . | _racec == . | agencies == . | _genhlth == . | ///
	_employ == . | _educa == . | _hlthplan == . | hc_crntyr == . | hc_prvsyr == .


keep hc_crntyr _age_g _sex _genhlth _racec _income2 _employ _educa ///
	agencies pop highschool malefemaleratio unemployment ///
	enroll acaexpan _menthlth_d _menthlthexm_d _menthlth lgbt
	

cd "../output/PubHealth"

dtable hc_crntyr i._age_g i._sex i._genhlth i._racec i._income2 i._employ i._educa ///
	agencies pop highschool malefemaleratio unemployment ///
	enroll i.acaexpan i._menthlth_d i._menthlthexm_d c._menthlth , by(lgbt) /*sample(, statistic(frequency))*/ ///
	export(table1.xlsx, replace)

