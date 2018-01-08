/*============================================================================================================
  Project Name     : NHL & EBV Strat 3 Years Analysis
  PI               : LAUREN TERAS
  Last update      : 11/26/13 - Created analysis for supplemental table 1 in the EBV and NHL publication
  ===========================================================================================================*/

*********************************************************;
*	STRATIFIED BY 3 YEARS BETWEEN BLOOD DRAW AND DX		*;
*********************************************************;

OPTIONS MPRINT;
LIBNAME EBV 'D:\USER\JBLASE\EBV Program Review\DATA';
%include 'D:\USER\JBLASE\MACROS\%ALCVARS.sas';


PROC FORMAT; 

VALUE  $CACOF   
	        '1' = '1: CASE'
			'2' = '2: CONTROL'; 

VALUE  CACOF   
	        1 = "1: CASE"
			0 = "0: CONTROL"; 

VALUE SMK4CAT 1='1.NEVER'
			  2='2.CURRENT'
			  3='3.FORMER'
			  9='9.UNKNOWN';

VALUE $ SMK97F
			'1' = '1.Nonsmoker'                     
			'2' = '2.Current Smoker'
			'3' = '3.Former Smoker'
			'8', '9',' ' = '8.&9.UNKNOWN'; 

VALUE ALC_BLK 	1='1: Non-drinker'
            	2='2: < 1/day'
	      		3='3: 1-2/day'
	      		4='4: >2/day'
	      		9='9: Missing'
		  		;
VALUE BMIWHO 	0='0: <25.0 (UNDER/NORMAL)'				
			 	1='1: 25.0-<30.0 (OVERWEIGHT)'
			 	2='2: >=30.0 (OBESE)'
			 	9='9: UNKNOWN'
				; 

VALUE BMIGRP 1='1: <18.5'
			 2='2: 18.5-<25.0'
			 3='3: 25-<30'
			 4='4: 30 +'
			 9='9: UNKNOWN';

VALUE $ REGIONF   
				'1' = '1: Northeast' 
				'2' = '2: West'      
				'3' = '3: South'     
				'4' = '4: MidWest'; 

VALUE $YNF
				'1' = '1: Yes'
				'2' = '2: No'
				' ' = 'UNKNOW'; 
VALUE EDUCAF 
                1 = '1: Less than high school'
				2 = '2: High school/missing education'
				3 = '3: Some college/vocational school'
				4 = '4: College/graduate school'; 

VALUE $PERF     '0' = '<= 25 Percentile'
                '1' = '25-75 Percentile'
				'2' = '>75   Percentile'
				; 

VALUE NPF      0 = '0. Seronegative'
               1 = '1. Seropositive'
				 ; 

VALUE NPQF      0 = '0. Seronegative'
                1 = '1. <=25% '
                2 = '2. 25%-75%'
				3 = '3. >75%'
				; 

VALUE EXCLUSION 1 = 'Missing lab data'
				2 = 'Hodgkin Lymphoma'
				3 = 'Multiple Myeloma'
				.='Final Cohort'
				;

VALUE SUB1CAT	0 = 'Control'
				1 = 'DLBCL'
				2 = 'CLL/SLL'
				3 = 'Follicular'
				4 = 'Other NHL'
				;

VALUE ANT_COMB	1 = 'No antigens positive'
				2 = 'VCA & EBNA'
				3 = 'EA, VCA, EBNA'
				4 = 'ZEBRA, VCA, EBNA'
				5 = 'All antigens positive'
				. = 'Other combos'
				;

%ALCVARFMT

RUN;

***CREATING NEW DATASETS WITH LESS THAN 3/ 3 AND MORE YEARS*;
***LESS THAN 3 YEARS***;

PROC SORT DATA=EBV.FINALCOHORT OUT=ONE; BY MATCH; RUN;

DATA TWO;
	SET ONE;
	IF DXIN3Y=1;
RUN;

DATA LTTHREE;
	MERGE TWO (IN=A) ONE;
	BY MATCH;
	IF A;
RUN;	

***3 OR MORE YEARS***;

DATA FOUR;
SET ONE;
IF DXIN3Y=2;
RUN;

DATA GETHREE;
MERGE FOUR (IN=A) ONE;
BY MATCH;
IF A;
RUN;

*CASE AND CONTROL FREQUENCIES (LESS THAN 3)*;
ODS RTF FILE="D:\USER\JBLASE\EBV Program Review\OUTPUT\STRATIFIED 3 YEARS - CACO FREQUENCIES.RTF";
TITLE 'CASE AND CONTROL FREQUENCIES - LESS THAN 3 YEARS';
PROC FREQ DATA=LTTHREE;  
	TABLE CACONEW*(EBV_CLASS ZEBRA75 EBNA_TRU75 EA_D75 VCA_p1875)/MISSING  NOROW NOCOL NOPERCENT; ; 
RUN; 

*CASE AND CONTROL FREQUENCIES (3 OR MORE YEARS)*;
TITLE 'CASE AND CONTROL FREQUENCIES - 3 OR MORE YEARS';
PROC FREQ DATA=GETHREE;  
	TABLE CACONEW*(EBV_CLASS ZEBRA75 EBNA_TRU75 EA_D75 VCA_p1875)/MISSING  NOROW NOCOL NOPERCENT; ; 
RUN; 
ODS RTF CLOSE;

***SEROPOSITIVITY ANALYSES IN LESS THAN 3 YEARS SUBGROUP***;
ODS OUTPUT  OddsRatios =OREst;
TITLE 'CONDITIONAL LOGISTIC MODEL, NHL ON EBV_CLASS IN LESS THAN 3 YEARS'; 
		PROC LOGISTIC DATA=LTTHREE;
			STRATA MATCH;
			CLASS  EBV_CLASS (REF=FIRST)/PARAM=REF ; 
			MODEL CACONEW (EVENT='1')=EBV_CLASS;
			EXACT EBV_CLASS/ESTIMATE=BOTH; 
		RUN;
