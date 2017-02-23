
// EMPE Employment data /////////////////////////////////////////////////////////////////
// 1. Hours Worked
/*
// Pull in Data. (change filepath to P drive once done)
use "P:\pop\BANGLADESH_PROJECT\MHSS2\Analysis Files\Data\Migrant\MHSS2_employment.dta", clear 

// keeping relevant variables
keep vill_id hhold_id line_no year_em empe05weeks empe05hours phone_survey

// Categorize individuals by migrant status for grouping
gen village = substr(vill_id,1,1)
gen internal_mig = 0 
replace internal_mig = 1 if village == "Y"

gen international_mig = village <= "9"

gen international_phone = international_mig & phone == 1

gen international_inperson = international_mig & phone==0

gen non_mig = village == "I" | village == "J"

gen mig_status = 0 if non_mig
replace mig_status = 1 if internal_mig
replace mig_status = 2 if international_phone 
replace mig_status = 3 if international_inperson

drop village

// Logic checks of hours and weeks
replace empe05weeks = . if empe05weeks > 52
replace empe05hours = . if empe05hours > 168

// accounting for missing values (making total hours missing if weeks or hours is missing)
gen hours_worked = empe05weeks * empe05hours
replace hours_worked = . if empe05weeks == . | empe05hours == .
gen missing = 0
replace missing = 1 if empe05weeks == . | empe05hours == .
replace hours_worked = . if missing != 0

// creating hours worked per week
gen hours_worked_per_week = hours_worked / 52

tempfile avg_hours_worked
save `avg_hours_worked', replace

// local list of years
local year_list 2002 2007 2011

// HISTOGRAMS of Hours Worked per Week
// For Each Year
foreach year of local year_list {
//All Groups
	histogram hours_worked_per_week if year_em == `year', title("Hours Worked for All Individuals, Year `year'")
	graph export "C:/Users/phill/Box Sync/MHSS/3_figures/hours_worked_per_week/histograms/hist_all_`year'.png", width(3000) replace
// By Migrant Status
	forvalues i=0/3 {
		histogram hours_worked_per_week if mig_status == `i' & year_em == `year', title("Hours Worked for Migrant Group `i', Year `year'")
		graph export "C:/Users/phill/Box Sync/MHSS/3_figures/hours_worked_per_week/histograms/hist_mig_stat_`i'_`year'.png", width(3000) replace
	}
}

// K DENSITY of Hours Worked per Week

foreach year of local year_list {
// All Groups
	graph twoway kdensity hours_worked
	graph export "C:/Users/phill/Box Sync/MHSS/3_figures/hours_worked_per_week/k_density/kdens_all_`year'.png", width(3000) replace
// Overlayed Migrant Groups
	tw ///
					(kdensity hours_worked_per_week if mig_status ==0 & year_em == `year', color(black)) ///
					(kdensity hours_worked_per_week if mig_status ==1 & year_em == `year', color(orange)) ///
					(kdensity hours_worked_per_week if mig_status ==2 & year_em == `year', color(green)) ///
					(kdensity hours_worked_per_week if mig_status ==3 & year_em == `year', color(blue)), ///
					title("Hours Worked Per Week `year'") ytitle("Density")xtitle("Hours Worked Per Week")legend(label(1 "Non Migrant") label(2 "Internal Migrant") label(3 "International Mig No Phone") label(4 "International Mig Phone"))
					graph export "C:/Users/phill/Box Sync/MHSS/3_figures/hours_worked_per_week/k_density/kdens_grouped_`year'.png", width(3000) replace
}

// Create Tables with Mean, Medians, SD, SE, Count
// By Year
preserve 
collapse (mean) hours_worked_mean=hours_worked_per_week  (median) hours_worked_median=hours_worked_per_week  (sd) hours_worked_sd=hours_worked_per_week  (semean) hours_worked_semean=hours_worked_per_week  (count) hours_worked_count=hours_worked_per_week , by(year_em)
export excel using "C:/Users/phill/Box Sync/MHSS/3_figures/hours_worked_per_week/tables/table_hours_worked_by_year.xlsx", firstrow(varlabels) sheetreplace
restore

// By Year and Group
preserve 
collapse (mean) hours_worked_mean=hours_worked_per_week (median) hours_worked_median=hours_worked_per_week  (sd) hours_worked_sd=hours_worked_per_week (semean) hours_worked_semean=hours_worked_per_week  (count) hours_worked_count=hours_worked_per_week , by(year_em mig_status)
label define I_Migrant_Groups 0 "Non Migrant" 1 "Internal Migrant" 2 "International No Phone" 3 "International Phone"
label values mig_status I_Migrant_Groups
export excel using "C:/Users/phill/Box Sync/MHSS/3_figures/hours_worked_per_week/tables/table_hours_worked_by_year_and_group.xlsx", firstrow(varlabels) sheetreplace
restore

// Earnings graphs
use "P:\pop\BANGLADESH_PROJECT\MHSS2\Analysis Files\Data\Migrant\MHSS2_employment.dta", clear 
*/


