


******************************************
** Figure 2 Country-level population pyramids in 1990 and 2015, 
**			with % change over 25 years 
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
	global filepath `""X:\The University of the West Indies\DataGroup - repo_data\data_p102\version01\2-working\""'
	cd $filepath

	capture log close
	log using country_metrics, replace
	
	use "fig2_data", clear 

	collapse (sum) pop, by(year country_name iso3 age_start1 sex)
**	 keep if iso3=="BRB" & year==2015
**	collapse (sum) pop, by(sex)

** reshaping wide by population 
	reshape wide pop, i(country_name year iso3 age_start1 ) j(sex) string 
	levelsof country_name, local (countries)
	levelsof year, local(years)
	gen zero = 0
	replace popmale = popmale*(-1)
	bysort country_name year: egen test = min(popmale)
	replace test = test-3
	keep if year==1990 | year==1995 | year==2000 | year==2005 | year==2010 | year==2015 
	bysort country_name: egen popmax =max(popfemale)
	**replace popfemale =popfemale/popmax
	**replace popmale =popmale/popmax
	
	** Population as a percentage of total population
	bysort country_name year: egen fpop =sum(popfemale)
	bysort country_name year: egen mpop =sum(popmale)
	gen fpop_pc = (popfemale/fpop)*100
	gen mpop_pc = (popmale/mpop)*100
		
	merge m:1 country_name using "key" 
	drop order 

	sort country_name year
	egen ordernum2 = group(country_name year)

/*

*******************************************************	
** 31-JAN-2018
** ADDITIONAL METRICS FOR REGION
** NEED TO COMMENT OUT THESE ADDITIONAL METRICS
** FOR GRAPHICS PORTION OF ALGORITHM TO RUN
*******************************************************	
** A. CHILDREN 		age_start1	(0-4, 5-9, 10-14 yrs)
** B. OLDER ADULTS 	age_start1	(45+) 
** C. ELDERLY 		age_start1	(70+) 
** D. WORKING AGE	age_start1	(15-64) also do (15-69)
** E. AGED DEPENDENCY RATIO --> 65+/(15to64)
*******************************************************	

keep country_name iso3 year age_start1 popfemale popmale 
order country_name iso3 year age_start1 popfemale popmale 

** TOTAL POP OVERALL AND BY SEX
replace popmale = popmale*-1
bysort country_name year: egen totf = sum(popfemale)
bysort country_name year: egen totm = sum(popmale)
gen poptotal = popfemale + popmale
bysort country_name year: egen tot = sum(poptotal)

*******************************************************	
** A. CHILDREN 		age_start1	(0-4, 5-9, 10-14 yrs)
*******************************************************	
** Proportion <15 overall and by sex	
gen fifteen = 0
replace fifteen = 1 if age_start1 <15 
bysort country_name  year fifteen: egen totf15 = sum(popfemale)
bysort country_name  year fifteen: egen totm15 = sum(popmale)
bysort country_name  year fifteen: egen tot15 = sum(poptotal)
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
noi tabdisp fifteen, by(country_name  year) c(percf15 percm15 perc15) format(%9.1f)


*******************************************************	
** B. OLDER ADULTS 	age_start1	(45+) 
*******************************************************	
** Proportion >=45 overall and by sex	
gen fortyfive = 0
replace fortyfive = 1 if age_start1 >=45 
bysort country_name year fortyfive: egen totf45 = sum(popfemale)
bysort country_name year fortyfive: egen totm45 = sum(popmale)
bysort country_name year fortyfive: egen tot45 = sum(poptotal)
gen percf45 = (totf45 / totf)*100
gen percm45 = (totm45 / totm)*100
gen perc45 =  (tot45  / tot) *100

** Tabulate the statistics
egen tag45 = tag(fortyfive)
noi dis "" _newline(3)
noi dis "B. OLDER ADULTS. Aged 45+"
noi tabdisp fortyfive, by(country_name year) c(percf45 percm45 perc45) format(%9.1f)

*******************************************************	
** C. ELDERLY 		age_start1	(70+) 
*******************************************************	
** Proportion >=70 overall and by sex	
gen seventy = 0
replace seventy = 1 if age_start1 >=70 
bysort country_name year seventy: egen totf70 = sum(popfemale)
bysort country_name year seventy: egen totm70 = sum(popmale)
bysort country_name year seventy: egen tot70 = sum(poptotal)
gen percf70 = (totf70 / totf)*100
gen percm70 = (totm70 / totm)*100
gen perc70 =  (tot70  / tot) *100

** Tabulate the statistics
egen tag70 = tag(seventy)
noi dis "" _newline(3)
noi dis "C. ELDERLY. Aged 70+"
noi tabdisp seventy, by(country_name year) c(percf70 percm70 perc70) format(%9.1f)

** INEQUALITY MEASURES for ELDERLY
preserve
	keep if age_start1==70
	** MAD and ID --> 70+
	keep country_name year perc70 
	rename perc70 ps
	reshape wide ps, i(country_name) j(year)

	** Calculate ID for each 5-year time period
	foreach var in ps1990 ps1995 ps2000 ps2005 ps2010 ps2015 {
		gen J =  _N-1
		** Best rate in given year group
		egen rref = max(`var')
		** Absolute difference between (group mean age) and (reference mean age)
		gen rdiff = abs(`var' - rref)
		** Sum the differences
		egen rsum = sum(rdiff)
		** NB: THIS IS THE MEAN ABSOLUTE DEVIATION
		gen md_`var' = ( (rsum / J))
	
		** Index of Disparity
		gen id_`var' = ( (rsum / J) / rref) * 100
		format id_`var' %9.4f
		drop J rref rdiff  rsum 
		}

	keep if _n==1
	gen rid=1
	keep rid md_ps* id_ps*
	order rid md_ps* id_ps*
	reshape long md_ps id_ps, i(rid) j(year)
	noi dis "" _newline(3)
	noi dis "MD and ID for PERCENTAGE 70+"
	noi dis "MD = mean absolute deviation (md_ps, absolute measure of inequality)"
	noi dis "ID = index of disparity (id_s, relative measure of inequality)"
	noi tabdisp year , c(md_ps id_ps) format(%9.1f)
