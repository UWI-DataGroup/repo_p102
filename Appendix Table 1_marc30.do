** Author: Miriam Alvarado
** Date: October 26, 2016
** Purpose: Calculate % deaths from CVD in caribbean SIDS out of all SIDS 
** edited: March 30 to just generate Appendix Table 1 


	clear all 
	set mem 2g
	set more off 
	set scheme s1color

	
******************************************
** DATA PREP 
******************************************

		
** bring in SIDS list 
	insheet using "Data\sids.csv", comma clear names
	gen country_name =substr(unesco, 4,.)
	replace country_name =ltrim(country_name)
	replace country_name = subinstr(country_name, "*", "", .) 
	replace country_name = subinstr(country_name, "St.", "Saint", .) 
	replace country_name = "The Bahamas" if country_name == "Bahamas"
	replace country_name = "Virgin Islands, U.S." if country_name == "United States Virgin Islands"


	drop in 40/48
	tempfile sids
	save `sids', replace
	
	
** bring in country codes
	insheet using "Data\codes.csv", comma clear 	
	replace country_name = "The Bahamas" if country_name == "Bahamas"
	replace country_name = "Virgin Islands, U.S." if country_name == "United States Virgin Islands"

	tempfile caribcodes
	save `caribcodes', replace

** bring in GBD  data 
	**insheet using "`folder'\Data\ihme_cvd_diabetes_deaths_sids.csv", comma clear names 
	** insheet using "`folder'\Data\IHME-GBD_2015_DATA-817daec0-1.csv", comma clear names 
	insheet using "Data\IHME-GBD_2015_DATA-1e3e3f45-1.csv", comma clear names 
	** this one has all years 
	rename location country_name
	gen cause_name=cause
	replace cause_name ="CVDdiabetes" if cause_name =="Cardiovascular diseases" | cause_name =="Diabetes mellitus"
	replace cause_name ="Allcause" if cause =="All causes"
	tempfile gbddata 
	save `gbddata', replace 
		
** keep Caribbean countries only 
	use `sids', clear
	merge m:1 country_name using `caribcodes'
	*keep if _m==3
	drop _m 

** merge on death data 
	merge 1:m country_name using `gbddata' 
	** _m ==1 are non-GBD countries - too small or non-sovereign 
	**_m ==2 are not locations of interest, not SIDS
	drop if _m!=3
	drop _m 
	
** gen Caribbean id 
	gen carib =(country_code!=. )
	
** collapse cvd/diabetes deaths 
	keep if measure=="Deaths"
	
** save full dataset 
	tempfile data 
	save `data', replace 
	
** collapse down to CVD/diabetes deaths
	keep if year ==2015
	keep if measure =="Deaths"
	keep if metric=="Number"
	keep if cause_name=="CVDdiabetes" 
	keep if age =="All Ages"  
	collapse (sum) val, by(country_name year carib)
	tempfile deaths 
	save `deaths', replace 
	
** gen total deaths 
	egen sids_deaths =total(val)
	gen rel_country =val/sids_deaths
	
** generate estimate of caribbean contribution to all SIDS deaths
	collapse (sum) val, by(carib)
	egen sids_deaths =total(val)
	gen rel_region =val/sids_deaths

** generate estimate of % deaths due to cvd/diabetes out of all, by country 
	use `data', clear
	keep if age =="All Ages"
	keep if year ==2015
	keep if measure =="Deaths"
	keep if metric=="Number"
	collapse (sum) val, by(country_name year carib cause_name)
	
	reshape wide val, i(country_name year ) j(cause_name) string
	
	gen rel_cvddiabetes = valCVD/valAll
	
	
** generate estimate of % deaths due to cvd/diabetes out of all, by country 
	use `data', clear
	keep if age =="All Ages"
	keep if year ==2015
	keep if measure =="Deaths"
	keep if metric=="Percent"
	collapse (sum) val, by(country_name year carib cause_name)
	
	reshape wide val, i(country_name year ) j(cause_name) string
	
	gen rel_cvddiabetes = valCVD/valAll
	keep if carib==1 
	sort country_name 
	order country_name valCVD
	outsheet using "Results\Appendix Table 1_relative_contribution_by_country.csv", comma replace
	
	