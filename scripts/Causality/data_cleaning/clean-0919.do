clear
cap cd "/Users/ortsang/Library/CloudStorage/GoogleDrive-kei.czeng@gmail.com/我的云端硬盘/Res/BRFSS/data/BRFSS"
cap cd "D:\Drives\Google Drive\Res\BRFSS\data\BRFSS" 

use "../HCD/qtl-st-hatecrime.dta", clear

egen hc_crntyr	= rowtotal(quarter1 quarter2 quarter3 quarter4)
bysort state: gen hc_prvsyr = hc_crntyr[_n-1]
keep state year hc_crntyr hc_prvsyr
tempfile hc
save `hc'

local folder: dir "./" files "*.dta*", respectcase

tempfile core
save `core', emptyok //emptyok means if there no observation still save

foreach file in `folder' {
	di "this is file `file'"
	use "`file'", clear
	*rename _* *
	rename _* *, lower
	cap rename orace racec
	cap rename veteran* veteran3
	cap rename alcday* alcday5
	cap rename _finalwt _llcpwt

	cap ren ladult1 ladult
	cap ren sex1 	sex
	cap ren sexvar 	sex
	cap ren hivtst7 hivtst6
	cap ren hivtst4 hivtst6
	cap ren hivtst5 hivtst6
	cap ren pvtresd1 pvtresid
	cap ren hlthpln1 hlthplan
	cap ren employ1 employ
	cap ren drnkany3 drnkany5
	cap ren drnkany4 drnkany5
	cap ren _prace* _prace
	cap ren hispanc2 _hispanc
	cap ren drocdy2_ droccdy_
	cap ren drocdy3_ droccdy_
	cap ren flushot* flushot3
	cap ren avedrnk* avedrnk2
	*cap ren scntmel* scntmel
	*cap	ren scntmeal scntmel
				
	keep _state idate iday imonth iyear pvtresid sex numadult ///
			nummen numwomen hivtst6 genhlth ///
			physhlth menthlth poorhlth hlthplan educa employ income2 ///
			_prace _hispanc _age_g _educag _incomg ///
			smoke100 drnkany5 flushot3 droccdy_ ///
			marital persdoc2 medcost ///
			veteran3 children drnk3ge5 alcday5 avedrnk2 smokday2 ///
			mscode _llcpwt 
				
	append using `core'
	save `core', replace
}

keep _state idate iday imonth iyear pvtresid sex numadult ///
		nummen numwomen hivtst6 genhlth ///
		physhlth menthlth poorhlth hlthplan educa employ income2 ///
		_prace _hispanc _age_g _educag _incomg ///
		smoke100 drnkany5 flushot3 droccdy_ ///
		marital persdoc2 medcost ///
		veteran3 children drnk3ge5 alcday5 avedrnk2 smokday2 ///
		mscode _llcpwt 
		
rename _* *
rename *_ *
rename * _=
			
compress

cd "../"
ren _state statefip
merge m:1 statefip using statefip
drop if _merge != 3
drop _merge

replace state = strproper(state)
gen year = usubstr(_idate,5,8)
destring year, replace
gen month = usubstr(_idate,1,2)
destring month, replace
gen day = usubstr(_idate,3,2)
destring day, replace

replace state = upper(state)

merge m:1 state year using `hc'
drop if _merge != 3
drop _merge

merge m:1 state year using "./HCD/state level agencies.dta"
drop if _merge != 3
drop _merge

merge m:1 state year using "./HCD/state level offenses"
drop if _merge != 3
drop _merge

merge m:1 state year using "./HCD/HSplus"
drop if _merge != 3
drop _merge

merge m:1 state year using "./HCD/Lawenforcement"
drop if _merge != 3
drop _merge

merge m:1 state year using "./HCD/sexratio"
drop if _merge != 3
drop _merge

merge m:1 state year using "./HCD/unemployment"
drop if _merge != 3
drop _merge

merge m:1 state year month using "./ACA/ACA"
drop if _merge == 2
drop _merge

replace 	enroll 		= 0 if enroll == .
gen 		acaexpan 	= 1 if year >= acayear & month >= acamonth & day >= acaday
replace 	acaexpan 	= 0 if acaexpan == .

compress

save BRFSS0919, replace
