// Bryan Phillips
// Graphing MHSS data

use  "P:\pop\BANGLADESH_PROJECT\MHSS2\Master Data\20160107_public\hc_lh_1.dta", clear


merge 1:1 vill_id hhold_id line_no using "P:\pop\BANGLADESH_PROJECT\MHSS2\Analysis Files\Data\Migrant\MHSS2_health.dta"

keep if _merge == 3


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


// BMI FIGURES
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
