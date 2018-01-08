*CJR MOA*;
*NOTE: IF YOU NEED TO RERUN THE CODE ABOVE RUN THE PROC DATASETS LINE BELOW TO CLEAR ALL TEMPORARY DATASETS SO OLD DATASETS DONT GET APPENDED TO NEW DATASETS*; 
PROC DATASETS LIBRARY=WORK KILL; RUN; QUIT;

OPTIONS MPRINT COMPRESS=YES;

**********************************************************************************************************************************************************************;
*MACRO PARAMETERS:*;

*STARTDATE: THE MONTH AND YEAR OF THE START OF THAT RELEASE (E.G. FOR R7, 0115)*;
*ENDDATE: THE MONTH AND YEAR OF THE END OF THAT RELEASE (E.G. FOR R7, 1215)*;
*BUNDLE: ABBREVIATION FOR BUNDLE (E.G. MAT)*;
*FILEPATH: A FILEPATH FOR OUTPUTTING (MUST BE SOMETHING YOU HAVE PERMISSION TO WRITE TO) (E.G. /ephc/ebp/nobackup/users/blase/)*; 
*RELEASE: RELEASE OF THE DATASET (E.G. R5)*;
*STATE: STATE ABBREVIATION (E.G. OH)*;
*FACIDVAR: FACILITY ID VARIABLE TO DISPLAY IN REPORTS ON PROVIDERS AND COST BY INDEX FACILITY TABS (E.G. billg_tax_id_hoppa OR indx_SRC_BILLG_TAX_ID)*;
*NOTE: DO NOT CHANGE THE DATASET MACRO VARIABLE, IT WILL BE CREATED FROM OTHER MACRO VARIABLES YOU POPULATE*;
**********************************************************************************************************************************************************************;
*FILL IN 7 PARAMETERS BELOW*;
*NOTE: ALTHOUGH WE CALL IT CJR NOW IT USED TO BE CALLED TJR AND THE DATASET IS IN THE TJR LIBRARY SO MAKE SURE
IT SAYS TJR IN THE LET STATEMENT BELOW*;

%LET STARTDATE=1015;
%LET ENDDATE=0916;
%LET BUNDLE=TJR;
%LET RELEASE=R10;
%LET STATE=NY;
%LET FACIDVAR=BILLG_TAX_ID_HOPPA;
%LET FILEPATH=/ephc/ebp/nobackup/users/blase/;
*------------------------------------------------------------------------------------------------------------------*;

%LET DATASET=&STATE._&BUNDLE._&STARTDATE._&ENDDATE._&RELEASE;
LIBNAME &BUNDLE._LIB "/ephc/ebp/backup/data/phi/mcare/%LOWCASE(&BUNDLE)/%LOWCASE(&STATE)/%LOWCASE(&BUNDLE)";


PROC FORMAT;

VALUE $WF "INITIAL_EPISODES"="Initial Medicare Advantage Episodes Identified"
			"MEM_EXCL_HEADING"="Member Program Participation Eligibility Exclusions" 
			"ANTHEM_EXCLUDE"="Anthem is not Primary"
			"MBR_TOT_EXCLUDE"="TOTAL Member Program Participation Eligibility Exclusions"
			"CLIN_EXCL_HEADING"="Clinical Program Exclusions"
			"SETTING_EXCLUDE"="Clinical Exclusion - Site of Service Non-IP"	
			"CUTOFF_EXCLUDE"="Clinical Exclusion - Contralateral"
			"DEATH_EXCLUDE"="Clinica Exclusion - Death"
			"CLIN_TOT_EXCLUDE"="TOTAL Clinical Program Exclusions"
			"PGM_EXCL_HEADING"="Pricing Program Exclusions"
			"COST_EXCLUDE"="Low Cost Outlier <$4,000"
			"PGM_TOT_EXCLUDE"="TOTAL Pricing Program Exclusions"
			"ELIG_EPISODES"="TOTAL Program Eligible Episodes"
			"AGE_EXCLUDE"="Age <65";


VALUE $ SRVC "IP Hosp"="Inpatient Hospital"
		     "OP Hosp"="Outpatient Hospital"
		     "ASC"="Ambulatory Surgical Center"
		     "ED"="Emergency Room"
			 "Total"="Episode Bundle Volume - Total";

VALUE $ SRVCNEW "IP Hosp"="ACUTE INPATIENT HOSPITAL"
		   "OP Hosp"="ACUTE OUTPATIENT HOSPITAL"
		   "ASC"="AMBULATORY SURGICAL CENTER"
			"Total"="ALL SITES OF SERVICE";


VALUE $ TMPFMT 'Total'='1'
			 'IP Hosp'='2'
			 'OP Hosp'='3'
			 'ASC'='4';

VALUE $CODEFMT '1'='Episode Bundle Volume - Total'
				'2'='Inpatient Hospital'
				'3'='Outpatient Hospital'
				'4'='Ambulatory Surgical Center';


VALUE $LOBF 'COMMERCIAL BUSINESS'='COMMERCIAL'
			'FEDERAL GOVERNMENT SOLUTIONS'='FEP';


VALUE $PRODUCTF 'POS'='OTHER';

VALUE $FUNDF 'ALTERNATE FUNDED'='ASO'
			 'INSURED'='FI';

VALUE $FUND2F 'ALTERNATE FUNDED'='ALTERNATE FUNDED (ASO)'
			 'INSURED'='FULLY INSURED (FI)';

VALUE GRAPHVAR 1="<$10,000"
			   2="$10,000-$14,999"
			   3="$15,000-$19,999"
			   4="$20,000-$24,999"
			   5="$25,000+";

VALUE GRAPHVAR_IQR  1="<$5,000"
			   		2="$5,000-$9,999"
			   		3="$10,000-$14,999"
			   		4="$15,000-$19,999"
			   		5="$20,000+";

RUN;

/*RUNNING ELIGIBLE EPISODES FOR ALL 14 MARKETS*/

/*%MACRO ALLTKR;*/
/**/
/*%LET STLIST=CA CO CT GA IN KY ME MO NH NV NY OH VA WI;*/
/**/
/*%DO A=1 %TO 14;*/
/*        %LET ST=%SCAN(&STLIST, &A, %STR( ));*/
/**/
/*libname &ST._LIB "/ephc/ebp/backup/data/phi/tjr/%LOWCASE(&ST)/%LOWCASE(&BUNDLE)";*/
/**/
/*PROC SQL;*/
/*CREATE TABLE ALLVAR_&ST.2 AS*/
/*SELECT bundlecost_tot_PCR, &FACIDVAR, SURGEON_NPI, MBR_KEY,  */
/*COUNT(*) AS ELIGTOT,*/
/*"&ST" AS STATE,*/
/*UPCASE(FACNAME_HOPPA) AS FACNAME_HOPPA2,*/
/*UPCASE(SURGEON_NAME) AS SURGEON_NAME2*/
/*FROM &ST._LIB.&ST._&BUNDLE._&STARTDATE._&ENDDATE._&RELEASE*/
/*WHERE DRG_flg=1 AND /* Exclude episodes with the correct surg proc code but incorrect DRG (i.e., 462)*/*/
/* 		  /* DRG inclusion criteria for index procedure but only apply to IP episodes */*/
/*			  /* allows for ASC episodes to not be excluded b/c DRG criteria is not applicable */*/
/*ind_flg=1 AND /* index trigger occurred within designated index period exclude 2nd index trigger */*/
/*			  /* occurring during experience period but outside of index period -- ind_flg=2 */*/
/* cap_flg in (0,2) AND  /* product exclusion criteria episodes with capitation-- cap_flg=1 */*/
/*ex_dx_flg=0 AND 	/* clinical historical exclusion criteria */*/
/*dx_flg=1 AND 		/* Dx inclusion criteria */*/
/*lob_lvl_flg in (1,2,3,4) AND /* Program Participation Exclusions of MCARE and MCAID */					*/
/*enrl_flg=1 AND /* continuous enrollment criteria */*/
/*lob_flg=1 AND  /* continuous enrollment in same plan criteria */*/
/*age_flg=1 AND  /* minimum age at index service date criteria */*/
/*WP_Primary=0 AND /* Anthem primary criteria */*/
/*blt_flg=0 AND   /* bilateral exclusion criteria */*/
/*hosp_only_flg=0; /* product exclusion criteria */*/
/**/
/*QUIT;*/
/**/
/*PROC APPEND BASE=ALLSTATES2 DATA=ALLVAR_&ST.2 FORCE; */
/*RUN;*/
/**/
/*PROC SQL;*/
/*CREATE TABLE CT_&ST.2 AS*/
/*SELECT*/
/*COUNT(*) AS ELIGTOT,*/
/*"&ST" AS STATE*/
/*FROM ALLVAR_&ST.2;*/
/*QUIT;*/
/**/
/*PROC APPEND BASE=ALLSTATES_COUNT2 DATA=CT_&ST.2 FORCE; */
/*RUN;*/
/**/
/*%END;*/
/**/
/*%MEND ALLTKR;*/
/*%ALLTKR; */

