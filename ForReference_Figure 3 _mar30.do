** Author: Miriam Alvarado
** Date: October 26, 2016
** Purpose: Calculate % deaths from CVD in caribbean SIDS out of all SIDS 
** Edited March 20, 2017 to clarify code 


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
		

	
** Generate graph of all caribbean countries age standardized rates of cvd/diabetes
	use `gbddata', clear
	merge m:1 country_name using `caribcodes' 
	keep if _m==3 | country_name == "United States" | country_name =="Caribbean" 
	
** collapse cvd/diabetes numbers, and rate... you can add rates? 
	collapse (sum) val, by(country_n measure metric age year cause_name)
	sort country_name measure metric age cause_name year
	
	
	twoway line val year if measure =="Deaths" & metric =="Rate" & age =="Age-standardized" & cause_name=="CVDdiabetes" , ytitle("Mortality Rate") xtitle("Years", margin(top))  yscale(range(200(200)800)) ylabel(#5) connect(ascending) lcolor(black) || line val year if measure =="Deaths" & metric =="Rate" & age =="Age-standardized" & cause_name=="CVDdiabetes" & country_name =="Caribbean", lwidth(vthick) lcolor(black) || line val year if measure =="Deaths" & metric =="Rate" & age =="Age-standardized" & cause_name=="CVDdiabetes" & country_name =="United States", lwidth(vthick) lpattern(dash_dot) lcolor (black) legend(label( 1 "Caribbean Countries") label (2 "Caribbean Region") label( 3 "United States") cols(1) region(lstyle(none))) ylabel(,angle(0))
	
	
	capture graph export "Graphs\all_rates_`x'.png", replace
	

** Figure Five
** Regional graph of age-standardized rates compared to absolute death trends
	use `gbddata', clear
	merge m:1 country_name using `caribcodes' 
	keep if  country_name == "United States" | country_name =="Caribbean" 
	
** collapse cvd/diabetes numbers, and rate... you can add rates? 
	collapse (sum) val, by(country_n measure metric age year cause_name)
	
	levelsof country_name, local(list)
	sort country_name measure metric age cause_name year
	foreach x of local list { 
	
	twoway line val year if country_name=="`x'" & measure =="Deaths" & metric =="Number" & age =="All Ages" & cause_name=="CVDdiabetes", ytitle("Number of Deaths")  ylabel(,angle(0) format(%9.0gc)) yscale(range(0)) ylabel(#5)|| line val year if country_name=="`x'" & measure =="Deaths" & metric =="Rate" & age =="Age-standardized" & cause_name=="CVDdiabetes" , ytitle("Mortality Rate", axis(2)) xtitle("Years")  legend(label(1 "Total Deaths") label(2 "Age-standardized Mortality Rate") region(lstyle(none))) yaxis(2)  ylabel(,angle(0) axis(2)) title("`x'") subtitle("CVD/Diabetes Deaths") yscale(range(0(200)1000) axis(2)) ylabel(#5, axis(2))
	
	capture graph export "Graphs\countrytest_`x'.png", replace

	}
	
	
	
	** endfile 