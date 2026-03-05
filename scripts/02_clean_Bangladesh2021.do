*--------------------------------------------------------------------------------------
* SCRIPT: 02_clean_Bangladesh2021.do
* PURPOSE: This do-files cleans household surveys conducted in Bangladesh in 2021.
*--------------------------------------------------------------------------------------

*----------------------------
* 1) Import excel dataset and cleaning
*----------------------------
*--------------------------------------------------
* Description
*--------------------------------------------------
/*


 I) Translation of answers to open questions
 II) Survey
     1) Cleaning: labels, renaming of variables
     2) Generating new variables
     3) Merge with translated answers
*/
*/
*--------------------------------------------------




*----------------------------------------------
* I) Translation of answers to open questions
*----------------------------------------------
clear all
import excel using "$working_ANALYSIS\data\bangladesh2021_translations.xlsx", sheet("Sheet1") clear


foreach var of varlist * {
  label variable `var' "`=`var'[1]'"
  replace `var'="" if _n==1
  destring `var', replace
}

* Keep open answer items
keep A O P X AU BM BA CV

drop if A == .

* Rename accordingly
rename A id
rename P phone
rename X hh_decision_other
rename AU move_reason_open 
lab var move_reason_open "Open: Reasons for you to move?"
rename BA stay_reason_open
lab var stay_reason_open "Open: Reasons for you to stay?"
rename BM hazard_name
rename CV cc_adapt_other_which
lab var cc_adapt_other_which "Type of other measures taken"

* Add _transl
foreach var in phone hh_decision_other move_reason_open stay_reason_open hazard_name cc_adapt_other_which {
	rename `var' `var'_transl	
}

	
save "$working_ANALYSIS\processed\bangladesh2021_aux1.dta", replace




*-----------------------
* II) Survey cleaning
*-----------------------
*Load raw dataset
import excel "$working_ANALYSIS\data\bangladesh2021.xlsx", sheet("hh_survey_BD_2021_translated") clear


replace IY="Welcoming Attitude [1 - not at all ,5 - very]" in 1 
replace IZ="Welcoming Attitude [1 - not at all ,5 - very]" in 1 
replace SY="Welcoming Attitude [1 - not at all ,5 - very]" in 1 
replace XF="Welcoming Attitude [1 - not at all ,5 - very]" in 1 
replace ABN="Welcoming Attitude [1 - not at all ,5 - very]" in 1 
replace AFH="It is common for people who are motivated enough to go from rags to riches" in 1

drop C D F H CN ABT ADN


foreach var of varlist * {
  label variable `var' "`=`var'[1]'"
  replace `var'="" if _n==1
  destring `var', replace
}

sort A

drop in 1/10 // Functionality test observations

*** Rename to lower case
rename IF union_move_to_jhenaida // variables are not allowed to be named 'if'
rename IN village_moved_to // variables not allowed to be named 'in'
rename *, lower



*** Rename variables
** Setup
rename a start
rename b end

label define interviewer1 1	"Assistant 1" 2	"Assistant 2" 3	"Assistant 3" 4	"Assistant 4" 5	"Assistant 5" 6 "Prosun" 7 "Ashequl" 8 "Sarah" 9 "Jasia"
encode e, generate(interviewer) label(interviewer1)
label define interviewer2 1	"Assist 1" 2 "Assist 2" 3 "Assist 3" 4 "Assist 4" 5	"Assist 5" 6 "Prosun" 7 "Ashequl" 8 "Sarah" 9 "Jasia"
lab val interviewer interviewer2

rename g date
rename i interview_village
gen d_interivew_village = interview_village if interview_village != "Atulia Union" & interview_village != "Gabura Union" & interview_village != "Kushlia Union"  & interview_village != "Nurnagar Union"  & interview_village != "Ishwaripur Union"  
encode d_interivew_village , generate(village) 

label define place_interview 1 "Home" 2 "Workplace" 3 "Other" , replace
encode j, generate(interview_place) label(place_interview)
rename k notes

rename l t_sunkcost
label define t_sc 1 "Control" 2 "T1: Sunk Cost" 3 "T2: Sunk Cost + CCC" , replace
label values t_sunkcost t_sc
 
rename m t_resettlement
drop t_resettlement // not asked

rename n t_scenario
label define t_secnario1 1 "Minor repair last month" 2 "Major repair last month" 3 "Minor repair 3 years ago" 4 "Major repair 3 years ago" , replace
label value t_scenario t_secnario1 

rename o t_open_question // otherway-round coded in survey [1 -> people received closed questions and 0 people received open questions]
replace t_open_question = (t_open_question - 1) * (-1)

label define yes_no 1 "yes" 0 "no" , replace
encode q , generate(participate) label(yes_no)

** Socio-Econ 1
rename r name
rename s phone
tostring phone, replace

label define female1 0 "Male" 1 "Female", replace
encode t, generate(female) label(female1)

label define marital1 1 "Never married" 2 "Married" 3 "Widowed" 4 "Divorced" 5 "Abandoned / separated" 6 "Other", replace
encode u, generate(marital) label(marital1)

label define worse_better -1 "worse" 0 "same" 1 "better", replace
encode age, generate(children_health) label(worse_better)
drop age

rename v age
rename w edu_yr

label define hh_decision1 1	"Me" 2 "My spouse" 3 "Me and my spouse" 4 "Someone else" , replace
encode x , gen(hh_decision) label(hh_decision1)
rename z hh_decision_other

rename y birth_yr

label define religion1 1 "Muslims" 2 "Hindus" 3	"Buddhists" 4 "Christians" 5 "Aboriginal" 6 "Other"
encode aa , generate(religion) label(religion1)

rename ah children
rename ai hh_member
rename ak hh_member_6
rename al hh_member_6_12
rename am hh_member_13_18
rename an hh_member_19_30
rename ao hh_member_31_60
rename ap hh_member_60
rename aq hh_member_6_18
rename ar edu_primary_6_18
rename as edu_primary_19_30
rename at edu_higher_19_30

gen hh_member_check_6_18 = hh_member_6_12 +hh_member_13_18 
tab hh_member_check_6_18 edu_primary_6_18
tab hh_member_19_30 edu_primary_19_30
tab hh_member_19_30 edu_higher_19_30

foreach var in hh_member_6 hh_member_6_12 hh_member_13_18 hh_member_19_30 hh_member_31_60 hh_member_60 hh_member_6_18 {
    replace `var' = 0 if hh_member == 0
}

encode au, gen(living_here_always) label(yes_no)
rename av living_here_years



** Preferences to move away
label define move1 1 "Move to another place" 0 "Stay here in my home" , replace
encode cu, gen(move_pref) label(move1)

* Move away
label define move_pref_strength1 5 "I do not care much whether to stay here or move away" 6 "I have a moderate wish to move away" 7 "I have a strong wish to move away" 8 "I definitely want to move away" , replace
encode cw , gen(move_pref_strength1) label(move_pref_strength1)

encode cx, gen(move_prepare) label(yes_no)

rename cz move_reason_economic
lab var move_reason_economic "I have better economic opportunities at another place"
lab val move_reason_economic yes_no

rename da move_reason_family
lab var move_reason_family "I have family/friends at another place I want to live with"
lab val move_reason_family yes_no

rename db move_reason_entitlement
lab var move_reason_entitlement "I have no entitlements to this land"
lab val move_reason_entitlement yes_no

rename dc move_reason_safety
lab var move_reason_safety "I do not feel safe at this place"
lab val move_reason_safety yes_no

rename dd move_reason_none
lab var move_reason_none "None of the above"
lab val move_reason_none  yes_no

rename de move_reason_other
lab var move_reason_other "Other reason to move"

* Stay here
rename df move_reason_open 
lab var move_reason_open "Open: Reasons for you to move?"

label define stay_pref_strength1 1 "I definitely want to stay here" 2 "I have a strong wish to stay here" 3 "I have a moderate wish to stay here" 4 "I do not care much whether to move away or stay here" , replace
encode dg , gen(stay_pref_strength1) label(stay_pref_strength1)

