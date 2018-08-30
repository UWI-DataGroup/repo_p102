
******************************************
** Figure 3 Contribution of 
**				Population Growth
**				Population Aging 
**				Epidemiological Change
**			To change in number of deaths over 25 years
**
** Author: 	Ian Hambleton
** Date:  	Nov 5, 2017 
******************************************	

	capture log close
	log using figure4, replace
	clear all 
	set more off 
	version 15
	macro drop _all
	set more 1
	set linesize 80 
		
** 	Setting filepath and directory
	global filepath `""C:\Sync\statistics\analysis\a064\versions\version02\""'
	cd $filepath

		use "data\fig4_data", clear

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
		
		#delimit ;
		label define orderlabel 	14 "Grenada" 
									13 "Barbados" 
									12 "Guyana" 
									11 "Haiti" 
									10 "Cuba" 
									9 "Antigua & Barbuda" 
									8 "St Vincent" 
									7 "Trinidad & Tobago" 
									6 "St Lucia" 
									5 "Jamaica" 
									4 "Suriname" 
									3 "Belize" 
									2 "Bahamas" 
									1 "Dominican Republic" , replace; 
		#delimit cr
		label values y1 orderlabel
		
		** for graphing black line at zero. 
		gen realzero=0
		
		** graphing code 
		set scheme s1color  
		
		
		#delimit ;
		
		graph twoway 
			///epi change
			(rbar zero graphepi y1, 	horizontal barwidth(.75)  lc(gs0) lw(0.05) fc("204 235 197")) 
			/// Change in Population Size
			(rbar basepop addage y1 , 	horizontal barwidth(.75)  lc(gs0) lw(0.05) fc("254 217 166")) 
			/// Change in Population Age
			(rbar addage addpop y1 , 	horizontal barwidth(.75)  lc(gs0) lw(0.05) fc("255 255 204")) 
			/// Vertical Zero Line
			(line y1 realzero, lcolor(gs10) lp(l) lc(gs0%25)) 
			/// Overall Change point
			(scatter y1 med_deaths, msymbol(O) mcolor(black) msize(medlarge))
			,

			plotregion(c(gs16) ic(gs16) ilw(thin) lw(thin)) 
			graphregion(c(gs16) ic(gs16) ilw(thin) lw(thin))
			ysize(15) xsize(12.5)
		
			xlabel(-1 "-100%" -.5 "-50%" 0 "0" .5 "50%" 1 "100%" 1.5 "150%" 2 "200%", labsize(2))
			
			ylabel(1(1)14, notick valuelabel angle(0) labsize(3)) 
			ytitle("") xtitle("Percent Change in Deaths, 1990-2015",margin(top)) 
			yscale(noline)
			
			legend( order(5 1 2 3)
			label(3 Percent change driven by changes in population size) 
			label(2 Percent change driven by changes in age structure) 
			label(1 Percent change driven by changes in age-standardized mortality rates)  
			label(5 "Percent change in deaths from 1990-2015") 
			cols(1) size(2) symysize(2) symxsize(3)
			) 
			legend(region(lcolor(none))
			)  
			;
#delimit cr



		
		/*
		
		
		** table code 
		gen sort =_n
		gsort - sort 
		keep country_name med_epi lower_epi upper_epi med_aging lower_aging upper_aging med_popgrowth lower_popgrowth upper_popgrowth med_deaths lower_deaths upper_deaths
		
		outsheet using "Results/Table 2.csv", comma replace 
		save "Interim results/Table 2 Stata format.dta", replace 
