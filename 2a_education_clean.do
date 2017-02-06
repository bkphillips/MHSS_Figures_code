

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
	li empe01 empe01_cl empe05* empe06 source if empe01!=empe01_cl
	
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
	4) I apply the annual average to all of our data (I also recorded the periodӳ high and low in case we wanted to use)

	FOR MORE INFORMATION SEE "${made}../historical_forex_rates.xlsx" for a README page
	*/
	
	tab empe06_ctry empe06_ctrycd,m
	
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
		
		export excel using "${m2_made}/historical_forex.xlsx", firstrow(var) replace
	restore
	
	** Merge in file with historical exchange rates
	mmerge empe06_ctrycd year_em using "${m2_made}/historical_forex_rates.dta", ///
		missing(nomatch) ukeep(average) 
		drop if _merge == 2 | _merge == -2
		
		tab empe01 _merge if source == 2 // All phone survey have rates brought in if needed
	
	** Conversion Here
	gen empe06_phone = empe06 if source == 2
	replace empe06 = empe06 * average if source == 2 & average!=.
	
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
		  
	bys vill_id hhold_id line_no source year_em: drop if _n > 1 // Somehow a duplicate was entered
 
	reshape wide empe01-empe07_ctry empe_answer02 empe02_tot empe06_phone, i(vill_id hhold_id line_no source) j(year_em)
	drop hhid_renum old_hhid use_books
	
	order vill_id hhold_id line_no source empe00
	
	
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
	mmerge vill_id hhold_id line_no source using "${dataclean_made}book_status.dta", ///
		ukeep(bk35date) missing(nomatch) type(1:1)
		drop if _merge == 2 | _merge == -2
	
	* Find the first year of income we have for a person
	gen m2_first_incyear_yr 			= .
		replace m2_first_incyear_yr 	= 2002 				if m2_ee_incyear2002!=. & m2_ee_incyear2002!=0 & m2_first_incyear_yr == .
		replace m2_first_incyear_yr 	= 2007 				if m2_ee_incyear2007!=. & m2_ee_incyear2007!=0 & m2_first_incyear_yr == .
		replace m2_first_incyear_yr 	= 2011 				if m2_ee_incyear2011!=. & m2_ee_incyear2011!=0 & m2_first_incyear_yr == .
		replace m2_first_incyear_yr		= year(bk35date) 	if m2_ea_incyear!=. 	& m2_first_incyear_yr == .
		
		tab m2_first_incyear_yr, m
		
	* Create variable with the person's first year of income
	gen m2_first_incyear				= .
		replace m2_first_incyear		= m2_ee_incyear2002 if m2_first_incyear_yr == 2002
		replace m2_first_incyear		= m2_ee_incyear2007 if m2_first_incyear_yr == 2007
		replace m2_first_incyear		= m2_ee_incyear2011 if m2_first_incyear_yr == 2011
		replace m2_first_incyear		= m2_ea_incyear 	if m2_first_incyear_yr == year(bk35date)
		
	* Calculate Compound Annual Growth Rate from first year to current year
	gen m2_diff_year	= year(bk35date) - m2_first_incyear_yr
	gen m2_cagr_incyear = (m2_ea_incyear/m2_first_incyear)^(1/m2_diff_year)-1
	
		sum m2_cagr_incyear if m2_first_incyear_yr<year(bk35date),d 
	
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
		
order vill_id hhold_id line_no source ///
		$m2_ea_outcomes $m2_eb_outcomes $m2_ee_outcomes $m2_outcomes ///
		m2_ea_* m2_eb_* m2_ec_* m2_ee_* m2_*
	
	
sum m2_ea_participate* m2_ea_incyear* m2_ea_tempmig line_no if empa00 == 0
sum m2_ee_participate* m2_ee_incyear* m2_ee_hrs_tot* m2_ee_skill* m2_ee_ag* line_no if empe00==3
	
save "${m2_made}MHSS2_employment.dta", replace

cap log close
