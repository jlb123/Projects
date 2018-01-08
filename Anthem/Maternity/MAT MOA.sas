*MAT MOA*;

/**NOTE: IF YOU NEED TO RERUN THE CODE ABOVE RUN THE PROC DATASETS LINE BELOW TO CLEAR ALL TEMPORARY DATASETS SO OLD DATASETS DONT GET APPENDED TO NEW DATASETS*; */
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

%LET STARTDATE=1015;
%LET ENDDATE=0916;
%LET BUNDLE=MAT;
%LET RELEASE=R10;
%LET STATE=CO;
%LET FACIDVAR=BILLG_TAX_ID_HOPPA;
%LET FILEPATH=/ephc/ebp/nobackup/users/blase/;
*------------------------------------------------------------------------------------------------------------------*;

%LET DATASET=&STATE._&BUNDLE._&STARTDATE._&ENDDATE._&RELEASE;
libname &BUNDLE._LIB "/ephc/ebp/backup/data/phi/%LOWCASE(&BUNDLE)/%LOWCASE(&STATE)";


PROC FORMAT;

VALUE $WF "INITIAL_EPISODES"="Initial Bundle Services Identified"
		    "ANTHEM_EXCLUDE"="Anthem is not Primary"
			"AGE_EXCLUDE"="Age < 13"
			"ENROLL_EXCLUDE"="Not continuously enrolled"
			"PRODUCT_EXCLUDE"="Enrolled in ineligible Product (i.e. hospital only, capitated)"
			"MBR_TOT_EXCLUDE"="SUBTOTAL Member Eligibility Exclusions"
			"CLIN_HIST_EXCLUDE"="Clinical diagnosis criteria (e.g., multiples 3+)"
			"CLIN_TOT_EXCLUDE"="SUBTOTAL Clinical Program Exclusions"
			"MCARE_EXCLUDE"="Medicare"
			"MCAID_EXCLUDE"="Medicaid"
			"PGM_TOT_EXCLUDE"="TOTAL Member Program Participation Eligibility Exclusions "
			"ELIG_EPISODES"="TOTAL Program Eligible Episodes"
			"MEM_EXCL_HEADING"="Member Eligibility Exclusions" 
			"CLIN_EXCL_HEADING"="Clinical Program Exclusions"
			"PGM_EXCL_HEADING"="LOB Program Exclusions"
			"NOPRENAT_EXCLUDE"="Limited / No Prenatal Care"
			"TOT_EPS_EXCLUDE"="TOTAL Episodes Excluded"
			"PRETERM_EXCLUDE"="Pre-term delivery";

VALUE $ SRVC "IP Hosp"="Inpatient Hospital"
		   "OP Hosp"="Outpatient Hospital"
		   "ASC"="Ambulatory Surgical Center"
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

VALUE $FUNDF 'ALTERNATE FUNDED'='ASO'
			 'INSURED'='FI';

VALUE $FUND2F 'ALTERNATE FUNDED'='ALTERNATE FUNDED (ASO)'
			 'INSURED'='FULLY INSURED (FI)';

VALUE CSECTF 0="VAGINAL DELIVERY"
			 1="C-SECTION";

VALUE GRAPHVAR 1="<$10,000"
			   2="$10,000-$14,999"
			   3="$15,000-$19,999"
			   4="$20,000-$24,999"
			   5="$25,000+";
RUN;

 *GENERATING COUNTS FOR WATERFALL*;
PROC SQL;
CREATE TABLE &BUNDLE._WATERFALL AS
SELECT
/* GENERATE TOPLINE -- Initial Episodes */
SUM (IND_FLG=1 AND DRG_FLG=1 AND LOB_LVL_FLG ne 9) AS INITIAL_EPISODES,
/* MEMBER Program Participation Exclusions */
SUM(IND_FLG=1 AND DRG_FLG=1 AND LOB_LVL_FLG ne 9 AND WP_PRIMARY=1) AS ANTHEM_EXCLUDE,
SUM(IND_FLG=1 AND DRG_FLG=1 AND LOB_LVL_FLG ne 9 AND WP_PRIMARY=0 AND AGE_FLG=0) AS AGE_EXCLUDE,
SUM(IND_FLG=1 AND DRG_FLG=1 AND LOB_LVL_FLG ne 9 AND WP_PRIMARY=0 AND AGE_FLG=1 AND (ENRL_FLG=0 AND
(preindex_tot_cost_PCR < 2000 OR index_tot_cost_PCR < 4000))) AS ENROLL_EXCLUDE,
SUM(IND_FLG=1 AND DRG_FLG=1 AND LOB_LVL_FLG ne 9 AND WP_PRIMARY=0 AND AGE_FLG=1 AND (enrl_flg=1 OR
(preindex_tot_cost_PCR >= 2000 AND index_tot_cost_PCR >= 4000)) AND (HOSP_ONLY_FLG=1 OR CAP_FLG=1)) AS 
PRODUCT_EXCLUDE,

/** MEMBER SUBTOTAL **/
SUM(CALCULATED ANTHEM_EXCLUDE, CALCULATED AGE_EXCLUDE, CALCULATED ENROLL_EXCLUDE, CALCULATED PRODUCT_EXCLUDE) 
AS MBR_TOT_EXCLUDE,

/* CLINICAL Program Exclusions */
SUM(IND_FLG=1 AND DRG_FLG=1 AND LOB_LVL_FLG ne 9 AND WP_PRIMARY=0 AND AGE_FLG=1 AND (enrl_flg=1 OR
(preindex_tot_cost_PCR >= 2000 AND index_tot_cost_PCR >= 4000)) AND hosp_only_flg=0
AND CAP_FLG in (0,2) AND pre_ex_flg=1) AS CLIN_HIST_EXCLUDE, /*JENNY - MAKE SURE CORRECT*/
/*LIMITED PRENATAL CARE*/
SUM(IND_FLG=1 AND DRG_FLG=1 AND LOB_LVL_FLG ne 9 AND WP_PRIMARY=0 AND AGE_FLG=1 AND (enrl_flg=1 OR
(preindex_tot_cost_PCR >= 2000 AND index_tot_cost_PCR >= 4000)) AND hosp_only_flg=0
AND CAP_FLG in (0,2) AND pre_ex_flg=0 AND ltd_prenat_flg=0) AS NOPRENAT_EXCLUDE,	
/*PRE-TERM BIRTH*/
SUM(IND_FLG=1 AND DRG_FLG=1 AND LOB_LVL_FLG ne 9 AND WP_PRIMARY=0 AND AGE_FLG=1 AND (enrl_flg=1 OR
(preindex_tot_cost_PCR >= 2000 AND index_tot_cost_PCR >= 4000)) AND hosp_only_flg=0
AND CAP_FLG in (0,2) AND pre_ex_flg=0 AND ltd_prenat_flg=1 AND preemie_flg=1) AS PRETERM_EXCLUDE,
/*CLINICAL SUBTOTAL*/
SUM(CALCULATED CLIN_HIST_EXCLUDE, CALCULATED NOPRENAT_EXCLUDE, CALCULATED PRETERM_EXCLUDE) AS CLIN_TOT_EXCLUDE,

/* PROGRAM Participation Exclusions */
/*MEDICARE EXCLUSION*/
SUM(IND_FLG=1 AND DRG_FLG=1 AND LOB_LVL_FLG ne 9 AND WP_PRIMARY=0 AND AGE_FLG=1 AND (enrl_flg=1 OR
(preindex_tot_cost_PCR >= 2000 AND index_tot_cost_PCR >= 4000)) AND hosp_only_flg=0
AND CAP_FLG in (0,2) AND pre_ex_flg=0 AND ltd_prenat_flg=1 AND preemie_flg=0 AND (LOB_LVL_FLG in (5,6,7))) 
AS MCARE_EXCLUDE,
/*MEDICAID EXCLUSION*/
SUM(IND_FLG=1 AND DRG_FLG=1 AND LOB_LVL_FLG ne 9 AND WP_PRIMARY=0 AND AGE_FLG=1 AND (enrl_flg=1 OR
(preindex_tot_cost_PCR >= 2000 AND index_tot_cost_PCR >= 4000)) AND hosp_only_flg=0
AND CAP_FLG in (0,2) AND pre_ex_flg=0 AND ltd_prenat_flg=1 AND preemie_flg=0 AND LOB_LVL_FLG NOT in (5,6,7) 
AND LOB_LVL_FLG=8) 
AS MCAID_EXCLUDE,

/*PROGRAM SUBTOTAL*/
SUM(CALCULATED MCARE_EXCLUDE, CALCULATED MCAID_EXCLUDE) AS PGM_TOT_EXCLUDE,

/*TOTAL EPISODES EXCLUDED*/
SUM(CALCULATED MBR_TOT_EXCLUDE, CALCULATED CLIN_TOT_EXCLUDE, CALCULATED 
PGM_TOT_EXCLUDE) AS TOT_EPS_EXCLUDE,

/* TOTAL Program Eligible Episode Bundles */