* ===================
* Prepare MHSS2 data
* ===================

***Prepare MHSS2 LH to merge in to see if in data source
use "P:\pop\BANGLADESH_PROJECT\MHSS2\Master Data\20160107_public\hc_lh_1.dta", clear
	count
	bys vill_id hhold_id line_no: gen dup=_N
	gen MHSS2dup=(dup>1)
	lab var MHSS2dup "1 if a duplicate exists in MHSS2 for this person"
	drop dup
	
	bys vill_id hhold_id line_no: gen dup=_n	
	tab dup								/* No duplicates */
	drop dup
	
	//rename lh08_clean rid

	order vill_id hhold_id line_no 
	
	* Create fake RID for those that are missing RIDs to match the backbone
	gen 	line_str = string(line_no)
	replace line_str = "0"+line_str if length(line_str) == 1
	
	gen rid = "9"+vill_id+hhold_id+line_str 
	drop line_str
	
	bys rid: gen dup2=_N
	gen MHSS2duprid=(dup>1 & dup<10 & rid~="")	/*Note many of the missing rids are coded as -8 */
	drop dup2
	
	*Religion
	gen m2_islamic=(lh16==1) 	if lh16~=.
	
	*Make indicator of in LH roster
	gen m2_LHroster=1
	
	
		*Make education from LH
	gen  		m2_lh_ed_yrs = lh18 if (lh18<30 & lh18>=0) & lh17~=.
	replace 	m2_lh_ed_yrs = 0 if  lh17==1| lh17==2 | lh17==5 | lh17==6 /*0 never attended, Maktab, Brac, Other NGO */		
	replace  	m2_lh_ed_yrs =. if lh17<=0 | lh17>9
	lab var 	m2_lh_ed_yrs "Highest grade completed including vocational and technical, BRAC Maktab coded as zero"

	gen  		m2_lh_ed_yrs2 = lh18 if lh18<30 & lh18>=0  & lh17~=.
	replace 	m2_lh_ed_yrs2 = 0 if lh17==1 | lh17==2  /*0 never attended, Maktab*/
	replace 	m2_lh_ed_yrs2 = 1 if lh17==5  | lh17==6 /*1 if brac or other NGO*/
	replace  	m2_lh_ed_yrs2 =. if lh17<=0 | lh17>9
	lab var 	m2_lh_ed_yrs2 "Highest grade completed including vocational and technical, Brac or NGO 1 year of school"
	gen 		m2_lh_brac	=(lh17==5) if lh17~=.
	
	
	gen 		m2_lh_ed_yrs3=m2_lh_ed_yrs
	replace 	m2_lh_ed_yrs3=2 if  lh17==5  | lh17==6   /*1 if BRAC*/
	lab var 	m2_lh_ed_yrs3 "Highest grade completed including vocational and technical, Brac or NGO 2 year of school"


	*rename all variables to start with m2
	foreach var of varlist lh01-lh21 {
		rename `var' m2_`var'
	}	
	
	rename use_books  m2_use_books
	rename use_obs	  m2_use_obs
	
	
	*Rename LH vars
	rename	m2_lh09month	m2_lh_birthmth
	rename	m2_lh09year	m2_lh_birthyr 

	label	var 		m2_lh_birthmth "Birth month from LH" 
	label	var 		m2_lh_birthyr  "Birth year from LH" 

	rename	m2_lh10year	m2_lh_ageyr
	rename	m2_lh10month	m2_lh_agemths 

	label	var 		m2_lh_ageyr 	"Age in years from LH" 
	label	var 		m2_lh_agemths  "Age in months from LH"

	tab m2_lh05
	gen 	m2_lh_male	=(m2_lh05==1) if m2_lh05~=.
	duplicates report rid
	
	rename 	m2_lh11			m2_lh_marrst
	label var	m2_lh_marrst	"Marrital Status from LH"
	
	
	* Clean up LH variables
	foreach var of varlist m2_lh_ageyr m2_lh_agemths m2_lh_marrst {
		replace `var' = . if `var' == -8
		replace `var' = . if `var' == -7
	}
	
	* Marrital Status
	replace m2_lh_marrst = . if m2_lh_marrst == 12
	
	recode m2_lh_marrst		(2=1) (nonm=0), gen(m2_lh_currmarr)
	recode m2_lh_marrst		(1=0) (nonm=1), gen(m2_lh_evermarr)
	
	label var	m2_lh_currmarr 	"=1 if currently married (MHSS2)"
	label var	m2_lh_evermarr 	"=1 if ever married (MHSS2)"


	
	mmerge vill_id hhold_id line_no using "P:\pop\BANGLADESH_PROJECT\MHSS2\Analysis Files\Data\Migrant\indiv_control.dta", uname(m2_) type(1:1)
		duplicates report rid
	
	tab _merge
	drop _merge
	
	keep if m2_use_obs==1	



