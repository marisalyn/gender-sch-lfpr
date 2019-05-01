/* Data cleaning educational attainment and labor force participation */
/* Author: Marisa Henry */
/* Date created: 25 March 2019 */ 

/* TASK: clean and merge data from Barro-Lee and World Bank WDI datasets (described more below). 
   The cleaned data is used in 02_analysis to explore some basic visualizations 
   and regressions of the relationships between LFPR and education */

/* Note that two countries in the Barro-Lee dataset are not in the WDI data: 
   Taiwan and Reunion. These countries are removed from the cleaned dataset. */
	 
/* All data downloaded on 3/25/2019. */ 

/* Educational data comes from the Barro-Lee educational attainment dataset 
   v.2.2 available from http://www.barrolee.com/  
   
   The Barro-Lee datasets are for population aged 15 and over, by sex and overall. */ 

/* Inidicators on GDP per capita and labor force participation come from
   the World Bank WDI data available from 
   https://databank.worldbank.org/data/source/world-development-indicators
   
   The WDI data is for four indicators: 
   - GDP per capita, PPP (constant 2011 international $) 
   - 3 LFPR indicators - the female, male and total LFPR as percentages of the 
     population age 15+, all based on the modeled ILO estimate. 
	 Time series: every 5 years from 1960-2010. 
	 Countries: all countries available plus world. */
   
/* Finally, countries by World Bank region are downloaded from 
   https://datahelpdesk.worldbank.org/knowledgebase/articles/906519-world-bank-country-and-lending-groups   */

clear
set more off  

cd "/Users/marisahenry/Dropbox/cgd_project"

capture log close
log using "./code/logs/dataCleaning.log", replace

////////////////////
/* BARRO-LEE DATA */ 
////////////////////

/* append datasets for males, females, and the total. */ 
use "rawData/BL2013_MF1599_v2.2.dta", clear
append using "rawData/BL2013_M1599_v2.2.dta"
append using "rawData/BL2013_F1599_v2.2.dta"
tabulate sex // make sure that appending worked

/* keep variables I want for analysis */
keep country year sex yr_sch yr_sch_pri yr_sch_sec yr_sch_ter WBcode pop

/* the WDI GDP per capita, PPP data begins in 1990, so analysis will be 
   restricted to 1990-2010 */
drop if (year < 1990) 

/* reshape the data for one observation for each country/year pair */ 
reshape wide yr_sch yr_sch_pri yr_sch_sec yr_sch_ter pop, i(WBcode year) j(sex) string

/* clean up labels */
label variable yr_schF "Years of Schooling, Female"
label variable yr_schM "Years of Schooling, Male"
label variable yr_schMF "Years of Schooling, Total"
label variable yr_sch_priF "Years of Primary Schooling, Female"
label variable yr_sch_priM "Years of Primary Schooling, Male"
label variable yr_sch_priMF "Years of Primary Schooling, Total"
label variable yr_sch_secF "Years of Secondary Schooling, Female"
label variable yr_sch_secM "Years of Secondary Schooling, Male"
label variable yr_sch_secMF "Years of Secondary Schooling, Total"
label variable yr_sch_terF "Years of Teritiary Schooling, Female"
label variable yr_sch_terM "Years of Teritiary Schooling, Male"
label variable yr_sch_terMF "Years of Teritiary Schooling, Total"
label variable popF "Population, Female"
label variable popM "Population, Male"
label variable popMF "Population, Total"

/* calculate ratios of female to male educational attainment */
gen yr_sch_ratio = yr_schF/yr_schM
gen yr_sch_pri_ratio = yr_sch_priF/yr_sch_priM
gen yr_sch_sec_ratio = yr_sch_secF/yr_sch_secM
gen yr_sch_ter_ratio = yr_sch_terF/yr_sch_terM

label variable yr_sch_ratio "Ratio of female to male years of schooling"
label variable yr_sch_pri_ratio "Ratio of female to male years of primary schooling,"
label variable yr_sch_sec_ratio "Ratio of female to male years of secondary schooling"
label variable yr_sch_ter_ratio "Ratio of female to male years of tertiary schooling"

/* sort and save to .dta */ 
sort WBcode year
save "producedData/BL2013_all1599_v2.2.dta", replace

////////////////////
/*    WDI DATA    */ 
////////////////////

clear
import delimited "rawData/WDI_data.csv", varnames(1)

/* rename and recast the data to correct type */
rename ïcountryname  country
rename countrycode WBcode

drop yr1960 yr1965 yr1970 yr1975 yr1980 yr1985 // no GDP per capita, PPP data <1990

replace yr1990 = "" if yr1990 == ".."
replace yr1995 = "" if yr1995 == ".."
replace yr2000 = "" if yr2000 == ".."
replace yr2005 = "" if yr2005 == ".."
replace yr2010 = "" if yr2010 == ".."

destring, replace

/* reshape data to be in country/year pairs and clean some values and labels */
reshape long yr, i(country seriescode) j(year)