rename di stay_reason_invested
lab var stay_reason_invested "Already invested too much in this house and land"
lab val stay_reason_invested yes_no

rename dj stay_reason_entitlement
lab var stay_reason_entitlement "If I move away, I lose the entitlement to this land"
lab val stay_reason_entitlement yes_no

rename dk stay_reason_afraid 
lab var stay_reason_afraid "I am afraid my life situation will worsen if I move elsewhere"
lab val stay_reason_afraid yes_no

rename dl stay_reason_resources
lab var stay_reason_resources "I lack the resources to move"
lab val stay_reason_resources yes_no

rename dm stay_reason_none
lab var stay_reason_none "None of the above"
lab val move_reason_none  yes_no

rename do stay_reason_open
lab var stay_reason_open "Open: Reasons for you to stay?"


* Compensation
encode dp, gen(compensation_accept) label(yes_no)
rename dq compensation_amount
replace compensation_amount = -1 if compensation_amount == 1


* Ability
label define move_ability1 1 "Extremely difficult" 2 "Moderately difficult" 3	"Slightly difficult" 4	"Neither easy nor difficult" 5 "Slightly easy" 6 "Moderately easy" 7 "Extremely easy"
encode dr, gen(move_ability) label(move_ability1)

* Expectation
label define move_place 1 "Current community" 2	"Other rural community" 3 "Regional capital" 4 "Capital (Dhaka)" 5	"Neighboring country (India, Myanmar)" 6 "Gulf countries" 7 "Other high-income country"
encode ds , gen(move_expectation) label(move_place)


* Move away / stay strength
label define move_pref_strength2 1 "Definetely want to stay" 2 "Strong wish to stay" 3 "Moderate wish to stay" 4 "Slight preference to stay" 5 "Slight preference to move" 6 "Moderate wish to move" 7 "Strong wish to move" 8 "Definetely want to move", replace
gen move_pref_strength = .
replace move_pref_strength = stay_pref_strength1 if stay_pref_strength1 != .
replace move_pref_strength = move_pref_strength1 if move_pref_strength1 != .
label var move_pref_strength "Preference to stay (1) or move (8)"
label values move_pref_strength move_pref_strength2



** Prime Check
rename dt prime_check_sc




** Hypothetical Sunk Cost scenario
label define pref_move_hypo1 1 "Sell the house and land, and move away" 0 "Keep the house and land and stay", replace
encode dz , gen(pref_move_hypo) lab(pref_move_hypo1)
rename ec pref_move_hypo_cert
rename eb pref_stay_hypo_cert

gen pref_hypo_certain = .
replace pref_hypo_certain = pref_move_hypo_cert if pref_move_hypo_cert != .
replace pref_hypo_certain = pref_stay_hypo_cert if pref_stay_hypo_cert != .
lab var pref_hypo_certain "Certainty for preferences stated"


** Norms regadring moves
encode ee , gen (move_emp_norm) lab(move1) 
label var move_emp_norm "Empirical Norm: What do you think most people would do?"
rename ef move_norm_dis
label var move_norm_dis "Disjunctive Norm: People important approve of you moving away permanently"








*-------
* Module C: Environmental Hazards
*---------

** Information on Hazard
rename ei hazard_number

label define hazard_type1 1 "Flood" 2 "Landslide" 3 "Erosion"  4 "Storm surge" 5 "Heavy Wind (Cyclone/Typhoon)"  6 "Heat wave / Drought" 7 "Earthquake" 8 "Other"
encode el , gen(hazard_type) label(hazard_type1)
label variable hazard_type "Type of environmental hazard"

rename en hazard_name
rename eo hazard_year
encode eq , gen(hazard_place_same) label(yes_no)

gen hazard_place_division = ""
gen hazard_place_district = ""
gen hazard_place_union = ""
gen hazard_place_village = ""

replace hazard_place_division = et if et != ""
replace hazard_place_district = ew if ew != ""
replace hazard_place_union = gf if gf != ""
replace hazard_place_village = gg if gg != ""

** Injuries / Destruction by hazard
* Persons Injured
rename gi hazard_injured_self
lab var hazard_injured_self "Person got injured"
rename gj hazard_injured_other
lab var hazard_injured_other "Other household member got injured"
rename gk hazard_killed_other
lab var hazard_killed_other "Other household members got killed"

* House damaged
lab define house_damage1 0 "No, it was not damaged" 1 "Yes, partially damaged" 2 "Yes, totally damaged" 99 "N/A: I did not own a house at that timee"
encode gm, gen(hazard_house_damage) lab (house_damage1)
lab var hazard_house_damage "House damaged by hazard"

* Land lost
lab define land_lost1 0 "No, I did lose no land" 1 "Yes, I lost land" 99 "N/A: I did not own land at that time"
encode gn , gen(hazard_land_lost) lab(land_lost1)
lab var hazard_land_lost "Land lost due to hazard"

* Other buildings damaged
lab define buildings_damage1 0 "No, it was not damaged" 1 "Yes, partially damaged" 2 "Yes, totally damaged"  99 "N/A: I did not own other buildings at that time"
encode go, gen(hazard_buildings_damage) lab(buildings_damage1)
lab var hazard_buildings_damage "Other buildings damaged by hazard"

* Animals harmed / killed
lab define animals_harmed1 0 "No, none harmed" 1 "Yes, injured" 2 "Yes, killed"  99 "N/A: I did not own animals at that time"
encode gp , gen(hazard_animals_harmed) lab(animals_harmed1)
lab var hazard_animals_harmed "Animals harmed by hazard"

* Other assets destroyed
lab define assets_destroyed1 0 "no, undamaged" 1 "Yes, totally destroyed" 2 "Yes, partially damaged" 99 "N/A: did not own other assets at that time"
encode gq , gen(hazard_assets_damage) lab(assets_destroyed1)
lab var hazard_assets_damage "Other assets destroyed by hazard"

** Rebuilding Costs
* House
rename gr house_rebuild_taka
replace house_rebuild_taka = -1 if house_rebuild_taka == 1
lab var house_rebuild_taka "Rebuilding costs (-1 if don't know)"
rename gs house_rebuild_days
lab var house_rebuild_days "Rebuilding time (-1 if don't know)"
encode gt , generate(house_rebuild_cond) lab(worse_better)
label var house_rebuild_cond "Condition of house afterwards"


** Movement after Hazard
replace gu = gv if gv !=""
lab define hazard_move1 0 "Stayed" 1 "Moved away"
encode gu , gen(hazard_move) lab(hazard_mvoe1)
lab var hazard_move "Moved away permanently after hazard"

lab define hazard_stay_wanted 0	"Had no other option" 1	"Wanted to stay" 
encode gw, gen(hazard_stay_delib) lab(hazard_stay_wanted)
lab var hazard_stay_delib "Stayed after hazard because wanted to"

lab define hazard_move_where1 0 "Moved to another place" 1 "Moved to the place living at today"
encode gx , gen(hazard_move_where) lab(hazard_move_where1)
lab var hazard_move_where "Moved to the place living at today after hazard"

encode is, gen(hazard_move_network) label(worse_better)
encode it, gen(hazard_move_economic) label(worse_better)
encode iu, gen(hazard_move_natural) label(worse_better)
encode iv, gen(hazard_move_exposure) label(worse_better)
encode iw, gen(hazard_move_living) label(worse_better)

rename iz hazard_move_reception
lab var hazard_move_reception "Reception at arrival in destination (1 - very unwelcoming ; 5 very welcoming)"

rename jb rebuild_total_here
lab var rebuild_total_here "In total, how often did you rebuild your house in current place?"
rename jc rebuild_total_near 
lab var rebuild_total_near "In total, how often did you rebuild your house at a place less than 500m away than the original place after losing the land it was standing upon?"

*-------
* Module D: Climate Change Perception
*---------

