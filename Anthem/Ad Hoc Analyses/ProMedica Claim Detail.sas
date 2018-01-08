
options compress=yes MPRINT;

%LET BUNDLE=TKR;
%LET PROVIDER=ProMedica; 
%LET STARTDATE=0715;
%LET ENDDATE=0616;
%LET IDVAR=billg_tax_id_hoppa;
%LET FILEPATH=/ephc/ebp/nobackup/users/blase/;
%LET RELEASE=R9;
%LET ADMINID=%STR('344428256','344446484','344428794','344430849','341883132','340898745');
%LET ST=OH;
%LET LOB=Commercial;
%LET BUNDLEDESC=Total Knee Replacement;
%LET PERIOD=4/1/2015 - 3/31/2016;
%LET FACIDVAR=billg_tax_id_hoppa;
%LET DATASET=&ST._&BUNDLE._&STARTDATE._&ENDDATE._&RELEASE;

libname &BUNDLE._LIB "/ephc/ebp/backup/data/phi/tjr/%LOWCASE(&ST)/%LOWCASE(&BUNDLE)";

DATA &BUNDLE._ORIG;
SET &BUNDLE._LIB.&DATASET;
LENGTH SRVC $ 8.; 

IF &IDVAR IN (&ADMINID);

*CONVERTING PLACE OF SERVICE VARIABLE*;
*ER (indx_PLACE_OF_SRVC_CD='23') CLASSIFIED AS OP PER SS IN EMAIL ON 3/15/16*;
IF indx_PLACE_OF_SRVC_CD='21' THEN SRVC="IP Hosp";
ELSE IF indx_PLACE_OF_SRVC_CD IN ('22','23') THEN SRVC="OP Hosp";
ELSE SRVC="ASC";

*MAKING NUMERIC SRVC VARIABLE TO ORDER BY INPATIENT, OUTPATIENT, ASC*;
IF indx_PLACE_OF_SRVC_CD='21' THEN SRVC2=1;
ELSE IF indx_PLACE_OF_SRVC_CD IN ('22','23') THEN SRVC2=2;
ELSE SRVC2=3;

*USE THIS FOR EPISODE COST SUMMARY SECTION IN SUMMARY SHEET*;
*TOTAL FACILITY AND PROFESSIONAL COSTS ACROSS INDEX AND POST-INDEX PROCEDURES*;
FAC_TOT=index_fac_cost_PCR+postindex_fac_cost_PCR;
PROF_TOT=index_prof_cost_PCR+postindex_prof_cost_PCR;
SURGEON_TOT=index_prof_SURG_PCR+postindex_prof_SURG_PCR;
ANESTH_TOT=index_prof_ANESTH_PCR+postindex_prof_ANESTH_PCR;
EQSUP_TOT=index_prof_EQ_SUP_PCR+postindex_prof_EQ_SUP_PCR;
OTHPROF_TOT=PROF_TOT-(EQSUP_TOT+ANESTH_TOT+SURGEON_TOT); *OTHER PROFESSIONAL COSTS (EXCLUDES SURGEON, ANESTHESIOLOGY 
AND EQUIPMENT/SUPPLIES COSTS IN ENTIRE EPISODE)*;

*SUMMARY SHEET - COST CONTRIBUTING FACTORS SECTION*;
*OTHER PROFESSIONAL COSTS IN INDEX PERIOD*;
index_otherprof_cost=index_prof_cost_PCR - index_prof_SURG_PCR - index_prof_ANESTH_PCR;
*OTHER PROFESSIONAL COSTS IN INDEX PERIOD;
postindex_otherprof_cost=postindex_prof_cost_PCR - postindex_prof_SURG_PCR - postindex_prof_RHAB_THPY_PCR;

*READMISSION FLAG*;
IF READMIT_FLG=1 AND (compl_flg=1 OR revise_flg=1) THEN READMISSION=1;
ELSE READMISSION=0;

FACNAME_HOPPA=UPCASE(FACNAME_HOPPA);

RUN;


PROC SQL;
CREATE TABLE TAB1 AS
SELECT DISTINCT &FACIDVAR, facname_hoppa, medcr_id_hoppa
FROM &BUNDLE._ORIG
ORDER BY &FACIDVAR, medcr_id_hoppa;
QUIT;

PROC SORT DATA=&BUNDLE._ORIG; BY &FACIDVAR medcr_id_hoppa; RUN;

*REMERGING DATASET WITH 1 NAME PER FACILITY WITH ENTIRE DATASET*;
DATA TAB3;
MERGE &BUNDLE._ORIG (DROP=facname_hoppa)
	  TAB1;
BY &FACIDVAR medcr_id_hoppa;

*NOW THAT HAVE FACILITY NAME STANDARDIZED, CHANGING SURGEONS NAMES WHO ARE UNK TO THE FACILITY NAME + OTHER SURGEON*;
*CHANGING UNKNOWN SURGEON NAME TO GENERIC FACILITY OTHER SURGEON*;
SURGEON_NAME2=UPCASE(SURGEON_NAME);
IF SURGEON_NAME="UNK" THEN SURGEON_NAME2=CATX(" ",facname_hoppa,"OTHER SURGEON");

*CHANGING UNKNOWN SURGEON NPI TO BLANK NPI*;
SURGEON_NPI2=SURGEON_NPI;
IF SURGEON_NPI="UNK" THEN SURGEON_NPI2=" ";

RUN;

