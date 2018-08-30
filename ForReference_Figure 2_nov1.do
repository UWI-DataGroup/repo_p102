** Author: Miriam Alvarado
** Date: May 5, 2015; Edited August 31 to incoporate latest population data; 
** Purpose: Figure 2 
** Edited Nov 1, 2016 to make Figure 1 (Caribbean region pyramid, 1990 and 2015); also to edit formatting of country graph 



	clear all 
	set mem 1g
	set more off 
	set scheme s1color
	local cedar 0 
	
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
	
	collapse (sum) pop, by(reference_date country_name iso3 age_start1 sex)
	rename reference_date year
	

******************************************
** GRAPHING POPULATION PYRAMIDS
******************************************
** reshaping wide by population 
	reshape wide pop, i(country_name year iso3 age_start1 ) j(sex) string 
	levelsof country_name, local (countries)
	levelsof year, local(years)
	gen zero = 0
	replace popmale = popmale*-1
	bysort country_name year: egen test = min(popmale)
	replace test = test-3
	tempfile data
	save `data', replace
	
	
	
	
** Trying to graph all population pyramids in one
** need to generate a new var = percentage of biggest number by country 
	
	keep if year ==2015 
	bysort country_name: egen popmax =max(popfemale)
	replace popfemale =popfemale/popmax
	replace popmale =popmale/popmax
	
	replace country_name ="SVG" if country_name=="Saint Vincent and the Grenadines"
	replace country_name ="USVI" if country_name=="United States Virgin Islands"
	
	merge m:1 country_name using `key' 
	drop order 
	label define orderlabel 1 "Belize" 2 "Guyana" 3 "Haiti" 4 "Dominican Republic" 5 "Suriname" 6 "SVG" 7 "Grenada" 8 "Antigua and Barbuda" 9 "Bahamas" 10 "Trinidad and Tobago" 11 "Saint Lucia" 12 "Jamaica" 13 "Aruba" 14 "Barbados" 15 "Curacao" 16 "Cuba" 17 "Puerto Rico" 18 "Guadeloupe" 19 "USVI" 20 "Martinique"
	label values ordernum orderlabel
	
	
	
	
	
**(Need to make a nod to the x-axis on this chart…)
**(Reduce size of legend and y-axis labelling, relative to other text in chart.)




	twoway bar popmale age_start1 if year==2015, by(ordernum) horizontal xvarlab(Males) barwidth(3) || bar  popfemale age_start1 if  year==2015, by(ordernum, legend(pos(5) )) horizontal xvarlab(Females) barwidth(3)  legend(label(1 Males) label(2 Females)) legend(order(1 2) cols(2) colgap(8) region(lstyle(none))  symysize(1) symxsize(1) size(2)) ytitle("Age", size(2)) xlabel(none) plotregion(style(none)) ysca(noline) xsca(noline) scheme(s1mono) ylabel(,angle(0) labsize(3))
	graph export "Graphs\Figure 2v2.png", replace height(3000) width(4000)

	


