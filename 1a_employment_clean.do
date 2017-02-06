
capture log close
clear all
set more off

*MAKE EMPLOYMENT DATA						

*******  Make Employment Data and Constuct key outcome variables  *******
**********************
*******  EMPA  *******
**********************
use "P:\pop\BANGLADESH_PROJECT\MHSS2\Master Data\20160107_public\b3_empa.dta", clear

set more off
*** Bring in cover information
mmerge vill_id hhold_id line_no using "P:\pop\BANGLADESH_PROJECT\MHSS2\Analysis Files\Data\Migrant\b3_cover.dta", ukeep(districtother exrate)
	drop if _merge==2
	drop _merge

*** Clean up variables
	recode empa00 3=0
	recode empa01 3=0
	
	**Recode -ve to missing
	foreach var of varlist  empa00 empa01 empa02weeks empa02hours  empa03  empa04loc1  empa04loc2 empa04ruralurban empa05loc1 empa05loc2 empa05ruralurban {
		replace `var' = . if `var'==-8
		replace `var' = . if `var'==-7
	}
	
	sum empa00 empa01 empa02weeks empa02hours empa03 empa04loc1 empa04loc2 empa04ruralurban empa05loc1 empa05loc2 empa05ruralurban
	
*** Adjust phone survey earnings information
	** Look at the quantity and units variables
	tab empa03_qty empa03_units if phone_survey == 1 & empa03!=., m // Does this mean that empa03 is not in an annual amount?
	
	** Keep original earnings if needed
	gen empa03_phone = empa03 if phone_survey == 1
	
	lab var empa03_phone "12 Months Earnings (Forex) from Phone Survey"
	
	** Convert to annual
	replace empa03 = empa03 * empa03_qty if phone_survey == 1 & inlist(empa03_units,1,2,3)
	
	** Check to see if the country code is the same as the country code from the cover
	gen fl_ea_phone_ctry = 0 			if phone_survey == 1 & empa03_ctrycd!=.
		replace fl_ea_phone_ctry = 1 	if phone_survey == 1 & empa03_ctrycd == districtother
		tab fl_ea_phone_ctry 			if phone_survey == 1, m  	//274 activites with ctry cd which doesn't match the cover. How to handle the exrate?
		
		li 	empa03_ctrycd districtother if fl_ea_phone_ctry == 0
		tab districtother empa03_ctrycd if fl_ea_phone_ctry == 0 // 273 cases where the empa03 country code == 50 (BD) - no conversion needed
		
		* Check Ctry name of the mismatch
		li vill_id empa03_ctry empa03_ctrycd districtother if fl_ea_phone_ctry == 0 & empa03_ctrycd!=50 // Country name missing
			// 450 (Madagascar) vs 458 (Malaysia)... the districtother matches the vill_id (458) //
			
			// HARD CODE - country code for this person //
			replace fl_ea_phone_ctry = 1 if fl_ea_phone_ctry==0 & empa03_ctrycd!=50
	
	** Create file which has all of the country/year 
	preserve
		replace empa03_ctry = trim(empa03_ctry)
		drop if empa03_ctrycd == .
		
		collapse (first) empa03_ctry, by(empa03_ctrycd)
		
		// export excel using "C:\Users\phill\Box Sync\migrant followup\MHSS\2_data\employment\2014_forex_rates.dta", firstrow(var) replace
	restore
	
	** Merge in file with historical exchange rates
	mmerge districtother using "P:\pop\BANGLADESH_PROJECT\MHSS2\Analysis Files\Data\Migrant\2014_forex_rates.dta", ///
		missing(nomatch) ukeep(average) umatch(empa03_ctrycd)
		drop if _merge == 2 | _merge == -2
		drop _merge
		
		rename average exrate2
		
		replace exrate2 = . if phone_survey !=1
		
	** Convert from foreign currency to Taka if a match was made
		//Note: exrate is foreign country currency per Taka so need to divide by exrate
		//BUT They are all greater than 1 so really need to multiply
		
		* Check the exrate
		tab fl_ea_phone_ctry
		sum exrate if fl_ea_phone_ctry == 1, d // obs match and no missings (-7,-8)
		
		* Conversion Here
		gen 	empa03b	= empa03 
		
		replace empa03 	= empa03  * exrate  if fl_ea_phone_ctry == 1
		replace empa03b = empa03b * exrate2 if fl_ea_phone_ctry == 1
	
	** Compare exrate and exrate2
	gen		exrate_diff = (exrate2-exrate)/exrate * 100 // Percent difference from stated value
	
	sum exrate_diff if fl_ea_phone_ctry == 1
	
	
	** Look at countries that are off by more than 5% in either direction.
	preserve
		sort exrate_diff
		li exrate exrate2 exrate_diff empa03_ctry empa03_ctrycd districtother if fl_ea_phone_ctry == 1 & (exrate_diff >=5 | exrate_diff<=-5)
		count if fl_ea_phone_ctry == 1 & (exrate_diff >=5 | exrate_diff<=-5)
		count if fl_ea_phone_ctry == 1
	restore
	
*** Check basic data	
	
	** Check Each Variable
	* Weeks
	tab empa02weeks // 2 Cases with greater than 52 (set to missing) - 54 and 57 weeks 
	sum empa02weeks if empa01 == 0 // 1 case filled in when not supposed to
	
	gen 	empa02weeks_cl 	= empa02weeks
	replace empa02weeks_cl 	= . 			if empa02weeks > 52
	
	** CHECK WITH TANIA ON THIS (if not in that sector, set weeks to 0)
	replace empa02weeks_cl 	= 0				if empa01 == 0 & empa02weeks_cl == .
	
	* Hours 
	tab empa02hours // No cases above 168
	sum empa02hours if empa01 == 0 // 1 case filled in when not supposed to
	
	gen 	empa02hours_cl 	= empa02hours
	replace empa02hours_cl 	= 0				if empa01 == 0 & empa02hours_cl == .
	
	gen		empa_hrs_tot  	= empa02weeks_cl * empa02hours_cl
	
	* Earnings
	sum empa03
	sum empa03 if empa01==0 // No cases filled in
	
	gen 	empa03_cl	   	= empa03
	replace empa03_cl	   	= 0				if empa01 == 0 & empa03_cl == .
	
	gen 	empa03b_cl	   	= empa03b
	replace empa03b_cl	   	= 0				if empa01 == 0 & empa03b_cl == .
	
	* Location CodeS
	tab empa04loc1 empa01,m
	tab empa04loc2 empa01,m
	tab empa04ruralurban empa01,m
	
	gen 	empa04loc1_cl 	= empa04loc1
	replace	empa04loc1_cl	= 1				if empa01 == 0 & empa04loc1 == .
	
	tab empa04loc1_cl empa01 if empa00==0,m
	
	tab empa05loc1 
	tab empa05loc2 
	tab empa05ruralurban
	
	* Activity Code
	tab item_emp_activity
	
	* Earnings
	sum empa03_cl, d
	sum empa03b_cl, d
	sum empa01-item_emp_activity
	sum empa01-item_emp_activity if empa01==1
		
***Make primary and secondary job sectors to check with empb and total number of sectors works in
	
	bys vill_id hhold_id line_no phone_survey: egen empa_sec_sal_rank=rank(empa03) 				/*ranks all jobs by employment with lowest starting at 1*/
	bys vill_id hhold_id line_no phone_survey: egen empa_sec_sal_rankmax=max(empa_sec_sal_rank) /*Total number of secotors worked*/
	bys vill_id hhold_id line_no phone_survey: gen  empa_sec_prim=item_emp_activity if empa_sec_sal_rank==empa_sec_sal_rankmax & empa_sec_sal_rankmax~=.
	bys vill_id hhold_id line_no phone_survey: gen  empa_sec_second=item_emp_activity if (empa_sec_sal_rank==empa_sec_sal_rankmax-1) & (empa_sec_sal_rankmax>1 & empa_sec_sal_rankmax~=.)
	bys vill_id hhold_id line_no phone_survey: egen empa_totalsec=total(empa01)
	
	lab var empa_totalsec "Total number of sectors worked in"
	
	**Check for ties as rank does not break ties - some entries where the salaries are exactly the same - 46 are non-zero salary ties
		*Primary sector
		bys vill_id hhold_id line_no phone_survey: egen empa_prim_number=count(empa_sec_prim)
		lab var empa_prim_number "Number of primary jobs, this is 2 if there is a salary tie for highest paying job"
	
		tab empa_prim_number
		tab empa_prim_number if empa03~=0 & empa_sec_prim==item_emp_activity
	
		l empa03  empa_sec_sal_rank empa_sec_prim empa_sec_second empa_prim_number if empa03~=0 & empa_sec_prim==item_emp_activity & empa_prim_number>1 , sepby(vill_id hhold_id line_no phone_survey)
	
		*Secondary sector - no ties for primary sector
		bys vill_id hhold_id line_no phone_survey: egen empa_second_number=count(empa_sec_second)
		lab var empa_second_number "Number of secondary jobs, this is 2 if there is a salary time for highest paying job"

		tab empa_second_number
		tab empa_second_number if empa03~=0 & empa_sec_second==item_emp_activity
		
		*Make primary and secondary variable that is constant across sectors for reshaping, need to make 2 primary sector variables
		bys vill_id hhold_id line_no phone_survey: egen empa_prim_act1=min(empa_sec_prim)
		bys vill_id hhold_id line_no phone_survey: egen empa_prim_act2=max(empa_sec_prim) if empa_prim_number==2
		bys vill_id hhold_id line_no phone_survey: egen empa_second_act1=min(empa_sec_second)
		
		lab var empa_prim_act1		"Item code of first primary activity"
		lab var empa_prim_act2 		"Item code of second primary activity, only for salary ties, empa_prim_number==2"
		lab var empa_second_act1 	"Item code of secondary activity, note need to adjust for prim_act2"

		*Drop interm variables
		drop empa_sec_sal_rankmax empa_sec_sal_rank empa_sec_prim empa_sec_second
	
*** Reshape the file
	drop fl_ea_phone_ctry

	order vill_id hhold_id line_no phone_survey use_books ///
		  empa_totalsec empa_prim_act1 empa_prim_act2 empa_prim_number ///
		  empa_second_act1 empa_second_number empa00 item_emp_activity ///
		  item_emp_activity_other item_emp_activity_other_eng empa01 empa02weeks empa02weeks_cl ///
		  empa02hours empa02hours_cl empa_hrs_tot empa03 empa03b empa03_cl empa03b_cl ///
		  empa03_ctrycd empa03_ctry empa03_units empa03_qty empa03_phone ///
		  empa04loc1 empa04loc1_cl empa04loc2 empa04ruralurban empa05loc1 empa05loc2 empa05ruralurban 
		  
// item_emp_activity HAS 609 MISSING VALUES. DROPPING FOR NOW
drop if item_emp_activity == .
		
	reshape wide item_emp_activity_other-empa04_ctry, i(vill_id hhold_id line_no phone_survey) j(item_emp_activity)
	order vill_id hhold_id line_no phone_survey use_books ///
		  districtother exrate exrate2 exrate_diff ///
		  empa_totalsec empa_prim_act1 empa_prim_act2 empa_prim_number  empa_second_act1 empa_second_number empa00  
	drop item_emp_activity_other1 item_emp_activity_other2 item_emp_activity_other3 item_emp_activity_other4 item_emp_activity_other5 item_emp_activity_other6 item_emp_activity_other7

