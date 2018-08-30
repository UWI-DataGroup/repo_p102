** Author: Miriam Alvarado
** Date: May 5, 2015; Edited August 31 to incoporate latest population data; 
** Purpose: Figure 2 
** Edited Nov 1, 2016 to make Figure 1 (Caribbean region pyramid, 1990 and 2015); also to edit formatting of country graph 



	clear all 
	set mem 1g
	set more off 
	set scheme s1color
	local ceder 0 
	
******************************************
** DATA PREP 
******************************************
	
	
** bring in country order 
	insheet using "Data\orderkey.csv", comma clear names 
	tempfile key 
	save `key', replace 
	
** bring in country codes
	insheet using "Data\codes.csv", comma clear 
	tempfile caribcodes
	save `caribcodes', replace

** insheet male pop data from UN WPP
	insheet using "Data\WPP2015_MALE_full.csv", comma clear
	gen sex="male"
	tempfile males
	save `males', replace

** insheet female pop data 
	insheet using "Data\WPP2015_FEMALE_full.csv", comma clear
	gen sex="female"
	append using `males' 

** keep Caribbean countries only 
	merge m:1 country_code using `caribcodes'
	keep if _m==3
	drop _m 

** prep variables for use 
	foreach var of varlist age* {
		destring `var' , force replace 
		}

** handling age vars
	drop age80_100
	reshape long age, i(country_code reference_date sex) j(agecat ) string
	rename age pop
	split agecat, parse("_") gen(age_start) 
	destring age_start1, replace force
	keep country_name pop sex reference_date iso3 age_start1
	destring pop, replace force

** Age group 80+ used for some years, and then more refined older age categories were used 
	*replace age_start1=80 if age_start1>80
	
	collapse (sum) pop, by(reference_date age_start1 sex)
	rename reference_date year
	

******************************************
** GRAPHING POPULATION PYRAMIDS
******************************************
** reshaping wide by population 
	reshape wide pop, i( age_start1 year ) j(sex) string 
	levelsof year, local(years)
	gen zero = 0
	replace popmale = popmale*-1
	bysort year: egen test = min(popmale)
	replace test = test-3
	tempfile data
	save `data', replace
	
	
	
** Trying to graph all population pyramids in one
** need to generate a new var = percentage of biggest number by country 
	
	keep if year ==2015 | year ==1990 
	bysort year: egen popmax =max(popfemale)
	*replace popfemale =popfemale/popmax
	*replace popmale =popmale/popmax
	


	twoway bar popmale age_start1, by(year) horizontal xvarlab(Males) barwidth(3) || bar  popfemale age_start1, by(year, legend(pos(5) )) horizontal xvarlab(Females) barwidth(3)  legend(label(1 Males) label(2 Females)) legend(order(1 2) cols(2) colgap(8) region(lstyle(none))  symysize(1) symxsize(1) size(2)) ytitle("Age", size(2)) xlabel(none) plotregion(style(none)) ysca(noline) xsca(noline) scheme(s1mono) ylabel(,angle(0) labsize(3)) xlabel( -2000 "2,000" -1000 "1,000" 0 "0" 2000 "2,000" 1000 "1,000"  , labsize(2))
	graph export "Graphs\Figure pyramid 1v1.png", replace height(2000) width(4000)

	


