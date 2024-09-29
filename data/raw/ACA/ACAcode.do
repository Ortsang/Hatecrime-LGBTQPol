clear

cap cd "/Users/ortsang/Library/CloudStorage/GoogleDrive-kei.czeng@gmail.com/我的云端硬盘/Res/BRFSS/data/ACA"
cap cd "D:\Drives\Google Drive\Res\BRFSS\data\ACA" 

tempfile acaexp
save `acaexp', emptyok //emptyok means if there no observation still save

import delimited "./Other/ACAexpansion.csv", delimiter(comma) bindquote(strict) varnames(1) clear 
replace state 	= 	upper(state)
gen 	expansion 		= 	(expansionstatus == "Adopted and Implemented")
split description , p(" on ")
replace description2 = "" if strlen(description2) > 10
replace description2 = "11/1/2018" if state == "VIRGINIA"
replace description2 = "1/10/2019" if state == "MAINE"
replace description2 = "10/01/2021"	if state == "MISSOURI" // Missouri adopted and implemented ACA 10/01/2021
replace description2 = "1/1/2020"	if state == "IDAHO" // Enrollment in Medicaid coverage under expansion began on November 1, 2019, and coverage for these enrollees began on January 1, 2020.
split description2 , p("/")
destring description21 description22 description23, g(acamonth acaday acayear) ignore(" ")

*replace expansion		= 	0 	if acayear > 2019
drop des* expansionstatus
save `acaexp', replace

local folder: dir "./" files "*.csv*", respectcase

tempfile core
save `core', emptyok //emptyok means if there no observation still save

foreach file in `folder' {
	di "this is file `file'"
	import delimited "`file'", clear
	cap rename enrollmentyear enrollment_year
	cap rename enrollmentmonth enrollment_month
	cap rename total_medicaidenrollees total_medicaid_enrollees
	cap rename totalmedicaidenrollees total_medicaid_enrollees
	
	
	keep state enrollment_year enrollment_month total_medicaid_enrollees
	rename (enrollment_year enrollment_month total_medicaid_enrollees) ///
		(year month enroll)
	
	destring enroll, replace force i(",")
	append using `core'
	save `core', replace
}

keep state month year enroll

replace state = upper(state)
replace state = "DISTRICT OF COLUMBIA" 	if state == "DIST. OF COL."
replace state = "NORTH DAKOTA" 			if state == "NORTH DAKOTA *"

collapse (sum) enroll, by(state month year)
sort state year month

drop if year == .
replace state = substr(state, 1, length(state) - 1) if substr(state, -1, 1) ==  " "
replace state = substr(state, 1, length(state) - 2) if substr(state, -1, 1) ==  "*" // for state such as "IDAHO *"
replace state = "DISTRICT OF COLUMBIA"  if state == "DIST. OF COL."

merge m:1 state using `acaexp'



drop 	if _m == 1 & year < 2019. 
drop _m
save ACA, replace

/* data not support 2015 before - obsolete
import delimited "./Other/Medicaid.csv", delimiter(comma) bindquote(strict) varnames(1) clear 
gen 	state 	=	upper(state_name)
drop 	if 	final_report != "Y"
keep 	state report_date new_applications_submitted_to_me ///
	total_medicaid_and_chip_enrollme total_medicaid_enrollment total_chip_enrollment 
rename (report_date new_applications_submitted_to_me total_medicaid_and_chip_enrollme total_medicaid_enrollment total_chip_enrollment) ///
	(date newappl medicaidnchip medicaid chip)
split 	date , p("/")
destring date1 date2 date3, g(month day year) ignore(" ")
keep 	newappl medicaidnchip medicaid chip state month day year
order 	state year month day
sort 	state year month day
drop 	if year > 2019