** Climate Severity
label define cc_severity1 5 "Much more severe than today" 4 "Somewhat more severe than today" 3 "Same as today" 2 "Somewhat less severe than today" 1 "Much less severe than today"  99 "Don't know"
encode jd , gen (cc_severity) lab(cc_severity1)



** Adaptation
rename jg cc_adapt_house
replace cc_adapt_house = 0 if cc_adapt_house ==.
lab var cc_adapt_house "Reinforced the house"
rename jh cc_adapt_store
replace cc_adapt_store = 0 if cc_adapt_store ==.
lab var cc_adapt_store "Store belongings on elevated level"
rename ji cc_adapt_stilts
replace cc_adapt_stilts = 0 if cc_adapt_stilts ==.
lab var cc_adapt_stilts "Rebuild on stilts"
rename jj cc_adapt_fortify
replace cc_adapt_fortify = 0 if cc_adapt_fortify ==.
lab var cc_adapt_fortify "Fortified the land"
rename jk cc_adapt_other
replace cc_adapt_other = 0 if cc_adapt_other == .
lab var cc_adapt_other "Other measure taken"
rename jv cc_adapt_other_which
lab var cc_adapt_other_which "Type of other measures taken"

gen cc_adapt = .
replace cc_adapt = 0 if cc_adapt_house == 0 & cc_adapt_store == 0 & cc_adapt_stilts == 0 & cc_adapt_fortify == 0 & cc_adapt_other == 0
replace cc_adapt = 1 if cc_adapt_house == 1 | cc_adapt_store == 1 | cc_adapt_stilts == 1 | cc_adapt_fortify == 1 | cc_adapt_other == 1
lab var cc_adapt "Any adaptation measures taken"
lab val cc_adapt yes_no

rename jm cc_noadapt_fortified
lab var cc_noadapt_fortified "House/Land already well protected"
rename jn cc_noadapt_hazard
lab var cc_noadapt_hazard "Not necessary as environmental hazards won't be severe"
rename jo cc_noadapt_resources
lab var cc_noadapt_resources "No resources available"
rename jp cc_noadapt_know
lab var cc_noadapt_know  "Don't know how to protect"
rename jq cc_noadapt_move1
lab var cc_noadapt_move1 "Will move away when it gets to bad"
rename jr cc_noadapt_move2 
lab var cc_noadapt_move2 "Will move away anyways"
rename js cc_noadapt_dk
lab var cc_noadapt_dk "Never thought about it / Don't know"
rename jt cc_noadapt_unable
lab var cc_noadapt_unable "Nothing I could do to protect my house and land"


foreach var in cc_adapt_house cc_adapt_store cc_adapt_stilts cc_adapt_fortify cc_adapt_other cc_noadapt_fortified cc_noadapt_hazard cc_noadapt_resources cc_noadapt_know cc_noadapt_move1 cc_noadapt_move2 cc_noadapt_dk cc_noadapt_unable {
lab val `var' yes_no
}

rename jx cc_uncertain
rename jy cc_agency


** Problems in area
rename ka prob_food
lab var prob_food "Food insecurity or access to drinking water"
rename kb prob_sanitation
lab var prob_sanitation "Access to sanitation"
rename kc prob_disease
lab var prob_disease "Potential spread of diseases"
rename kd prob_crime
lab var prob_crime "Crime and insecurity"
rename ke prob_hazard
lab var prob_hazard "Exposure to environmental hazards (flooding, drought, storm surges)"
rename kf prob_pollution 
lab var prob_pollution "Exposure to pollution (air, noise, visual and water)"
rename kg prob_poverty
lab var prob_poverty "Poverty"
rename kh prob_population
lab var prob_population "Increasing population density"
rename ki prob_jobs 
lab var prob_jobs  "Increasing competition over jobs"
rename kj prob_social_service 
lab var prob_social_service  "Access to social service (educational institutions, health clinics etc)"
rename kk prob_credit
lab var prob_credit "Access to financial credit"
rename kl prob_transfer
lab var prob_transfer "Access to support by government welfare"
rename km prob_housing
lab var prob_housing "Housing"
rename kn prob_tranpsort
lab var prob_tranpsort "Transportation"
rename ko prob_work
lab var prob_work "Work opportunities"

foreach var in prob_food prob_sanitation prob_disease prob_crime prob_hazard prob_pollution prob_poverty prob_population prob_jobs prob_social_service prob_credit prob_transfer prob_housing prob_tranpsort prob_work {
lab val `var' yes_no
}


** Water
lab define yes_no_maybe 5 "Strongly Yes" 4 "Moderately Yes" 3 "Middle" 2 "Moderately No" 1 "Strongly No"
encode kq, gen(water_fresh) label(yes_no_maybe)
lab var water_fresh "Do you have sufficient fresh water for drinking in your area"

lab define water_quality1 1	"Fresh" 2 "Dirty" 3	"Salty" 4 "Very salty / unable to drink or use"
encode kr , gen(water_quality) lab(water_quality1)

lab define water_collect1 1	"Yes" 2 "No, we have supplied water/tap water" 3 "No, someone delivers water to our door"
encode ks , gen(water_collect) label(water_collect1)

rename ku water_ponds
lab var water_ponds "Collect water in ponds" 
rename kv water_psf
lab var water_psf "Collect water in PSF" 
rename kw water_rainwater
lab var water_rainwater "Collect rainwater" 
rename kx water_rivers
lab var water_rivers "Collect water in rivers"
rename ky water_shallow_tw
lab var water_shallow_tw "Collect water shallow tubewells"
rename kz water_deep_tw
lab var water_deep_tw "Collect water deep tubewells"
rename la water_plant
lab var water_plant "Collect water at water treatment plant"

rename lc water_time

rename le water_men
lab var water_men "Men in charge of collecting water"
rename lf water_women
lab var water_women "Women in charge of collecting water"
rename lg water_elderly
lab var water_elderly "Elderly in charge of collecting water"
rename lh water_children
lab var water_children "Children in charge of collecting water"
	
rename lj water_collect_walking
lab var water_collect_walking "Collecting water by walking"
rename lk water_collect_cycling
lab var water_collect_cycling "Collecting water by bicycle"
rename ll water_collect_rickshaw
lab var water_collect_rickshaw "Collecting water by rickshaw"
rename lm water_collect_cng
lab var water_collect_cng "Collecting water by CNG/Three wheeler"
rename ln water_collect_bike
lab var water_collect_bike "Collecting water by motorobike"
rename lq water_collect_other
lab var water_collect_other "Collecting water by other means"
	
lab define gender_both1 1 "Male" 2 "Female" 3 "Both"
encode lr , gen(water_elderly_gender) lab(gender_both)
encode ls , gen(water_child_gender) lab(gender_both)

rename lu water_collect_f_walking
lab var water_collect_f_walking "Female collecting water by walking"
rename lv water_collect_f_cycling
lab var water_collect_f_cycling "Female collecting water by bicycle"
rename lw water_collect_f_rickshaw
lab var water_collect_f_rickshaw "Female collecting water by rickshaw"
rename lx water_collect_f_cng
lab var water_collect_f_cng "Female collecting water by CNG/Three wheeler"
rename ly water_collect_f_bike
lab var water_collect_f_bike "Female collecting water by motorobike"
rename mb water_collect_f_other
lab var water_collect_f_other "Female collecting water by other means"

rename ma water_delivery

