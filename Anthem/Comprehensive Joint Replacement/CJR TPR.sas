*********************************;
*	TARGET PRICING REPORT - CJR	*;
*********************************;
***NOTE: THIS PROGRAM IS TO BE USED WITH R10 DATA OR LATER. IT HAS BEEN UPDATED FOR THE AGE CRITERIA THAT 
WAS ADDED IN R10 AND WILL ONLY GIVE THE CORRECT READMISSION RATES FOR R10 OR AFTER***;

*NORTHWELL: '111562701','111630914','111633487','111661359','111667761','112241326','112296824','112868878','113241243','131624070','131725076','131740118','112163522'; 
*MT SINAI: '135564934','131624096','132997301','135562304';
*LIHN: '111704595','111888924','111639818','111635088','111352310','061562701','111871039','112050523','113438973','111633486';

options compress=yes MPRINT SYMBOLGEN;

*MUST FILL THESE FOR EACH REPORT*;
*ALL INPUTS MUST BE ONE WORD - CAN HAVE AN UNDERSCORE IF NECESSARY*;
%LET BUNDLE=TJR;
%LET PROVIDER=LIHN; 
%LET IDVAR=billg_tax_id_hoppa;
%LET FILEPATH=/ephc/ebp/nobackup/users/blase/;
%LET RELEASE=R10;
%LET ADMINID=%STR('111704595','111888924','111639818','111635088','111352310','061562701','111871039','112050523','113438973','111633486');
%LET STARTDATE=1015;
%LET ENDDATE=0916;
%LET ST=NY;

libname &BUNDLE._LIB "/ephc/ebp/backup/data/phi/mcare/%LOWCASE(&BUNDLE)/%LOWCASE(&ST)/%LOWCASE(&BUNDLE)";

%LET DATASET=&ST._&BUNDLE._&STARTDATE._&ENDDATE._&RELEASE;


*ALL VALID EPISODES FOR MARKET AND PROVIDER OF INTEREST*;

DATA &BUNDLE._MARKET &BUNDLE._&PROVIDER;
SET &BUNDLE._LIB.&DATASET;

/*CJR WATERFALL CRITERIA*/

/* CJR -- VALID Flagging criteria applied here */
if 
DRG_flg=1 AND /* Exclude episodes with the correct surg proc code but incorrect DRG (i.e., 462)*/
ind_flg=1 AND /* index trigger occurred within designated index period exclude 2nd index trigger */
lob_lvl_flg=5 AND /* Program Participation - MCARE  */
WP_Primary=0 AND /* Anthem primary criteria */
IP_flg=1 AND /* restrict to IP setting only */
DEATH_flg=0 AND /* restrict to alive at discharge */
DISCHARGE_flg ne 3 AND /* hospice discharge considered same as death */
cutoff_flg=0 AND /* remove 1st episode if truncated as contralateral */
bundlecost_tot_PCR ge 4000 AND /* pricing program exclusion - remove episodes for low outlier exclusion */
age_flg=1   /* minimum age 65+ at index service date criteria */

THEN VALID=1;
ELSE VALID=0;

IF &IDVAR IN (&ADMINID) AND VALID=1 THEN OUTPUT &BUNDLE._&PROVIDER; *OUTPUTTING ALL VALID EPISODES FOR A PROVIDER*;
IF VALID=1 THEN OUTPUT &BUNDLE._MARKET; *OUTPUTTING ALL VALID EPISODES FOR A MARKET*;

RUN;

*READMISSION VARIABLE: CMS_readmit_flg2*;

*CREATING MACRO VARIABLES FOR THE TOTAL NUMBER OF VALID OBSERVATIONS
NOTE: THESE NUMBERS WILL STAY THE SAME REGARDLESS OF RENEGOTIATIONS*;
PROC SQL;
SELECT DISTINCT 
COUNT(*)
INTO :N_&PROVIDER._&BUNDLE
FROM &BUNDLE._&PROVIDER;

