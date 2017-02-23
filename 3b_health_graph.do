// Bryan Phillips
// Graphing MHSS data

// Pull in identifier data
use  "P:\pop\BANGLADESH_PROJECT\MHSS2\Master Data\20160107_public\hc_lh_1.dta", clear

// Merge Health Dataset
merge 1:1 vill_id hhold_id line_no using "P:\pop\BANGLADESH_PROJECT\MHSS2\Analysis Files\Data\Migrant\MHSS2_health.dta"

keep if _merge == 3

// Create migrant status identifier (mig_status)
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


// Restrict health dataset to men over 15 and under 59
keep if lh05 == 1 & lh10year >= 15 & lh10year <= 59

save "P:\pop\BANGLADESH_PROJECT\MHSS2\Analysis Files\Data\Migrant\MHSS2_health_males_15.dta", replace

//////////////////////////////////////////////////
// FIGURES /////////////////////////////////////
//////////////////////////////////////////////////
use "P:\pop\BANGLADESH_PROJECT\MHSS2\Analysis Files\Data\Migrant\MHSS2_health_males_15.dta", clear


// BMI FIGURES /////////////////////////////////
	// histogram
	histogram m2_bmicl, by(mig_status)
	graph export "C:/Users/phill/Box Sync/migrant followup/MHSS/3_figures/health/bmi/hist_bmi_by_mig.png", width(3000) replace
	
	// K Density
	tw ///
					(kdensity m2_bmicl if mig_status ==0 , color(black)) ///
					(kdensity m2_bmicl if mig_status ==1 , color(orange)) ///
					(kdensity m2_bmicl if mig_status ==2 , color(green)) ///
					(kdensity m2_bmicl if mig_status ==3 , color(blue)), ///
					title("Cleaned BMI") ytitle("Density")xtitle("BMI")legend(label(1 "Non Migrant") label(2 "Internal Migrant") label(3 "International Mig Phone") label(4 "International Mig No Phone"))
					graph export "C:/Users/phill/Box Sync/migrant followup/MHSS/3_figures/health/bmi/kdens_bmi_by_mig.png", width(3000) replace
					
	
	
	// TABLES
	local sum_stats count mean median sd se cv kurt skew 				
	preserve
	bysort mig_status : egen skew = skew(m2_bmi)
	bysort mig_status : egen kurt = kurt(m2_bmi)
	bysort mig_status : egen skewcl = skew(m2_bmicl )
	bysort mig_status : egen kurtcl = kurt(m2_bmicl )
	
	collapse (mean) mean=m2_bmi meancl=m2_bmicl skew skewcl kurt kurtcl (median) median=m2_bmi mediancl=m2_bmicl  (sd) sd=m2_bmi sdcl=m2_bmicl  (semean) se=m2_bmi secl=m2_bmicl   (count)  count=m2_bmi countcl=m2_bmicl  , by(mig_status)
		gen cv = (sd / mean) * 100
		gen cvcl = (sdcl / meancl) * 100
		
		foreach var of local sum_stats {
			gen `var'_dif = ((`var' - `var'cl)/`var') *100
			replace `var'_dif = round(`var'_dif,1)
			replace `var' = round(`var',.01)
			replace `var'cl = round(`var'cl,.01)
		}
	
	order mig_status count countcl count_dif mean meancl mean_dif median mediancl median_dif sd sdcl sd_dif se secl se_dif cv cvcl cv_dif skew skewcl skew_dif kurt kurtcl kurt_dif
	
	export excel using "C:/Users/phill/Box Sync/migrant followup/MHSS/3_figures/health/bmi/table_bmi_comparison.xlsx", firstrow(variables) sheetreplace
	restore