*CLEANING SURGEON NAME*;
*EXTRACTING INDIVIDUAL SURGEONS*;

/*PROC SQL;*/
/*CREATE TABLE ALLST_TAB4 AS*/
/*SELECT DISTINCT SURGEON_NPI, SURGEON_NAME2*/
/*FROM ALLSTATES2*/
/*ORDER BY SURGEON_NPI, SURGEON_NAME2;*/
/*QUIT;*/
/**/
/**IF PROVIDER HAS THE SAME NPI BUT NAME IS DIFFERENT THIS REMOVES DUPLICATE NAMES*;*/
/*DATA ALLST_TAB5;*/
/*SET ALLST_TAB4;*/
/*BY SURGEON_NPI;*/
/*IF FIRST.SURGEON_NPI;*/
/*RUN;*/
/**/
/**RE-SORTING DATASET TO BE MERGED BELOW*;*/
/*PROC SORT DATA=ALLST_TAB5; BY SURGEON_NPI; RUN;*/
/*PROC SORT DATA=ALLSTATES2; BY SURGEON_NPI; RUN;*/
/**/
/**REMERGING DATASET WITH NAME CORRECTIONS FOR LATER USE AND ONLY KEEPING ELIGIBLE CASES*;*/
/**NOTE: USE SURGEON_NAME2 FOR SURGEON NAME AND FACNAME_HOPPA2 FOR FACILITY NAME SINCE THEYRE CORRECTED*;*/
/*DATA ALLST_&BUNDLE;*/
/*MERGE ALLSTATES2 (DROP=SURGEON_NAME2)*/
/*	  ALLST_TAB5;*/
/*BY SURGEON_NPI;*/
/*RUN;*/
/**/
/**TOP 5 FACILITIES IN THE STATE*;*/
/*PROC SQL;*/
/*CREATE TABLE ALLST_FACILITY AS */
/*SELECT FACNAME_HOPPA2,*/
/*COUNT(*) AS ELIG_FAC*/
/*FROM ALLST_&BUNDLE*/
/*GROUP BY FACNAME_HOPPA2*/
/*ORDER BY ELIG_FAC DESC, FACNAME_HOPPA2;*/
/*QUIT;*/
/**/
/**OUTPUT THIS FOR DASHBOARD TAB*;*/
/*DATA FACILITY5;*/
/*SET ALLST_FACILITY;*/
/**/
/*IF _N_<=5;*/
/**/
/*RUN;*/
/**/
/**TOP 5 SURGEONS IN THE STATE*;*/
/*PROC SQL;*/
/*CREATE TABLE ALLST_SURGEON AS */
/*SELECT SURGEON_NAME2,*/
/*COUNT(*) AS ELIG_SURG*/
/*FROM ALLST_&BUNDLE*/
/*GROUP BY SURGEON_NAME2*/
/*ORDER BY ELIG_SURG DESC, SURGEON_NAME2;*/
/*QUIT;*/
/**/
/**THIS WILL BE OUTPUT FOR DASHBOARD TAB*;*/
/*DATA SURGEON5;*/
/*SET ALLST_SURGEON;*/
/**/
/*IF _N_<=5;*/
/**/
/*RUN;*/
/**/
/**CALCULATING MEAN, MEDIAN, 1ST AND 3RD QUARTILES FOR ALL ELIGIBLE EPISODES IN ALL STATES*;*/
/*PROC MEANS DATA=ALLST_&BUNDLE N MEAN MEDIAN Q1 Q3 MAXDEC=0;*/
/*VAR bundlecost_tot_PCR;*/
/*OUTPUT OUT=ALLSTATES_OUT N=BUNDLE_N MEAN=BUNDLE_MEAN MEDIAN=BUNDLE_MEDIAN Q1=BUNDLE_Q1 Q3=BUNDLE_Q3;*/
/*RUN;*/

DATA &BUNDLE._ORIG;
SET &BUNDLE._LIB.&DATASET;
LENGTH PLAN $ 40.;

*CONVERTING PLACE OF SERVICE VARIABLE*;
IF indx_PLACE_OF_SRVC_CD='21' THEN SRVC="IP Hosp";
ELSE IF indx_PLACE_OF_SRVC_CD='22' THEN SRVC="OP Hosp";
ELSE IF indx_PLACE_OF_SRVC_CD='24' THEN SRVC="ASC";
ELSE IF indx_PLACE_OF_SRVC_CD='23' THEN SRVC="ED";
ELSE SRVC="Other";

*MAKING NUMERIC SRVC VARIABLE SO EASIER TO SORT*;
IF SRVC="IP Hosp" THEN SRVC2=1;
ELSE IF SRVC="OP Hosp" THEN SRVC2=2;
ELSE IF SRVC="ASC" THEN SRVC2=3;
ELSE IF SRVC="ED" THEN SRVC2=4;
ELSE SRVC2=5;

IF PROD_LVL_2_DESC IN ('PPO','OTHER','FFS') THEN PROD='PPO';
ELSE IF PROD_LVL_2_DESC=' ' THEN PROD='UNK';
ELSE PROD='HMO';

FACNAME_HOPPA2=UPCASE(FACNAME_HOPPA);

SURGEON_NAME2=UPCASE(SURGEON_NAME);

RUN;

PROC SQL;
CREATE TABLE &BUNDLE._WATERFALL AS
SELECT
/* GENERATE TOPLINE -- Initial Episodes */
SUM (IND_FLG=1 AND DRG_FLG=1 AND LOB_LVL_FLG=5) AS INITIAL_EPISODES,

/* MEMBER Program Participation Exclusions */
SUM(IND_FLG=1 AND DRG_FLG=1 AND LOB_LVL_FLG=5 AND WP_PRIMARY=1) AS ANTHEM_EXCLUDE,

/*AGE EXCLUSION*/
SUM(IND_FLG=1 AND DRG_FLG=1 AND LOB_LVL_FLG =5 AND WP_PRIMARY=0 AND AGE_FLG=0) AS AGE_EXCLUDE,

/** MEMBER SUBTOTAL */
SUM(CALCULATED ANTHEM_EXCLUDE, CALCULATED AGE_EXCLUDE) AS MBR_TOT_EXCLUDE,

/* CLINICAL Program Exclusions */
SUM(IND_FLG=1 AND DRG_FLG=1 AND LOB_LVL_FLG=5 
AND WP_PRIMARY=0 AND AGE_FLG=1
AND ((DISCHARGE_FLG=3)OR(DEATH_FLG=1))) AS DEATH_EXCLUDE,  