*CALCULATING MARKET READMISSION RATE*;
CREATE TABLE MARKET_READMIT AS
SELECT 
/*READMISSION RATE*/
SUM(CMS_readmit_flg2)/COUNT(*) AS READMIT_MARKET FORMAT=PERCENT8.1 LABEL="Market Readmission Rate",
1 AS MERGEVAR 
FROM &BUNDLE._MARKET;

*CALCULATING MARKET MORTALITY RATE*;
CREATE TABLE MARKET_MORT AS
SELECT
/*MORTALITY RATE*/
SUM(CASE WHEN DEATH_FLG=1 OR DISCHARGE_FLG=3 THEN 1 ELSE 0 END)/COUNT(*) AS MORT_MARKET 
FORMAT=PERCENT8.1 LABEL="Market Mortality Rate",
1 AS MERGEVAR 
FROM &BUNDLE._LIB.&DATASET
WHERE ind_flg=1 and DRG_flg=1 and lob_lvl_flg in (5) and WP_Primary=0;

*CALCULATING PROVIDER MORTALITY RATE*;
CREATE TABLE &PROVIDER._MORT AS
SELECT
/*MORTALITY RATE*/
SUM(CASE WHEN DEATH_FLG=1 OR DISCHARGE_FLG=3 THEN 1 ELSE 0 END)/COUNT(*) AS MORT_&PROVIDER 
FORMAT=PERCENT8.1 LABEL="&PROVIDER Mortality Rate",
1 AS MERGEVAR 
FROM &BUNDLE._LIB.&DATASET
WHERE &IDVAR IN (&ADMINID) AND ind_flg=1 and DRG_flg=1 and lob_lvl_flg in (5) and WP_Primary=0;

*CALCULATING NUMBER OF INITIAL EPISODES (BEFORE EXCLUSION CRITERIA APPLIED)*;
CREATE TABLE INITIAL_EPS AS 
SELECT
/* GENERATE TOPLINE -- Initial Episodes */
SUM (IND_FLG=1 AND DRG_FLG=1 AND LOB_LVL_FLG=5) AS INITIAL_EPISODES LABEL='Topline Number of Total Baseline Episodes',
1 AS MERGEVAR
FROM &BUNDLE._LIB.&DATASET
WHERE &IDVAR IN (&ADMINID);

*CREATING MACRO VARIABLE FOR HIGH COST*;
SELECT 
MEAN(bundlecost_tot_PCR)+(2*(STD(bundlecost_tot_PCR)))
INTO :HIGHCAP_&PROVIDER._&BUNDLE
FROM &BUNDLE._MARKET;

*CREATING VARIABLE FOR HIGH COST FOR OUTPUTTING*;
CREATE TABLE HIGHCOST AS
SELECT
/*HIGH OUTLIER CAP*/
MEAN(bundlecost_tot_PCR)+(2*(STD(bundlecost_tot_PCR))) AS HIGHCAP_VAR_&PROVIDER FORMAT=DOLLAR11. 
LABEL='High Outlier Cap',
1 AS MERGEVAR
FROM &BUNDLE._MARKET; 

CREATE TABLE T1 AS 
SELECT bundlecost_tot_PCR, 
CASE
/*ADJUSTING COSTS TO HIGH CAP*/
/*WHEN A TOTAL BUNDLE COST IS GREATER THAN THE MARKET HIGH OUTLIER, WE CAP IT AT THE HIGH OUTLIER COST */
WHEN bundlecost_tot_PCR>&&HIGHCAP_&PROVIDER._&BUNDLE THEN &&HIGHCAP_&PROVIDER._&BUNDLE 
ELSE bundlecost_tot_PCR
END AS NEWBUNDLE_TOT,
/*Total Outlier Adjusted Allowed Dollars for Valid Episodes*/
SUM(CALCULATED NEWBUNDLE_TOT) AS NEWBUNDLE_SUM
FROM &BUNDLE._&PROVIDER;
/*ONLY FOR CASES OVER $4K, IF UNDER THEY ARE EXCLUDED*/
/*WHERE bundlecost_tot_PCR GE 4000;*/