// HEIGHT FIGURES
	// histogram
	histogram m2_heightcl, by(mig_status)
	graph export "C:/Users/phill/Box Sync/migrant followup/MHSS/3_figures/health/height/hist_height_by_mig.png", width(3000) replace
	
	// (trimmed height between 120 and 180)
	histogram m2_heightcl if m2_heightcl >= 120 & m2_heightcl <= 180, by(mig_status)
	graph export "C:/Users/phill/Box Sync/migrant followup/MHSS/3_figures/health/height/hist_height_by_mig_trimmed.png", width(3000) replace
	
	// K Density
	tw ///
					(kdensity m2_heightcl if mig_status ==0, color(black)) ///
					(kdensity m2_heightcl if mig_status ==1, color(orange)) ///
					(kdensity m2_heightcl if mig_status ==2, color(green)) ///
					(kdensity m2_heightcl if mig_status ==3, color(blue)), ///
					title("Cleaned Height") ytitle("Density")xtitle("Height")legend(label(1 "Non Migrant") label(2 "Internal Migrant") label(3 "International Mig Phone") label(4 "International Mig No Phone"))
					graph export "C:/Users/phill/Box Sync/migrant followup/MHSS/3_figures/health/height/kdens_height_by_mig.png", width(3000) replace
	// K Density (trimmed height between 120 and 180)
	tw ///
					(kdensity m2_heightcl if mig_status ==0 & m2_heightcl >= 120 & m2_heightcl <= 180, color(black)) ///
					(kdensity m2_heightcl if mig_status ==1 & m2_heightcl >= 120 & m2_heightcl <= 180, color(orange)) ///
					(kdensity m2_heightcl if mig_status ==2 & m2_heightcl >= 120 & m2_heightcl <= 180, color(green)) ///
					(kdensity m2_heightcl if mig_status ==3 & m2_heightcl >= 120 & m2_heightcl <= 180, color(blue)), ///
					title("Cleaned Height. Trimmed 120-180") ytitle("Density")xtitle("Height")legend(label(1 "Non Migrant") label(2 "Internal Migrant") label(3 "International Mig Phone") label(4 "International Mig No Phone"))
					graph export "C:/Users/phill/Box Sync/migrant followup/MHSS/3_figures/health/height/kdens_height_by_mig_trimmed.png", width(3000) replace
					
	// TABLES
	local sum_stats count mean median sd se cv kurt skew 				
	preserve
	bysort mig_status : egen skew = skew(m2_height)
	bysort mig_status : egen kurt = kurt(m2_height)
	bysort mig_status : egen skewcl = skew(m2_heightcl )
	bysort mig_status : egen kurtcl = kurt(m2_heightcl )
	
	collapse (mean) mean=m2_height meancl=m2_heightcl skew skewcl kurt kurtcl (median) median=m2_height mediancl=m2_heightcl  (sd) sd=m2_height sdcl=m2_heightcl  (semean) se=m2_height secl=m2_heightcl   (count)  count=m2_height countcl=m2_heightcl  , by(mig_status)
		gen cv = (sd / mean) * 100
		gen cvcl = (sdcl / meancl) * 100
		
		foreach var of local sum_stats {
			gen `var'_dif = ((`var' - `var'cl)/`var') *100
			replace `var'_dif = round(`var'_dif,1)
			replace `var' = round(`var',.01)
			replace `var'cl = round(`var'cl,.01)
		}
	
	order mig_status count countcl count_dif mean meancl mean_dif median mediancl median_dif sd sdcl sd_dif se secl se_dif cv cvcl cv_dif skew skewcl skew_dif kurt kurtcl kurt_dif	

	export excel using "C:/Users/phill/Box Sync/migrant followup/MHSS/3_figures/health/height/table_height_comparison.xlsx", firstrow(variables) sheetreplace
	
	restore
	
