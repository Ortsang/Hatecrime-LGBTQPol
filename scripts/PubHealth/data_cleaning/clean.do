cap cd "/Users/ortsang/Library/CloudStorage/GoogleDrive-kei.czeng@gmail.com/我的云端硬盘/Res/BRFSS/data"
cap cd "D:\Drives\Google Drive\Res\BRFSS\data" 

use "./HCD/qtl-st-hatecrime.dta", clear

egen hc_crntyr	= rowtotal(quarter1 quarter2 quarter3 quarter4)
bysort state: gen hc_prvsyr = hc_crntyr[_n-1]
keep state year hc_crntyr hc_prvsyr
tempfile hc
save `hc'

cd "./BRFSS"

local folder: dir "./" files "*.XPT*", respectcase

tempfile core
save `core', emptyok //emptyok means if there no observation still save

foreach file in `folder' {
	di "this is file `file'"
	import sasxport5 "`file'", clear
	cap ren (ladult1) (ladult)
	cap ren sexvar sex
	cap ren hivtst7 hivtst6
	cap ren hivtst4 hivtst6
	cap ren hivtst5 hivtst6
	cap ren pvtresd1 pvtresid
	cap ren hlthpln1 hlthplan
	cap ren employ1 employ
	cap ren drnkany3 drnkany5
	cap ren drnkany4 drnkany5
	cap ren race2 racec
	cap ren _race racec
	cap ren hispanc2 _hispanc
	cap ren drnkany4 drnkany5
	cap ren drocdy2_ droccdy_
	cap ren drocdy3_ droccdy_
	cap ren flushot* flushot3
	
	keep _state idate pvtresid sex numadult ///
		nummen numwomen hivtst6 genhlth ///
			physhlth menthlth poorhlth hlthplan educa employ income2 ///
			racec _hispanc _age_g _educag _incomg ///
			smoke100 drnkany5 flushot3 droccdy_ ///
			marital persdoc2 medcost 
			
			
	append using `core'
	save `core', replace
}

keep _state idate pvtresid sex numadult ///
		nummen numwomen hivtst6 genhlth ///
			physhlth menthlth poorhlth hlthplan educa employ income2 ///
			racec _hispanc _age_g _educag _incomg ///
			smoke100 drnkany5 flushot3 droccdy_ ///
			marital persdoc2 medcost 
			
rename _* *
rename (idate-droccdy_) _=

compress

cd "../"

ren _state statefip
merge m:1 statefip using statefip
drop if _m != 3
drop _m

replace state = strproper(state)

gen year = usubstr(idate,5,8)
destring year, replace
gen month = usubstr(idate,1,2)
destring month, replace
gen day = usubstr(idate,3,2)
destring day, replace

replace state = upper(state)

merge m:1 state year using `hc'
drop if _merge != 3
drop _merge

merge m:1 state year using "./HCD/state level agencies.dta"
drop if _m != 3
drop _m

merge m:1 state year using "./HCD/state level offenses"
drop if _m != 3
drop _m

merge m:1 state year using "./HCD/HSplus"
drop if _m != 3
drop _m

merge m:1 state year using "./HCD/Lawenforcement"
drop if _m != 3
drop _m

merge m:1 state year using "./HCD/sexratio"
drop if _m != 3
drop _m

merge m:1 state year using "./HCD/unemployment"
drop if _m != 3
drop _m

merge m:1 state year using "./HCD/hcspecific"
drop if _m == 2
drop _m

merge m:1 state year month using "./ACA/ACA"
drop if _m == 2
drop _m

replace 	enroll 		= 0 if enroll == .
gen 		acaexpan 	= 1 if year >= acayear & month >= acamonth & day >= acaday
replace 	acaexpan 	= 0 if acaexpan == .

compress

save BRFSS1119_test, replace