// TOP CODE (added by Bryan)

global outlier_vars		m2_ea_incyear m2_ea_incyear1 m2_ea_hrs_tot m2_ee_incyear2002 m2_ee_incyear2007 m2_ee_incyear2011   
						
mmerge vill_id hhold_id line_no using "P:\pop\BANGLADESH_PROJECT\MHSS2\Analysis Files\Data\Migrant\MHSS2_employment.dta"

// Generate Age Groups
gen age_groups = .
local age_min 15
local age_max 24
forvalues i=1/9 {
	replace age_groups = `i' if m2_lh_ageyr >= `age_min' & m2_lh_ageyr <= `age_max'
	local age_min `age_min'+10
	local age_max `age_max'+10
}


foreach var of global outlier_vars {
	disp "var:`var'"
	*** Determine outliers by percentiles
	forvalues q = 90(1)99 {
		**** WITH ZEROS ****
		*** Create Upper Bounds by age group/sex
		egen 	`var'`q'	= pctile(`var') if m2_self_yob_b6>=1947, p(`q') by(age_groups m2_lh_male)
		
		* Trim
		cap drop `var'_tr`q'
		gen		`var'_tr`q'	= `var'
		replace	`var'_tr`q'	= .	 	if `var' > `var'`q' & `var' != .
		
		//
		cap drop `var'_tc`q'
		gen		`var'_tc`q'	= `var'
		replace	`var'_tc`q'	= `var'`q'	 	if `var' > `var'`q' & `var' != .
		
		drop `var'`q'

		**** WITHOUT ZEROS ****
		*** Create Upper Bounds by age group/sex (not including zero's)
		egen 	`var'`q'	= pctile(`var') if m2_self_yob_b6>=1947 & `var'!=0, p(`q') by(age_groups m2_lh_male)
		
		* Trim
		cap drop `var'_0tr`q'
		gen		`var'_0tr`q'	= `var'
		replace	`var'_0tr`q'	= .	 	if `var' > `var'`q' & `var' != .
		
		// 
		cap drop `var'_0tc`q'
		gen		`var'_0tc`q'	= `var'
		replace	`var'_0tc`q'	= `var'`q'	 	if `var' > `var'`q' & `var' != .
		
		drop `var'`q'
		
		**** TRIM NOT BY GROUP ****
		*** Create Upper Bounds for variable by sex
		egen	`var'`q'	= pctile(`var'), p(`q') by(m2_lh_male)
		
		*** Create Cleaned version of variable
		* Trim
		cap drop `var'_tra`q'
		gen		`var'_tra`q' = `var'
		replace	`var'_tra`q' = .		if `var' > `var'`q' & `var' != .
		
		cap drop `var'_tca`q'
		gen		`var'_tca`q' = `var'
		replace	`var'_tca`q' = `var'`q'		if `var' > `var'`q' & `var' != .
		
		drop `var'`q'	
	
	}
}




** Scale income numbers to be in USD
foreach var of varlist m2_ea_inc* m2_ee_inc* m2_avg_incyear m2_avg_incyear m2_mg_migcost {
	replace `var' = `var' / 78
}


* Construct some trimmed variables
foreach var of varlist m2_ea_incyear? m2_ea_incyear?? {
	gen `var'_trb95 = `var' if m2_ea_incyear==m2_ea_incyear_tra95		
}