// Weight FIGURES
	// histogram
	histogram m2_weightcl, by(mig_status)
	graph export "C:/Users/phill/Box Sync/migrant followup/MHSS/3_figures/health/weight/hist_weight_by_mig.png", width(3000) replace
	
	// K Density
	tw ///
					(kdensity m2_weightcl if mig_status ==0, color(black)) ///
					(kdensity m2_weightcl if mig_status ==1, color(orange)) ///
					(kdensity m2_weightcl if mig_status ==2, color(green)) ///
					(kdensity m2_weightcl if mig_status ==3, color(blue)), ///
					title("Cleaned weight") ytitle("Density")xtitle("Weight")legend(label(1 "Non Migrant") label(2 "Internal Migrant") label(3 "International Mig Phone") label(4 "International Mig No Phone"))
					graph export "C:/Users/phill/Box Sync/migrant followup/MHSS/3_figures/health/weight/kdens_weight_by_mig.png", width(3000) replace
		
	// TABLES
	local sum_stats count mean median sd se cv kurt skew 				
	preserve
	bysort mig_status : egen skew = skew(m2_weight)
	bysort mig_status : egen kurt = kurt(m2_weight)
	bysort mig_status : egen skewcl = skew(m2_weightcl )
	bysort mig_status : egen kurtcl = kurt(m2_weightcl )
	
	collapse (mean) mean=m2_weight meancl=m2_weightcl skew skewcl kurt kurtcl (median) median=m2_weight mediancl=m2_weightcl  (sd) sd=m2_weight sdcl=m2_weightcl  (semean) se=m2_weight secl=m2_weightcl   (count)  count=m2_weight countcl=m2_weightcl  , by(mig_status)
		gen cv = (sd / mean) * 100
		gen cvcl = (sdcl / meancl) * 100
		
		foreach var of local sum_stats {
			gen `var'_dif = ((`var' - `var'cl)/`var') *100
			replace `var'_dif = round(`var'_dif,1)
			replace `var' = round(`var',.01)
			replace `var'cl = round(`var'cl,.01)
		}
	
	order mig_status count countcl count_dif mean meancl mean_dif median mediancl median_dif sd sdcl sd_dif se secl se_dif cv cvcl cv_dif skew skewcl skew_dif kurt kurtcl kurt_dif
	
	export excel using "C:/Users/phill/Box Sync/migrant followup/MHSS/3_figures/health/weight/table_weight_comparison.xlsx", firstrow(variables) sheetreplace
	restore

// AGE
// K Density
tw ///
				(kdensity lh10year if mig_status ==0 , color(black)) ///
				(kdensity lh10year if mig_status ==1 , color(orange)) ///
				(kdensity lh10year if mig_status ==2 , color(green)) ///
				(kdensity lh10year if mig_status ==3 , color(blue)), ///
				title("Cleaned Age") ytitle("Density")xtitle("Age")legend(label(1 "Non Migrant") label(2 "Internal Migrant") label(3 "International Mig Phone") label(4 "International Mig No Phone"))
				graph export "C:/Users/phill/Box Sync/migrant followup/MHSS/3_figures/health/age/kdens_age_by_mig.png", width(3000) replace
				
// HEALTH VARIABLES LOOP

local health m2_diff_vision m2_diff_hear m2_gh_hstat_cat4 m2_gh_hstat_poor m2_gh_hstat_cat4_12 m2_gh_hstat_fairpl_betavg m2_gh_hstat_good m2_gh_daysill m2_gh_adl_mob m2_gh_adl_mob_diff m2_gh_adl_mob_notatall m2_gh_adl_mob_easy m2_gh_adl_mobshort m2_gh_adl_mobshort_diff m2_gh_adl_mobshort_notatall m2_gh_adl_mobshort_easy m2_injury m2_injury_work m2_unint_injury m2_injury_disab cm46 smoke_m2_smokestat m2_smoke_perday m2_smoke_current m2_smoke_ever m2_diarrhea m2_asthma_simple m2_angina_screen 
cap mkdir "C:/Users/phill/Box Sync/migrant followup/MHSS/3_figures/health/all_health_vars"
		
