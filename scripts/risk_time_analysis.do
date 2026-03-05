clear all

** Append 2018, 2021, and GPS reference samples for risk/patience analysis
use "$working_ANALYSIS\data\bangladesh_GPS.dta"
keep if isocode=="BGD"
gen sample=3
lab def sampli 1 "BD 2018" 2 "BD 2021" 3 "BD GPS", replace
lab val sample sampli

su patience,  meanonly
gen patience_norm = (patience - r(min)) / (r(max) - r(min))*100
su risktaking, meanonly
gen risktaking_norm = (risktaking - r(min)) / (r(max) - r(min))*100

keep sample patience risktaking patience_norm risktaking_norm gender age
save "$working_ANALYSIS\processed\bangladesh_GPS_risk_time.dta", replace

*BD 2018
use "$working_ANALYSIS\processed\bangladesh2018.dta", clear
gen sample=1
keep sample survey_risk survey_time self_efficacy female age edu income_hh_pp place_attachment mobility_cat
rename survey_risk staircase_risk
rename survey_time staircase_patience
su self_efficacy, meanonly
gen self_efficacy_norm = (self_efficacy - r(min)) / (r(max) - r(min)) 
replace self_efficacy_norm=self_efficacy_norm*100

save "$working_ANALYSIS\processed\bangladesh2018_risk_time.dta", replace

*BD 2021
use "$working_ANALYSIS\processed\bangladesh2021.dta", clear
gen sample=2
keep sample risk impatience self_efficacy female age edu_yr income_average_hh place_attach mobility_cat
gen survey_patience=10-impatience
rename risk survey_risk
drop impatience
rename edu_yr edu
rename place_attach place_attachment
rename income_average_hh income_hh_pp
su self_efficacy, meanonly
gen self_efficacy_norm = (self_efficacy - r(min)) / (r(max) - r(min)) 
replace self_efficacy_norm=self_efficacy_norm*100


save "$working_ANALYSIS\processed\bangladesh2021_risk_time.dta", replace

append using "$working_ANALYSIS\processed\bangladesh2018_risk_time.dta"

* Ensure deterministic data order for reproducible MI.
* Stata's sort breaks ties randomly unless sortseed is set; different tie
* resolution changes which donors PMM selects, even with rseed().
set sortseed 1987
sort sample female age edu income_hh_pp place_attachment mobility_cat self_efficacy, stable

* Set dataset in memory as MI dataset
mi set flong
** Inspect missing values
mi misstable summarize survey_risk survey_patience staircase_risk staircase_patience
mi misstable patterns survey_risk survey_patience staircase_risk staircase_patience

*variables to be imputed
mi register imputed survey_risk survey_patience staircase_risk staircase_patience
mi describe

* Lock RNG state before imputation to ensure reproducibility across runs.
* PMM with knn(5) draws randomly among nearest donors; without explicit
* RNG initialization, session state can produce different donor draws.
set rng mt64s
set seed 1987
mi impute chained (pmm, knn(5)) survey_risk survey_patience staircase_risk staircase_patience = female age edu income_hh_pp place_attachment, add(20) rseed(1987)

* Z-score within each imputation (flong: _mi_m = 0..20)
foreach var of varlist staircase_risk staircase_patience survey_risk survey_patience {
	bysort _mi_m: egen double mean_`var' = mean(`var')
	bysort _mi_m: egen double sd_`var' = sd(`var')
	gen double z_`var' = (`var' - mean_`var') / sd_`var'
	drop mean_`var' sd_`var'
}

* Build composites within each imputation (GPS weights)
*Patience = 0.7115185 × Staircase patience + 0.2884815 × Will. to give up sth. today
gen double patience = 0.7115185*z_staircase_patience + 0.2884815*z_survey_patience
*Risk taking = 0.4729985 × Staircase risk + 0.5270015 × Will. to take risks
gen double risktaking = 0.4729985*z_staircase_risk + 0.5270015*z_survey_risk

* Min-max normalize within each imputation
foreach var of varlist patience risktaking {
	bysort _mi_m: egen double min_`var' = min(`var')
	bysort _mi_m: egen double max_`var' = max(`var')
	gen double `var'_norm = (`var' - min_`var') / (max_`var' - min_`var') * 100
	drop min_`var' max_`var'
}

* Register composites as passive (vary across imputations)
mi register passive z_staircase_risk z_staircase_patience z_survey_risk z_survey_patience
mi register passive patience risktaking patience_norm risktaking_norm

* Self-efficacy: already computed from observed data, constant across imputations
mi register regular self_efficacy_norm

* Median splits on observed demographics (same across all imputations)
foreach x of varlist income_hh_pp age place_attachment edu {
	bysort _mi_m: egen aux_`x' = median(`x')
	gen `x'_median = 1 if `x' >= aux_`x'
	replace `x'_median = 0 if `x' < aux_`x'
	drop aux_`x'
}
mi register regular income_hh_pp_median age_median place_attachment_median edu_median

* Save full MI dataset (Studies 1+2, for mi estimate regressions)
save "$working_ANALYSIS\processed\risk_time_mi.dta", replace

* Extract m=20 for descriptive plots (kernel densities, subgroup means, KW tests)
mi extract 20
append using "$working_ANALYSIS\processed\bangladesh_GPS_risk_time.dta"


save "$working_ANALYSIS\processed\risk_time_rdy.dta", replace
