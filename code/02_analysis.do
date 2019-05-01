/* Data analysis educational attainment and labor force participation */
/* Author: Marisa Henry */
/* Date created: 25 March 2019 */ 

/* Data used is created from the file dataCleaning.do. Data sources are the
   Barro-Lee educational attainment dataset and the World Bank WDI */

/* TASKS: Create attractive scatter plots of labor force participation vs education 
   and explore relationships by region. Run regressions of female labor force
   participation on female years of schooling, with and without World Bank
   region fixed effects, and export coefficients to LaTeX. 
   
   Analyses and plots are used in a blog post "op-ed" style write-up titled: 
   "A Call for More Holistic Interventions and Long-Term Evaluations
   in Gender & Development" */  
   
/* Note that there are many more plots below than included in the final write up. */
   
clear
set more off 

/* install packages as needed */
// ssc install labutil
// ssc install estout
// ssc install grstyle
// ssc install palettes
// ssc inst _gwtmean
// net from http://www.stata.com
// net cd users
// net cd vwiggins
// net install grc1leg

cd "/Users/marisahenry/Dropbox/cgd_project"
capture log close
log using "./code/logs/analysis.log", replace

/* some programs for specifying custom plots */ 
program drop colorpalette_538mod
program colorpalette_538mod
	c_local P #3C8FD1, #EA462A, #83A952, #EFBD42, #D98FE4, #F28A32, ///
	   #8B008B, #AACCF2, #F2F2F2, #CDCDCF, #F5B7AA, #FDF3F2
	c_local I blue, red, green, yellow, pink, orange, purple, ///
	   lightBlue, lightGrey, grey, lightRed, lightLightRed
end
		
