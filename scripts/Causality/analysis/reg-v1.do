est clear

cap cd "D:\Drives\Google Drive\Res\BRFSS\data"
cap cd "/Users/ortsang/Library/CloudStorage/GoogleDrive-kei.czeng@gmail.com/我的云端硬盘/Res/BRFSS/data"

* loading state tempfile
tempfile abb

import delimited "vote2016.csv", varnames(1) clear 
replace state = upper(state)
save `abb', replace

*use BRFSS1019, clear
use BRFSS0919, clear
rename (idate-hivtst6 mscode droccdy_) _=
merge m:1 state using `abb', nogen

merge m:1 state year using ./policy/LGBT/leader/leader0623
drop if _merge == 2
drop _merge

egen leader_all = rowtotal(dem_state_leg rep_state_leg dem_state_exe dem_local_exe rep_local_exe dem_local_leg other_local_leg rep_local_leg)
egen lrepub_all = rowtotal(rep_local_exe rep_state_leg rep_local_leg)
egen ldemoc_all = rowtotal(dem_state_leg dem_state_exe dem_local_exe dem_local_leg)
egen leader_pre_all = rowtotal(pre_dem_state_leg pre_rep_state_leg pre_dem_state_exe pre_dem_local_exe pre_rep_local_exe pre_dem_local_leg pre_other_local_leg pre_rep_local_leg)

merge m:1 state year using "./HCD/hcspecific.dta"
drop if _merge == 2
drop _merge

rename (Raceethnicity-Genderidentity) (hc_=)

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

drop if year_earliest<2012 | leader_pre_all>0
gen post = (year >= year_earliest)
* replace post = 0 if leader_all == 0
drop if year_earliest == 2019

* 2016 supporters rate
gen election2016 = year>=2016
gen election2016Xtrump = election2016*trumprate

/*********************************************
* 		Hate crime X Democrate Leaders
*********************************************
encode state, generate(estate)
gen modate=ym(year,month)
gen qdate = qofd(dofm(ym(year, month)))

hdidregress aipw (_menthlth_d c.hc_crntyr c.hc_prvsyr ///
	i._age_g i._sex i._genhlth i._income2 i._employ i._educa ///
	i.acaexpan c.pop c.agencies c.highschool c.malefemaleratio c.unemployment ///
	i.election2016##c.trumprate /// 
	c.enroll i.estate) ///
	(post leader_all), group(estate) time(year)
	
hdidregress aipw (_menthlthexm_d c.hc_crntyr c.hc_prvsyr ///
	i._age_g i._sex i._genhlth i._income2 i._employ i._educa ///
	i.acaexpan c.pop c.agencies c.highschool c.malefemaleratio c.unemployment ///
	c.enroll ) ///
	(post leader_all), group(estate) time(year)
	
hdidregress aipw (_menthlth c.hc_crntyr c.hc_prvsyr ///
	i._age_g i._sex i._genhlth i._income2 i._employ i._educa ///
	i.acaexpan c.pop c.agencies c.highschool c.malefemaleratio c.unemployment ///
	c.enroll ) ///
	(post leader_all), group(estate) time(year)
	
hdidregress aipw (c.hc_crntyr c.hc_prvsyr ///
	i._age_g i._sex i._genhlth i._income2 i._employ i._educa ///
	i.acaexpan c.pop c.agencies c.highschool c.malefemaleratio c.unemployment ///
	c.enroll ) ///
	(post leader_all), group(estate) time(year)


qui logit _menthlth_d (c.hc_crntyr c.hc_prvsyr ///
	i._age_g i._sex i._genhlth i._racec i._income2 i._employ i._educa ///
	c.agencies c.pop c.highschool c.malefemaleratio c.unemployment ///
	c.enroll i.acaexpan)##i.post ///
	i.nstate i.year i.month ///
	, vce(cluster nstate)

eststo ht_ext_dem: margins, dydx(i.post) post noestimcheck
	
qui logit _menthlthexm_d (c.hc_crntyr c.hc_prvsyr ///
	i._age_g i._sex i._genhlth i._racec i._income2 i._employ i._educa ///
	c.agencies c.pop c.highschool c.malefemaleratio c.unemployment ///
	c.enroll i.acaexpan)##i.post ///
	i.nstate i.year i.month ///
	, vce(cluster nstate)
	
eststo ht_ext_dem: margins, dydx(i.post) post noestimcheck

qui ppmlhdfe _menthlth (c.hc_crntyr c.hc_prvsyr ///
	i._age_g i._sex i._genhlth i._racec i._income2 i._employ i._educa ///
	c.agencies c.pop c.highschool c.malefemaleratio c.unemployment ///
	c.enroll i.acaexpan)##i.post ///
	, absorb(nstate i.year i.month) vce(cluster nstate) d

eststo ht_ext_dem: margins, dydx(i.post) post noestimcheck





qui logit _menthlth_d c.hc_crntyr##(c.ldemoc_all c.leader_pre_all) c.hc_prvsyr ///
	i._age_g i._sex i._genhlth i._racec i._income2 i._employ i._educa ///
	agencies pop  malefemaleratio unemployment ///
	enroll i.acaexpan ///
	i.nstate i.year i.month ///
	, vce(cluster nstate)

eststo ht_ext_dem: margins, dydx(c.ldemoc_all) post
	
qui logit _menthlthexm_d c.hc_crntyr##(c.ldemoc_all c.leader_pre_all) c.hc_prvsyr ///
	i._age_g i._sex i._genhlth i._racec i._income2 i._employ i._educa ///
	agencies pop highschool malefemaleratio unemployment ///
	enroll i.acaexpan ///
	i.nstate i.year i.month ///
	, vce(cluster nstate)
	
eststo ht_eext_dem: margins, dydx(c.ldemoc_all) post

qui ppmlhdfe _menthlth c.hc_crntyr##(c.ldemoc_all c.leader_pre_all) c.hc_prvsyr ///
	i._age_g i._sex i._genhlth i._racec i._income2 i._employ i._educa ///
	agencies pop highschool malefemaleratio unemployment ///
	enroll i.acaexpan ///
	, absorb(nstate i.year i.month) vce(cluster nstate) d

eststo ht_int_dem: margins, dydx(c.ldemoc_all) noestimcheck post