CALCULATED INITIAL_EPISODES- CALCULATED TOT_EPS_EXCLUDE AS ELIG_EPISODES

FROM &BUNDLE._LIB.&DATASET;

QUIT;

DATA WF_TAB1;
SET &BUNDLE._WATERFALL;

*ADDING VARIABLES FOR LINES WITH ONLY HEADINGS IN REPORT*;
MEM_EXCL_HEADING=" ";
CLIN_EXCL_HEADING=" ";
PGM_EXCL_HEADING=" ";

RUN;

%*THIS TABLE WILL BE OUTPUT*;
PROC TRANSPOSE DATA=WF_TAB1 OUT=WF_TAB2 NAME=VAR1; 
VAR INITIAL_EPISODES
MEM_EXCL_HEADING 
ANTHEM_EXCLUDE 
AGE_EXCLUDE  
ENROLL_EXCLUDE 
PRODUCT_EXCLUDE 
MBR_TOT_EXCLUDE 
CLIN_EXCL_HEADING
CLIN_HIST_EXCLUDE 
NOPRENAT_EXCLUDE 
PRETERM_EXCLUDE
CLIN_TOT_EXCLUDE 
PGM_EXCL_HEADING
MCARE_EXCLUDE 
MCAID_EXCLUDE 
PGM_TOT_EXCLUDE
TOT_EPS_EXCLUDE 
ELIG_EPISODES; 
RUN;


DATA ELIGIBLE_&STATE;
SET &BUNDLE._LIB.&DATASET;
LENGTH PLAN $ 40. SRVC $ 20.;

/*** VALID MATS -- Commercial - EXCLUSION CASCADE   ***/
if 
DRG_flg=1 AND     /* Topline flag -- exclude extraneus DRGs  */
ind_flg=1 AND /* Topline flag  --  index trigger occurred within designated index period  */
pre_ex_flg=0 AND  /* clinical historial prior to admission or present at admission */
ltd_prenat_flg=1 AND /* limited or not prenatal care exclusion */
preemie_flg=0 AND /* premature delivery exclusion */
/* dx_flg=1 AND */         /* Dx inclusion criteria */
lob_lvl_flg in (1,2,3,4) AND /* Program Participation Exclusions of  */                         
                           /*Medicare and Medicaid */
(enrl_flg=1 OR
(preindex_tot_cost_PCR >= 2000 AND index_tot_cost_PCR >= 4000)) AND
/*lob_flg=1 AND */ /* continuous enrollment exclusion */
age_flg=1 AND /* age exclusion <13 at episode start */
/*gndr_flg=1 AND */ /* gender exclusion */
WP_Primary=0 AND /* Anthem primary exclusion */
hosp_only_flg=0 AND /* PRODUCT exclusion criteria */
cap_flg in (0,2)  /* PRODUCT exclusion criteria */
;

*CONVERTING PLACE OF SERVICE VARIABLE*;
*ER (indx_PLACE_OF_SRVC_CD='23') CLASSIFIED AS OP PER SS IN EMAIL ON 3/15/16*;
IF indx_PLACE_OF_SRVC_CD='21' THEN SRVC="IP Hosp";
ELSE IF indx_PLACE_OF_SRVC_CD IN ('22','23') THEN SRVC="OP Hosp";
ELSE IF indx_PLACE_OF_SRVC_CD IN ('25') THEN SRVC="Birthing Center";

*PLAN*;
IF  PROD_LVL_4_DESC='MEDICARE ADVANTAGE' then PLAN='MEDICARE ADVANTAGE';              
ELSE IF PROD_LVL_4_DESC='MEDICARE SUPPLEMENT' then PLAN='MEDICARE SUPPLEMENT';          
ELSE IF MBU_GL_LVL_4_DESC='MEDICARE PROGRAMS' then PLAN=UPCASE('Medicare Other');                                  
ELSE IF (MBU_GL_LVL_4_DESC='COMMERCIAL BUSINESS' and MBU_LVL_1_DESC ='INDIVIDUAL') then 
	PLAN=UPCASE('Commercial Individual');   
ELSE IF (MBU_GL_LVL_4_DESC='COMMERCIAL BUSINESS' and MBU_LVL_1_DESC='LOCAL GROUP') then 
	PLAN=UPCASE('Commercial Local');  
ELSE IF (MBU_LVL_1_DESC='NATIONAL GROUP' and MBU_LVL_2_DESC='BLUE CARD/NASCO PAR') then 
	PLAN=UPCASE('Commercial National Host'); 
ELSE IF (MBU_LVL_1_DESC='NATIONAL GROUP' and MBU_LVL_2_DESC='HOME') then PLAN=UPCASE('Commercial National Home');    
ELSE IF (MBU_GL_LVL_4_DESC='COMMERCIAL BUSINESS' and  MBU_LVL_1_DESC='NATIONAL GROUP') then 
	PLAN=UPCASE('Commercial National');  
ELSE IF MBU_GL_LVL_4_DESC='COMMERCIAL BUSINESS' then PLAN='Commercial Other';     
else PLAN=UPCASE('Other'); 

FACNAME_HOPPA2=UPCASE(FACNAME_HOPPA);
IF &FACIDVAR="UNK" THEN FACNAME_HOPPA2=" ";

SURGEON_NAME2=UPCASE(SURGEON_NAME);
IF SURGEON_NPI="UNK" THEN SURGEON_NAME2=" ";

PHYS_GRP_NAME2=PHYS_GRP_NAME;
IF SURGEON_TIN="UNK" OR PHYS_GRP_NAME="UNK" THEN PHYS_GRP_NAME2=" ";

IF PROD_LVL_2_DESC IN ('PPO','OTHER','FFS') THEN PROD='PPO';
ELSE IF PROD_LVL_2_DESC=' ' THEN PROD='UNK';
ELSE PROD='HMO';

RUN;

*EXTRACTING INDIVIDUAL SURGEONS - USING MOST FREQUENT SURGEON NAME PER NPI*;
PROC SQL;
CREATE TABLE TAB_SURG AS 
SELECT SURGEON_NPI, SURGEON_NAME2,
COUNT(*) AS SURG_FREQ
FROM ELIGIBLE_&STATE
GROUP BY SURGEON_NPI,SURGEON_NAME2
ORDER BY SURGEON_NPI, CALCULATED SURG_FREQ DESC, SURGEON_NAME2;
QUIT;

DATA TAB_1ST_SURG;
SET TAB_SURG;
*ONLY TAKING THE FIRST NAME/NPI COMBO IF THE SURGEON NAME/NPI IS MISSING*;
/*IF SURGEON_NPI NE ' ' THEN DO;*/
	BY SURGEON_NPI;
	IF FIRST.SURGEON_NPI;
/*IF SURGEON_NPI="UNK" THEN SURGEON_NAME2=" ";*/
/*END;*/

RUN;

*EXTRACTING INDIVIDUAL PHYSICIAN GROUP - USING MOST FREQUENT PHYSICIAN GROUP NAME*;
PROC SQL;
CREATE TABLE TAB_PG AS 
SELECT SURGEON_TIN, PHYS_GRP_NAME2,
COUNT(*) AS PG_FREQ
FROM ELIGIBLE_&STATE
GROUP BY SURGEON_TIN, PHYS_GRP_NAME2
ORDER BY SURGEON_TIN, CALCULATED PG_FREQ DESC, PHYS_GRP_NAME2;
QUIT;

DATA TAB_1ST_PG;
SET TAB_PG;
	BY SURGEON_TIN;
	IF FIRST.SURGEON_TIN;

/*IF SURGEON_TIN="UNK" THEN PHYS_GRP_NAME=" ";*/
RUN;

*EXTRACTING INDIVIDUAL FACILITIES - USING MOST FREQUENT FACILITY NAME*;
PROC SQL;
CREATE TABLE TAB_FAC AS 
SELECT &FACIDVAR, FACNAME_HOPPA2,
COUNT(*) AS FAC_FREQ
FROM ELIGIBLE_&STATE
GROUP BY &FACIDVAR, FACNAME_HOPPA2
ORDER BY &FACIDVAR, CALCULATED FAC_FREQ DESC, FACNAME_HOPPA2;
QUIT;

DATA TAB_1ST_FAC;
SET TAB_FAC;
	BY &FACIDVAR;
	IF FIRST.&FACIDVAR;
/*IF &FACIDVAR="UNK" THEN FACNAME_HOPPA2=" ";*/
RUN;

*REMERGING DATASET WITH NAME CORRECTIONS FOR PHYSICIAN, FACILITY AND PHYSICIAN GROUP. DATASET ONLY CONTAINS ELIGIBLE
CASES*;
PROC SQL;
CREATE TABLE NEW_&BUNDLE AS 
SELECT A.*,B.SURGEON_NAME2, C.PHYS_GRP_NAME2, D.FACNAME_HOPPA2
FROM ELIGIBLE_&STATE (DROP=SURGEON_NAME2 PHYS_GRP_NAME2 FACNAME_HOPPA2) A
LEFT JOIN TAB_1ST_SURG B
ON A.SURGEON_NPI=B.SURGEON_NPI
LEFT JOIN TAB_1ST_PG C 
ON A.SURGEON_TIN=C.SURGEON_TIN
LEFT JOIN TAB_1ST_FAC D
ON A.&FACIDVAR=D.&FACIDVAR;
QUIT;
 
