*--------------------------------------------------
* This script generates tables and figures reported in the manuscript and SOM of the paper:
* "Behavioral barriers to climate change adaptation"
* Date: 2023-08-25
*--------------------------------------------------



*--------------------------------------------------
* (1) Study 1: Motivated reasoning
*--------------------------------------------------
clear all
use "$working_ANALYSIS\processed\bangladesh2018.dta", clear

*Table S4.	Summary statistics: Study 1
winsor2 rebuild_frequency number_extremes, replace cuts(0 95)
sum number_extremes, d
global overview female age edu income_hh_pp number_extremes rebuild_frequency place_attachment

estpost tabstat $overview, statistics(mean sd min max) columns(statistics)
esttab . using "$working_ANALYSIS\results\tables\tableS4_summary_statistics_study1.rtf", cells("mean(fmt(%9.2fc)) sd(fmt(%9.2fc)) min(fmt(0)) max(fmt(0))")  not nostar unstack nomtitle nonumber nonote label replace



*define globals
global control age female edu income_hh_pp asset_sum
global info is_media is_socialnetwork
global exposure number_extremes land_lost rebuild
global overview age female edu income_hh_pp asset_sum is_media is_socialnetwork number_extremes land_lost rebuild

lab var pp_slr "SLR: Past (1-5)"
lab var fp_slr "SLR: Future (1-5)"
lab var pc_livelihood "Livelihood risk (0-10)"


*--------------------------------------
* Figure 2.	Information avoidance 
*--------------------------------------