SUM(IND_FLG=1 AND DRG_FLG=1 AND LOB_LVL_FLG=5 
AND WP_PRIMARY=0 AND AGE_FLG=1
AND (DISCHARGE_FLG NE 3) AND (DEATH_FLG=0) 
AND (IP_FLG=1 AND (CUTOFF_FLG=1))) AS CUTOFF_EXCLUDE,

SUM(IND_FLG=1 AND DRG_FLG=1 AND LOB_LVL_FLG=5 
AND WP_PRIMARY=0 AND AGE_FLG=1
AND (DISCHARGE_FLG NE 3) AND (DEATH_FLG=0) 
AND IP_FLG=0) AS SETTING_EXCLUDE,

/** CLINICAL SUBTOTAL  */
SUM(CALCULATED DEATH_EXCLUDE, CALCULATED CUTOFF_EXCLUDE, CALCULATED SETTING_EXCLUDE) AS CLIN_TOT_EXCLUDE,

/* Pricing Program Exclusions */
SUM(IND_FLG=1 AND DRG_FLG=1 AND lob_lvl_flg=5
AND WP_PRIMARY=0 AND AGE_FLG=1
AND (DISCHARGE_FLG NE 3) AND (DEATH_FLG=0) 
AND IP_FLG=1 
AND (CUTOFF_FLG=0) 
AND bundlecost_tot_PCR LT 4000) AS COST_EXCLUDE, 
 
/** PROGRAM SUBTOTAL */
CALCULATED COST_EXCLUDE AS PGM_TOT_EXCLUDE,

/* TOTAL Program Eligible Episode Bundles */
/* INITIAL_EPISODES - MBR_TOT_EXCLUDE - CLIN_TOT_EXCLUDE - PGM_TOT_EXCLUDE = ELIG_EPISODES */
CALCULATED INITIAL_EPISODES -
/* MBR_TOT_EXCLUDE  */
CALCULATED MBR_TOT_EXCLUDE -
/* CLIN_TOT_EXCLUDE  */
CALCULATED CLIN_TOT_EXCLUDE -
/* PGM_TOT_EXCLUDE  */
CALCULATED PGM_TOT_EXCLUDE
AS ELIG_EPISODES

FROM  &BUNDLE._ORIG
QUIT;


DATA WF_TAB1;
SET &BUNDLE._WATERFALL;

*ADDING VARIABLES FOR LINES WITH ONLY HEADINGS IN REPORT*;
MEM_EXCL_HEADING=" ";
CLIN_EXCL_HEADING=" ";
PGM_EXCL_HEADING=" ";

RUN;

PROC TRANSPOSE DATA=WF_TAB1 OUT=WF_TAB2 NAME=VAR1; 
VAR INITIAL_EPISODES
MEM_EXCL_HEADING 
ANTHEM_EXCLUDE 
AGE_EXCLUDE
MBR_TOT_EXCLUDE 
CLIN_EXCL_HEADING
SETTING_EXCLUDE
CUTOFF_EXCLUDE
DEATH_EXCLUDE 
CLIN_TOT_EXCLUDE 
PGM_EXCL_HEADING
COST_EXCLUDE 
PGM_TOT_EXCLUDE 
ELIG_EPISODES; 
RUN;

*EXTRACTING INDIVIDUAL SURGEONS - USING MOST FREQUENT SURGEON NAME PER NPI*;
PROC SQL;
CREATE TABLE TAB_SURG AS 
SELECT SURGEON_NPI, SURGEON_NAME2,
COUNT(*) AS SURG_FREQ
FROM &BUNDLE._ORIG
GROUP BY SURGEON_NPI,SURGEON_NAME2
ORDER BY SURGEON_NPI, CALCULATED SURG_FREQ DESC, SURGEON_NAME2;
QUIT;

DATA TAB_1ST_SURG;
SET TAB_SURG;
*ONLY TAKING THE FIRST NAME/NPI COMBO IF THE SURGEON NAME/NPI IS MISSING*;
	BY SURGEON_NPI;
	IF FIRST.SURGEON_NPI;
RUN;

*EXTRACTING INDIVIDUAL FACILITIES AND MEDICARE IDS - USING MOST FREQUENT FACILITY NAME*;
PROC SQL;
CREATE TABLE TAB_FAC AS 
SELECT &FACIDVAR, FACNAME_HOPPA2,
COUNT(*) AS FAC_FREQ
FROM &BUNDLE._ORIG
GROUP BY &FACIDVAR, FACNAME_HOPPA2
ORDER BY &FACIDVAR, CALCULATED FAC_FREQ DESC, FACNAME_HOPPA2;
QUIT;

*TAKING THE MOST FREQUENT FACILITY NAME PER TIN*;
DATA TAB_1ST_FAC;
SET TAB_FAC;
	BY &FACIDVAR;
	IF FIRST.&FACIDVAR;
RUN;

PROC SORT DATA=TAB_1ST_FAC; BY FACNAME_HOPPA2; RUN;
PROC SORT DATA=TAB_1ST_SURG; BY SURGEON_NAME2; RUN;

*REMERGING DATASET WITH NAME CORRECTIONS FOR LATER USE AND ONLY KEEPING ELIGIBLE CASES*;
*NOTE: USE SURGEON_NAME2 FOR SURGEON NAME AND facname_hoppa FOR FACILITY NAME SINCE THEYRE CORRECTED*;
*DID NOT CORRECT PHYSICIAN GROUP NAME SINCE ITS NOT USED IN CJR MOA*;
PROC SQL;
CREATE TABLE NEW_&BUNDLE AS 
SELECT A.*,B.SURGEON_NAME2, D.FACNAME_HOPPA2
FROM &BUNDLE._ORIG (DROP=SURGEON_NAME2 FACNAME_HOPPA2) A
LEFT JOIN TAB_1ST_SURG B
ON A.SURGEON_NPI=B.SURGEON_NPI
LEFT JOIN TAB_1ST_FAC D
ON A.&FACIDVAR=D.&FACIDVAR
WHERE  
DRG_flg=1 AND /* Exclude episodes with the correct surg proc code but incorrect DRG (i.e., 462)*/
ind_flg=1 AND /* index trigger occurred within designated index period exclude 2nd index trigger */
lob_lvl_flg=5 AND /* Program Participation - MCARE  */
WP_Primary=0 AND /* Anthem primary criteria */
IP_flg=1 AND /* restrict to IP setting only */
DEATH_flg=0 AND /* restrict to alive at discharge */
DISCHARGE_flg ne 3 AND /* hospice discharge considered same as death */
cutoff_flg=0 AND /* remove 1st episode if truncated as contralateral */
bundlecost_tot_PCR ge 4000 AND /* pricing program exclusion - remove episodes for low outlier exclusion */
age_flg=1;   /* minimum age 65+ at index service date criteria */

RUN;


*COMMENTING OUT THIS PART SINCE NOT STRATIFYING BY SURGEON FOR CJR*;
*CLEANING SURGEON NAMES*;
*EXTRACTING INDIVIDUAL SURGEONS*;

/*PROC SQL;*/
/*CREATE TABLE TAB4 AS*/
/*SELECT DISTINCT SURGEON_NPI, SURGEON_NAME2*/
/*FROM ELIGIBLE_&STATE*/
/*ORDER BY SURGEON_NPI, SURGEON_NAME2;*/
/*QUIT;*/
/**/
/**IF PROVIDER HAS THE SAME NPI BUT NAME IS DIFFERENT THIS REMOVES DUPLICATE NAMES*;*/
/*DATA TAB5;*/
/*SET TAB4;*/
/*BY SURGEON_NPI;*/
/*IF FIRST.SURGEON_NPI;*/
/*RUN;*/
/**/
/**RESORTING DATASET TO BE MERGED BELOW*;*/
/*PROC SORT DATA=TAB5; BY SURGEON_NPI; RUN;*/
/*PROC SORT DATA=ELIGIBLE_&STATE; BY SURGEON_NPI; RUN;*/
/**/
/**REMERGING DATASET WITH NAME CORRECTIONS FOR LATER USE AND ONLY KEEPING ELIGIBLE CASES*;*/
/**NOTE: USE SURGEON_NAME2 FOR SURGEON NAME AND indx_PROV_NM2 FOR FACILITY NAME SINCE THEYRE CORRECTED*;*/
/*DATA NEW_&BUNDLE;*/
/*MERGE ELIGIBLE_&STATE (DROP=SURGEON_NAME2)*/
/*	  TAB5;*/
/*BY SURGEON_NPI;*/
/*RUN;*/