ODS OUTPUT CLOSE;

DATA WORK.ODDS_combo;
			LENGTH OR_CI $25;	
			SET WORK.OREst;	
			VARIABLE=EFFECT; 

			RR=PUT(OddsRatioEst, 4.2);
			Lcl=PUT(LOWERCL, 4.2);
			Ucl=PUT(UPPERCL, 4.2);

			OR_CI=RR||" ("||Lcl||", "||Ucl||")";   
			OUTCOME="ALL HEME"; 

			KEEP VARIABLE OR_CI OUTCOME ;
		RUN;

***SEROPOSITIVITY ANALYSES IN 3 YEARS OR MORE SUBGROUP***;
ODS OUTPUT OddsRatios=OREst2;
TITLE 'CONDITIONAL LOGISTIC MODEL, NHL ON EBV_CLASS IN LESS THAN 3 YEARS'; 
		PROC LOGISTIC DATA=GETHREE;
			STRATA MATCH;
			CLASS  EBV_CLASS (REF=FIRST)/PARAM=REF ; 
			MODEL CACONEW (EVENT='1')=EBV_CLASS; 
			EXACT EBV_CLASS/ESTIMATE=BOTH; 
		RUN;
ODS OUTPUT CLOSE;

DATA WORK.ODDS_combo2;
			LENGTH OR_CI $25;	
			SET WORK.OREst2;	
			VARIABLE=EFFECT; 

			RR=PUT(OddsRatioEst, 4.2);
			Lcl=PUT(LOWERCL, 4.2);
			Ucl=PUT(UPPERCL, 4.2);

			OR_CI=RR||" ("||Lcl||", "||Ucl||")";   
			OUTCOME="ALL HEME"; 

			KEEP VARIABLE OR_CI OUTCOME ;
		RUN;

*MACRO FOR CONDITIONAL LOGISTIC REGRESSION MODELS FOR ANTIGEN QUARTILES*;
%MACRO COND_LOG (DAT=, EXPOSURE=, OUTCOME=, NUMBER=);

ODS OUTPUT ODDSRATIOS=ONE&NUMBER;
PROC LOGISTIC DATA=&DAT;
STRATA MATCH;
CLASS &EXPOSURE (REF='1. <=25% ')/PARAM=REF ;
MODEL &OUTCOME (EVENT='1') = &EXPOSURE;
EXACT &EXPOSURE/ ESTIMATE=BOTH;
RUN;
ODS OUTPUT CLOSE;

DATA TWO&NUMBER;	
			SET ONE&NUMBER;	
			VARIABLE=EFFECT;  

			OR=PUT(OddsRatioEst, 4.2);
			Lcl=PUT(LOWERCL, 4.2);
			Ucl=PUT(UPPERCL, 4.2);

			OR_CI=OR||" ("||Lcl||", "||Ucl||")";   
			OUTCOME="&OUTCOME"; 

			KEEP VARIABLE OR_CI OUTCOME;
		RUN;

PROC SQL;
			INSERT INTO TWO&NUMBER VALUES("  "," ", " "); *INSERT DEFAULT OR FOR REFERENT;
		QUIT;

PROC APPEND BASE=COND_LOG&NUMBER DATA=TWO&NUMBER FORCE;
		RUN;

%MEND COND_LOG; 

*ANTIGEN QUARTILES IN LESS THAN 3 YEARS SUBSET*;
%COND_LOG (DAT=LTTHREE, EXPOSURE=ZEBRA75, OUTCOME=CACONEW, NUMBER=1);
%COND_LOG (DAT=LTTHREE,EXPOSURE=EBNA_TRU75, OUTCOME=CACONEW, NUMBER=1);
%COND_LOG (DAT=LTTHREE,EXPOSURE=VCA_p1875, OUTCOME=CACONEW, NUMBER=1);
%COND_LOG (DAT=LTTHREE,EXPOSURE=EA_D75, OUTCOME=CACONEW, NUMBER=1);

*ANTIGEN QUARTILES IN 3 OR MORE YEARS SUBSET*;
%COND_LOG (DAT=GETHREE, EXPOSURE=ZEBRA75, OUTCOME=CACONEW, NUMBER=2);
%COND_LOG (DAT=GETHREE,EXPOSURE=EBNA_TRU75, OUTCOME=CACONEW, NUMBER=2);
%COND_LOG (DAT=GETHREE,EXPOSURE=VCA_p1875, OUTCOME=CACONEW, NUMBER=2);
%COND_LOG (DAT=GETHREE,EXPOSURE=EA_D75, OUTCOME=CACONEW, NUMBER=2);

ODS RTF FILE="D:\USER\JBLASE\EBV Program Review\OUTPUT\STRATIFIED 3 YEARS - ORS.RTF";
TITLE 'ORS EBV CLASS - LESS THAN 3 YEARS';
PROC PRINT DATA=ODDS_COMBO; RUN;
TITLE 'ORS EBV CLASS - 3 OR MORE YEARS';
PROC PRINT DATA=ODDS_COMBO2; RUN;
TITLE 'ANTGEN QUARTILE ORS - LESS THAN 3 YEARS';
PROC PRINT DATA=COND_LOG1; RUN;
TITLE 'ANTGEN QUARTILE ORS - 3 OR MORE YEARS';
PROC PRINT DATA=COND_LOG2; RUN;
ODS RTF CLOSE;
