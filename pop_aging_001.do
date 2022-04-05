** Author: Miriam Alvarado
** Date: Nov 1, 2017 
** Purpose: To combine all code for pop aging 

	capture log close
	log using 20171104_pop_aging_001, replace
	clear all 
	set more off 
	version 15
	macro drop _all
	set more 1
	set linesize 80 
		
** 	Setting filepath and directory
	global filepath `""C:\Sync\statistics\analysis\a064\versions\version02\""'
	cd $filepath
	
** 	Make directories
	cap mkdir "Results" 
	cap mkdir "Graphs" 
	cap mkdir "Interim results" 
	
** Tempfile Definitions
	** caribcodes 		is a list of all Caribbean countries (iso3 and country name) 
	** males 			is the UN WPP pop for males
	** females 			in the UN WPP pop for females 
	** datafig1			is the data prepped to be used for Figure 1
	** basic 			is the WPP data (both sexes) in long format, with population data for only Caribbean countries 
	** over70 			is the country-year specific population 70+
	** allages			is the country-year specific population (all ages summed) 
	** propold 			is the country-year specific proportion 70+ 
	** key 				is the ordering of countries based on their 2015 proportion 70+
	** pop 				is the tempfile for the country-year-age specific population 
	** poplim 			is the tempfile for total population, in wide format, by iso3 (same data as "allages" but in wide format)
	** datafig2 		is the tempfile of data prepped to be used Figure 2 (prior to be collapsed by year as in Fig 1)
	** sids 			is similar to caribcodes but the country names are in a slightly different format (UN vs GBD) 
	** caribcodes2 		is similar again, but with the slight modifications needed to merge on different country name formats
	** gbddata 			is a slightly prepped file w/ GBD results 
	** data 			is the file w/ GBD draws
	** results 			is the file w/ GBD prepped draw level data 
	** migration 		is all-country UN migration data 
	** popwide 			is pop just reshaped into wide format for a merge 
	
******************************************
** Data Prep 
******************************************

** bring in country codes
	insheet using "data\codes.csv", comma clear 	
	tempfile caribcodes
	save `caribcodes', replace

** insheet male pop data from UN WPP
	insheet using "data\WPP2015_MALE_full.csv", comma clear
	gen sex="male"
	tempfile males
	save `males', replace

** insheet female pop data 
	insheet using "data\WPP2015_FEMALE_full.csv", comma clear
	gen sex="female"
	append using `males' 

** keep Caribbean countries only 
	merge m:1 country_code using `caribcodes'
	keep if _m==3
	drop _m 

** prep variables for use  - some values are nonnumeric and these nonnumerics values should be missing
	foreach var of varlist age* {
		destring `var' , force replace 
		}
		
** Fix long Names 	
	replace country_name ="SVG" if country_name=="Saint Vincent and the Grenadines"
	replace country_name ="USVI" if country_name=="United States Virgin Islands"
	
	rename reference_date_as_of_1_july year 
	tempfile datafig1
	save `datafig1', replace 
	save "data\fig1_data", replace 
	
** Reshaping data set so we have age long
	reshape long age, i(country_code year sex) j(agecat) string
	rename age pop
	split agecat, parse("_") gen(age_start) 
	destring age_start1, replace force

** Identify population 70+ 
	gen under70=0
	replace under70=1 if age_start1<70
	
	tempfile basic
	save `basic', replace 