*Panel A Frequency distribution of motivated reasoning measurement
tab bias_measurement
mylabels 0(10)60, myscale(@) local(pctlabel) suffix("%")
twoway hist bias_measurement if bias_measurement , discrete percent lcolor(none)  gap(10)  yla(`pctlabel', nogrid) xla(0 `" "-5" "Ignore migration" "consequence" "' 1 `"-4"' 2 `"-3"' 3 "-2" 4 `" "-1" "' 5 `" "0" "Ignore" "neither"' 6 `"1"' 7 `"2"' 8 `"3"' 9 `"4"' 10 `" "5" "Ignore adaptation" "consequence"', nogrid) xtitle("") ytitle("") title("{bf: A} Distribution") xsize(3.465) ysize(3) 
gr save "$working_ANALYSIS\results\intermediate\fig3_a", replace


global reasons ignore_accretion_reason1 ignore_accretion_reason2 ignore_accretion_reason3 ignore_accretion_reason4 ignore_accretion_reason5 ignore_accretion_reason6 ignore_erosion_reason1 ignore_erosion_reason2 ignore_erosion_reason3 ignore_erosion_reason4 ignore_erosion_reason5 ignore_erosion_reason6

estpost tabstat $reasons, statistics(mean sd min max) columns(statistics)
esttab . using "$working_ANALYSIS\results\tables\reasons_ignore.rtf", cells("mean(fmt(%9.2fc)) sd(fmt(%9.2fc)) min(fmt(0)) max(fmt(0))")  not nostar unstack nomtitle nonumber nonote label replace




*Panel B: Motivated reasoning across individuals
/*
When analysing and classifying mobility types one needs to be aware that migrants are on average better educated (Drabo and Mbaye, 2015), wealthier (Richard Black et al., 2011a; Bryan et al., 2014; Cattaneo and Peri, 2016), not female (Gray and Mueller, 2012; Mueller et al., 2014), more risk-loving (Jaeger et al., 2010), less patient (Goldbach and Schlüter, 2018), more tolerant of uncertainty (Williams and Baláž, 2012) and have stronger social ties to the destination (Beine and Parsons, 2015; Haug, 2008; Manchin and Orazbayev, 2018), and less attachment to the place of origin (Bonaiuto et al., 2016).
Variables: education, SES, gender, risk-loving, impatient, less place attached
*/

gen ignore_slr100 = ignore_slr*100
gen ignore_any= 0 if bias_measurement == 5
replace ignore_any = 1 if bias_measurement != 5
gen ignore_any100 = ignore_any*100

*median splits of control variables
foreach x of varlist wealth_pca age place_attachment edu {
	egen aux_`x' = median(`x')
	gen `x'_median = 1 if `x' >= aux_`x'
	replace `x'_median = 0 if `x' < aux_`x'
	drop aux_`x'
}

reg	ignore_slr100 female wealth_pca_median age_median place_attachment_median edu_median, robust
eststo predictions: margins, at(female= (0 1))  at(wealth_pca_median= (0 1))  at(age_median= (0 1) ) at(place_attachment_median= (0 1))  at(edu_median= (0 1)) post


reg	ignore_any100 female wealth_pca_median age_median place_attachment_median edu_median, robust
eststo predictions2: margins, at(female= (0 1))  at(wealth_pca_median= (0 1))  at(age_median= (0 1) ) at(place_attachment_median= (0 1))  at(edu_median= (0 1)) post


eststo all_sample: mean ignore_any100
eststo gender: mean ignore_any100, over(female) coeflegend
eststo SES: mean ignore_any100, over(wealth_pca_median) coeflegend
eststo age: mean ignore_any100, over(age_median) coeflegend
eststo PA:  mean ignore_any100, over(place_attachment_median) coeflegend
eststo edu:  mean ignore_any100, over(edu_median) coeflegend


su ignore_any100, meanonly
local mean_ignore = r(mean)
mylabels 20(10)70, myscale(@) local(pctlabel) suffix("%")
coefplot (all_sample) (gender) (age) (SES) (edu) (PA),  title("{bf: B} Across socio-economic groups") level(95 90) ciopts(lwidth(0.5 1.2) lcolor(*.8 *.2) recast(rcap)) msymbol(D) msize(3pt) nooffsets coeflabels(ignore_any100 = "All sample" c.ignore_any100@0.female = "Men" c.ignore_any100@1.female = "Women" c.ignore_any100@0.wealth_pca_median = "Low" c.ignore_any100@1.wealth_pca_median  = "High" c.ignore_any100@0.age_median = "Below 34" c.ignore_any100@1.age_median  = "34 and above" c.ignore_any100@0.place_attachment_median = "Low" c.ignore_any100@1.place_attachment_median  = "High" c.ignore_any100@0.edu_median  = "Low" c.ignore_any100@1.edu_median  = "High")  groups(c.ignore_any100@0.female c.ignore_any100@1.female = "{bf:Gender}" c.ignore_any100@0.wealth_pca_median c.ignore_any100@1.wealth_pca_median = "{bf:SES}" c.ignore_any100@0.age_median c.ignore_any100@1.age_median  = "{bf:Age}" c.ignore_any100@0.place_attachment_median c.ignore_any100@1.place_attachment_median = "{bf:Attachment}" c.ignore_any100@0.edu_median c.ignore_any100@1.edu_median = "{bf:Education}",) drop(_cons) xline(`mean_ignore', lcolor(gs8) lwidth(medium) lpattern(dash))  legend(off) grid(none)  xla(`pctlabel', nogrid) mlabposition(1) xtitle("Mean ignoring either consequence of SLR") xsize(3.465) ysize(4) 
gr_edit .plotregion1.plot18.style.editstyle marker(fillcolor("100 143 255*1.3")) editcopy
gr_edit .plotregion1.plot16.style.editstyle area(linestyle(color("100 143 255*1.3"))) editcopy
gr save "$working_ANALYSIS\results\intermediate\fig3_b", replace

*differences significant?
probit	ignore_any100 female wealth_pca_median age_median place_attachment_median edu_median, robust
eststo ignore_any: margins, dydx(*) post
probit	ignore_slr100 female wealth_pca_median age_median place_attachment_median edu_median, robust
eststo ignore_slr: margins, dydx(*) post
probit	ignore_alternative female wealth_pca_median age_median place_attachment_median edu_median, robust
eststo ignore_alt: margins, dydx(*) post

esttab ignore_any ignore_slr ignore_alt using "$working_ANALYSIS\results\tables\tableS6_motivated_reasoning_across_groups.rtf", se transform(ln*: exp(@) exp(@)) mtitles("Ignore either" "Ignore SLR" "Ignore Accretion") b(%4.2f)label stats(N r2_p, labels("N" "Pseudo R2") fmt(%4.0f %4.2f)) star(* 0.10 ** 0.05 *** 0.01) varlabels(,elist(weight:_cons "{break}{hline @width}"))  nonotes addnotes("Notes: Average marginal effects calculated after probit regressions with robust standard errors. * p<0.10, ** p<0.05, *** p<0.01") replace


gr combine "$working_ANALYSIS\results\intermediate\fig3_a" "$working_ANALYSIS\results\intermediate\fig3_b", rows(1) graphregion(margin(tiny)) xsize(3.465) ysize(2) scale(1.2)
gr save "$working_ANALYSIS\results\intermediate\figure3_ab.gph", replace


gen confi_bias = 0 if bias_measurement==5
replace confi_bias = 1 if bias_measurement<5
replace confi_bias = 2 if bias_measurement>5
lab def confi_lab 0 "No bias" 1 "Ignore Migration consequences" 2 "Ignore Adaptation consequences", replace
lab val confi_bias confi_lab
tab confi_bias


reg z_pp_slr i.confi_bias $control $info $exposure, vce(robust)
est store reg_slr_pp
reg z_fp_slr i.confi_bias $control $info $exposure, vce(robust)
est store reg_slr_fp
reg z_pc_livelihood i.confi_bias $control $info $exposure, vce(robust)
est store reg_livelihoods
reg z_self_efficacy i.confi_bias $control $info $exposure, vce(robust)
est store reg_self_efficacy


*PANEL C: Estimated correlation of ignoring and awarness
coefplot(reg_slr_pp), bylabel(Past SLR intensity) || (reg_slr_fp),bylabel(Future SLR intensity) || (reg_livelihoods),  bylabel(Risk to livelihoods) ||,  xla(-0.8(0.2)0.2, nogrid labsize(6pt)) byopts(title("{bf:C} Ignoring information correlates with risk awareness", ) compact  imargin(*1.2) rows(1) legend(off))  keep(1.confi_bias 2.confi_bias)  xline(0, lpattern(dash) lcolor(gs3)) xtitle("Association (SD) relative to 'ignore neither'") grid(none) levels(95 90)mlabel(cond(@pval<.005, "***", cond(@pval<.05, "**", cond(@pval<.1, "*", "")))) msize(3pt) msymbol(D) mlabsize(10pt) mlabposition(12) mlabgap(-1.2)  subtitle(, lstyle(none) margin(medium) nobox justification(center) alignment(top) bmargin(top))  xsize(3.465) ysize(2) ciopts(lwidth(0.8 2) lcolor("140 140 140%80" "140 140 140*0.6")  recast(rcap)) mcolor("140 140 140") norecycle plotregion(margin(0 0 0 0)) aspectratio(0.9)

gr save  "$working_ANALYSIS/results/intermediate/fig3_c.gph", replace

gr combine "$working_ANALYSIS\results\intermediate\figure3_ab" "$working_ANALYSIS\results\intermediate\fig3_c", rows(2) graphregion(margin(tiny)) xsize(4) ysize(3) scale(1.2)
graph save "$working_ANALYSIS\results\intermediate\figure2_motivated_reasoning.gph", replace
graph export "$working_ANALYSIS\results\figures\figure2_motivated_reasoning.png", replace width(4500)



*Table S6.	Information avoidance across respondents groups
esttab reg_slr_pp reg_slr_fp reg_livelihoods using "$working_ANALYSIS\results\tables\tableS7_stage1_results.rtf", se keep(1.confi_bias 2.confi_bias  $control $info $exposure _cons)   transform(ln*: exp(@) exp(@))mtitles("Perceived strength SLR hazards (past)" "Perceived strength SLR hazards (future)" "Perceived threat on livelihoods") b(%4.2f)label stats(N r2 r2_a F p, labels("N" "R2" "Adjusted R2" "F statistics" "p") fmt(%4.0f %4.2f)) star(* 0.10 ** 0.05 *** 0.01) varlabels(,elist(weight:_cons "{break}{hline @width}"))  nonotes addnotes("Notes: Estimates are from OLS regressions with robust standard errors. Omitted category is ‘Ignore None’. * p<0.10, ** p<0.05, *** p<0.01") replace


cibar cc_contribution3, over1(confi_bias)
reg cc_contribution3 i.confi_bias $control $info $exposure, vce(robust)

*Determinants of place attachment and migration intentions
global behavioral ignore_any z_risk z_time
reg place_attachment $control 
reg place_attachment $control ignore_any z_pc_livelihood z_pp_slr z_fp_slr z_survey_risk z_survey_time z_self_efficacy
reg z_place $info

gen vol_immobile = 0
replace vol_immobile = 1 if mobility_cat==1
eststo all_sample: mean vol_immobile
eststo bias: mean vol_immobile, over(ignore_any100) coeflegend
reg move_pref ignore_any100 z_survey_time z_survey_risk z_self_efficacy
margins, dydx(*)

mylabels 20(10)70, myscale(@) local(pctlabel) suffix("%")
coefplot (all_sample) (bias) (age) (SES) (edu) (PA),  title("{bf: B} Motivated reasoning across individuals") level(95 90) ciopts(lwidth(0.5 1.2) lcolor(*.8 *.2) recast(rcap)) msymbol(D) msize(3pt) nooffsets coeflabels(ignore_any100 = "All sample" c.ignore_any100@0.female = "Men" c.ignore_any100@1.female = "Women" c.ignore_any100@0.wealth_pca_median = "Low" c.ignore_any100@1.wealth_pca_median  = "High" c.ignore_any100@0.age_median = "Below 34" c.ignore_any100@1.age_median  = "34 and above" c.ignore_any100@0.place_attachment_median = "Low" c.ignore_any100@1.place_attachment_median  = "High" c.ignore_any100@0.edu_median  = "Low" c.ignore_any100@1.edu_median  = "High")  groups(c.ignore_any100@0.female c.ignore_any100@1.female = "{bf:Gender}" c.ignore_any100@0.wealth_pca_median c.ignore_any100@1.wealth_pca_median = "{bf:SES}" c.ignore_any100@0.age_median c.ignore_any100@1.age_median  = "{bf:Age}" c.ignore_any100@0.place_attachment_median c.ignore_any100@1.place_attachment_median = "{bf:Attachment}" c.ignore_any100@0.edu_median c.ignore_any100@1.edu_median = "{bf:Education}",) drop(_cons) xline(`mean_ignore', lcolor(gs8) lwidth(medium) lpattern(dash))  legend(off) grid(none)  xla(`pctlabel', nogrid) mlabposition(1) xtitle("Mean ignoring either information") xsize(4) ysize(4)
gr_edit .plotregion1.plot18.style.editstyle marker(fillcolor("100 143 255*1.3")) editcopy
gr_edit .plotregion1.plot16.style.editstyle area(linestyle(color("100 143 255*1.3"))) editcopy
gr save "$working_ANALYSIS\results\intermediate\fig3_b", replace





*--------------------------------------------------
* (2) Study 2: Sunk cost bias
*--------------------------------------------------
clear all
use "$working_ANALYSIS\processed\bangladesh2021.dta", clear


*hazard mobility response
gen stay_reason_cat = 1 if hazard_move==1
replace stay_reason_cat = 2 if hazard_stay_delib == 0
replace stay_reason_cat = 3 if hazard_stay_delib == 1
lab def why_stay 1 "Moved" 2 "Stayed: No other option" 3 "Stayed: Wanted to", replace
lab val stay_reason_cat why_stay
tab stay_reason_cat

*best measure for sunkcost bias?
gen rebuild_total = rebuild_total_here+ rebuild_total_near
sum rebuild_total, detail
winsor2 rebuild_total, cuts(0 95)
*outcome: move_pref, for those who stay additionally: compensation_accept
winsor2 hazard_number, cuts(0 95)

*median splits of control variables
foreach x of varlist income_average_hh age place_attach edu_yr {
	egen aux_`x' = median(`x')
	gen `x'_median = 1 if `x' >= aux_`x'
	replace `x'_median = 0 if `x' < aux_`x'
	drop aux_`x'
}

*Table S5.	Summary statistics: Study 2
global overview age female edu_yr income_average_hh hazard_number_w rebuild_total_w place_attach

estpost tabstat $overview, statistics(mean sd min max) columns(statistics)
esttab . using "$working_ANALYSIS\results\tables\tableS5_summary_statistics_study2.rtf", cells("mean(fmt(%9.2fc)) sd(fmt(%9.2fc)) min(fmt(0)) max(fmt(0))")  not nostar unstack nomtitle nonumber nonote label replace



* Exposure to environmental hazards in the past 5 years
sum hazard_number_w, detail
tab1 hazard_type hazard_injured_self hazard_injured_other hazard_killed_other hazard_house_damage hazard_land_lost hazard_buildings_damage hazard_animals_harmed


*Number of times rebuild at same location / within 500m
sum rebuild_total_w, detail
pwcorr rebuild_total_w place_attach edu_yr income_average_hh, sig

*-----------------------------
* Figure 3.	Sunk-cost bias
*-----------------------------
*Panel A: reasons selected
foreach x of varlist stay_reason_entitlement stay_reason_afraid stay_reason_resources stay_reason_invested {
	replace `x'=100*`x'
}
betterbarci  stay_reason_entitlement stay_reason_afraid stay_reason_resources stay_reason_invested, vertical barlab format(%5.1f)  xla(2 "Sunk costs" 8 "Lack resources" 14 "Fear being worse off" 20 "Lose land entitlement")  title("{bf: A} Reasons to prefer staying over moving", size(10pt))  yla(0(20)100) ytitle("Mean", size(6pt))  xsize(3.465) ysize(3)  legend(ring (1) pos(6) rows(1) size(6pt))
gr_edit xaxis1.style.editstyle majorstyle(tickangle(stdarrow)) editcopy
gr_edit legend.draw_view.setstyle, style(no)
gr_edit plotregion1.plot3.style.editstyle label(textstyle(size(medium))) editcopy
gr_edit plotregion1.plot3.style.editstyle label(textstyle(size(medsmall))) editcopy
gr_edit yaxis1.style.editstyle majorstyle(tickstyle(textstyle(size(medsmall)))) editcopy
gr_edit xaxis1.style.editstyle majorstyle(tickstyle(textstyle(size(medium)))) editcopy
gr save  "$working_ANALYSIS/results/intermediate/fig5_a.gph", replace 

betterbarci  stay_reason_entitlement stay_reason_afraid stay_reason_resources stay_reason_invested, over(t_sunkcost)  vertical barlab format(%5.1f)  xla(4 "Sunk costs" 16 "Lack resources" 30 "Fear being worse off" 42 "Lose land entitlement")  title("{bf: A} Reasons to prefer staying over moving", size(10pt))  yla(0(20)100) ytitle("Mean", size(6pt))  xsize(3) ysize(2)  legend(ring (1) pos(6) rows(1) size(6pt))
gr save  "$working_ANALYSIS/results/intermediate/figureS3_sunk_cost_treatment.gph", replace 
graph export "$working_ANALYSIS\results\figures\figureS3_sunk_cost_treatment.png", replace width(3465)



preserve
use "$working_ANALYSIS\processed\bangladesh2021.dta", clear

*best measure for sunkcost bias?
gen rebuild_total = rebuild_total_here+ rebuild_total_near
sum rebuild_total, detail
winsor2 rebuild_total, cuts(0 95)
*outcome: move_pref, for those who stay additionally: compensation_accept


*median splits of control variables
foreach x of varlist income_average_hh age place_attach edu_yr {
	egen aux_`x' = median(`x')
	gen `x'_median = 1 if `x' >= aux_`x'
	replace `x'_median = 0 if `x' < aux_`x'
	drop aux_`x'
}



*stay_reason_invested stay_reason_open, impute values for stay_reason_invested for those who got the open question
* rebuild at same place  before?
* Ensure deterministic data order for reproducible MI
set sortseed 1234
sort female age place_attach edu_yr income_average_hh hazard_number rebuild_total_w, stable

** Set dataset in memory as MI dataset
mi set flong // set dataset in memory as "MI" dataset; _mi_miss, _mi_m, and _mi_id generated to track imputed datasets and values

** Inspect missing values
mi misstable summarize stay_reason_invested stay_reason_entitlement stay_reason_afraid stay_reason_resources land_lost compensation_accept land_lost
mi misstable patterns stay_reason_invested stay_reason_entitlement stay_reason_afraid stay_reason_resources land_lost compensation_accept land_lost

/* Imputation model specification
- Include in the imputation model all the variables (also interaction-terms) that will be included in the analysis model
- Include in the imputation model the outcome variable for the analysis model
- Include variables that are related to the missingness and variables that are correlated with variables of interest (recommendation r>.4)
*/

*variables to be imputed
mi register imputed stay_reason_invested stay_reason_entitlement stay_reason_afraid stay_reason_resources compensation_accept land_lost
mi describe

mi impute chained (pmm, knn(5)) stay_reason_invested stay_reason_entitlement stay_reason_afraid stay_reason_resources compensation_accept land_lost = female income_average_hh_median age_median place_attach_median edu_yr_median rebuild_total_w hazard_number cc_adapt_stilts, add(20) rseed(1234)

/*
Imputation diagnostics
After performing an imputation it is also useful to look at means, frequencies and box plots comparing observed and imputed values to assess if the range appears reasonable. You may also want to examine plots of residuals and outliers for each imputed dataset individually. If anomalies are evident in only a small number of imputations then this indicates a problem with the imputation model (White et al, 2010).
*/

mi xeq 0 1 20: summarize stay_reason_invested stay_reason_entitlement stay_reason_afraid stay_reason_resources land_lost
mi describe


replace stay_reason_invested=stay_reason_invested*100
*means across groups
mi estimate, post: mean stay_reason_invested if move_pref==0
local mean_sunk = _b[stay_reason_invested]
estimates store all_sample
mi estimate, post: mean stay_reason_invested if move_pref==0, over(female) coeflegend
estimates store gender 
mi estimate, post: mean stay_reason_invested if move_pref==0, over(income_average_hh_median) coeflegend
estimates store SES
mi estimate, post: mean stay_reason_invested if move_pref==0, over(age_median) coeflegend
estimates store age
mi estimate, post: mean stay_reason_invested if move_pref==0, over(place_attach_median) coeflegend
estimates store PA 
mi estimate, post: mean stay_reason_invested if move_pref==0, over(edu_yr_median) coeflegend
estimates store edu 


* are differences significant across groups?
replace stay_reason_resources=stay_reason_resources*100
replace stay_reason_afraid=stay_reason_afraid*100
replace stay_reason_entitlement=stay_reason_entitlement*100
mi estimate, post: reg stay_reason_invested female income_average_hh_median age_median place_attach_median edu_yr_median if move_pref==0, robust
est sto sunk_cost

mi estimate, post: reg stay_reason_resources female income_average_hh_median age_median place_attach_median edu_yr_median if move_pref==0,robust
est sto resources

mi estimate, post: reg stay_reason_afraid female income_average_hh_median age_median place_attach_median edu_yr_median if move_pref==0,robust
est sto afraid

mi estimate, post: reg stay_reason_entitlement female income_average_hh_median age_median place_attach_median edu_yr_median if move_pref==0, robust
est sto land


*association of reasons with self-efficacy
mi estimate, post: reg z_self_efficacy stay_reason_invested stay_reason_entitlement stay_reason_afraid stay_reason_resources  female income_average_hh_median age_median place_attach_median edu_yr_median if move_pref==0,robust
est sto efficacy
restore

*Table S8.	Sunk cost bias across respondent groups
esttab sunk_cost resources afraid land using "$working_ANALYSIS\results\tables\tableS8_sunk_costs_across_groups.rtf", se transform(ln*: exp(@) exp(@)) mtitles("Sunk costs" "Lack resources" " Fear being worse off" "Loss land entitlement") b(%4.2f)label stats(N F_mi p_mi, labels("N" "F-statistic" "p-value") fmt(%4.0f %4.2f %4.3f)) star(* 0.10 ** 0.05 *** 0.01) varlabels(,elist(weight:_cons "{break}{hline @width}"))  nonotes addnotes("Notes: Linear probability model (OLS) with multiple imputation and robust standard errors." "Dependent variables are binary (0/100); predicted values may fall outside [0, 100]." "* p<0.10, ** p<0.05, *** p<0.01") replace


*Panel B: Sunkcost the reason why they prefer to stay
mylabels 0(20)80, myscale(@) local(pctlabel) suffix("%")
coefplot (all_sample) (gender) (age) (SES) (edu) (PA),  title("{bf: B} Reason: Sunk costs") level(95 90) ciopts(lwidth(0.5 1.2) lcolor(*.8 *.2) recast(rcap)) msymbol(D) msize(4pt) nooffsets coeflabels(stay_reason_invested = "All sample" c.stay_reason_invested@0.female = "Men" c.stay_reason_invested@1.female = "Women" c.stay_reason_invested@0.income_average_hh_median = "Low" c.stay_reason_invested@1.income_average_hh_median  = "High" c.stay_reason_invested@0.age_median = "Below 34" c.stay_reason_invested@1.age_median  = "34 and above" c.stay_reason_invested@0.place_attach_median = "Low" c.stay_reason_invested@1.place_attach_median  = "High" c.stay_reason_invested@0.edu_yr_median  = "Low" c.stay_reason_invested@1.edu_yr_median  = "High")  groups(c.stay_reason_invested@0.female c.stay_reason_invested@1.female = "{bf:Gender}" c.stay_reason_invested@0.income_average_hh_median c.stay_reason_invested@1.income_average_hh_median = "{bf:SES}"c.stay_reason_invested@0.age_median c.stay_reason_invested@1.age_median  = "{bf:Age}" c.stay_reason_invested@0.place_attach_median c.stay_reason_invested@1.place_attach_median = "{bf:Attachment}" c.stay_reason_invested@0.edu_yr_median c.stay_reason_invested@1.edu_yr_median = "{bf:Education}",) drop(_cons) xline(`mean_sunk', lcolor(gs8) lwidth(medium) lpattern(dash))  legend(off) grid(none)  xla(`pctlabel', nogrid) mlabposition(1) xtitle("Mean sunk cost") xsize(3.465) ysize(3)
gr_edit plotregion1.plot18.style.editstyle marker(fillcolor("100 143 255*1.3")) editcopy
gr_edit plotregion1.plot16.style.editstyle area(linestyle(color("100 143 255*1.3"))) editcopy
gr save  "$working_ANALYSIS/results/intermediate/fig5_b.gph", replace


gr combine "$working_ANALYSIS\results\intermediate\fig5_a" "$working_ANALYSIS\results\intermediate\fig5_b", rows(1) graphregion(margin(tiny)) xsize(4) ysize(2) scale(1.1)
gr_edit plotregion1.graph1.title.style.editstyle size(10-pt) editcopy
gr_edit plotregion1.graph2.title.style.editstyle size(10-pt) editcopy
gr_edit plotregion1.graph2.yaxis1.style.editstyle majorstyle(tickstyle(textstyle(size(6-pt)))) editcopy
gr_edit plotregion1.graph2.yaxis2.style.editstyle majorstyle(tickstyle(textstyle(size(6-pt)))) editcopy
gr_edit plotregion1.graph2.xaxis1.style.editstyle majorstyle(tickstyle(textstyle(size(6-pt)))) editcopy
gr_edit plotregion1.graph2.xaxis1.title.locked = 1
gr_edit plotregion1.graph2.xaxis1.title.locked = 0
gr_edit plotregion1.graph2.xaxis1.title.draw_view.setstyle, style(no)
gr save "$working_ANALYSIS\results\intermediate\figure3_sunkcosts.gph", replace
graph export "$working_ANALYSIS\results\figures\figure3_sunkcosts.png", replace width(3465)





*----------------------------------------------------------
* (3) Stage 3: Risk aversion, impatience, & self-efficacy
*----------------------------------------------------------
clear all
use "$working_ANALYSIS\processed\risk_time_rdy.dta"

*globals
global controls female age edu place_attachment income_hh_pp sample

*------------------------------------------------------------------------
*Figure 4.	Patience and risk aversion compared to average in Bangladesh
*------------------------------------------------------------------------


*Panel A:
twoway (kdensity risktaking_norm if sample==1) (kdensity risktaking_norm if sample==2) (kdensity risktaking_norm if sample==3), yla(, nogrid)   xla(0(20)100) title("{bf:A} Risk taking") legend(row(1) order(1 2 3) stack label(1 "Study 1")  label(2 "Study 2") label(3 "GPS")) xtitle("Higher values imply more risk taking") ytitle("Density") 
gr save "$working_ANALYSIS\results\intermediate\fig6_a", replace
kwallis risktaking_norm,  by(sample)
kwallis risktaking_norm if sample!=3, by(sample)

*Panel B:
*median splits of control variables

eststo all_sample: mean risktaking_norm if sample <3
eststo gender: mean risktaking_norm if sample <3, over(female) coeflegend
eststo SES: mean risktaking_norm if sample <3, over(income_hh_pp_median) coeflegend
eststo age: mean risktaking_norm if sample <3, over(age_median) coeflegend
eststo PA:  mean risktaking_norm if sample <3, over(place_attachment_median) coeflegend
eststo edu:  mean risktaking_norm if sample <3, over(edu_median) coeflegend

*eststo risky: reg risktaking_norm female income_hh_pp_median age_median place_attachment_median edu_median, robust


su risktaking_norm if sample <3, meanonly
local mean_risk = r(mean)
mylabels 35(5)55, myscale(@) local(pctlabel)
coefplot (all_sample) (gender) (age) (SES) (edu) (PA),  title("{bf: B} Risk taking across groups") level(95 90) ciopts(lwidth(0.5 1.2) lcolor(*.8 *.2) recast(rcap)) msymbol(D) msize(3pt) nooffsets coeflabels(risktaking_norm = "All sample" c.risktaking_norm@0.female = "Men" c.risktaking_norm@1.female = "Women" c.risktaking_norm@0.income_hh_pp_median = "Low" c.risktaking_norm@1.income_hh_pp_median  = "High" c.risktaking_norm@0.age_median = "Below 34" c.risktaking_norm@1.age_median  = "34 and above" c.risktaking_norm@0.place_attachment_median = "Low" c.risktaking_norm@1.place_attachment_median  = "High" c.risktaking_norm@0.edu_median  = "Low" c.risktaking_norm@1.edu_median  = "High")  groups(c.risktaking_norm@0.female c.risktaking_norm@1.female = "{bf:Gender}" c.risktaking_norm@0.income_hh_pp_median c.risktaking_norm@1.income_hh_pp_median = "{bf:SES}" c.risktaking_norm@0.age_median c.risktaking_norm@1.age_median  = "{bf:Age}" c.risktaking_norm@0.place_attachment_median c.risktaking_norm@1.place_attachment_median = "{bf:Attachment}" c.risktaking_norm@0.edu_median c.risktaking_norm@1.edu_median = "{bf:Education}",) drop(_cons) xline(`mean_risk', lcolor(gs8) lwidth(medium) lpattern(dash))  legend(off) grid(none)   xla(`pctlabel', nogrid) mlabposition(1)  xsize(3.465) ysize(4)
gr_edit plotregion1.plot18.style.editstyle marker(fillcolor("100 143 255*1.3")) editcopy
gr_edit plotregion1.plot16.style.editstyle area(linestyle(color("100 143 255*1.3"))) editcopy
gr save "$working_ANALYSIS\results\intermediate\fig6_b", replace


*Panel C:
reg patience_norm i.mobility_cat, robust

twoway (kdensity patience_norm if sample==1) (kdensity patience_norm if sample==2) (kdensity patience_norm if sample==3) , yla(, nogrid)  xla(0(20)100)  title("{bf:C} Patience") legend(row(1) order(1 2 3) stack  label(1 "Study 1")  label(2 "Study 2") label(3 "GPS")) xtitle("Higher values imply  more patience") ytitle("Density")
gr save "$working_ANALYSIS\results\intermediate\fig6_c", replace
kwallis patience_norm, by(sample)
kwallis patience_norm if sample!=3, by(sample)

*panel D:
eststo all_sample: mean patience_norm if sample <3
eststo gender: mean patience_norm if sample <3, over(female) coeflegend
eststo SES: mean patience_norm if sample <3, over(income_hh_pp_median) coeflegend
eststo age: mean patience_norm if sample <3, over(age_median) coeflegend
eststo PA:  mean patience_norm if sample <3, over(place_attachment_median) coeflegend
eststo edu:  mean patience_norm if sample <3, over(edu_median) coeflegend

*eststo patience: reg patience_norm female income_hh_pp_median age_median place_attachment_median edu_median, robust

su patience_norm if sample <3, meanonly
local mean_patience = r(mean)
mylabels 15(5)35, myscale(@) local(pctlabel)
coefplot (all_sample) (gender) (age) (SES) (edu) (PA),  title("{bf: D} Patience across groups") level(95 90) ciopts(lwidth(0.5 1.2) lcolor(*.8 *.2) recast(rcap)) msymbol(D) msize(3pt) nooffsets coeflabels(patience_norm = "All sample" c.patience_norm@0.female = "Men" c.patience_norm@1.female = "Women" c.patience_norm@0.income_hh_pp_median = "Low" c.patience_norm@1.income_hh_pp_median  = "High" c.patience_norm@0.age_median = "Below 34" c.patience_norm@1.age_median  = "34 and above" c.patience_norm@0.place_attachment_median = "Low" c.patience_norm@1.place_attachment_median  = "High" c.patience_norm@0.edu_median  = "Low" c.patience_norm@1.edu_median  = "High")  groups(c.patience_norm@0.female c.patience_norm@1.female = "{bf:Gender}" c.patience_norm@0.income_hh_pp_median c.patience_norm@1.income_hh_pp_median = "{bf:SES}" c.patience_norm@0.age_median c.patience_norm@1.age_median  = "{bf:Age}" c.patience_norm@0.place_attachment_median c.patience_norm@1.place_attachment_median = "{bf:Attachment}" c.patience_norm@0.edu_median c.patience_norm@1.edu_median = "{bf:Education}",) drop(_cons) xline(`mean_patience', lcolor(gs8) lwidth(medium) lpattern(dash))  legend(off) grid(none)   xla(`pctlabel', nogrid) mlabposition(1)  xsize(3.465) ysize(4)
gr_edit plotregion1.plot18.style.editstyle marker(fillcolor("100 143 255*1.3")) editcopy
gr_edit plotregion1.plot16.style.editstyle area(linestyle(color("100 143 255*1.3"))) editcopy
gr save "$working_ANALYSIS\results\intermediate\fig6_d", replace


*panel E:
sum self_efficacy_norm, detail
twoway (kdensity self_efficacy_norm if sample==1) (kdensity self_efficacy_norm if sample==2) , yla(, nogrid)  xla(0(20)100)  title("{bf:E} Self-efficacy") legend(row(1) order(1 2 3) stack  label(1 "Study 1")  label(2 "Study 2") ) xtitle("Higher values imply  more self-efficacy") ytitle("Density")
gr save "$working_ANALYSIS\results\intermediate\fig6_e", replace
kwallis self_efficacy_norm, by(sample)

ttest self_efficacy_norm, by(sample)
stripplot self_efficacy_norm, over(sample)  title("{bf: A} Cumulative distribution")  mcolor("98 142 255*.7" "98 142 255*.7" "98 142 255*.7") msymbol(oh oh oh) yla(0(20)100 , nogrid)  xtitle("Sample") ytitle("Self-efficacy (index)") vertical center cumul cumprob bar boffset(.2) refline(lw(medium)  lc(gs6) lp(dash)) reflinestretch(-0.2) xla(, noticks) yla(, ang(h)) xlab(1 "Study 1" 2 "Study 2") height(0.8) legend(order(4 "Observation" 3 "Mean" 2 "95% CI") rowgap(zero) keygap(tiny) size(small) region(fcolor(none) lcolor(none)) ring(0) pos(5) cols(1)) xsize(3) ysize(2)
gr save "$working_ANALYSIS\results\intermediate\fig7_a", replace


*Panel F:
eststo all_sample: mean self_efficacy_norm if sample <3
eststo gender: mean self_efficacy_norm if sample <3, over(female) coeflegend
eststo SES: mean self_efficacy_norm if sample <3, over(income_hh_pp_median) coeflegend
eststo age: mean self_efficacy_norm if sample <3, over(age_median) coeflegend
eststo PA:  mean self_efficacy_norm if sample <3, over(place_attachment_median) coeflegend
eststo edu:  mean self_efficacy_norm if sample <3, over(edu_median) coeflegend

*eststo selfy: reg self_efficacy_norm female income_hh_pp_median age_median place_attachment_median edu_median, robust

su self_efficacy_norm if sample <3, meanonly
local mean_efficacy = r(mean)
mylabels 30(5)45, myscale(@) local(pctlabel)
coefplot (all_sample) (gender) (age) (SES) (edu) (PA),  title("{bf: F} Self-efficacy across groups") level(95 90) ciopts(lwidth(0.5 1.2) lcolor(*.8 *.2) recast(rcap)) msymbol(D) msize(3pt) nooffsets coeflabels(self_efficacy_norm = "All sample" c.self_efficacy_norm@0.female = "Men" c.self_efficacy_norm@1.female = "Women" c.self_efficacy_norm@0.income_hh_pp_median = "Low" c.self_efficacy_norm@1.income_hh_pp_median  = "High" c.self_efficacy_norm@0.age_median = "Below 34" c.self_efficacy_norm@1.age_median  = "34 and above" c.self_efficacy_norm@0.place_attachment_median = "Low" c.self_efficacy_norm@1.place_attachment_median  = "High" c.self_efficacy_norm@0.edu_median  = "Low" c.self_efficacy_norm@1.edu_median  = "High")  groups(c.self_efficacy_norm@0.female c.self_efficacy_norm@1.female = "{bf:Gender}" c.self_efficacy_norm@0.income_hh_pp_median c.self_efficacy_norm@1.income_hh_pp_median = "{bf:SES}" c.self_efficacy_norm@0.age_median c.self_efficacy_norm@1.age_median  = "{bf:Age}" c.self_efficacy_norm@0.place_attachment_median c.self_efficacy_norm@1.place_attachment_median = "{bf:Attachment}" c.self_efficacy_norm@0.edu_median c.self_efficacy_norm@1.edu_median = "{bf:Education}",) drop(_cons) xline(`mean_efficacy', lcolor(gs8) lwidth(medium) lpattern(dash))  legend(off) grid(none)   xla(`pctlabel', nogrid) mlabposition(1)  xsize(3.465) ysize(4)
gr_edit plotregion1.plot18.style.editstyle marker(fillcolor("100 143 255*1.3")) editcopy
gr_edit plotregion1.plot16.style.editstyle area(linestyle(color("100 143 255*1.3"))) editcopy
gr save "$working_ANALYSIS\results\intermediate\fig6_f", replace


gr combine "$working_ANALYSIS\results\intermediate\fig6_a" "$working_ANALYSIS\results\intermediate\fig6_b" "$working_ANALYSIS\results\intermediate\fig6_c" "$working_ANALYSIS\results\intermediate\fig6_d" "$working_ANALYSIS\results\intermediate\fig6_e" "$working_ANALYSIS\results\intermediate\fig6_f", rows(3) xsize(3.465) ysize(4)  graphregion(margin(tiny))
gr save "$working_ANALYSIS\results\intermediate\figure4_risk_time_efficacy.gph", replace
graph export "$working_ANALYSIS\results\figures\figure4_risk_time_efficacy.png", replace width(4500)


*Table S9.	Impatience, risk aversion, and self-efficacy across respondent groups
* Using mi estimate for proper inference on imputed composites
preserve
use "$working_ANALYSIS\processed\risk_time_mi.dta", clear

mi estimate, post: reg risktaking_norm female income_hh_pp_median age_median place_attachment_median edu_median, robust
eststo risky_mi

mi estimate, post: reg patience_norm female income_hh_pp_median age_median place_attachment_median edu_median, robust
eststo patience_mi

mi estimate, post: reg self_efficacy_norm female income_hh_pp_median age_median place_attachment_median edu_median, robust
eststo selfy_mi

restore

* Individual self-efficacy items (no MI needed — fully observed)
* Pool Study 1 and Study 2, harmonize item names
preserve
use "$working_ANALYSIS\processed\bangladesh2018.dta", clear
gen sample = 1
gen item1_norm = (6 - cc_contribution1 - 1) / 4 * 100
gen item2_norm = (6 - cc_contribution3 - 1) / 4 * 100
keep sample item1_norm item2_norm female age edu income_hh_pp place_attachment
save "$working_ANALYSIS\processed\temp_efficacy_s1.dta", replace

use "$working_ANALYSIS\processed\bangladesh2021.dta", clear
gen sample = 2
gen item1_norm = (6 - cc_uncertain - 1) / 4 * 100
gen item2_norm = (6 - cc_agency - 1) / 4 * 100
rename edu_yr edu
rename place_attach place_attachment
rename income_average_hh income_hh_pp
keep sample item1_norm item2_norm female age edu income_hh_pp place_attachment

append using "$working_ANALYSIS\processed\temp_efficacy_s1.dta"
erase "$working_ANALYSIS\processed\temp_efficacy_s1.dta"

lab var item1_norm "Uncertain about best options (reversed, 0-100)"
lab var item2_norm "CC too big for me (reversed, 0-100)"

foreach x of varlist income_hh_pp age place_attachment edu {
	egen aux_`x' = median(`x')
	gen `x'_median = 1 if `x' >= aux_`x'
	replace `x'_median = 0 if `x' < aux_`x'
	drop aux_`x'
}

eststo item1: reg item1_norm female income_hh_pp_median age_median place_attachment_median edu_median, robust
eststo item2: reg item2_norm female income_hh_pp_median age_median place_attachment_median edu_median, robust

restore

esttab risky_mi patience_mi selfy_mi item1 item2 using "$working_ANALYSIS\results\tables\tableS9_risk_time_efficacy_across_groups.rtf", se mtitles("Risk taking" "Patience" "Self-efficacy" "Uncertain about options" "CC too big for me") b(%4.2f) label stats(N F_mi p_mi r2 F p, labels("N" "F-statistic (MI)" "p-value (MI)" "R2" "F-statistic" "p-value") fmt(%4.0f %4.2f %4.3f %4.2f %4.2f %4.3f)) star(* 0.10 ** 0.05 *** 0.01) nonotes addnotes("Notes: Columns 1-3 use OLS regressions combined across 20 multiple imputations via Rubin's rules." "Columns 4-5 use OLS on observed (non-imputed) individual self-efficacy items, pooled across studies." "Items reverse-coded: higher values = stronger self-efficacy. Robust standard errors." "* p<0.10, ** p<0.05, *** p<0.01") replace



*Figure S4: Behavioral factors differ across mobility types
*Risk taking
lab def moby 1 " Voluntary immobile (n=184)" 2 "Acquiescent immobile (n=295)" 3 "Involuntary immobile (n=73)" 4 "Potentially mobile (n=80)"
lab val mobility_cat moby
tab mobility_cat
*eststo risky_mob: reg risktaking_norm i.mobility_cat $controls, robust
betterbarci risktaking_norm if mobility_cat==1 | mobility_cat==4, over(mobility_cat)  vertical barlab format(%5.0f)   title("{bf: A} Risk attitudes", size(10pt))  yla(0(20)100, nogrid) ytitle("Mean", size(6pt)) xla("")  xsize(3) ysize(2)  legend(ring (1) pos(6) rows(1) size(6pt))
gr save  "$working_ANALYSIS/results/intermediate/risk_mobility.gph", replace 

*Patience
*eststo patience_mob: reg patience_norm i.mobility_cat $controls, robust
betterbarci patience_norm if mobility_cat==1 | mobility_cat==4, over(mobility_cat)  vertical barlab format(%5.0f)    title("{bf: B} Patience", size(10pt))  yla(0(20)100, nogrid) ytitle("Mean", size(6pt)) xla("")  xsize(3) ysize(2)  legend(ring (1) pos(6) rows(1) size(6pt))
gr save  "$working_ANALYSIS/results/intermediate/patience_mobility.gph", replace 

*Efficacy
*eststo efficacy_mob: reg self_efficacy_norm i.mobility_cat $controls, robust
betterbarci self_efficacy_norm if mobility_cat==1 | mobility_cat==4, over(mobility_cat)  vertical barlab format(%5.0f)    title("{bf: C} Adaptation self-efficacy", size(10pt))  yla(0(20)100, nogrid) ytitle("Mean", size(6pt)) xla("")  xsize(3) ysize(2)  legend(ring (1) pos(6) rows(2) size(6pt))
gr save  "$working_ANALYSIS/results/intermediate/efficacy_mobility.gph", replace 


* behavioral factors by mobility types
grc1leg  "$working_ANALYSIS\results\intermediate\risk_mobility" "$working_ANALYSIS\results\intermediate\patience_mobility" "$working_ANALYSIS\results\intermediate\efficacy_mobility", rows(1) xsize(3) ysize(2) scale(1.4) graphregion(margin(tiny))
gr save "$working_ANALYSIS\results\intermediate\figureS4_behavioral_mobilty_types.gph", replace
graph export "$working_ANALYSIS\results\figures\figureS4_behavioral_mobilty_types.png", replace width(4500)

* Using mi estimate for mobility type regressions
preserve
use "$working_ANALYSIS\processed\risk_time_mi.dta", clear

global controls female age edu place_attachment income_hh_pp sample
lab def moby 1 " Voluntary immobile (n=184)" 2 "Acquiescent immobile (n=295)" 3 "Involuntary immobile (n=73)" 4 "Potentially mobile (n=80)"
lab val mobility_cat moby

mi estimate, post: reg risktaking_norm i.mobility_cat $controls, robust
eststo risky_mob_mi

mi estimate, post: reg patience_norm i.mobility_cat $controls, robust
eststo patience_mob_mi

mi estimate, post: reg self_efficacy_norm i.mobility_cat $controls, robust
eststo efficacy_mob_mi

esttab risky_mob_mi patience_mob_mi efficacy_mob_mi using "$working_ANALYSIS\results\tables\tableS10_determinants_behavioral.rtf", se mtitles("Risk taking" "Patience" "Self-efficacy") b(%4.2f) label stats(N F_mi p_mi, labels("N" "F-statistic" "p-value") fmt(%4.0f %4.2f %4.3f)) star(* 0.10 ** 0.05 *** 0.01) nonotes addnotes("Notes: Estimates are from OLS regressions combined across 20 multiple imputations via Rubin's rules with robust standard errors. * p<0.10, ** p<0.05, *** p<0.01") replace

restore







*--------------------------------------------------


**EOF