cap log close
log using "/PATH/03_output/02_logs/trends_paper_figures", replace text

* Variable and Figure 1 Creation for Trends in Post-Acute Care JAMDA Paper
*
*
* Zach Templeton
* July 19, 2021

clear all
global home "/PATH"
global data "/PATH/01_data"
global do_file "/PATH/02_script"
global output "/PATH/03_output"
sysdir set PLUS "/PATH/01_data/05_ado"
sysdir set PERSONAL "/PATH/01_data/05_ado"
cd "$home"
set more off



********************************************************************************
// Data cleaning and variable creation //
********************************************************************************
/* Analytical dataset that spans 2000-2018 and contains SNF FFS beneficiaries 
from MedPAR, along with LTC Focus data (2000-2017) and ACS data
*/
use "/PATH/01_data/snf_adm00_18.dta"
rename *, lower
rename adm_yr snf_admsn_year
gen female = sex == "2"
replace female = . if sex == "0"
label var female "Beneficiary is female"
gen white = 1 if race == "1"
replace white = 0 if missing(white)
replace white = . if race == "0"
gen black = 1 if race == "2"
replace black = 0 if missing(black)
replace black = . if race == "0"
gen hispanic = 1 if race == "5"
replace hispanic = 0 if missing(hispanic)
replace hispanic = . if race == "0"
gen other = 1 if race == "3" | race == "4" | race == "6"
replace other = 0 if missing(other)
replace other = . if race == "0"
save "$output/01_analytic_data/final_data_snfclaims_tr.dta", replace

/* Merge in LTC Focus ID for SNFs (accpt_id) using CMS ID for SNFs (PROV1680) 
NOTE: There are 22 NHs that don't have an accpt_id in the crosswalk. They are only 
present in the dataset once. Missing accpt_ids have been replaced with CMS ID */
tempfile crosswalk
preserve
	import excel "$data/03_ltcfocus/accptid_crosswalk.xls", sheet("ACCPT_ID_CROSSWALK") firstrow case(lower) clear
	rename prov1680 snf_prvdr_num
	save "`crosswalk'"
restore
merge m:1 snf_prvdr_num using "`crosswalk'"
keep if _merge == 1 | _merge == 3
drop _merge
replace accpt_id = snf_prvdr_num if missing(accpt_id)

/* Only keep SNF-years that are present in both LTC Focus and MedPAR */
* Don't have LTC Focus data for 2018
drop if snf_admsn_year == 2018
* Drop SNF-years that are present in MedPAR but not LTC Focus
drop if missing(accpt_id)
save "$output/01_analytic_data/final_data_snfclaims_tr.dta", replace

/* Calculates # Medicare admissions and # Medicare admissions per bed by SNF-year */ 
keep accpt_id snf_admsn_year snf_bed_cnt
gen n = 1
collapse (count) snf_med_admns = n (first) snf_bed_cnt, by(accpt_id snf_admsn_year)
gen snf_med_admns_beds = snf_med_admns / snf_bed_cnt
foreach num of numlist 10 20 30 40 50 60 70 80 90 {
	bysort snf_admsn_year: egen snf_med_admns_beds_p`num' = pctile(snf_med_admns_beds), p(`num')
}
label var snf_med_admns "# Medicare admissions"
label var snf_med_admns_beds "# Medicare admissions per bed"
save "$output/01_analytic_data/snf_med_admns.dta", replace

* Identify outliers in SNF % Medicare over time based on IQR for a given SNF
use "$output/01_analytic_data/final_data_snfclaims_tr.dta", clear
collapse (first) snf_pct_medicare, by(accpt_id year)
foreach var in snf_pct_medicare {
	bysort accpt_id: egen `var'_iqr = iqr(`var')
	bysort accpt_id: egen `var'_p25 = pctile(`var'), p(25)
	bysort accpt_id: egen `var'_p75 = pctile(`var'), p(75)
	gen upbd_`var'_out = `var'_p75 + 3 * `var'_iqr
	gen lwbd_`var'_out = `var'_p25 - 3 * `var'_iqr
	gen `var'_out = cond(missing(`var'), ., cond(float(`var') > upbd_`var'_out | ///
		float(`var') < lwbd_`var'_out, 1, 0))
}
* accpt_id_out identifies SNFs with a % Medicare outlier in at least 1 year
bysort accpt_id: egen accpt_id_out = max(snf_pct_medicare_out)
drop snf_pct_medicare_iqr snf_pct_medicare_p25 snf_pct_medicare_p75
save "$output/01_analytic_data/pct_med_outliers.dta", replace
use "$output/01_analytic_data/final_data_snfclaims_tr.dta", clear
merge m:1 accpt_id year using "$output/01_analytic_data/pct_med_outliers.dta"
keep if _merge == 1 | _merge == 3
drop _merge