foreach var in water_ponds water_psf water_rainwater water_rivers water_shallow_tw water_deep_tw water_plant water_men water_women water_elderly water_children water_collect_walking water_collect_cycling water_collect_rickshaw water_collect_cng water_collect_bike water_collect_f_walking water_collect_f_cycling water_collect_f_rickshaw water_collect_f_cng water_collect_f_bike {
lab val `var' yes_no
}





*-------
* Module E: Moves
*---------
** Non-permanent moves
/*
mg - ms years in increasing order
*/
rename mg m_temp_10
lab var m_temp_10 "Moved temporarily in 2010"
rename mh m_temp_11
lab var m_temp_11 "Moved temporarily in 2011"
rename mi m_temp_12
lab var m_temp_12 "Moved temporarily in 2012"
rename mj m_temp_13
lab var m_temp_13 "Moved temporarily in 2013"
rename mk m_temp_14
lab var m_temp_14 "Moved temporarily in 2014"
rename ml m_temp_15
lab var m_temp_15 "Moved temporarily in 2015"
rename mm m_temp_16
lab var m_temp_16 "Moved temporarily in 2016"
rename mn m_temp_17
lab var m_temp_17 "Moved temporarily in 2017"
rename mo m_temp_18
lab var m_temp_18 "Moved temporarily in 2018"
rename mp m_temp_19
lab var m_temp_19 "Moved temporarily in 2019"
rename mq m_temp_20
lab var m_temp_20 "Moved temporarily in 2020"
rename mr m_temp_21
lab var m_temp_21 "Moved temporarily in 2021"
rename ms m_temp_none
lab var m_temp_none "Did not move temporarily between 2010 and 2021"


** Permanent moves
/*
mw - nh years in increasing order + ni => none
*/
rename mw m_perm_10
lab var m_perm_10 "Moves permanently in 2010"

rename mx m_perm_11
lab var m_perm_11 "Moves permanently in 2011"

rename my m_perm_12
lab var m_perm_12 "Moves permanently in 2012"

rename mz m_perm_13
lab var m_perm_13 "Moves permanently in 2013"

rename na m_perm_14
lab var m_perm_14 "Moves permanently in 2014"

rename nb m_perm_15
lab var m_perm_15 "Moves permanently in 2015"

rename nc m_perm_16
lab var m_perm_16 "Moves permanently in 2016"

rename nd m_perm_17
lab var m_perm_17 "Moves permanently in 2017"

rename ne m_perm_18
lab var m_perm_18 "Moves permanently in 2018"

rename nf m_perm_19
lab var m_perm_19 "Moves permanently in 2019"

rename ng m_perm_20
lab var m_perm_20 "Moves permanently in 2020"

rename nh m_perm_21
lab var m_perm_21 "Moves permanently in 2021"

rename ni m_perm_none
lab var m_perm_none "Did not move permanently between 2010 and 2021"

*** Move 3

** Origin
rename xu m_orig_division

gen m_orig_district = ""
lab var m_orig_district "In which district did you live before moving?"
foreach var in xw xx {
replace m_orig_district = `var' if `var' !=""
}

gen m_orig_union = ""
lab var m_orig_union "In which union did you live before moving?"
foreach var in yk zf za {
replace m_orig_union  = `var' if `var' != ""
}

rename zh m_orig_village


** Destination
rename zj m_dest_division

gen m_dest_district = ""
lab var m_dest_district "To which district did you move to?"
foreach var in zk zl zm {
replace m_dest_district = `var' if `var' !=""
}

gen m_dest_union = ""
lab var m_dest_union "To which union did you move to?"
foreach var in zt zz aau {
replace m_dest_union  = `var' if `var' != ""
}

rename aaw m_dest_village


** Origin Affected by natural disasters
encode aay , gen(m_orig_hazards) label(yes_no)

** Moving Reasons
rename abb m_reason_hazards
lab var m_reason_hazards "Reason: Too many hazards at old place"
rename abc m_reason_conflict
lab var m_reason_conflict "Reason: Conflict with other people at place"
rename abd m_reason_job
lab var m_reason_job "Reason: Better job opportunities in new place"

** Effect of moving
encode abh , gen(m_effect_network) label(better_worse)

encode abi , gen(m_effect_economic) label(better_worse)

encode abj , gen(m_effect_natcap) label(better_worse)

encode abk , gen(m_effect_exposure) label(better_worse)

encode abl , gen(m_effect_living) label(better_worse)

encode abm , gen(m_effect_connection) label(better_worse)

rename abn m_welcoming

** Moves in General
rename abo permanent_moves
rename abp permanent_moves_hazards



*-------
* Module F: Ability to move 
*---------
encode abq , gen(move_ability_friends) label(yes_no)
label var move_ability_friends "Do you have friends or family at safe place?"

encode abr , gen(move_ability_resources) label(yes_no)
lab var move_ability_resources "Do you have the financial resources to move permanently to a safe place"

encode abs , gen (move_ability_ob) label(yes_no)
lab var move_ability_ob "Would it be possible for you to find a job in safe place?"





*-------
* Module G: Life satisfaction
*---------

** Self
rename abx ladder_life_now
lab var ladder_life_now "Current position on life satisfaction ladder"
rename aby ladder_life_future
lab var ladder_life_now "Position on life satisfaction ladder in 5 years"
rename abz ladder_life_aspiration
lab var ladder_life_now "Highest achievable position on life satisfaction ladder"

** Migrant: UAE
rename ace ladder_life_migr_uae_now
lab var ladder_life_migr_uae_now "Migrant in UAE: Current positionon life satisfaction ladder"
rename acf ladder_life_migr_uae_future
lab var ladder_life_migr_uae_future "Migrant in UAE: Positionon life satisfaction ladder in 5 years"

** Migrant: Dhaka
rename aci ladder_life_migr_dhaka_now
lab var ladder_life_migr_dhaka_now "Migrant in Dhaka: Current positionon life satisfaction ladder"
rename acj ladder_life_migr_dhaka_future
lab var ladder_life_migr_uae_future "Migrant in Dhaka: Positionon life satisfaction ladder in 5 years"

** Migration Options
rename acm migration_option_uae 
lab var migration_option_uae "Could migrate to United Arab Emirates"
rename acn migration_option_dhaka
lab var migration_option_dhaka "Could migrate to Dhaka"
rename aco migration_option_none
lab var migration_option_none "Could not migrate to Dhaka or United Arab Emirates"

rename acq migration_option_child_uaw
lab var migration_option_child_uaw "Would own children want to have option to migrate to United Arab Emirates"
rename acr migration_option_child_dhaka
lab var migration_option_child_dhaka "Would own children want to have option to migrate to Dhaka"
rename acs migration_option_child_none
lab var migration_option_child_none "Would own children not want to have option to migrate to Dhaka or UAE"

replace migration_option_child_uaw = acu if migration_option_child_uaw == .
replace migration_option_child_dhaka = acv if migration_option_child_dhaka  ==.
replace migration_option_child_none = acw if migration_option_child_none  == .