*MARKET SUMMARY TAB*;
PROC SQL;
SELECT DISTINCT 
COUNT(*)
INTO :N_ELIGIBLE_&BUNDLE 
FROM NEW_&BUNDLE;
QUIT;


*MORTALITY PERCENTAGES*;
DATA MORT_DATA;
SET &BUNDLE._LIB.&DATASET;

LENGTH SRVC $ 8.; 

IF ind_flg=1 and DRG_flg=1 and lob_lvl_flg in (5) and WP_Primary=0;

*MORTALITY INDICATOR - DEATH OR DISCHARGED TO HOSPICE*;
IF DEATH_FLG=1 OR DISCHARGE_FLG=3 THEN MORT_FLG=1;
ELSE MORT_FLG=0;

*CONVERTING PLACE OF SERVICE VARIABLE*;
IF indx_PLACE_OF_SRVC_CD='21' THEN SRVC="IP Hosp";
ELSE IF indx_PLACE_OF_SRVC_CD='22' THEN SRVC="OP Hosp";
ELSE IF indx_PLACE_OF_SRVC_CD='24' THEN SRVC="ASC";
ELSE IF indx_PLACE_OF_SRVC_CD='23' THEN SRVC="ED";
ELSE SRVC="Other";

FACNAME_HOPPA2=UPCASE(FACNAME_HOPPA);
SURGEON_NPI2=SURGEON_NPI;

SURGEON_NPI2=SURGEON_NPI;
IF SURGEON_NPI="UNK" THEN SURGEON_NPI2=" ";

IF PROD_LVL_2_DESC IN ('PPO','OTHER','FFS') THEN PROD='PPO';
ELSE IF PROD_LVL_2_DESC=' ' THEN PROD='UNK';
ELSE PROD='HMO';

RUN;

%*CREATING MACRO VARIABLE FOR NUMBER OF TOTAL CASES*;
PROC SQL;
SELECT DISTINCT 
COUNT(*)
INTO :N_&BUNDLE._MORT 
FROM MORT_DATA;
QUIT;

/*MARKET SUMMARY TAB*/
%MACRO SUMMARY_TAB;

*STRATIFYING BY PLACE OF SERVICE AND PRODUCT ONLY FOR CJR;
%LET VARLIST=SRVC PROD;
%LET NAMELIST=SITESERV PRODUCT;

%DO B=1 %TO 2;
	%LET STRATVAR=%SCAN(&VARLIST, &B, %STR( ));
	%LET NAMEVAR=%SCAN(&NAMELIST, &B, %STR( ));
	
PROC SQL;
CREATE TABLE &NAMEVAR._1 AS 
SELECT &STRATVAR,
COUNT(*) AS ELIG,
CALCULATED ELIG/&&N_ELIGIBLE_&BUNDLE AS MKTSHARE,
MEAN(bundlecost_tot_PCR) AS TOT_MEAN,
MEAN(index_tot_cost_PCR) AS INDX_TOT_MEAN,
MEAN(index_fac_cost_PCR) AS INDX_FAC_MEAN,
MEAN(index_prof_cost_PCR) AS INDX_PROF_MEAN,
MEAN(postindex_fac_cost_PCR) AS POST_FAC_MEAN,
MEAN(postindex_prof_cost_PCR) AS POST_PROF_MEAN,
MEAN(postindex_tot_cost_PCR) AS POST_TOT_MEAN,
SUM(bundlecost_tot_PCR) AS TOT_SUM,
SUM(CMS_readmit_flg2)/CALCULATED ELIG AS READMIT_&STATE._PER FORMAT=PERCENT8.1
FROM NEW_&BUNDLE
GROUP BY &STRATVAR
ORDER BY ELIG DESC;

*MORTALITY PREVALENCES*;
CREATE TABLE &NAMEVAR._3 AS 
SELECT &STRATVAR,
COUNT(*) AS N_MORT,
SUM(MORT_FLG)/CALCULATED N_MORT AS MORT_PER
FROM MORT_DATA
GROUP BY &STRATVAR
ORDER BY N_MORT DESC;

QUIT;

PROC SORT DATA=NEW_&BUNDLE; BY &STRATVAR; RUN;

proc means data=NEW_&BUNDLE n Q1 Q3 maxdec=0; 
var bundlecost_tot_PCR;
OUTPUT OUT=&NAMEVAR._2 Q1=BUNDLE_Q1 Q3=BUNDLE_Q3;
BY &STRATVAR; 
RUN;

PROC SQL;
CREATE TABLE &NAMEVAR AS
SELECT A.*, B.BUNDLE_Q1, B.BUNDLE_Q3, C.MORT_PER
FROM &NAMEVAR._1 A, &NAMEVAR._2 B, &NAMEVAR._3 C
WHERE A.&STRATVAR=B.&STRATVAR=C.&STRATVAR;
QUIT;

%END;

%MEND SUMMARY_TAB;
%SUMMARY_TAB;


*MARKET BY COUNTY TAB*;

PROC SORT DATA=NEW_&BUNDLE; BY COUNTY_HOPPA; RUN;

proc means data=NEW_&BUNDLE n Q1 Q3 maxdec=0; 
var bundlecost_tot_PCR;
OUTPUT OUT=COUNTY_2 Q1=BUNDLE_Q1 Q3=BUNDLE_Q3;
BY COUNTY_HOPPA; 
RUN;

/*proc means data=NEW_&BUNDLE n Q1 Q3 maxdec=0; */
/*var bundlecost_tot_PCR;*/
/*OUTPUT OUT=COUNTY_SUM_2 Q1=BUNDLE_Q1 Q3=BUNDLE_Q3;*/
/*RUN;*/

PROC SQL;
CREATE TABLE COUNTY_1 AS 
SELECT COUNTY_HOPPA,
COUNT(*) AS ELIG,
CALCULATED ELIG/&&N_ELIGIBLE_&BUNDLE AS MKTSHARE,
MEAN(bundlecost_tot_PCR) AS TOT_MEAN,
MEAN(index_tot_cost_PCR) AS INDX_TOT_MEAN,
MEAN(index_fac_cost_PCR) AS INDX_FAC_MEAN,
MEAN(index_prof_cost_PCR) AS INDX_PROF_MEAN,
MEAN(postindex_fac_cost_PCR) AS POST_FAC_MEAN,
MEAN(postindex_prof_cost_PCR) AS POST_PROF_MEAN,
MEAN(postindex_tot_cost_PCR) AS POST_TOT_MEAN,
SUM(bundlecost_tot_PCR) AS TOT_SUM,
SUM(CMS_readmit_flg2)/CALCULATED ELIG AS READMIT_&STATE._PER FORMAT=PERCENT8.1
FROM NEW_&BUNDLE
GROUP BY COUNTY_HOPPA;

