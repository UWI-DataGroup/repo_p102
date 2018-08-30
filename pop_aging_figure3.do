
******************************************
** Figure 3 Variation in Mortality Rate 
**			by Caribbean Country over 25 years. 
**			EquiPlot 
** Author: 	Ian Hambleton
** Date:  	Nov 5, 2017 
******************************************	

	capture log close
	log using figure3, replace
	clear all 
	set more off 
	version 15
	macro drop _all
	set more 1
	set linesize 80 
		
** 	Setting filepath and directory
	global filepath `""C:\Sync\statistics\analysis\a064\versions\version02\""'
	cd $filepath

	use "data\fig2_data", clear 
	
******************************************
** Figure 3   	(Caribbean region pyramid, 1990 and 2015)
**				Original Code
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


** ----------------------------------------------
** 19-NOV-2017
** ----------------------------------------------
** Ian Hambleton
** Cleaning and restricting the dataset
** ----------------------------------------------
	
** Keep deaths only
keep if measure=="Deaths"
drop measure

** Keep age-standardized rates
keep if age=="Age-standardized"
drop age

** Keep rate
keep if metric=="Rate"
drop metric

** Keep CVDdiabetes
keep if cause_name=="CVDdiabetes"
drop cause_name

** Country codes
replace country_name = "Bahamas" if country_name=="The Bahamas"
drop if country_name == "United States"

** Reshape before finding mininum and maximum values
*drop country_name
reshape wide val, i(country_name) j(year)




** Caribbean value
** gen mid = val5

** Minimum value (Good)
gen low  = 	min(val1990,val1991,val1992,val1993,val1994,val1995,val1996,val1997,val1998,val1999,		///
				val2000,val2001,val2002,val2003,val2004,val2005,val2006,val2007,val2008,val2009,		///
				val2010,val2011,val2012,val2013,val2014,val2015)

** Maximum value (Bad)
gen high  = max(val1990,val1991,val1992,val1993,val1994,val1995,val1996,val1997,val1998,val1999,		///
				val2000,val2001,val2002,val2003,val2004,val2005,val2006,val2007,val2008,val2009,		///
				val2010,val2011,val2012,val2013,val2014,val2015)

sort low					
egen ordernum3 = group(val2015) 
sort ordernum3

#delimit ;
label define orderlabel3 		1 "Puerto Rico" 
								2 "Cuba" 
								3 "Barbados" 
								4 "Caribbean" 
								5 "Antigua and Barbuda"
								6 "Dominican Republic" 
								7 "Bahamas" 
								8 "Dominica" 
								9 "Jamaica" 
								10 "St Lucia" 
								11 "USVI" 
								12 "Suriname" 
								13 "Belize"
								14 "Grenada" 
								15 "Trinidad and Tobago" 
								16 "St Vincent" 
								17 "Haiti" 
								18 "Guyana";
#delimit cr							
label values ordernum3 orderlabel3							
order country_name ordernum3

				
				
				
				
**keep if year==1990 | year==1995 | year==2000 | year==2005 | year==2010 | year==2015
**gen yaxis = 1 if year==1990
**replace yaxis = 1 if year==1990
**replace yaxis = 2 if year==1995
**replace yaxis = 3 if year==2000
**replace yaxis = 4 if year==2005
**replace yaxis = 5 if year==2010
**replace yaxis = 6 if year==2015

#delimit ;
	gr twoway 
		/// Line between min and max
		(rspike val2015 val1990 ordernum3, 		hor lc(gs8) lw(0.35))
		/// Minimum Mortality Rate
		(sc ordernum3 val2015 if ordernum!=4, 				msize(4.5) m(o) mlc(gs0) mfc("198 219 239") mlw(0.1))
		/// Maximum Mortality Rate
		(sc ordernum3 val1990 if ordernum!=4 , 			msize(4.5) m(o) mlc(gs0) mfc("8 81 156") mlw(0.1))
		/// Caribbean Rate
		(sc ordernum3 val2015 if ordernum==4, 				msize(4.5) m(o) mlc(gs0) mfc("252 174 145") mlw(0.1))
		(sc ordernum3 val1990 if ordernum==4 , 			msize(4.5) m(o) mlc(gs0) mfc("165 15 21") mlw(0.1))
		,
			plotregion(c(gs16) ic(gs16) ilw(thin) lw(thin)) 
			graphregion(c(gs16) ic(gs16) ilw(thin) lw(thin)) 		
			ysize(16) xsize(10)

			xlab(200(200)800, labs(3.5) tlc(gs0) labc(gs0) nogrid glc(gs16))
			xscale(fill range(200(100)900) lc(gs0)) 
			xtitle("", size(3.5) color(gs0) margin(l=2 r=2 t=5 b=2)) 
			xmtick(200(100)900, tlc(gs0))
			
			ylab(1(1)18
					,
			valuelabel labc(gs0) labs(3.5) tstyle(major_notick) nogrid glc(gs16) angle(0) format(%9.0f))
			yscale(noline lw(vthin) reverse range(0.5(0.5)18.5)) 
				ytitle("", size(3.5) margin(l=2 r=5 t=2 b=2)) 
			
			legend(size(3.5) position(6) ring(1) nobox colf cols(1)
			region(fcolor(gs16) lw(none) margin(l=2 r=2 t=2 b=2)) 
			order(2 3 4 5) 
			lab(2 "2015 mortality rate") 
			lab(3 "1990 mortality rate") 		
			lab(4 "2015 Caribbean") 		
			lab(5 "1990 Caribbean") 		
			);
#delimit cr	












	
/*	
	twoway line val year if measure =="Deaths" & metric =="Rate" & age =="Age-standardized" & cause_name=="CVDdiabetes" , ytitle("Mortality Rate") xtitle("Years", margin(top))  yscale(range(200(200)800)) ylabel(#5) connect(ascending) lcolor(black) || line val year if measure =="Deaths" & metric =="Rate" & age =="Age-standardized" & cause_name=="CVDdiabetes" & country_name =="Caribbean", lwidth(vthick) lcolor(black) || line val year if measure =="Deaths" & metric =="Rate" & age =="Age-standardized" & cause_name=="CVDdiabetes" & country_name =="United States", lwidth(vthick) lpattern(dash_dot) lcolor (black) legend(label( 1 "Caribbean Countries") label (2 "Caribbean Region") label( 3 "United States") cols(1) region(lstyle(none))) ylabel(,angle(0))
	graph export "Graphs\Figure 3.png", replace
	