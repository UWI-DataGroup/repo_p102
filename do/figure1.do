
qui {

******************************************
** Figure 1 (Caribbean region pyramid, 1990 and 2015); also to edit formatting of country graph 
** Author: 	Ian Hambleton
** Date:  	Nov 5, 2017 
******************************************	

	clear all 
	set more off 
	version 15
	macro drop _all
	set more 1
	set linesize 80 
		
** 	Setting filepath and directory
	global filepath `""C:\Sync\statistics\analysis\a064\versions\version02\""'
	cd $filepath

	capture log close
	noi log using regional_metrics, replace
	
** bring in data for Figure 1 (compiled earlier) 
	use "data\fig1_data", clear 

** handling age vars
	drop age80_100
	reshape long age, i(country_code year sex) j(agecat ) string
	rename age pop
	split agecat, parse("_") gen(age_start) 
	destring age_start1, replace force
	keep country_name pop sex year iso3 age_start1
	
	tempfile datafig2 
	save `datafig2', replace 
	
	collapse (sum) pop, by(year age_start1 sex)
	 
** reshaping wide by population 
	reshape wide pop, i( age_start1 year ) j(sex) string 
	levelsof year, local(years)
	gen zero = 0
	replace popmale = popmale*-1
	bysort year: egen test = min(popmale)
	replace test = test-3
	keep if year==1990 | year==1995 | year==2000 | year==2005 | year==2010 | year==2015 
	bysort year: egen popmax =max(popfemale)

}



preserve

*******************************************************	
** ADDITIONAL METRICS FOR REGION
*******************************************************	
** A. CHILDREN 		age_start1	(0-4, 5-9, 10-14 yrs)
** B. OLDER ADULTS 	age_start1	(45+) 
** C. ELDERLY 		age_start1	(70+) 
** D. WORKING AGE	age_start1	(15-64) also do (15-69)
** E. AGED DEPENDENCY RATIO --> 65+/(15to64)
*******************************************************	

