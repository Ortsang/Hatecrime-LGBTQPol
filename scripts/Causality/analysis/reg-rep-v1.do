est clear

cap cd "D:\Drives\Google Drive\Res\BRFSS\data"
cap cd "/Users/ortsang/Library/CloudStorage/GoogleDrive-kei.czeng@gmail.com/我的云端硬盘/Res/BRFSS/data"

* loading state tempfile
* state abbreviation
tempfile abb
import delimited "vote2016.csv", varnames(1) clear 
replace state = upper(state)
save `abb', replace

* loading main file
use BRFSS0919, clear
merge m:1 state using `abb', nogen

* recoding
recode _menthlth _physhlth _poorhlth (77 99 = .) (88 = 0)
recode _income2 (77 99 . = 99)
recode _medcost (7 9 . = 2)
recode _marital (. = 9)
recode _prace 	(6 7 8 77 99 . = 99)
recode _genhlth (7 9 . = 9)
recode _hlthplan (2 7 9 . = 0)

gen college = (_educa==5|_educa==6)
gen work = (_employ==1|_employ==2)

replace _numadult = 10 if _numadult >= 10

drop if _sex > 2

label define _ghlthl 1 "Excellent" 2 "Very good" 3 "Good" 4 "Fair" 5 "Poor"
label values _genhlth _ghlthl	

foreach v of varlist _menthlth _physhlth _poorhlth {
	gen `v'_d 		= `v'>0
	qui su `v', d
	gen `v'exm_d 	= `v'>r(p75)
}

gen lgbt = (_numadult == 2 & (_nummen == 2 | _numwomen == 2))
gen cisf = (_numadult == 2 & (_nummen == 1 & _numwomen == 1))
gen familycat = (lgbt==1)
replace familycat = 2 if cisf==1

keep if _numadult == 2

keep if _age_g >= 2 // keeping only age above 16

merge m:1 state year using ./policy/LGBT/leader/leader0023
drop if _merge == 2
drop _merge

egen leader_all = rowtotal(dem_state_leg rep_state_leg dem_state_exe dem_local_exe rep_local_exe dem_local_leg other_local_leg rep_local_leg)
egen lrepub_all = rowtotal(rep_local_exe rep_state_leg rep_local_leg)
egen ldemoc_all = rowtotal(dem_state_leg dem_state_exe dem_local_exe dem_local_leg)
egen leader_pre_all = rowtotal(pre_dem_state_leg pre_rep_state_leg pre_dem_state_exe pre_dem_local_exe pre_rep_local_exe pre_dem_local_leg pre_other_local_leg pre_rep_local_leg)

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

* 2016 supporters rate
gen election2016 = year>=2016
gen election2016Xtrump = election2016*trumprate

*********************************************
* 		Republican DID
*********************************************

encode state, generate(estate)
gen modate=ym(year,month)
gen qdate = qofd(dofm(ym(year, month)))

gen rep_leader = 0
replace rep_leader = 1 if stateab == "OH" & year>=2013 // & year <=2016 // Tim Brown, Ohio House of Representatives
replace rep_leader = 1 if stateab == "NH" & year>=2016 // & year <=2018 // Daniel Innis, New Hampshire Senate
replace rep_leader = 1 if stateab == "MD" & year>=2018 // & year <=2018 // Meagan Simonaire, came out 2018

gen treat = inlist(stateab,"OH","NH","MD")
keep if treat==1 | year_earliest>2019
*drop if stateab == "CA"

hdidregress aipw (_menthlth_d c.hc_crntyr c.hc_prvsyr ///
	i._age_g i._sex i._genhlth i._income2 i._medcost ///
	i._hlthplan i._hispanc i._marital i._prace  ///
	i.work i.college ///
	i.acaexpan c.pop c.agencies c.highschool c.malefemaleratio c.unemployment ///
	i.election2016##c.trumprate /// 
	c.enroll i.estate#c.year i.LSSM c.leader_pre_all c.leader_all) ///
	(rep_leader), group(estate) time(year)
	
bysort lgbt: hdidregress aipw (_menthlthexm_d c.hc_crntyr c.hc_prvsyr ///
	i._age_g i._sex i._genhlth i._income2 i._medcost ///
	i._hlthplan i._hispanc i._marital i._prace  ///
	i.work i.college ///
	i.acaexpan c.pop c.agencies c.highschool c.malefemaleratio c.unemployment ///
	i.election2016##c.trumprate /// 
	c.enroll i.estate#c.year i.LSSM c.leader_pre_all c.leader_all) ///
	(rep_leader), group(estate) time(year)
	
bysort lgbt: hdidregress aipw (_menthlth c.hc_crntyr c.hc_prvsyr ///
	i._age_g i._sex i._genhlth i._income2 i._medcost ///
	i._hlthplan i._hispanc i._marital i._prace  ///
	i.work i.college ///
	i.acaexpan c.pop c.agencies c.highschool c.malefemaleratio c.unemployment ///
	i.election2016##c.trumprate /// 
	c.enroll i.estate#c.year i.LSSM c.leader_pre_all c.leader_all) ///
	(rep_leader), group(estate) time(year)