*EXTRACTING INDIVIDUAL SURGEONS*;
*NOTE: LISTING ALL SURGEONS FOR A PARTICULAR ADMINISTRATIVE PROVIDER, NOT JUST THE ONES THAT HAD ELIGIBLE
BUNDLE EPISODES. PER BUSINESS TEAM - WE WANT TO MAKE SURE THAT ADMIN PROVIDER KNOWS THAT WE SEARCHED ALL SURGEONS
EVEN IF SOME DIDNT END UP HAVING ELIGIBLE EPISODES*;

PROC SORT DATA=TAB3; BY SURGEON_NPI2 SURGEON_NAME2; RUN;

*FREQUENCY OF SURGEON NAME USED BY SURGEON NPI. USING SURGEON NAME THATS USED MOST OFTEN.*;
PROC SQL;
CREATE TABLE TAB4 AS 
SELECT SURGEON_NPI2, SURGEON_NAME2,
COUNT(*) AS TESTVAR
FROM TAB3
GROUP BY SURGEON_NPI2,SURGEON_NAME2
ORDER BY SURGEON_NPI2, CALCULATED TESTVAR DESC, SURGEON_NAME2;
QUIT;

DATA TAB5;
SET TAB4;
*ONLY TAKING THE FIRST NAME/NPI COMBO IF THE SURGEON NAME/NPI IS MISSING*;
IF SURGEON_NPI2 NE ' ' THEN DO;
	BY SURGEON_NPI2;
	IF FIRST.SURGEON_NPI2;
END;

RUN;

*ALPHABETIZING SURGEON NAMES*;
PROC SORT DATA=TAB5; BY SURGEON_NAME2; RUN;

*RESORTING DATASET TO BE MERGED BELOW*;
PROC SORT DATA=TAB5; BY SURGEON_NPI2; RUN;

*REMERGING DATASET WITH NAME CORRECTIONS FOR LATER USE AND ONLY KEEPING ELIGIBLE CASES*;
*NOTE: USE SURGEON_NAME2 FOR SURGEON NAME AND facname_hoppa FOR FACILITY NAME SINCE THEYRE CORRECTED*;
DATA NEW_&BUNDLE;
MERGE TAB3 (DROP=SURGEON_NAME2)
	  TAB5;
BY SURGEON_NPI2;

/*** VALID -- Commercial - EXCLUSION CASCADE   ***/
*NOTE: EXCLUSIONS ARE THE SAME FOR THR AND TKR*;
if 
DRG_flg=1 AND /* Exclude episodes with the correct surg proc code but incorrect DRG (i.e., 462)*/
 		  /* DRG inclusion criteria for index procedure but only apply to IP episodes */
			  /* allows for ASC episodes to not be excluded b/c DRG criteria is not applicable */
ind_flg=1 AND /* index trigger occurred within designated index period exclude 2nd index trigger */
			  /* occurring during experience period but outside of index period -- ind_flg=2 */
 cap_flg in (0,2) AND  /* product exclusion criteria episodes with capitation-- cap_flg=1 */
ex_dx_flg=0 AND 	/* clinical historical exclusion criteria */
dx_flg=1 AND 		/* Dx inclusion criteria */
lob_lvl_flg in (1,2,3,4) AND /* Program Participation Exclusions of MCARE and MCAID */					
enrl_flg=1 AND /* continuous enrollment criteria */
lob_flg=1 AND  /* continuous enrollment in same plan criteria */
age_flg=1 AND  /* minimum age at index service date criteria */
WP_Primary=0 AND /* Anthem primary criteria */
blt_flg=0 AND   /* bilateral exclusion criteria */
hosp_only_flg=0; /* product exclusion criteria */

RUN;

PROC SQL;
CREATE TABLE CLAIM_DETAIL AS 
SELECT 
B.CLM_ADJSTMNT_KEY,
B.FNL_DRG_CD,
B.DRG_CD,
B.ALWD_AMT,
B.CLM_NBR,
A.MBR_KEY,
A.RBNUM,
B.CLM_LINE_SRVC_STRT_DT,
B.CLM_LINE_SRVC_END_DT,
A.SURGEON_NPI2,
B.SRC_BILLG_TAX_ID,
B.PLACE_OF_SRVC_CD,
B.PRNCPL_DIAG_CD_HDR,
B.PRNCPL_DIAG_CD_LN,
B.PRNCPL_ICD_PROC_CD,
B.ICD_PROC_1_CD,
B.ICD_PROC_2_CD,
B.OTHR_DIAG_1_CD_HDR,
B.OTHR_DIAG_1_CD_LN,
B.OTHR_DIAG_2_CD_HDR,
B.OTHR_DIAG_2_CD_LN,
B.OTHR_DIAG_3_CD_HDR,
B.OTHR_DIAG_3_CD_LN,
B.OTHR_ICD_PROC_1_CD,
B.OTHR_ICD_PROC_2_CD,
B.RVNU_CD,
B.HLTH_SRVC_CD,
B.SRVC_RNDRG_TYPE_CD
from NEW_&BUNDLE A
LEFT join &BUNDLE._LIB.&ST._&BUNDLE._PCR_CLM_0715_0616 B 
on A.MBR_KEY = B.MBR_KEY AND
A.RBNUM=B.RBNUM
WHERE CLM_FLG='INDX_PST'
GROUP BY A.MBR_KEY, A.RBNUM
ORDER BY A.MBR_KEY, A.RBNUM;
QUIT;