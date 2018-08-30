** Author: Miriam Alvarado
** Date: April 13, 2015
** Edited August 28, 2015 to add in 2015 data; Edited Oct 2015 for Alafia's graphs. 
** Edited October 22 2015 for 70+ pop, MAD, 
** Purpose: To explore and begin initial prep of UN Population data and conduct basic tabulations including 70+ and 80+ 

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
		
** Dropping a non mutually exclusive age category
	*drop age80_100

** Reshaping data set so we have age long
	reshape long age, i(country_code reference_date sex) j(agecat ) string
	rename age pop
	split agecat, parse("_") gen(age_start) 
	destring age_start1, replace force

** Identify population 70+ 
	gen under70=0
	replace under70=1 if age_start1<70
	destring pop, replace force
	
	tempfile basic
	save `basic', replace 
	

******************************************
** PROPORTION 70+ 
******************************************

** Estimate proportion 70+  
	collapse (sum) pop, by(under70 country_name referen)
	keep if under70==0
	rename pop pop_over70
	tempfile over70 
	save `over70', replace

** summ population across all ages 
	use `basic', clear
	collapse (sum) pop, by(country_name reference_date)
	rename pop allagespop
	tempfile allages
	save `allages', replace
	
** merge on prop over 70 
	merge 1:1 country_name reference_date using `over70' 
	drop _m 

** Gen proportion 70+ 
	gen prop_over70 =pop_over70/allagespop
	drop under70 

** Graph prop 70+ by country (check y axis to make sure all in agreement. Also, year range)
replace country_name ="SVG" if country_name=="Saint Vincent and the Grenadines"

	twoway scatter prop_over70 reference_date if reference_date>=1975, xtitle("Year") by(country_name) ylabel(,angle(0)) msize(large) legend(label(1 "Pop 70+") region(lstyle(none)))   xscale(range(1975/2015)) xlabel(1975(10)2015) ytitle("Proportion 70+") 
	graph export "Graphs\prop_over70_2015.png", replace height(7000) width(8000)
	rename reference_date_as_of_1_july reference_date
	keep country_name reference_date prop_over70 
	tempfile data1 
	save `data1', replace

	
******************************************
** OTHER MEASURES OF AGING - MAD of proportion 70+  - TABLE ONE 
******************************************
**calculate MAD
	use `data1', clear
	collapse (mean) prop_over70, by(reference_date)
	rename prop_over70 mean_propover70
	merge 1:m reference_date using `data1'
	gen abs_diff = abs(prop_over70 -mean_propover70)
	collapse (mean) abs_diff, by(reference_date)
	

	gen country_name ="xMAD"
	rename abs_diff prop_over70
	append using `data1'
	keep if ref==1975 | ref ==1985 | ref==1995 | ref== 2005 | ref==2015
	order country_name reference_date prop_over70  

	reshape wide  prop_over70 ,i(country_name ) j(reference_date)
	outsheet using "Results\measures_of_aging_mad_2015.csv", comma replace

	
******************************************
** POPULATION GROWTH CALCULATIONS 
******************************************
	
/* ** testing total populatiion growth rate compared to un estimates. 
	use `basic', clear 
	collapse (sum) pop, by(country_name reference_date)
	reshape wide pop, i(country_name ) j(reference_date)
	gen rate = (pop1955-pop1950)/(pop1950*5)
	gen rate2 = ln(pop1955/pop1950)/5 
	gen test= ((pop1990/pop1980)^(1/d))-1 */
	

** calculate rate of population change 70+ 
	use `basic', clear 
	keep if under70==0
	collapse (sum) pop, by(country_name reference_date)
	reshape wide pop, i(country_name) j(reference_date)
	gen oldrate1975=ln(pop1985/pop1975)/10
	gen oldrate1985=ln(pop1995/pop1985)/10
	gen oldrate1995=ln(pop2005/pop1995)/10
	gen oldrate2005=ln(pop2015/pop2005)/10
	drop pop*
	tempfile old_rates
	save `old_rates', replace