*CREATING MACRO VARIABLE FOR THE SUM OF THE NEW BUNDLE TO USE BELOW*;
SELECT DISTINCT NEWBUNDLE_SUM
INTO :NEWBUNDLE_SUM
FROM T1;

/*MACRO VARIABLE FOR INITIAL TOPLINE EPISODES FOR PROVIDER*/
SELECT
/* GENERATE TOPLINE -- Initial Episodes */
SUM (IND_FLG=1 AND DRG_FLG=1 AND LOB_LVL_FLG=5) 
INTO :N_INITIAL
FROM &BUNDLE._LIB.&DATASET
WHERE &IDVAR IN (&ADMINID);

CREATE TABLE T2 AS
SELECT 
/*NUMBER OF VALID BASELINE EPISODES*/
COUNT(*) AS ELIG_EPS LABEL='Number of Valid Baseline Episodes',
/*Total Actual Baseline Allowed Dollars for Valid Episodes (prior to outlier adjustment)*/
SUM(bundlecost_tot_PCR) AS BL_TOT FORMAT=DOLLAR11. 
LABEL='Total Actual Baseline Allowed Dollars for Valid Episodes (prior to outlier adjustment)',
/*Number of Low Outlier Episodes Removed*/
/*SUM(bundlecost_tot_PCR<4000) AS LOW_REMOVED LABEL='Number of Low Outlier Episodes Removed',*/
/*Number of High Outlier Episodes Adjusted*/
SUM(bundlecost_tot_PCR>&&HIGHCAP_&PROVIDER._&BUNDLE) AS HIGH_CAPPED 
LABEL='Number of High Outlier Episodes Adjusted',
/*SIMPLE HISTORICAL CASE RATE - ADJUSTING FOR RICHMOND RENEGOTIATION*/
MEAN(index_prof_SURG_PCR) AS HIST_CSRATE FORMAT=DOLLAR11. LABEL='Historical Case Rate',
/*READMISSION RATE*/
SUM(CMS_readmit_flg2)/&&N_&PROVIDER._&BUNDLE AS READMIT_&PROVIDER FORMAT=PERCENT8.1
LABEL="&PROVIDER Readmission Rate",
/*OUTLIER ADJUSTED AMOUNT*/
CALCULATED BL_TOT-&NEWBUNDLE_SUM AS ADJ_AMT FORMAT=DOLLAR11. LABEL="Outlier Adjusted Amount",
1 AS MERGEVAR,

/*MP1 DATA*/
/*CALCULATING PROPOSED EPISODE TARGET TO USE IN FORMULA BELOW*/
/*Outlier Adjusted Cost per Valid Episode (CELL E22 - INTERNAL)*/
&NEWBUNDLE_SUM/(&&N_&PROVIDER._&BUNDLE) AS ADJCOST_PEREP FORMAT=DOLLAR11. 
LABEL='Outlier Adjusted Cost per Valid Episode',
/*PROPOSED EPISODE TARGET (CELL E24 - INTERNAL)*/
CALCULATED ADJCOST_PEREP*0.94 AS EP_TARGET FORMAT=DOLLAR11. 
	LABEL= "Proposed Episode Target", /*COST PER VALID EPISODE WITH 6 PERCENT HAIRCUT*/ 
/*CELL H39*/
(&&N_&PROVIDER._&BUNDLE/2)*CALCULATED EP_TARGET AS H39 FORMAT=DOLLAR11. LABEL="Aggregate Target Budget",

(&N_INITIAL/2)*CALCULATED HIST_CSRATE AS TAA_EXCLUSIVE FORMAT=DOLLAR11. 
	LABEL='Total Allowed Amount exclusive of fee schedule adjustment',

/*DOING THIS FOR ALL 3 MODELS*/
/*CELL I39*/
(CALCULATED H39*0.9) AS I39_MOD4 FORMAT=DOLLAR11. LABEL="Range 4", /*10 PERCENT*/
(CALCULATED H39*0.9249) AS I39_MOD3 FORMAT=DOLLAR11. LABEL="Range 3", /*7.51 PERCENT*/
(CALCULATED H39*0.9449) AS I39_MOD2 FORMAT=DOLLAR11. LABEL="Range 2", /*5.51 PERCENT*/
(CALCULATED H39*0.96) AS I39_MOD1 FORMAT=DOLLAR11. LABEL="Range 1", /*4 PERCENT*/