qui {

** TOTAL POP OVERALL AND BY SEX
replace popmale = popmale*-1
bysort year: egen totf = sum(popfemale)
bysort year: egen totm = sum(popmale)
gen poptotal = popfemale + popmale
bysort year: egen tot = sum(poptotal)

*******************************************************	
** A. CHILDREN 		age_start1	(0-4, 5-9, 10-14 yrs)
*******************************************************	
** Proportion <15 overall and by sex	
gen fifteen = 0
replace fifteen = 1 if age_start1 <15 
bysort year fifteen: egen totf15 = sum(popfemale)
bysort year fifteen: egen totm15 = sum(popmale)
bysort year fifteen: egen tot15 = sum(poptotal)
gen percf15 = (totf15 / totf)*100
gen percm15 = (totm15 / totm)*100
gen perc15 =  (tot15  / tot) *100

** Tabulate the statistics
egen tag15 = tag(fifteen)
noi dis "" _newline(3)
noi dis "A. CHILDREN. percentage aged 0-15 yrs)"
noi dis "percf15 = female percentage aged less than 15 years"
noi dis "percm15 = male percentage aged less than 15 years"
noi dis "perc15 = overall percentage aged less than 15 years"
noi tabdisp fifteen, by(year) c(percf15 percm15 perc15) format(%9.1f)


*******************************************************	
** B. OLDER ADULTS 	age_start1	(45+) 
*******************************************************	
** Proportion >=45 overall and by sex	
gen fortyfive = 0
replace fortyfive = 1 if age_start1 >=45 
bysort year fortyfive: egen totf45 = sum(popfemale)
bysort year fortyfive: egen totm45 = sum(popmale)
bysort year fortyfive: egen tot45 = sum(poptotal)
gen percf45 = (totf45 / totf)*100
gen percm45 = (totm45 / totm)*100
gen perc45 =  (tot45  / tot) *100

** Tabulate the statistics
egen tag45 = tag(fortyfive)
noi dis "" _newline(3)
noi dis "B. OLDER ADULTS. Aged 45+"
noi tabdisp fortyfive, by(year) c(percf45 percm45 perc45) format(%9.1f)

*******************************************************	
** C. ELDERLY 		age_start1	(70+) 
*******************************************************	
** Proportion >=70 overall and by sex	
gen seventy = 0
replace seventy = 1 if age_start1 >=70 
bysort year seventy: egen totf70 = sum(popfemale)
bysort year seventy: egen totm70 = sum(popmale)
bysort year seventy: egen tot70 = sum(poptotal)
gen percf70 = (totf70 / totf)*100
gen percm70 = (totm70 / totm)*100
gen perc70 =  (tot70  / tot) *100

** Tabulate the statistics
egen tag70 = tag(seventy)
noi dis "" _newline(3)
noi dis "C. ELDERLY. Aged 70+"
noi tabdisp seventy, by(year) c(percf70 percm70 perc70) format(%9.1f)

*******************************************************	
** D. WORKING AGE	age_start1	(15-64) 
*******************************************************	
** Proportion >=15 & <65 overall and by sex	
gen working1 = 0
replace working1 = 1 if age_start1>=15 & age_start1 <65 
bysort year working1: egen totfw1 = sum(popfemale)
bysort year working1: egen totmw1 = sum(popmale)
bysort year working1: egen totw1 = sum(poptotal)
gen percfw1 = (totfw1 / totf)*100
gen percmw1 = (totmw1 / totm)*100
gen percw1 =  (totw1  / tot) *100

** Tabulate the statistics
egen tagw1 = tag(working1)
noi dis "" _newline(3)
noi dis "D. WORKING AGE. Aged 15-64"
noi tabdisp working1, by(year) c(percfw1 percmw1 percw1) format(%9.1f)

*******************************************************	
** E. WORKING AGE	age_start1	(15-69)
*******************************************************	
** Proportion >=15 & <70 overall and by sex	
gen working2 = 0
replace working2 = 1 if age_start1>=15 & age_start1 <70 
bysort year working2: egen totfw2 = sum(popfemale)
bysort year working2: egen totmw2 = sum(popmale)
bysort year working2: egen totw2 = sum(poptotal)
gen percfw2 = (totfw2 / totf)*100
gen percmw2 = (totmw2 / totm)*100
gen percw2 =  (totw2  / tot) *100

** Tabulate the statistics
egen tagw2 = tag(working2)
noi dis "" _newline(3)
noi dis "E. WORKING AGE. Aged 15-69"
noi tabdisp working2, by(year) c(percfw2 percmw2 percw2) format(%9.1f)


*******************************************************	
** F. 65+
*******************************************************	
** Proportion >=65 overall and by sex	
gen sixtyfive = 0
replace sixtyfive = 1 if age_start1 >=65 
bysort year sixtyfive: egen totf65 = sum(popfemale)
bysort year sixtyfive: egen totm65 = sum(popmale)
bysort year sixtyfive: egen tot65 = sum(poptotal)
gen percf65 = (totf65 / totf)*100
gen percm65 = (totm65 / totm)*100
gen perc65 =  (tot65  / tot) *100


*******************************************************	
** G. AGED DEPENDENCY RATIO --> 65+/(15-64)
*******************************************************	


	keep if sixtyfive==1 & working2==1
	keep year totf65 totm65 tot65 totfw1 totmw1 totw1
	gen dratiof = (totf65/totfw1)*100
	gen dratiom = (totm65/totmw1)*100
	gen dratio = (tot65/totw1)*100

	** Tabulate the statistics
	noi dis "" _newline(3)
	noi dis "G. AGED DEPENDENCY RATIO. (65+/15-64)*100"
	noi tabdisp year, c(dratiof dratiom dratio) format(%9.1f)

restore


** GRAPHICS

** Proportion >=70 overall and by sex for graphics text	
bysort year: egen totf = sum(popfemale)
bysort year: egen totm = sum(popmale)
gen seventy = 0
replace seventy = 1 if age_start1 >=70 
bysort year seventy: egen totf70 = sum(popfemale)
bysort year seventy: egen totm70 = sum(popmale)
gen percf = (totf70 / totf)*100
gen percm = (totm70 / totm)*100

sort year age_start1


** ORIGINAL GRAPHICS CODE
	** twoway bar popmale age_start1, by(year) horizontal xvarlab(Males) barwidth(3) || bar  popfemale age_start1, by(year, legend(pos(5) )) horizontal xvarlab(Females) barwidth(3)  legend(label(1 Males) label(2 Females)) legend(order(1 2) cols(2) colgap(8) region(lstyle(none))  symysize(1) symxsize(1) size(2)) ytitle("Age", size(2)) xlabel(none) plotregion(style(none)) ysca(noline) xsca(noline) scheme(s1mono) ylabel(,angle(0) labsize(3)) xlabel( -2000 "2,000" -1000 "1,000" 0 "0" 2000 "2,000" 1000 "1,000"  , labsize(2))
	

** Color Scheme from ColorBrewer
** Five shades of Purple (Light to Dark)
** 242 240 247
** 203 201 226
** 158 154 200
** 117 107 177
** 84 39 143

** Five shades of blue (Light to Dark)
** 239 243 255
** 189 215 231
** 107 174 214
** 49 130 189
** 8 81 156



** ToDo
** Add text showing % over 70 by sex for each year
** Add shaded area to 70+ ??

** YEAR - further restriction
keep if year==1990 | year==2015
	
** FIGURE 1
** NEW GRAPHICS CODE 1
** SINGLE GRAPHIC using BY() CODE
	#delimit ;
		graph twoway 
		/// Men 65 years and younger
		(bar popmale age_start1 if age_start<=65, 	
									horizontal xvarlab(Males) 	
									barwidth(4.5) 
									by(year)
									fcolor("189 215 231") lc(gs10) lw(none)
									) 

		/// Men 70 years and older
		(bar popmale age_start1 if age_start>=	70, 	
									horizontal xvarlab(Males) 	
									barwidth(4.5) 
									by(year)
									fcolor("49 130 189") lc(gs10)
									) 									

		/// Women 65 years and younger
		(bar popfemale age_start1 if age_start<=65, 	
									horizontal xvarlab(Females) 
									barwidth(4.5) 
									by(year) 
									fcolor("203 201 226") lc(gs10) lw(none)
									)

		/// Women 70 years and older
		(bar popfemale age_start1 if age_start>=70, 	
									horizontal xvarlab(Females) 
									barwidth(4.5) 
									by(year, 
										plotregion(c(gs16) ic(gs16) ilw(thin) lw(thin)) 
										graphregion(c(gs16) ic(gs16) ilw(thin) lw(thin)) 
										legend(pos(6) ring(50) box region(lc(gs16) ilw(thin) lw(thin))) note("")) 
									fcolor("117 107 177") lc(gs10)
									),

		subtitle(, nobox size(4))
		///text(80  -1500 "percent 70+" , place(e)) 
		ysize(12) xsize(15)
		
		ytitle("Age in 5-year groups", size(2.5)) 
		yscale(noline) 			
		ylabel(none, angle(0) nogrid labsize(2.5)) 

		xtitle("Population size", size(2.5)) 
		xscale(noline) 
		xlabel( -1000 "1,000" 0 "0" 1000 "1,000" , labsize(2.5))
		
		legend(size(2.5) colf cols(2) colgap(8)
		region(fcolor(gs16) lw(none) margin(l=2 r=2 t=4 b=2)) order(2 1 4 3)
		label(1 "Males 69 and younger") 
		label(2 "Males 70 and older")
		label(3 "Females 69 and younger") 
		label(4 "Females 70 and older")
		) 
		;
#delimit cr		



}