*DATASET DENOMINATOR*;
PROC SQL;
SELECT DISTINCT 
COUNT(*)
INTO :N_ELIGIBLE_&BUNDLE 
FROM NEW_&BUNDLE;
QUIT;

*PREMATURE DELIVERY PERCENTAGES*;

PROC SQL;
CREATE TABLE PREMAT_ORIG AS
SELECT *,
CASE
WHEN indx_PLACE_OF_SRVC_CD='21' THEN "IP Hosp"
WHEN indx_PLACE_OF_SRVC_CD IN ('22','23') THEN "OP Hosp"
WHEN indx_PLACE_OF_SRVC_CD IN ('25') THEN "Birthing Center"
END AS SRVC LENGTH=20,
CASE
WHEN PROD_LVL_2_DESC IN ('PPO','OTHER','FFS') THEN 'PPO'
WHEN PROD_LVL_2_DESC=' ' THEN 'UNK'
ELSE 'HMO'
END AS PROD

FROM &BUNDLE._LIB.&DATASET
WHERE DRG_flg=1 AND     /* Topline flag -- exclude extraneus DRGs  */
ind_flg=1 AND /* Topline flag  --  index trigger occurred within designated index period  */
pre_ex_flg=0 AND  /* clinical historial prior to admission or present at admission */
ltd_prenat_flg=1 AND /* limited or not prenatal care exclusion */
/* dx_flg=1 AND */         /* Dx inclusion criteria */
lob_lvl_flg in (1,2,3,4) AND /* Program Participation Exclusions of  */                         
                           /*Medicare and Medicaid */
(enrl_flg=1 OR
(preindex_tot_cost_PCR >= 2000 AND index_tot_cost_PCR >= 4000)) AND
/*lob_flg=1 AND */ /* continuous enrollment exclusion */
age_flg=1 AND /* age exclusion <13 at episode start */
/*gndr_flg=1 AND */ /* gender exclusion */
WP_Primary=0 AND /* Anthem primary exclusion */
hosp_only_flg=0 AND /* PRODUCT exclusion criteria */
cap_flg in (0,2)/* PRODUCT exclusion criteria */
;
QUIT;


/*MARKET SUMMARY TAB*/
%MACRO SUMMARY_TAB;

*STRATIFYING BY PLACE OF SERVICE, LOB, PLAN, PRODUCT, FUNDING;
%LET VARLIST=SRVC PROD FUNDG_TYPE_LVL_1_DESC;
%LET NAMELIST=SITESERV PRODUCT FUNDING;

%DO B=1 %TO 3;
	%LET STRATVAR=%SCAN(&VARLIST, &B, %STR( ));
	%LET NAMEVAR=%SCAN(&NAMELIST, &B, %STR( ));
	
PROC SQL;
CREATE TABLE &NAMEVAR._1 AS 
SELECT &STRATVAR,
COUNT(*) AS ELIG,
CALCULATED ELIG/&&N_ELIGIBLE_&BUNDLE AS MKTSHARE,
SUM(er_pre_flg)/CALCULATED ELIG AS ER_PER,
SUM(CSECTION_FLG)/CALCULATED ELIG AS CSECTION_PER,
SUM(ultrsnd_flg GE 3)/CALCULATED ELIG AS US_PER,
SUM(vbac_flg)/CALCULATED ELIG AS VBAC_PER,
MEAN(preindex_fac_cost_PCR) AS PRE_FAC_MEAN,
MEAN(preindex_prof_cost_PCR) AS PRE_PROF_MEAN,
MEAN(preindex_tot_cost_PCR) AS PRE_TOT_MEAN,
MEAN(index_fac_cost_PCR) AS INDX_FAC_MEAN,
MEAN(index_prof_cost_PCR) AS INDX_PROF_MEAN,
MEAN(index_tot_cost_PCR) AS INDX_TOT_MEAN,
MEAN(postindex_fac_cost_PCR) AS POST_FAC_MEAN,
MEAN(postindex_prof_cost_PCR) AS POST_PROF_MEAN,
MEAN(postindex_tot_cost_PCR) AS POST_TOT_MEAN,
MEAN(bundlecost_tot_PCR) AS BUNDLEMEAN,
SUM(bundlecost_tot_PCR) AS BUNDLE_SUM
FROM NEW_&BUNDLE
GROUP BY &STRATVAR
ORDER BY ELIG DESC;

CREATE TABLE PREMAT_&NAMEVAR AS
SELECT &STRATVAR,
SUM(PREEMIE_FLG)/COUNT(*) AS PREMAT_PER
FROM PREMAT_ORIG
GROUP BY &STRATVAR;

QUIT;

PROC SORT DATA=NEW_&BUNDLE; BY &STRATVAR; RUN;

proc means data=NEW_&BUNDLE n Q1 Q3 QRANGE maxdec=0; 
var bundlecost_tot_PCR;
OUTPUT OUT=&NAMEVAR._2 Q1=BUNDLE_Q1 Q3=BUNDLE_Q3 QRANGE=BUNDLE_IQR;
BY &STRATVAR; 
RUN;

PROC SQL;
CREATE TABLE &NAMEVAR AS
SELECT A.*, B.BUNDLE_Q1, B.BUNDLE_Q3, B.BUNDLE_IQR, C.PREMAT_PER
FROM &NAMEVAR._1 A, &NAMEVAR._2 B, PREMAT_&NAMEVAR C
WHERE A.&STRATVAR=B.&STRATVAR=C.&STRATVAR;
QUIT;

%END;

%MEND SUMMARY_TAB;
%SUMMARY_TAB;


*TABLE BY DELIVERY, LINE OF BUSINESS, PLAN, PRODUCT, FUNDING ARRANGEMENT, # ELIGIBLE EPISODES, PERCENT
OF MARKET SHARE, AND COST AND QUALITY METRICS NUMBERS. ORDER BY ELIGIBLE EPISODES. NOT STRATIFIED BY SITE OF SERVICE*;

/*PROC SORT DATA=NEW_&BUNDLE; BY CSECTION_FLG MBU_GL_LVL_4_DESC PLAN PROD_LVL_2_DESC FUNDG_TYPE_LVL_1_DESC; RUN;*/
/**/
/*proc means data=NEW_&BUNDLE n Q1 Q3 maxdec=0; */
/*var bundlecost_tot_PCR;*/
/*OUTPUT OUT=TAB_ALL_QUARTS Q1=BUNDLE_Q1 Q3=BUNDLE_Q3;*/
/*BY CSECTION_FLG MBU_GL_LVL_4_DESC PLAN PROD_LVL_2_DESC FUNDG_TYPE_LVL_1_DESC; */
/*RUN;*/
/**/
/*PROC SQL;*/
/*CREATE TABLE TAB_ALL AS*/
/*SELECT CSECTION_FLG, MBU_GL_LVL_4_DESC, PLAN, PROD_LVL_2_DESC, FUNDG_TYPE_LVL_1_DESC, */
/*COUNT(*) AS ELIG,*/
/*CALCULATED ELIG/&&N_ELIGIBLE_&BUNDLE AS MKTSHARE,*/
/*MEDIAN(bundlecost_tot_PCR) AS BUNDLEMED,*/
/*MEAN(bundlecost_tot_PCR) AS BUNDLEMEAN,*/
/*STD(bundlecost_tot_PCR) AS BUNDLESTD,*/
/*SUM(comp_pst_flg)/CALCULATED ELIG AS COMPL_PER,*/
/*SUM(READMISSION)/CALCULATED ELIG AS READMIT_PER*/
/*FROM NEW_&BUNDLE*/
/*GROUP BY CSECTION_FLG, MBU_GL_LVL_4_DESC, PLAN, PROD_LVL_2_DESC, FUNDG_TYPE_LVL_1_DESC;*/
/**/
/*CREATE TABLE TAB_ALL_FINAL AS*/
/*SELECT A.*, B.BUNDLE_Q1, BUNDLE_Q3*/
/*FROM TAB_ALL A, TAB_ALL_QUARTS B*/
/*WHERE A.CSECTION_FLG=B.CSECTION_FLG AND A.MBU_GL_LVL_4_DESC=B.MBU_GL_LVL_4_DESC AND A.PLAN=B.PLAN AND*/
/*A.PROD_LVL_2_DESC=B.PROD_LVL_2_DESC AND A.FUNDG_TYPE_LVL_1_DESC=B.FUNDG_TYPE_LVL_1_DESC*/
/*ORDER BY ELIG DESC;*/
/*QUIT;*/


*MARKET BY COUNTY TAB*;

PROC SORT DATA=NEW_&BUNDLE; BY COUNTY_HOPPA; RUN;