sort accpt_id
by accpt_id: egen first_year = min(year)
by accpt_id: egen last_year = max(year)
gen first_year_z = 1 if snf_pct_medicare == 0 & year == first_year
by accpt_id: egen first_year_zero = min(first_year_z)
gen second_year_z = 1 if snf_pct_medicare == 0 & year == first_year + 1
by accpt_id: egen second_year_zero = min(second_year_z)

gen second_year_t = 1 if snf_pct_medicare > .10 & year == first_year + 1 & first_year_zero == 1
by accpt_id: egen second_year_th = min(second_year_t)
gen snf_pct_medicare_adj = snf_pct_medicare
replace snf_pct_medicare_adj = . if year == first_year & second_year_th == 1
/* NOTE: 248 NHs have % Medicare equal to 0 in the first year and have % Medicare >10% in the second year */

label var snf_pct_medicare_adj "% Medicare (cleaned)"
label var snf_pct_medicare_out "% Medicare for NH-year is likely outlier"
label var first_year_z "1 if NH has 0% Medicare in 1st year"
label var first_year_zero "1 if NH has 0% Medicare in 1st year (NH level)"
label var second_year_z "1 if NH has 0% Medicare in 2nd year"
label var second_year_zero "1 if NH has 0% Medicare in 2nd year (NH level)"
label var accpt_id "LTC Focus ID for SNFs"
label var first_year "First year in dataset for SNF"
label var last_year "Last year in dataset for SNF"
label var second_year_t "1 if NH has 0% Med in 1st year & >10% Med in 2nd year"
label var second_year_th "1 if NH has 0% Med in 1st year & >10% Med in 2nd year (NH level)"

* Merge in # Medicare admissions
merge m:1 accpt_id snf_admsn_year using "$output/01_analytic_data/snf_med_admns.dta"
keep if _merge == 1 | _merge == 3
drop _merge
save "$output/01_analytic_data/final_data_snfclaims_tr.dta", replace
********************************************************************************
********************************************************************************


/* Definitions of new, staying, and exiting SNFs
- SNFs are classified as new across the entire study period if they enter any time
after 2000
- Similarly, SNFs are classified as exiting across the entire study period if they exit
any time before 2017
- In the case where a SNF enters and exits during the study period, it will be
classified as new in the first half and exiting in the second half
- SNFs that are present in all years (2000-2017) are classified as staying
*/
egen first_year_global = min(year)
egen last_year_global = max(year)
gen new_nh_a = 1 if year == first_year & year != first_year_global
gen exit_nh_a = 1 if year == last_year & year != last_year_global
bysort accpt_id: egen new_nh_all = min(new_nh_a)
bysort accpt_id: egen exit_nh_all = min(exit_nh_a)
gen stay_nh_all = 1 if new_nh_all != 1 & exit_nh_all != 1
foreach var of varlist new_nh_all stay_nh_all exit_nh_all {
	replace `var' = 0 if missing(`var')
}
drop new_nh_a exit_nh_a
save "$output/01_analytic_data/final_data_snfclaims_tr.dta", replace

bysort accpt_id year: gen firstob_snfyear = (_n == 1)
keep if firstob_snfyear == 1
by accpt_id: egen mid_year = median(year)
* Count # SNFs that are currently classified as both new and exiting
preserve
	by accpt_id: gen firstob_snf = (_n == 1)
	keep if firstob_snf == 1
	count if new_nh_all == 1 & exit_nh_all == 1
restore
gen both_new_exit = cond(new_nh_all == 1 & exit_nh_all == 1, 1, 0)
replace exit_nh_all = 0 if (year <= mid_year) & both_new_exit == 1
replace new_nh_all = 0 if (year > mid_year) & both_new_exit == 1
* Check that new, staying, and exiting definitions are mutually exclusive for each year
gen check = new_nh_all + stay_nh_all + exit_nh_all
tab check
table year, c(sum new_nh_all sum stay_nh_all sum exit_nh_all)
keep accpt_id year new_nh_all stay_nh_all exit_nh_all
tempfile new_all
save "`new_all'"