rename seriesname indicator 
rename yr value
drop seriescode 
replace indicator = "GDP_perCap" if indicator == "GDP per capita, PPP (constant 2011 international $)"
replace indicator = "LFPR_F" if indicator == "Labor force participation rate, female (% of female population ages 15+) (modeled ILO estimate)"
replace indicator = "LFPR_M" if indicator == "Labor force participation rate, male (% of male population ages 15+) (modeled ILO estimate)"
replace indicator = "LFPR_MF" if indicator == "Labor force participation rate, total (% of total population ages 15+) (modeled ILO estimate)"

reshape wide value, i(country year) j(indicator) string
rename value* *

label variable GDP_perCap "GDP per Capita, PPP" 
label variable LFPR_F "Labor force participation rate, female (% of female population ages 15+) (ILO)" 
label variable LFPR_M "Labor force participation rate, male (% of male population ages 15+) (ILO)" 
label variable LFPR_MF "Labor force participation rate, total (% of total population ages 15+) (ILO)" 

/* calculate ratios of female to male LFPR  */
gen LFPR_ratio = LFPR_F/LFPR_M
label variable LFPR_ratio "Ratio of female to male labor force participation rate"

/* sort and save to .dta */ 
sort WBcode year
save "producedData/WDI_tidy.dta", replace

/* add regions (note this information isn't in the WDI dataset, but available here
   https://datahelpdesk.worldbank.org/knowledgebase/articles/906519-world-bank-country-and-lending-groups )  */
import delimited  "rawData/regions.csv", clear varnames(1)
rename ïregioncode regioncode
rename countrycode WBcode
save "producedData/regions_tidy.dta", replace

/* merge the regions into the WDI dataset */
use "producedData/WDI_tidy.dta", clear
merge m:1 WBcode using "producedData/regions_tidy.dta"
list if _merge == 2 

/* Taiwain not in WDI data -- remove from regions then merge again */
use "producedData/regions_tidy.dta", clear
drop if WBcode == "TWN" 

/* merge the regions into the WDI dataset */
use "producedData/WDI_tidy.dta", clear
merge m:1 WBcode using "producedData/regions_tidy.dta"
drop _merge

/* replace & with "and" */
replace region = subinstr(region, "&", "and", . )
 
/* encode region as categorical var */
encode region, gen(region_cat)
drop region
rename region_cat region

/* fix labels */
label variable regioncode "World Bank Region Code"
label variable region "World Bank Region"

/* sort and save data */
sort WBcode year
save "producedData/WDI_tidy_regions.dta", replace

//////////////////////////////////////
/*   MERGE BARRO-LEE AND WDI DATA   */ 
//////////////////////////////////////

/* merge datasets by 1:1 merge on WBcode year key values */
use "producedData/BL2013_all1599_v2.2.dta", clear
merge 1:1 WBcode year using "producedData/WDI_tidy_regions.dta"

/* look at countries that didn't match */
bysort country _merge : gen country_tag = _n == 1 
list country if country_tag & _merge == 1
list country if country_tag & _merge == 2

/* Fix merges by inspection. There are a two countries which have different WBcodes
   listed, but which I assume are the same counties. Specifically:
   The Republic of Moldova (ROM) in the BL dataset is Moldova (MDA) in WDI dataset. 
   Serbia (SER) in the BL dataset is Serbia (SRB) in the WDI data. */

   /* Taiwan and Reunion do not appear to be in the WDI data, so they 
   will be dropped along with all the countries in the WDI data that do not
   have data in the BL dataset. */ 
   
use "producedData/WDI_tidy_regions.dta", clear
replace WBcode = "ROM" if WBcode == "MDA" 
replace WBcode = "SER" if WBcode == "SRB" 
save "producedData/WDI_tidy_regions.dta", replace

/* merge again! */
use "producedData/BL2013_all1599_v2.2.dta", clear
merge 1:1 WBcode year using "producedData/WDI_tidy_regions.dta"

/* Drop countries that didn't merge */
drop if _merge == 1 | _merge == 2 
drop _merge 

/* sort and save merged data */ 
sort country year
save "producedData/mergedData.dta", replace

////////////////////////////////////////////
/*   CREATE VARIABLE TRANSFORMATIONS      */ 
////////////////////////////////////////////

/* I want to use the differences in variables from 1990 to 2010 as my 
   outcome variable in analysis. I create */ 

use "producedData/mergedData.dta", clear

/* set as panel data */ 
encode country, gen(country_cat)
drop country
rename country_cat country
tsset country year, delta(5)

/* create variables for changes from 1990 to 2010 */ 
foreach var of varlist yr_sch* LFPR* GDP*{
gen `var'_9010 = `var'-l4.`var'
gen `var'_9010_pc = (`var' -l4.`var')/l4.`var'
label variable `var'_9010 "Change in of `var', 1990-2010"
label variable `var'_9010_pc "Percent Change in `var', 1990-2010 "
} 

/* create logs of GDP */
gen GDP_perCap_log = ln(GDP_perCap)
label variable GDP_perCap_log "Log GDP per Capita, PPP"
gen GDP_perCap_9010_log = ln(GDP_perCap_9010)
label variable GDP_perCap_log "Log Diff in GDP per Capita, PPP 1990-2010"

/* save final dataset for analysis */ 

save "producedData/finalData.dta", replace

log close
