** Author: Miriam Alvarado
** Date: August 17, 2015; Edited October 22 to shift population to 70+
** Edited: January 4, 2016 to add a fourth column to decompositon graphs 
** Purpose: To attempt iterate through 1000 draws for decomposition analysis. 
** Edited Jan 4, 2016 to assess impact of looking at different time periods


		clear all 
		set mem 2g
		set more off 
		set maxvar 7000

** Prepping reference population data from UN 
** (Need to add DMA data)
		use "Data\reference_pop_allyears.dta", clear 
		rename age_start1 age
		drop if age ==. 
		replace iso3="SUR" if country_name =="Suriname"
		replace iso3="GUY" if country_name =="Guyana"
		drop if iso3 ==""
		drop if year ==. 
		tempfile pop 
		save `pop', replace 

** Bring in draw data from IHME (received August 17, 2015)
		local counter =0
		foreach x of numlist 1990 1995 2000 2005 2010 2013 {
			insheet using "Data/death_draws_`x'.csv", comma clear 
			if `counter'==0 {
				tempfile interim 
				}
			else {
				append using `interim'
				}
			save `interim', replace
			local counter =1
		}
		
		replace age =0 if age==97 
		** GBD uses 97 to correspond to under 5 age group. 
		keep if sex ==3
		save `interim', replace 

** Collapse causes to look at CVD+Diabetes
		collapse (sum) death* , by(iso3 year age)

		save `interim', replace 
** now getting total population 
		merge 1:1 age iso3 year using `pop'
		
		drop if _m!=3
		drop _m 


** Generate all age population to see if pop>150,000 in 2010 - nevermind we've scrapped this part 
		preserve
		collapse (sum) pop, by(iso3 year)
		rename pop totalpop
		reshape wide totalpop, i(iso3) j(year)
		*keep if totalpop2010>150
		** keep all population sizes 
		
		tempfile poplim 
		save `poplim', replace
		restore

	
** Reshape to fit for calcualtions
		reshape wide death* pop, i(iso3 country_name age) j(year)
	
** Merge on total population
		merge m:1 iso3 using `poplim' 
		keep if _m==3
		drop _m 

** Modified age structure doesn't vary across draws 
		gen agestruc2000_pop2010 = (pop2000/totalpop2000)*totalpop2010

		tempfile data 
		save `data', replace 
		save "Data\allyears_decomp.dta", replace 