/*CREATE TABLE COUNTY_SUM_1 AS */
/*SELECT*/
/*COUNT(*) AS ELIG,*/
/*CALCULATED ELIG/&&N_ELIGIBLE_&BUNDLE AS MKTSHARE,*/
/*MEAN(bundlecost_tot_PCR) AS TOT_MEAN,*/
/*MEAN(index_tot_cost_PCR) AS INDX_TOT_MEAN,*/
/*MEAN(index_fac_cost_PCR) AS INDX_FAC_MEAN,*/
/*MEAN(index_prof_cost_PCR) AS INDX_PROF_MEAN,*/
/*MEAN(postindex_fac_cost_PCR) AS POST_FAC_MEAN,*/
/*MEAN(postindex_prof_cost_PCR) AS POST_PROF_MEAN,*/
/*MEAN(postindex_tot_cost_PCR) AS POST_TOT_MEAN,*/
/*SUM(bundlecost_tot_PCR) AS TOT_SUM,*/
/*SUM(case when age>64 then 1 else 0 end) as N_Readmit,*/
/*SUM(case when age>64 then CMS_readmit_flg2 else 0 end)/CALCULATED N_Readmit AS READMIT_&STATE._PER FORMAT=PERCENT8.1,*/
/*"Total:" AS COUNTY_HOPPA*/
/*FROM NEW_&BUNDLE;*/

*MORTALITY PREVALENCE*;
CREATE TABLE COUNTY_MORT AS 
SELECT COUNTY_HOPPA,
COUNT(*) AS N_MORT,
SUM(MORT_FLG)/CALCULATED N_MORT AS MORT_PER
FROM MORT_DATA
GROUP BY COUNTY_HOPPA
ORDER BY N_MORT DESC;

/*CREATE TABLE COUNTY_MORT_SUM AS */
/*SELECT*/
/*SUM(MORT_FLG)/&&N_&BUNDLE._MORT AS MORT_PER,*/
/*"Total:" AS COUNTY_HOPPA*/
/*FROM MORT_DATA;*/
 
CREATE TABLE COUNTY_FINAL AS
SELECT A.*, B.BUNDLE_Q1, B.BUNDLE_Q3, C.MORT_PER
FROM COUNTY_1 A, COUNTY_2 B, COUNTY_MORT C
WHERE A.COUNTY_HOPPA=B.COUNTY_HOPPA=C.COUNTY_HOPPA 
ORDER BY ELIG DESC, COUNTY_HOPPA;

/*CREATE TABLE COUNTY_SUM AS*/
/*SELECT A.*, B.BUNDLE_Q1, B.BUNDLE_Q3*/
/*FROM COUNTY_SUM_1 A, COUNTY_SUM_2 B;*/

QUIT;

*THIS DATASET WILL BE OUTPUT*;
/*DATA COUNTY_FINAL; */
/*SET COUNTY COUNTY_SUM; */
/*RUN;*/


/*MARKET BY FACILITY TAB*/
*REMOVED Medcr_id_hoppa*;
PROC SORT DATA=NEW_&BUNDLE; BY &FACIDVAR FACNAME_HOPPA2; RUN;

proc means data=NEW_&BUNDLE n Q1 Q3 QRANGE maxdec=0; 
var bundlecost_tot_PCR;
OUTPUT OUT=FACILITY_2 Q1=BUNDLE_Q1 Q3=BUNDLE_Q3 QRANGE=BUNDLE_IQR;
BY &FACIDVAR FACNAME_HOPPA2; 
RUN;

/*proc means data=NEW_&BUNDLE n Q1 Q3 maxdec=0; */
/*var bundlecost_tot_PCR;*/
/*OUTPUT OUT=FACILITY_SUM_2 Q1=BUNDLE_Q1 Q3=BUNDLE_Q3;*/
/*RUN;*/

PROC SQL;
CREATE TABLE FACILITY_1 AS 
SELECT &FACIDVAR, FACNAME_HOPPA2,
COUNT(*) AS ELIG,
CALCULATED ELIG/&&N_ELIGIBLE_&BUNDLE AS MKTSHARE,
MEAN(bundlecost_tot_PCR) AS TOT_MEAN,
MEAN(index_tot_cost_PCR) AS INDX_TOT_MEAN,
MEAN(index_fac_cost_PCR) AS INDX_FAC_MEAN,
MEAN(index_prof_cost_PCR) AS INDX_PROF_MEAN,
MEAN(postindex_fac_cost_PCR) AS POST_FAC_MEAN,
MEAN(postindex_prof_cost_PCR) AS POST_PROF_MEAN,
MEAN(postindex_tot_cost_PCR) AS POST_TOT_MEAN,
SUM(bundlecost_tot_PCR) AS TOT_SUM,
SUM(CMS_readmit_flg2)/CALCULATED ELIG AS READMIT_&STATE._PER FORMAT=PERCENT8.1
FROM NEW_&BUNDLE
GROUP BY &FACIDVAR, FACNAME_HOPPA2
ORDER BY ELIG DESC, &FACIDVAR, FACNAME_HOPPA2;

/*CREATE TABLE FACILITY_SUM_1 AS */
/*SELECT*/
/*COUNT(*) AS ELIG,*/
/*CALCULATED ELIG/&&N_ELIGIBLE_&BUNDLE AS MKTSHARE,*/
/*MEDIAN(bundlecost_tot_PCR) AS BUNDLEMED,*/
/*MEAN(bundlecost_tot_PCR) AS BUNDLEMEAN,*/
/*STD(bundlecost_tot_PCR) AS BUNDLESTD,*/
/*MIN(bundlecost_tot_PCR) AS BUNDLEMIN,*/
/*MAX(bundlecost_tot_PCR) AS BUNDLEMAX,*/
/*SUM(COMPL_FLG)/CALCULATED ELIG AS COMPL_PER,*/
/*SUM(REVISE_FLG)/CALCULATED ELIG AS REVISE_PER,*/
/*SUM(READMISSION)/CALCULATED ELIG AS READMIT_PER,*/
/*SUM(FUNDG_TYPE_LVL_1_DESC='INSURED')/CALCULATED ELIG AS FI_PER,*/
/*"Total:" AS &FACIDVAR*/
/*FROM NEW_&BUNDLE;*/

*MORTALITY PREVALENCE*;
CREATE TABLE FACILITY_MORT AS 
SELECT &FACIDVAR, FACNAME_HOPPA2,
COUNT(*) AS N_MORT,
SUM(MORT_FLG)/CALCULATED N_MORT AS MORT_PER
FROM MORT_DATA
GROUP BY &FACIDVAR, FACNAME_HOPPA2
ORDER BY N_MORT DESC;

CREATE TABLE FACILITY_FINAL AS
SELECT A.*, B.BUNDLE_Q1, B.BUNDLE_Q3, C.MORT_PER, B.BUNDLE_IQR
FROM FACILITY_1 A, FACILITY_2 B, FACILITY_MORT C
WHERE A.&FACIDVAR=B.&FACIDVAR=C.&FACIDVAR AND A.FACNAME_HOPPA2=B.FACNAME_HOPPA2=C.FACNAME_HOPPA2
ORDER BY ELIG DESC, &FACIDVAR, FACNAME_HOPPA2;

/*CREATE TABLE FACILITY_SUM AS*/
/*SELECT A.*, B.BUNDLE_Q1, B.BUNDLE_Q3*/
/*FROM FACILITY_SUM_1 A, FACILITY_SUM_2 B;*/

QUIT;

*THIS DATASET WILL BE OUTPUT*;
/*DATA FACILITY_FINAL; */
/*SET FACILITY FACILITY_SUM; */
/*RUN;*/

*MARKET BY PHYSICIAN GROUP INSTEAD OF BY SURGEON FOR CJR*;
PROC SORT DATA=NEW_&BUNDLE; BY SURGEON_TIN; RUN;

proc means data=NEW_&BUNDLE n Q1 Q3 maxdec=0; 
var bundlecost_tot_PCR;
OUTPUT OUT=PHYSGROUP_2 Q1=BUNDLE_Q1 Q3=BUNDLE_Q3;
BY SURGEON_TIN; 
RUN;