proc means data=NEW_&BUNDLE n Q1 Q3 maxdec=0 QRANGE; 
var bundlecost_tot_PCR;
OUTPUT OUT=COUNTY_2 Q1=BUNDLE_Q1 Q3=BUNDLE_Q3 QRANGE=BUNDLE_IQR;
BY COUNTY_HOPPA; 
RUN;


PROC SQL;
CREATE TABLE COUNTY_1 AS 
SELECT COUNTY_HOPPA,
COUNT(*) AS ELIG,
CALCULATED ELIG/&&N_ELIGIBLE_&BUNDLE AS MKTSHARE,
SUM(er_pre_flg)/CALCULATED ELIG AS ER_PER,
SUM(CSECTION_FLG)/CALCULATED ELIG AS CSECTION_PER,
SUM(ultrsnd_flg GE 3)/CALCULATED ELIG AS US_PER,
SUM(vbac_flg)/CALCULATED ELIG AS VBAC_PER,
MEAN(preindex_fac_cost_PCR) AS PRE_FAC_MEAN,
MEAN(preindex_prof_cost_PCR) AS PRE_PROF_MEAN,
MEAN(preindex_tot_cost_PCR) AS PRE_TOT_MEAN,
MEAN(index_fac_cost_PCR) AS INDX_FAC_MEAN,
MEAN(index_prof_cost_PCR) AS INDX_PROF_MEAN,
MEAN(index_tot_cost_PCR) AS INDX_TOT_MEAN,
MEAN(postindex_fac_cost_PCR) AS POST_FAC_MEAN,
MEAN(postindex_prof_cost_PCR) AS POST_PROF_MEAN,
MEAN(postindex_tot_cost_PCR) AS POST_TOT_MEAN,
MEAN(bundlecost_tot_PCR) AS BUNDLEMEAN,
SUM(bundlecost_tot_PCR) AS BUNDLE_SUM
FROM NEW_&BUNDLE
GROUP BY COUNTY_HOPPA;

CREATE TABLE PREMAT_COUNTY AS
SELECT COUNTY_HOPPA,
SUM(PREEMIE_FLG)/COUNT(*) AS PREMAT_PER
FROM PREMAT_ORIG
GROUP BY COUNTY_HOPPA;

CREATE TABLE COUNTY AS
SELECT A.*, B.BUNDLE_Q1, B.BUNDLE_Q3, B.BUNDLE_IQR, C.PREMAT_PER
FROM COUNTY_1 A, COUNTY_2 B, PREMAT_COUNTY C
WHERE A.COUNTY_HOPPA=B.COUNTY_HOPPA=C.COUNTY_HOPPA 
ORDER BY ELIG DESC, COUNTY_HOPPA;


QUIT;

/*MARKET BY FACILITY TAB*/
PROC SORT DATA=NEW_&BUNDLE; BY &FACIDVAR FACNAME_HOPPA2; RUN;

proc means data=NEW_&BUNDLE n Q1 Q3 maxdec=0 QRANGE; 
var bundlecost_tot_PCR;
OUTPUT OUT=FACILITY_2 Q1=BUNDLE_Q1 Q3=BUNDLE_Q3 QRANGE=BUNDLE_IQR;
BY &FACIDVAR FACNAME_HOPPA2; 
RUN;

PROC SQL;
CREATE TABLE FACILITY_1 AS 
SELECT DISTINCT &FACIDVAR, FACNAME_HOPPA2,
COUNT(*) AS ELIG,
CALCULATED ELIG/&&N_ELIGIBLE_&BUNDLE AS MKTSHARE,
SUM(er_pre_flg)/CALCULATED ELIG AS ER_PER,
SUM(CSECTION_FLG)/CALCULATED ELIG AS CSECTION_PER,
SUM(ultrsnd_flg GE 3)/CALCULATED ELIG AS US_PER,
SUM(vbac_flg)/CALCULATED ELIG AS VBAC_PER,
MEAN(preindex_fac_cost_PCR) AS PRE_FAC_MEAN,
MEAN(preindex_prof_cost_PCR) AS PRE_PROF_MEAN,
MEAN(preindex_tot_cost_PCR) AS PRE_TOT_MEAN,
MEAN(index_fac_cost_PCR) AS INDX_FAC_MEAN,
MEAN(index_prof_cost_PCR) AS INDX_PROF_MEAN,
MEAN(index_tot_cost_PCR) AS INDX_TOT_MEAN,
MEAN(postindex_fac_cost_PCR) AS POST_FAC_MEAN,
MEAN(postindex_prof_cost_PCR) AS POST_PROF_MEAN,
MEAN(postindex_tot_cost_PCR) AS POST_TOT_MEAN,
MEAN(bundlecost_tot_PCR) AS BUNDLEMEAN,
SUM(bundlecost_tot_PCR) AS BUNDLE_SUM
FROM NEW_&BUNDLE
GROUP BY &FACIDVAR
ORDER BY ELIG DESC, &FACIDVAR;

CREATE TABLE PREMAT_FACILITY AS
SELECT &FACIDVAR,
SUM(PREEMIE_FLG)/COUNT(*) AS PREMAT_PER
FROM PREMAT_ORIG
GROUP BY &FACIDVAR;

CREATE TABLE FACILITY AS
SELECT A.*, B.BUNDLE_Q1, B.BUNDLE_Q3, B.BUNDLE_IQR, C.PREMAT_PER
FROM FACILITY_1 A, FACILITY_2 B, PREMAT_FACILITY C
WHERE A.&FACIDVAR=B.&FACIDVAR=C.&FACIDVAR 
ORDER BY ELIG DESC, &FACIDVAR;

QUIT;

/*MARKET BY PHYSICIAN TAB*/

PROC SORT DATA=NEW_&BUNDLE; BY SURGEON_NPI; RUN;

proc means data=NEW_&BUNDLE n Q1 Q3 maxdec=0 QRANGE; 
var bundlecost_tot_PCR;
OUTPUT OUT=SURGEON_2 Q1=BUNDLE_Q1 Q3=BUNDLE_Q3 QRANGE=BUNDLE_IQR;
BY SURGEON_NPI; 
RUN;


PROC SQL;
CREATE TABLE SURGEON_1 AS 
SELECT DISTINCT SURGEON_NPI, SURGEON_NAME2, 
COUNT(*) AS ELIG,
CALCULATED ELIG/&&N_ELIGIBLE_&BUNDLE AS MKTSHARE,
SUM(er_pre_flg)/CALCULATED ELIG AS ER_PER,
SUM(CSECTION_FLG)/CALCULATED ELIG AS CSECTION_PER,
SUM(ultrsnd_flg GE 3)/CALCULATED ELIG AS US_PER,
SUM(vbac_flg)/CALCULATED ELIG AS VBAC_PER,
MEAN(preindex_fac_cost_PCR) AS PRE_FAC_MEAN,
MEAN(preindex_prof_cost_PCR) AS PRE_PROF_MEAN,
MEAN(preindex_tot_cost_PCR) AS PRE_TOT_MEAN,
MEAN(index_fac_cost_PCR) AS INDX_FAC_MEAN,
MEAN(index_prof_cost_PCR) AS INDX_PROF_MEAN,
MEAN(index_tot_cost_PCR) AS INDX_TOT_MEAN,
MEAN(postindex_fac_cost_PCR) AS POST_FAC_MEAN,
MEAN(postindex_prof_cost_PCR) AS POST_PROF_MEAN,
MEAN(postindex_tot_cost_PCR) AS POST_TOT_MEAN,
MEAN(bundlecost_tot_PCR) AS BUNDLEMEAN,
SUM(bundlecost_tot_PCR) AS BUNDLE_SUM
FROM NEW_&BUNDLE
GROUP BY SURGEON_NPI
ORDER BY ELIG DESC;

CREATE TABLE PREMAT_SURGEON AS
SELECT SURGEON_NPI,
SUM(PREEMIE_FLG)/COUNT(*) AS PREMAT_PER
FROM PREMAT_ORIG
GROUP BY SURGEON_NPI;

CREATE TABLE SURGEON AS
SELECT A.*, B.BUNDLE_Q1, B.BUNDLE_Q3, B.BUNDLE_IQR, C.PREMAT_PER
FROM SURGEON_1 A, SURGEON_2 B, PREMAT_SURGEON C
WHERE A.SURGEON_NPI=B.SURGEON_NPI=C.SURGEON_NPI 
ORDER BY ELIG DESC;

QUIT;


/*MARKET BY PHYSICIAN GROUP TAB*/

PROC SORT DATA=NEW_&BUNDLE; BY SURGEON_TIN; RUN;

proc means data=NEW_&BUNDLE n Q1 Q3 maxdec=0 QRANGE; 
var bundlecost_tot_PCR;
OUTPUT OUT=PG_2 Q1=BUNDLE_Q1 Q3=BUNDLE_Q3 QRANGE=BUNDLE_IQR;
BY SURGEON_TIN; 
RUN;


