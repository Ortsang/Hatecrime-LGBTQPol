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

// gen sshxmental = _menthlth*(lgbt==1)
// replace sshxmental = . if lgbt==0
// gen dshxmental = _menthlth*(lgbt==0)
// replace dshxmental = . if lgbt==1

collapse (mean) hc_crntyr _menthlth_d _menthlthexm_d _menthlth, by(year lgbt)
reshape wide hc_crntyr _menthlth _menthlth_d _menthlthexm_d, i(year) j(lgbt)

*gen yq = yq(year, _quarter)
*format yq %tq

preserve

/*
tsset lgbt yq

bysort lgbt: gen _menthlth_mv = (F1._menthlth + 2 * _menthlth + L1._menthlth) / 4
bysort lgbt: gen hc_crntqrt_mv = (F1.hc_crntqrt + 2 * hc_crntqrt + L1.hc_crntqrt) / 4
*bysort lgbt: gen hc_crntqrt_mv1 = (F1.hc_crntqrt + hc_crntqrt + L1.hc_crntqrt) / 3

cd "../output/figs"
twoway tsline _menthlth_mv if lgbt==1, lwidth(medthick) || ///
		tsline _menthlth_mv if lgbt==0, yaxis(1) ytitle("Days Mental Health Not Good") lwidth(medthick) || ///
		tsline hc_crntqrt_mv if lgbt==1, yaxis(2) ytitle("Number of Hate Crime Cases", axis(2)) lpattern("_-.") ///
		legend(pos(6) lab (1 "Same-sex Household") lab(2 "Different-sex Household") lab(3 "Hate Crime") rows(1)) xtitle(" ")
		
graph display, xsize(7) 

graph export "figure-ts-mentalhatecrime.png", width(1500) replace
*/

******************
* leader graph 	 *
******************

use "./policy/LGBT/leader/leader.dta", clear

egen lstate_all = rowtotal(dem_state_leg rep_state_leg dem_state_exe)
egen leader_all = rowtotal(dem_local_leg dem_state_exe dem_state_leg other_local_leg rep_local_leg rep_state_leg)
egen lrepub_all = rowtotal(rep_state_leg rep_local_leg)
egen ldemoc_all = rowtotal(dem_state_leg dem_state_exe dem_local_leg)
egen leader_pre_all = rowtotal(pre_all_local_exe pre_dem_local_leg pre_dem_state_exe pre_dem_state_leg pre_other_local_leg pre_rep_local_leg pre_rep_state_leg)

collapse (sum) leader_all lrepub_all ldemoc_all, by(year)

tempfile leader
save `leader'

restore

merge m:1 year using `leader'
keep if _merge == 3
drop _merge

export excel using "hcmentalxleader", firstrow(variables) replace

/*
twoway bar leader_all year, bcolor(sienna%40) || ///
	bar ldemoc_all year, bcolor(ebblue%70) || ///
	bar lrepub_all year, bcolor(red%70) sort ///
	legend(pos(6) lab (1 "All Leaders") lab(2 "Dem. Leaders") lab(3 "GOP Leaders") rows(1)) xtitle(" ")
	
graph display, xsize(7) 

graph export "figure-bar-leaders.png", width(1500) replace

		