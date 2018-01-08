/****** DATA PROFILING AUTOMATION FOR THR/TKR ******/

*NOTE: IF YOU NEED TO RERUN THE CODE ABOVE RUN THE PROC DATASETS LINE BELOW TO CLEAR ALL TEMPORARY DATASETS SO OLD DATASETS DONT GET APPENDED TO NEW DATASETS*; 
PROC DATASETS LIBRARY=WORK KILL; RUN; QUIT;

ODS PATH RESET;
ODS PATH (PREPEND) WORK.TEMPLAT(UPDATE);

PROC TEMPLATE;
EDIT BASE.FREQ.ONEWAYLIST;
	EDIT Frequency;                          
      FORMAT = COMMA6.;                      
    END;                                     
    EDIT CumFrequency;                       
      FORMAT = COMMA6.;                      
    END;                                     
    EDIT Percent;                            
      FORMAT = 5.1;                          
    END;                                     
    EDIT CumPercent;                         
      FORMAT = 5.1;                          
    END;                                     
  END;                                       
RUN;               

%LET STARTDATE=0715;
%LET ENDDATE=0616;
%LET RELEASE=R9;
%LET STATE=WI;
%LET FILEPATH=/ephc/ebp/nobackup/users/blase/;
*------------------------------------------------------------------------------------------------------------------*;

%LET DATASET_THR=&STATE._THR_&STARTDATE._&ENDDATE._&RELEASE;
%LET DATASET_TKR=&STATE._TKR_&STARTDATE._&ENDDATE._&RELEASE;

libname THR_&STATE "/ephc/ebp/backup/data/phi/tjr/%LOWCASE(&STATE)/thr";
libname TKR_&STATE "/ephc/ebp/backup/data/phi/tjr/%LOWCASE(&STATE)/tkr";
options compress=yes;

/*************************************************************************/
/****************           TKR  --  VALID        ************************/

/* TKR -- VALID Flagging criteria applied here */
data &STATE._TKR_VALID; set TKR_&STATE..&DATASET_TKR;
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
lob_flg=1 AND  /* continuous enrolllment in same plan criteria */
age_flg=1 AND  /* minimum age at index service date criteria */
WP_Primary=0 AND /* Anthem primary criteria */
blt_flg=0 AND   /* bilateral exclusion criteria */
hosp_only_flg=0; /* product exclusion criteria */

IF READMIT_FLG=1 AND (compl_flg=1 OR revise_flg=1) THEN READMISSION=1;
ELSE READMISSION=0;

IF bundlecost_tot_PCR = 0 THEN NOCOST=1;
ELSE NOCOST=0;

/*IF MDY(4,1,2015)<=INDX_CLM_LINE_SRVC_STRT_DT<MDY(7,1,2015) THEN Q=2;*/
/*ELSE IF MDY(7,1,2015)<=INDX_CLM_LINE_SRVC_STRT_DT<MDY(10,1,2015) THEN Q=3;*/
/*ELSE IF MDY(10,1,2015)<=INDX_CLM_LINE_SRVC_STRT_DT<MDY(1,1,2016) THEN Q=4;*/
/*ELSE Q=1;*/

run;

/************************************************************************/
/**************            THR    --  VALID               ***************/
 
/***  THR  -- VALID -- COmmercial   ***/
data &STATE._THR_VALID; set THR_&STATE..&DATASET_THR;
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
lob_flg=1 AND  /* continuous enrolllment in same plan criteria */
age_flg=1 AND  /* minimum age at index service date criteria */
WP_Primary=0 AND /* Anthem primary criteria */
blt_flg=0 AND   /* bilateral exclusion criteria */
hosp_only_flg=0; /* product exclusion criteria */

IF READMIT_FLG=1 AND (compl_flg=1 OR revise_flg=1) THEN READMISSION=1;
ELSE READMISSION=0;

IF bundlecost_tot_PCR = 0 THEN NOCOST=1;
ELSE NOCOST=0;