PROC SQL;
CREATE TABLE PG_1 AS 
SELECT DISTINCT SURGEON_TIN, PHYS_GRP_NAME2, 
COUNT(*) AS ELIG,
CALCULATED ELIG/&&N_ELIGIBLE_&BUNDLE AS MKTSHARE,
SUM(er_pre_flg)/CALCULATED ELIG AS ER_PER,
SUM(CSECTION_FLG)/CALCULATED ELIG AS CSECTION_PER,
SUM(ultrsnd_flg GE 3)/CALCULATED ELIG AS US_PER,
SUM(vbac_flg)/CALCULATED ELIG AS VBAC_PER,
MEAN(preindex_fac_cost_PCR) AS PRE_FAC_MEAN,
MEAN(preindex_prof_cost_PCR) AS PRE_PROF_MEAN,
MEAN(preindex_tot_cost_PCR) AS PRE_TOT_MEAN,
MEAN(index_fac_cost_PCR) AS INDX_FAC_MEAN,
MEAN(index_prof_cost_PCR) AS INDX_PROF_MEAN,
MEAN(index_tot_cost_PCR) AS INDX_TOT_MEAN,
MEAN(postindex_fac_cost_PCR) AS POST_FAC_MEAN,
MEAN(postindex_prof_cost_PCR) AS POST_PROF_MEAN,
MEAN(postindex_tot_cost_PCR) AS POST_TOT_MEAN,
MEAN(bundlecost_tot_PCR) AS BUNDLEMEAN,
SUM(bundlecost_tot_PCR) AS BUNDLE_SUM
FROM NEW_&BUNDLE
GROUP BY SURGEON_TIN
ORDER BY ELIG DESC;

CREATE TABLE PREMAT_PG AS
SELECT SURGEON_TIN,
SUM(PREEMIE_FLG)/COUNT(*) AS PREMAT_PER
FROM PREMAT_ORIG
GROUP BY SURGEON_TIN;

CREATE TABLE PG AS
SELECT A.*, B.BUNDLE_Q1, B.BUNDLE_Q3, B.BUNDLE_IQR, C.PREMAT_PER
FROM PG_1 A, PG_2 B, PREMAT_PG C
WHERE A.SURGEON_TIN=B.SURGEON_TIN=C.SURGEON_TIN 
ORDER BY ELIG DESC;

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

TITLE;

*OUTPUTTING*;
ods Tagsets.ExcelXP file="&FILEPATH &STATE MOA &BUNDLE &RELEASE - &SYSDATE..xml" style=SEASIDE
     options(embedded_titles='yes' embedded_footnotes='yes');

*WATERFALL TAB*;
ods tagsets.excelxp options(sheet_name = 'Market Data Waterfall' sheet_interval='table');

PROC REPORT DATA=WF_TAB2;
COLUMN VAR1 COL1;
DEFINE VAR1/ DISPLAY "Episode Bundle Distribution" FORMAT=$WF.;
DEFINE COL1/ DISPLAY "Total" CENTER style(column)={tagattr='format:#,##0'};
RUN;

*MARKET DASHBOARD TAB*;
ods tagsets.excelxp options(sheet_name = 'Market Dashboard' sheet_interval='none');

PROC REPORT DATA=CHART_ALL HEADLINE CENTER SPLIT="/";
COLUMN GRAPHVAR COUNT;
DEFINE GRAPHVAR/DISPLAY "All" FORMAT=GRAPHVAR.;
DEFINE COUNT/DISPLAY "# Cases"; 
RUN;

*SUMMARY TAB*;
ods tagsets.excelxp options(sheet_name = 'Market Summary' sheet_interval='none');

/*SITE OF SERVICE*/
PROC REPORT DATA=SITESERV HEADLINE CENTER SPLIT="/";
COLUMN SRVC ELIG MKTSHARE ER_PER US_PER PREMAT_PER CSECTION_PER VBAC_PER PRE_FAC_MEAN PRE_PROF_MEAN PRE_TOT_MEAN 
INDX_FAC_MEAN INDX_PROF_MEAN INDX_TOT_MEAN POST_FAC_MEAN POST_PROF_MEAN POST_TOT_MEAN BUNDLEMEAN BUNDLE_Q1 
BUNDLE_Q3 BUNDLE_IQR BUNDLE_SUM;
DEFINE SRVC/DISPLAY "Site of Service" FORMAT=$SRVCNEW.;
DEFINE ELIG/DISPLAY "Count of Episode Bundles" style(column)={tagattr='format:#,##0'};
DEFINE MKTSHARE/DISPLAY "% of Market/Share" style(column)={tagattr='format:##0.0%'}; 
DEFINE BUNDLEMEAN/DISPLAY "Total Episode Costs Mean" 
style(column)={cellwidth=1.0 in tagattr='format:$#,##0'};
DEFINE PRE_FAC_MEAN/DISPLAY "Pre-Index Facility/Costs Mean" 
style(column)={cellwidth=1.0 in tagattr='format:$#,##0'};
DEFINE PRE_PROF_MEAN/DISPLAY "Pre-Index Professional/Costs Mean" 
style(column)={cellwidth=1.0 in tagattr='format:$#,##0'};
DEFINE PRE_TOT_MEAN/DISPLAY "Pre-Index Total/Costs Mean" 
style(column)={cellwidth=1.0 in tagattr='format:$#,##0'};
DEFINE INDX_FAC_MEAN/DISPLAY "Index Facility/Costs Mean" 
style(column)={cellwidth=1.0 in tagattr='format:$#,##0'};
DEFINE INDX_PROF_MEAN/DISPLAY "Index Professional/Costs Mean" 
style(column)={cellwidth=1.0 in tagattr='format:$#,##0'};
DEFINE INDX_TOT_MEAN/DISPLAY "Index Total/Costs Mean" 
style(column)={cellwidth=1.0 in tagattr='format:$#,##0'};
DEFINE POST_FAC_MEAN/DISPLAY "Post-Index Facility/Costs Mean" 
style(column)={cellwidth=1.0 in tagattr='format:$#,##0'};
DEFINE POST_PROF_MEAN/DISPLAY "Post-Index Professional/Costs Mean" 
style(column)={cellwidth=1.0 in tagattr='format:$#,##0'};
DEFINE POST_TOT_MEAN/DISPLAY "Post-Index Total/Costs Mean" 
style(column)={cellwidth=1.0 in tagattr='format:$#,##0'};
DEFINE BUNDLE_Q1/DISPLAY "Total Episode Cost/Lower Quartile" 
style(column)={cellwidth=1.0 in tagattr='format:$#,##0'};
DEFINE BUNDLE_Q3/DISPLAY "Total Episode Cost/Upper Quartile" 
style(column)={cellwidth=1.0 in tagattr='format:$#,##0'};
DEFINE BUNDLE_IQR/DISPLAY "Interquartile Range (IQR)" 
style(column)={cellwidth=1.0 in tagattr='format:$#,##0'};
DEFINE BUNDLE_SUM/DISPLAY "Total Episode/Costs Sum" 
style(column)={cellwidth=1.0 in tagattr='format:$#,##0'};

DEFINE ER_PER/DISPLAY "ER Utilization/Rate" 
style(column)={cellwidth=1.0 in tagattr='format:##0.0%'};
DEFINE US_PER/DISPLAY "3+ Ultrasound/Rate" 
style(column)={cellwidth=1.0 in tagattr='format:##0.0%'};
DEFINE CSECTION_PER/DISPLAY "C-Section/Rate" 
style(column)={cellwidth=1.0 in tagattr='format:##0.0%'};
DEFINE VBAC_PER/DISPLAY "VBAC/Rate" 
style(column)={cellwidth=1.0 in tagattr='format:##0.0%'};
DEFINE PREMAT_PER/DISPLAY "Preterm Birth/Rate" 
style(column)={cellwidth=1.0 in tagattr='format:##0.0%'};
RUN;