// Categorize individuals by migrant status for grouping
gen village = substr(vill_id,1,1)
gen internal_mig = 0 
replace internal_mig = 1 if village == "Y"

gen international_mig = village <= "9"

gen international_phone = international_mig & phone == 1

gen international_inperson = international_mig & phone==0

gen non_mig = village == "I" | village == "J"

gen mig_status = 0 if non_mig
replace mig_status = 1 if internal_mig
replace mig_status = 2 if international_phone 
replace mig_status = 3 if international_inperson

drop village

// Create filtered datasets
////// males 15+
preserve
keep if m2_lh05 == 1 & m2_lh_ageyr >= 15
tempfile employ_males_15
save "P:\pop\BANGLADESH_PROJECT\MHSS2\Analysis Files\Data\Migrant\MHSS2_employment_males_15.dta", replace
restore



// pull in data
use "P:\pop\BANGLADESH_PROJECT\MHSS2\Analysis Files\Data\Migrant\MHSS2_employment_males_15.dta", clear

// EARNINGS 99% trimmed histograms and k density graphs


// create locals for loops
local earn_trim_vars tra99 0tr99 tr99 tc99 0tc99 tca99
local year_list 2002 2007 2011
local stats_vars mean median sd se count skew kurt



// Loop through trimmed vars to Generate Graphs
foreach var of local earn_trim_vars {
// histograms for whole population
	cap mkdir "C:/Users/phill/Box Sync/migrant followup/MHSS/3_figures/earnings/histograms/`var'"
	histogram m2_ea_incyear_`var', title("Annual Earnings for Primary Activity Trimmed (`var')")
	graph export "C:/Users/phill/Box Sync/migrant followup/MHSS/3_figures/earnings/histograms/`var'/hist_trim_`var'.png", width(3000) replace
	
// histograms by year for whole pop
	foreach year of local year_list {
		histogram m2_ee_incyear`year'_`var', title("Annual Earnings for `year' Trimmed (`var')")
		graph export "C:/Users/phill/Box Sync/migrant followup/MHSS/3_figures/earnings/histograms/`var'/hist_trim_`var'_`year'.png", width(3000) replace
	}
// histograms for each migrant pop	
	forvalues i=0/3 {
		histogram m2_ea_incyear_`var' if mig_status ==`i', title("Annual Earnings for Primary Activity Trimmed, Migrant Pop `i' (`var')")
		graph export "C:/Users/phill/Box Sync/migrant followup/MHSS/3_figures/earnings/histograms/`var'/hist_trim_`i'_`var'.png", width(3000) replace
		// By Year
		foreach year of local year_list {
			histogram m2_ee_incyear`year'_`var' if mig_status==`i', title("Annual Earnings for `year' Trimmed, Mig Group `i' (`var')")
			graph export "C:/Users/phill/Box Sync/migrant followup/MHSS/3_figures/earnings/histograms/`var'/hist_trim_`var'_`year'_`i'.png", width(3000) replace
		}
	}
// k density for whole population
	cap mkdir "C:/Users/phill/Box Sync/migrant followup/MHSS/3_figures/earnings/k_density/`var'"
	graph twoway kdensity m2_ea_incyear_`var', title("Annual Earnings for Primary Activity Trimmed (`var')")
	graph export "C:/Users/phill/Box Sync/migrant followup/MHSS/3_figures/earnings/k_density/`var'/kdens_trim_all_`var'.png", width(3000) replace
// k density for each migrant pop
	tw ///
					(kdensity m2_ea_incyear_`var' if mig_status ==0, color(black)) ///
					(kdensity m2_ea_incyear_`var' if mig_status ==1, color(orange)) ///
					(kdensity m2_ea_incyear_`var' if mig_status ==2, color(green)) ///
					(kdensity m2_ea_incyear_`var' if mig_status ==3, color(blue)), ///
					title("Annual Earnings Trimmed (`var')") ytitle("Density")xtitle("Earnings")legend(label(1 "Non Migrant") label(2 "Internal Migrant") label(3 "International Mig Phone") label(4 "International Mig No Phone"))
					graph export "C:/Users/phill/Box Sync/migrant followup/MHSS/3_figures/earnings/k_density/`var'/kdens_trim_grouped_`var'.png", width(3000) replace
	foreach year of local year_list {			
		graph twoway kdensity m2_ee_incyear`year'_`var', title("Annual Earnings for Primary Activity Trimmed (`var')")
		graph export "C:/Users/phill/Box Sync/migrant followup/MHSS/3_figures/earnings/k_density/`var'/kdens_trim_all_`var'_`year'.png", width(3000) replace
		// k density for each migrant pop
			tw ///
					(kdensity m2_ee_incyear`year'_`var' if mig_status ==0, color(black)) ///
					(kdensity m2_ee_incyear`year'_`var' if mig_status ==1, color(orange)) ///
					(kdensity m2_ee_incyear`year'_`var' if mig_status ==2, color(green)) ///
					(kdensity m2_ee_incyear`year'_`var' if mig_status ==3, color(blue)), ///
					title("Annual Earnings Trimmed for `year' (`var')") ytitle("Density")xtitle("Earnings")legend(label(1 "Non Migrant") label(2 "Internal Migrant") label(3 "International Mig Phone") label(4 "International Mig No Phone"))
					graph export "C:/Users/phill/Box Sync/migrant followup/MHSS/3_figures/earnings/k_density/`var'/kdens_trim_grouped_`var'_`year'.png", width(3000) replace
	}	
// Tables
// m2_ea_incyear

cap mkdir "C:/Users/phill/Box Sync/migrant followup/MHSS/3_figures/earnings/tables/`var'"
// CURRENT YEAR TABLE

preserve

egen skew_old = skew(m2_ea_incyear)
egen skew_trim = skew(m2_ea_incyear_`var')
egen kurt_old = kurt(m2_ea_incyear)
egen kurt_trim = kurt(m2_ea_incyear_`var')

collapse (mean) mean_old=m2_ea_incyear mean_trim=m2_ea_incyear_`var'  skew_old skew_trim kurt_old kurt_trim (median) median_old=m2_ea_incyear median_trim=m2_ea_incyear_`var'  (sd) sd_old=m2_ea_incyear sd_trim=m2_ea_incyear_`var'  (semean) se_old=m2_ea_incyear se_trim=m2_ea_incyear_`var'   (count) count_old=m2_ea_incyear count_trim=m2_ea_incyear_`var'
foreach stat of local stats_vars {
	gen `stat'_dif = ((`stat'_old - `stat'_trim) / `stat'_old) * 100
	replace `stat'_dif = round(`stat'_dif,1)
	replace `stat'_old = round(`stat'_old,.1)
	replace `stat'_trim = round(`stat'_trim,.1)
	rename `stat'_old old_`stat'
	rename `stat'_trim trim_`stat'
	rename `stat'_dif dif_`stat'
}
gen my_var = 1
reshape long old_ trim_ dif_, i(my_var) j(var_type) string
drop my_var
export excel using "C:/Users/phill/Box Sync/migrant followup/MHSS/3_figures/earnings/tables/`var'/table_earnings_current_`var'.xlsx", firstrow(variables) sheetreplace
restore

// BY MIGRANT STATUS

preserve

bysort mig_status : egen skew_old = skew(m2_ea_incyear)
bysort mig_status : egen skew_trim = skew(m2_ea_incyear_`var')
bysort mig_status : egen kurt_old = kurt(m2_ea_incyear)
bysort mig_status : egen kurt_trim = kurt(m2_ea_incyear_`var')

collapse (mean) mean_old=m2_ea_incyear mean_trim=m2_ea_incyear_`var' skew_old skew_trim kurt_old kurt_trim  (median) median_old=m2_ea_incyear median_trim=m2_ea_incyear_`var'  (sd) sd_old=m2_ea_incyear sd_trim=m2_ea_incyear_`var'  (semean) se_old=m2_ea_incyear se_trim=m2_ea_incyear_`var'   (count) count_old=m2_ea_incyear count_trim=m2_ea_incyear_`var'  , by(mig_status)
foreach stat of local stats_vars {
	gen `stat'_dif = ((`stat'_old - `stat'_trim) / `stat'_old) * 100
	replace `stat'_dif = round(`stat'_dif,1)
	replace `stat'_old = round(`stat'_old,.1)
	replace `stat'_trim = round(`stat'_trim,.1)
}
order mig_status count_old count_trim count_dif mean_old mean_trim mean_dif median_old median_trim median_dif sd_old sd_trim sd_dif se_old se_trim se_dif skew_old skew_trim skew_dif kurt_old kurt_trim kurt_dif
export excel using "C:/Users/phill/Box Sync/migrant followup/MHSS/3_figures/earnings/tables/`var'/table_earnings_groups_current_`var'.xlsx", firstrow(variables) sheetreplace
restore

// BY YEAR/ MIGRANT STATUS

preserve
foreach year of local year_list {
	rename m2_ee_incyear`year'_`var' m2_ee_incyear`var'_`year'
}

reshape long m2_ee_incyear`var'_ m2_ee_incyear, i(vill_id hhold_id line_no) j(my_year)

//create skew and kurt 
bysort my_year mig_status : egen skew_old = skew(m2_ee_incyear)
bysort my_year mig_status : egen skew_trim = skew(m2_ee_incyear`var'_)
bysort my_year mig_status : egen kurt_old = kurt(m2_ee_incyear)
bysort my_year mig_status : egen kurt_trim = kurt(m2_ee_incyear`var'_)
		

collapse (mean) mean_old=m2_ee_incyear mean_trim=m2_ee_incyear`var'_  skew_old skew_trim kurt_old kurt_trim  (median) median_old=m2_ee_incyear median_trim=m2_ee_incyear`var'_  (sd) sd_old=m2_ee_incyear sd_trim=m2_ee_incyear`var'_  (semean) se_old=m2_ee_incyear se_trim=m2_ee_incyear`var'_   (count) count_old=m2_ee_incyear count_trim=m2_ee_incyear`var'_  , by(my_year mig_status)
foreach stat of local stats_vars {
	gen `stat'_dif = ((`stat'_old - `stat'_trim) / `stat'_old) * 100
	replace `stat'_dif = round(`stat'_dif,1)
	replace `stat'_old = round(`stat'_old,.1)
	replace `stat'_trim = round(`stat'_trim,.1)
}

order my_year mig_status count_old count_trim count_dif mean_old mean_trim mean_dif median_old median_trim median_dif sd_old sd_trim sd_dif se_old se_trim se_dif skew_old skew_trim skew_dif kurt_old kurt_trim kurt_dif
export excel using "C:/Users/phill/Box Sync/migrant followup/MHSS/3_figures/earnings/tables/`var'/table_earnings_years_`var'.xlsx", firstrow(variables) sheetreplace
restore

}





// Loops to create New Untrimmed graphs and tables
local untrimmed_vars m2_ea_incyear m2_ea_incyear1 m2_ee_incyear2002 m2_ee_incyear2007 m2_ee_incyear2011
local sum_stats mean median sd se cv kurt skew 	
foreach var of local untrimmed_vars {

	cap mkdir "C:/Users/phill/Box Sync/migrant followup/MHSS/3_figures/earnings/histograms/untrimmed"
	histogram `var', title("Annual Earnings for Primary Activity Untrimmed `var'")
	graph export "C:/Users/phill/Box Sync/migrant followup/MHSS/3_figures/earnings/histograms/untrimmed/hist_`var'.png", width(3000) replace

	cap mkdir "C:/Users/phill/Box Sync/migrant followup/MHSS/3_figures/earnings/k_density/untrimmed"
	// k density for each migrant pop
	tw ///
					(kdensity `var' if mig_status ==0, color(black)) ///
					(kdensity `var' if mig_status ==1, color(orange)) ///
					(kdensity `var' if mig_status ==2, color(green)) ///
					(kdensity `var' if mig_status ==3, color(blue)), ///
					title("`var' Untrimmed with 0") ytitle("Density")xtitle("Earnings")legend(label(1 "Non Migrant") label(2 "Internal Migrant") label(3 "International Mig Phone") label(4 "International Mig No Phone"))
					graph export "C:/Users/phill/Box Sync/migrant followup/MHSS/3_figures/earnings/k_density/untrimmed/kdens_untrim_`var'.png", width(3000) replace
		// k density for each migrant pop excluding 0's
	tw ///
					(kdensity `var' if mig_status ==0 & `var' != 0, color(black)) ///
					(kdensity `var' if mig_status ==1 & `var' != 0, color(orange)) ///
					(kdensity `var' if mig_status ==2 & `var' != 0, color(green)) ///
					(kdensity `var' if mig_status ==3 & `var' != 0, color(blue)), ///
					title("`var' Untrimmed No 0") ytitle("Density")xtitle("Earnings")legend(label(1 "Non Migrant") label(2 "Internal Migrant") label(3 "International Mig Phone") label(4 "International Mig No Phone"))
					graph export "C:/Users/phill/Box Sync/migrant followup/MHSS/3_figures/earnings/k_density/untrimmed/kdens_untrim_no0_`var'.png", width(3000) replace

	cap mkdir "C:/Users/phill/Box Sync/migrant followup/MHSS/3_figures/earnings/tables/untrimmed"	
	
preserve

	bysort mig_status : egen skew = skew(`var')
	bysort mig_status : egen kurt = kurt(`var')

collapse (mean) mean=`var' skew kurt (median) median=`var'  (sd) sd=`var'  (semean) se=`var'   (count) count=`var'  , by(mig_status)
	gen cv = (sd / mean) * 100
	foreach var of local sum_stats {
		replace `var' = round(`var',.01)
	}



gen var_name = "`var'"

order var_name mig_status count mean median sd se cv skew kurt
export excel using "C:/Users/phill/Box Sync/migrant followup/MHSS/3_figures/earnings/tables/untrimmed/table_`var'.xlsx", firstrow(variables) sheetreplace

tempfile untrimmed_`var'
save `untrimmed_`var'', replace
restore			
	
}

use "`untrimmed_m2_ea_incyear'", clear

foreach var in m2_ea_incyear1 m2_ee_incyear2002 m2_ee_incyear2007 m2_ee_incyear2011 {
	append using `untrimmed_`var''
}

export excel using "C:/Users/phill/Box Sync/migrant followup/MHSS/3_figures/earnings/tables/untrimmed/Compiled_untrimmed.xlsx", firstrow(variables) sheetreplace






// Create Year/Group tables for employment variables
label define I_year_list 1 "2002" 2 "2007" 3 "2011" 4 "Current Year"
label define I_Migrant_Groups 0 "Non Migrant" 1 "Internal Migrant" 2 "International Phone" 3 "International No Phone"


local income_list m2_ee_incyear2002 m2_ee_incyear2007 m2_ee_incyear2011 m2_ea_incyear 

local hrs_list m2_ee_hrs_tot2002 m2_ee_hrs_tot2007 m2_ee_hrs_tot2011 m2_ea_hrs_tot 

local wage_list m2_ee_inchour2002 m2_ee_inchour2007 m2_ee_inchour2011 m2_ea_inchour 

local table_list income_list hrs_list wage_list

local sum_stats mean median sd se cv kurt skew 	

foreach var of local table_list {
	local year_count = 0
	di "`var'"
	preserve
	foreach table in ``var'' {
	di "`table'"
		local year_count = `year_count' + 1
		rename `table' variable_`year_count'
	}
	
	reshape long variable_, i(vill_id hhold_id line_no mig_status) j(year_num)
	

		
	
	collapse (mean) mean=variable_  kurt skew (median) median=variable_  (sd) sd=variable_  (semean) se=variable_   (count) count=variable_  , by(year_num mig_status)
	gen cv = (sd / mean) * 100
	
		

	order year_num mig_status count mean median sd se cv kurt skew
	gsort -year_num mig_status
		
	label values mig_status I_Migrant_Groups
	label values year_num I_year_list
	
	
	export excel using "C:/Users/phill/Box Sync/migrant followup/MHSS/3_figures/employment/untrimmed_tables/table_`var'.xlsx", firstrow(variables) sheetreplace
	
	restore

}


// OTHER EMPLOYMENT TABLES
use "P:\pop\BANGLADESH_PROJECT\MHSS2\Analysis Files\Data\Migrant\MHSS2_employment_males_15.dta", clear

local   other_employ_vars	m2_ea_part_inc m2_eb_profplus m2_eb_ag m2_eb_manual m2_eb_elementary m2_eb_physical m2_eb_anyeduc_cl  m2_eb_profplus_noshop3 m2_eb_prof m2_eb_prof_prim34 m2_ea_incyearHH m2_ea_hrs_tot
local sum_stats mean median sd se cv kurt skew  

label define I_Migrant_Groups 0 "Non Migrant" 1 "Internal Migrant" 2 "International Phone" 3 "International No Phone"

foreach var of local other_employ_vars {
	gen variable_`var' = `var'
}

	reshape long variable_, i(vill_id hhold_id line_no mig_status) j(var_name) string

	bysort mig_status : egen skew = skew(variable_)
	bysort mig_status : egen kurt = kurt(variable_)
		
	
	collapse (mean) mean=variable_  kurt skew (median) median=variable_  (sd) sd=variable_  (semean) se=variable_   (count) count=variable_  , by(mig_status var_name)
	gen cv = (sd / mean) * 100
	
	foreach var of local sum_stats {
		replace `var' = round(`var',.01)
	}

	order var_name mig_status count mean median sd se cv kurt skew
	gsort var_name mig_status
		
	label values mig_status I_Migrant_Groups
	
	
	export excel using "C:/Users/phill/Box Sync/migrant followup/MHSS/3_figures/employment/untrimmed_tables/other_employ_table.xlsx", firstrow(variables) sheetreplace
	












// HISTOGRAMS of Hours Worked per Week
// For Each Year
foreach year of local year_list {
//All Groups
	histogram m2_ea_incyearHH_trb95, title("Annual Earnings for Primary Activity")
	graph export "C:\Users\phill\Box Sync\migrant followup\MHSS\3_figures\earnings\histograms\hist_all_`year'.png", width(3000) replace
// By Migrant Status
	forvalues i=0/3 {
		histogram m2_ee_incyear`year' if mig_status == `i', title("Annual Earnings for Primary Activity `i', Year `year'")
		graph export "C:\Users\phill\Box Sync\migrant followup\MHSS\3_figures\earnings\histograms\hist_mig_stat_`i'_`year'.png", width(3000) replace
	}
}


// K DENSITY of Hours Worked per Week

foreach year of local year_list {
// All Groups
	graph twoway kdensity m2_ee_incyear`year' if m2_ee_incyear`year' != 0
	graph export "C:\Users\phill\Box Sync\migrant followup\MHSS\3_figures\earnings\k_density\kdens_all_`year'.png", width(3000) replace
// Overlayed Migrant Groups
	tw ///
					(kdensity m2_ee_incyear`year' if mig_status ==0 & m2_ee_incyear`year' != 0, color(black)) ///
					(kdensity m2_ee_incyear`year' if mig_status ==1 & m2_ee_incyear`year' != 0, color(orange)) ///
					(kdensity m2_ee_incyear`year' if mig_status ==2 & m2_ee_incyear`year' != 0, color(green)) ///
					(kdensity m2_ee_incyear`year' if mig_status ==3 & m2_ee_incyear`year' != 0, color(blue)), ///
					title("Annual Earnings `year'") ytitle("Density")xtitle("Earnings")legend(label(1 "Non Migrant") label(2 "Internal Migrant") label(3 "International Mig No Phone") label(4 "International Mig Phone"))
					graph export "C:/Users/phill/Box Sync/migrant followup/MHSS/3_figures/earnings/k_density/kdens_grouped_`year'.png", width(3000) replace
}



// Create Tables with Mean, Medians, SD, SE, Count
// By Year
preserve 
keep vill_id m2_ee_incyear*
reshape long m2_ee_incyear, i() j(year)
collapse (mean) hours_worked_mean=hours_worked_per_week  (median) hours_worked_median=hours_worked_per_week  (sd) hours_worked_sd=hours_worked_per_week  (semean) hours_worked_semean=hours_worked_per_week  (count) hours_worked_count=hours_worked_per_week , by(year_em)
export excel using "C:/Users/phill/Box Sync/MHSS/3_figures/hours_worked_per_week/tables/table_hours_worked_by_year.xlsx", firstrow(variables) sheetreplace
restore

// By Year and Group
preserve 
collapse (mean) hours_worked_mean=hours_worked_per_week (median) hours_worked_median=hours_worked_per_week  (sd) hours_worked_sd=hours_worked_per_week (semean) hours_worked_semean=hours_worked_per_week  (count) hours_worked_count=hours_worked_per_week , by(year_em mig_status)
label define I_Migrant_Groups 0 "Non Migrant" 1 "Internal Migrant" 2 "International No Phone" 3 "International Phone"
label values mig_status I_Migrant_Groups
export excel using "C:/Users/phill/Box Sync/MHSS/3_figures/hours_worked_per_week/tables/table_hours_worked_by_year_and_group.xlsx", firstrow(variables) sheetreplace
restore

// Earnings graphs
use "C:\Users\phill\Box Sync\migrant followup\MHSS\2_data\employment\MHSS2_employment.dta", clear 