/*IF MDY(4,1,2015)<=INDX_CLM_LINE_SRVC_STRT_DT<MDY(7,1,2015) THEN Q=2;*/
/*ELSE IF MDY(7,1,2015)<=INDX_CLM_LINE_SRVC_STRT_DT<MDY(10,1,2015) THEN Q=3;*/
/*ELSE IF MDY(10,1,2015)<=INDX_CLM_LINE_SRVC_STRT_DT<MDY(1,1,2016) THEN Q=4;*/
/*ELSE Q=1;*/

run;


*VALID EPISODE COSTS*;
*TOTAL BUNDLE COSTS*;

*THR*;
proc means data=&STATE._THR_VALID n median mean std Q1 Q3 maxdec=0;
title1 "&STATE Market Level Summary Statistics - Valid THRs";
title2 'Total Episode Costs (Index + Post-Index)';
	var bundlecost_tot_PCR;
	output out = &STATE._THR_BUNDLE Q1=BUNDLE_Q1 Q3=BUNDLE_Q3 MEDIAN=BUNDLE_MEDIAN MEAN=BUNDLE_MEAN STD=BUNDLE_STD 
	N=BUNDLE_N;
run;

*TKR*; 
proc means data=&STATE._TKR_VALID n median mean std Q1 Q3 maxdec=0;
title1 "&STATE Market Level Summary Statistics - Valid TKRs";
title2 'Total Episode Costs (Index + Post-Index)';
	var bundlecost_tot_PCR;
	output out = &STATE._TKR_BUNDLE Q1=BUNDLE_Q1 Q3=BUNDLE_Q3 MEDIAN=BUNDLE_MEDIAN MEAN=BUNDLE_MEAN STD=BUNDLE_STD 
	N=BUNDLE_N;
run;

PROC APPEND BASE=BUNDLE_FINAL DATA=&STATE._THR_BUNDLE FORCE; RUN;
PROC APPEND BASE=BUNDLE_FINAL DATA=&STATE._TKR_BUNDLE FORCE; RUN;

DATA BUNDLE_FINAL (DROP=_TYPE_ _FREQ_);
SET BUNDLE_FINAL;

FORMAT BUNDLE_N COMMA8. BUNDLE_MEDIAN BUNDLE_MEAN BUNDLE_STD BUNDLE_Q1 BUNDLE_Q3 DOLLAR11.;
RUN;


*INDEX FACILITY COSTS*;

*THR*;
proc means data=&STATE._THR_VALID n median mean std Q1 Q3 maxdec=0;
title1 "&STATE Market Level Summary Statistics - Valid THRs";
title2 'Index Facility Costs';
	var index_fac_cost_PCR;
	output out = &STATE._THR_FAC Q1=FAC_Q1 Q3=FAC_Q3 MEDIAN=FAC_MEDIAN MEAN=FAC_MEAN STD=FAC_STD 
	N=FAC_N;
run;

*TKR*;
proc means data=&STATE._TKR_VALID n median mean std Q1 Q3 maxdec=0;
title1 "&STATE Market Level Summary Statistics - Valid TKRs";
title2 'Index Facility Costs';
	var index_fac_cost_PCR;
	output out = &STATE._TKR_FAC Q1=FAC_Q1 Q3=FAC_Q3 MEDIAN=FAC_MEDIAN MEAN=FAC_MEAN STD=FAC_STD 
	N=FAC_N;
run;

PROC APPEND BASE=FAC_FINAL DATA=&STATE._THR_FAC FORCE; RUN;
PROC APPEND BASE=FAC_FINAL DATA=&STATE._TKR_FAC FORCE; RUN;

DATA FAC_FINAL;
SET FAC_FINAL;

FORMAT FAC_N COMMA8. FAC_MEDIAN FAC_MEAN FAC_STD FAC_Q1 FAC_Q3 DOLLAR11.;
RUN;


ODS RTF FILE="/ephc/ebp/nobackup/users/blase/&STATE &RELEASE THR TKR DATA PROFILING - &SYSDATE..RTF"; 

/*******************************************************************************/
/************            VALID EPISODES             ************/
/* apply inclusion/exclusion flags to determine valid episodes */

/****************             TKR                ***************/

/*********    TOPLINE FLAGS     ********/
proc freq data=thr_&STATE..&DATASET_THR;
title "&STATE THR  - Total TOPLINE";
tables lob_lvl_flg /list missing;
where ind_flg=1 and DRG_flg=1 and lob_lvl_flg ne 9;
run;