/*PRODUCT*/
PROC REPORT DATA=PRODUCT HEADLINE CENTER SPLIT="/";
COLUMN PROD ELIG MKTSHARE ER_PER US_PER PREMAT_PER CSECTION_PER VBAC_PER PRE_FAC_MEAN PRE_PROF_MEAN PRE_TOT_MEAN 
INDX_FAC_MEAN INDX_PROF_MEAN INDX_TOT_MEAN POST_FAC_MEAN POST_PROF_MEAN POST_TOT_MEAN BUNDLEMEAN BUNDLE_Q1
BUNDLE_Q3 BUNDLE_IQR BUNDLE_SUM;
DEFINE PROD/DISPLAY "Product" FORMAT=$PRODUCTF.;
DEFINE ELIG/DISPLAY "Count of Eligible Episodes" style(column)={tagattr='format:#,##0'};
DEFINE MKTSHARE/DISPLAY "% of Market/Share" style(column)={tagattr='format:##0.0%'}; 
DEFINE BUNDLEMEAN/DISPLAY "Total Episode Costs Mean" 
style(column)={cellwidth=1.0 in tagattr='format:$#,##0'};
DEFINE PRE_FAC_MEAN/DISPLAY "Pre-Index Facility/Costs Mean" 
style(column)={cellwidth=1.0 in tagattr='format:$#,##0'};
DEFINE PRE_PROF_MEAN/DISPLAY "Pre-Index Professional/Costs Mean" 
style(column)={cellwidth=1.0 in tagattr='format:$#,##0'};
DEFINE PRE_TOT_MEAN/DISPLAY "Pre-Index Total/Costs Mean" 
style(column)={cellwidth=1.0 in tagattr='format:$#,##0'};
DEFINE INDX_FAC_MEAN/DISPLAY "Index Facility/Costs Mean" 
style(column)={cellwidth=1.0 in tagattr='format:$#,##0'};
DEFINE INDX_PROF_MEAN/DISPLAY "Index Professional/Costs Mean" 
style(column)={cellwidth=1.0 in tagattr='format:$#,##0'};
DEFINE INDX_TOT_MEAN/DISPLAY "Index Total/Costs Mean" 
style(column)={cellwidth=1.0 in tagattr='format:$#,##0'};
DEFINE POST_FAC_MEAN/DISPLAY "Post-Index Facility/Costs Mean" 
style(column)={cellwidth=1.0 in tagattr='format:$#,##0'};
DEFINE POST_PROF_MEAN/DISPLAY "Post-Index Professional/Costs Mean" 
style(column)={cellwidth=1.0 in tagattr='format:$#,##0'};
DEFINE POST_TOT_MEAN/DISPLAY "Post-Index Total/Costs Mean" 
style(column)={cellwidth=1.0 in tagattr='format:$#,##0'};
DEFINE BUNDLE_Q1/DISPLAY "Total Episode Cost/Lower Quartile" 
style(column)={cellwidth=1.0 in tagattr='format:$#,##0'};
DEFINE BUNDLE_Q3/DISPLAY "Total Episode Cost/Upper Quartile" 
style(column)={cellwidth=1.0 in tagattr='format:$#,##0'};
DEFINE BUNDLE_IQR/DISPLAY "Interquartile/Range (IQR)" 
style(column)={cellwidth=1.0 in tagattr='format:$#,##0'};
DEFINE BUNDLE_SUM/DISPLAY "Total Episode/Costs Sum" 
style(column)={cellwidth=1.0 in tagattr='format:$#,##0'};

DEFINE ER_PER/DISPLAY "ER Utilization/Rate" 
style(column)={cellwidth=1.0 in tagattr='format:##0.0%'};
DEFINE US_PER/DISPLAY "3+ Ultrasound/Rate" 
style(column)={cellwidth=1.0 in tagattr='format:##0.0%'};
DEFINE CSECTION_PER/DISPLAY "C-Section/Rate" 
style(column)={cellwidth=1.0 in tagattr='format:##0.0%'};
DEFINE VBAC_PER/DISPLAY "VBAC/Rate" 
style(column)={cellwidth=1.0 in tagattr='format:##0.0%'};
DEFINE PREMAT_PER/DISPLAY "Preterm Birth/Rate" 
style(column)={cellwidth=1.0 in tagattr='format:##0.0%'};
RUN;

*FUNDING ARRANGEMENT*;
PROC REPORT DATA=FUNDING HEADLINE CENTER SPLIT="/";
COLUMN FUNDG_TYPE_LVL_1_DESC ELIG MKTSHARE ER_PER US_PER PREMAT_PER CSECTION_PER VBAC_PER PRE_FAC_MEAN PRE_PROF_MEAN PRE_TOT_MEAN 
INDX_FAC_MEAN INDX_PROF_MEAN INDX_TOT_MEAN POST_FAC_MEAN POST_PROF_MEAN POST_TOT_MEAN BUNDLEMEAN BUNDLE_Q1 
BUNDLE_Q3 BUNDLE_IQR BUNDLE_SUM;
DEFINE FUNDG_TYPE_LVL_1_DESC/DISPLAY "Funding/Arrangement" FORMAT=$FUND2F.;
DEFINE ELIG/DISPLAY "Count of Eligible Episodes" style(column)={tagattr='format:#,##0'};
DEFINE MKTSHARE/DISPLAY "% of Market/Share" style(column)={tagattr='format:##0.0%'}; 
DEFINE BUNDLEMEAN/DISPLAY "Total Episode Costs Mean" 
style(column)={cellwidth=1.0 in tagattr='format:$#,##0'};
DEFINE PRE_FAC_MEAN/DISPLAY "Pre-Index Facility/Costs Mean" 
style(column)={cellwidth=1.0 in tagattr='format:$#,##0'};
DEFINE PRE_PROF_MEAN/DISPLAY "Pre-Index Professional/Costs Mean" 
style(column)={cellwidth=1.0 in tagattr='format:$#,##0'};
DEFINE PRE_TOT_MEAN/DISPLAY "Pre-Index Total/Costs Mean" 
style(column)={cellwidth=1.0 in tagattr='format:$#,##0'};
DEFINE INDX_FAC_MEAN/DISPLAY "Index Facility/Costs Mean" 
style(column)={cellwidth=1.0 in tagattr='format:$#,##0'};
DEFINE INDX_PROF_MEAN/DISPLAY "Index Professional/Costs Mean" 
style(column)={cellwidth=1.0 in tagattr='format:$#,##0'};
DEFINE INDX_TOT_MEAN/DISPLAY "Index Total/Costs Mean" 
style(column)={cellwidth=1.0 in tagattr='format:$#,##0'};
DEFINE POST_FAC_MEAN/DISPLAY "Post-Index Facility/Costs Mean" 
style(column)={cellwidth=1.0 in tagattr='format:$#,##0'};
DEFINE POST_PROF_MEAN/DISPLAY "Post-Index Professional/Costs Mean" 
style(column)={cellwidth=1.0 in tagattr='format:$#,##0'};
DEFINE POST_TOT_MEAN/DISPLAY "Post-Index Total/Costs Mean" 
style(column)={cellwidth=1.0 in tagattr='format:$#,##0'};
DEFINE BUNDLE_Q1/DISPLAY "Total Episode Cost/Lower Quartile" 
style(column)={cellwidth=1.0 in tagattr='format:$#,##0'};
DEFINE BUNDLE_Q3/DISPLAY "Total Episode Cost/Upper Quartile" 
style(column)={cellwidth=1.0 in tagattr='format:$#,##0'};
DEFINE BUNDLE_IQR/DISPLAY "Interquartile/Range (IQR)" 
style(column)={cellwidth=1.0 in tagattr='format:$#,##0'};
DEFINE BUNDLE_SUM/DISPLAY "Total Episode/Costs Sum" 
style(column)={cellwidth=1.0 in tagattr='format:$#,##0'};

DEFINE ER_PER/DISPLAY "ER Utilization/Rate" 
style(column)={cellwidth=1.0 in tagattr='format:##0.0%'};
DEFINE US_PER/DISPLAY "3+ Ultrasound/Rate" 
style(column)={cellwidth=1.0 in tagattr='format:##0.0%'};
DEFINE CSECTION_PER/DISPLAY "C-Section/Rate" 
style(column)={cellwidth=1.0 in tagattr='format:##0.0%'};
DEFINE VBAC_PER/DISPLAY "VBAC/Rate" 
style(column)={cellwidth=1.0 in tagattr='format:##0.0%'};
DEFINE PREMAT_PER/DISPLAY "Preterm Birth/Rate" 
style(column)={cellwidth=1.0 in tagattr='format:##0.0%'};

RUN;

ods tagsets.excelxp options(sheet_name = 'Market by County' sheet_interval='table');

PROC REPORT DATA=COUNTY HEADLINE CENTER SPLIT="/";
COLUMN COUNTY_HOPPA ELIG MKTSHARE ER_PER US_PER PREMAT_PER CSECTION_PER VBAC_PER PRE_FAC_MEAN PRE_PROF_MEAN PRE_TOT_MEAN 
INDX_FAC_MEAN INDX_PROF_MEAN INDX_TOT_MEAN POST_FAC_MEAN POST_PROF_MEAN POST_TOT_MEAN BUNDLEMEAN BUNDLE_Q1 
BUNDLE_Q3 BUNDLE_IQR BUNDLE_SUM;
DEFINE COUNTY_HOPPA/DISPLAY "Facility County" ;
DEFINE ELIG/DISPLAY "Count of Episode Bundles" style(column)={tagattr='format:#,##0'};
DEFINE MKTSHARE/DISPLAY "% of Market/Share" style(column)={tagattr='format:##0.0%'}; 
DEFINE BUNDLEMEAN/DISPLAY "Total Episode Costs Mean" 
style(column)={cellwidth=1.0 in tagattr='format:$#,##0'};
DEFINE PRE_FAC_MEAN/DISPLAY "Pre-Index Facility/Costs Mean" 
style(column)={cellwidth=1.0 in tagattr='format:$#,##0'};
DEFINE PRE_PROF_MEAN/DISPLAY "Pre-Index Professional/Costs Mean" 
style(column)={cellwidth=1.0 in tagattr='format:$#,##0'};
DEFINE PRE_TOT_MEAN/DISPLAY "Pre-Index Total/Costs Mean" 
style(column)={cellwidth=1.0 in tagattr='format:$#,##0'};
DEFINE INDX_FAC_MEAN/DISPLAY "Index Facility/Costs Mean" 
style(column)={cellwidth=1.0 in tagattr='format:$#,##0'};
DEFINE INDX_PROF_MEAN/DISPLAY "Index Professional/Costs Mean" 
style(column)={cellwidth=1.0 in tagattr='format:$#,##0'};
DEFINE INDX_TOT_MEAN/DISPLAY "Index Total/Costs Mean" 
style(column)={cellwidth=1.0 in tagattr='format:$#,##0'};
DEFINE POST_FAC_MEAN/DISPLAY "Post-Index Facility/Costs Mean" 
style(column)={cellwidth=1.0 in tagattr='format:$#,##0'};
DEFINE POST_PROF_MEAN/DISPLAY "Post-Index Professional/Costs Mean" 
style(column)={cellwidth=1.0 in tagattr='format:$#,##0'};
DEFINE POST_TOT_MEAN/DISPLAY "Post-Index Total/Costs Mean" 
style(column)={cellwidth=1.0 in tagattr='format:$#,##0'};
DEFINE BUNDLE_Q1/DISPLAY "Total Episode Cost/Lower Quartile" 
style(column)={cellwidth=1.0 in tagattr='format:$#,##0'};
DEFINE BUNDLE_Q3/DISPLAY "Total Episode Cost/Upper Quartile" 
style(column)={cellwidth=1.0 in tagattr='format:$#,##0'};
DEFINE BUNDLE_IQR/DISPLAY "Interquartile/Range (IQR)" 
style(column)={cellwidth=1.0 in tagattr='format:$#,##0'};
DEFINE BUNDLE_SUM/DISPLAY "Total Episode/Costs Sum" 
style(column)={cellwidth=1.0 in tagattr='format:$#,##0'};