use "$output/01_analytic_data/final_data_snfclaims_tr.dta", clear
/* Replace and update are critical because we've changed values for new_nh_all
and exit_nh_all in the temporary file */
merge m:1 accpt_id year using "`new_all'", replace update
drop _merge
gen nh_status = .
replace nh_status = 1 if new_nh_all == 1	// new nursing homes
replace nh_status = 2 if stay_nh_all == 1	// staying nursing homes
replace nh_status = 3 if exit_nh_all == 1	// exiting nursing homes
label define nh_statusl 1 "New" 2 "Staying" 3 "Exiting"
label values nh_status nh_statusl
label var nh_status "Type of nursing home"
save "$output/01_analytic_data/final_data_snfclaims_tr.dta", replace
********************************************************************************
********************************************************************************


/* Calculates Medicare admissions and admissions per bed by SNF-year
NOTE:
- Restricted to non-hospital-based SNFs (including percentile groups) 
- Admissions variables are missing for SNFs in their first year and missing for 
exiting SNFs in their last year */
keep if snf_hosp_based == 0
keep accpt_id snf_admsn_year snf_bed_cnt first_year last_year new_nh_all ///
	stay_nh_all exit_nh_all
gen n = 1
collapse (sum) admns_nonhosp = n (first) snf_bed_cnt first_year last_year ///
	new_nh_all stay_nh_all exit_nh_all, by(accpt_id snf_admsn_year)
replace admns_nonhosp = . if snf_admsn_year == first_year
replace admns_nonhosp = . if snf_admsn_year == last_year & exit_nh_all == 1
gen admns_beds_nonhosp = admns_nonhosp / snf_bed_cnt
foreach num of numlist 10 20 30 40 50 60 70 80 90 {
	bysort snf_admsn_year: egen admns_beds_nonhosp_p`num' = pctile(admns_beds_nonhosp), p(`num')
}
label var admns_nonhosp "Medicare admissions (non-hospital-based SNFs)"
label var admns_beds_nonhosp "Medicare admissions per bed (non-hospital-based SNFs)"
keep accpt_id snf_admsn_year admns_nonhosp admns_beds_nonhosp admns_beds_nonhosp_p*
save "$output/01_analytic_data/admns_nonhosp.dta", replace

* Merge in # Medicare admissions (non-hospital-based SNFs)
use "$output/01_analytic_data/final_data_snfclaims_tr.dta", clear
merge m:1 accpt_id snf_admsn_year using "$output/01_analytic_data/admns_nonhosp.dta"
keep if _merge == 1 | _merge == 3
drop _merge
save "$output/01_analytic_data/final_data_snfclaims_tr.dta", replace
********************************************************************************
********************************************************************************


/* # Medicare admissions per bed percentile groups (non-hospital-based SNFs) */
gen admns_beds_nonhosp_pct = .
replace admns_beds_nonhosp_pct = 1 if admns_beds_nonhosp <= admns_beds_nonhosp_p10 & !missing(admns_beds_nonhosp)
replace admns_beds_nonhosp_pct = 2 if admns_beds_nonhosp > admns_beds_nonhosp_p10 & admns_beds_nonhosp <= admns_beds_nonhosp_p50 & !missing(admns_beds_nonhosp)
replace admns_beds_nonhosp_pct = 3 if admns_beds_nonhosp > admns_beds_nonhosp_p50 & admns_beds_nonhosp <= admns_beds_nonhosp_p90 & !missing(admns_beds_nonhosp)
replace admns_beds_nonhosp_pct = 4 if admns_beds_nonhosp > admns_beds_nonhosp_p90 & !missing(admns_beds_nonhosp)
label define admns_beds_nonhosp_pctL 1 "<10th" 2 "11-50th" 3 "51-90th" 4 ">91st"
label values admns_beds_nonhosp_pct admns_beds_nonhosp_pctL

