import excel "/Users/ortsang/Library/CloudStorage/GoogleDrive-kei.czeng@gmail.com/我的云端硬盘/Res/BRFSS/data/Hate Crime Raw Data/2020-2023/Hatecrime2020.xlsx", sheet("Table 13") firstrow case(lower) clear
destring raceethnicityancestry religion sexualorientation disability gender genderidentity stquarter ndquarter rdquarter thquarter population1, replace

rename statefederal state

gen year = 2020

tempfile year
save `year', replace


import excel "/Users/ortsang/Library/CloudStorage/GoogleDrive-kei.czeng@gmail.com/我的云端硬盘/Res/BRFSS/data/Hate Crime Raw Data/2020-2023/Hatecrime2021.xlsx", sheet("Table 13") firstrow case(lower) clear
destring raceethnicityancestry religion sexualorientation disability gender genderidentity stquarter ndquarter rdquarter thquarter population1, replace

gen year = 2021

append using `year'
save `year', replace


import excel "/Users/ortsang/Library/CloudStorage/GoogleDrive-kei.czeng@gmail.com/我的云端硬盘/Res/BRFSS/data/Hate Crime Raw Data/2020-2023/Hatecrime2022.xlsx", sheet("Table 13") firstrow case(lower) clear
rename n population1
destring raceethnicityancestry religion sexualorientation disability gender genderidentity stquarter ndquarter rdquarter thquarter population1, replace

gen year = 2022

append using `year'
save `year', replace

import excel "/Users/ortsang/Library/CloudStorage/GoogleDrive-kei.czeng@gmail.com/我的云端硬盘/Res/BRFSS/data/Hate Crime Raw Data/2020-2023/Hatecrime2023.xlsx", sheet("Table 13") firstrow case(lower) clear
rename n population1
destring raceethnicityancestry religion sexualorientation disability gender genderidentity stquarter ndquarter rdquarter thquarter population1, replace

gen year = 2023

append using `year'

local state = state[1]

forvalues row = 1/`=_N' {
	
	local rowstate = state[`row']
	di "`state' - `rowstate'"
	
	if "`rowstate'" == "" {
		replace state = "`state'" in `row'	
	}

	else {
		
		local state = "`rowstate'"
		
	}	
}

drop if agencytype != ""


collapse (sum) raceethnicityancestry religion sexualorientation disability gender genderidentity stquarter ndquarter rdquarter thquarter, by(state year)

drop if strlen(state)>20

replace raceethnicityancestry = 82 	if state == "Florida" & year == 2021
replace religion = 20 				if state == "Florida" & year == 2021
replace sexualorientation = 42 		if state == "Florida" & year == 2021
replace disability = 1 		if state == "Florida" & year == 2021

egen typetotal = rowtotal(raceethnicityancestry religion sexualorientation disability gender genderidentity)
egen yeartotal = rowtotal(stquarter ndquarter rdquarter thquarter)


replace typetotal = 148 		if state == "Florida" & year == 2021
replace typetotal = 148 		if state == "Florida" & year == 2021

save "/Users/ortsang/Library/CloudStorage/GoogleDrive-kei.czeng@gmail.com/我的云端硬盘/Res/BRFSS/data/HCD/HC20to22.dta", replace

* need to supplement FL data with https://www.myfloridalegal.com/files/pdf/page/BE0185D36969417B852589270066D783/Web+Link.pdf






