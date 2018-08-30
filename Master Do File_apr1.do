** Author: Miriam Alvarado
** Date: April 1, 2017 
** Purpose: To test running all do-files to replicate pop aging results 


		clear all 
		set more off 
		set maxvar 10000
		
	** 	Setting filepath and directory
		global filepath `""C:\Users\miria\Google Drive\Health Disparities CDRC\CD007\Tables and Figures\Replication Files\""'
		
		cd $filepath
		

	** Generating all Figures/Tables: 
	
	** Code to prep reference population and to establish order for countries throughout analysis
		do "Code\Data Prep 1_apr1.do"
		
	** Code to prep IHME death draw data 
		do "Code\Data Prep 2_apr1.do"
		
	** Code to create Figure of population pyramids 
		do "Code\Figure 1_nov1.do"
		
	** Code to create Figure of population pyramids by country 
		do "Code\Figure 2_nov1.do"
		
	** Code to generate Fig 3 and Fig 5- 
		do "Code\Figure 3 _mar30.do"
		
	** Code to generate Fig 4 &  decomposition table 2
		do "Code\Figure 4_mar30.do"
		
	** Measure of 70+ proportion Table 
		do "Code\Table 1_mar30.do"
		
	** Code to generate CVD/diabetes deaths as a percent of total deaths by country
		do "Code\Appendix Table 1_marc30.do"
		
	** Code to generate migration 
		do "Code\Appendix Table 3_mar30.do"
		