** calculate rate of population change overall 
	use `basic', clear 
	
	collapse (sum) pop, by(country_name reference_date)
	reshape wide pop, i(country_name) j(reference_date)
	gen rate1975=ln(pop1985/pop1975)/10
	gen rate1985=ln(pop1995/pop1985)/10
	gen rate1995=ln(pop2005/pop1995)/10
	gen rate2005=ln(pop2015/pop2005)/10

** merge together both estimates of population growth for comparison
	merge 1:1 country_name using `old_rates'
	drop pop*
	drop  _merge
	order country_name *1975 *1985 *1995 *2005
	gen id ="x"
	tempfile growth 
	save `growth', replace 
	
	
** adding in MAD for growth rates. 	
	collapse (mean) old* rate*
	rename oldrate1975 meanoldrate1975
	rename oldrate1985 meanoldrate1985
	rename oldrate1995 meanoldrate1995
	rename oldrate2005 meanoldrate2005
	rename rate1975 meanrate1975 
	rename rate1985 meanrate1985 
	rename rate1995 meanrate1995 
	rename rate2005 meanrate2005 
	gen id ="x"
	
	merge 1:m id using `growth'
	drop _m
	
	gen abs_diff_old1975= abs( oldrate1975- meanoldrate1975)
	gen abs_diff_old1985= abs(  oldrate1985 -meanoldrate1985)
	gen abs_diff_old1995= abs( oldrate1995 -meanoldrate1995)
	gen abs_diff_old2005= abs( oldrate2005 -meanoldrate2005)
	gen abs_diff_1975= abs(  rate1975 -meanrate1975 )
	gen abs_diff_1985= abs(  rate1985 -meanrate1985 )
	gen abs_diff_1995= abs(  rate1995 -meanrate1995 )
	gen abs_diff_2005= abs(  rate2005 -meanrate2005 )
	collapse (mean) abs_diff*
	gen country_name ="xMAD"
	
	rename abs_diff_old1975 oldrate1975
	rename abs_diff_old1985 oldrate1985
	rename abs_diff_old1995 oldrate1995
	rename abs_diff_old2005 oldrate2005
	rename abs_diff_1975 rate1975 
	rename abs_diff_1985 rate1985 
	rename abs_diff_1995 rate1995 
	rename abs_diff_2005 rate2005 
	
	
	append using `growth'
	sort country_name

	
	order country_name rate1975 oldrate1975 rate1985 oldrate1985 rate1995 oldrate1995 rate2005 oldrate2005
	drop id 
	outsheet using "Results\rates_of_pop_growth_2015.csv", comma replace

	
** Scatter prop 70+ vs (growth rate 70+/growth rate <70)
	use `growth', clear
	reshape long rate oldrate, i(country_name) j(reference_date)
	replace reference_date = reference_date +5
	replace country_name = "SVG" if country_name =="Saint Vincent and the Grenadines"
	merge 1:1 country_name reference_date using `data1'
	keep if _m==3
	drop _m

	
	
	preserve 
	collapse (mean) oldrate prop_over70, by(reference_date)
	rename oldrate avgoldrate
	rename prop_over70 avgprop_over70
	tempfile avg 
	save `avg', replace 
	restore 
	
	merge m:1 reference_date using `avg'
	
	levelsof reference_date, local(years)
	tempfile graph 
	save `graph', replace 
	foreach year of local years {
	use `graph', clear 
	keep if ref==`year'
	local y = [avgoldrate]
	local x = [avgprop_over70]
	twoway scatter oldrate prop_over70, mlabel(country_name) yline(`y') xline(`x') xtitle("Proportion 70+") ytitle("Growth Rate 70+") title("Aging Dynamics in the Caribbean, `year'") 
	
	graph export "Graphs\aging_profiles_`year'.png", replace height(7000) width(8000)
	} 
	
	
	
******************************************
** REFERENCE POPULATION DATA FOR OTHER CALCULATIONS
******************************************	

** exporting age specific population 
	use `basic', clear
	drop if pop ==.
	
	keep country_name pop sex reference_date iso3 age_start1
	destring pop, replace force
	replace age_start1=80 if age_start1>80
	collapse (sum) pop, by(reference_date country_name iso3 age_start1)
	rename reference_date year
	
	keep if year ==1990 | year==1995 | year ==2000 | year ==2005 | year ==2010 | year ==2015
	
	tempfile popfix 
	save `popfix', replace
	keep if year>=2010
	collapse (mean) pop, by(country_name iso3 age_start1)
	gen year =2013
	append using `popfix'
	drop if year ==2015
	
	save "Data\reference_pop_allyears.dta", replace 
		
		
	keep if year==1990 | year==2010

	save "Data\reference_pop_2015.dta", replace 