restore


*******************************************************	
** D. WORKING AGE	age_start1	(15-64) 
*******************************************************	
** Proportion >=15 & <65 overall and by sex	
gen working1 = 0
replace working1 = 1 if age_start1>=15 & age_start1 <65 
bysort country_name year working1: egen totfw1 = sum(popfemale)
bysort country_name year working1: egen totmw1 = sum(popmale)
bysort country_name year working1: egen totw1 = sum(poptotal)
gen percfw1 = (totfw1 / totf)*100
gen percmw1 = (totmw1 / totm)*100
gen percw1 =  (totw1  / tot) *100

** Tabulate the statistics
egen tagw1 = tag(working1)
noi dis "" _newline(3)
noi dis "D. WORKING AGE. Aged 15-64"
noi tabdisp working1, by(country_name year) c(percfw1 percmw1 percw1) format(%9.1f)

*******************************************************	
** E. WORKING AGE	age_start1	(15-69)
*******************************************************	
** Proportion >=15 & <70 overall and by sex	
gen working2 = 0
replace working2 = 1 if age_start1>=15 & age_start1 <70 
bysort country_name year working2: egen totfw2 = sum(popfemale)
bysort country_name year working2: egen totmw2 = sum(popmale)
bysort country_name year working2: egen totw2 = sum(poptotal)
gen percfw2 = (totfw2 / totf)*100
gen percmw2 = (totmw2 / totm)*100
gen percw2 =  (totw2  / tot) *100