foreach var of local health {

	cap mkdir "C:/Users/phill/Box Sync/migrant followup/MHSS/3_figures/health/all_health_vars/`var'"
	// histogram
	histogram `var', by(mig_status)
	graph export "C:/Users/phill/Box Sync/migrant followup/MHSS/3_figures/health/all_health_vars/`var'/hist_`var'.png", width(3000) replace
	
	// K Density
	tw ///
					(kdensity `var' if mig_status ==0, color(black)) ///
					(kdensity `var' if mig_status ==1, color(orange)) ///
					(kdensity `var' if mig_status ==2, color(green)) ///
					(kdensity `var' if mig_status ==3, color(blue)), ///
					title("`var'") ytitle("Density") legend(label(1 "Non Migrant") label(2 "Internal Migrant") label(3 "International Mig Phone") label(4 "International Mig No Phone"))
					graph export "C:/Users/phill/Box Sync/migrant followup/MHSS/3_figures/health/all_health_vars/`var'/kdens_`var'.png", width(3000) replace
		
	// TABLES
	local sum_stats count mean median sd se cv kurt skew 				
	preserve
	bysort mig_status : egen skew = skew(`var')
	bysort mig_status : egen kurt = kurt(`var')
	
	collapse (mean) mean=`var' skew kurt (median) median=`var' (sd) sd=`var' (semean) se=`var' (count)  count=`var', by(mig_status)
		gen cv = (sd / mean) * 100

		
		foreach var of local sum_stats {
			replace `var' = round(`var',.01)
		}
	
	order mig_status count mean median sd se cv
	
	export excel using "C:/Users/phill/Box Sync/migrant followup/MHSS/3_figures/health/all_health_vars//`var'//table_`var'.xlsx", firstrow(variables) sheetreplace
	
	restore
}



////////////////////////////////
// Compiled table of other vars
///////////////////////////////
// Health TABLES

use "P:\pop\BANGLADESH_PROJECT\MHSS2\Analysis Files\Data\Migrant\MHSS2_health_males_15.dta", clear


local sum_stats count mean median sd se cv kurt skew 

local health m2_diff_vision m2_diff_hear m2_gh_hstat_cat4 m2_gh_hstat_poor m2_gh_hstat_cat4_12 m2_gh_hstat_fairpl_betavg m2_gh_hstat_good m2_gh_daysill m2_gh_adl_mob m2_gh_adl_mob_diff m2_gh_adl_mob_notatall m2_gh_adl_mob_easy m2_gh_adl_mobshort m2_gh_adl_mobshort_diff m2_gh_adl_mobshort_notatall m2_gh_adl_mobshort_easy m2_injury m2_unint_injury m2_smokestat m2_smoke_current m2_smoke_ever m2_diarrhea 
// had to take out from local: 
// m2_injury_work m2_injury_disab cm46 m2_smoke_perday m2_asthma_simple  m2_angina_screen

foreach var of local health {
	rename `var' oth_`var'
}

reshape long oth_, i(vill_id hhold_id line_no) j(var_name) string

preserve

bysort mig_status var_name : egen skew = skew(oth_)
bysort mig_status var_name : egen kurt = kurt(oth_)

collapse (mean) mean=oth_ skew kurt (median) median=oth_ (sd) sd=oth_ (semean) se=oth_ (count)  count=oth_, by(var_name mig_status)
	gen cv = (sd / mean) * 100
	
foreach var of local sum_stats {
	replace `var' = round(`var',.01)
}

order var_name mig_status count mean median sd se cv kurt skew	

export excel using "C:/Users/phill/Box Sync/migrant followup/MHSS/3_figures/health/all_health_vars/Compiled_Health_Table_by_mig.xlsx", firstrow(variables) sheetreplace

keep var_name mig_status mean sd

reshape wide mean sd, i(var_name) j(mig_status)

order var_name mean0 sd0 mean1 sd1 mean2 sd2 mean3 sd3 


export excel using "C:/Users/phill/Box Sync/migrant followup/MHSS/3_figures/health/all_health_vars/Health_Table_of_means.xlsx", firstrow(variables) sheetreplace

	

restore

preserve

bysort var_name : egen skew = skew(oth_)
bysort var_name : egen kurt = kurt(oth_)

collapse (mean) mean=oth_ skew kurt (median) median=oth_ (sd) sd=oth_ (semean) se=oth_ (count)  count=oth_, by(var_name)
	gen cv = (sd / mean) * 100

	
local sum_stats count mean median sd se cv kurt skew 	
foreach var of local sum_stats {
	replace `var' = round(`var',.01)
}
	
order var_name count mean median sd se cv kurt skew

export excel using "C:/Users/phill/Box Sync/migrant followup/MHSS/3_figures/health/all_health_vars/Compiled_Health_Table.xlsx", firstrow(variables) sheetreplace

restore



// ////////////////////////////
// Physical TABLES

use "P:\pop\BANGLADESH_PROJECT\MHSS2\Analysis Files\Data\Migrant\MHSS2_health_males_15.dta", clear

local physical m2_hyper m2_arthritis m2_angina m2_asthma m2_diabetes m2_stroke m2_cld m2_diff_vision_l m2_diff_vision_r m2_diff_vision m2_cataract m2_diff_hear b6_bp_sys_avg b6_bp_sys_avgcl b6_bp_dia_avg b6_bp_dia_avgcl bp_pulse_avg bp_pulse_avgcl b6_bp_systolic b6_bp_optimalcl	b6_bp_normalcl b6_bp_highnormalcl b6_bp_hyperstage1plcl	b6_bp_hyperstage2plcl b6_bp_hyperstage3cl b6_opc_score b6_opc_score_notap b6_gs_max_dom b6_gs_max_domcl b6_gs_max_nondom b6_gs_avg_domcl b6_gs_avg_nondomcl m2_waistcl m2_hipcl m2_armcl

local sum_stats count mean median sd se cv kurt skew 


foreach var of local physical {
	rename `var' oth_`var'
}



reshape long oth_, i(vill_id hhold_id line_no) j(var_name) string

preserve

bysort mig_status var_name : egen skew = skew(oth_)
bysort mig_status var_name : egen kurt = kurt(oth_)

collapse (mean) mean=oth_ skew kurt (median) median=oth_ (sd) sd=oth_ (semean) se=oth_ (count)  count=oth_, by(var_name mig_status)
	gen cv = (sd / mean) * 100
	
foreach var of local sum_stats {
	replace `var' = round(`var',.01)
}

order var_name mig_status count mean median sd se cv kurt skew	

export excel using "C:/Users/phill/Box Sync/migrant followup/MHSS/3_figures/health/all_health_vars/Compiled_Physical_Table_by_mig.xlsx", firstrow(variables) sheetreplace
	
keep var_name mig_status mean sd

reshape wide mean sd, i(var_name) j(mig_status)

order var_name mean0 sd0 mean1 sd1 mean2 sd2 mean3 sd3 


export excel using "C:/Users/phill/Box Sync/migrant followup/MHSS/3_figures/health/all_health_vars/Physical_Table_of_means.xlsx", firstrow(variables) sheetreplace

	
restore

preserve

bysort var_name : egen skew = skew(oth_)
bysort var_name : egen kurt = kurt(oth_)

collapse (mean) mean=oth_ skew kurt (median) median=oth_ (sd) sd=oth_ (semean) se=oth_ (count)  count=oth_, by(var_name)
	gen cv = (sd / mean) * 100

	
local sum_stats count mean median sd se cv kurt skew 	
foreach var of local sum_stats {
	replace `var' = round(`var',.01)
}
	
order var_name count mean median sd se cv kurt skew

export excel using "C:/Users/phill/Box Sync/migrant followup/MHSS/3_figures/health/all_health_vars/Compiled_Physical_Table.xlsx", firstrow(variables) sheetreplace

restore


// Height, Weight, BMI
use "P:\pop\BANGLADESH_PROJECT\MHSS2\Analysis Files\Data\Migrant\MHSS2_health_males_15.dta", clear


gen overweight = m2_bmicl >= 25
gen obese = m2_bmicl >= 30


local basic_health m2_heightcl m2_weightcl m2_bmicl overweight obese
local sum_stats count mean median sd se cv kurt skew 


foreach var of local basic_health {
	rename `var' oth_`var'
}



reshape long oth_, i(vill_id hhold_id line_no) j(var_name) string

preserve

bysort mig_status var_name : egen skew = skew(oth_)
bysort mig_status var_name : egen kurt = kurt(oth_)

collapse (mean) mean=oth_ skew kurt (median) median=oth_ (sd) sd=oth_ (semean) se=oth_ (count)  count=oth_, by(var_name mig_status)
	gen cv = (sd / mean) * 100
	
foreach var of local sum_stats {
	replace `var' = round(`var',.01)
}

order var_name mig_status count mean median sd se cv kurt skew	

keep var_name mig_status mean sd

reshape wide mean sd, i(var_name) j(mig_status)

order var_name mean0 sd0 mean1 sd1 mean2 sd2 mean3 sd3 


export excel using "C:/Users/phill/Box Sync/migrant followup/MHSS/3_figures/health/all_health_vars/Compiled_Basic_Health_Table_by_mig.xlsx", firstrow(variables) sheetreplace
	
restore


// OTHER DISABILITY Table (single item questions for all four migrant groups)


 m2_injury_work m2_injury_disab m2_smoke_perday m2_asthma_screen m2_angina_screen




