PROC SQL;
CREATE TABLE PHYSGROUP_1 AS 
SELECT SURGEON_TIN,
COUNT(*) AS ELIG,
CALCULATED ELIG/&&N_ELIGIBLE_&BUNDLE AS MKTSHARE,
MEAN(bundlecost_tot_PCR) AS TOT_MEAN,
MEAN(index_tot_cost_PCR) AS INDX_TOT_MEAN,
MEAN(index_fac_cost_PCR) AS INDX_FAC_MEAN,
MEAN(index_prof_cost_PCR) AS INDX_PROF_MEAN,
MEAN(postindex_fac_cost_PCR) AS POST_FAC_MEAN,
MEAN(postindex_prof_cost_PCR) AS POST_PROF_MEAN,
MEAN(postindex_tot_cost_PCR) AS POST_TOT_MEAN,
SUM(bundlecost_tot_PCR) AS TOT_SUM,
SUM(CMS_readmit_flg2)/CALCULATED ELIG AS READMIT_&STATE._PER FORMAT=PERCENT8.1
FROM NEW_&BUNDLE
GROUP BY SURGEON_TIN
ORDER BY ELIG DESC, SURGEON_TIN;

*MORTALITY PREVALENCE*;
CREATE TABLE PHYSGROUP_MORT AS 
SELECT SURGEON_TIN,
COUNT(*) AS N_MORT,
SUM(MORT_FLG)/CALCULATED N_MORT AS MORT_PER
FROM MORT_DATA
GROUP BY SURGEON_TIN
ORDER BY N_MORT DESC;

CREATE TABLE PHYSGROUP_FINAL AS
SELECT A.*, B.BUNDLE_Q1, B.BUNDLE_Q3, C.MORT_PER
FROM PHYSGROUP_1 A, PHYSGROUP_2 B, PHYSGROUP_MORT C
WHERE A.SURGEON_TIN=B.SURGEON_TIN=C.SURGEON_TIN
ORDER BY ELIG DESC, SURGEON_TIN;

QUIT;

/*MARKET DASHBOARD TAB CHART*/
PROC SQL;
CREATE TABLE CHART_TAB1 AS 
SELECT 
CASE
WHEN bundlecost_tot_PCR LT 10000 THEN 1
WHEN 10000<=bundlecost_tot_PCR<15000 THEN 2
WHEN 15000<=bundlecost_tot_PCR<20000 THEN 3
WHEN 20000<=bundlecost_tot_PCR<25000 THEN 4
ELSE 5
END AS GRAPHVAR
FROM NEW_&BUNDLE;
QUIT;

PROC FREQ DATA=CHART_TAB1;
   TABLES GRAPHVAR/LIST MISSING NOPERCENT out=FreqOut_ALL;
RUN;

PROC SORT DATA=FREQOUT_ALL; BY GRAPHVAR; RUN;

%*CREATING TABLE WITH ALL 5 VALUES AND 0 FOR COUNTS TO INSERT 0 CELLS IF ANY LEVELS OF GRAPHVAR ARE MISSING*;
Data full;
      do Graphvar= 1 to 5;
         count=0;
         output;
      end;
run;

%*OUTPUTTING THIS DATASET*;
%*ENTIRE DATASET*;
data CHART_ALL;
   update full freqout_ALL;
   by  Graphvar;
run;

*FACILITY INTERQUARTILE RANGE CHART*;
PROC SQL;
CREATE TABLE IQR_CHART AS 
SELECT 
CASE
WHEN BUNDLE_IQR LT 5000 THEN 1
WHEN 5000<=BUNDLE_IQR<10000 THEN 2
WHEN 10000<=BUNDLE_IQR<15000 THEN 3
WHEN 15000<=BUNDLE_IQR<20000 THEN 4
ELSE 5
END AS GRAPHVAR
FROM FACILITY_FINAL;
QUIT;

PROC FREQ DATA=IQR_CHART;
   TABLES GRAPHVAR/LIST MISSING NOPERCENT out=FreqOut_IQR;
RUN;

PROC SORT DATA=FREQOUT_IQR; BY GRAPHVAR; RUN;

%*OUTPUTTING THIS DATASET*;
%*ENTIRE DATASET*;
data IQR_TOT;
   update full freqout_IQR;
   by  Graphvar;
run;

TITLE;

*OUTPUTTING*;
ods Tagsets.ExcelXP file="&FILEPATH &STATE MOA CJR &RELEASE - &SYSDATE..xml" style=SEASIDE
     options(embedded_titles='yes' embedded_footnotes='yes');

	 *WATERFALL TAB*;
ods tagsets.excelxp options(sheet_name = 'Market Data Waterfall' sheet_interval='table');

PROC REPORT DATA=WF_TAB2;
COLUMN VAR1 COL1;
DEFINE VAR1/ DISPLAY "Episode Bundle Distribution" FORMAT=$WF.;
DEFINE COL1/ DISPLAY "Total" CENTER style(column)={tagattr='format:#,##0'};
RUN;

*DASHBOARD TAB*;
ods tagsets.excelxp options(sheet_name = 'Market Dashboard' sheet_interval='none');

PROC REPORT DATA=CHART_ALL HEADLINE CENTER SPLIT="/";
COLUMN GRAPHVAR COUNT;
DEFINE GRAPHVAR/DISPLAY "All" FORMAT=GRAPHVAR.;
DEFINE COUNT/DISPLAY "# Cases"; 
RUN;

PROC REPORT DATA=IQR_TOT HEADLINE CENTER SPLIT="/";
COLUMN GRAPHVAR COUNT;
DEFINE GRAPHVAR/DISPLAY "IQR Frequency" FORMAT=GRAPHVAR_IQR.;
DEFINE COUNT/DISPLAY "# Cases"; 
RUN;

/*PROC REPORT DATA=ALLSTATES_COUNT2 HEADLINE CENTER SPLIT="/";*/
/*COLUMN ("Count of Eligible Episodes for Each Market" STATE ELIGTOT);*/
/*DEFINE STATE/DISPLAY "State" CENTER;*/
/*DEFINE ELIGTOT/DISPLAY "Eligible/Episodes" CENTER style(column)={tagattr='format:#,##0'} ; */
/*RUN;*/

/*PROC REPORT DATA=FACILITY5 HEADLINE CENTER SPLIT="/";*/
/*COLUMN ("Top 5 Facilities by Total Eligible Episode Bundles" FACNAME_HOPPA2 ELIG_FAC);*/
/*DEFINE FACNAME_HOPPA2/DISPLAY "Facility";*/
/*DEFINE ELIG_FAC/DISPLAY "Eligible/Episodes" CENTER style(column)={tagattr='format:#,##0'} ; */
/*RUN;*/

/*PROC REPORT DATA=SURGEON5 HEADLINE CENTER SPLIT="/";*/
/*COLUMN ("Top 5 Facilities by Total Eligible Episode Bundles" SURGEON_NAME2 ELIG_SURG);*/
/*DEFINE SURGEON_NAME2/DISPLAY "Surgeon";*/
/*DEFINE ELIG_SURG/DISPLAY "Eligible/Episodes" CENTER style(column)={tagattr='format:#,##0'} ; */
/*RUN;*/
/**/
/*PROC REPORT DATA=ALLSTATES_OUT HEADLINE CENTER SPLIT="/";*/
/*COLUMN ("Total Episode Bundle Costs" BUNDLE_N BUNDLE_Q1 BUNDLE_MEAN BUNDLE_MEDIAN BUNDLE_Q3);*/
/*DEFINE BUNDLE_MEAN/DISPLAY "Mean" RIGHT style(column)={cellwidth=1.0 in tagattr='format:$#,##0'};*/
/*DEFINE BUNDLE_Q1/DISPLAY "1st Quartile" RIGHT style(column)={cellwidth=1.0 in tagattr='format:$#,##0'};*/
/*DEFINE BUNDLE_Q3/DISPLAY "3rd Quartile" RIGHT style(column)={cellwidth=1.0 in tagattr='format:$#,##0'};*/
/*DEFINE BUNDLE_MEDIAN/DISPLAY "Median" RIGHT style(column)={cellwidth=1.0 in tagattr='format:$#,##0'};*/
/*DEFINE BUNDLE_N/DISPLAY "Total Episodes for All Markets" style*/
/*(column)={cellwidth=1.0 in tagattr='format:#,##0'};*/
/*RUN;*/