** Tabulate the statistics
egen tagw2 = tag(working2)
noi dis "" _newline(3)
noi dis "E. WORKING AGE. Aged 15-69"
noi tabdisp working2, by(country_name year) c(percfw2 percmw2 percw2) format(%9.1f)


*******************************************************	
** F. 65+
*******************************************************	
** Proportion >=65 overall and by sex	
gen sixtyfive = 0
replace sixtyfive = 1 if age_start1 >=65 
bysort country_name year sixtyfive: egen totf65 = sum(popfemale)
bysort country_name year sixtyfive: egen totm65 = sum(popmale)
bysort country_name year sixtyfive: egen tot65 = sum(poptotal)
gen percf65 = (totf65 / totf)*100
gen percm65 = (totm65 / totm)*100
gen perc65 =  (tot65  / tot) *100


** SORT ORDER
sort country_name year age_start1

**keep if iso3=="BRB" & year==2015
keep country_name year sixtyfive working1 totf65 totm65 tot65 totfw1 totmw1 totw1

*******************************************************	
** G. AGED DEPENDENCY RATIO --> 65+/(15-64)
*******************************************************	
** Only keep the two rows we need
gen keep1 = 0
replace keep1 = 1 if working1==1 & working1[_n+1]==0
gen keep2 = 0
replace keep2 = 1 if sixtyfive==1 & sixtyfive[_n-1]==0
keep if keep1==1 | keep2==1

collapse 	(max) 	totfw1_max=totfw1 	///
					totmw1_max=totmw1 	///
					totw1_max=totw1 	///
			(min)	totf65_max=totf65	///
					totm65_max=totm65	///
					tot65_max=tot65 , by(country_name year)

gen dratiof = (totf65/totfw1)*100
gen dratiom = (totm65/totmw1)*100
gen dratio = (tot65/totw1)*100

** Tabulate the statistics
noi dis "" _newline(3)
noi dis "G. AGED DEPENDENCY RATIO. (65+/15-64)*100"
noi tabdisp year , by(country_name) c(dratiof dratiom dratio) format(%9.1f)



** INEQUALITY MEASURES for DEPENDENCY RATIO

