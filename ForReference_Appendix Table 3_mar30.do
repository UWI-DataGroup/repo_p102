** Author: Miriam Alvarado
** Date: January 4, 2016
** Purpose: To try and look at migration data for one of the tables
** 3. Look at absolute numbers of migration; and relative migration numbers to population when it comes to the table on overall growth rate. 


	clear all 
	set mem 2g
	set more off 
	set scheme s1color
	
******************************************
** DATA PREP 
******************************************

** bring in country codes
	insheet using "Data\codes.csv", comma clear 	
	tempfile caribcodes
	save `caribcodes', replace

** insheet male pop data from UN WPP
	insheet using "Data\migration.csv", comma clear
	
** keep Caribbean countries only 
	merge m:1 country_code using `caribcodes'
	keep if _m==3
	drop _m 
	
** prepping data	
	keep _* country*
	reshape long _, i(country_code country_name) j(year)
	rename _ migration
	destring migration, replace force 
	
	gen id =round(year,10)
	keep if id>1975
	
	collapse (sum) migration, by(country* id)
	rename id year 
	tempfile migration 
	save `migration', replace 
	


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

** prep variables for use  - some are nonumeric and nonnumerics should be missing
	foreach var of varlist age* {
		destring `var' , force replace 
		}
		

** Reshaping data set so we have age long
	reshape long age, i(country_code reference_date sex) j(agecat ) string
	rename age pop
	split agecat, parse("_") gen(age_start) 
	destring age_start1, replace force
	
	tempfile basic
	save `basic', replace 
	
** Merge migration and  pop data 
	rename reference_date year
	*rename major_area_region_country_or_are country_name
	
	collapse (sum) pop, by(country_code year)
	
	merge 1:1 country_code year using `migration' 
	
	keep if _m==3
	drop _m 
	
	** Note: merging year vlues that are 1950-1955 with single year estimates. 
	** This way pop est in 1955 are matched with 1950-1955.
	gen rel_migration = migration/pop 
	
	
** reshape wide
	reshape wide migration rel_migration pop, i(country*) j(year)
	sort country_name 
	outsheet using "Results\migration_overtime.csv", comma replace 