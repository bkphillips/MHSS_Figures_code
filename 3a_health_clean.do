
// Randall's additional health code


use "P:\pop\BANGLADESH_PROJECT\MHSS2\Analysis Files\Data\Migrant\Health Data\book36.dta", clear

drop _merge

gen m2_gh_hstat_cat4_12 = m2_gh_hstat_cat4 <= 2 if m2_gh_hstat_cat4~=.

global health m2_diff_vision m2_diff_hear m2_gh_hstat_cat4 m2_gh_hstat_poor m2_gh_hstat_cat4_12 m2_gh_hstat_fairpl_betavg m2_gh_hstat_good m2_gh_daysill m2_gh_adl_mob m2_gh_adl_mob_diff m2_gh_adl_mob_notatall m2_gh_adl_mob_easy m2_gh_adl_mobshort m2_gh_adl_mobshort_diff m2_gh_adl_mobshort_notatall m2_gh_adl_mobshort_easy m2_injury m2_injury_work m2_unint_injury m2_injury_disab cm46 smoke_m2_smokestat m2_smoke_perday m2_smoke_current m2_smoke_ever m2_diarrhea


mmerge vill_id hhold_id line_no using "P:\pop\BANGLADESH_PROJECT\MHSS2\Master Data\20160107_public\b3_spn", ukeep(spn06cig)
tab _merge
drop if _merge==2

mmerge vill_id hhold_id line_no using "P:\pop\BANGLADESH_PROJECT\MHSS2\Master Data\20160107_public\b3_cm"
tab _merge
drop if _merge==2


/**************************/
/*****Injuries************/
/**************************/

// gen m2_injury_work = cm45 == 3 & cm44 ==1 if cm44~=. // Ask randall why cm45 doesnt exist

// gen m2_injury_disab = cm49 == 1 & cm44 ==1 if cm44~=.

gen m2_smoke_perday = spn06cig if spn06cig~=. & spn06cig>0 // Ask randall why spn06cig doesnt exist 
replace m2_smoke_perday = 0 if m2_smokestat~=1
label 		var 	m2_smoke_perday "Number of cigarettes per day (0 if not current)" 

gen 		m2_smoke_ever 		= m2_smokestat<=3 if m2_smokestat~=.
label 		var 	m2_smoke_ever  "=1 if smoke ever, =0 no" 
/*
gen 		m2_asthma_simple = cm34==1 if cm34~=.                            // cm34 does not exist
label 		variable m2_asthma_screen "Asthma (Screening report only - cm34)"

gen 		m2_angina_screen = cm12==1 if cm12~=.                               // cm12 does not exist
label 		variable m2_angina_screen "m2_angina (Screening question only - cm12)"
*/
save "P:\pop\BANGLADESH_PROJECT\MHSS2\Analysis Files\Data\Migrant\MHSS2_health.dta", replace