foreach var in ladder_life_migr_uae_now ladder_life_migr_uae_future ladder_life_migr_dhaka_now ladder_life_migr_dhaka_future migration_option_uae migration_option_dhaka migration_option_none migration_option_child_uaw migration_option_child_dhaka migration_option_child_none {
lab val `var' yes_no
}

*----------
* Module H: Poverty, Aspiration, and Agency
*---------
** Economic Ladder
rename acz ladder_econ_now
lab var ladder_econ_now "Current position on economic ladder"
rename ada ladder_econ_years
lab var ladder_econ_years "Years on current step of economic ladder"
rename ade ladder_econ_before
lab var ladder_econ_before "Prior position on economic ladder"
rename adf ladder_econ_before_years
lab var ladder_econ_before_years "Year on prior step of economic ladder"
rename adi ladder_econ_max
lab var ladder_econ_max "Highest step on ladder within last 10 years"
rename adj ladder_econ_min
lab var ladder_econ_min "Lowest step on ladder within last 10 years"
rename adl ladder_econ_future
lab var ladder_econ_future "Position on economic ladder in 5 years"
rename adm  ladder_econ_aspiration
lab var ladder_econ_aspiration "Highest achievable position on economic ladder"

** Drivers
rename adp econ_driver_job
label var econ_driver_job "Find a better job"
rename adq econ_driver_work
label var econ_driver_work "Work hard and save money"
rename adr econ_driver_city
label var econ_driver_city "Move to a bigger city"
rename ads econ_driver_abroad
label var econ_driver_abroad "Move abroad"
rename adt econ_driver_network
label var econ_driver_network "Improve social networks"
rename adu econ_driver_edu
label var econ_driver_edu "Improve education"
rename adv econ_driver_skills
label var econ_driver_skills "Improve skills"
rename adw econ_driver_risks
label var econ_driver_risks "Take risks"
rename adx econ_driver_support
label var econ_driver_support "Get Support of Government & NGOs"
rename ady econ_driver_god
label var econ_driver_god "Help of God"
rename adz econ_driver_nothing
label var econ_driver_nothing "Nothing, it will come by itself"
rename aea econ_driver_born
label var econ_driver_born "Being born into a rich / influential family"
rename aeb econ_driver_fair
label var econ_driver_fair "Be fair / decent"
rename aec econ_driver_other
label var econ_driver_other "Other"
rename aed econ_driver_none
label var econ_driver_none "None of the above / Don't know"

** Barriers
rename aef econ_barrier_job
rename aeg econ_barrier_move
rename aeh econ_barrier_network
rename aei econ_barrier_support
rename aej econ_barrier_hazard
rename aek econ_barrier_health
rename ael econ_barrier_expenses
rename aem econ_barrier_abilities
rename aen econ_barrier_perseverance
rename aeo econ_barrier_luck
rename aep econ_barrier_family
rename aeq econ_barrier_fair
rename aer econ_barrier_egoistic
rename aes econ_barrier_other
rename aet econ_barrier_none
label var econ_barrier_job "Lack of opportunities (e.g. no job opportunities)"
label var econ_barrier_move "Lack of opportunities to move away"
label var econ_barrier_network "Lack of social network"
label var econ_barrier_support "Lack of support of Government & NGOs"
label var econ_barrier_hazard "Natural disasters destroying what I build up"
label var econ_barrier_health "Poor health conditions"
label var econ_barrier_expenses "Unexpected expenses"
label var econ_barrier_abilities "Lack of abilities"
label var econ_barrier_perseverance "Lack of perseverance"
label var econ_barrier_luck "Bad luck"
label var econ_barrier_family "Being born into a poor family / family without influence"
label var econ_barrier_fair "Be fair / decent"
label var econ_barrier_egoistic "Being egoistic / reckless"
label var econ_barrier_other "Other"
label var econ_barrier_none "None of the above / Don't know"

foreach var in econ_driver_job econ_driver_work econ_driver_city econ_driver_abroad econ_driver_network econ_driver_edu econ_driver_skills econ_driver_risks econ_driver_support econ_driver_god econ_driver_nothing econ_driver_born econ_driver_fair econ_driver_other econ_driver_none econ_barrier_job econ_barrier_move econ_barrier_network econ_barrier_support econ_barrier_hazard econ_barrier_health econ_barrier_expenses econ_barrier_abilities econ_barrier_perseverance econ_barrier_luck econ_barrier_family econ_barrier_fair econ_barrier_egoistic econ_barrier_other econ_barrier_none {
lab val `var' yes_no
}




** Agency
rename aev econ_aspiration
rename aew econ_knowledge
rename aex econ_agency1
rename aey econ_agency2
rename aez econ_agency3
rename afa econ_agency4
rename afb econ_agency5
rename afc econ_agency6
rename afd econ_agency7
rename afe econ_agency8

alpha econ_aspiration econ_knowledge econ_agency1 econ_agency2 econ_agency3 econ_agency4 econ_agency5 econ_agency6 econ_agency7 econ_agency8
factor econ_aspiration econ_knowledge econ_agency1 econ_agency2 econ_agency3 econ_agency4 econ_agency5 econ_agency6 econ_agency7 econ_agency8, factors(1)
predict econ_agency
label var econ_agency "Perceived sense of economic agency based on factor analysis."


** Mobility
rename aff soc_mobility1
rename afg soc_mobility2
rename afh soc_mobility3
rename afi soc_mobility4
rename afj soc_mobility5
rename afk soc_mobility6




*----------
* Module I: Preferences, Attitude, and Personality
*----------

* Preferences
rename afn recip_pos
rename afo recip_neg
rename afp trust1
rename afq time
rename afr altruism
rename afs risk

* Place Attachment
rename afy place_attach1
rename afz place_attach2
rename aga place_attach3

rename agb community_work


* Life Goals
lab define life_goals 1 "Strive economically" 2 "Strong social ties" 3 "Provide good education to my children" 4 "Live a religious life" 5 "Enjoy as many pleasant moments as possible"
encode afu, gen(life_goal1) lab(life_goals)
lab var life_goal1 "Most important life goal"
encode afv, gen(life_goal2) lab(life_goals)
lab var life_goal2 "Second most important life goal"
encode afw, gen(life_goal3) lab(life_goals)
lab var life_goal2 "Third most important life goal"

* Childrens life
encode agd, generate(children_education) label(worse_better)
encode agf, generate(children_economic) label(worse_better)
encode agg, generate(children_satisfac) label(worse_better)
encode agh, generate(children_community) label(worse_better)
encode agi, generate(children_environ) label(worse_better)






*-----------
* Module J: Socioeconomics
*----------

** Occupation & Income
rename agk occupation
rename agl income_average
lab var income_average "Income average"
rename agm income_good 
label var income_good "Income good month"
rename agn income_bad 
lab var income_bad "Income bad month"

encode agq , gen(remmitance) lab(yes_no)
rename agr remmitance_average
lab var remmitance_average "Remmitance in average month"
rename ags remmitance_good
lab var remmitance_good "Remmitance in good month"
rename agt remmitance_bad
lab var remmitance_bad "Remmitance in bad month"

** Savings / Debts
label define savings_debts 0 "0" 1 "0 - 1,500 Taka" 2 "1,500 - 7,500 Taka" 3 "> 7,500 Taka" 4 "Don't know" 5 "Prefer not to say"
encode ago , gen(savings) label(savings_debts)
encode agp , gen(debts) label(savings_debts)


** Eaten too little
lab define low_nutri1 4 "Almost every day" 3 "Almost every week" 2	"Almost every month" 1 "Some months but not every month" 0 "Never"
encode agu, gen(low_nutri) lab(low_nutri1)


** Livestock
rename agw chicken
rename agx cattle 
rename agy goats
rename agz other
encode aha, gen(fish) label(yes_no)



** Materials house is build of
rename ahc house_stone
rename ahd house_brick
rename ahe house_cement
rename ahf house_iron
rename ahg house_tin
rename ahh house_wood
rename ahi house_mud
rename ahj house_grass
rename ahk house_other
label var house_stone "Stone used to build house"
label var house_brick "Brick used to build house"
label var house_cement "Cement used to build house"
label var house_iron "Corrugated iron sheet used to build house"
label var house_tin "Tin used to build house"
label var house_wood "Wood used to build house"
label var house_mud "Mud used to build house"
label var house_grass "Grass / Straw used to build house"
label var house_other "Other used to build house"


** Investments: Land & Buildings
* Agricultural land
replace ax = ahm if t_sunkcost == 1
encode ax , gen(agri_land) label(yes_no)

rename ay agri_land_size
replace agri_land_size = ahn if t_sunkcost == 1 

rename az agri_land_value
replace agri_land_value = aho if t_sunkcost == 1 
label define title1 1 "Yes, for all the land" 2 "Yes, for most of the land" 3 "Yes, for some of the land" 4 "No, for none of the land", replace

replace ba = ahp if t_sunkcost == 1
encode  ba , gen(agri_land_title) label(title1)
rename bb agri_land_invest_taka

replace agri_land_invest_taka = ahq if t_sunkcost == 1
rename bc agri_land_invest_days

replace agri_land_invest_taka = ahr if t_sunkcost == 1

* Non-agricultural land
replace bd = ahs if t_sunkcost == 1
encode bd , gen(non_agri_land) label(yes_no)

replace be = aht if t_sunkcost == 1
rename be non_agri_land_size

replace bf = ahu if t_sunkcost == 1
rename bf non_agri_land_value

replace bg = ahv if t_sunkcost == 1
encode bg , gen(non_agri_land_title) label(title1)