*SUMMARY TAB*;
ods tagsets.excelxp options(sheet_name = 'Market Summary' sheet_interval='none');

/*SITE OF SERVICE*/
PROC REPORT DATA=SITESERV HEADLINE CENTER SPLIT="/";
COLUMN SRVC ELIG MKTSHARE INDX_FAC_MEAN INDX_PROF_MEAN INDX_TOT_MEAN POST_FAC_MEAN POST_PROF_MEAN 
POST_TOT_MEAN TOT_MEAN BUNDLE_Q1 BUNDLE_Q3 TOT_SUM READMIT_&STATE._PER MORT_PER;

DEFINE SRVC/DISPLAY "Site of Service" FORMAT=$SRVCNEW.;
DEFINE ELIG/DISPLAY "Count of Eligible Episodes" style(column)={tagattr='format:#,##0'};
DEFINE MKTSHARE/DISPLAY "% of Market/Share" style(column)={tagattr='format:##0.0%'}; 
DEFINE INDX_FAC_MEAN/DISPLAY "Index Facility Costs Mean" 
style(column)={cellwidth=1.0 in tagattr='format:$#,##0'};
DEFINE INDX_PROF_MEAN/DISPLAY "Index Professional Costs Mean" 
style(column)={cellwidth=1.0 in tagattr='format:$#,##0'};
DEFINE INDX_TOT_MEAN/DISPLAY "Index Total Costs Mean" 
style(column)={cellwidth=1.0 in tagattr='format:$#,##0'};
DEFINE POST_FAC_MEAN/DISPLAY "Post-Index Facility Costs Mean" 
style(column)={cellwidth=1.0 in tagattr='format:$#,##0'};
DEFINE POST_PROF_MEAN/DISPLAY "Post-Index Professional Costs Mean" 
style(column)={cellwidth=1.0 in tagattr='format:$#,##0'};
DEFINE POST_TOT_MEAN/DISPLAY "Post-Index Total Costs Mean" 
style(column)={cellwidth=1.0 in tagattr='format:$#,##0'};
DEFINE TOT_MEAN/DISPLAY "Total Episode Costs Mean" 
style(column)={cellwidth=1.0 in tagattr='format:$#,##0'};
DEFINE BUNDLE_Q1/DISPLAY "Total Episode Costs Lower Quartile" 
style(column)={cellwidth=1.0 in tagattr='format:$#,##0'};
DEFINE BUNDLE_Q3/DISPLAY "Total Episode Costs Upper Quartile" 
style(column)={cellwidth=1.0 in tagattr='format:$#,##0'};
DEFINE TOT_SUM/DISPLAY "Total Episode Costs Sum" 
style(column)={cellwidth=1.0 in tagattr='format:$#,##0'};
DEFINE READMIT_&STATE._PER/DISPLAY "Readmission Rate" 
style(column)={cellwidth=1.0 in tagattr='format:##0.0%'};
DEFINE MORT_PER/DISPLAY "Mortality Rate" 
style(column)={cellwidth=1.0 in tagattr='format:##0.0%'};
RUN;


/*PRODUCT*/
PROC REPORT DATA=PRODUCT HEADLINE CENTER SPLIT="/";
COLUMN PROD ELIG MKTSHARE INDX_FAC_MEAN INDX_PROF_MEAN INDX_TOT_MEAN POST_FAC_MEAN POST_PROF_MEAN 
POST_TOT_MEAN TOT_MEAN BUNDLE_Q1 BUNDLE_Q3 TOT_SUM READMIT_&STATE._PER MORT_PER;
DEFINE PROD/DISPLAY "Product" FORMAT=$PRODUCTF.;
DEFINE ELIG/DISPLAY "Count of Eligible Episodes" style(column)={tagattr='format:#,##0'};
DEFINE MKTSHARE/DISPLAY "% of Market/Share" style(column)={tagattr='format:##0.0%'}; 
DEFINE INDX_FAC_MEAN/DISPLAY "Index Facility Costs Mean" 
style(column)={cellwidth=1.0 in tagattr='format:$#,##0'};
DEFINE INDX_PROF_MEAN/DISPLAY "Index Professional Costs Mean" 
style(column)={cellwidth=1.0 in tagattr='format:$#,##0'};
DEFINE INDX_TOT_MEAN/DISPLAY "Index Total Costs Mean" 
style(column)={cellwidth=1.0 in tagattr='format:$#,##0'};
DEFINE POST_FAC_MEAN/DISPLAY "Post-Index Facility Costs Mean" 
style(column)={cellwidth=1.0 in tagattr='format:$#,##0'};
DEFINE POST_PROF_MEAN/DISPLAY "Post-Index Professional Costs Mean" 
style(column)={cellwidth=1.0 in tagattr='format:$#,##0'};
DEFINE POST_TOT_MEAN/DISPLAY "Post-Index Total Costs Mean" 
style(column)={cellwidth=1.0 in tagattr='format:$#,##0'};
DEFINE TOT_MEAN/DISPLAY "Total Episode Costs Mean" 
style(column)={cellwidth=1.0 in tagattr='format:$#,##0'};
DEFINE BUNDLE_Q1/DISPLAY "Total Episode Costs Lower Quartile" 
style(column)={cellwidth=1.0 in tagattr='format:$#,##0'};
DEFINE BUNDLE_Q3/DISPLAY "Total Episode Costs Upper Quartile" 
style(column)={cellwidth=1.0 in tagattr='format:$#,##0'};
DEFINE TOT_SUM/DISPLAY "Total Episode Costs Sum" 
style(column)={cellwidth=1.0 in tagattr='format:$#,##0'};
DEFINE READMIT_&STATE._PER/DISPLAY "Readmission Rate" 
style(column)={cellwidth=1.0 in tagattr='format:##0.0%'};
DEFINE MORT_PER/DISPLAY "Mortality Rate" 
style(column)={cellwidth=1.0 in tagattr='format:##0.0%'};
RUN;

ods tagsets.excelxp options(sheet_name = 'Market by County' sheet_interval='table');