proc freq data=tkr_&STATE..&DATASET_TKR;
title "&STATE TKR  - Total TOPLINE";
tables lob_lvl_flg /list missing;
where ind_flg=1 and DRG_flg=1 and lob_lvl_flg ne 9;
run;

*TOPLINE EPISODES BY SITE OF SERVICE - TKR*;

*TOPLINE EPISODES BY SITE OF SERVICE - THR*;
proc freq data=thr_&STATE..&DATASET_THR;
title "&STATE THR Topline - Place of Service";
tables indx_PLACE_OF_SRVC_CD /list missing;
where DRG_flg=1 AND ind_flg=1 AND lob_lvl_flg ne 9;
run;

proc freq data=tkr_&STATE..&DATASET_TKR;
title "&STATE TKR Topline - Place of Service";
tables indx_PLACE_OF_SRVC_CD /list missing;
where DRG_flg=1 AND ind_flg=1 AND lob_lvl_flg ne 9;
run;

/****               PROFILING Valid Episodes                        ****/

/** COSTS **/
TITLE1 "&STATE TOTAL BUNDLE COSTS";
PROC PRINT DATA=BUNDLE_FINAL; 
VAR BUNDLE_N BUNDLE_MEDIAN BUNDLE_MEAN BUNDLE_STD BUNDLE_Q1 BUNDLE_Q3;
RUN;

TITLE1 "&STATE INDEX FACILITY COSTS";
PROC PRINT DATA=FAC_FINAL; 
VAR FAC_N FAC_MEDIAN FAC_MEAN FAC_STD FAC_Q1 FAC_Q3;
RUN;

/**  MEMBER PROFILE  **/
proc means data=&STATE._THR_VALID n mean maxdec=1;
title1 "&STATE Market Level Summary Statistics - Valid THRs";
title2 'Age';
	var age;
run;

proc means data=&STATE._TKR_VALID n mean maxdec=1;
title1 "&STATE Market Level Summary Statistics - Valid TKRs";
title2 'Age';
	var age;
run;

proc freq data=&STATE._THR_VALID;
title1 "&STATE Market Level Summary Statistics - Valid THRs";
title2 'Gender, Member Plan, Member Product';
tables MBR_GNDR_CD PROD_LVL_2_DESC SBU_DESC/list;
run;

proc freq data=&STATE._TKR_VALID;
title1 "&STATE Market Level Summary Statistics - Valid TKRs";
title2 'Gender, Member Plan, Member Product';
tables MBR_GNDR_CD PROD_LVL_2_DESC SBU_DESC/list;
run;

proc means data=&STATE._THR_VALID n mean maxdec=1;
title1 "&STATE Market Level Summary Statistics - Valid THRs";
title2 'Episode Bundle Profile - LOS';
	var LOS_CNT;
run;

proc means data=&STATE._TKR_VALID n mean maxdec=1;
title1 "&STATE Market Level Summary Statistics - Valid TKRs";
title2 'Episode Bundle Profile - LOS';
	var LOS_CNT;
run;

proc freq data=&STATE._THR_VALID;
title1 "&STATE Market Level Summary Statistics - Valid THRs";
title2 'Episode Bundle Profile - Extended Episode, Readmissions, Complications, Revisions';
tables IP_ext_flg readmission compl_flg revise_flg/list;
run;

proc freq data=&STATE._TKR_VALID;
title1 "&STATE Market Level Summary Statistics - Valid TKRs";
title2 'Episode Bundle Profile - Extended Episode, Readmissions, Complications, Revisions';
tables IP_ext_flg readmission compl_flg revise_flg/list;
run;

title1 "&STATE Market Level Summary Statistics - Valid THRs";
title2 'NO COST EPISODES';
PROC FREQ DATA=&STATE._THR_VALID;
TABLES NOCOST;
RUN;

title1 "&STATE Market Level Summary Statistics - Valid TKRs";
title2 'NO COST EPISODES';
PROC FREQ DATA=&STATE._TKR_VALID;
TABLES NOCOST;
RUN;


ODS RTF CLOSE;