program drop graphsetup
program graphsetup
	args x y
	local xsize = `x' / 2.54
	local ysize = `y' / 2.54
	local rsize = min(`xsize', `ysize')
	foreach pt in .5 3 6 8 10 {
		local nm: subinstr local pt "." "_"
		local `nm'pt = `pt' /(`rsize'*72)*100
	}
	grstyle init
	grstyle set plain, horizontal grid
    grstyle set color 538mod
	grstyle graphsize x `xsize'
	grstyle graphsize y `ysize'
	grstyle gsize heading `10pt'
	grstyle gsize subheading `8pt'
	grstyle gsize axis_title `6pt'
	grstyle gsize tick_label `6pt'
	grstyle gsize key_label `4pt'
	grstyle gsize plabel `6pt'
	grstyle gsize text_option `6pt'
	grstyle symbolsize p `5pt'
	grstyle linewidth axisline `_5pt'
	grstyle linewidth tick `_5pt'
	grstyle linewidth major_grid `_5pt'
	grstyle linewidth legend `_1pt'
	grstyle linewidth xyline `_5pt'
end

///////////////////////////////
/*     SUMMARY STATS         */ 
///////////////////////////////

use "producedData/finalData.dta", clear

/* look at REGIONAL average schooling by year, and sex */
bysort region year: egen yr_schMF_mean = wtmean(yr_schMF), weight(popMF)
bysort region year: egen yr_schF_mean = wtmean(yr_schF), weight(popF)
bysort region year: egen yr_schM_mean = wtmean(yr_schM), weight(popM)
bysort region: summarize yr_schF_mean yr_schM_mean if year == 2010

/* look at GLOBAL average schooling year, and sex */
bysort year: egen LFPR_MF_mean = wtmean(LFPR_MF), weight(popMF)
bysort year: egen LFPR_F_mean = wtmean(LFPR_F), weight(popF)
bysort year: egen LFPR_M_mean = wtmean(LFPR_M), weight(popM)
bysort year: summarize LFPR_F_mean LFPR_M_mean 

/* look at trends in yeas of schooling for certain regions */
mean(yr_schMF_mean) if year == 1990 & region == 5 // 12.01372 // North America 
mean(yr_schMF_mean) if year == 1990 & (region == 6) // 3.4253 // South Asia
mean(yr_schMF_mean) if year == 1990 & (region == 7) // 3.807388 // SSA 

mean(yr_schMF_mean) if year == 2010 & region == 5 // 13.09504
mean(yr_schMF_mean) if year == 2010 & (region == 6) // 6.066738
mean(yr_schMF_mean) if year == 2010 & (region == 7) // 5.279197

// difference between SSA and NA in 1990 = 12.01372 - 3.807388 = 8.206
// difference between SSA and NA in 2010 = 13.09504 - 5.279197 = 7.815

/* look at GLOBAL LFPR for females in 2010 */
use "producedData/WDI_tidy.dta", clear
summarize LFPR_F if year == 2010 & country == "World"

/////////////////////////////////////////////////////////////////
/*      PLOT GDP PER CAPITA VS CHANGE IN YRS SCHOOLING         */ 
/////////////////////////////////////////////////////////////////

use "producedData/finalData.dta", clear

scatter GDP_perCap_9010 yr_schMF_9010 [w=popMF], msymbol(circle_hollow) mcolor(navy) ///
  || lfit GDP_perCap_9010 yr_schMF_9010, lcolor(dkorange)
  
/* Get rid of outliers */ 
list if GDP_perCap_9010 < -10000
list if GDP_perCap_9010 > 50000 & !missing(GDP_perCap_9010)

/* UAE is an outlier with really low change in GDP per capita - this makes sense 
   because of the oil crash in 2009.  Macao is an outlier with a huge increase in
   GDP per capita - this also makes sense because it was returned to China in 
   1999. Both UAE and Macao are removed from plots and analysis. */ 

drop if WBcode == "ARE" 
drop if WBcode == "MAC" 

/* Label a few points */
gen label1 = "Singapore" if WBcode == "SGP" & !missing(GDP_perCap_9010)
replace label1 = "Luxembourg" if WBcode == "LUX" & !missing(GDP_perCap_9010)
replace label1 = "USA" if WBcode == "USA" & !missing(GDP_perCap_9010)
replace label1 = "USA" if WBcode == "USA" & !missing(GDP_perCap_9010)
replace label1 = "UK" if WBcode == "GBR" & !missing(GDP_perCap_9010)
replace label1 = "USA" if WBcode == "USA" & !missing(GDP_perCap_9010)
replace label1 = "Ukraine" if WBcode == "UKR" & !missing(GDP_perCap_9010)

gen label1_pos = 7 if label1 == "Singapore" | label1 ==  "Luxembourg"  | label1 ==  "USA"  
replace label1_pos = 11 if label1 ==  "USA" | label1 ==  "UK" | label1 == "Zimbabwe" | label1 == "Haiti"
replace label1_pos = 4 if label1 == "Ukraine"

/* final plot of GDP per capita vs change in years of schooling  */ 
graphsetup 11 7
twoway(scatter GDP_perCap_9010 yr_schMF_9010 [w=popMF], ///
  msymbol(circle_hollow) mcolor(navy)) ///
  (scatter GDP_perCap_9010 yr_schMF_9010, mlabel(label1) ms(i) ///
  mlabcolor(black) mlabvposition(label1_pos) mlabgap(3)), legend(off), ///
  (lfit GDP_perCap_9010 yr_schMF_9010, lcolor(dkorange)), ///
  xtitle("Change in Years of Schooling, 1990 to 2010")  ///
  ytitle("Change in GDP per Capita, PPP, 1990 to 2010") // (constant 2011 international $)

//////////////////////////////////////////////////////////
/*      PLOT LFPR VS CAHNGE IN YRS SCHOOLING            */ 
//////////////////////////////////////////////////////////

use "producedData/finalData.dta", clear

graphsetup 11 7
separate LFPR_MF_9010, by(region) gen(temp)
labvarch temp*, after(==) 
twoway(scatter temp* yr_schMF_9010, ///
  msymbol(circle_hollow circle_hollow circle_hollow circle_hollow circle_hollow circle_hollow circle_hollow )) ///
  (lfit LFPR_MF_9010 yr_schMF_9010, lcolor(cranberry)), ///
  xtitle("Change in Years of Schooling, 1990 to 2010")  ///
  ytitle("Change in Labor Force Participation Rate, 1990 to 2010") 
drop temp*

separate LFPR_F_9010, by(region) gen(temp)
labvarch temp*, after(==) 
graphsetup 11 7
twoway(scatter temp* yr_schF_9010, ///
  msymbol(circle circle circle circle circle circle circle ) ///
  mlwidth(none none none none none none none) ///
  mcolor(%50 %50 %50 %50 %50 %50 %50) ///
  msize(large large large large large large large)) ///
  (lfit LFPR_F_9010 yr_schMF_9010, lcolor(cranberry) lwidth(0.5)), ///
  xtitle("Change in Female Years of Schooling, 1990 to 2010")  ///
  ytitle("Change in Female LFPR, 1990 to 2010") 
drop temp* 

graph export "TeX/LFPRF_yrsch.png", replace

////////////////////////////////////////////////////
/*      PLOT LFPR  VS   YRS SCH RATIO           */ 
///////////////////////////////////////////////////

use "producedData/finalData.dta", clear

keep if year == 2010
twoway(scatter LFPR_MF yr_sch_ratio [w=popMF], ///
  msymbol(circle_hollow) mcolor(navy)), legend(off), ///
  (lfit LFPR_MF yr_sch_ratio, lcolor(dkorange)), ///
  xtitle("Ratio of Female to Male Years of Schooling (2010)")  ///
  ytitle("LFPR (2010)") 
 
////////////////////////////////////////////////////
/*      PLOT YRS SCH OVER TIME         */ 
///////////////////////////////////////////////////

/* regional average years of schooling, 
   countries weighted by population */ 
   
use "producedData/finalData.dta", clear
graphsetup 11 7
bysort region year: egen yr_schMF_mean = wtmean(yr_schMF), weight(popMF)
separate yr_schMF_mean, by(region) gen(temp)
labvarch temp*, after(==) 
twoway(connected temp* year), ///
  ytitle("Average Years of Schooling")
    
////////////////////////////////////////////////////
/*      PLOT YRS SCH RATIO BY REGION OVER TIME         */ 
///////////////////////////////////////////////////

use "producedData/finalData.dta", clear
graphsetup 11 7
bysort region year: egen yr_sch_ratio_mean = wtmean(yr_sch_ratio), weight(popMF)
separate yr_sch_ratio_mean, by(region) gen(temp)
labvarch temp*, after(==) 
twoway(connected temp* year, lwidth(0.5 0.5 0.5 0.5 0.5 0.5 0.5)) , ///
  yline(1, lwidth(0.5) lpattern(dash) lcolor(cranberry)) ///
  ytitle("Ratio of Female to Male Years of Schooling") ///
  ysc(r(0.4 1.1)) ///
  ytick(#10) ylabel(#10) 
  
graph export "TeX/yrsch_ratio.png", replace

////////////////////////////////////////////////////////////////////
/*      PLOT YRS SCH BY GENDER OVER TIME           */ 
///////////////////////////////////////////////////////////////////

use "producedData/finalData.dta", clear

bysort year: egen yr_schF_mean = wtmean(yr_schF), weight(popF)
bysort year: egen yr_schM_mean = wtmean(yr_schM), weight(popM)

graphsetup 9 7
label variable yr_schF_mean "Female"
label variable yr_schM_mean "Male"
gen year_offset1 = year - 1
gen year_offset2 = year + 1
twoway (connected yr_schF_mean year) ///
   (connected yr_schM_mean year), ///
   ysc(r(0 9)) ///
   ytick(#10) ylabel(#10) ///
   ytitle("Average Years of Schooling")
   
////////////////////////////////////////////////////
/*      PLOT YRS PRI, SEC, TER SCH OVER TIME         */ 
///////////////////////////////////////////////////

use "producedData/finalData.dta", clear

bysort region year: egen yr_sch_pri_ratio_mean = wtmean(yr_sch_pri_ratio), weight(popMF)
separate yr_sch_pri_ratio_mean, by(region) gen(temp)
labvarch temp*, after(==) 
twoway(connected temp* year), ///
  yline(1, lwidth(0.3) lstyle(dot) lcolor(black)) ///
  title("Years of Primary School") ///
  ytitle("Ratio of Females To Males") ///
  xtitle("") ///
  name(g1, replace)
drop temp* 

bysort region year: egen yr_sch_sec_ratio_mean = wtmean(yr_sch_sec_ratio), weight(popMF)
separate yr_sch_sec_ratio_mean, by(region) gen(temp)
labvarch temp*, after(==) 
twoway(connected temp* year), ///
  yline(1, lwidth(0.3) lstyle(dot) lcolor(black)) ///
  title("Years of Secondary School") ///
  ytitle("Y") ///
  name(g2, replace)
drop temp* 
  
bysort region year: egen yr_sch_ter_ratio_mean = wtmean(yr_sch_ter_ratio), weight(popMF)
separate yr_sch_ter_ratio_mean, by(region) gen(temp)
labvarch temp*, after(==) 
twoway(connected temp* year), ///
  yline(1, lwidth(0.3) lstyle(dot) lcolor(black)) ///
  title("Years of Tertiary School") ///
  ytitle("Y") ///
  name(g3, replace)
drop temp* 

grc1leg g1 g2 g3, ycommon col(3)

////////////////////////////////////////
/*      PLOT LFPR OVER TIME         */ 
///////////////////////////////////////

use "producedData/WDI_tidy.dta", clear // use just clean WDI data for global level

keep if country == "World"

graphsetup 9 7
label variable LFPR_F "Female"
label variable LFPR_M "Male"
gen year_offset1 = year - 1
gen year_offset2 = year + 1
twoway (bar LFPR_F year_offset1, barwidth(2)) ///
   (bar LFPR_M year_offset2, barwidth(2)), ///
   ysc(r(0 100)) ///
   ytick(#10) ylabel(#10) 
  
///////////////////////////////////////////////////////
/*      PLOT LFPR RATIO BY REGION OVER TIME          */ 
///////////////////////////////////////////////////////

use "producedData/finalData.dta", clear

graphsetup 11 7
bysort region year: egen LFPR_ratio_mean = wtmean(LFPR_ratio), weight(popMF)
separate LFPR_ratio_mean, by(region) gen(temp)
labvarch temp*, after(==) 
twoway(connected temp* year), ///
   ytitle(Ratio of female to male LFPR) /// 
   ysc(r(0 1)) /// 
   ytick(0(5)1) ylabel(,grid)
     
///////////////////////
/*      MODELS       */ 
///////////////////////

use "producedData/finalData.dta", clear

/* change in LFPR vs change in years of school */
regress LFPR_MF_9010 yr_schMF_9010 
rvpplot yr_schMF_9010, yline(0) // diagnostics

/* change in FEMALE LFPR vs change in years of school */
regress LFPR_F_9010 yr_schF_9010 
rvpplot yr_schF_9010, yline(0)  // diagnostics
   
/* FINAL MODEL 2: change in FEMALE LFPR vs change in FEMALE years of school */ 
label variable yr_schF_9010 "Change in Female Years of Schooling, 1990 to 2010"
eststo clear
eststo: quietly regress LFPR_F_9010 yr_schF_9010 
eststo: quietly regress LFPR_F_9010 yr_schF_9010 i.region
esttab using "TeX/LFPR_F_sch.tex", label replace booktabs p width(\hsize) nomtitles ///
   title("Regression of the change in female labor force participation from 1990 to 2010 against change in female years of schooling during the same period "\label{tab1})
   
/* change in PER CAPITA GDP vs change in years of school */
use "producedData/finalData.dta", clear

/* Get rid of outliers */ 
drop if WBcode == "ARE" 
drop if WBcode == "MAC" 

/* UAE is an outlier with really low change in GDP per capita - this makes sense 
   because of the oil crash in 2009.  Macao is an outlier with a huge increase in
   GDP per capita - this also makes sense because it was returned to China in 
   1999. Both UAE and Macao are removed from plots and analysis. */ 
   
regress GDP_perCap_9010 yr_schMF_9010 
rvpplot yr_schMF_9010, yline(0)  // diagnostics 


log close