replace bh = ahw if t_sunkcost == 1
rename bh non_agri_land_invest_taka

replace bi = ahx if t_sunkcost == 1
rename bi non_agri_land_invest_days

* House
replace bj = ahy if t_sunkcost == 1
encode bj, gen(house) label(yes_no)

replace bk = ahz if t_sunkcost == 1
label define rent_own 0 "Rent" 1 "Own", replace
encode bk, gen(house_own) label(rent_own)

replace bl = aia if t_sunkcost == 1
rename bl house_size

replace bm = aib if t_sunkcost == 1
rename bm house_value

replace bn = aic if t_sunkcost == 1
rename bn house_invest_taka

replace bo = aid if t_sunkcost == 1
rename bo house_invest_days

* Other Buildings
replace bp = aie if t_sunkcost == 1
encode bp , gen (buildings) label(yes_no)

replace bq = aif if t_sunkcost == 1
encode bq , gen(buildings_own) label(rent_own)

replace br = "-2" if br == "-2-2-2"
replace br = "42" if br =="24+18" // 24x18 squarefeet! to be calculated
replace br = "12" if br == "30-18" // 30x18 ft²
replace br = "42.2" if br == "42,20" 
destring br, replace
replace br = aig if t_sunkcost == 1
rename br buildings_size

replace bs = aih if t_sunkcost == 1
rename bs buildings_value

replace bt = aii if t_sunkcost == 1
rename bt buildings_invest_taka

replace bu = aij if t_sunkcost == 1
rename bu buildings_invest_days

*** -1 => don't know; -2 => prefer not to say [however, for some the minus option did not work]
foreach var in agri_land_value agri_land_invest_taka non_agri_land_value non_agri_land_invest_taka house_value house_invest_taka buildings_value buildings_invest_taka {
replace `var'=-1 if `var'==1
replace `var'=-2 if `var'==2
}

** Set to missing if don't know or prefer not to say
foreach var in agri_land_size agri_land_value agri_land_invest_taka agri_land_invest_days non_agri_land_size non_agri_land_value non_agri_land_invest_taka non_agri_land_invest_days house_size house_value house_invest_taka house_invest_days buildings_size buildings_value buildings_invest_taka buildings_invest_days {
replace `var'= . if `var'== -1 | `var'== -2 
}


egen investments_taka = rowtotal(agri_land_invest_taka non_agri_land_invest_taka house_invest_taka buildings_invest_taka)
lab var investments_taka "Money invested in land and buildings"
winsor2 investments_taka, replace cuts(0 95)
gen d_invest_taka = 0 if investments_taka < 1000
replace d_invest_taka = 1 if investments_taka >= 1000
replace investments_taka= 0 if investments_taka< 1000

egen investments_days = rowtotal(agri_land_invest_days non_agri_land_invest_days house_invest_days buildings_invest_days)
lab var investments_days "Time in land and buildings"
winsor2 investments_days, replace cuts(0 95)

gen d_invest_days = 0 if investments_days==0
replace d_invest_days = 1 if investments_days > 0

egen value_taka = rowtotal(agri_land_value non_agri_land_value house_value buildings_value)
lab var value_taka "Assets value in PPP $"
winsor2 value_taka, replace cuts(0 90)
replace value_taka= 0 if value_taka < 0

** Health
rename aik health

** Help in Emergency situation
rename aim help_relatives
rename ain help_friends
rename aio help_neighbors
rename aip help_bank
rename aiq help_insurance
rename air help_gov
rename ais help_ngo
rename ait help_religion
label var help_relatives "Help in Emergency: Relatives"
label var help_friends "Help in Emergency: Friends"
label var help_neighbors "Help in Emergency: Neighbors"
label var help_bank "Help in Emergency: My Bank"
label var help_insurance "Help in Emergency: My insurance provider"
label var help_gov "Help in Emergency: Government"
label var help_ngo "Help in Emergency: NGO"
label var help_religion "Help in Emergency: Religious group"

** Participate in Associations
encode aiu, generate(member_assosi) lab(yes_no)

rename aiw member_neighborhood
rename aix member_district
rename aiy member_migrant
rename aiz member_livelihood
rename aja member_farmer
rename ajb member_formal_political
rename ajc member_informal_political
rename ajd member_student
rename aje member_women
rename ajf member_cultural
rename ajg member_sport
label var member_neighborhood "Member in Neighbourhood association"
label var member_district "Member in Local district association"
label var member_migrant "Member in Migrant association"
label var member_livelihood "Member in Cooperative associated with your livelihood"
label var member_farmer "Member in Farmers association"
label var member_formal_political "Member in Formal political association"
label var member_informal_political "Member in Informal political association"
label var member_student "Member in Student association"
label var member_women "Member in Women's association"
label var member_cultural "Member in Cultural association"
label var member_sport "Member in Sport association"
rename aji member_other
label var member_other "Member in other"





***************************
***     Generating      ***
***************************
*Lenght of survey
split start, p("T" "." "+") gen(start_)
drop start_3 start_4
gen double clock1 = clock(start_2,"hms")
gen start_time = clock1 /1000 /60

split end, p("T" "." "+") gen(end_)
drop end_3 end_4
gen double clock2 = clock(end_2,"hms")
gen end_time = clock2 /1000 /60


drop start end clock1 clock2 start_time end_time end_1 

rename start_1 start_date
lab var start_date "Start date"
rename start_2 start_time
lab var start_time "Start time"
rename end_2 end_time
lab var end_time "End time"

gen start_time_stata = clock(start_time, "hms")
gen end_time_stata=clock(end_time, "hms")
gen time_sum= (end_time_stata-start_time_stata) / (60000) // milliseconds to minutes: /(60*1000)
label var time_sum "Lenght of survey in minutes"

** Time stamps
rename cm time_stamp1 // Before sunc cost treatment
rename cv time_stamp2 // After sunc cost treatment
rename du time_stamp3 // Before willingness to move scenario
rename ea time_stamp4 // After willingness to move scenario [Faulty!]
rename eg time_stamp5 // Before extreme event
rename ja time_stamp6 // After extreme event group 
rename abu time_stamp7 // before life satisfaction ladder 
rename aca time_stamp8 // after life satisfaction ladder 
rename ack time_stamp9 //  after life satisfaction ladder part
rename acx time_stamp10 // before explanation econ ladder 
rename adb time_stamp11 // after explanation econ ladder



generate time_12 = (time_stamp2 - time_stamp1) * 60 * 60 * 24
lab var time_12 "Time on sunk cost treatment"

generate time_23 = (time_stamp3 - time_stamp2) * 60 * 60 * 24
lab var time_23 "Time on preferences, abiltiy, and expectation to move"

generate time_34 = (time_stamp4 - time_stamp3) * 60 * 60 * 24
lab var time_34 "Faulty as time3 = time 4 (time on scenario)"

generate time_35 = (time_stamp5 - time_stamp4) * 60 * 60 * 24
lab var time_35 "Time of scenario + Norms"

generate time_56 = (time_stamp6 - time_stamp5) * 60 * 60 * 24
lab var time_56 "Faulty: Time 6 only captured for few (Time on environmental hazards)"

generate time_67 = (time_stamp7 - time_stamp6) * 60 * 60 * 24
lab var time_67 "Faulty: Time 6 only captured for few"
generate time_78 = (time_stamp8 - time_stamp7) * 60 * 60 * 24

lab var time_78 "Time on Life Satisfaction ladder"
generate time_89 = (time_stamp9 - time_stamp8) * 60 * 60 * 24

generate time_910 = (time_stamp10 - time_stamp9) * 60 * 60 * 24

generate time_1011 = (time_stamp11 - time_stamp10) * 60 * 60 * 24
lab var time_1011 "Time on econ ladder"


drop id
generate id = _n
lab var id "Participant ID"

***Save
save "$working_ANALYSIS\processed\bangladesh2021_aux2.dta" , replace