DEFINE ER_PER/DISPLAY "ER Utilization/Rate" 
style(column)={cellwidth=1.0 in tagattr='format:##0.0%'};
DEFINE US_PER/DISPLAY "3+ Ultrasound/Rate" 
style(column)={cellwidth=1.0 in tagattr='format:##0.0%'};
DEFINE CSECTION_PER/DISPLAY "C-Section/Rate" 
style(column)={cellwidth=1.0 in tagattr='format:##0.0%'};
DEFINE VBAC_PER/DISPLAY "VBAC/Rate" 
style(column)={cellwidth=1.0 in tagattr='format:##0.0%'};
DEFINE PREMAT_PER/DISPLAY "Preterm Birth/Rate" 
style(column)={cellwidth=1.0 in tagattr='format:##0.0%'};

RUN;

ods tagsets.excelxp options(sheet_name = 'Market by Facility' sheet_interval='table');

PROC REPORT DATA=FACILITY HEADLINE CENTER SPLIT="/";
COLUMN BILLG_TAX_ID_HOPPA FACNAME_HOPPA2 ELIG MKTSHARE ER_PER US_PER PREMAT_PER CSECTION_PER VBAC_PER PRE_FAC_MEAN PRE_PROF_MEAN PRE_TOT_MEAN 
INDX_FAC_MEAN INDX_PROF_MEAN INDX_TOT_MEAN POST_FAC_MEAN POST_PROF_MEAN POST_TOT_MEAN BUNDLEMEAN BUNDLE_Q1 
BUNDLE_Q3 BUNDLE_IQR BUNDLE_SUM;

DEFINE BILLG_TAX_ID_HOPPA/DISPLAY "Facility Tax ID" style(column)={cellwidth=1.0 in tagattr='Format:@'};
DEFINE FACNAME_HOPPA2/DISPLAY "Facility Name" style(column)={cellwidth=1.5 in};
DEFINE ELIG/DISPLAY "Count of Episode Bundles" style(column)={tagattr='format:#,##0'};
DEFINE MKTSHARE/DISPLAY "% of Market/Share" style(column)={tagattr='format:##0.0%'}; 
DEFINE BUNDLEMEAN/DISPLAY "Total Episode Costs Mean" 
style(column)={cellwidth=1.0 in tagattr='format:$#,##0'};
DEFINE PRE_FAC_MEAN/DISPLAY "Pre-Index Facility/Costs Mean" 
style(column)={cellwidth=1.0 in tagattr='format:$#,##0'};
DEFINE PRE_PROF_MEAN/DISPLAY "Pre-Index Professional/Costs Mean" 
style(column)={cellwidth=1.0 in tagattr='format:$#,##0'};
DEFINE PRE_TOT_MEAN/DISPLAY "Pre-Index Total/Costs Mean" 
style(column)={cellwidth=1.0 in tagattr='format:$#,##0'};
DEFINE INDX_FAC_MEAN/DISPLAY "Index Facility/Costs Mean" 
style(column)={cellwidth=1.0 in tagattr='format:$#,##0'};
DEFINE INDX_PROF_MEAN/DISPLAY "Index Professional/Costs Mean" 
style(column)={cellwidth=1.0 in tagattr='format:$#,##0'};
DEFINE INDX_TOT_MEAN/DISPLAY "Index Total/Costs Mean" 
style(column)={cellwidth=1.0 in tagattr='format:$#,##0'};
DEFINE POST_FAC_MEAN/DISPLAY "Post-Index Facility/Costs Mean" 
style(column)={cellwidth=1.0 in tagattr='format:$#,##0'};
DEFINE POST_PROF_MEAN/DISPLAY "Post-Index Professional/Costs Mean" 
style(column)={cellwidth=1.0 in tagattr='format:$#,##0'};
DEFINE POST_TOT_MEAN/DISPLAY "Post-Index Total/Costs Mean" 
style(column)={cellwidth=1.0 in tagattr='format:$#,##0'};
DEFINE BUNDLE_Q1/DISPLAY "Total Episode Cost/Lower Quartile" 
style(column)={cellwidth=1.0 in tagattr='format:$#,##0'};
DEFINE BUNDLE_Q3/DISPLAY "Total Episode Cost/Upper Quartile" 
style(column)={cellwidth=1.0 in tagattr='format:$#,##0'};
DEFINE BUNDLE_IQR/DISPLAY "Interquartile/Range (IQR)" 
style(column)={cellwidth=1.0 in tagattr='format:$#,##0'};
DEFINE BUNDLE_SUM/DISPLAY "Total Episode/Costs Sum" 
style(column)={cellwidth=1.0 in tagattr='format:$#,##0'};

DEFINE ER_PER/DISPLAY "ER Utilization/Rate" 
style(column)={cellwidth=1.0 in tagattr='format:##0.0%'};
DEFINE US_PER/DISPLAY "3+ Ultrasound/Rate" 
style(column)={cellwidth=1.0 in tagattr='format:##0.0%'};
DEFINE CSECTION_PER/DISPLAY "C-Section/Rate" 
style(column)={cellwidth=1.0 in tagattr='format:##0.0%'};
DEFINE VBAC_PER/DISPLAY "VBAC/Rate" 
style(column)={cellwidth=1.0 in tagattr='format:##0.0%'};
DEFINE PREMAT_PER/DISPLAY "Preterm Birth/Rate" 
style(column)={cellwidth=1.0 in tagattr='format:##0.0%'};

RUN;

ods tagsets.excelxp options(sheet_name = 'Market by Physician Group' sheet_interval='table');

PROC REPORT DATA=PG HEADLINE CENTER SPLIT="/";
COLUMN SURGEON_TIN PHYS_GRP_NAME2 ELIG MKTSHARE ER_PER US_PER PREMAT_PER CSECTION_PER VBAC_PER PRE_FAC_MEAN PRE_PROF_MEAN PRE_TOT_MEAN 
INDX_FAC_MEAN INDX_PROF_MEAN INDX_TOT_MEAN POST_FAC_MEAN POST_PROF_MEAN POST_TOT_MEAN BUNDLEMEAN BUNDLE_Q1 
BUNDLE_Q3 BUNDLE_IQR BUNDLE_SUM;