PROC REPORT DATA=COUNTY_FINAL HEADLINE CENTER SPLIT="/";
COLUMN COUNTY_HOPPA ELIG MKTSHARE INDX_FAC_MEAN INDX_PROF_MEAN INDX_TOT_MEAN POST_FAC_MEAN POST_PROF_MEAN 
POST_TOT_MEAN TOT_MEAN BUNDLE_Q1 BUNDLE_Q3 TOT_SUM READMIT_&STATE._PER MORT_PER;
DEFINE COUNTY_HOPPA/DISPLAY "Facility County" ;
DEFINE ELIG/DISPLAY "Count of Eligible Episodes" style(column)={tagattr='format:#,##0'};
DEFINE MKTSHARE/DISPLAY "% of Market/Share" style(column)={tagattr='format:##0.0%'}; 
DEFINE INDX_FAC_MEAN/DISPLAY "Index Facility Costs Mean" 
style(column)={cellwidth=1.0 in tagattr='format:$#,##0'};
DEFINE INDX_PROF_MEAN/DISPLAY "Index Professional Costs Mean" 
style(column)={cellwidth=1.0 in tagattr='format:$#,##0'};
DEFINE INDX_TOT_MEAN/DISPLAY "Index Total Costs Mean" 
style(column)={cellwidth=1.0 in tagattr='format:$#,##0'};
DEFINE POST_FAC_MEAN/DISPLAY "Post-Index Facility Costs Mean" 
style(column)={cellwidth=1.0 in tagattr='format:$#,##0'};
DEFINE POST_PROF_MEAN/DISPLAY "Post-Index Professional Costs Mean" 
style(column)={cellwidth=1.0 in tagattr='format:$#,##0'};
DEFINE POST_TOT_MEAN/DISPLAY "Post-Index Total Costs Mean" 
style(column)={cellwidth=1.0 in tagattr='format:$#,##0'};
DEFINE TOT_MEAN/DISPLAY "Total Episode Costs Mean" 
style(column)={cellwidth=1.0 in tagattr='format:$#,##0'};
DEFINE BUNDLE_Q1/DISPLAY "Total Episode Costs Lower Quartile" 
style(column)={cellwidth=1.0 in tagattr='format:$#,##0'};
DEFINE BUNDLE_Q3/DISPLAY "Total Episode Costs Upper Quartile" 
style(column)={cellwidth=1.0 in tagattr='format:$#,##0'};
DEFINE TOT_SUM/DISPLAY "Total Episode Costs Sum" 
style(column)={cellwidth=1.0 in tagattr='format:$#,##0'};
DEFINE READMIT_&STATE._PER/DISPLAY "Readmission Rate" 
style(column)={cellwidth=1.0 in tagattr='format:##0.0%'};
DEFINE MORT_PER/DISPLAY "Mortality Rate" 
style(column)={cellwidth=1.0 in tagattr='format:##0.0%'};
RUN;

ods tagsets.excelxp options(sheet_name = 'Market by Facility' sheet_interval='table');

PROC REPORT DATA=FACILITY_FINAL HEADLINE CENTER SPLIT="/";
COLUMN BILLG_TAX_ID_HOPPA FACNAME_HOPPA2 ELIG MKTSHARE INDX_FAC_MEAN INDX_PROF_MEAN INDX_TOT_MEAN POST_FAC_MEAN POST_PROF_MEAN 
POST_TOT_MEAN TOT_MEAN BUNDLE_Q1 BUNDLE_Q3 TOT_SUM READMIT_&STATE._PER MORT_PER;
DEFINE BILLG_TAX_ID_HOPPA/DISPLAY "Facility Tax ID" style(column)={cellwidth=1.0 in tagattr='Format:@'};
DEFINE FACNAME_HOPPA2/DISPLAY "Facility Name" style(column)={cellwidth=1.5 in};
DEFINE ELIG/DISPLAY "Count of Eligible Episodes" style(column)={cellwidth=0.5 in tagattr='format:#,##0'};
DEFINE MKTSHARE/DISPLAY "% of Market/Share" style(column)={tagattr='format:##0.0%'}; 
DEFINE INDX_FAC_MEAN/DISPLAY "Index Facility Costs Mean" 
style(column)={cellwidth=1.0 in tagattr='format:$#,##0'};
DEFINE INDX_PROF_MEAN/DISPLAY "Index Professional Costs Mean" 
style(column)={cellwidth=1.0 in tagattr='format:$#,##0'};
DEFINE INDX_TOT_MEAN/DISPLAY "Index Total Costs Mean" 
style(column)={cellwidth=1.0 in tagattr='format:$#,##0'};
DEFINE POST_FAC_MEAN/DISPLAY "Post-Index Facility Costs Mean" 
style(column)={cellwidth=1.0 in tagattr='format:$#,##0'};
DEFINE POST_PROF_MEAN/DISPLAY "Post-Index Professional Costs Mean" 
style(column)={cellwidth=1.0 in tagattr='format:$#,##0'};
DEFINE POST_TOT_MEAN/DISPLAY "Post-Index Total Costs Mean" 
style(column)={cellwidth=1.0 in tagattr='format:$#,##0'};
DEFINE TOT_MEAN/DISPLAY "Total Episode Costs Mean" 
style(column)={cellwidth=1.0 in tagattr='format:$#,##0'};
DEFINE BUNDLE_Q1/DISPLAY "Total Episode Costs Lower Quartile" 
style(column)={cellwidth=1.0 in tagattr='format:$#,##0'};
DEFINE BUNDLE_Q3/DISPLAY "Total Episode Costs Upper Quartile" 
style(column)={cellwidth=1.0 in tagattr='format:$#,##0'};
DEFINE TOT_SUM/DISPLAY "Total Episode Costs Sum" 
style(column)={cellwidth=1.0 in tagattr='format:$#,##0'};
DEFINE READMIT_&STATE._PER/DISPLAY "Readmission Rate" 
style(column)={cellwidth=1.0 in tagattr='format:##0.0%'};
DEFINE MORT_PER/DISPLAY "Mortality Rate" 
style(column)={cellwidth=1.0 in tagattr='format:##0.0%'};
RUN;

ods tagsets.excelxp options(sheet_name = 'Market by Physician Group' sheet_interval='table');

PROC REPORT DATA=PHYSGROUP_FINAL HEADLINE CENTER SPLIT="/";
COLUMN SURGEON_TIN ELIG MKTSHARE INDX_FAC_MEAN INDX_PROF_MEAN INDX_TOT_MEAN POST_FAC_MEAN POST_PROF_MEAN 
POST_TOT_MEAN TOT_MEAN BUNDLE_Q1 BUNDLE_Q3 TOT_SUM READMIT_&STATE._PER MORT_PER;

DEFINE SURGEON_TIN/DISPLAY "Physician Group Tax ID" style(column)={cellwidth=1.0 in tagattr='Format:@'};
DEFINE ELIG/DISPLAY "Count of Eligible Episodes" style(column)={cellwidth=0.5 in tagattr='format:#,##0'};
DEFINE MKTSHARE/DISPLAY "% of Market/Share" style(column)={tagattr='format:##0.0%'}; 
DEFINE INDX_FAC_MEAN/DISPLAY "Index Facility Costs Mean" 
style(column)={cellwidth=1.0 in tagattr='format:$#,##0'};
DEFINE INDX_PROF_MEAN/DISPLAY "Index Professional Costs Mean" 
style(column)={cellwidth=1.0 in tagattr='format:$#,##0'};
DEFINE INDX_TOT_MEAN/DISPLAY "Index Total Costs Mean" 
style(column)={cellwidth=1.0 in tagattr='format:$#,##0'};
DEFINE POST_FAC_MEAN/DISPLAY "Post-Index Facility Costs Mean" 
style(column)={cellwidth=1.0 in tagattr='format:$#,##0'};
DEFINE POST_PROF_MEAN/DISPLAY "Post-Index Professional Costs Mean" 
style(column)={cellwidth=1.0 in tagattr='format:$#,##0'};
DEFINE POST_TOT_MEAN/DISPLAY "Post-Index Total Costs Mean" 
style(column)={cellwidth=1.0 in tagattr='format:$#,##0'};
DEFINE TOT_MEAN/DISPLAY "Total Episode Costs Mean" 
style(column)={cellwidth=1.0 in tagattr='format:$#,##0'};
DEFINE BUNDLE_Q1/DISPLAY "Total Episode Costs Lower Quartile" 
style(column)={cellwidth=1.0 in tagattr='format:$#,##0'};
DEFINE BUNDLE_Q3/DISPLAY "Total Episode Costs Upper Quartile" 
style(column)={cellwidth=1.0 in tagattr='format:$#,##0'};
DEFINE TOT_SUM/DISPLAY "Total Episode Costs Sum" 
style(column)={cellwidth=1.0 in tagattr='format:$#,##0'};
DEFINE READMIT_&STATE._PER/DISPLAY "Readmission Rate" 
style(column)={cellwidth=1.0 in tagattr='format:##0.0%'};
DEFINE MORT_PER/DISPLAY "Mortality Rate" 
style(column)={cellwidth=1.0 in tagattr='format:##0.0%'};
RUN;

ODS tagsets.excelxp close;