/*estimated shared savings potential opportunity (40 percent)*/
(CALCULATED H39- CALCULATED I39_MOD4)*0.4 AS SSPO_MOD4 FORMAT=DOLLAR11. 
	LABEL="Shared Savings Potential Opp - Range 4", /*RANGE 4 - 10 PERCENT*/
(CALCULATED H39- CALCULATED I39_MOD3)*0.4 AS SSPO_MOD3 FORMAT=DOLLAR11. 
	LABEL="Shared Savings Potential Opp - Range 3", /*RANGE 3 - 7.51 PERCENT*/
(CALCULATED H39- CALCULATED I39_MOD2)*0.4 AS SSPO_MOD2 FORMAT=DOLLAR11. 
	LABEL="Shared Savings Potential Opp - Range 2", /*RANGE 2 - 5.51 PERCENT*/
(CALCULATED H39- CALCULATED I39_MOD1)*0.4 AS SSPO_MOD1 FORMAT=DOLLAR11. 
	LABEL="Shared Savings Potential Opp - Range 1", /*RANGE 1 - 4 PERCENT*/

/*CALCULATING PERCENTAGE INCREASE TO EQUAL EXACT SHARED SAVINGS OPPORTUNITY*/
CEIL((((CALCULATED SSPO_MOD4+CALCULATED TAA_EXCLUSIVE)/CALCULATED TAA_EXCLUSIVE)-1)*100) AS 
CASERATE_ADJ_MOD4 LABEL="Case Rate Adjustment - Range 4", /*RANGE 4 - 10 PERCENT*/
CEIL((((CALCULATED SSPO_MOD3+CALCULATED TAA_EXCLUSIVE)/CALCULATED TAA_EXCLUSIVE)-1)*100) AS 
CASERATE_ADJ_MOD3 LABEL="Case Rate Adjustment - Model 3", /*RANGE 3 - 7.51 PERCENT*/
CEIL((((CALCULATED SSPO_MOD2+CALCULATED TAA_EXCLUSIVE)/CALCULATED TAA_EXCLUSIVE)-1)*100) AS 
CASERATE_ADJ_MOD2 LABEL="Case Rate Adjustment - Model 2", /*RANGE 2 - 5.51 PERCENT*/
CEIL((((CALCULATED SSPO_MOD1+CALCULATED TAA_EXCLUSIVE)/CALCULATED TAA_EXCLUSIVE)-1)*100) AS 
CASERATE_ADJ_MOD1 LABEL="Case Rate Adjustment - Model 1"/*RANGE 1 - 4 PERCENT*/

FROM &BUNDLE._&PROVIDER;

CREATE TABLE FINAL_&BUNDLE (DROP=MERGEVAR /*H39 TAA_EXCLUSIVE I39_MOD3 I39_MOD2 I39_MOD1 SSPO_MOD3 SSPO_MOD2 
SSPO_MOD1*/) AS
SELECT *
FROM INITIAL_EPS AS IE, T2 AS TABLE2, MARKET_READMIT AS MR, MARKET_MORT AS MM, 
HIGHCOST AS HC, &PROVIDER._MORT AS PMORT
WHERE IE.MERGEVAR=TABLE2.MERGEVAR=MR.MERGEVAR=MM.MERGEVAR=HC.MERGEVAR=PMORT.MERGEVAR; 
QUIT; 


OPTIONS ORIENTATION=LANDSCAPE;
ODS RTF FILE="&FILEPATH &PROVIDER &BUNDLE TPR - &SYSDATE..RTF"; 

TITLE "&PROVIDER &BUNDLE &RELEASE"; 
TITLE2 "FOR IDS: &ADMINID";
PROC PRINT DATA=FINAL_&BUNDLE LABEL; RUN;

ODS RTF CLOSE;

TITLE; TITLE2;