*------
* 3) Merge with translation
*-----
use  "$working_ANALYSIS\processed\bangladesh2021_aux2.dta" , clear
merge 1:1 id using "$working_ANALYSIS\processed\bangladesh2021_aux1.dta"
drop _merge

* br phone phone_transl if phone != phron_transl // check whether merging was successful: look good; all phone numbers match each other
* br hh_decision_other hh_decision_other_transl  move_reason_open  move_reason_open_transl stay_reason_open stay_reason_open_transl hazard_name hazard_name_transl cc_adapt_other_which cc_adapt_other_which_transl // looks good
drop hh_decision_other move_reason_open stay_reason_open hazard_name cc_adapt_other_which
foreach var in hh_decision_other move_reason_open stay_reason_open hazard_name cc_adapt_other_which {
	rename `var'_transl `var'
}



// Adjusted household income_average
winsor2 income_average, replace cuts(0 95)
gen adj_income = income_average / (1 + 0.3*(hh_member_6 + hh_member_6_12) + 0.5* (hh_member_13_18 + hh_member_19_30 + hh_member_31_60 + hh_member_60))



// Logarithmic income & investment measures
gen log_income = log(income_average + 1)
gen log_adj_income = log(adj_income + 1)
gen log_inv_house = log(house_invest_taka + 1)

gen log_inv_taka = log(investments_taka + 1)
gen log_inv_days = log(investments_days + 1)

// Investment categories / 10% percentiles (for descriptives)
gen inv_taka_cat = .
replace inv_taka_cat = 0 if investments_taka == 0
replace inv_taka_cat = 1 if investments_taka > 0 & investments_taka <= 20000
replace inv_taka_cat = 2 if investments_taka > 20000 & investments_taka <= 35000
replace inv_taka_cat = 3 if investments_taka > 35000 & investments_taka <= 50000
replace inv_taka_cat = 4 if investments_taka > 50000 & investments_taka <= 60000
replace inv_taka_cat = 5 if investments_taka > 60000 & investments_taka <= 80000
replace inv_taka_cat = 6 if investments_taka > 80000 & investments_taka <= 110000
replace inv_taka_cat = 7 if investments_taka > 110000 & investments_taka <= 150000
replace inv_taka_cat = 8 if investments_taka > 150000 & investments_taka <= 250000
replace inv_taka_cat = 9 if investments_taka > 250000 & investments_taka <= 400000
replace inv_taka_cat = 10 if investments_taka > 400000

lab def inv_taka_cat1 0 "0" 1 "0-20,000" 2 "20,000-35,000" 3 "35,000-50,000" 4 "50,000-60,000" 5 "60,0000-80,0000" 6 "80,000-110,000" 7 "110,000-150,000" 8 "150,000-250,000" 9 "250,000-400,000" 10 ">400,000" 
lab val inv_taka_cat inv_taka_cat1 


// Investment categories / Nothing - low - middle - high (for descriptives)
gen inv_taka_cat25 = .
replace inv_taka_cat25 = 0 if investments_taka == 0
replace inv_taka_cat25 = 1 if investments_taka > 0 & investments_taka <= 40000
replace inv_taka_cat25 = 2 if investments_taka > 40000 & investments_taka <= 80000
replace inv_taka_cat25 = 3 if investments_taka > 80000 & investments_taka <= 200000
replace inv_taka_cat25 = 4 if investments_taka > 200000

lab def inv_taka_cat2 0 "0" 1 "0-40,000" 2 "40,000-80,000" 3 "80,000-200,000" 4 ">200,000"
lab val inv_taka_cat25 inv_taka_cat2

*income adjusted for hh size
replace hh_member = hh_member+1
gen income_average_hh= income_average/hh_member
winsor2 income_average_hh, replace cuts(0 95)

*values of movable/sellable assets and savings_debts
*value of chicken cattle goats: 1 goat 80.000 Taka, 1 chicken = 210 Taka, 1 goat = 10.000
gen value_cattle = cattle*80000
gen value_chicken = chicken*210
gen value_goat = goat*10000
egen value_livestock = rowtotal(value_cattle value_chicken value_goat)
gen value_livestock_hh = value_livestock/hh_member
winsor2 value_livestock_hh, replace cuts(0 95)


*savings adjusted for hh size
gen savings_hh = 0 if savings==0
replace savings_hh = 750 if savings==1
replace savings_hh = 3000 if savings==2
replace savings_hh = 10000 if savings==3
replace savings_hh = 0 if savings>3
replace savings_hh = savings_hh / hh_member

* PPP adjust: 2021 conversion factor: 32.09938209
foreach x of varlist income_average income_average_hh value_livestock_hh savings_hh investments_taka value_taka {
    replace `x' = `x'/32.09938209
}

* total movable/sellable assets adjusted for hh size
egen financial_ability = rowtotal(savings_hh value_livestock_hh)

// costs to move to dhaka (from 2018 data collection) including expenses for staying there the first month (accomodation and food): 326 PPP --> adjust for inflation 2021 conversion factor: 32,09938209; 2018 conversion factor: 30,73048114 --> .04454538 percent increase
di 326*1.04454538
* about 341 PPP needed
gen move_financial = 0 if financial_ability < 341
replace move_financial = 1 if financial_ability >= 341
replace move_financial = 1 if income_average_hh >= 341
lab def mig_lab 0 "No financial ability to move" 1 "Financial ability to move", replace
lab val move_financial mig_lab
tab move_financial move_pref



// Married binary
gen married = .
replace married = 1 if marital == 2
replace married = 0 if marital != 2
lab var married "Married"

// Household-decision binary
gen hh_decision_d = .
replace hh_decision_d = 1 if hh_decision == 1 | hh_decision == 3
replace hh_decision_d = 0 if hh_decision == 2 | hh_decision == 4
lab var hh_decision_d "Involved in household-decision"

// Place attachment index
alpha place_attach1 place_attach2 place_attach3 // rather higher; fine to build simple, unweighted index
gen place_attach = (place_attach1 + place_attach2 + place_attach3) / 3
lab var place_attach "Place attachmend index"
egen z_place = std(place_attach)
// Expectation to move
gen expect_move = .
replace expect_move = 0 if move_expectation == 1
replace expect_move = 1 if move_expectation != 1
lab var expect_move "Expect to move in the next 5 yrs"


*gen immobility variable
bysort move_pref: tab move_pref_strength
gen mobility_pref = 1 if move_pref_strength < 3
replace mobility_pref = 2 if move_pref_strength >= 3 & move_pref_strength <5
replace mobility_pref = 3 if move_pref_strength >= 5 & move_pref_strength <7
replace mobility_pref = 4 if move_pref_strength >= 7
lab def mobile_lab 1 "Strongly stay" 2 "Weakly stay" 3 "Weakly move" 4 "Strongly move", replace
lab val mobility_pref mobile_lab
tab mobility_pref

*perceived ability to migrate internally or even abroad
gen migration_ability = 0 if migration_option_none==1 
replace migration_ability = 1 if migration_option_none==0
lab def mig_lab 0 "No ability" 1 "Able to move", replace
lab val migration_ability mig_lab
tab migration_ability

*gen mobility categories based on aspiration/capability
gen mobility_cat = 1 if move_pref==0 & migration_ability==1
replace mobility_cat = 2 if move_pref==0 & migration_ability==0
replace mobility_cat = 3 if move_pref==1 & migration_ability==0
replace mobility_cat = 4 if move_pref==1 & migration_ability==1

lab def trapper 1 "Voluntary immobile (=1)" 2 "Acquiescent immobile (=1)" 3 "Involuntary immobile (=1)" 4 "Potentially mobile (=1)", replace
lab val mobility_cat trapper

tab mobility_cat

*binary sunkcost (real investments)
gen d_sunkcost = 0
replace d_sunkcost = 1 if d_invest_taka==1 | d_invest_days==1