** MAD and ID --> Dependency ratio
preserve
	keep country_name year dratio 
	rename dratio dr
	reshape wide dr, i(country_name) j(year)

	** Calculate ID for each 5-year time period
	foreach var in dr1990 dr1995 dr2000 dr2005 dr2010 dr2015 {
		gen J =  _N-1
		** Best rate in given year group
		egen rref = max(`var')
		** Absolute difference between (group mean age) and (reference mean age)
		gen rdiff = abs(`var' - rref)
		** Sum the differences
		egen rsum = sum(rdiff)
		** NB: THIS IS THE MEAN ABSOLUTE DEVIATION
		gen md_`var' = ( (rsum / J))

		** Index of Disparity
		gen id_`var' = ( (rsum / J) / rref) * 100
		format id_`var' %9.4f
		drop J rref rdiff  rsum 
	}

	keep if _n==1
	gen rid=1
	keep rid md_dr* id_dr*
	order rid md_dr* id_dr*
	reshape long md_dr id_dr, i(rid) j(year)
	noi dis "" _newline(3)
	noi dis "MD and ID for AGED DEPENDENCY RATIO"
	noi dis "MD = mean absolute deviation (md_dr, absolute measure of inequality)"
	noi dis "ID = index of disparity (id_dr, relative measure of inequality)"
	noi tabdisp year , c(md_dr id_dr) format(%9.1f)
	
restore

*/

*******************************************************	
** 31-JAN-2018
** END OF 
** ADDITIONAL METRICS FOR REGION
** START HERE FOR GRAPHICAL CALCULATIONS
** NEED TO COMMENT OUT THESE ADDITIONAL METRICS
** FOR GRAPHICS PORTION OF ALGORITHM TO RUN
*******************************************************	



		
******************************************5 "
** MANUALLY CHECK LABEL ORDER 
******************************************
**label define orderlabel 1 "Belize" 2 "Guyana" 3 "Haiti" 4 "Dominican Republic" 5 "Suriname" 6 "SVG" 7 "Grenada" 8 "Antigua and Barbuda" 9 "Bahamas" 10 "Trinidad and Tobago" 11 "Saint Lucia" 12 "Jamaica" 13 "Aruba" 14 "Barbados" 15 "Curacao" 16 "Cuba" 17 "Puerto Rico" 18 "Guadeloupe" 19 "USVI" 20 "Martinique"
**label values ordernum orderlabel
	

	#delimit ;
	label define orderlabel2 	1 "Antigua and Barbuda" 2 "Antigua and Barbuda" 
								3 "Aruba" 4 "Aruba"
								5 "Bahamas" 6 "Bahamas"
								7 "Barbados" 8 "Barbados"
								9 "Belize" 10 "Belize"
								11 "Cuba" 12 "Cuba"
								13 "Curacao" 14 "Curacao"
								15 "Dominican Republic" 16 "Dominican Republic"
								17 "Grenada" 18 "Grenada"
								19 "Guadeloupe" 20 "Guadeloupe"
								21 "Guyana" 22 "Guyana"
								23 "Haiti" 24 "Haiti"
								25 "Jamaica" 26 "Jamaica"
								27 "Martinique" 28 "Martinique"
								29 "Puerto Rico" 30 "Puerto Rico"
								31 "St Vincent" 32 "St Vincent"
								33 "St Lucia" 34 "St Lucia"
								35 "Suriname" 36 "Suriname"
								37 "Trinidad and Tobago" 38 "Trinidad and Tobago"
								39 "USVI" 40 "USVI";
	#delimit cr							
	label values ordernum2 orderlabel2							
	


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



** ADDITIONAL METRICS BY COUNTRY
** A. CHILDREN 		age_start1	(0-4, 5-9, 10-14 yrs)
** B. OLDER ADULTS 	age_start1	(45+) 
** C. ELDERLY 		age_start1	(70+) 
** D. WORKING AGE	age_start1	(15-64) also do (15-69)
** E. RATIO OF 		(WORKING AGE : ELDERLY)
** F. MAD 			absolute inequality metric for each year
** G. ID			relative inequality metric for each year


** THREE GRAPHS PER COUNTRY - TO COMBINE INTO SINGLE ROW

** **************************************************************
** GRAPH A and GRAPH B for each country
** POP PYRAMID in 1990 and 2015 for 20 countries
** Unique graphs identified by -ordernum2- (1 to 40)
** **************************************************************

forval x = 1(1)40 {
	#delimit ;
		graph twoway 
		/// Men 
		(bar popmale age_start1 if ordernum2==`x', 	
									horizontal xvarlab(Males) 	
									barwidth(4.5) 
									fcolor("49 130 189") lc(gs10) lw(none)
									) 
		/// Women
		(bar popfemale age_start1 if ordernum2==`x', 	
									horizontal xvarlab(Females) 
									barwidth(4.5) 
									fcolor("117 107 177") lc(gs10)
									),
		subtitle(, nobox size(4))
		ysize(15) xsize(15)

		plotregion(c(gs16) ic(gs16) ilw(thin) lw(thin)) 
		graphregion(c(gs16) ic(gs16) ilw(thin) lw(thin)) 
										
		ytitle("", size(2.5)) 
		yscale(noline) 			
		ylabel(none, angle(0) nogrid labsize(2.5)) 

		xtitle("", size(2.5)) 
		xscale(noline) 
		xlabel(-1(1)1 , nolab notick labsize(2.5))
		
		legend(off) 
		name(graph`x');
#delimit cr
}


** **************************************************************
** GRAPH C
** POP CHANGE FOR EACH COUNTRY
** Percentage point change (so absolute difference)
** **************************************************************

cap drop _merge test ordernum2
sort country_name year
egen ordernum3 = group(country_name)

#delimit ;
label define orderlabel3 	1 "Antigua and Barbuda" 
								2 "Aruba" 
								3 "Bahamas" 
								4 "Barbados" 
								5 "Belize" 
								6 "Cuba" 
								7 "Curacao" 
								8 "Dominican Republic" 
								9 "Grenada" 
								10 "Guadeloupe" 
								11 "Guyana" 
								12 "Haiti" 
								13 "Jamaica" 
								14 "Martinique" 
								15 "Puerto Rico"
								16 "St Vincent" 
								17 "St Lucia" 
								18 "Suriname" 
								19 "Trinidad and Tobago" 
								20 "USVI";
#delimit cr							
label values ordernum3 orderlabel3	
** Percentage point change 1990 --> 2015	
reshape wide popfemale fpop fpop_pc popmale mpop mpop_pc , i(ordernum3 age_start1) j(year)
gen fdiff = fpop_pc2015 - fpop_pc1990
gen mdiff = mpop_pc2015 - mpop_pc1990
gen diff = fdiff + mdiff

forval x = 1(1)20 {
	#delimit ;
		graph twoway 

		/// <70 YRS 
		(bar diff age_start1 if age_start1<70 & ordernum3==`x', 	
									horizontal xvarlab(Males) 	
									barwidth(4.5) 
									fcolor(gs10) lc(gs10) lw(none)
									)

		///>=70 YRS
		(bar diff age_start1 if age_start1>=70 & ordernum3==`x', 	
									horizontal xvarlab(Males) 	
									barwidth(4.5) 
									fcolor(red*0.75) lc(red*0.75) lw(none)
									),

		subtitle(, nobox size(4))
		ysize(15) xsize(15)

		plotregion(c(gs16) ic(gs16) ilw(thin) lw(thin)) 
		graphregion(c(gs16) ic(gs16) ilw(thin) lw(thin)) 
										
		ytitle("", size(2.5)) 
		yscale(noline) 			
		ylabel(none, angle(0) nogrid labsize(2.5)) 

		xtitle("", size(2.5)) 
		xscale(noline range(-13(1)10)) 
		xlabel(-1(1)1 , nolab notick labsize(2.5))
		
		legend(off) 
		name(diff_graph`x')
		saving(Graphs\diff_graph`x', replace)
		;
#delimit cr
}


** COMBINE THE THREE GRAPHS (A, B, C) INTO SINGLE GRAPHIC PER COUNTRY

** ANTIGUA & BARBUDA
#delimit ;
	graph combine graph1 graph2 diff_graph1, 
		cols(3) 
		///title("Antigua and Barbuda", pos(9) size(7))
		plotregion(c(gs16) ic(gs16) ilw(thin) lw(thin)) 
		graphregion(c(gs16) ic(gs16) ilw(thin) lw(thin)) 		
		ysize(5) xsize(15)
		imargin(l=10 r=10)
		name(atg)
		saving(Graphs\atg, replace)
		;
#delimit cr


** ARUBA
#delimit ;
	graph combine graph3 graph4 diff_graph2, 
		cols(3) 
		///	title("Aruba", pos(9) size(7))
		plotregion(c(gs16) ic(gs16) ilw(thin) lw(thin)) 
		graphregion(c(gs16) ic(gs16) ilw(thin) lw(thin)) 		
		ysize(5) xsize(15)
		imargin(l=10 r=10)
		name(abw)
		saving(Graphs\abw, replace)
		;
#delimit cr

** BAHAMAS
#delimit ;
	graph combine graph5 graph6 diff_graph3, 
		cols(3) 
		///title("The Bahamas", pos(9) size(7))
		plotregion(c(gs16) ic(gs16) ilw(thin) lw(thin)) 
		graphregion(c(gs16) ic(gs16) ilw(thin) lw(thin)) 		
		ysize(5) xsize(15)
		imargin(l=10 r=10)
		name(bhs)
		saving(Graphs\bhs, replace)
		;
#delimit cr

** BARBADOS
#delimit ;
	graph combine graph7 graph8 diff_graph4, 
		cols(3) 
		///title("Barbados", pos(11) size(7))
		plotregion(c(gs16) ic(gs16) ilw(thin) lw(thin)) 
		graphregion(c(gs16) ic(gs16) ilw(thin) lw(thin)) 		
		ysize(5) xsize(15)
		imargin(l=10 r=10)
		name(brb)
		saving(Graphs\brb, replace)
		;
#delimit cr

** BELIZE
#delimit ;
	graph combine graph9 graph10 diff_graph5, 
		cols(3) 
		///title("Belize", pos(11) size(7))
		plotregion(c(gs16) ic(gs16) ilw(thin) lw(thin)) 
		graphregion(c(gs16) ic(gs16) ilw(thin) lw(thin)) 		
		ysize(5) xsize(15)
		imargin(l=10 r=10)
		name(blz)
		saving(Graphs\blz, replace)
		;
#delimit cr

** CUBA
#delimit ;
	graph combine graph11 graph12 diff_graph6, 
		cols(3) 
		///title("Cuba", pos(11) size(7))
		plotregion(c(gs16) ic(gs16) ilw(thin) lw(thin)) 
		graphregion(c(gs16) ic(gs16) ilw(thin) lw(thin)) 		
		ysize(5) xsize(15)
		imargin(l=10 r=10)
		name(cub)
		saving(Graphs\cub, replace)
		;
#delimit cr


** CURACAO
#delimit ;
	graph combine graph13 graph14 diff_graph7, 
		cols(3) 
		///title("Curacao", pos(11) size(7))
		plotregion(c(gs16) ic(gs16) ilw(thin) lw(thin)) 
		graphregion(c(gs16) ic(gs16) ilw(thin) lw(thin)) 		
		ysize(5) xsize(15)
		imargin(l=10 r=10)
		name(cur)
		saving(Graphs\cur, replace)
		;
#delimit cr


** DOMINICAN REPUBLIC
#delimit ;
	graph combine graph15 graph16 diff_graph8, 
		cols(3) 
		///title("Dominican Republic", pos(11) size(7))
		plotregion(c(gs16) ic(gs16) ilw(thin) lw(thin)) 
		graphregion(c(gs16) ic(gs16) ilw(thin) lw(thin)) 		
		ysize(5) xsize(15)
		imargin(l=10 r=10)
		name(dom)
		saving(Graphs\dom, replace)
		;
#delimit cr

** GRENADA
#delimit ;
	graph combine graph17 graph18 diff_graph9, 
		cols(3) 
		///title("Grenada", pos(11) size(7))
		plotregion(c(gs16) ic(gs16) ilw(thin) lw(thin)) 
		graphregion(c(gs16) ic(gs16) ilw(thin) lw(thin)) 		
		ysize(5) xsize(15)
		imargin(l=10 r=10)
		name(grd)
		saving(Graphs\grd, replace)
		;
#delimit cr


** GUADELOUPE
#delimit ;
	graph combine graph19 graph20 diff_graph10, 
		cols(3) 
		///title("Guadeloupe", pos(11) size(7))
		plotregion(c(gs16) ic(gs16) ilw(thin) lw(thin)) 
		graphregion(c(gs16) ic(gs16) ilw(thin) lw(thin)) 		
		ysize(5) xsize(15)
		imargin(l=10 r=10)
		name(glp)
		saving(Graphs\glp, replace)
		;
#delimit cr

** GUYANA
#delimit ;
	graph combine graph21 graph22 diff_graph11, 
		cols(3) 
		///title("Guyana", pos(11) size(7))
		plotregion(c(gs16) ic(gs16) ilw(thin) lw(thin)) 
		graphregion(c(gs16) ic(gs16) ilw(thin) lw(thin)) 		
		ysize(5) xsize(15)
		imargin(l=10 r=10)
		name(guy)
		saving(Graphs\guy, replace)
		;
#delimit cr

** HAITI
#delimit ;
	graph combine graph23 graph24 diff_graph12, 
		cols(3) 
		///title("Haiti", pos(11) size(7))
		plotregion(c(gs16) ic(gs16) ilw(thin) lw(thin)) 
		graphregion(c(gs16) ic(gs16) ilw(thin) lw(thin)) 		
		ysize(5) xsize(15)
		imargin(l=10 r=10)
		name(hti)
		saving(Graphs\hti, replace)
		;
#delimit cr

** JAMAICA
#delimit ;
	graph combine graph25 graph26 diff_graph13, 
		cols(3) 
		///title("Jamaica", pos(11) size(7))
		plotregion(c(gs16) ic(gs16) ilw(thin) lw(thin)) 
		graphregion(c(gs16) ic(gs16) ilw(thin) lw(thin)) 		
		ysize(5) xsize(15)
		imargin(l=10 r=10)
		name(jam)
		saving(Graphs\jam, replace)
		;
#delimit cr

** MARTINIQUE
#delimit ;
	graph combine graph27 graph28 diff_graph14, 
		cols(3) 
		///title("Martinique", pos(11) size(7))
		plotregion(c(gs16) ic(gs16) ilw(thin) lw(thin)) 
		graphregion(c(gs16) ic(gs16) ilw(thin) lw(thin)) 		
		ysize(5) xsize(15)
		imargin(l=10 r=10)
		name(mtq)
		saving(Graphs\mtq, replace)
		;
#delimit cr

** PUERTO RICO
#delimit ;
	graph combine graph29 graph30 diff_graph15, 
		cols(3) 
		///title("Puerto Rico", pos(11) size(7))
		plotregion(c(gs16) ic(gs16) ilw(thin) lw(thin)) 
		graphregion(c(gs16) ic(gs16) ilw(thin) lw(thin)) 		
		ysize(5) xsize(15)
		imargin(l=10 r=10)
		name(pri)
		saving(Graphs\pri, replace)
		;
#delimit cr

** ST VINCENT
#delimit ;
	graph combine graph31 graph32 diff_graph16, 
		cols(3) 
		///title("St Vincent and the Grenadines", pos(11) size(7))
		plotregion(c(gs16) ic(gs16) ilw(thin) lw(thin)) 
		graphregion(c(gs16) ic(gs16) ilw(thin) lw(thin)) 		
		ysize(5) xsize(15)
		imargin(l=10 r=10)
		name(vct)
		saving(Graphs\vct, replace)
		;
#delimit cr

** ST LUCIA
#delimit ;
	graph combine graph33 graph34 diff_graph17, 
		cols(3) 
		///title("St Lucia", pos(11) size(7))
		plotregion(c(gs16) ic(gs16) ilw(thin) lw(thin)) 
		graphregion(c(gs16) ic(gs16) ilw(thin) lw(thin)) 		
		ysize(5) xsize(15)
		imargin(l=10 r=10)
		name(lca)
		saving(Graphs\lca, replace)
		;
#delimit cr

** SURINAME
#delimit ;
	graph combine graph35 graph36 diff_graph18, 
		cols(3) 
		///title("Suriname", pos(11) size(7))
		plotregion(c(gs16) ic(gs16) ilw(thin) lw(thin)) 
		graphregion(c(gs16) ic(gs16) ilw(thin) lw(thin)) 		
		ysize(5) xsize(15)
		imargin(l=10 r=10)
		name(sur)
		saving(Graphs\sur, replace)
		;
#delimit cr


** TRINIDAD
#delimit ;
	graph combine graph37 graph38 diff_graph18, 
		cols(3) 
		///title("Trinidad and Tobago", pos(11) size(7))
		plotregion(c(gs16) ic(gs16) ilw(thin) lw(thin)) 
		graphregion(c(gs16) ic(gs16) ilw(thin) lw(thin)) 		
		ysize(5) xsize(15)
		imargin(l=10 r=10)
		name(tto)
		saving(Graphs\tto, replace)
		;
#delimit cr


** USVI
#delimit ;
	graph combine graph39 graph40 diff_graph20, 
		cols(3) 
		///title("United States Virgin Islands", pos(11) size(7))
		plotregion(c(gs16) ic(gs16) ilw(thin) lw(thin)) 
		graphregion(c(gs16) ic(gs16) ilw(thin) lw(thin)) 		
		ysize(5) xsize(15)
		imargin(l=10 r=10)
		name(vir)
		saving(Graphs\vir, replace)
		;
#delimit cr







** SECOND COMBINATION - COMBINING COUNTRIES INTO SINGLE GRAPHIC
** We don't use this right now
#delimit ;
	graph combine 	"Graphs\atg" 
					"Graphs\abw"
					"Graphs\bhs"
					"Graphs\brb"
					"Graphs\blz"
					"Graphs\cub"
					"Graphs\cur"
					"Graphs\dom"
					"Graphs\grd"
					"Graphs\glp"
					"Graphs\guy"
					"Graphs\hti"
					"Graphs\jam"
					"Graphs\mtq"
					"Graphs\pri"
					"Graphs\vct"
					"Graphs\lca"
					"Graphs\sur"
					"Graphs\tto"
					"Graphs\vir"
					, 
		cols(2) 
		title("", pos(11) size(7))
		plotregion(c(gs16) ic(gs16) ilw(thin) lw(thin)) 
		graphregion(c(gs16) ic(gs16) ilw(thin) lw(thin)) 		
		ysize(15) xsize(11)
		imargin(l=0 r=0)
		iscale(*0.8)
		name(countries);
#delimit cr


** SECOND COMBINATION - COMBINING COUNTRIES INTO SINGLE GRAPHIC
** 1 country per row (OVER 3 PAGES)
** We don't use this right now

** Page 1
#delimit ;
	graph combine 	"Graphs\atg" 
					"Graphs\abw"
					"Graphs\bhs"
					"Graphs\brb"
					"Graphs\blz"
					"Graphs\cub"
					"Graphs\cur"

					, 
		cols(1) 
		title("", pos(11) size(7))
		plotregion(c(gs16) ic(gs16) ilw(thin) lw(thin)) 
		graphregion(c(gs16) ic(gs16) ilw(thin) lw(thin)) 		
		ysize(15) xsize(7.5)
		imargin(l=0 r=0)
		name(countries1);
#delimit cr

** Page 2
#delimit ;
	graph combine 	"Graphs\dom"
					"Graphs\grd"
					"Graphs\glp"
					"Graphs\guy"
					"Graphs\hti"
					"Graphs\jam"
					"Graphs\mtq"
					, 
		cols(1) 
		title("", pos(11) size(7))
		plotregion(c(gs16) ic(gs16) ilw(thin) lw(thin)) 
		graphregion(c(gs16) ic(gs16) ilw(thin) lw(thin)) 		
		ysize(15) xsize(7.5)
		imargin(l=0 r=0)
		name(countries2);
#delimit cr

** Page 3
#delimit ;
	graph combine 	"Graphs\pri"
					"Graphs\lca"
					"Graphs\vct"
					"Graphs\sur"
					"Graphs\tto"
					"Graphs\vir"
					, 
		cols(1) 
		title("", pos(11) size(7))
		plotregion(c(gs16) ic(gs16) ilw(thin) lw(thin)) 
		graphregion(c(gs16) ic(gs16) ilw(thin) lw(thin)) 		
		ysize(15) xsize(5)
		imargin(l=0 r=0)
		name(countries3);
#delimit cr