gen admns_beds_nonhosp_pct2 = .
replace admns_beds_nonhosp_pct2 = 1 if admns_beds_nonhosp <= admns_beds_nonhosp_p20 & !missing(admns_beds_nonhosp)
replace admns_beds_nonhosp_pct2 = 2 if admns_beds_nonhosp > admns_beds_nonhosp_p20 & admns_beds_nonhosp <= admns_beds_nonhosp_p50 & !missing(admns_beds_nonhosp)
replace admns_beds_nonhosp_pct2 = 3 if admns_beds_nonhosp > admns_beds_nonhosp_p50 & admns_beds_nonhosp <= admns_beds_nonhosp_p80 & !missing(admns_beds_nonhosp)
replace admns_beds_nonhosp_pct2 = 4 if admns_beds_nonhosp > admns_beds_nonhosp_p80 & !missing(admns_beds_nonhosp)
label define admns_beds_nonhosp_pct2L 1 "<20th" 2 "21-50th" 3 "51-80th" 4 ">81st"
label values admns_beds_nonhosp_pct2 admns_beds_nonhosp_pct2L
sort accpt_id snf_admsn_year
save "$output/01_analytic_data/final_data_snfclaims_tr.dta", replace
********************************************************************************
********************************************************************************


/* Collapse dataset to SNF-year level for later figure and table creation */
drop if snf_hosp_based == 1
collapse snf_pct_medicare_adj admns_nonhosp admns_beds_nonhosp admns_beds_nonhosp_pct ///
	pct_nh_days snf_bed_cnt snf_for_profit snf_hosp_based snf_in_chain snf_rn_hrppd ///
	snf_lpn_hrppd snf_cna_hrppd snf_dca_hrppd snf_rntonr nh_status female black ///
	white hispanic other age_cnt dual_at_adm, by(accpt_id snf_admsn_year)
save "/PATH/01_analytic_data/snf_yr_trends_final.dta", replace



********************************************************************************
// Figures for trends paper //
********************************************************************************
/* Figure 1 - Medicare admissions per bed over time for new, staying, and exiting NHs */
* Restriction of sample to non-hospital-based SNFs
use "/PATH/03_output/01_analytic_data/final_data_snfclaims_tr.dta", clear
keep if snf_hosp_based == 0
collapse (first) admns_beds_nonhosp new_nh_all stay_nh_all exit_nh_all, ///
	by(accpt_id snf_admsn_year)
gen admns_beds_nonhosp_new = admns_beds_nonhosp if new_nh_all == 1
gen admns_beds_nonhosp_stay = admns_beds_nonhosp if stay_nh_all == 1
gen admns_beds_nonhosp_exit = admns_beds_nonhosp if exit_nh_all == 1
table snf_admsn_year, c(sum new_nh_all sum stay_nh_all sum exit_nh_all)
collapse (mean) admns_beds_nonhosp admns_beds_nonhosp_new admns_beds_nonhosp_stay admns_beds_nonhosp_exit ///
	(sum) new_nh_all stay_nh_all exit_nh_all, by(snf_admsn_year)
label var admns_beds_nonhosp "Mean"
label var admns_beds_nonhosp_new "New SNFs"
label var admns_beds_nonhosp_stay "Staying SNFs"
label var admns_beds_nonhosp_exit "Exiting SNFs"
label var snf_admsn_year "Year of SNF Admission"
label var new_nh_all "N (New SNFs)"
label var stay_nh_all "N (Staying SNFs)"
label var exit_nh_all "N (Exiting SNFs)"
order snf_admsn_year admns_beds_nonhosp admns_beds_nonhosp_new admns_beds_nonhosp_stay admns_beds_nonhosp_exit ///
	new_nh_all stay_nh_all exit_nh_all
twoway line admns_beds_nonhosp admns_beds_nonhosp_new admns_beds_nonhosp_stay admns_beds_nonhosp_exit snf_admsn_year, ///
	title("Admissions Per Bed (Non-Hospital)") saving("$output/03_graphs/trends_figure1_graph_nonhosp_all.gph", replace)
graph export "$output/03_graphs/trends_figure1_graph_nonhosp_all.png", replace
export excel using "$output/03_graphs/trends_figure1_graph_nonhosp_all.xls", replace firstrow(varlabels)
use "$output/01_analytic_data/final_data_snfclaims_tr.dta", clear
	

/* NOTE: Please see R scripts for reproducing remaining figures and tables from the paper */



********************************************************************************
********************************************************************************
log close