DEFINE PHYS_GRP_NAME2/DISPLAY "Physician Group Name" style(column)={cellwidth=1.5 in};
DEFINE SURGEON_TIN/DISPLAY "Physician Group Tax ID" style(column)={cellwidth=1.0 in tagattr='Format:@'};
DEFINE ELIG/DISPLAY "Count of Eligible Episodes" style(column)={tagattr='format:#,##0'};
DEFINE MKTSHARE/DISPLAY "% of Market/Share" style(column)={tagattr='format:##0.0%'}; 
DEFINE BUNDLEMEAN/DISPLAY "Total Episode Costs Mean" 
style(column)={cellwidth=1.0 in tagattr='format:$#,##0'};
DEFINE PRE_FAC_MEAN/DISPLAY "Pre-Index Facility/Costs Mean" 
style(column)={cellwidth=1.0 in tagattr='format:$#,##0'};
DEFINE PRE_PROF_MEAN/DISPLAY "Pre-Index Professional/Costs Mean" 
style(column)={cellwidth=1.0 in tagattr='format:$#,##0'};
DEFINE PRE_TOT_MEAN/DISPLAY "Pre-Index Total/Costs Mean" 
style(column)={cellwidth=1.0 in tagattr='format:$#,##0'};
DEFINE INDX_FAC_MEAN/DISPLAY "Index Facility/Costs Mean" 
style(column)={cellwidth=1.0 in tagattr='format:$#,##0'};
DEFINE INDX_PROF_MEAN/DISPLAY "Index Professional/Costs Mean" 
style(column)={cellwidth=1.0 in tagattr='format:$#,##0'};
DEFINE INDX_TOT_MEAN/DISPLAY "Index Total/Costs Mean" 
style(column)={cellwidth=1.0 in tagattr='format:$#,##0'};
DEFINE POST_FAC_MEAN/DISPLAY "Post-Index Facility/Costs Mean" 
style(column)={cellwidth=1.0 in tagattr='format:$#,##0'};
DEFINE POST_PROF_MEAN/DISPLAY "Post-Index Professional/Costs Mean" 
style(column)={cellwidth=1.0 in tagattr='format:$#,##0'};
DEFINE POST_TOT_MEAN/DISPLAY "Post-Index Total/Costs Mean" 
style(column)={cellwidth=1.0 in tagattr='format:$#,##0'};
DEFINE BUNDLE_Q1/DISPLAY "Total Episode Cost/Lower Quartile" 
style(column)={cellwidth=1.0 in tagattr='format:$#,##0'};
DEFINE BUNDLE_Q3/DISPLAY "Total Episode Cost/Upper Quartile" 
style(column)={cellwidth=1.0 in tagattr='format:$#,##0'};
DEFINE BUNDLE_IQR/DISPLAY "Interquartile/Range (IQR)" 
style(column)={cellwidth=1.0 in tagattr='format:$#,##0'};
DEFINE BUNDLE_SUM/DISPLAY "Total Episode/Costs Sum" 
style(column)={cellwidth=1.0 in tagattr='format:$#,##0'};

DEFINE ER_PER/DISPLAY "ER Utilization/Rate" 
style(column)={cellwidth=1.0 in tagattr='format:##0.0%'};
DEFINE US_PER/DISPLAY "3+ Ultrasound/Rate" 
style(column)={cellwidth=1.0 in tagattr='format:##0.0%'};
DEFINE CSECTION_PER/DISPLAY "C-Section/Rate" 
style(column)={cellwidth=1.0 in tagattr='format:##0.0%'};
DEFINE VBAC_PER/DISPLAY "VBAC/Rate" 
style(column)={cellwidth=1.0 in tagattr='format:##0.0%'};
DEFINE PREMAT_PER/DISPLAY "Preterm Birth/Rate" 
style(column)={cellwidth=1.0 in tagattr='format:##0.0%'};

RUN;

ods tagsets.excelxp options(sheet_name = 'Market by Physician' sheet_interval='table');

PROC REPORT DATA=SURGEON HEADLINE CENTER SPLIT="/";
COLUMN SURGEON_NPI SURGEON_NAME2 ELIG MKTSHARE ER_PER US_PER PREMAT_PER CSECTION_PER VBAC_PER PRE_FAC_MEAN PRE_PROF_MEAN PRE_TOT_MEAN 
INDX_FAC_MEAN INDX_PROF_MEAN INDX_TOT_MEAN POST_FAC_MEAN POST_PROF_MEAN POST_TOT_MEAN BUNDLEMEAN BUNDLE_Q1 
BUNDLE_Q3 BUNDLE_IQR BUNDLE_SUM;

DEFINE SURGEON_NAME2/DISPLAY "Physician Name" style(column)={cellwidth=1.5 in};
DEFINE SURGEON_NPI/DISPLAY "Physician NPI" style(column)={cellwidth=1.0 in tagattr='Format:@'};
DEFINE ELIG/DISPLAY "Count of Eligible Episodes" style(column)={tagattr='format:#,##0'};
DEFINE MKTSHARE/DISPLAY "% of Market/Share" style(column)={tagattr='format:##0.0%'}; 
DEFINE BUNDLEMEAN/DISPLAY "Total Episode Costs Mean" 
style(column)={cellwidth=1.0 in tagattr='format:$#,##0'};
DEFINE PRE_FAC_MEAN/DISPLAY "Pre-Index Facility/Costs Mean" 
style(column)={cellwidth=1.0 in tagattr='format:$#,##0'};
DEFINE PRE_PROF_MEAN/DISPLAY "Pre-Index Professional/Costs Mean" 
style(column)={cellwidth=1.0 in tagattr='format:$#,##0'};
DEFINE PRE_TOT_MEAN/DISPLAY "Pre-Index Total/Costs Mean" 
style(column)={cellwidth=1.0 in tagattr='format:$#,##0'};
DEFINE INDX_FAC_MEAN/DISPLAY "Index Facility/Costs Mean" 
style(column)={cellwidth=1.0 in tagattr='format:$#,##0'};
DEFINE INDX_PROF_MEAN/DISPLAY "Index Professional/Costs Mean" 
style(column)={cellwidth=1.0 in tagattr='format:$#,##0'};
DEFINE INDX_TOT_MEAN/DISPLAY "Index Total/Costs Mean" 
style(column)={cellwidth=1.0 in tagattr='format:$#,##0'};
DEFINE POST_FAC_MEAN/DISPLAY "Post-Index Facility/Costs Mean" 
style(column)={cellwidth=1.0 in tagattr='format:$#,##0'};
DEFINE POST_PROF_MEAN/DISPLAY "Post-Index Professional/Costs Mean" 
style(column)={cellwidth=1.0 in tagattr='format:$#,##0'};
DEFINE POST_TOT_MEAN/DISPLAY "Post-Index Total/Costs Mean" 
style(column)={cellwidth=1.0 in tagattr='format:$#,##0'};
DEFINE BUNDLE_Q1/DISPLAY "Total Episode Cost/Lower Quartile" 
style(column)={cellwidth=1.0 in tagattr='format:$#,##0'};
DEFINE BUNDLE_Q3/DISPLAY "Total Episode Cost/Upper Quartile" 
style(column)={cellwidth=1.0 in tagattr='format:$#,##0'};
DEFINE BUNDLE_IQR/DISPLAY "Interquartile/Range (IQR)" 
style(column)={cellwidth=1.0 in tagattr='format:$#,##0'};
DEFINE BUNDLE_SUM/DISPLAY "Total Episode/Costs Sum" 
style(column)={cellwidth=1.0 in tagattr='format:$#,##0'};

DEFINE ER_PER/DISPLAY "ER Utilization/Rate" 
style(column)={cellwidth=1.0 in tagattr='format:##0.0%'};
DEFINE US_PER/DISPLAY "3+ Ultrasound/Rate" 
style(column)={cellwidth=1.0 in tagattr='format:##0.0%'};
DEFINE CSECTION_PER/DISPLAY "C-Section/Rate" 
style(column)={cellwidth=1.0 in tagattr='format:##0.0%'};
DEFINE VBAC_PER/DISPLAY "VBAC/Rate" 
style(column)={cellwidth=1.0 in tagattr='format:##0.0%'};
DEFINE PREMAT_PER/DISPLAY "Preterm Birth/Rate" 
style(column)={cellwidth=1.0 in tagattr='format:##0.0%'};

RUN;

ODS tagsets.excelxp close;

*WHEN EPISODES ARE PERFORMED IN MORE THAN 1 SETTING - CREATING SUMMARY LINE FOR CHARTS IN SUMMARY DASHBOARD*; 

PROC SQL;
CREATE TABLE SUMMARY AS 
SELECT
COUNT(*) AS ELIG,
SUM(er_pre_flg)/CALCULATED ELIG AS ER_PER,
SUM(CSECTION_FLG)/CALCULATED ELIG AS CSECTION_PER,
SUM(ultrsnd_flg GE 3)/CALCULATED ELIG AS US_PER,
SUM(vbac_flg)/CALCULATED ELIG AS VBAC_PER,
MEAN(preindex_fac_cost_PCR) AS PRE_FAC_MEAN,
MEAN(preindex_prof_cost_PCR) AS PRE_PROF_MEAN,
MEAN(index_fac_cost_PCR) AS INDX_FAC_MEAN,
MEAN(index_prof_cost_PCR) AS INDX_PROF_MEAN,
MEAN(postindex_fac_cost_PCR) AS POST_FAC_MEAN,
MEAN(postindex_prof_cost_PCR) AS POST_PROF_MEAN
FROM NEW_&BUNDLE;

CREATE TABLE PREMAT_SUMMARY AS
SELECT 
SUM(PREEMIE_FLG)/COUNT(*) AS PREMAT_PER
FROM PREMAT_ORIG;
QUIT;

*OUTPUTTING*;
ods Tagsets.ExcelXP file="&FILEPATH &STATE MOA &BUNDLE &RELEASE SUMMARY - &SYSDATE..xml" style=SEASIDE
     options(embedded_titles='yes' embedded_footnotes='yes');

PROC PRINT DATA=SUMMARY; RUN;
PROC PRINT DATA=PREMAT_SUMMARY; RUN;

ODS tagsets.excelxp close;