/*	
******************************************
** PROPORTION 70+ 
******************************************

** Estimate proportion 70+  
	collapse (sum) pop, by(under70 country_name year)
	keep if under70==0
	rename pop pop_over70
	tempfile over70 
	save `over70', replace

** summ population across all ages 
	use `basic', clear
	collapse (sum) pop, by(country_name year)
	rename pop allagespop
	tempfile allages
	save `allages', replace
	
** merge on prop over 70 
	merge 1:1 country_name year using `over70' 
	drop _m 

** Gen proportion 70+ 
	gen prop_over70 =pop_over70/allagespop
	drop under70 
	tempfile propold 
	save `propold', replace
	
** Graph prop 70+ by country (check y axis to make sure all in agreement. Also, year range)
	gsort - year prop_over70
	gen order =_n
	replace order=. if year!=2015
	gsort country_name -year 
	carryforward order, replace 
	gen ordernum=order
	keep country_name order 
	duplicates drop country_name order, force 
	gen ordernum=order 
	
	tempfile key 
	save `key', replace 
	save "data\key", replace

	
******************************************
** TABLE 1
******************************************	
	use `propold', clear	 
	drop *pop* 
	** keep if year==1975 | year==1985 | year==1990 | year==1995 | year ==2005 | year==2015
	keep if year==1990 | year==1995 | year==2000 | year ==2005 | year==2010 | year==2015
	
	reshape wide prop_over70, i(country_name) j(year)
	forvalues y =1990(5)2015 {
		egen mad`y' =mad(prop_over70`y') 
		}
	save "Results/Table 1.csv", replace 
	
******************************************
** REFERENCE POPULATION DATA FOR OTHER CALCULATIONS
******************************************	


** exporting age specific population 
	use `basic', clear
	drop if pop ==.
	keep country_name pop sex year iso3 age_start1
	replace age_start1=80 if age_start1>80
	collapse (sum) pop, by(year country_name iso3 age_start1)
	 
	keep if year ==1990 | year==1995 | year ==2000 | year ==2005 | year ==2010 | year ==2015

	rename age_start1 age
	tempfile pop 
	save `pop', replace 
	save "Interim results/reference_pop_allyears2015.dta", replace 

** Bring in draw data from IHME (received Sept, 2017)
		insheet using "Data/oct6_death_draws.csv", comma clear 
		rename year_id year 
		rename ihme_loc_id iso3 
		gen age =substr(age_group_name, 1,2)
		destring age, replace force 
		replace age =97 if age==. | age==1
		rename sex sexlabel
		gen sex =3 if sexlabel=="both"
		drop if sex==. 
		rename cause_name acause 
		replace acause ="cvd_ihd" if acause=="Ischemic heart disease"
		replace acause ="cvd_stroke" if acause=="Cardiovascular diseases"	
		replace acause ="diabetes" if acause=="Diabetes mellitus"	
		keep if acause=="cvd_ihd" | acause=="cvd_stroke" | acause=="diabetes"
	
		forvalues x= 0/999 {
			rename draw_`x' death_`x'
			}
			
** keep Caribbean countries only 
		merge m:1 iso3 using `caribcodes'
		keep if _m==3
		drop _m 
		
** GBD uses 97 to correspond to under 5 age group. 
		replace age =0 if age==97 
		
** Collapse causes to look at CVD+Diabetes
		collapse (sum) death* , by(iso3 year age)

** now getting total population 
		merge 1:1 age iso3 year using `pop'
		drop if _m!=3
		drop _m 

** Reshape to fit for calcualtions
		reshape wide death* pop, i(iso3 country_name age) j(year)
	
** Generate all age population by country
		preserve
		collapse (sum) pop*, by(iso3)
		foreach x of numlist 1990 2015 { 
			rename pop`x' totalpop`x'
			}
	
		tempfile poplim 
		save `poplim', replace
		restore
		
** Merge on total population
		merge m:1 iso3 using `poplim' 
		keep if _m==3
		drop _m 
		tempfile data 
		save `data', replace 
		save "Interim results\allyears_decomp2015.dta", replace 


******************************************
** Figure 1 (Caribbean region pyramid, 1990 and 2015); also to edit formatting of country graph 
******************************************	
	
** bring in data for Figure 1 (compiled earlier) 
	use `datafig1', clear 

** handling age vars
	drop age80_100
	reshape long age, i(country_code year sex) j(agecat ) string
	rename age pop
	split agecat, parse("_") gen(age_start) 
	destring age_start1, replace force
	keep country_name pop sex year iso3 age_start1
	tempfile datafig2 
	save `datafig2', replace 
	save "data\fig2_data", replace 
	
	collapse (sum) pop, by(year age_start1 sex)
	 
** reshaping wide by population 
	reshape wide pop, i( age_start1 year ) j(sex) string 
	levelsof year, local(years)
	gen zero = 0
	replace popmale = popmale*-1
	bysort year: egen test = min(popmale)
	replace test = test-3
	keep if year ==2015 | year ==1990 
	bysort year: egen popmax =max(popfemale)
	
	twoway bar popmale age_start1, by(year) horizontal xvarlab(Males) barwidth(3) || bar  popfemale age_start1, by(year, legend(pos(5) )) horizontal xvarlab(Females) barwidth(3)  legend(label(1 Males) label(2 Females)) legend(order(1 2) cols(2) colgap(8) region(lstyle(none))  symysize(1) symxsize(1) size(2)) ytitle("Age", size(2)) xlabel(none) plotregion(style(none)) ysca(noline) xsca(noline) scheme(s1mono) ylabel(,angle(0) labsize(3)) xlabel( -2000 "2,000" -1000 "1,000" 0 "0" 2000 "2,000" 1000 "1,000"  , labsize(2))
	graph export "Graphs\Figure 1.png", replace height(2000) width(4000)

******************************************
** Figure 2 (Caribbean region pyramid, 1990 and 2015); also to edit formatting of country graph 
******************************************	
	use "data\fig2_data", clear 
	
	collapse (sum) pop, by(year country_name iso3 age_start1 sex)
	 
	
** reshaping wide by population 
	reshape wide pop, i(country_name year iso3 age_start1 ) j(sex) string 
	levelsof country_name, local (countries)
	levelsof year, local(years)
	gen zero = 0
	replace popmale = popmale*-1
	bysort country_name year: egen test = min(popmale)
	replace test = test-3
	keep if year ==2015 
	bysort country_name: egen popmax =max(popfemale)
	replace popfemale =popfemale/popmax
	replace popmale =popmale/popmax
	
	merge m:1 country_name using `key' 
	drop order 
	
******************************************
** MANUALLY CHECK LABEL ORDER 
******************************************
	label define orderlabel 1 "Belize" 2 "Guyana" 3 "Haiti" 4 "Dominican Republic" 5 "Suriname" 6 "SVG" 7 "Grenada" 8 "Antigua and Barbuda" 9 "Bahamas" 10 "Trinidad and Tobago" 11 "Saint Lucia" 12 "Jamaica" 13 "Aruba" 14 "Barbados" 15 "Curacao" 16 "Cuba" 17 "Puerto Rico" 18 "Guadeloupe" 19 "USVI" 20 "Martinique"
	label values ordernum orderlabel
	
	twoway bar popmale age_start1 if year==2015, by(ordernum) horizontal xvarlab(Males) barwidth(3) || bar  popfemale age_start1 if  year==2015, by(ordernum, legend(pos(5) )) horizontal xvarlab(Females) barwidth(3)  legend(label(1 Males) label(2 Females)) legend(order(1 2) cols(2) colgap(8) region(lstyle(none))  symysize(1) symxsize(1) size(2)) ytitle("Age", size(2)) xlabel(none) plotregion(style(none)) ysca(noline) xsca(noline) scheme(s1mono) ylabel(,angle(0) labsize(3))
	graph export "Graphs\Figure 2.png", replace height(3000) width(4000)

	
******************************************
** Figure 3   (Caribbean region pyramid, 1990 and 2015)
******************************************	
		
** bring in SIDS list 
	insheet using "data\sids.csv", comma clear names
	gen country_name =substr(unesco, 4,.)
	replace country_name =ltrim(country_name)
	replace country_name = subinstr(country_name, "*", "", .) 
	replace country_name = subinstr(country_name, "St.", "Saint", .) 
	replace country_name = "The Bahamas" if country_name == "Bahamas"
	drop in 40/48
	tempfile sids
	save `sids', replace
	
** bring in country codes
	insheet using "data\codes.csv", comma clear 	
	replace country_name = "The Bahamas" if country_name == "Bahamas"
	replace country_name = "Virgin Islands, U.S." if country_name == "United States Virgin Islands"

	tempfile caribcodes2
	save `caribcodes2', replace

** bring in GBD  data 
	insheet using "data\IHME-GBD_2015_DATA-1e3e3f45-1.csv", comma clear names 
	rename location country_name
	gen cause_name=cause
	replace cause_name ="CVDdiabetes" if cause_name =="Cardiovascular diseases" | cause_name =="Diabetes mellitus"
	replace cause_name ="Allcause" if cause =="All causes"
	tempfile gbddata 
	save `gbddata', replace 
		
** Generate graph of all caribbean countries age standardized rates of cvd/diabetes
	merge m:1 country_name using `caribcodes2' 	
	keep if _m==3 | country_name == "United States" | country_name =="Caribbean" 
	
** collapse cvd/diabetes numbers
	collapse (sum) val, by(country_n measure metric age year cause_name)
	sort country_name measure metric age cause_name year
	
	twoway line val year if measure =="Deaths" & metric =="Rate" & age =="Age-standardized" & cause_name=="CVDdiabetes" , ytitle("Mortality Rate") xtitle("Years", margin(top))  yscale(range(200(200)800)) ylabel(#5) connect(ascending) lcolor(black) || line val year if measure =="Deaths" & metric =="Rate" & age =="Age-standardized" & cause_name=="CVDdiabetes" & country_name =="Caribbean", lwidth(vthick) lcolor(black) || line val year if measure =="Deaths" & metric =="Rate" & age =="Age-standardized" & cause_name=="CVDdiabetes" & country_name =="United States", lwidth(vthick) lpattern(dash_dot) lcolor (black) legend(label( 1 "Caribbean Countries") label (2 "Caribbean Region") label( 3 "United States") cols(1) region(lstyle(none))) ylabel(,angle(0))
	graph export "Graphs\Figure 3.png", replace
	
	
******************************************
** Figure 4   
******************************************	

** reformat pop data	
		use `pop', clear
		reshape wide pop, i(iso3 age) j(year)
		tempfile popwide 
		save `popwide', replace 
	
** Bring in draw data from IHME (received August 17, 2015)
		use "Interim results\allyears_decomp2015.dta", clear 
		
** Collapse causes to look at CVD+Diabetes
		collapse (sum) death* , by(iso3  age )

** now getting total population 
		merge 1:1 age iso3 using `popwide'
		drop if _m!=3
		drop _m 

** Merge on total population
		merge m:1 iso3 using `poplim' 
		keep if _m==3
		drop _m 

** Modified age structure doesn't vary across draws 
		gen agestruc1990_pop2015 = (pop1990/totalpop1990)*totalpop2015
		tempfile data 
		save `data', replace 

** setting local to save
		local start =1 

** generate measures of interest using UN pop and GBD rates, looping through 0-999
		foreach x of numlist 0/999 {
			use `data', clear
			
			keep agestruc1990_pop2015 iso3 country_name total* pop* death_`x'1990 death_`x'2015
			gen rt_1990`x' = death_`x'1990/pop1990
			gen rt_2015`x' = death_`x'2015/pop2015
	
			gen deaths_2015pop_1990age_`x' = agestruc1990_pop2015*(rt_1990`x')
			gen deaths_2015pop_2015age_`x' = pop2015*(rt_1990`x')
			
			collapse (sum) death* , by(country_name iso3)

			gen change_deaths_`x'=((death_`x'2015-death_`x'1990)/death_`x'1990)
			
			** Combined metrics of interest
			gen change_pop_growth_`x'=(deaths_2015pop_1990age_`x'-death_`x'1990)/death_`x'1990
			gen change_aging_`x' = (deaths_2015pop_2015age_`x'-deaths_2015pop_1990age_`x')/death_`x'1990
			gen change_epi_`x' = (change_deaths_`x'-change_aging_`x'-change_pop_growth_`x') 
			gen test_epi_`x' = (death_`x'2015-deaths_2015pop_2015age_`x')/death_`x'1990

			keep iso3 country_name change_pop_growth_`x'  change_aging_`x' change_epi_`x' test_epi_`x' change_deaths_`x'

			reshape long change_pop_growth_ change_aging_ change_epi_ test_epi_ change_deaths_, i(country_name iso3) j(iter)

			
			if `start' ==1 { 
				tempfile results
				}
			else { 
				append using `results'
				}

			save `results', replace 
			local start =0
			}

	** changes in epi	
		bysort iso3: egen med_epi = median(change_epi_)
		bysort iso3: egen lower_epi = pctile(change_epi_), p(2.75)
		bysort iso3: egen upper_epi = pctile(change_epi_), p(97.5)

	** changes in aging
		bysort iso3: egen med_aging = median(change_aging_)
		bysort iso3: egen lower_aging = pctile(change_aging_), p(2.75)
		bysort iso3: egen upper_aging = pctile(change_aging_), p(97.5)

	** changes in aging
		bysort iso3: egen med_popgrowth = median(change_pop_growth_)
		bysort iso3: egen lower_popgrowth = pctile(change_pop_growth_), p(2.75)
		bysort iso3: egen upper_popgrowth = pctile(change_pop_growth_), p(97.5)

	** changes in deaths 
		bysort iso3: egen med_deaths = median(change_deaths_)
		bysort iso3: egen lower_deaths = pctile(change_deaths_), p(2.75)
		bysort iso3: egen upper_deaths = pctile(change_deaths_), p(97.5)

	** Graphing bar charts with uncertainty
		duplicates drop iso3 country_name, force
		sort country_name
	
	** Save dataset for Figure 4
	save "data\fig4_data", replace
	
	** graphing
		gen zero=0
		gen addage = med_aging if med_epi<0  & med_aging>0
		gen basepop =0 
		replace basepop =med_aging if med_aging<0
		replace basepop =med_epi +basepop if med_epi>0
		replace addage = med_aging+med_epi if med_epi>0 
		replace addage = med_epi if med_epi>0 & med_aging<0
		gen addpop = addage+med_popgrowth
		
		** Additional code to adjust for Belize's pattern. 
		gen graphepi=med_epi
		replace graphepi =med_epi +med_aging if iso3=="BLZ"
		replace zero=med_aging if iso3=="BLZ"
		replace addage=0 if iso3=="BLZ" 
		replace addpop =med_popgrowth if iso3=="BLZ" 
		
		gsort - med_deaths
		gen y1=_n
		
		*label define orderlabel 14 "SVG" 13 "Guyana" 12 "Barbados" 11 "Grenada" 10 "Jamaica" 9 "Antigua" 8 "Cuba" 7 "Saint Luia" 6 "TNT" 5 "Belize" 4 "Haiti" 3 "Suriname" 2 "Bahamas" 1 "DR" , replace 
		label define orderlabel 14 "Grenada" 13 "Barbados" 12 "Guyana" 11 "Haiti" 10 "Cuba" 9 "Antigua" 8 "SVG" 7 "TNT" 6 "Saint Lucia" 5 "Jamaica" 4 "Suriname" 3 "Belize" 2 "Bahamas" 1 "DR" , replace 
		label values y1 orderlabel
		
		** for graphing black line at zero. 
		gen realzero=0
		
		** graphing code 
		set scheme s1color  
		
		
		twoway rbar zero graphepi y1, barwidth(.5) horizontal  color("27 158 119") || rbar basepop addage y1 , barwidth(.5) horizontal color("217 95 2") || rbar addage addpop y1 , barwidth(.5) horizontal color("117 112 179") || rcap realzero realzero y1, horizontal lcolor(black) msize(vlarge)  || scatter y1 med_deaths, msymbol(diamond_hollow) mcolor(black) msize(medlarge)  ylabel(1(1)14,valuelabel angle(0) labsize(2)) legend( order( 1 2 3 5)label(3 Percent change driven by changes in population size) label(2 Percent change driven by changes in age structure) label(1 Percent change driven by changes in age-standardized mortality rates)  label(5 "Percent change in deaths from 1990-2015") cols(1) size(2) symysize(1) symxsize(2)) ytitle("") xtitle("Percent Change in Deaths, 1990-2015",margin(top)) legend(region(lcolor(none)))  xlabel(-.5 "-50%" 0 "0" .5 "50%" 1 "100%" 1.5 "150%" 2 "200%", labsize(2))
		graph export "Graphs/Figure 4.png", replace height(1600) width(1600) 
		
		** table code 
		gen sort =_n
		gsort - sort 
		keep country_name med_epi lower_epi upper_epi med_aging lower_aging upper_aging med_popgrowth lower_popgrowth upper_popgrowth med_deaths lower_deaths upper_deaths
		
		outsheet using "Results/Table 2.csv", comma replace 
		save "Interim results/Table 2 Stata format.dta", replace 


******************************************
** Appendix Table 1 % deaths from CVD in caribbean SIDS out of all SIDS 
******************************************
	use `sids', clear
	merge m:1 country_name using `caribcodes'
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

** generate estimate of % deaths due to cvd/diabetes out of all, by country 
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
	keep country_name valCVD 
	outsheet using "Results\Appendix Table 1.csv", comma replace
	
******************************************
** Appendix Table 3 Migration
******************************************	

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
	
** Merge migration and  pop data 
	use `basic', clear 
	
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
	outsheet using "Results\Appendix Table 3.csv", comma replace 