***	Make totals for all sectors
	**Hours and Wages
	egen 	empa01 			= rowmax(empa01*) // This will be missing for any that is missing all activites
	
	gen 	flag_ea_partial = 0
	replace flag_ea_partial = 1 if empa01!=. & (empa011==. | empa012==. | empa013==. | empa014==. | empa015==. | empa016==. | empa017==. | empa018==.)
	
	tab flag_ea_partial // 2 Partial cases
	
	sum empa01* line_no 			 // 16 people missing from empa01 (these are refusals and proxies
	sum empa01* line_no if empa00==0 // 3 people missing (these are the refusals and missing verified from Mitra
	
	egen 	empa_inc_tot	= rowtotal(empa03_cl?)
	replace empa_inc_tot	= . 					if empa01==.
	
	egen 	empa_inc_totb	= rowtotal(empa03b_cl?)
	replace empa_inc_totb	= . 					if empa01==.
	
		** Fix earnigns for household businesses to share among all participants in HH
		forvalues i=1(1)8 {
			gen empa03HH_cl`i' = empa03_cl`i'
		}
		foreach i in 4 7 8 {
			bys vill_id hhold_id: egen empa03_cl`i'_hhtot = total(empa03_cl`i')
			bys vill_id hhold_id: egen empa01`i'_hhtot = total(empa01`i')
			replace empa03HH_cl`i' = empa03_cl`i'_hhtot / empa01`i'_hhtot if empa01`i' == 1 
		}
	
	egen	empa_inc_totHH	= rowtotal(empa03HH_cl?)
	replace empa_inc_totHH	= . 					if empa01==.
	
	egen		empa_inc_totNFarm = rowtotal(empa03_cl1 empa03_cl2 empa03_cl3 empa03_cl4 empa03_cl5 empa03_cl6 empa03_cl8)
	replace empa_inc_totNFarm = .						if empa01 == .
	
	egen 	empa_inc_totNFam = rowtotal(empa03_cl1 empa03_cl2 empa03_cl3 empa03_cl5 empa03_cl6)
	replace empa_inc_totNFam = . if empa01==.

	egen 	empa_hrs_tot	= rowtotal(empa_hrs_tot*)
	replace empa_hrs_tot	= .							if empa01==.
	
	gen 	empa_hrs_tot_wk	= empa_hrs_tot/52.17			/*We can change this to 52 if we want */
	gen 	empa_wagehr		= empa_inc_tot/empa_hrs_tot
	
	sum empa_inc_tot empa_hrs_tot empa_hrs_tot_wk empa_wagehr line_no
	sum empa_inc_tot empa_hrs_tot empa_hrs_tot_wk empa_wagehr line_no if empa00==0
	// Wage is missing for half since many people have hours==0 (can't divide by 0)
	
	lab var empa01 			"=1 if worked in any sector"
	lab var empa_inc_tot	"Total earned across all sectors sum empa03*"
	lab var empa_inc_totb	"Total earned across all sectors sum empa03* (external forex rate)"
	lab var empa_hrs_tot 	"Total number of hours worked in all sectors sum empa_hrs_tot*"
	lab var	empa_hrs_tot_wk "Total number of hours works in all sectors per week empa_hrs_tot/52.17"
	lab var empa_wagehr		"wage earned per hour: empa_inc_tot/empa_hrs_tot"
	
*** Check if total hours worked over all sectors
	sum empa_hrs_tot_wk, d
	
	count if empa_hrs_tot_wk>120 /*30 cases - could send back to Mitra to check hours and months */
	count if empa_hrs_tot_wk>152 /* 6 */
	
	sum empa_inc_tot, d		
	sum empa_wagehr, d
	
tempfile empa
save `empa'

**********************
*******  EMPB  *******
**********************
use  "P:\pop\BANGLADESH_PROJECT\MHSS2\Master Data\20160107_public\b3_empb.dta", clear

set more off
order vill_id hhold_id line_no phone_survey use_books itemno 


*** Reshape wide to get information on first and secondary job
	reshape wide empb01-empb15other_eng, i(vill_id hhold_id line_no phone_survey) j(itemno)
	drop use_books
	
*** Sum all variables to check fo -ve values
	sum empb041-empb152
	
	tab empb10hours1 if empb021==3 & (empb10hours1 < 0 | empb10hours1 == .),m
	
	foreach var of varlist empb041-empb151 empb042-empb152{
		replace `var' =. if `var'==-8 
		replace `var' =. if `var'==-7 
		replace `var' =. if `var'==-6 
	}
	
	* Check empb03
	tab empb031,m
	tab empb031 if empb021==3,m // only 1 missing
	
	* Check empb04-empb06
	sum empb041-empb06class1 line_no
	sum empb041-empb06class1 line_no if inlist(empb031,1,2,8) & empb021==3
	
	* Check empb07-empb10
	sum empb071-empb10hours1 line_no
	sum empb071-empb10hours1 line_no if empb021==3
	
	*** DO THESE NEED TO BE FILLED IN?
	count if empb10hours1==. & empb021==3 // 8 cases (these were missing in data and not -6,-7,-8, see above)
	
	
*** Tab remaining non-continuous variables and check that codes are in range
	
	foreach var of varlist empb041-empb10a1 empb131-empb151 empb042-empb10a2 empb132-empb152 {
		tab `var', nol m
	}	
	
*** Check Taka amounts
	sum empb111, d
	sum empb112, d
	sum empb121, d
	sum empb122, d
	
*** Check Number of observations same with empa
	sum empb011-empb031
	
*** Merge on empa so will be able to check primary and secondary status
	mmerge vill_id hhold_id line_no phone_survey using `empa'
		// tab _merge phoney_survey												/* 4 observations that are only in the using data */
		l vill_id hhold_id line_no phone_survey empa* if _merge==2
	
	gen empa_book = (_merge == 1 | _merge == 3)
	gen empb_book = (_merge == 2 | _merge == 3)
	
	tab empb031
	tab empb032
	tab empb031 empa01, m
	
*** Make conversion for phone survey earnings (phone survey only has Main so don't need to worry about Secondary)
	tab empb11_ctry1
	
	gen fl_eb_phone_ctry = 0 if phone_survey == 1 & empb11_ctry1!=.
		replace fl_eb_phone_ctry = 1 if phone_survey == 1 & empb11_ctry1==districtother
		
		tab empb11_ctry1 if fl_eb_phone_ctry == 0 // All cases where these are 0 they are in BD, except 1
		
		* Check case where ctry code is not BD and doesn't match cover
		li vill_id empb11_ctry1 districtother exrate if fl_eb_phone_ctry==0 & empb11_ctry1!=50 // 784 (UAE) vs 785 (not real)
		
		* HARD CODE fix - the one not in BD does have the correct ctry code so use exrate
		replace fl_eb_phone_ctry = 1 if fl_eb_phone_ctry==0 & empb11_ctry1!=50
		
		tab fl_eb_phone_ctry if phone_survey == 1
		
	** Convert from foreign currency to Taka if a match was made
		* Note: exrate is foreign country currency per Taka so need to divide by exrate
		* BUT!!! no exrate is less than 1, I think they did Taka per foreign currency, so multiply
		
		*Check the exrate
		sum exrate 		if fl_eb_phone_ctry == 1, d // obs match and no missings (-7,-8)
		sum empb111 	if fl_eb_phone_ctry == 1, d // 1 phone survey obs is missing empb11
		
		*Conversion Here
		replace empb111 = empb111 * exrate if fl_eb_phone_ctry == 1
	
***Make cleaned primary and secondary status variables so can make adjustment	
	gen empb031_cl	=empb031	
	gen empb032_cl	=empb032	
	gen empb10a1_cl	=empb10a1
	gen empb10a2_cl	=empb10a2	
	
***EMPB3 and 10 match
	**Total number of issues
	count if empb031~=empb10a1 /*604 are not matching, 599 are missing in emp10a1 (from phone survey), don't change variables just use emp031 */
	count if empb10a1==. & phone_survey==2
	count if empb10a1==. & phone_survey~=2 & empb031~=.
	
	tab empb031 empb10a1 if empb031~=empb10a1, m
	tab empb111 if inlist(empb031, 1,  2, 5, 6) & empb10a1==. , m	/*Note there are no missings so we are good here*/
	
	count if empb032~=empb10a2 /*2*/
	tab empb032 empb10a2 if empb032~=empb10a2, m
	tab empb112 if inlist(empb032, 1,  2, 5, 6) & empb10a2==. , m /*1 missing here*/

	*Replace those that look like typos
	count if empb10a1==empa_prim_act1 & empb031~=empb10a1
	l  empa_prim_act1 empa_second_act1 empb031 empb032 empb10a1 empb10a2 empb07* empb13* if empb10a1==empa_prim_act1 & empb031~=empb10a1, nol
	
	*!! HARD CODE, these are data entry typos
	replace empb031_cl=empa_prim_act1 if empb10a1==empa_prim_act1 & empb031~=empb10a1
		
	count if empb10a2==empa_second_act1 & empb032~=empb10a2
	l  empa_prim_act1 empa_second_act1 empb031 empb032 empb10a1 empb10a2 empb07* empb13* if empb10a2==empa_second_act1 & empb032~=empb10a2, nol
	
	*!! HARD CODE, these are data entry typos
	replace empb032_cl=empa_second_act1 if empb10a2==empa_second_act1 & empb032~=empb10a2
	
***	Change the EMPA primary and secondary codes so they match empb for tied cases from empa
	** Primary
	gen		empa_prim_act_cl	=empa_prim_act1 if empa_prim_number==1
	replace empa_prim_act_cl	=empa_prim_act1 if empa_prim_number==2 & empa_prim_act1==empb031
	replace empa_prim_act_cl	=empa_prim_act2 if empa_prim_number==2 & empa_prim_act2==empb031
	
	** Secondary
	gen 	empa_second_act_cl	=empa_second_act1
	replace empa_second_act_cl=empa_prim_act1 if empa_prim_number==2 & empa_prim_act1==empb032
	replace empa_second_act_cl=empa_prim_act2 if empa_prim_number==2 & empa_prim_act2==empb032
	
	tab 		empa_prim_act_cl 		empb031 if  empa_prim_number==2
	count if 	empa_prim_act_cl	~= 	empb031 &   empa_prim_number==2	/*1 that does not match */
	count if 	empa_second_act_cl	~= 	empb032 &   empa_prim_number==2
	
	** Missing in clean but not in originals - 1 person - code in empa is 4 and in empb is 3, change to empa
		count 	if empa_prim_act_cl==. & empa_prim_act1~=. & empa_prim_act2~=. & empa_prim_number==2
		l empa_prim_act_cl empa_prim_act1 empa_prim_act2 empa_second_act1 empb031 empb032 	///
				if empa_prim_act_cl==. & empa_prim_act1~=. & empa_prim_act2~=. & empa_prim_number==2
	
		gen flag_ch_emp_act_cl_miss = 1 if empa_prim_act_cl==. & empa_prim_act1~=. & empa_prim_act2~=. & empa_prim_number==2
	
	*!!Change HARD CODE:Looks like a typo in empb03 - will also need to change empb10
		replace empb031_cl			=empa_prim_act1  if  flag_ch_emp_act_cl_miss==1
		replace empa_prim_act_cl	=empa_prim_act1  if  flag_ch_emp_act_cl_miss==1
		replace empa_second_act_cl	=empa_prim_act2  if  flag_ch_emp_act_cl_miss==1
		
	gen flag_hardcode_b031	=1 if empa_prim_act_cl==. & empa_prim_act1~=. & empa_prim_act2~=. & empa_prim_number==2	
	
		
	l empa_prim_act_cl empa_prim_act1 empa_prim_act2 empa_second_act_cl empb031_cl empb031 empb032 if flag_ch_emp_act_cl_miss==1
	
*** NOTE NEED TO BE AWARE THAT EMPA WILL HAVE SECONDARY BUT NOT EMPB FOR PHONE SURVEY!

	count if empb031_cl==empa_prim_act_cl 
	count if empb031_cl~=empa_prim_act_cl	/*149 that don't match */
	
		tab empb031_cl empa_prim_act_cl if empb031_cl~=empa_prim_act_cl,m
	
	count if empb032_cl==empa_second_act_cl  
	count if empb032_cl~=empa_second_act_cl		/*1039 that don't match */
	
		tab empb032_cl empa_second_act_cl if empb032_cl~=empa_second_act_cl,m /* The majority come from missings in secondary job */
	
/****** Determine why EMPA and EMPB primary and secondary sector codes not the same *******/	

*** Check if empb031 | empb032 is missing - 1 person recode empb031
	**Primary Sector;
	count 	if empa_prim_act1~=empb031 & empa_prim_number==1 &  empb021==3 & empb031==. & empb071~=.	/*1 because empb031 is missing but 7 on is filled out*/
	l empa_prim_act1 empa_second_act1 empb031 empb032 empb111 empb112 if empa_prim_act1~=empb031 & empa_prim_number==1 &  empb021==3 & empb031==.
	
	*!!Change in empb031 here with empa - 1 change
	replace empb031_cl=empa_prim_act1 if empa_prim_act1~=empb031 & empa_prim_number==1 &  empb021==3 & empb031==.
		
	**Secondary Sector; *-- could send back to Mitra
	count if empa_second_act1~=empb032 & empa_prim_number==1 &  empb031~=. & empb032==. /* 4 */
	count if empa_second_act1~=empb032 & empa_prim_number==1 &  empb031~=. & empb032==. & empb072~=. /*1*/
	*browse if empa_second_act1~=empb032 & empa_prim_number==1 &  empb021==3 & empb032==. & empb072~=.
	
	replace empb032_cl=empa_second_act1 if empa_second_act1~=empb032 & empa_prim_number==1 &  empb021==3 & empb032==. & empb072~=.

*** Check if gave same sector codes in primary and secondary job
	count if empb031==empb032 & empb031~=.					/*904 obs were sector codes are the same */
	tab empa_second_act1 if empb031==empb032 & empb031~=., m
	
	count if empb031==empb032 & empb031~=. & empa_second_act_cl~=. /*46 owhere EMPA has a secondary sector so not matching */
	count if empb031==empb032 & empb031~=. & empa_second_act_cl==. /*857 where EMPA has no secondary sector*/
	
	gen flag_second_empamissing=1 if empb031==empb032 & empb031~=. & empa_second_act_cl==.
	lab var flag_second_empamissing "1 if secondary sector empb but not a, both jobs reporter in B were in same sector"

	count if empb032~=empa_second_act_cl & flag_second_empamissing==.	/*185 remaining where empa and empb secondary sector do not match*/

	*Check sectors and amounts person makes differs for these activities;
	tab empb031 if empb031==empb032 & empb031~=. 		/*700+ are in agriculture, could think about combining these*/
	

*** Check if codes don't match because they did not fill out EMPB03 because said yes to empb02;
	tab empb021 if  empa_prim_act_cl~=empb031  /* 19 people said had not main activity, but 8 reported some income */
	tab empb022 if  empa_prim_act_cl~=empb031  /* 0 people */	
	
	tab empb021 if  empa_second_act_cl~=empb032  /*0 people here */
	tab empb022 if  empa_second_act_cl~=empb032  /* 0 people */	

	tab empb021 if  	empa_prim_act_cl~=empb031 & empa_prim_number==1 & (empa_inc_tot==0 | empa_inc_tot==.) 	/*11 people had no income and said they had no main sector*/
	tab empa_inc_tot if empa_prim_act_cl~=empb031 & empa_prim_number==1 & (empa_inc_tot>0  | empa_inc_tot~=.) & empb021==1

	gen flag_lostB02=1 if  empa_prim_act1~=empb031 & (empb021==1 | empb021==.) 	/* 20 */
	lab var flag_lostB02 "1 if primary and secondary not matching empA and B becuase emp02==1 or missing so didn't do section "
	tab flag_lostB02
	
	*!!Note: 20 - but 11 of 141 account for here that may make sense because had zero income, 8 folks who made income so a mistake was made with these ones
	*!!Note: DX0 0033 1 is missing EMPB all together may want to send this back to see why

*** Check if empa primary and secondary sector information is missing - 14 BUT NOT 1 EXTRA IN HERE NEED TO SORT OUT
	gen flag_empaPrim_missing=1  if empa_prim_act1==. & empb031~=. & flag_second_empamissing==. & flag_lostB02==. & flag_hardcode_b031==.
	
	tab empa_prim_act_cl empb031 if flag_second_empamissing==. & flag_lostB02==. & flag_hardcode_b031==.,m /*15 which have no empa_prim_act_cl */
	tab empa_prim_act1   empb031 if flag_second_empamissing==. & flag_lostB02==. & flag_hardcode_b031==.,m
		
		
*** Check if numbers for those with and without ties in empa
	tab empa_prim_number if empb031~=empa_prim_act_cl   & flag_second_empamissing~=1 & flag_lostB02==. & flag_hardcode_b031==. &  flag_empaPrim_missing==.		/*136 no ties */
	tab empa_prim_number if empb032~=empa_second_act_cl & flag_second_empamissing~=1 & flag_lostB02==. & flag_hardcode_b031==. &  flag_empaPrim_missing==.		/*180 no ties */
	
*** See 3 and 4 flipped in EMPB
	** Check how many other observations have this problem
	count if  empa_prim_act1==3 & empb031==4 & empb032==.
	l empa_prim_act* empa_second_act* empb031 empb032  if   empa_prim_act1==3 & empb031==4 & empb032==.
	tab empb10a1 if  empa_prim_act1==3 & empb031==4 & empb032==., nol
	
	
	*!!HARD CODE: Change in empb031 here with empa - 1 change
	gen flag_empAB_hardcode=1 if empb031==4 & empa_prim_act1==3 & empb032==.
	
	replace empb031_cl=3 if   empb031==4 & empa_prim_act1==3 & empb032==.
	replace empb10a1_cl=3 if  empb031==4 & empa_prim_act1==3 & empb032==. 

*** Flags for those who remain not to match
	gen flag_prim_nomatch=1 	if empb031_cl~=empa_prim_act_cl   & flag_second_empamissing~=1  & flag_lostB02==. & flag_empaPrim_missing==. & flag_empAB_hardcode==.
	gen flag_second_nomatch=1 	if empb032_cl~=empa_second_act_cl & flag_second_empamissing~=1	& flag_lostB02==. & flag_empaPrim_missing==. & flag_empAB_hardcode==.

	*Count remaing problesm by ties in primary sector in empa
		tab flag_prim_nomatch empa_prim_number, m		/*120 problems, none with empa ties */
		tab flag_second_nomatch empa_prim_number, m		/*180 problems, none with empa ties */
		
*** Check if primary and secondary jobs may be flipped -- 106
	tab empa_prim_act1 empb031 if flag_prim_nomatch~=1
	count if empa_prim_act_cl==empb032_cl & empa_second_act_cl==empb031 	& flag_prim_nomatch==1  /*106*/
	count if empa_prim_act_cl==empb032_cl & empa_second_act_cl==empb031 	& flag_second_nomatch==1 /*106*/	 
	
	*Check if there is a empb secondary sector for those whose primary sector was not correct,and were paid more weekly in secondary sector IN EMPB - 34
	count if empa_second_act1==empb031 & empa_prim_act1~=empb031 & flag_prim_nomatch==1  & ((empb112>empb111 & empb112~=.) | (empb111==. & (empb112>0 & empb112~=.))) /*34*/
	count if empa_prim_act1==empb032 & empa_second_act1~=empb032 & flag_prim_nomatch==1 & ((empb112>empb111 & empb112~=.) | (empb111==. & (empb112>0 & empb112~=.))) /*35*/
	count if empa_prim_act1==empb032 & empa_second_act1~=empb032 & empa_second_act1==empb031 & empa_prim_act1~=empb031 & flag_prim_nomatch==1 & ((empb112>empb111 & empb112~=.) | (empb111==. & (empb112>0 & empb112~=.))) /*34*/
	
	gen flag_reverse=1 if empa_prim_act1==empb032 & empa_second_act1~=empb032 & empa_second_act1==empb031 & empa_prim_act1~=empb031 & flag_prim_nomatch==1 & ((empb112>empb111 & empb112~=.) | (empb111==. & (empb112>0 & empb112~=.))) /*35*/

	l empa_prim_act1 empa_second_act1 empb031 empb032 empb111 empb112   if flag_reverse==1 
				
		*!!NEED TO REVERSE PRIMARY AND SECONDARY IN EMPB FOR ALL THESE OBSERVATIONS; 
		replace empb031_cl=empb032 	if flag_reverse==1
		replace empb032_cl=empb031	if flag_reverse==1

		*Count how many of these are sector 1 and 2
		tab empb031 empb032 if flag_reverse==1 // 7 Cases are missed in C because their incorect main occupation was not 1/2
		
	
	*Count number for which there is no weekly income for the primary or secondary in empb
	*Have positive income in empa - 34
	
	count if empa_second_act1==empb031 & empa_prim_act1==empb032 & flag_prim_nomatch==1 & ((empb111==.|empb111==0) & (empb112==.|  empb112==0)) & (empa_inc_tot>0 & empa_inc_tot~=.) 

	gen flag_reverse_noinc=1 if empa_second_act1==empb031 & empa_prim_act1==empb032 & flag_prim_nomatch==1 & ((empb111==.|empb111==0) & (empb112==.|  empb112==0)) & (empa_inc_tot>0 & empa_inc_tot~=.) 
	tab flag_reverse flag_reverse_noinc, m
	
	
	*Have no income in empa - no observations here
		count if flag_reverse_noinc==1 & (empa_inc_tot==0 | empa_inc_tot==.)  /*None where empa income is zero*/
	
	
		*!!NEED TO REVERSE PRIMARY AND SECONDARY IN EMPB FOR ALL THESE OBSERVATIONS; 
		replace empb031_cl=empb032 	if flag_reverse_noinc==1
		replace empb032_cl=empb031	if flag_reverse_noinc==1
 
	*Examine remaining problems
		*Number remaining with reverse primary and secondary - 38
		count if empa_second_act1==empb031 & empa_prim_act1==empb032 & empa_prim_act1~=empb031 & empa_second_act1~=empb032 & flag_prim_nomatch==1 &  flag_reverse==. & flag_reverse_noinc==.

		l empa_prim_act1 empa_second_act1  empb111 empb112 empb10hours1 empa03*  if empa_second_act1==empb031 & empa_prim_act1==empb032 & empa_prim_act1~=empb031 & empa_second_act1~=empb032 & flag_prim_nomatch==1 &  flag_reverse==. & flag_reverse_noinc==.
		
		*Of remaining 38, 36 of them there is no income for the empb secondary jobs so looks like put in primary or secondary based on empb income not empa income, other 2 higher income for empb prim than secondary 
		count if empa_second_act1==empb031 & empa_prim_act1==empb032 & empa_prim_act1~=empb031 & empa_second_act1~=empb032 & flag_prim_nomatch==1 &  flag_reverse==. & flag_reverse_noinc==. & empb031~=. & empb111~=. & empb112==.

	*!Need to decide what to do with these, the primary and secondary sector is based of empb NOT empa
	
		gen 	flag_reverse_EMPB =1 if empa_second_act1==empb031 & empa_prim_act1==empb032 & empa_prim_act1~=empb031 & empa_second_act1~=empb032 & flag_prim_nomatch==1 &  flag_reverse==. & flag_reverse_noinc==. & empb031~=. & empb111~=. & empb112==.
		lab var flag_reverse_EMPB "1 if primary and secondary sector based off empB not empA and the real primary sector had no income past week"
	
	*Remaining ones that are reversed
		count if empa_prim_act_cl==empb032_cl & empa_second_act_cl==empb031 & flag_prim_nomatch==1 & flag_reverse_EMPB==. & flag_reverse_noinc==. & flag_reverse==.
		l empa_prim_act1 empa_second_act1 empb031 empb032 empb111 empb112 empa_inc_tot if empa_prim_act_cl==empb032_cl & empa_second_act_cl==empb031 & flag_prim_nomatch==1 & flag_reverse_EMPB==. & flag_reverse_noinc==. & flag_reverse==.
		gen flag_other_reverse=1 if empa_prim_act_cl==empb032_cl & empa_second_act_cl==empb031 & flag_prim_nomatch==1 & flag_reverse_EMPB==. & flag_reverse_noinc==. & flag_reverse==.
	
***Check remaining issues with primary sector that are not due to reveral of prim and secondary
	count if flag_prim_nomatch==1   &  flag_reverse==. & flag_reverse_noinc==. & flag_reverse_EMPB==. & flag_other_reverse /*16*/ 
	count if flag_second_nomatch==1 &  flag_reverse==. & flag_reverse_noinc==. & flag_reverse_EMPB==. & flag_other_reverse /*76*/
	
	l empa_prim_act1 empa_second_act1 empb031 empb032 empb111 empb112 empa_inc_tot  if flag_prim_nomatch==1 &  flag_reverse==. & flag_reverse_noinc==. & flag_reverse_EMPB==.
	l empa_prim_act1 empa_second_act1 empb031 empb032 empb111 empb112 empa_inc_tot empb10a1 empb10a2  if flag_second_nomatch==1 &  flag_reverse==. & flag_reverse_noinc==. & flag_reverse_EMPB==., nol
	
	
	*Secondary jobs, number which have missing wages, and sectors same in prim and secondary - 38
		count if empb031==empb032 & empb111==. & empb112==. & flag_second_nomatch==1		/* 38 */
		
		*See how many the primary job matched
		count if empa_prim_act1==empb031 & empb031==empb032 & empb111==. & empb112==. & flag_second_nomatch==1	/* 38 */
	
		*!Need to decide what to do with these
		gen flag_secon_repeatprim=1	 if empa_prim_act1==empb031 & empb031==empb032 & empb111==. & empb112==. & flag_second_nomatch==1
	
order vill_id hhold_id line_no phone_survey use_books ///
	empa_totalsec empa_prim_act1 empa_prim_act2 empa_prim_act_cl empa_prim_number empa_second_act1 empa_second_number empa_second_act_cl ///
	empa* item_emp_activity_other8 ///
	empb031_cl empb032_cl empb10a1_cl empb10a2_cl empb* flag* 
  
tempfile empb
save `empb'

**********************
*******  EMPC  *******
**********************
use  "P:\pop\BANGLADESH_PROJECT\MHSS2\Master Data\20160107_public\b3_empc.dta", clear
	
	set more off
	drop use_books
	
*** Determine number people should answer questions
	gen empc_respondent=1 if empc00==3 & empc01==1
	lab var empc_respondent "=1 should answer this section if empc00==3 & empc01==1"

*** Sum all variables to check fo -ve values
	sum empc_respondent empc00-empc13
	sum empc_respondent empc00-empc13 if empc_respondent==1
	
	foreach var of varlist empc00-empc13 {
		replace `var' =. if `var'==-8 
		replace `var' =. if `var'==-7 
	}
	
	sum empc00-empc13
	
*** Tab remaining non-continuous variables and check that codes are in range;
	foreach var of varlist empc00-empc06 empc08a-empc13  {
		tab `var', nol m
	}	
	
*** Check Taka amounts
	sum empc07a, d
	sum empc07b, d
	sum empc10, d
	
*** Check skips
	tab empc03 empc04, m 	/*64 filled out that did not need to be (could change to yes could be typos, 1 missing */
	tab empc08a empc08b, m	/*0 filled out that did not need to be, 1 missing */
	tab empc12 empc13, m	/*13 filled out that did not need to be, 0 missing */

tempfile empc
save `empc'

**********************
*******  EMPD  *******
**********************
use  "P:\pop\BANGLADESH_PROJECT\MHSS2\Master Data\20160107_public\b3_empd.dta", clear
	set more off
	*** Sum all variables to check fo -ve values
	sum empd04b-empd06 empd07line-empd15 empd16-empd19f empd20a-empd20g empd20h empd21a empd21b empd23 empd24-empd27
	
	foreach var of varlist  empd04b-empd06 empd07line-empd15 empd16-empd19f empd20a-empd20g empd20h empd21a empd21b empd23 empd24-empd27{
		replace `var' =. if `var'==-8 
		replace `var' =. if `var'==-7 
		replace `var' =. if `var'==-6 
	}	
	sum empd04b-empd06 empd07line-empd15 empd16-empd19f empd20a-empd20g empd20h empd21a empd21b empd23 empd24-empd27
	
	*** Tab non-continuous variables and check that codes are in range
	foreach var of varlist	empd01 empd02a empd05 empd05a empd05b empd06 empd07line empd07a empd09 ///
							empd10a empd10b empd11 empd12 empd13 empd15 empd18 empd19? empd20? empd27 {
		disp "`var'"
		tab `var', nol m
	}
	
	*** Reshape wide to get information on first and secondary job
	reshape wide empd04a-empd27, i(vill_id hhold_id line_no phone_survey) j(businesstype)
	drop use_books
	
*** Determine number people should answer questions
	gen empd_respondent=1 if empd01c==1 | empd01d==1 | empd01g==1
	lab var empd_respondent "=1 should answer this section if empd01c==1 | empd01d==1 | empd01g==1"
	
	gen empd_respondent1=1 if empd_respondent==1
	gen empd_respondent2=1 if empd_respondent==1 & empd02>1 & empd02!=.
	
	* See how this compare to empd01
	tab empd01 empd_respondent,m
	
	li vill_id hhold_id line_no empd_respondent empd01 empd01? if empd01==1 & empd_respondent==.
	li vill_id hhold_id line_no empd_respondent empd01 empd01? if empd01==3 & empd_respondent==1
	li vill_id hhold_id line_no empd_respondent empd01 empd01? if empd01==. & empd_respondent==1
	li vill_id hhold_id line_no empd_respondent empd01 empd01? if empd01==. & empd_respondent==.

	
	
	
*** Check Taka amounts
	sum empd21a1, d
	sum empd21b1, d
	sum empd231, d
	sum empd241, d
	sum empd251, d
	sum empd261, d
	
	sum empd21a2, d
	sum empd21b2, d
	sum empd232, d
	sum empd242, d
	sum empd252, d
	sum empd262, d
	
	
*** Check skips
	tab empd051 empd05a1, m
	tab empd10a1 empd10b1, m
	tab empd181 empd19a1, m

tempfile empd
save `empd'

**********************
*******  EMPE  *******
**********************
use  "P:\pop\BANGLADESH_PROJECT\MHSS2\Master Data\20160107_public\b3_empe.dta", clear

	set more off
	des, full
	tab empe00 empe01, m		/* 9 people missed answering proxy but empe01 info there, 12 people answered that didn't need to */


***Check sample size for all variables;
	gen 		empe_answer02=1 if empe02a==1 | empe02b==1 | empe02c==1 | empe02d==1 | empe02e==1 | empe02f==1 | empe02g==1 | empe02h==1
	
	egen 		empe02_tot=rowtotal(empe02a empe02b empe02c empe02d empe02e empe02f empe02g empe02h)
	lab var 	empe02_tot "Number of jobs worked, rowtotal empe2a-empe2h"
	
	sum empe_answer02 empe01-empe07ru if empe01==1
	tab empe03,m // Need to trim the phone survey cases
	replace empe03 = trim(empe03)
	
	count 	if empe03~="" & empe_answer02 ==.
	l 		if empe03~="" & empe_answer02 == .	/*looks like empe02 is missing and can be filled in with empe03*/
	
	**!! HARD CODE - Fix three cases from above
	replace empe02a = 1 if empe03=="A" & empe02a==. & empe_answer02==.
	replace empe02c = 1 if empe03=="C" & empe02c==. & empe_answer02==.
	
	* Some people report job information but have empe01==0
	gen 	empe01_cl = empe01
	replace empe01_cl = 1 		if empe02_tot>0 & empe02_tot!=. & empe03!=""
	li empe01 empe01_cl empe05* empe06 phone_survey if empe01!=empe01_cl
	
	* Set the No to 0
	replace empe01_cl = 0 		if empe01_cl == 3
	
	** Check that activity was circled if main actiity is listed
	count if empe02a==. & empe03=="A"
	count if empe02b==. & empe03=="B"
	count if empe02c==. & empe03=="C"
	count if empe02d==. & empe03=="D"
	count if empe02e==. & empe03=="E"
	count if empe02f==. & empe03=="F"
	count if empe02g==. & empe03=="G"
	count if empe02h==. & empe03=="H"
	
	** How do we reconcile these?
	count if (empe02a==. & empe03=="A") | (empe02b==. & empe03=="B") | (empe02c==. & empe03=="C") | ///
			 (empe02d==. & empe03=="D") | (empe02d==. & empe03=="D") | (empe02e==. & empe03=="E") | ///
			 (empe02f==. & empe03=="F") | (empe02g==. & empe03=="G") | (empe02h==. & empe03=="H")
	
	** Turn the main activity into an integer
	encode empe03, gen(empe03cd)
		tab empe03 empe03cd,m
		drop empe03
		rename empe03cd empe03
		
	order vill_id hhold_id line_no empe00-empe02h_other empe03
	
	* Remake the count of jobs
	drop empe02_tot
	egen 		empe02_tot=rowtotal(empe02a empe02b empe02c empe02d empe02e empe02f empe02g empe02h)
	lab var 	empe02_tot "Number of jobs worked, rowtotal empe2a-empe2h"
	
***Sum all variables to check fo -ve values
	foreach var of varlist empe01-empe02h empe04-empe06 empe07a-empe07ru{
		replace `var' =. if `var'==-8 
		replace `var' =. if `var'==-7 
		replace `var' =. if `var'==-6
	}
	
	sum empe01-empe07ru

*** Make conversion for phone survey earnings (phone survey only has Main so don't need to worry about Secondary)
	/*  Here are the steps for how I found historical forex rates
	1) I made a list of all country-year pairs in our data.
	2) I went to an online site which had historical exchange rate information (www.oanda.com)
	3) I pulled the average of all weekly BID exchange rates (how many takas you can buy with 1 unit of foreign currency) 
	   from Jan1 - Dec31 for each country-year in our data. 
	4) I apply the annual average to all of our data (I also recorded the period’s high and low in case we wanted to use)

	FOR MORE INFORMATION SEE "${made}../historical_forex_rates.xlsx" for a README page
	*/
	
	*tab empe06_ctry empe06_ctrycd,m
	
	** There are two people missing empe06_ctry
		* One person with empe06_ctrycd==51, but blank country code
		// Looking at the person's other records, they live in Saudi Arabia
		// but have been reporting income in Taka
		* HARD CODE
		replace empe06_ctrycd = 50 if empe06_ctrycd==51 
		
		* Another person that has empe06_ctrycd==684 (invalid) but their vill_id == 784
		* HARD CODE
		replace empe06_ctrycd = 784 if empe06_ctrycd==684
		replace empe07b		  = 784 if empe07b      ==684
	
	** Create file which has all of the country/year 
	preserve
		replace empe06_ctry = trim(empe06_ctry)
		drop if empe06_ctrycd == . // There are two records with blank country names, 51=Armenia (maybe typo?) and 684 is invalid
		
		collapse (first) empe06_ctry, by(empe06_ctrycd year_em)
		
		// export excel using "C:\Users\phill\Box Sync\migrant followup\MHSS\2_data\employment\historical_forex.xlsx", firstrow(var) replace
	restore
	
	** Merge in file with historical exchange rates
	mmerge empe06_ctrycd year_em using "P:\pop\BANGLADESH_PROJECT\MHSS2\Analysis Files\Data\Migrant\historical_forex_rates.dta", ///
		missing(nomatch) ukeep(average) 
		drop if _merge == 2 | _merge == -2
		
		tab empe01 _merge if phone_survey == 1 // All phone survey have rates brought in if needed
	
	** Conversion Here
	gen empe06_phone = empe06 if phone_survey == 1
	replace empe06 = empe06 * average if phone_survey == 1 & average!=.
	
	drop average _merge
	
*** If report not working, set weeks/hours/earnings to 0
	sum empe05weeks empe05hours empe06 if empe01==0
	
	gen		empe05weeks_cl 	= empe05weeks
	replace	empe05weeks_cl 	= 0 			if empe01_cl==0 & empe05weeks==.
	
	gen 	empe05hours_cl 	= empe05hours
	replace	empe05hours_cl 	= 0				if empe01_cl==0 & empe05hours==.
	
	gen 	empe06_cl		= empe06
	replace	empe06_cl		= 0				if empe01_cl==0 & empe06==.
	
	sum empe05weeks_cl empe05hours_cl empe06_cl line_no
	sum empe05weeks_cl empe05hours_cl empe06_cl empe01 line_no if empe00==3 & empe01_cl!=.
	
	li empe01_cl empe03 empe05weeks_cl empe05hours_cl empe06_cl if empe00==3 & empe01!=. & empe05weeks_cl == .
	li empe01_cl empe03 empe05weeks_cl empe05hours_cl empe06_cl if empe00==3 & empe01!=. & empe05hours_cl == .
	li empe01_cl empe03 empe05weeks_cl empe05hours_cl empe06_cl if empe00==3 & empe01!=. & empe06_cl == .

 ***Reshape so information on past jobs is wide
	order vill_id hhold_id line_no empe00 empe01 empe01_cl ///
		  empe02a empe02b empe02c empe02d empe02e empe02f empe02g empe02h empe02h_other empe02h_other_eng ///
		  empe03 empe04name empe04name_eng empe04 empe05weeks empe05weeks_cl empe05hours empe05hours_cl ///
		  empe06 empe06_cl empe06_ctrycd empe06_ctry empe06_units empe06_qty ///
		  empe07a empe07b empe07ru empe07_ctry
		  
	bys vill_id hhold_id line_no phone_survey year_em: drop if _n > 1 // Somehow a duplicate was entered
 
	reshape wide empe01-empe07_ctry empe_answer02 empe02_tot empe06_phone, i(vill_id hhold_id line_no phone_survey) j(year_em)
	drop use_books
	
	order vill_id hhold_id line_no phone_survey empe00
	
tempfile empe
save `empe'

**********************
*******  EMPF  *******
**********************

**********************
*****   MERGES   *****
**********************
use `empa', clear
	
	mmerge vill_id hhold_id line_no phone_survey using `empb', ///
		missing(nomatch) type(1:1) 
		drop _merge
		
	mmerge vill_id hhold_id line_no phone_survey using `empc', ///
		missing(nomatch) type(1:1)
		
		gen empc_book = (_merge == 2 | _merge == 3)
		drop _merge
	
	mmerge vill_id hhold_id line_no phone_survey using `empd', ///
		missing(nomatch) type(1:1)
		
		gen empd_book = (_merge == 2 | _merge == 3)
		drop _merge
	
	mmerge vill_id hhold_id line_no phone_survey using `empe', ///
		missing(nomatch) type(1:1)
		
		gen empe_book = (_merge == 2 | _merge == 3)
		drop _merge
	/*	
	mmerge vill_id hhold_id line_no source using `empf', ///
		missing(nomatch) type(1:1)
		
		gen empf_book = (_merge == 2 | _merge == 3)
		drop _merge
	*/
	
	** Set to zero if missing (because missing means they don't have book)
	replace empa_book = 0 if empa_book == .
	replace empb_book = 0 if empb_book == .
	replace empc_book = 0 if empc_book == .
	replace empd_book = 0 if empd_book == .
	replace empe_book = 0 if empe_book == .
	*replace empf_book = 0 if empf_book == .
	
	tempfile emp_data
	save `emp_data', replace
	
**********************
*****  OUTCOMES  *****
**********************
use `emp_data', clear

*** EMPA Outcomes ***
	** Overall Outcomes
	*Labor Force Participation
	gen m2_ea_part_any 	= empa01
	gen m2_ea_part_inc	= empa01 * (empa_inc_tot>0 & empa_inc_tot!=.)
	
	lab var m2_ea_part_any 	"=1 if worked 5 days or more in last 12 months, any sector"
	lab var m2_ea_part_inc	"=1 if worked 5 days or more for pay in last 12 months, any sector"
	
	tab m2_ea_part_any empa01,m
	tab m2_ea_part_inc empa01,m
	
	* Earnings
	gen 	m2_ea_incyear 		= empa_inc_tot
	replace m2_ea_incyear 		= .	if empa00==1
	gen 	m2_ea_incyearb 		= empa_inc_totb
	replace m2_ea_incyearb		= . if empa00==1
	gen 	m2_ea_incyearHH		= empa_inc_totHH
	replace m2_ea_incyearHH		= . if empa00==1
	gen 	m2_ea_incyearNFarm 	= empa_inc_totNFarm
	replace m2_ea_incyearNFarm	= . if empa00==1
	gen 	m2_ea_incyearNFam	= empa_inc_totNFam 
	replace m2_ea_incyearNFam	= . if empa00==1
	
	gen m2_ea_lnincyear	= ln(m2_ea_incyear)
	gen 	m2_ea_inchour 	= empa_wagehr
	replace m2_ea_inchour	= . if empa00==1
	gen m2_ea_lninchour	= ln(m2_ea_inchour)
	
	gen		m2_ea_lnincyear_1 		= ln(m2_ea_incyear + 1)
	gen		m2_ea_lnincyear_10 		= ln(m2_ea_incyear + 10)
	gen		m2_ea_lnincyear_100 	= ln(m2_ea_incyear + 100)
	gen		m2_ea_lnincyear_1000	= ln(m2_ea_incyear + 1000)
	
	sum m2_ea_incyear-m2_ea_lninchour
		
	lab var m2_ea_incyear 		"Annual Earnings (Tk), all sectors"
	lab var m2_ea_incyearb 		"Annual Earnings (Tk), all sectors (forex)"
	lab var m2_ea_incyearHH		"Annual Earnings (Tk), all sectors (fam. bus. adjusted)"
	lab var m2_ea_incyearNFarm	"Annual Earnings (Tk), w/o Family Farm"
	lab var m2_ea_incyearNFam	"Annual Earnings (Tk), w/o Family Bus./Farm and Other"
	lab var m2_ea_lnincyear 	"Ln Annual Earnings (Tk), all sectors"
	lab var m2_ea_inchour 		"Hourly Earnings (Tk), all sectors"
	lab var m2_ea_lninchour 	"Ln Hourly Earnings (Tk), all sectors"
	
	** Interpret the village code of the person
	* International Villages
	gen 		intl_vill		= 0
		replace	intl_vill		= 1 if real(vill_id)!=.
	
	gen 		intl_villcd		= real(vill_id) if intl_vill == 1
	
	*** Create list of all international countries
	preserve
		keep if intl_vill == 1
		bys intl_villcd: keep if _n == 1
		
		// export excel intl_villcd using "C:\Users\phill\Box Sync\migrant followup\MHSS\2_data\intl_countries.xls", firstrow(variable) replace
	restore
	
	*** Bring in the ppp_deflator
	mmerge intl_villcd using "P:\pop\BANGLADESH_PROJECT\MHSS2\Analysis Files\Data\Migrant\intl_countries_ppprates.dta", ukeep(deflator deflator2) uname(ppp_) missing(nomatch)
		drop if _merge == 2 | _merge == -2
		assert _merge != 1
		
		** If in BD (_merge==-1) then set ppp_deflator to 1
		replace ppp_deflator  = 1 if _merge == -1
		replace ppp_deflator2 = 1 if _merge == -1
		
		drop _merge
	
	* Create a deflated income values
	gen 	m2_ea_incyearc	= m2_ea_incyear  * ppp_deflator2
	gen 	m2_ea_incyeard 	= m2_ea_incyearb * ppp_deflator2
	
	* Remove housing expenses from household
		* Merge in household rent data from HC
		mmerge vill_id hhold_id using "P:\pop\BANGLADESH_PROJECT\MHSS2\Master Data\20160107_public\b1_hc.dta", ukeep(hc01 hc02)
			drop if _merge == 2 | _merge == -2

		*Determine number of workers in the household
		bys vill_id hhold_id: egen hh_tot_workers = total(m2_ea_part_inc)
		
		*Calculate rent per worker
		gen		rent_per_worker = hc02 / hh_tot_workers
		replace	rent_per_worker = 0 if hc02==.
		replace rent_per_worker = 0 if hh_tot_workers == 0
		
		gen		m2_ea_incyearf = m2_ea_incyearHH
		replace m2_ea_incyearf = m2_ea_incyearf - rent_per_worker if m2_ea_incyearf!=0 
			li m2_ea_incyearHH m2_ea_incyearf hh_tot_workers hc02 rent_per_worker if m2_ea_incyearf<0 // Negative incomes (all are workers)
		replace m2_ea_incyearf = 0 if m2_ea_incyearf < 0
		
			sum m2_ea_incyearHH m2_ea_incyearf
			
	
	* Remove migration expenses
		* Merge in migration expenses
		mmerge vill_id hhold_id line_no using "P:\pop\BANGLADESH_PROJECT\MHSS2\Master Data\20160107_public\b3_mg.dta", ukeep(mg21)
			drop if _merge == 2 | _merge == -2
			
		* Create Mig Costs (assume 5 year migration contract)
		replace mg21 = . if mg21 < 0
		gen 	m2_mg_migcost = mg21 / 5
		
		bys vill_id: egen temp = mean(m2_mg_migcost) 
		replace m2_mg_migcost = temp if m2_mg_migcost == .
			// There are two individuals that are in a country with no one else to fill in a mean
			// Belgium and Canada.  The Canadian has been there for a long time, probably don't need 
			// to deduct migration cost.  The Beligian appears to actually be in BD.
			drop temp
		
		gen 	m2_ea_incyearg = m2_ea_incyearHH
		replace m2_ea_incyearg = m2_ea_incyearg - m2_mg_migcost if intl_vill==1 & m2_mg_migcost!=. 
			li m2_ea_incyearHH m2_ea_incyearg m2_mg_migcost 	if m2_ea_incyearg<0
		replace m2_ea_incyearg = 0 if m2_ea_incyearg < 0 
		
			sum m2_ea_incyearHH m2_ea_incyearg
			
		
	* Remove both migration and rent expenses
		gen 	m2_ea_incyearh = m2_ea_incyearHH
		replace m2_ea_incyearh = m2_ea_incyearh - rent_per_worker if m2_ea_incyear!=0  
		replace m2_ea_incyearh = m2_ea_incyearh - m2_mg_migcost if intl_vill==1 & m2_mg_migcost!=. 
		replace m2_ea_incyearh = 0 if m2_ea_incyearh < 0
		
		sum m2_ea_incyearHH m2_ea_incyearh
		
	lab var m2_ea_incyearc 		"Annual Earnings (Tk), all sectors (ppp)"
	lab var m2_ea_incyeard 		"Annual Earnings (Tk), all sectors (forex&ppp)"
	// m2_ea_incyeare is made at end of Panel file to use Transfers
	lab var m2_ea_incyearf 		"Annual Earnings (Tk), all sectors (HHInc&rent)"
	lab var m2_ea_incyearg		"Annual Earnings (Tk), all sectors (HHInc&migcosts)"
	lab var m2_ea_incyearh		"Annual Earnings (Tk), all sectors (HHInc&migcosts&rent)"
	
	* Domestic non-Matlab Vilages
	gen 		nonmatlab_vill	= 0 
		replace nonmatlab_vill	= 1 if substr(vill_id,1,1)=="Y"
	
	gen 		nonm_villcd		= real(substr(vill_id,2,2)) if nonmatlab_vill==1
	
	* Matlab Villages
	gen			matlab_vill		= 0 
		replace matlab_vill 	= 1 if intl_vill == 0 & nonmatlab_vill == 0
	
	* Dhaka Metro
	gen			dhaka_vill		= 0
		replace dhaka_vill		= 1 if inlist(nonm_villcd,39,40,41,42,43)
		
	gen 		urban_vill		= 0
		replace	urban_vill		= 1 if inlist(nonm_villcd,39,40,41,42,43,60) // Dhaka + Chittagong
		
		tab vill_id intl_vill
		tab vill_id nonmatlab_vill
		tab vill_id matlab_vill
		tab vill_id dhaka_vill

	* Create a district code for non-matlab/intl people using vill_id
	gen 		vill_distcd = .
		replace vill_distcd = intl_villcd if intl_vill == 1
		replace vill_distcd = nonm_villcd if nonmatlab_vill == 1
		
	** Sectoral Outcomes
	forvalues i=1(1)8 {
		* Labor Force Participation
		gen m2_ea_participate`i' = empa01`i'
		gen m2_ea_part_inc`i' = empa01`i' * (empa03_cl`i'>0 & empa03_cl`i'!=.)
			
		label var m2_ea_participate`i' 	"=1 if worked 5 days or more in last 12 months in Sector `i'"
		label var m2_ea_part_inc`i'		"=1 if worked for pay in last 12 months in Sector `i'"
		
		* Earnings
		gen m2_ea_incyear`i' 	= empa03_cl`i'
		gen m2_ea_lnincyear`i' 	= ln(m2_ea_incyear`i')
		gen m2_ea_incweek`i' 	= m2_ea_incyear`i' / empa02weeks_cl`i'
		gen m2_ea_lnincweek`i'	= ln(m2_ea_incweek`i')
		gen m2_ea_inchour`i' 	= m2_ea_incweek`i' / empa02hours_cl`i'
		gen m2_ea_lninchour`i' 	= ln(m2_ea_inchour`i')
		
		lab var m2_ea_incyear`i' 	"Annual Earnings (Tk) in Sector `i'"
		lab var m2_ea_lnincyear`i' 	"Ln Annual Earnings (Tk) in Sector `i'"
		lab var m2_ea_incweek`i' 	"Weekly Earnings (Tk) in Sector `i'"
		lab var m2_ea_lnincweek`i' 	"Ln Weekly Earnings (Tk) in Sector `i'"
		lab var m2_ea_inchour`i' 	"Hourly Earnings (Tk) in Sector `i'"
		lab var m2_ea_lninchour`i' 	"Ln Hourly Earnings (Tk) in Sector `i'"
		
		* Labor Supply
		gen m2_ea_hrs_tot`i'	= empa_hrs_tot`i'
		
		lab var m2_ea_hrs_tot`i'	"Annual Hours Worked in Sector `i'"
		
		* Location
		tab 	empa04loc1_cl`i'
		tab 	empa04ruralurban`i'
	/*	recode 	empa04loc1`i' 		(1/3 = 1) (nonm = 0), gen(m2_ea_samevill`i')
		recode 	empa04loc1`i' 		(1/4 = 1) (nonm = 0), gen(m2_ea_samethana`i')
		recode	empa04loc1`i' 		(6 = 1)   (nonm = 0), gen(m2_ea_diffdist`i')
		recode 	empa04loc1`i' 		(7 = 1)   (nonm = 0), gen(m2_ea_diffctry`i') */
		recode 	empa04ruralurban`i' (2 = 1)   (nonm = 0), gen(m2_ea_urban`i')
		
	/*	recode 	empa05loc1`i' 		(1/3 = 1) (nonm = 0), gen(m2_ea_samevill`i'_sec)
		recode 	empa05loc1`i' 		(1/4 = 1) (nonm = 0), gen(m2_ea_samethana`i'_sec)
		recode 	empa05loc1`i' 		(6 = 1)   (nonm = 0), gen(m2_ea_diffdist`i'_sec)
		recode 	empa05loc1`i' 		(7 = 1)   (nonm = 0), gen(m2_ea_diffctry`i'_sec) */
		recode 	empa05ruralurban`i' (2 = 1)   (nonm = 0), gen(m2_ea_urban`i'_sec)
		
	/*	lab var m2_ea_samevill`i' 		"=1 if Sector `i' job in same village"
		lab var m2_ea_samethana`i' 		"=1 if Sector `i' job in same thana"
		lab var m2_ea_diffdist`i' 		"=1 if Sector `i' job in different district"
		lab var m2_ea_diffctry`i' 		"=1 if Sector `i' job in different country" */
		lab var m2_ea_urban`i'			"=1 if Sector `i' job in urban location"
			
	/*	lab var m2_ea_samevill`i'_sec 	"=1 if Sector `i' job in same village (secondary)"
		lab var m2_ea_samethana`i'_sec 	"=1 if Sector `i' job in same thana (secondary)"
		lab var m2_ea_diffdist`i'_sec 	"=1 if Sector `i' job in different district (secondary)"
		lab var m2_ea_diffctry`i'_sec 	"=1 if Sector `i' job in different country (secondary)" */
		lab var m2_ea_urban`i'_sec 		"=1 if Sector `i' job in urban location (secondary)"
		
		* Intl Migrant
		gen 		intl_mig`i'				= .
			replace intl_mig`i'				= 0 if empa04loc1`i'!=.
			replace intl_mig`i'				= 1 if intl_vill==1 | empa04loc1`i'==7 
		
		* Temporary Migrant
		gen 		m2_ea_tempmig`i'		= .
			replace m2_ea_tempmig`i'		= 0 if empa04loc1_cl`i'!=.
			replace m2_ea_tempmig`i'		= 1 if inlist(empa04loc1_cl`i',6,7) & empa04loc2`i'!=vill_distcd 			& matlab_vill==0
			replace m2_ea_tempmig`i'		= 1 if inlist(empa04loc1_cl`i',6,7) & empa04loc2`i'!=56		  				& matlab_vill==1
			replace m2_ea_tempmig`i'		= 0 if inlist(empa04loc1_cl`i',6)	& inlist(empa04loc2`i',39,40,41,42,43)	& dhaka_vill==1 // Dhaka Metro people
		
		* Interact with urban/rural/intl
		gen 		m2_ea_tempmig_urban`i' 	= m2_ea_tempmig`i' * m2_ea_urban`i'
		gen			m2_ea_tempmig_rural`i'	= m2_ea_tempmig`i' * (1 - m2_ea_urban`i')
		gen 		m2_ea_tempmig_intl`i'	= m2_ea_tempmig`i' * intl_mig`i'
		
		lab var intl_mig`i'				"=1 if work/live outside BD, activity `i'"
		lab var m2_ea_tempmig`i'		"=1 if work in different district than live, activity `i'"
		lab var m2_ea_tempmig_urban`i'	"=1 if work in urban area in different district than live, activity `i'"
		lab var m2_ea_tempmig_rural`i'	"=1 if work in rural area in different district than live, activity `i'"
		lab var m2_ea_tempmig_intl`i'	"=1 if work in intl in different district than live, activity `i'"
	}
	
	** Just some tabs to see what is going on with the location codes...
		* Check some vills outside of matlab
		tab empa04loc21 empa04loc1_cl1 if vill_id == "Y39" & empa04loc1_cl1!=.,m
		tab empa04loc21 empa04loc1_cl1 if vill_id == "Y41" & empa04loc1_cl1!=.,m
		
		* Check matlab people
		tab empa04loc21 empa04loc1_cl1 if matlab_vill==1   & empa04loc1_cl1!=.,m
		
		* Check intl people
		tab empa04loc21 empa04loc1_cl1 if intl_vill==1     & empa04loc1_cl1!=.,m // Some 7's -check below / No 6's GOOD
		tab vill_id empa04loc21		   if intl_vill==1     & empa04loc1_cl1==7,m // All the sevens above report their own country as the country code
		
	** Create Location Codes 
		* Temporary migrant (any activity)
		egen m2_ea_tempmig			= rowmax(m2_ea_tempmig?)
		egen m2_ea_tempmig_urban	= rowmax(m2_ea_tempmig_urban?)
		egen m2_ea_tempmig_rural	= rowmax(m2_ea_tempmig_rural?)
		egen m2_ea_tempmig_intl		= rowmax(m2_ea_tempmig_intl?)
		
		* Permanent migrant
		gen m2_ea_permmig			= nonmatlab_vill == 1 | intl_vill == 1
		gen m2_ea_permmig_urban 	= m2_ea_permmig * (urban_vill) 
		gen m2_ea_permmig_rural 	= m2_ea_permmig * (1-urban_vill) * (1-intl_vill)
		gen m2_ea_permmig_intl		= intl_vill == 1
		
		gen 	m2_ea_permmig_chadpur	= m2_ea_permmig
		replace m2_ea_permmig_chadpur 	= 0 if nonm_villcd == 56
		
		gen m2_ea_permmig_chad_urb	= m2_ea_permmig_chadpur * (urban_vill)
		gen m2_ea_permmig_chad_rur	= m2_ea_permmig_chadpur * (1-urban_vill) * (1-intl_vill)
		
	** Ag / Non-Ag Participation
	egen m2_ea_part_ag		= rowmax(empa015 empa017)
	egen m2_ea_part_nag		= rowmax(empa011 empa012 empa013 empa014 empa016 empa018)
	egen m2_ea_part_skill	= rowmax(empa011 empa012 empa014)
	
	egen m2_ea_part_ag_inc		= rowmax(m2_ea_part_inc5 m2_ea_part_inc7)
	egen m2_ea_part_nag_inc		= rowmax(m2_ea_part_inc1 m2_ea_part_inc2 m2_ea_part_inc3 m2_ea_part_inc4 m2_ea_part_inc6 m2_ea_part_inc8)
	egen m2_ea_part_skill_inc	= rowmax(m2_ea_part_inc1 m2_ea_part_inc2 m2_ea_part_inc4)
	
	lab var m2_ea_part_skill 	"=1 if Salaried, Self-Employed, or Family Business"
	lab var m2_ea_part_ag 		"=1 if Agricultural Day Laborer or Work on Family Farm"
	lab var m2_ea_part_nag 		"=1 if Not Agricultural Day Laborer or Work on Family Farm"
	
	lab var m2_ea_part_skill_inc 	"=1 if paid Salaried, Self-Employed, or Family Business"
	lab var m2_ea_part_ag_inc 		"=1 if paid Agricultural Day Laborer or Work on Family Farm"
	lab var m2_ea_part_nag_inc 		"=1 if paid Not Agricultural Day Laborer or Work on Family Farm"
		
	forvalues i = 1(1)8{
		disp "Activity: `i'"
		disp "Number of Temporary Migrants working 52 Weeks in activity"
		count if empa02weeks_cl`i' == 52 & m2_ea_tempmig`i'==1
		disp "out of"
		count if m2_ea_tempmig`i'==1
		disp "migrants"
		disp " "
	}
	
	* Labor Supply
	gen m2_ea_hrs_tot 		= empa_hrs_tot
	gen m2_ea_lnhrs_tot		= ln(m2_ea_hrs_tot)
	gen m2_ea_lnhrs_tot_1	= ln(m2_ea_hrs_tot+1)
	gen m2_ea_lnhrs_tot_10	= ln(m2_ea_hrs_tot+10)
	gen m2_ea_lnhrs_tot_100	= ln(m2_ea_hrs_tot+100)
	
	
	lab var m2_ea_hrs_tot	"Annual Hours Worked, all sectors"
	lab var m2_ea_lnhrs_tot	"Log Annual Hours Worked, all sectors"
	
	* Type of Activity
	forvalues i=1(1)8 {
		rename empa01`i' m2_ea_act`i'
	}
	
	lab var m2_ea_act1 		"=1 if Salaried Worker"
	lab var m2_ea_act2 		"=1 if Piece-Rate Worker"
	lab var m2_ea_act3 		"=1 if Self-Employed"
	lab var m2_ea_act4 		"=1 if Family Business Worker"
	lab var m2_ea_act5 		"=1 if Agricultural Day Laborer"
	lab var m2_ea_act6 		"=1 if Other Day Laborer"
	lab var m2_ea_act7 		"=1 if Work on Family Farm"
	lab var m2_ea_act8 		"=1 if Other Activity"
	
	forvalues i = 1(1)8{
		gen 	m2_ea_primact`i' = .
		replace m2_ea_primact`i' = 0 if empa01!=.
		replace m2_ea_primact`i' = 1 if empa_prim_act_cl == `i'
	}
	
	lab var m2_ea_primact1 	"=1 if Salaried Worker (Primary)"
	lab var m2_ea_primact2 	"=1 if Piece-Rate Worker (Primary)"
	lab var m2_ea_primact3 	"=1 if Self-Employed (Primary)"
	lab var m2_ea_primact4 	"=1 if Family Business Worker (Primary)"
	lab var m2_ea_primact5 	"=1 if Agricultural Day Laborer (Primary)"
	lab var m2_ea_primact6 	"=1 if Other Day Laborer (Primary)"
	lab var m2_ea_primact7 	"=1 if Work on Family Farm (Primary)"
	lab var m2_ea_primact8 	"=1 if Other Activity (Primary)"
	
	gen 	m2_ea_primact34 = .
	replace m2_ea_primact34 = 0 if empa01!=.
	replace m2_ea_primact34 = 1 if m2_ea_primact3 == 1 | m2_ea_primact4 == 1
	
	egen m2_ea_primpart_skill 	= 	rowmax(m2_ea_primact1 m2_ea_primact3 m2_ea_primact4)
	egen m2_ea_primpart_ag  	= 	rowmax(m2_ea_primact5 m2_ea_primact7)
	egen m2_ea_primpart_nag		=	rowmax(m2_ea_primact1 m2_ea_primact2 m2_ea_primact4)
		
	lab var m2_ea_primpart_skill 	"=1 if Salaried, Self-Employed, or Family Business (Primary)"
	lab var m2_ea_primpart_ag 		"=1 if Agricultural Day Laborer or Work on Family Farm (Primary)"
	lab var m2_ea_primpart_ag 		"=1 if Not Agricultural Day Laborer or Work on Family Farm (Primary)"
	
	gen 	m2_ea_loc1_primact1 = .
	gen 	m2_ea_loc1_primact2 = .
	forvalues i = 1(1)8 {
		replace m2_ea_loc1_primact1 = empa04loc1_cl`i' if empa_prim_act_cl == `i'
		replace m2_ea_loc1_primact2 = empa05loc1`i' if empa_prim_act_cl == `i'
	}
	
	recode m2_ea_loc1_primact1 (1/4=0) (nonm=1), gen(m2_ea_commuter1)
	recode m2_ea_loc1_primact1 (1/3=0) (nonm=1), gen(m2_ea_commuter2)
	
	** Earnings for primary activity
	gen m2_ea_incyear_prim = .
	gen m2_ea_incweek_prim = .
	gen m2_ea_inchour_prim = .
	gen m2_ea_hrs_tot_prim = .
	
	forvalues i=1(1)8 {
		replace m2_ea_incyear_prim = m2_ea_incyear`i' if m2_ea_primact`i'==1
		replace m2_ea_incweek_prim = m2_ea_incweek`i' if m2_ea_primact`i'==1
		replace m2_ea_inchour_prim = m2_ea_inchour`i' if m2_ea_primact`i'==1
		replace m2_ea_hrs_tot_prim = m2_ea_hrs_tot`i' if m2_ea_primact`i'==1
	}
	
	replace m2_ea_incyear_prim = 0 if empa01==0 & m2_ea_incyear_prim == .
	replace m2_ea_hrs_tot_prim = 0 if empa01==0 & m2_ea_hrs_tot_prim == .
	
	gen m2_ea_lnincyear_prim = ln(m2_ea_incyear_prim)
	gen m2_ea_lnincweek_prim = ln(m2_ea_incweek_prim)
	gen m2_ea_lninchour_prim = ln(m2_ea_inchour_prim)
	
	lab var m2_ea_incyear_prim 		"Annual Earnings (Tk), primary activity"
	lab var m2_ea_incweek_prim 		"Weekly Earnings (Tk), primary activity"
	lab var m2_ea_inchour_prim 		"Hourly Earnings (Tk), primary activity"
	lab var m2_ea_lnincyear_prim 	"Ln Annual Earnings (Tk), primary activity"
	lab var m2_ea_lnincweek_prim 	"Ln Weekly Earnings (Tk), primary activity"
	lab var m2_ea_lninchour_prim 	"Ln Hourly Earnings (Tk), primary activity"
	lab var m2_ea_hrs_tot_prim		"Annual Hours Worked, primary activity"
	
	** Earnings split by different activities
	gen 	m2_ea_incyear_sal 		= m2_ea_incyear1
	replace m2_ea_incyear_sal 		= 0 	if m2_ea_incyear_sal == . & m2_ea_incyear!=.
	gen 	m2_ea_incyear_self		= m2_ea_incyear3
	replace m2_ea_incyear_self		= 0 	if m2_ea_incyear_self == . & m2_ea_incyear!=.
	egen 	m2_ea_incyear_selfhh	= rowtotal(m2_ea_incyear3 m2_ea_incyear4),m
	replace m2_ea_incyear_selfhh	= 0 	if m2_ea_incyear_selfhh == . & m2_ea_incyear!=.
	egen 	m2_ea_incyear_lownag	= rowtotal(m2_ea_incyear2 m2_ea_incyear6), m
	replace m2_ea_incyear_lownag	= 0		if m2_ea_incyear_lownag == . & m2_ea_incyear!=.
	egen 	m2_ea_incyear_nag		= rowtotal(m2_ea_incyear1 m2_ea_incyear2 m2_ea_incyear3 m2_ea_incyear4 m2_ea_incyear6 m2_ea_incyear8),m
	replace m2_ea_incyear_nag		= 0 	if m2_ea_incyear_nag == . & m2_ea_incyear!=.
	gen		m2_ea_incyear_lowag		= m2_ea_incyear5
	replace m2_ea_incyear_lowag 	= 0		if m2_ea_incyear_lowag == . & m2_ea_incyear!=.
	egen	m2_ea_incyear_ag		= rowtotal(m2_ea_incyear5 m2_ea_incyear7),m
	replace m2_ea_incyear_ag		= 0 	if m2_ea_incyear_ag == . & m2_ea_incyear!=.
	gen 	m2_ea_incyear_highag	= m2_ea_incyear7 
	replace m2_ea_incyear_highag	= 0 	if m2_ea_incyear_highag == . & m2_ea_incyear!=.
	
	order vill_id hhold_id line_no phone_survey $m2_ea_outcomes m2_ea_*
	
	sum m2_ea_participate* m2_ea_incyear* m2_ea_tempmig line_no // Only missing the same 16 as above
	sum $m2_ea_outcomes empa_prim_act_cl line_no
	
	sum m2_ea_primact? line_no
	
*** EMPB Outcomes ***

	** Occupation
	gen m2_eb_occupd=empb01a1  
	gen m2_eb_occup = . // Should revisit these groupings...
		replace m2_eb_occup = 0 if inlist(m2_eb_occupd,100) 
		replace m2_eb_occup = 1 if inlist(m2_eb_occupd,110,111,120,130)
		replace m2_eb_occup = 2 if inlist(m2_eb_occupd,210,221,222,223,224,231,232,233,234,241,261,262,263,270)
		replace m2_eb_occup = 3 if inlist(m2_eb_occupd,310,320,330,341)
		replace m2_eb_occup = 4 if inlist(m2_eb_occupd,410,420,431,432,433,434,435,440,441,442)
		replace m2_eb_occup = 5 if inlist(m2_eb_occupd,511,512,513,514,515,516,517)
		replace m2_eb_occup = 6 if inlist(m2_eb_occupd,611,612,621,622,623,630,640,650,651,652,652,660,661,662,663,670,680)
		replace m2_eb_occup = 7 if inlist(m2_eb_occupd,711,712,713,714,715,730,731,732)
		replace m2_eb_occup = 8 if inlist(m2_eb_occupd,811,812,813,814,815,816,820,821,822,830,840,860,870,880,890)
		replace m2_eb_occup = 9 if inlist(m2_eb_occupd,920,930,940,950,960,970,971)
	
	lab var m2_eb_occup "General Occupation Category (Main)"
		
	gen m2_eb_occupd_sec=empb01a2 
	gen m2_eb_occup_sec = .
		replace m2_eb_occup_sec = 0 if inlist(m2_eb_occupd_sec,100)
		replace m2_eb_occup_sec = 1 if inlist(m2_eb_occupd_sec,110,111,120,130)
		replace m2_eb_occup_sec = 2 if inlist(m2_eb_occupd_sec,210,221,222,223,224,231,232,233,234,241,261,262,263,270)
		replace m2_eb_occup_sec = 3 if inlist(m2_eb_occupd_sec,310,320,330,341)
		replace m2_eb_occup_sec = 4 if inlist(m2_eb_occupd_sec,410,420,431,432,433,434,435,440,441,442)
		replace m2_eb_occup_sec = 5 if inlist(m2_eb_occupd_sec,511,512,513,514,515,516,517)
		replace m2_eb_occup_sec = 6 if inlist(m2_eb_occupd_sec,611,612,621,622,623,630,640,650,651,652,652,660,661,662,663,670,680)
		replace m2_eb_occup_sec = 7 if inlist(m2_eb_occupd_sec,711,712,713,714,715,730,731,732)
		replace m2_eb_occup_sec = 8 if inlist(m2_eb_occupd_sec,811,812,813,814,815,816,820,821,822,830,840,860,870,880,890)
		replace m2_eb_occup_sec = 9 if inlist(m2_eb_occupd_sec,920,930,940,950,960,970,971)
	
	lab var m2_eb_occup_sec "General Occupation Category (Secondary)"
	
	#delimit ;
	label define gen_occup_lbl  0 "Armed Forces"
								1 "Managers"
								2 "Professionals"
								3 "Technicians and Associate Professionals"
								4 "Clerical Support, Sales Workers, Security"
								5 "Skilled Agriculture, Forestry, Fishery Workers"
								6 "Manual, Craft, and Related Trades Workers"
								7 "Machine Operators, Factory Workers, and Assemblers"
								8 "Elementary Occupations"
								9 "Others";
	#delimit cr
	lab values m2_eb_occup 	 gen_occup_lbl
	lab values m2_eb_occup_sec gen_occup_lbl
	
	#delimit ;
	lab define occupd_lbl 100 "Armed Forces"
							110 "Senior government officer, senior civil servant"
							111 "Government official, elected"
							120 "Director, chief executve, or senior manager in large business or NGO"
							130 "Owner of large/medium trading/brokering business, large/medium shop, or large/medium moneylending business"
							210 "Science, engineering, technology professional"
							221 "Doctor, dentist"
							222 "Nursing or midwifery professional"
							223 "Traditional medicine professional (degreed)"
							224 "Other degreed health professional"
							231 "Teacher, college/university"
							232 "Teacher, secondary"
							233 "Teacher, primary and pre-primary"
							234 "Other degreed teaching professional"
							241 "Management professional in business, non-profit, or government"
							261 "Lawyer, judges, or other degreed legal professional"
							262 "Religious Professional"
							263 "Other cultural professional"
							270 "Other skilled professional"
							310 "Science, engineering, and technology associate professional or technician"
							320 "Health or medical technician"
							330 "Business and administration associate"
							341 "Other technician or associate professional"
							410 "Secretary or keyboard operator"
							420 "Other clerk"
							431 "Hotel or tourism worker"
							432 "Restaurant worker"
							433 "Hair cutter or other personal service provider"
							434 "Police, Ansar, BDR, fire fighter, prison guard"
							435 "Security guard"
							440 "Shop worker (salesperson, cashier)"
							441 "Owner of small trading/brokering business, small shop, or small moneylending business"
							442 "Entry-level workers"
							511 "Farmer (own farm)"
							512 "Farmer (sharecropper)"
							513 "Raising cows, goats, sheep"
							514 "Raising ducks or hens"
							515 "Fish farm or fish hatchery"
							516 "Fishing in river or sea"
							517 "Other agriculture or forestry production"
							611 "Carpenter, skilled house builder, supervisor, house contractor, mason"
							612 "Skilled home finish or repair"
							621 "Sheet and structural metal supervisor, moulders and welders"
							622 "Blacksmith or tool maker"
							623 "Machinery mechanics and repair"
							630 "Handicraft worker"
							640 "Eletrical and electronic appliance repair, maintenance, installation"
							650 "Food processing"
							651 "Woodworking"
							652 "Garment and related trade workers"
							660 "Traditional healer / kabiraj"
							661 "Traditional birth attendant"
							662 "Entry level or non-degree health care worker"
							663 "Social worker"
							670 "Tutor"
							680 "Other craft workers "
							711 "Mine worker or mineral processing"
							712 "Garment factory worker (textiles, leather, fur, fabric)"
							713 "Jute mill worker"
							714 "Food processing factory worker"
							715 "Other factory machine operator "
							730 "Driver of car, van or motorcycle, motor boat"
							731 "Driver of heavy equipment"
							732 "Driver of baby taxi / CNG / autorickshaw / tempo / tractor"
							811 "Domestic worker in home or office"
							812 "Caretaker, gardener, messenger, or doorman in home or office"
							813 "Rickshaw / bicycle van driver"
							814 "Boatman (country boat)"
							815 "Street vendor or hawker"
							816 "Bearers and peons"
							820 "Agricultural laborer"
							821 "Construction or earth-work laborer (non-food for work)"
							822 "Construction or earth-work laborer (food for work)"
							830 "Laborer in factory, mine, or transport"
							840 "Food preparation assistant or kitchen helper"
							860 "Sweeper"
							870 "Refuse worker, sorter, recycler, forager"
							880 "Beggar"
							890 "Other daily laborer or elementary worker"
							920 "Searching for work"
							930 "Not looking for work"
							940 "Unable to do work"
							950 "Student"
							960 "Household work/ housewife"
							970 "Retired"
							971 "Old age";
	#delimit cr
	lab values m2_eb_occupd 		occupd_lbl
	lab values m2_eb_occupd_sec 	occupd_lbl
	
	* See errors in occupation codes (ALL OF THESE ARE INVALID CODES PER THE BOOK OF CODES)
	// Can we figure this out looking at the description? //
	tab empb01a1 if m2_eb_occupd!=. & m2_eb_occup==.
	tab empb01a2 if m2_eb_occupd_sec!=. & m2_eb_occup_sec==.
	
	li empb01a1 empb011 if m2_eb_occupd!=. & m2_eb_occup==.
	li empb01a2 empb012 if m2_eb_occupd_sec!=. & m2_eb_occup_sec==.
	** Looks like I could use the above list to clean the occupation codes... **
	
	
	** Group Occupations
	recode m2_eb_occup 	(1/3=1) (nonm=0), gen(m2_eb_prof)
	recode m2_eb_occup 	(1/4=1) (nonm=0), gen(m2_eb_profplus)
	recode m2_eb_occup 	(5=1)   (nonm=0), gen(m2_eb_ag)
	recode m2_eb_occupd	(513 514=1) (nonm=0), gen(m2_eb_livestock)
	recode m2_eb_occupd (511 512=1) (nonm=0), gen(m2_eb_crops)
	recode m2_eb_occupd (515 516=1) (nonm=0), gen(m2_eb_fish)
	recode m2_eb_occup 	(6/7=1) (nonm=0), gen(m2_eb_manual)
	recode m2_eb_occup 	(8=1)   (nonm=0), gen(m2_eb_elementary)
	
	gen 	m2_eb_entrepreneur = .
	replace m2_eb_entrepreneur = 0 if m2_eb_occupd!=.
	replace m2_eb_entrepreneur = 1 if inlist(m2_eb_occupd,130,221,223,261,263,433,441,515,516,622,660,670,730,732) // These occupations have atleast 50% of our sample men working as "self-employed"
	
	gen 	m2_eb_owner = .
	replace m2_eb_owner = 0 if m2_eb_occupd!=.
	replace m2_eb_owner = 1 if inlist(m2_eb_occupd,130,441)
	
	tab m2_eb_occup m2_eb_prof,m
	tab m2_eb_occup m2_eb_manual,m
	tab m2_eb_occup m2_eb_elementary,m
	
	lab var m2_eb_prof 			"=1 if Manager, Professional or Assoc. Professional"
	lab var m2_eb_profplus 		"=1 if Manager, (Assoc.) Professional or Clerical"
	lab var m2_eb_ag			"=1 if Agriculture Occupation"
	lab var m2_eb_livestock		"=1 if raising livestock occupation"
	lab var m2_eb_crops			"=1 if farm occupation"
	lab var m2_eb_fish			"=1 if fishery occupation"
	lab var m2_eb_manual 		"=1 if Manual/Craft, or Machine/Factory/Assembler"
	lab var m2_eb_elementary 	"=1 if Elementary Occupations"
	
	gen 	m2_eb_prof_prim1 		= m2_eb_prof * m2_ea_primact1
	gen 	m2_eb_prof_prim34 		= m2_eb_prof * m2_ea_primact3
	replace m2_eb_prof_prim34		= m2_eb_prof * m2_ea_primact4 if m2_eb_prof_prim34==0
	gen 	m2_eb_profplus_prim1 	= m2_eb_profplus * m2_ea_primact1
	gen 	m2_eb_profplus_prim34 	= m2_eb_profplus * m2_ea_primact3
	replace m2_eb_profplus_prim34	= m2_eb_profplus * m2_ea_primact4 if m2_eb_profplus_prim34==0
	gen		m2_eb_profplus_noshop1  = m2_eb_profplus
	replace m2_eb_profplus_noshop1  = 0 if m2_eb_occupd==440 & m2_eb_profplus==1
	gen		m2_eb_profplus_noshop2  = m2_eb_profplus
	replace m2_eb_profplus_noshop2  = 0 if m2_eb_occupd==441 & m2_eb_profplus==1
	gen		m2_eb_profplus_noshop3  = m2_eb_profplus
	replace m2_eb_profplus_noshop3  = 0 if (m2_eb_occupd==440 | m2_eb_occupd==441) & m2_eb_profplus==1
	
	replace empb01_eng1 = upper(empb01_eng1)
	gen		m2_eb_profplus_noshop4  = m2_eb_profplus
	replace m2_eb_profplus_noshop4  = 0 if (strpos(empb01_eng1,"TEA")>0 | strpos(empb01_eng1,"HAWKER")>0 | strpos(empb01_eng1,"BISCUIT")>0 | strpos(empb01_eng1,"BETEL")>0 | strpos(empb01_eng1,"BEGGER")>0 | strpos(empb01_eng1,"BEGGAR")>0) & m2_eb_profplus==1
	
	lab var m2_eb_prof_prim1 		"=1 if Professional and Salaried"
	lab var m2_eb_prof_prim34 		"=1 if Professional and Self-Employed or Family Business"
	lab var m2_eb_profplus_prim1 	"=1 if Prof Plus and Salaried"
	lab var m2_eb_profplus_prim34 	"=1 if Prof Plus and Self-Employed or Family Business"
	lab var m2_eb_profplus_noshop1  "=1 if Prof Plus but not Shop Worker (440)"
	lab var m2_eb_profplus_noshop2  "=1 if Prof Plus but not Small Shop Ownder (441)"
	lab var m2_eb_profplus_noshop3  "=1 if Prof Plus but not Shop Worker or Small Shop Ownder (440|441)"
	lab var m2_eb_profplus_noshop4  "=1 if Prof Plus but not Tea,Hawker,Biscuit,Betel,Beggar"
	
	recode m2_eb_occup_sec 	(1/3=1) (nonm=0), gen(m2_eb_prof_sec)
	recode m2_eb_occup_sec 	(1/4=1) (nonm=0), gen(m2_eb_profplus_sec)
	recode m2_eb_occup_sec 	(5=1)   (nonm=0), gen(m2_eb_ag_sec)
	recode m2_eb_occupd_sec	(513 514=1) (nonm=0), gen(m2_eb_livestock_sec)
	recode m2_eb_occupd_sec (511 512=1) (nonm=0), gen(m2_eb_crops_sec)
	recode m2_eb_occupd_sec (515 516=1) (nonm=0), gen(m2_eb_fish_sec)
	recode m2_eb_occup_sec 	(6/7=1) (nonm=0), gen(m2_eb_manual_sec)
	recode m2_eb_occup_sec 	(8=1)   (nonm=0), gen(m2_eb_elementary_sec)
	
	tab m2_eb_occup_sec m2_eb_prof_sec,m
	tab m2_eb_occup_sec m2_eb_manual_sec,m
	tab m2_eb_occup_sec m2_eb_elementary_sec,m
		
	lab var m2_eb_prof_sec 			"=1 if Manager, Professional or Assoc. Professional"
	lab var m2_eb_profplus_sec 		"=1 if Manager, (Assoc.) Professional or Clerical"
	lab var m2_eb_ag_sec			"=1 if Agriculture Occupation"
	lab var m2_eb_livestock_sec		"=1 if raising livestock occupation"
	lab var m2_eb_crops_sec			"=1 if farm occupation"
	lab var m2_eb_fish_sec			"=1 if fishery occupation"
	lab var m2_eb_manual_sec 		"=1 if Manual/Craft, or Machine/Factory/Assembler"
	lab var m2_eb_elementary_sec 	"=1 if Elementary Occupations"
	
	** Main Actiity
	forvalues i = 1(1)8{
		recode empb031_cl (`i'=1) (nonm=0), gen(m2_eb_act`i')
		tab empb031_cl m2_eb_act`i',m
	}
	
	lab var m2_eb_act1 "=1 if Salaried Worker"
	lab var m2_eb_act2 "=1 if Piece-Rate Worker"
	lab var m2_eb_act3 "=1 if Self-Employed"
	lab var m2_eb_act4 "=1 if Family Business Worker"
	lab var m2_eb_act5 "=1 if Agricultural Day Laborer"
	lab var m2_eb_act6 "=1 if Other Day Laborer"
	lab var m2_eb_act7 "=1 if Work on Family Farm"
	lab var m2_eb_act8 "=1 if Other Activity"
	
	recode empb031_cl (1 3/4=1) (nonm=0), gen(m2_eb_skill_act)
	recode empb031_cl (5 7=1)   (nonm=0), gen(m2_eb_ag_act)
	
	tab empb031_cl m2_eb_skill,m
	tab empb031_cl m2_eb_ag,m
		
	lab var m2_eb_skill_act "=1 if Salaried, Self-Employed, or Family Business (Main)"
	lab var m2_eb_ag_act 	"=1 if Agricultural Day Laborer or Work on Family Farm (Main)"
	
	** Secondary Activity
	* Do they have a secondary activitiy? (missing if also no Primary activity)
	gen m2_eb_havesecondary = .
		replace m2_eb_havesecondary = 0 if empb032_cl == . & empb031_cl != .
		replace m2_eb_havesecondary = 1 if empb032_cl != . & empb031_cl != .
		
	* Look at breakout by primary/secondary activity
	tab empb032_cl m2_eb_havesecondary,m
	* Look at empb02 for both if missing secondary and primary (only 4 problems)
	tab empb021 empb022 if m2_eb_havesecondary==.,m
	li emp?_book if empb021==. & empb022==. & m2_eb_havesecondary==.
	
	
	forvalues i = 1(1)8{
		recode empb032_cl (`i'=1) (nonm=0), gen(m2_eb_act`i'_sec)
		tab empb032_cl m2_eb_act`i'_sec,m
	}
	
	lab var m2_eb_havesecondary "=1 if have a secondary activity"
	lab var m2_eb_act1_sec 		"=1 if Salaried Worker"
	lab var m2_eb_act2_sec 		"=1 if Piece-Rate Worker"
	lab var m2_eb_act3_sec 		"=1 if Self-Employed"
	lab var m2_eb_act4_sec 		"=1 if Family Business Worker"
	lab var m2_eb_act5_sec 		"=1 if Agricultural Day Laborer"
	lab var m2_eb_act6_sec 		"=1 if Other Day Laborer"
	lab var m2_eb_act7_sec 		"=1 if Work on Family Farm"
	lab var m2_eb_act8_sec 		"=1 if Other Activity"
	
	recode empb032_cl (1 3/4=1) (nonm=0), gen(m2_eb_skill_act_sec)
	recode empb032_cl (5 7=1)   (nonm=0), gen(m2_eb_ag_act_sec)
	
	tab empb032_cl m2_eb_skill_act_sec,m
	tab empb032_cl m2_eb_ag_act_sec,m
		
	lab var m2_eb_skill_act_sec "=1 if Salaried, Self-Employed, or Family Business"	
	lab var m2_eb_ag_act_sec 	"=1 if Agricultural Day Laborer or Work on Family Farm"
	
	** Use the Activity to fill in the employer (CHECK ON THESE WITH TANIA)
	gen empb041_cl = empb041
		replace empb041_cl = 7 if empb031_cl == 3 // Self-Employed -> Works for Self
		replace empb041_cl = 7 if empb031_cl == 4 // Family Business -> Other household member
		replace empb041_cl = 8 if empb031_cl == 5 // Ag Day Laborer -> Other Indiv/Household
		replace empb041_cl = 8 if empb031_cl == 6 // Other Day Laborer -> Other Indiv/HH
		replace empb041_cl = 7 if empb031_cl == 7 // Farming/Livestock -> Self / Other HH member
		replace empb041_cl = 9 if empb031_cl == 8 // Other -> Other
	
	** Main Employer
	forvalues i = 1(1)9{
		recode empb041_cl (`i'=1) (nonm=0), gen(m2_eb_employer`i')
		tab empb041_cl m2_eb_employer`i',m
	}

	lab var m2_eb_employer1 "=1 if work for Government office/organization"
	lab var m2_eb_employer2 "=1 if work for Government factory/mill"
	lab var m2_eb_employer3 "=1 if work for Private office/organization"
	lab var m2_eb_employer4 "=1 if work for Private factory/mill"
	lab var m2_eb_employer5 "=1 if work for ICDDR,B"
	lab var m2_eb_employer6 "=1 if work for other NGO"
	lab var m2_eb_employer7 "=1 if work for Self or other household member"
	lab var m2_eb_employer8 "=1 if work for Other individual or household"
	lab var m2_eb_employer9 "=1 if work for Other"

	recode empb041_cl (1 2=1) (nonm=0), gen(m2_eb_govemployer)
	recode empb041_cl (3 4=1) (nonm=0), gen(m2_eb_privemployer)
	recode empb041_cl (5 6=1) (nonm=0), gen(m2_eb_ngoemployer)
	recode empb041_cl (7=0)   (nonm=1), gen(m2_eb_notselfemployer)
	
	tab empb041_cl m2_eb_govemployer,m
	tab empb041_cl m2_eb_privemployer,m
	tab empb041_cl m2_eb_ngoemployer,m
	tab empb041_cl m2_eb_notselfemployer,m
	
	lab var m2_eb_govemployer 		"=1 if work for Government"
	lab var m2_eb_privemployer 		"=1 if work for Private employer"
	lab var m2_eb_ngoemployer 		"=1 if work for NGO (incl. icddr,b)"
	lab var m2_eb_notselfemployer 	"=1 if work for someone else"
	
	// Won't do for secondary, there are only 161 with these values //

	** Skills
	
	
	
	recode empb051 (1 3=1) (nonm=0), gen(m2_eb_readwrite)
	recode empb051 (2 3=1) (nonm=0), gen(m2_eb_math)
	recode empb051 (1/3=1) (nonm=0), gen(m2_eb_readwriteormath)
	recode empb051 (3=1)   (nonm=0), gen(m2_eb_readwriteandmath)
	recode empb051 (4=1)   (nonm=0), gen(m2_eb_noreadwritemath)
	recode empb071 (1=1)   (nonm=0), gen(m2_eb_physical)
	
	foreach var in m2_eb_readwrite m2_eb_math m2_eb_physical m2_eb_readwriteormath m2_eb_readwriteandmath {
		replace `var' = 0 if empb021==1 | m2_eb_occup==9 // Set to 0 anyone that isn't working
	}
	
	** Fix for self-employed/family business/ag/other day laborer
	tab m2_eb_occupd empb051, row nofreq nol // Take the highest percentage as the answer for these other observations
	gen 	empb051_cl = empb051
	replace empb051_cl = 3 if empb051_cl==. & inlist(empb031,3,4,5,6,7) & inrange(m2_eb_occupd,100,420)
	replace empb051_cl = 4 if empb051_cl==. & inlist(empb031,3,4,5,6,7) & inrange(m2_eb_occupd,431,433)
	replace empb051_cl = 3 if empb051_cl==. & inlist(empb031,3,4,5,6,7) & inrange(m2_eb_occupd,434,435)
	replace empb051_cl = 4 if empb051_cl==. & inlist(empb031,3,4,5,6,7) & inrange(m2_eb_occupd,440,441)
	replace empb051_cl = 3 if empb051_cl==. & inlist(empb031,3,4,5,6,7) & inrange(m2_eb_occupd,442,442)
	replace empb051_cl = 4 if empb051_cl==. & inlist(empb031,3,4,5,6,7) & inrange(m2_eb_occupd,511,661)
	replace empb051_cl = 3 if empb051_cl==. & inlist(empb031,3,4,5,6,7) & inrange(m2_eb_occupd,662,670)
	replace empb051_cl = 3 if empb051_cl==. & inlist(empb031,3,4,5,6,7) & inrange(m2_eb_occupd,680,815)
	replace empb051_cl = 4 if empb051_cl==. & inlist(empb031,3,4,5,6,7) & inrange(m2_eb_occupd,680,815)
	replace empb051_cl = 3 if empb051_cl==. & inlist(empb031,3,4,5,6,7) & inrange(m2_eb_occupd,816,816)
	replace empb051_cl = 4 if empb051_cl==. & inlist(empb031,3,4,5,6,7) & inrange(m2_eb_occupd,820,890)
	
	recode empb051_cl (1 3=1) (nonm=0), gen(m2_eb_readwrite_cl)
	recode empb051_cl (2 3=1) (nonm=0), gen(m2_eb_math_cl)
	recode empb051_cl (1/3=1) (nonm=0), gen(m2_eb_readwriteormath_cl)
	recode empb051_cl (3=1)   (nonm=0), gen(m2_eb_readwriteandmath_cl)
	recode empb051_cl (4=1)   (nonm=0), gen(m2_eb_noreadwritemath_cl)
	
	foreach var in m2_eb_readwrite_cl m2_eb_math_cl m2_eb_readwriteormath_cl m2_eb_readwriteandmath_cl {
		replace `var' = 0 if empb021==1 | m2_eb_occup==9 // Set to 0 anyone that isn't working
	}
	
	lab var m2_eb_readwrite 		"=1 if job requires ability to Read and Write"
	lab var m2_eb_math			    "=1 if job requires ability to do Math"
	lab var m2_eb_readwriteormath	"=1 if job requires Reading/Writing and/or Math"
	lab var m2_eb_readwriteandmath 	"=1 if job requires Reading, Writing, and Math ability"
	lab var m2_eb_noreadwritemath	"=1 if no Reading, Writing, and Math ability needed"
	lab var m2_eb_physical 			"=1 if job requires the use of physical strength"
	
	lab var m2_eb_readwrite_cl 			"=1 if job requires ability to Read and Write"
	lab var m2_eb_math_cl			    "=1 if job requires ability to do Math"
	lab var m2_eb_readwriteormath_cl	"=1 if job requires Reading/Writing and/or Math"
	lab var m2_eb_readwriteandmath_cl 	"=1 if job requires Reading, Writing, and Math ability"
	lab var m2_eb_noreadwritemath_cl	"=1 if no Reading, Writing, and Math ability needed"
	
	** Education requirement
	recode empb061 (1=1) (nonm=0), gen(m2_eb_anyeduc)
	replace m2_eb_anyeduc = 0 if empb021==1 | m2_eb_occup==9
	
	tab empb061 m2_eb_anyeduc,m
	
	tab m2_eb_occupd empb061, row nofreq nol m
	
	gen 	empb061_cl = empb061
	replace empb061_cl = 1 if empb061_cl==. & inlist(empb031,3,4,5,6,7) & inrange(m2_eb_occupd,100,262)
	replace empb061_cl = 3 if empb061_cl==. & inlist(empb031,3,4,5,6,7) & inrange(m2_eb_occupd,263,263)
	replace empb061_cl = 1 if empb061_cl==. & inlist(empb031,3,4,5,6,7) & inrange(m2_eb_occupd,270,330)
	replace empb061_cl = 3 if empb061_cl==. & inlist(empb031,3,4,5,6,7) & inrange(m2_eb_occupd,341,341)
	replace empb061_cl = 1 if empb061_cl==. & inlist(empb031,3,4,5,6,7) & inrange(m2_eb_occupd,410,420)
	replace empb061_cl = 3 if empb061_cl==. & inlist(empb031,3,4,5,6,7) & inrange(m2_eb_occupd,430,433)
	replace empb061_cl = 1 if empb061_cl==. & inlist(empb031,3,4,5,6,7) & inrange(m2_eb_occupd,434,435)
	replace empb061_cl = 3 if empb061_cl==. & inlist(empb031,3,4,5,6,7) & inrange(m2_eb_occupd,440,441)
	replace empb061_cl = 1 if empb061_cl==. & inlist(empb031,3,4,5,6,7) & inrange(m2_eb_occupd,442,442)
	replace empb061_cl = 3 if empb061_cl==. & inlist(empb031,3,4,5,6,7) & inrange(m2_eb_occupd,511,661)
	replace empb061_cl = 1 if empb061_cl==. & inlist(empb031,3,4,5,6,7) & inrange(m2_eb_occupd,662,670)
	replace empb061_cl = 3 if empb061_cl==. & inlist(empb031,3,4,5,6,7) & inrange(m2_eb_occupd,680,815)
	replace empb061_cl = 1 if empb061_cl==. & inlist(empb031,3,4,5,6,7) & inrange(m2_eb_occupd,816,816)
	replace empb061_cl = 3 if empb061_cl==. & inlist(empb031,3,4,5,6,7) & inrange(m2_eb_occupd,820,890)
	
	recode empb061_cl (1=1) (nonm=0), gen(m2_eb_anyeduc_cl)
	replace m2_eb_anyeduc_cl = 0 if empb021==1 | m2_eb_occup==9
	// Where should I made cutoffs using the education codes? //
	
	lab var m2_eb_anyeduc 		"=1 if job requires any level of education"
	lab var m2_eb_anyeduc_cl	"=1 if job requires any level of education"

	** Experience
	tab empb08years1,m
	tab empb08months1,m // Some cases greater than 12
	
		* Replace months if greater than 11
		gen empb08months1_cl = empb08months1
		replace empb08months1_cl = . if empb08months1_cl>11
	
	* Make it using years+months and years|months
	gen empb08years_months = empb08years1*12
	
	egen m2_eb_exper1 		 = rowtotal(empb08years_months empb08months1_cl), missing 
	gen  m2_eb_exper2		 = empb08years_months
		replace m2_eb_exper2 = empb08months1_cl if m2_eb_exper2 == . | m2_eb_exper2 == 0
		
		* Check the correlation
		corr m2_eb_exper1 m2_eb_exper2 // 0.9999
	
	* Work in last 7 days?
	recode empb091 (1=1) (nonm=0), gen(m2_eb_work7day)
	
		tab empb091 m2_eb_work7day,m
	
	* Hours in one week
	tab empb10hours1 // A couple with high (worked every hour...) but 98% less than 100
	
	egen m2_eb_hrs_week = rowtotal(empb10hours1 empb10hours2),m
	
	lab var m2_eb_exper1 		"Experience at current occupation (Months):Years*12+Months"
	lab var m2_eb_exper2 		"Experience at current occupation (Months):Years*12 OR Months"
	lab var m2_eb_work7day 		"=1 if worked in past 7 days as occupation"
	lab var m2_eb_hrs_week		"Hours Worked in last 7 days worked, primary and secondary"
	
	** Earnings
	egen m2_eb_incweek 		= rowtotal(empb111 empb121) // NOTE: empb11 is already converted from the above code
	gen  m2_eb_lnincweek 	= ln(m2_eb_incweek)
	
	lab var m2_eb_incweek 		"Total earnings (cash&in-kind) past 7 days (Tk)"
	lab var m2_eb_lnincweek		"Ln Total earnings (cash&in-kind) past 7 days"
	
	** Travel Time
	gen m2_eb_traveltime = empb131 
	
	lab var m2_eb_traveltime "Travel Time to Job (Minutes)"
	
	** Job Outlook (SHOULD TALK ABOUT THESE)
	recode empb141 (1=1)   (nonm=0), gen(m2_eb_injob5year)
	recode empb151 (1/5=1) (nonm=0), gen(m2_eb_injob5year_pos)
	recode empb151 (6/8=1) (nonm=0), gen(m2_eb_injob5year_neg)
	
		tab empb141 m2_eb_injob5year,m
		tab empb151 m2_eb_injob5year_pos,m
		tab empb151 m2_eb_injob5year_neg,m
	
	lab var m2_eb_injob5year 		"=1 if expect to be in occupation in 5 years"
	lab var m2_eb_injob5year_pos 	"=1 if expect to retire or have better situation"
	lab var m2_eb_injob5year_neg 	"=1 if expect to be sick or not working for other negative reason"
	
*** EMPC OUTCOMES *** (only for salary / piece-rate)
	** Experience?
	recode empc02 (1=1) (nonm=0), gen(m2_ec_expreq)
	recode empc03 (1=1) (nonm=0), gen(m2_ec_evertrainee)
	recode empc04 (1=1) (nonm=0), gen(m2_ec_nowtrainee)
	
	replace empc04 = 0 if empc03 == 3 // Set to zero anyone who has never been a trainee
		
		tab empc02 m2_ec_expreq,m
		tab empc03 m2_ec_evertrainee,m
		tab empc04 m2_ec_nowtrainee,m
	
	lab var m2_ec_expreq		"=1 if prior experience required"
	lab var m2_ec_evertrainee 	"=1 if ever a trainee"
	lab var m2_ec_nowtrainee 	"=1 if currently a trainee"
	
	** Firm Size
	recode empc05 (1=1)   (nonm=0), gen(m2_ec_firmsize5)
	recode empc05 (1/2=1) (nonm=0), gen(m2_ec_firmsize20)
	recode empc05 (1/3=1) (nonm=0), gen(m2_ec_firmsize100)
	recode empc05 (1/4=1) (nonm=0), gen(m2_ec_firmsize1000)
	
	lab var m2_ec_firmsize5		"=1 if employer < 5 people"
	lab var m2_ec_firmsize20 	"=1 if employer < 20 people"
	lab var m2_ec_firmsize100 	"=1 if employer < 100 people"
	lab var m2_ec_firmsize1000 	"=1 if employer < 1000 people"
	
	** Contract
	recode empc06 (1=1)   (nonm=0), gen(m2_ec_permposition)
	recode empc06 (2=1)   (nonm=0), gen(m2_ec_fixposition)
	recode empc06 (1/3=1) (nonm=0), gen(m2_ec_writtencontract)
	recode empc06 (1/2=1) (nonm=0), gen(m2_ec_guarposition)
	recode empc06 (1/4=1) (nonm=0), gen(m2_ec_anycontract)
	
		tab empc06 m2_ec_permposition,m
		tab empc06 m2_ec_fixposition,m
		tab empc06 m2_ec_writtencontract,m
		tab empc06 m2_ec_guarposition,m
		tab empc06 m2_ec_anycontract,m
	
	lab var m2_ec_permposition 		"=1 if have written permanent contract (empc only)"
	lab var m2_ec_fixposition 		"=1 if have written fixed contract (empc only)"
	lab var m2_ec_writtencontract	"=1 if have any written contract (empc only)"
	lab var m2_ec_guarposition 		"=1 if permanent or fixed contract (empc only)"
	lab var m2_ec_anycontract		"=1 if written or verbal contract (empc only)"

	foreach var in permposition fixposition writtencontract guarposition anycontract {
		gen 	m2_ec_`var'_all = m2_ec_`var'
		replace m2_ec_`var'_all = 0				if m2_ec_`var' == .
	}
	
	lab var m2_ec_permposition_all 		"=1 if have written permanent contract (all emp)"
	lab var m2_ec_fixposition_all 		"=1 if have written fixed contract (all emp)"
	lab var m2_ec_writtencontract_all	"=1 if have any written contract (all emp)"
	lab var m2_ec_guarposition_all 		"=1 if permanent or fixed contract (all emp)"
	lab var m2_ec_anycontract_all		"=1 if written or verbal contract (all emp)"
	
	** Earnings
	gen m2_ec_incmonth_gross 	= empc07a
	gen m2_ec_lnincmonth_gross 	= ln(m2_ec_incmonth_gross)
	gen m2_ec_incmonth_net 		= empc07b
	gen m2_ec_lnincmonth_net 	= ln(m2_ec_incmonth_net)
	
	recode empc08b (1=1)   (nonm=0), gen(m2_ec_pension_deduct)
	*recode empc08b (2/3=1) (nonm=0), gen(m2_ec_pension_employer)
	
		tab empc08b m2_ec_pension_deduct,m
		*tab empc08b m2_ec_pension_employer,m
	
	lab var m2_ec_incmonth_gross 	"Gross Monthly Earnings (Tk)"
	lab var m2_ec_lnincmonth_gross 	"Ln Gross Monthly Earnings (Tk)"
	lab var m2_ec_incmonth_net 		"Net Monthly Earnings (Tk)"
	lab var m2_ec_lnincmonth_net 	"Ln Net Monthly Earnings (Tk)"
	lab var m2_ec_pension_deduct 	"=1 if have pension paid by salary"
	*lab var m2_ec_pension_employer 	"=1 if have pension paid by employer"

	** Benefits
	recode empc08a	(1=1) (nonm=0), gen(m2_ec_pension)
	recode empc09a 	(1=1) (nonm=0), gen(m2_ec_healthins)
	*recode empc09b	(1=1) (nonm=0), gen(m2_ec_loans)
	*recode empc09c 	(1=1) (nonm=0), gen(m2_ec_housing)
	*recode empc09d 	(1=1) (nonm=0), gen(m2_ec_transport)
	recode empc11	(1=1) (nonm=0), gen(m2_ec_advance)
	
	gen m2_ec_eidbonus	 = empc10
	
	** Union
	recode empc12	(1=1) (nonm=0), gen(m2_ec_haveunion)
	recode empc13	(1=1) (nonm=0), gen(m2_ec_inunion)
	
	replace m2_ec_inunion = 0 if m2_ec_haveunion == 0
	
	lab var m2_ec_pension		"=1 if have pension/retirement ins./provident fund"
	lab var	m2_ec_healthins		"=1 if job provides health insurance"
	*lab var m2_ec_loans			"=1 if job provides loans with no or low interest"
	*lab var m2_ec_housing		"=1 if job provides free or discounted housing"
	*lab var m2_ec_transport		"=1 if job provides transport"
	lab var m2_ec_advance		"=1 if can get an advance on salary"
	lab var m2_ec_haveunion		"=1 if there is a trade union or staff welfare association in job"
	lab var m2_ec_inunion		"=1 if in trade union or staff welfare association"
	
	
	gen m2_ec_present=empc01==1
	* These need to be run when in the emp cycle
	gen m2_ec_contract			=empc06<=2 
	gen m2_ec_written			=empc06<=3
	gen m2_ec_writtenverbal		=empc06<=4
	gen m2_ec_pension_any		=empc08a==1 
	gen m2_ec_pension_employer	=empc08b==2 | empc08b==3 
	gen m2_ec_health			=empc09a==1 
	gen m2_ec_loans				=empc09b==1 
	gen m2_ec_housing			=empc09c==1 
	gen m2_ec_transport			=empc09d==1 
	gen m2_ec_union_member		=empc13==1 

	gen m2_ec_benefits1_empconly 	= m2_ec_contract + m2_ec_pension_any + m2_ec_pension_employer + m2_ec_health + m2_ec_loans + m2_ec_housing + m2_ec_transport + m2_ec_union if m2_ec_present==1
	gen m2_ec_benefits1_all 		= m2_ec_contract + m2_ec_pension_any + m2_ec_pension_employer + m2_ec_health + m2_ec_loans + m2_ec_housing + m2_ec_transport + m2_ec_union
	
	recode m2_ec_benefits1_empconly (0=0) (nonm=1), gen(m2_ec_benf1_empconly)
	recode m2_ec_benefits1_all		(0=0) (nonm=1), gen(m2_ec_benf1_all)
	
	gen m2_ec_benefits2_empconly 	= m2_ec_contract + m2_ec_pension_any + m2_ec_pension_employer + m2_ec_health + m2_ec_loans + m2_ec_transport + m2_ec_union if m2_ec_present==1
	gen m2_ec_benefits2_all 		= m2_ec_contract + m2_ec_pension_any + m2_ec_pension_employer + m2_ec_health + m2_ec_loans + m2_ec_transport + m2_ec_union
	
	recode m2_ec_benefits2_empconly (0=0) (nonm=1), gen(m2_ec_benf2_empconly)
	recode m2_ec_benefits2_all		(0=0) (nonm=1), gen(m2_ec_benf2_all)
	
	
	gen m2_ec_benefits3_empconly 	= m2_ec_written + m2_ec_pension_any + m2_ec_pension_employer + m2_ec_health + m2_ec_loans + m2_ec_housing + m2_ec_transport + m2_ec_union if m2_ec_present==1
	gen m2_ec_benefits3_all 		= m2_ec_written + m2_ec_pension_any + m2_ec_pension_employer + m2_ec_health + m2_ec_loans + m2_ec_housing + m2_ec_transport + m2_ec_union
	
	recode m2_ec_benefits3_empconly (0=0) (nonm=1), gen(m2_ec_benf3_empconly)
	recode m2_ec_benefits3_all		(0=0) (nonm=1), gen(m2_ec_benf3_all)
	
	gen m2_ec_benefits4_empconly 	= m2_ec_writtenverbal + m2_ec_pension_any + m2_ec_pension_employer + m2_ec_health + m2_ec_loans + m2_ec_housing + m2_ec_transport + m2_ec_union if m2_ec_present==1
	gen m2_ec_benefits4_all 		= m2_ec_writtenverbal + m2_ec_pension_any + m2_ec_pension_employer + m2_ec_health + m2_ec_loans + m2_ec_housing + m2_ec_transport + m2_ec_union
	
	recode m2_ec_benefits4_empconly (0=0) (nonm=1), gen(m2_ec_benf4_empconly)
	recode m2_ec_benefits4_all		(0=0) (nonm=1), gen(m2_ec_benf4_all)
	
	gen m2_ec_fixpenshlth_empconly 		= m2_ec_contract + m2_ec_pension_any + m2_ec_pension_employer + m2_ec_health if m2_ec_present==1
	gen m2_ec_fixpenshlth_all 	 		= m2_ec_contract + m2_ec_pension_any + m2_ec_pension_employer + m2_ec_health
	
	gen m2_ec_writpenshlth_empconly 	= m2_ec_written + m2_ec_pension_any + m2_ec_pension_employer + m2_ec_health if m2_ec_present==1
	gen m2_ec_writpenshlth_all 	 		= m2_ec_written + m2_ec_pension_any + m2_ec_pension_employer + m2_ec_health
	
	gen m2_ec_writverbpenshlth_empconly = m2_ec_writtenverbal + m2_ec_pension_any + m2_ec_pension_employer + m2_ec_health if m2_ec_present==1
	gen m2_ec_writverbpenshlth_all 	 	= m2_ec_writtenverbal + m2_ec_pension_any + m2_ec_pension_employer + m2_ec_health
	
*** EMPD OUTCOMES ***
	* Number of businesses
	gen m2_ed_bizct = empd02
	label var m2_ed_bizct "Number of businesses owned/worked for in past 12 mos."
	
	gen m2_ed_isiccode_main = empd04b1
	gen m2_ed_isiccode_sec  = empd04b2
	
	label define isic_lbl 	1 "Crop and animal production, hunting and related service activities" ///
							2 "Forestry and logging" ///
							3 "Fishing and aquaculture" ///
							5 "Mining of coal and lignite" ///
							6 "Extraction of crude petroleum and natural gas" ///
							7 "Mining of metal ores" ///
							8 "Other mining and quarrying" ///
							9 "Mining support service activities" ///
							10 "Mfr. of food products" ///
							11 "Mfr. of beverages" ///
							12 "Mfr. of tobacco products" ///
							13 "Mfr. of textiles" ///
							14 "Mfr. of wearing apparel" ///
							15 "Mfr. of leather and related products" ///
							16 "Mfr. of wood and of products of wood and cork, except furniture; Mfr. of articles of straw and plaiting materials" ///
							17 "Mfr. of paper and paper products" ///
							18 "Printing and reproduction of recorded media" ///
							19 "Mfr. of coke and refined petroleum products" ///
							20 "Mfr. of chemicals and chemical products" ///
							21 "Mfr. of basic pharmaceutical products and pharmaceutical preparations" ///
							22 "Mfr. of rubber and plastics products" ///
							23 "Mfr. of other non-metallic mineral products" ///
							24 "Mfr. of basic metals" ///
							25 "Mfr. of fabricated metal products, except machinery and equipment" ///
							26 "Mfr. of computer, electronic and optical products" ///
							27 "Mfr. of electrical equipment" ///
							28 "Mfr. of machinery and equipment n.e.c." ///
							29 "Mfr. of motor vehicles, trailers and semi-trailers" ///
							30 "Mfr. of other transport equipment" ///
							31 "Mfr. of furniture" ///
							32 "Other manufacturing" ///
							33 "Repair and installation of machinery and equipment" ///
							35 "Electricity, gas, steam and air conditioning supply" ///
							36 "Water collection, treatment and supply" ///
							37 "Sewerage" ///
							38 "Waste collection, treatment and disposal activities; materials recovery" ///
							39 "Remediation activities and other waste management services" ///
							41 "Construction of buildings" ///
							42 "Civil engineering" ///
							43 "Specialized construction activities" ///
							45 "Wholesale and retail trade and repair of motor vehicles and motorcycles" ///
							46 "Wholesale trade, except of motor vehicles and motorcycles" ///
							47 "Retail trade, except of motor vehicles and motorcycles" ///
							49 "Land transport and transport via pipelines" ///
							50 "Water transport" ///
							51 "Air transport" ///
							52 "Warehousing and support activities for transportation" ///
							53 "Postal and courier activities" ///
							55 "Accommodation" ///
							56 "Food and beverage service activities" ///
							58 "Publishing activities" ///
							59 "Motion picture, video and television programme production, sound recording and music publishing activities" ///
							60 "Programming and broadcasting activities" ///
							61 "Telecommunications" ///
							62 "Computer programming, consultancy and related activities" ///
							63 "Information service activities" ///
							64 "Financial service activities, except insurance and pension funding" ///
							65 "Insurance, reinsurance and pension funding, except compulsory social security" ///
							66 "Activities auxiliary to financial service and insurance activities" ///
							68 "Real estate activities" ///
							69 "Legal and accounting activities" ///
							70 "Activities of head offices; management consultancy activities" ///
							71 "Architectural and engineering activities; technical testing and analysis" ///
							72 "Scientific research and development" ///
							73 "Advertising and market research" ///
							74 "Other professional, scientific and technical activities" ///
							75 "Veterinary activities" ///
							77 "Rental and leasing activities" ///
							78 "Employment activities" ///
							79 "Travel agency, tour operator, reservation service and related activities" ///
							80 "Security and investigation activities" ///
							81 "Services to buildings and landscape activities" ///
							82 "Office administrative, office support and other business support activities" ///
							85 "Education" ///
							86 "Human health activities" ///
							87 "Residential care activities" ///
							88 "Social work activities without accommodation" ///
							90 "Creative, arts and entertainment activities" ///
							91 "Libraries, archives, museums and other cultural activities" ///
							92 "Gambling and betting activities" ///
							93 "Sports activities and amusement and recreation activities" ///
							95 "Repair of computers and personal and household goods" ///
							96 "Other personal service activities" ///
							97 "Activities of households as employers of domestic personnel" ///
							98 "Undifferentiated goods- and services-producing activities of private households for own use"
	label values m2_ed_isiccode_main isic_lbl
	label values m2_ed_isiccode_sec isic_lbl
	
	* There are a number of ISIC codes out of range of listed code in book.  It seems the 3 digit codes matchup with Occupation Codes and not ISIC codes
	li m2_ed_isiccode_main empd04a_eng1 if inlist(m2_ed_isiccode_main,270,441,447,511,512,513,514,515,516,517)
	** COULD CLEAN THESE ISIC Codes
	
	* Business Ownership
	recode empd05b1 (1/3=1) (nonm=0), gen(m2_ed_ownerany)
	recode empd05b1 (1=1) (nonm=0), gen(m2_ed_ownersolo)
	recode empd05b1 (1/2=1) (nonm=0), gen(m2_ed_ownerhh)
	
	label var m2_ed_ownerany 	"=1 if main business owned by self alone or with another person"
	label var m2_ed_ownersolo 	"=1 if main business owned by self alone"
	label var m2_ed_ownerhh 	"=1 if main business owned by self alone or with another householder"
	
	
	
	* Whether or not the business was started or inherited
	recode empd10b1 (1=1) (nonm=0), gen(m2_ed_startalone)
	recode empd10b1 (2=1) (nonm=0), gen(m2_ed_startwith)
	recode empd10b1 (3=1) (nonm=0), gen(m2_ed_inherited)
	recode empd10b1 (4=1) (nonm=0), gen(m2_ed_purchased)
	recode empd10b1 (1/2=1) (nonm=0), gen(m2_ed_startalonewith)
	recode empd10b1 (1 2 4=1) (nonm=0), gen(m2_ed_startpurchase)
	
	label var m2_ed_startalone 		"=1 if started main business alone"
	label var m2_ed_startwith 		"=1 if started main business with business partner"
	label var m2_ed_inherited 		"=1 if inherited or given main business"
	label var m2_ed_purchased 		"=1 if puchased main business"
	label var m2_ed_startalonewith 	"=1 if started main business alone or with business partner"
	label var m2_ed_startpurchase	"=1 if started main business alone, w/ partner, or purchased"
	
	* Code up ownership and starting business for everyone (not just empd folks)
	gen 	m2_ed_startbiz_all = m2_ed_startpurchase
	replace m2_ed_startbiz_all = 0 if m2_ed_startbiz_all == .
	
	gen 	m2_ed_bizowner_all = m2_ed_ownerany
	replace m2_ed_bizowner_all = 0 if m2_ed_bizowner_all == .
	
	label var m2_ed_startbiz_all "=1 if started a business"
	label var m2_ed_bizowner_all "=1 if a business owner"
	
	** Calculate age of business
		* Bring in book completion date
		mmerge vill_id hhold_id line_no using "P:\pop\BANGLADESH_PROJECT\MHSS2\Analysis Files\Data\Migrant\indiv_control.dta", ukeep(self_bk35date)
			drop if _merge == 2
			drop _merge
		
		gen 	m2_ed_bizstartyear = empd101
		gen		m2_ed_bizage = year(self_bk35date) - m2_ed_bizstartyear 

		tab m2_ed_bizage // Should check how realistic these ages are...
	
	* Business location
	recode empd111 (1=1) (3=0), gen(m2_ed_homebusiness)
	
	label var m2_ed_homebusiness "=1 if business activities occur at home"
	
	* Financial Instruments
	recode empd121 (1=1) (3=0), gen(m2_ed_bankaccount)
	recode empd131 (1=1) (3=0), gen(m2_ed_accounting)
	
	label var m2_ed_homebusiness "=1 if have bank or savings account for business"
	label var m2_ed_accounting "=1 if detailed accounts are kept of business (e.g., balance sheet)"
	
	** Firm Size
	foreach i in 5 20 100 1000 {
		gen		m2_ed_firmsize`i' = .
		replace m2_ed_firmsize`i' = 0 if empd161!=.
		replace m2_ed_firmsize`i' = 1 if empd161<`i'
		
		lab var m2_ed_firmsize`i' "=1 if employer < `i' people"
		
		gen 	m2_ecd_firmsize`i' = m2_ec_firmsize`i'
		replace m2_ecd_firmsize`i' = m2_ed_firmsize`i' if m2_ecd_firmsize`i' == .
		
		lab var m2_ecd_firmsize`i' "=1 if employer < `i' people"
	}
	
*** EMPE OUTCOMES ***
*** Create outcomes for each year
	forvalues i = 2002/2011{
		if `i' == 2002 | `i' == 2007 | `i' == 2011{
		** Activities
			* Participation
			gen m2_ee_participate`i'	= empe01_cl`i'
			gen m2_ee_actcount`i' 		= empe02_tot`i'
			
			lab var m2_ee_participate`i'	"=1 if worked atleast 20 days in `i'"
			lab var m2_ee_actcount`i' 		"Total Number of Activities in `i'"
			
			* If participate, were in activity j
			local k = 1
			
			foreach j in a b c d e f g h {
				disp `k'
				gen m2_ee_act`k'`i'			= .
					replace m2_ee_act`k'`i'	= 0 if empe02`j'`i' == . & empe01_cl`i' == 1
					replace m2_ee_act`k'`i' = 1 if empe02`j'`i' == 1 & empe01_cl`i' == 1
				tab empe01`i' m2_ee_act`k'`i',m
				
				local k = `k' + 1
			} 
			
			lab var m2_ee_act1`i' "=1 if Salaried Worker in `i'"
			lab var m2_ee_act2`i' "=1 if Piece-Rate Worker in `i'"
			lab var m2_ee_act3`i' "=1 if Self-Employed in `i'"
			lab var m2_ee_act4`i' "=1 if Family Business Worker in `i'"
			lab var m2_ee_act5`i' "=1 if Agricultural Day Laborer in `i'"
			lab var m2_ee_act6`i' "=1 if Other Day Laborer in `i'"
			lab var m2_ee_act7`i' "=1 if Work on Family Farm in `i'"
			lab var m2_ee_act8`i' "=1 if Other Activity in `i'"
			

			* Was activity j your main activity
			forvalues j = 1(1)8{			
				recode empe03`i' (`j'=1) (nonm=0), gen(m2_ee_primact`j'`i')
				tab empe03`i' m2_ee_primact`j'`i',m
			}
			
			lab var m2_ee_primact1`i' "=1 if Salaried Worker in `i', primary"
			lab var m2_ee_primact2`i' "=1 if Piece-Rate Worker in `i', primary"
			lab var m2_ee_primact3`i' "=1 if Self-Employed in `i', primary"
			lab var m2_ee_primact4`i' "=1 if Family Business Worker in `i', primary"
			lab var m2_ee_primact5`i' "=1 if Agricultural Day Laborer in `i', primary"
			lab var m2_ee_primact6`i' "=1 if Other Day Laborer in `i', primary"
			lab var m2_ee_primact7`i' "=1 if Work on Family Farm in `i', primary"
			lab var m2_ee_primact8`i' "=1 if Other Activity in `i', primary"
			
			recode empe03`i' (1 3/4=1) (nonm=0), gen(m2_ee_skill`i') // uses main activity
			recode empe03`i' (5 7 =1)  (nonm=0), gen(m2_ee_ag`i') // uses main activity
			
			replace m2_ee_skill`i' = 0 if empe01_cl`i' == 0 & m2_ee_skill`i' == .
			replace m2_ee_ag`i'    = 0 if empe01_cl`i' == 0 & m2_ee_ag`i' == .
			
			lab var m2_ee_skill`i'			"=1 if Salaried, Self-Employed, or Family Business in `i'"
			lab var m2_ee_ag`i'				"=1 if Agricultural Day Laborer or Work on Family Farm in `i'"
			
		** Occupation
			* Label the variables
			gen m2_ee_occupd`i'			= empe04`i'
			gen m2_ee_occup`i'			= . // Should revisit these groupings...
				replace m2_ee_occup`i' 	= 0 if inlist(m2_ee_occupd`i',100) 
				replace m2_ee_occup`i' 	= 1 if inlist(m2_ee_occupd`i',110,111,120,130)
				replace m2_ee_occup`i' 	= 2 if inlist(m2_ee_occupd`i',210,221,222,223,224,231,232,233,234,241,261,262,263,270)
				replace m2_ee_occup`i' 	= 3 if inlist(m2_ee_occupd`i',310,320,330,341)
				replace m2_ee_occup`i' 	= 4 if inlist(m2_ee_occupd`i',410,420,431,432,433,434,435,440,441,442)
				replace m2_ee_occup`i' 	= 5 if inlist(m2_ee_occupd`i',511,512,513,514,515,516,517)
				replace m2_ee_occup`i' 	= 6 if inlist(m2_ee_occupd`i',611,612,621,622,623,630,640,650,651,652,652,660,661,662,663,670,680)
				replace m2_ee_occup`i' 	= 7 if inlist(m2_ee_occupd`i',711,712,713,714,715,730,731,732)
				replace m2_ee_occup`i' 	= 8 if inlist(m2_ee_occupd`i',811,812,813,814,815,816,820,821,822,830,840,860,870,880,890)
				replace m2_ee_occup`i'	= 9 if inlist(m2_ee_occupd`i',920,930,940,950,960,970,971)
				
			lab values m2_ee_occupd`i'	occupd_lbl	
			lab values m2_ee_occup`i' 	gen_occup_lbl
			
			lab var m2_ee_occupd`i' "Detailed Occupation Code in `i'"
			lab var m2_ee_occup`i'	"General Occupation Code in `i'"
			
			* Create Occupation Groupings
			recode m2_ee_occup`i' (1/3=1) (nonm=0), gen(m2_ee_prof`i')
			recode m2_ee_occup`i' (5/7=1) (nonm=0), gen(m2_ee_manual`i')
			recode m2_ee_occup`i' (8=1)   (nonm=0), gen(m2_ee_elementary`i')
			
			tab m2_ee_occup`i' m2_ee_prof`i',m
			tab m2_ee_occup`i' m2_ee_manual`i',m
			tab m2_ee_occup`i' m2_ee_elementary`i',m
			
			lab var m2_ee_prof`i' 		"=1 if Manager, Professional or Assoc. Professional in `i'"
			lab var m2_ee_manual`i'		"=1 if Skilled Ag, Manual/Craft, or Machine/Factory/Assembler `i'"
			lab var m2_ee_elementary`i' "=1 if Elementary Occupations `i'"
			
		** Labor Supply
			* Hours worked
			gen m2_ee_hrs_tot`i' = empe05weeks_cl`i' * empe05hours_cl`i'
			
			lab var m2_ee_hrs_tot`i' "Annual Hours Worked, primary activity"
			
			* Earnings
			// NOTE: These are equivalent to the primary activity earnings from EMPA (not total earnings) SEE QUESTION WORDING //
			gen m2_ee_incyear`i' 	= empe06_cl`i' // Phone Survey converted above...
			gen m2_ee_lnincyear`i'	= ln(m2_ee_incyear`i')
			gen m2_ee_incweek`i'	= m2_ee_incyear`i' / empe05weeks_cl`i'
			gen m2_ee_lnincweek`i'	= ln(m2_ee_incweek`i')
			gen m2_ee_inchour`i'	= m2_ee_incyear`i' / m2_ee_hrs_tot`i'
			gen m2_ee_lninchour`i'	= ln(m2_ee_inchour`i')
			
			lab var m2_ee_incyear`i' 	"Annual Earnings (Tk) in `i', primary activity"
			lab var m2_ee_lnincyear`i' 	"Ln Annual Earnings (Tk) in `i', primary activity"
			lab var m2_ee_incweek`i'	"Weekly Earnings (Tk) in `i', primary activity"
			lab var m2_ee_lnincweek`i'	"Ln Weekly Earnings (Tk) in `i', primary activity"
			lab var m2_ee_inchour`i'	"Hourly Earnings (Tk) in `i', primary activity"
			lab var m2_ee_lninchour`i'	"Ln Hourly Earnings (Tk) in `i', primary activity"
		}
	}

	** Look for miscoded occupations
	tab empe042002 if m2_ee_occupd2002!=. & m2_ee_occup2002==. // 25 Cases
	li empe042002 empe04name2002 if m2_ee_occupd2002!=. & m2_ee_occup2002==.
	
	tab empe042007 if m2_ee_occupd2007!=. & m2_ee_occup2007==. // 31 Cases
	li empe042007 empe04name2007 if m2_ee_occupd2007!=. & m2_ee_occup2007==.
	
	tab empe042011 if m2_ee_occupd2011!=. & m2_ee_occup2011==. // 40 Cases
	li empe042011 empe04name2011 if m2_ee_occupd2011!=. & m2_ee_occup2011==.
	
	// NEED TO FIX THESE //
	
	** Best Earnings (looking at primary activity)
	egen m2_best_incyear	= rowmax(m2_ea_incyear_prim m2_ee_incyear*)
	egen m2_best_incweek	= rowmax(m2_ea_incweek_prim m2_ee_incweek*)
	egen m2_best_inchour	= rowmax(m2_ea_inchour_prim m2_ee_inchour*)
	egen m2_avg_incyear		= rowmean(m2_ea_incyearHH m2_ee_incyear*)
	
	gen m2_best_lnincyear	= ln(m2_best_incyear)
	gen m2_best_lnincweek	= ln(m2_best_incweek)
	gen m2_best_lninchour 	= ln(m2_best_inchour)
	
	gen m2_incyear_growing	= .
		replace m2_incyear_growing = 0 if m2_best_incyear!=m2_ea_incyear_prim & m2_best_incyear!=.
		replace m2_incyear_growing = 1 if m2_best_incyear==m2_ea_incyear_prim & m2_best_incyear!=.
	
	gen m2_incweek_growing	= .
		replace m2_incweek_growing = 0 if m2_best_incweek!=m2_ea_incweek_prim & m2_best_incweek!=.
		replace m2_incweek_growing = 1 if m2_best_incweek==m2_ea_incweek_prim & m2_best_incweek!=.
		
	gen m2_inchour_growing	= .
		replace m2_inchour_growing = 0 if m2_best_inchour!=m2_ea_inchour_prim & m2_best_inchour!=.
		replace m2_inchour_growing = 1 if m2_best_inchour==m2_ea_inchour_prim & m2_best_inchour!=.
		
		tab m2_incyear_growing,m
		tab m2_incweek_growing,m
		tab m2_inchour_growing,m
		
		corr m2_incyear_growing m2_incweek_growing m2_inchour_growing
		
	lab var m2_best_incyear		"Highest Annual Earnings 2002-present (Tk), primary activity"
	lab var m2_best_incweek		"Highest Weekly Earnings 2002-present (Tk), primary activity"
	lab var m2_best_inchour		"Highest Hourly Earnings 2002-present (Tk), primary activity"
	lab var m2_incyear_growing	"=1 if Current Annual Earnings >= Earlier Annual Earnings"
	lab var m2_incweek_growing	"=1 if Current Weekly Earnings >= Earlier Weekly Earnings"
	lab var m2_inchour_growing	"=1 if Current Hourly Earnings >= Earlier Hourly Earnings"
		
	** Most hours worked
	egen m2_most_hrs_tot = rowmax(m2_ea_hrs_tot_prim m2_ee_hrs_tot*)
	
	gen m2_hrs_tot_growing = .
		replace m2_hrs_tot_growing = 0 if m2_most_hrs_tot!=m2_ea_hrs_tot_prim & m2_most_hrs_tot!=.
		replace m2_hrs_tot_growing = 1 if m2_most_hrs_tot==m2_ea_hrs_tot_prim & m2_most_hrs_tot!=.
		
	lab var m2_most_hrs_tot 	"Most Annual Hours Worked 2002-present, primary activity"
	lab var m2_hrs_tot_growing 	"=1 if if Current Annual Hours >= Earlier Annual Hours"
		
	** Earnings Growth
	* Bring in date survey was completed
	mmerge vill_id hhold_id line_no using "P:\pop\BANGLADESH_PROJECT\MHSS2\Analysis Files\Data\Migrant\indiv_control.dta", ///
		ukeep(self_bk35date) missing(nomatch) type(1:1)
		drop if _merge == 2 | _merge == -2
	
	* Find the first year of income we have for a person
	gen m2_first_incyear_yr 			= .
		replace m2_first_incyear_yr 	= 2002 				if m2_ee_incyear2002!=. & m2_ee_incyear2002!=0 & m2_first_incyear_yr == .
		replace m2_first_incyear_yr 	= 2007 				if m2_ee_incyear2007!=. & m2_ee_incyear2007!=0 & m2_first_incyear_yr == .
		replace m2_first_incyear_yr 	= 2011 				if m2_ee_incyear2011!=. & m2_ee_incyear2011!=0 & m2_first_incyear_yr == .
		replace m2_first_incyear_yr		= year(self_bk35date) 	if m2_ea_incyear!=. 	& m2_first_incyear_yr == .
		
		tab m2_first_incyear_yr, m
		
	* Create variable with the person's first year of income
	gen m2_first_incyear				= .
		replace m2_first_incyear		= m2_ee_incyear2002 if m2_first_incyear_yr == 2002
		replace m2_first_incyear		= m2_ee_incyear2007 if m2_first_incyear_yr == 2007
		replace m2_first_incyear		= m2_ee_incyear2011 if m2_first_incyear_yr == 2011
		replace m2_first_incyear		= m2_ea_incyear 	if m2_first_incyear_yr == year(self_bk35date)
		
	* Calculate Compound Annual Growth Rate from first year to current year
	gen m2_diff_year	= year(self_bk35date) - m2_first_incyear_yr
	gen m2_cagr_incyear = (m2_ea_incyear/m2_first_incyear)^(1/m2_diff_year)-1
	
		sum m2_cagr_incyear if m2_first_incyear_yr<year(self_bk35date),d 
	
	lab var m2_first_incyear_yr 	"First year of Annual Earnings data"
	lab var m2_first_incyear		"Annual Earnings (Tk) from first year of data available"
	lab var m2_diff_year			"Years since first year of Annual Earnings data to present"
	lab var m2_cagr_incyear			"Compound Annual Growth Rate - Annual Earnings, first year to present"
	
	sum m2_ee_participate* m2_ee_incyear* m2_ee_hrs_tot* m2_ee_skill* m2_ee_ag* line_no 
	sum m2_ee_participate* m2_ee_incyear* m2_ee_hrs_tot* m2_ee_skill* m2_ee_ag* line_no if empe00==3
	

*** EMPF OUTCOMES ***

*** Save a file with outcomes
gen m2_ea_proxy = (empa00==1)
gen m2_ec_proxy = (empc00==1)
gen m2_ee_proxy = (empe00==1)
		
order vill_id hhold_id line_no phone_survey ///
		$m2_ea_outcomes $m2_eb_outcomes $m2_ee_outcomes $m2_outcomes ///
		m2_ea_* m2_eb_* m2_ec_* m2_ee_* m2_*
	
	
sum m2_ea_participate* m2_ea_incyear* m2_ea_tempmig line_no if empa00 == 0
sum m2_ee_participate* m2_ee_incyear* m2_ee_hrs_tot* m2_ee_skill* m2_ee_ag* line_no if empe00==3


	
save "P:\pop\BANGLADESH_PROJECT\MHSS2\Analysis Files\Data\Migrant\MHSS2_employment.dta", replace

cap log close