*time on sunk-cost treatment
gen time_treatment = time_12
replace time_treatment = 0 if t_sunkcost==1 // set to 0 for control group
replace time_treatment = 0 if time_12 < 0 // set to 0 if negative value
sum time_treatment if t_sunkcost>1, detail

*land lost dummy
gen land_lost = 1 if  hazard_land_lost==1
replace land_lost = 0 if hazard_land_lost==0 | hazard_land_lost==99

*self-efficacy index and standardization of other main variables
alpha cc_uncertain cc_agency, gen(self_efficacy) reverse(cc_uncertain cc_agency)
rename time impatience, replace
rename prime_check_sc sunkcost, replace
gen risk_aversion = 10-risk
foreach x of varlist impatience risk_aversion self_efficacy sunkcost {
	egen z_`x' = std(`x')
}
lab var z_sunkcost "Perceived sunk costs (std.)"
lab var z_self_efficacy "Adaptation self-efficacy (std.)"
lab var age "Age"
lab var female "Female (=1)"
lab var edu_yr "Education (years)"
lab var income_average_hh "Monthly income in PPP $ (adjusted for HH size)"
lab var hazard_number "Environmental hazards (last 5 years)"
lab var land_lost "Lost land to erosion (=1)"
lab var cc_adapt_stilts "Rebuild house on stilts (=1)"
global control age female edu_yr income_average_hh value_taka investments_days investments_taka
global exposure hazard_number land_lost cc_adapt_stilts

*---------
* Order
*---------
order ///
/*setup*/ id date interviewer interview_place interview_village village notes t_sunkcost t_scenario t_open_question participate start_date start_time end_time time_sum ///
/*socioeconomics I*/ name phone female marital age birth_yr religion edu_yr hh_decision hh_decision_other children hh_member hh_member_6 hh_member_6_12 hh_member_13_18 hh_member_19_30 hh_member_31_60 hh_member_60 hh_member_6_18 edu_primary_6_18 edu_primary_19_30 edu_higher_19_30 living_here_always living_here_years ///
/*Moving Preferences*/ move_pref move_pref_strength move_prepare move_reason_economic move_reason_family move_reason_entitlement move_reason_safety move_reason_none move_reason_open stay_reason_invested stay_reason_entitlement stay_reason_afraid stay_reason_resources stay_reason_none stay_reason_open compensation_accept compensation_amount move_ability move_expectation ///
/*Prime Check*/ sunkcost ///
/* Moving Pref Hypothetical*/ pref_move_hypo pref_hypo_certain ///
/* Norms*/ move_emp_norm move_norm_dis ///
/*Hazards*/ hazard_number hazard_type hazard_name hazard_year hazard_place_same hazard_place_division hazard_place_district hazard_place_union hazard_place_village hazard_injured_self hazard_injured_other hazard_killed_other hazard_killed_other hazard_house_damage hazard_land_lost hazard_buildings_damage hazard_animals_harmed hazard_assets_damage  house_rebuild_taka house_rebuild_days house_rebuild_cond hazard_move hazard_stay_delib hazard_move_where hazard_move_network hazard_move_economic hazard_move_natural hazard_move_exposure hazard_move_living hazard_move_reception rebuild_total_here rebuild_total_near ///
/*Hazard Perception*/ cc_severity cc_adapt_house cc_adapt_store cc_adapt_stilts cc_adapt_fortify cc_adapt_other cc_adapt_other_which cc_noadapt_fortified cc_noadapt_hazard cc_noadapt_resources cc_noadapt_know cc_noadapt_move1 cc_noadapt_move2 cc_noadapt_dk cc_noadapt_unable cc_uncertain cc_agency ///
/*Problem location*/ prob_food prob_sanitation prob_disease prob_crime prob_hazard prob_pollution prob_poverty prob_population prob_jobs prob_social_service prob_credit prob_transfer prob_housing prob_tranpsort prob_work ///
/*Water*/ water_fresh water_quality water_collect water_elderly_gender water_child_gender water_ponds water_psf water_rainwater water_rivers water_shallow_tw water_deep_tw water_plant water_time water_men water_women water_elderly water_children water_collect_walking water_collect_cycling water_collect_rickshaw water_collect_cng water_collect_bike water_collect_other water_collect_f_walking water_collect_f_cycling water_collect_f_rickshaw water_collect_f_cng water_collect_f_bike water_delivery water_collect_f_other ///
/*Moves*/ m_temp_10 m_temp_11 m_temp_12 m_temp_13 m_temp_14 m_temp_15 m_temp_16 m_temp_17 m_temp_18 m_temp_19 m_temp_20 m_temp_21 m_temp_none m_perm_10 m_perm_11 m_perm_12 m_perm_13 m_perm_14 m_perm_15 m_perm_16 m_perm_17 m_perm_18 m_perm_19 m_perm_20 m_perm_21 m_perm_none m_orig_division m_orig_district m_orig_union m_orig_village m_dest_division m_dest_district m_dest_union m_dest_village m_orig_hazards m_reason_hazards m_reason_conflict m_reason_job  m_effect_network m_effect_economic m_effect_natcap m_effect_exposure m_effect_living m_effect_connection m_welcoming permanent_moves permanent_moves_hazards ///
/*Move Ability*/ move_ability_friends move_ability_resources move_ability_ob ///
/*Life satisfaction ladder*/ ladder_life_now ladder_life_future ladder_life_aspiration ladder_life_migr_uae_now ladder_life_migr_uae_future ladder_life_migr_dhaka_now ladder_life_migr_dhaka_future migration_option_uae migration_option_dhaka migration_option_none migration_option_child_uaw migration_option_child_dhaka migration_option_child_none ///
/*Economic ladder*/ ladder_econ_now ladder_econ_years ladder_econ_before ladder_econ_before_years ladder_econ_max ladder_econ_min ladder_econ_future ladder_econ_aspiration econ_driver_job econ_driver_work econ_driver_city econ_driver_abroad econ_driver_network econ_driver_edu econ_driver_skills econ_driver_risks econ_driver_support econ_driver_god econ_driver_nothing econ_driver_born econ_driver_fair econ_driver_other econ_driver_none econ_barrier_job econ_barrier_move econ_barrier_network econ_barrier_support econ_barrier_hazard econ_barrier_health econ_barrier_expenses econ_barrier_abilities econ_barrier_perseverance econ_barrier_luck econ_barrier_family econ_barrier_fair econ_barrier_egoistic econ_barrier_other econ_barrier_none ///
/*Econ Agency*/ econ_agency econ_aspiration econ_knowledge econ_agency1 econ_agency2 econ_agency3 econ_agency4 econ_agency5 econ_agency6 econ_agency7 econ_agency8 soc_mobility1 soc_mobility2 soc_mobility3 soc_mobility4 soc_mobility5 soc_mobility6 ///
/*Preferences, attitudes, personality*/ recip_pos recip_neg trust1 impatience altruism risk life_goal1 life_goal2 life_goal3 place_attach1 place_attach2 place_attach3 community_work children_health children_education children_economic children_satisfac children_community children_environ ///
/*Socio-econ*/ occupation income_average income_good income_bad remmitance remmitance_average remmitance_good remmitance_bad savings debts low_nutri investments_taka investments_days value_taka agri_land agri_land_size agri_land_value agri_land_title  agri_land_invest_taka agri_land_invest_days non_agri_land_title non_agri_land non_agri_land_size non_agri_land_value non_agri_land_invest_taka non_agri_land_invest_days house house_own house_size house_value house_invest_taka house_invest_days buildings buildings_own buildings_size buildings_value buildings_invest_taka buildings_invest_days chicken cattle goats other fish house_stone house_brick house_cement house_iron house_tin house_wood house_mud house_grass house_other health help_relatives help_friends help_neighbors help_bank help_insurance help_gov help_ngo help_religion member_assosi member_neighborhood member_district member_migrant member_livelihood member_farmer member_formal_political member_informal_political member_student member_women member_cultural member_sport member_other 

*** Save 2021 datasett
save "$working_ANALYSIS\processed\bangladesh2021.dta" , replace



 
** EOF