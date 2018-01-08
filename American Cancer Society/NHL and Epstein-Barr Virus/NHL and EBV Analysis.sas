/*============================================================================================================
  Project Name     : NHL & EBV Analysis
  PI               : LAUREN TERAS
  Last update      : 6/28/2013 - CHANGED SO IT WOULD RUN ON JENNY BLASE S-DRIVE
  					 7/15/2013 - JB REWORKED ANALYSIS
  ===========================================================================================================*/
OPTIONS MPRINT;
TITLE 'EBV AND NHL ANALYSIS' ; 
    FOOTNOTE1  "Program: D:\USER\JBLASE\EBV\EBV and NHL Analysis.sas"; 
    FOOTNOTE2  "Last run by JENNY BLASE on &sysdate";

LIBNAME EBV 'D:\USER\JBLASE\EBV Program Review\DATA'; 

%include 'D:\USER\JBLASE\MACROS\DESCRIPTIVE_TBL.sas';

PROC FORMAT; 

VALUE  CACOF   
	        1 = "1: CASE"
			0 = "0: CONTROL"; 

VALUE $ SMOKE '1' = 'NEVER'
			  '2' = 'CURRENT'
			  '3' = 'FORMER'
			  '9' = 'MISSING';

VALUE BMIWHO 	0='0: <25.0 (UNDER/NORMAL)'				
			 	1='1: 25.0-<30.0 (OVERWEIGHT)'
			 	2='2: >=30.0 (OBESE)'
			 	9='9: UNKNOWN'; 

VALUE $ REGIONF   
				'1' = '1: Northeast' 
				'2' = '2: West'      
				'3' = '3: South'     
				'4' = '4: MidWest'; 

VALUE EDUCAF 
                1 = '1: Less than high school'
				2 = '2: High school/missing education'
				3 = '3: Some college/vocational school'
				4 = '4: College/graduate school'; 

VALUE QUARTS    1 = '<= 25 Percentile'
                2 = '25-75 Percentile'
			   	3 = '>75   Percentile';

VALUE NPF      0 = '0. Seronegative'
               1 = '1. Seropositive'; 
 
VALUE EXCLUSION 1 = 'Missing lab data'
				2 = 'Hodgkin Lymphoma'
				3 = 'Multiple Myeloma'
				.='Final Cohort';

VALUE SUB1CAT	0 = 'Control'
				1 = 'DLBCL'
				2 = 'CLL/SLL'
				3 = 'Follicular'
				4 = 'Other NHL';

VALUE SEX	0 = 'Female'
			1 = 'Male';

VALUE ALC	1 = '0 DRINKS/DAY'
			2 = '<=1 DRINKS/DAY'
			3 = '>1 DRINKS/DAY'
			9 = 'MISSING';

VALUE RACENEW 1 = 'White'
			  2 = 'Black'
			  3 = 'Other/Missing';

RUN;

*************************************************************;
*				DESCRIPTIVE TABLES & FREQUENCIES 			*;
*************************************************************;

*DESCRIPTIVE TABLE & FREQUENCIES*;

%DESCRIPTIVE_TBL (DAT= EBV.FINALCOHORT, EXPOSURE=CACONEW, COVCAT= SEX SMK99 ALC99 REGION92 BMIWHO EDUCA,
                      COVCONT= AGELL YEARDS AGEDX, MISSVAL=, ORDER=FORMATTED, ROWCOL=COL,CHI=1,LIMIT=1,
				      PERDEC=0.1, CONTMEAS=MEANSD , PRINTOUT=0,TOTAL=0,COLWDTH=40,STARTLAB=,TITL= Population Characteristics by Caco Status,
				      ODSTYPE=RTF,ODSSTYLE=Minimal,ODSPATH= D:\USER\JBLASE\EBV Program Review\NEW OUTPUT\TABLE 1 - &SYSDATE..RTF,
                      ORIENT=LANDSCAPE,permdata= ); 

*CALCULATING P-VALUE FOR AGE AT BLOOD DRAW FOR TABLE 1*;					  
ODS RTF FILE="D:\USER\JBLASE\EBV Program Review\NEW OUTPUT\TABLE 1 T-TEST.RTF";
PROC TTEST DATA=EBV.FINALCOHORT;
CLASS CACONEW;
VAR AGELL;
RUN;
ODS RTF CLOSE;

***STATISTICS IN METHODS SECTION***;  
ODS RTF FILE="D:\USER\JBLASE\EBV Program Review\NEW OUTPUT\Methods Statistics -&SYSDATE..RTF";

*CASE ASCERTAINMENT (PG. 4) - NONE WERE VERIFIED BY DEATH RECORDS SO THAT PORTION OF THE CODE WAS DELETED*;
TITLE 'Case Ascertainment'; 
PROC FREQ DATA=EBV.FINALCOHORT; 
WHERE CACONEW=1;
TABLE  CACONEW*VERFY*DATASRC/LIST MISSING NOPERCENT;
RUN;

*NHL CASE FREQUENCIES BY SUBTYPE AND HISTOLOGY CODES (PG. 4-5)*;
TITLE 'NHL Case Frequencies Subtypes by Histology Codes';
PROC FREQ DATA = EBV.FINALCOHORT;
WHERE CACONEW=1;
TABLES SUB1CAT*HISTOGY/LIST NOPERCENT NOCOL NOROW;
RUN;

TITLE;
ODS RTF CLOSE;

*EXCLUSION OF THE 3 CONTROLS THAT DID NOT HAVE LAB DATA (ZEBRA=.) AND THE 1 CASE THAT MATCHED 2 OF THE CONTROLS (BARCODE='073529-209') (PG. 8)*;
ODS RTF STYLE=JOURNAL BODYTITLE FILE= "D:\USER\JBLASE\EBV Program Review\NEW OUTPUT\Results Statistics -&SYSDATE..RTF"; 
OPTIONS ORIENTATION=PORTRAIT MISSING = " " NODATE;

*EXCLUSIONS (PG. 8)*;
TITLE 'Exclusions';
PROC FREQ DATA = COHORT;
WHERE EXCLUSION=1;
TABLES ID*ZEBRA*BARCODE*MATCH*CACONEW/LIST MISSING;
RUN;

*N (PG. 8)*;
TITLE 'Case/Control Status';
PROC FREQ DATA = EBV.FINALCOHORT;
TABLES CACONEW;
RUN;

*SEROPOSITIVITY STATS (PG. 8)*;
TITLE 'Seropositivity Statistics';
PROC FREQ DATA=EBV.FINALCOHORT;  
	TABLE CACONEW*EBV_CLASS/NOPERCENT NOCOL;
	FORMAT CACONEW CACOF. EBV_CLASS NPF.; 
RUN; 

*SEROPOSITIVITY*ANTIGEN STATS (PG. 8)*;
TITLE 'Seropositivity by Antigen';
PROC FREQ DATA = EBV.FINALCOHORT;  
	TABLE EBV_CLASS*(ZEBRA_NP EBNA_TRU_NP EA_D_NP VCA_p18_NP)/NOROW NOCOL;  
	FORMAT EBV_CLASS ZEBRA_NP EBNA_TRU_NP EA_D_NP VCA_p18_NP NPF.;
RUN; 

TITLE;
ODS RTF CLOSE;

ODS RTF FILE= "D:\USER\JBLASE\EBV Program Review\NEW OUTPUT\Blood Draw to Dx -&SYSDATE..RTF"; 
*BLOOD DRAW TO DIAGNOSIS RANGE (YEARS)*;
TITLE 'Blood draw to diagnosis date in years';
PROC UNIVARIATE DATA=EBV.FINALCOHORT;
WHERE CACONEW=1;
VAR YEARDS;
RUN;

TITLE;
ODS RTF CLOSE;

*NOTE: THIS WAS FROM THE NHL AND POLYOMAVIRUS ANALYSIS - PLEASE SEE THAT ANALYSIS FOR DETAILS*;
*There was no association between BKV seropositivity and NHL risk (+ vs.-: OR=0.83, 95% CI: 0.53�1.29), nor were there any associations between antibody level and risk.*;


*TABLE 2 FREQUENCIES*;
*STATS FOR ALL NHL*EBV_STATUS ARE IN THE RESULTS STATISTICS FILE - SEE SEROPOSITIVITY STATISTICS SECTION*;
ODS RTF FILE= "D:\USER\JBLASE\EBV Program Review\NEW OUTPUT\Table 2 Frequencies.RTF"; 

*SEROPOSITIVITY AND ANTIGEN QUARTILE FREQUENCIES IN CONTROLS (TABLE 2)*;
TITLE 'SEROPOSITIVITY AND ANTIGEN QUARTILE FREQUENCIES IN CONTROLS';
PROC FREQ DATA=EBV.FINALCOHORT;
WHERE CACONEW=0;
TABLE EBV_CLASS ZEBRA75 EBNA_TRU75 EA_D75 VCA_p1875/NOPERCENT NOCOL NOROW NOCOL;
FORMAT EBV_CLASS NPF.; 
RUN; 

TITLE 'SEROPOSITIVITY IN MAIN NHL SUBTYPES';
PROC FREQ DATA=EBV.FINALCOHORT;
TABLE MAINNHL*EBV_CLASS/NOPERCENT NOCOL NOROW NOCOL;
FORMAT MAINNHL CACOF. EBV_CLASS NPF.; 
RUN; 

TITLE 'ANTIGEN QUARTILE FREQUENCIES IN MAIN NHL SUBTYPES';
PROC FREQ DATA=EBV.FINALCOHORT;
WHERE MAINNHL=1;
TABLE MAINNHL*(ZEBRA75 EBNA_TRU75 EA_D75 VCA_p1875)/MISSING NOROW NOCOL NOPERCENT NOCUM;
FORMAT MAINNHL CACOF.;
RUN;

TITLE 'Seropositivity in NHL Subtypes';
PROC FREQ DATA=EBV.FINALCOHORT;
WHERE SUB1CAT GT 0;
TABLES SUB1CAT*EBV_CLASS/NOROW NOCOL NOPERCENT NOCUM; 
FORMAT EBV_CLASS NPF.;
RUN;

TITLE 'Quartile frequencies for all cases (Table 2)';
PROC FREQ DATA=EBV.FINALCOHORT; 
	WHERE SUB1CAT GT 0; 
	TABLE SUB1CAT*(ZEBRA75 EBNA_TRU75 EA_D75 VCA_p1875)/MISSING  NOROW NOCOL NOPERCENT; 
RUN;

TITLE;
ODS RTF CLOSE;
 
*ALL NHL ON EBV CLASS (SEROPOSITIVITY STATUS) - TOP ROW, 1ST COLUMN OF TABLE 2*;
TITLE 'Conditional Logistic Model, NHL (EXCLUDE MM) ON EBV_CLASS'; 
ODS OUTPUT ODDSRATIOS=JB;
PROC LOGISTIC DATA=EBV.FINALCOHORT;
			STRATA MATCH;
			CLASS  EBV_CLASS (REF=FIRST)/PARAM=REF ; 
			MODEL CACONEW (EVENT='1') = EBV_CLASS;
			EXACT EBV_CLASS / estimate=both; 
		RUN;
ODS OUTPUT CLOSE;

DATA JB2;	
			SET JB;	
			LENGTH OUTCOME $8;

			VARIABLE=EFFECT; 

			OR=PUT(OddsRatioEst, 4.2);
			Lcl=PUT(LOWERCL, 4.2);
			Ucl=PUT(UPPERCL, 4.2);

			OR_CI=OR||" ("||Lcl||", "||Ucl||")";
			OUTCOME="ALL NHL"; 

			KEEP VARIABLE OR_CI OUTCOME;
		RUN;

PROC APPEND BASE=JB_FINAL DATA=JB2 FORCE;
		RUN;

*MAIN NHL ON EBV CLASS (SEROPOSITIVITY STATUS) - TOP ROW, 2ND COLUMN - TABLE 2*;

TITLE 'Conditional Logistic Model, Main NHL ON EBV_CLASS'; 
ODS OUTPUT ODDSRATIOS=JB;
PROC LOGISTIC DATA=EBV.FINALCOHORT;
			STRATA MATCH;
			CLASS  EBV_CLASS (REF=FIRST)/PARAM=REF ; 
			MODEL MAINNHL (EVENT='1') = EBV_CLASS;
			EXACT EBV_CLASS / estimate=both; 
		RUN;
ODS OUTPUT CLOSE;

DATA JB2;	
			SET JB;	
			LENGTH OUTCOME $8;
			VARIABLE=EFFECT; 

			OR=PUT(OddsRatioEst, 4.2);
			Lcl=PUT(LOWERCL, 4.2);
			Ucl=PUT(UPPERCL, 4.2);

			OR_CI=OR||" ("||Lcl||", "||Ucl||")"; 
			OUTCOME="MAIN NHL"; 

			KEEP VARIABLE OR_CI OUTCOME;
	RUN;
		PROC APPEND BASE=JB_FINAL DATA=JB2 FORCE;
		RUN;


*POLYTOMOUS LOGISTIC REGRESSION FOR NHL SUBCATEGORIES ON EBV_CLASS - TOP ROW OF TABLE 2*;
ODS OUTPUT  OddsRatios =JB3;
TITLE "MULTINOMIAL REGRESSION OF SEROPOSITIVITY STATUS";  
PROC LOGISTIC DATA = EBV.FINALCOHORT DESCENDING;
CLASS AGELL_CAT RACENEW/PARAM=REF REF=FIRST;
MODEL SUB1CAT (REF='Control')= EBV_CLASS SEX AGELL_CAT DRAWDATE_CAT RACENEW/LINK=GLOGIT RL; 
RUN;
ODS OUTPUT CLOSE;

DATA JB4;
	SET JB3 (WHERE=(SUBSTR(EFFECT,1,9)='EBV_class'));

			LENGTH OR_CI $25;	
			VARIABLE=EFFECT; 

			OR=PUT(OddsRatioEst, 4.2);
			Lcl=PUT(LOWERCL, 4.2);
			Ucl=PUT(UPPERCL, 4.2);

			OR_CI=OR||" ("||Lcl||", "||Ucl||")";   
			OUTCOME=RESPONSE; 

			KEEP VARIABLE OR_CI OUTCOME ;

RUN;

*ALL NHL AND NHL SUBTYPES ON EBV CLASS*;
ODS RTF FILE="D:\USER\JBLASE\EBV Program Review\NEW OUTPUT\ALL NHL AND SUBTYPES ON EBV CLASS &SYSDATE..RTF";
TITLE 'ALL NHL AND MAIN NHL REGRESSED ON EBV CLASS (SEROPOSITIVITY)';
PROC PRINT DATA=JB_FINAL; RUN;
TITLE 'NHL SUBTYPES REGRESSED ON EBV CLASS (SEROPOSITIVITY)';
PROC PRINT DATA=JB4; RUN;
ODS RTF CLOSE;


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

*MACRO FOR UNCONDITIONAL POLYTOMOUS LOGISTIC REGRESSION MODELS FOR ANTIGEN QUARTILES*;
%MACRO POLY (EXPOSURE=, NUMBER=); 

ODS OUTPUT  OddsRatios =THREE&NUMBER;
TITLE "MULTINOMIAL REGRESSION OF &EXPOSURE";  
PROC LOGISTIC DATA = EBV.FINALCOHORT DESCENDING;
CLASS &EXPOSURE (PARAM=REF REF='<= 25 Percentile') AGELL_CAT RACENEW/PARAM=REF REF=FIRST;
MODEL SUB1CAT (REF='Control')= &EXPOSURE SEX AGELL_CAT DRAWDATE_CAT RACENEW/LINK=GLOGIT RL;
RUN;
ODS OUTPUT CLOSE;

DATA FOUR&NUMBER;
	SET THREE&NUMBER (WHERE=(SUBSTR(EFFECT,1,LENGTH("&EXPOSURE"))="&EXPOSURE"));

RUN;

PROC SORT DATA=FOUR&NUMBER OUT=FIVE&NUMBER; BY RESPONSE; RUN;

DATA FIVE&NUMBER;
			LENGTH OR_CI $25;	
			SET FOUR&NUMBER;	
			VARIABLE=EFFECT; 

			RR=PUT(OddsRatioEst, 4.2);
			Lcl=PUT(LOWERCL, 4.2);
			Ucl=PUT(UPPERCL, 4.2);

			OR_CI=RR||" ("||Lcl||", "||Ucl||")";   
			OUTCOME=RESPONSE; 

			KEEP VARIABLE OR_CI OUTCOME ;
		RUN;

		PROC SQL;
			INSERT INTO FIVE&NUMBER VALUES("  "," ", " "); *INSERT DEFAULT OR FOR REFERENT;
		QUIT;

		PROC APPEND BASE=POLY&NUMBER DATA=FIVE&NUMBER FORCE;
		RUN;

%MEND POLY;

*CONDITIONAL LOGISTIC REGRESSION FOR THE MAIN SUBTYPES OF NHL, EXCULDING MM AND OTHER NHL (PAGE 8 AND IN ABSTRACT)*;
%COND_LOG (DAT=EBV.FINALCOHORT, EXPOSURE=ZEBRA75, OUTCOME=MAINNHL, NUMBER=1);
%COND_LOG (DAT=EBV.FINALCOHORT, EXPOSURE=EBNA_TRU75, OUTCOME=MAINNHL, NUMBER=1);
%COND_LOG (DAT=EBV.FINALCOHORT, EXPOSURE=VCA_p1875, OUTCOME=MAINNHL, NUMBER=1);
%COND_LOG (DAT=EBV.FINALCOHORT, EXPOSURE=EA_D75, OUTCOME=MAINNHL, NUMBER=1);

ODS RTF FILE="D:\USER\JBLASE\EBV Program Review\NEW OUTPUT\CONDITIONAL LOGISTIC REGRESSION - MAIN NHL SUBTYPES ON ANTIGEN QUARTILES &SYSDATE..RTF";
TITLE 'CONDITIONAL LOGISTIC REGRESSION - MAIN NHL SUBTYPES REGRESSED ON ANTIGEN QUARTILES';
PROC PRINT DATA=COND_LOG1;
RUN;
ODS RTF CLOSE;

*CONDITIONAL LOGISTIC REGRESSION FOR ALL NHL FOR ANTIGEN QUARTILES (LEFT COLUMN IN TABLE 2)*;
%COND_LOG (DAT=EBV.FINALCOHORT, EXPOSURE=ZEBRA75, OUTCOME=CACONEW, NUMBER=2);
%COND_LOG (DAT=EBV.FINALCOHORT, EXPOSURE=EBNA_TRU75, OUTCOME=CACONEW, NUMBER=2);
%COND_LOG (DAT=EBV.FINALCOHORT, EXPOSURE=VCA_p1875, OUTCOME=CACONEW, NUMBER=2);
%COND_LOG (DAT=EBV.FINALCOHORT, EXPOSURE=EA_D75, OUTCOME=CACONEW, NUMBER=2);

*POLYTOMOUS LOGISTIC REGRESSION FOR NHL SUBTYPES AND ANTIGEN QUARTILES*;
%POLY (EXPOSURE=ZEBRA75, NUMBER=5);
%POLY (EXPOSURE=EBNA_TRU75, NUMBER=5);
%POLY (EXPOSURE=EA_D75, NUMBER=5);
%POLY (EXPOSURE=VCA_p1875, NUMBER=5);

ODS RTF FILE="D:\USER\JBLASE\EBV Program Review\NEW OUTPUT\ALL NHL AND NHL SUBTYPES ON ANTIGEN QUARTILES - TABLE 2 &SYSDATE..RTF";
TITLE 'ALL NHL REGRESSED ON ANTIGEN QUARTILES - TABLE 2';
PROC PRINT DATA=COND_LOG2; RUN;
TITLE 'NHL SUBTYPES ON ANTIGEN QUARTILES - TABLE 2';
PROC PRINT DATA=POLY5; RUN;
ODS RTF CLOSE;


*************;
*	SPLINES	*;
*************;
*RUN LOCALLY*;

LIBNAME EBV 'S:\USER\JBLASE\EBV Program Review\DATA'; 
%INCLUDE 'S:\USER\JBLASE\Macros\lgtphcurv9.sas';
*LIBNAME LIBRARY 'S:\USER\JBLASE'; 
OPTIONS MPRINT;

*Evaluation of restricted cubic splines did not suggest any nonlinearity in the associations of EBV antibody levels and NHL risk*;

ODS RTF FILE="S:\USER\JBLASE\EBV Program Review\BRIAN\OUTPUT\ALL SPLINES.RTF"; 

*ZEBRA*;
TITLE2 'ZEBRA';
%lgtphcurv9(DATA=EBV.FINALCOHORT, MODEL=CONDLOG, STRATA=MATCH, TIME=TIME, CASE=CACONEW, EXPOSURE=ZEBRA, 
            SELECT=1, REFVAL=MIN, CI=1, PLOT=2, FOOTER=NONE, KLINES=T, MODPRINT=F, PRINTCV=F, DISPLAYX=T)

*EBNA*;
TITLE2 'EBNA';
%lgtphcurv9(DATA=EBV.FINALCOHORT, MODEL=CONDLOG, STRATA=MATCH, TIME=TIME, CASE=CACONEW, EXPOSURE=EBNA_TRUNCATED, 
            SELECT=1, REFVAL=MIN, CI=1, PLOT=2, FOOTER=NONE, KLINES=T, MODPRINT=F, PRINTCV=F, DISPLAYX=T)

*EA_D*;
TITLE2 'EA_D';
%lgtphcurv9(DATA=EBV.FINALCOHORT, MODEL=CONDLOG, STRATA=MATCH, TIME=TIME, CASE=CACONEW, EXPOSURE=EA_D, 
            SELECT=1, REFVAL=MIN, CI=1, PLOT=2, FOOTER=NONE, KLINES=T, MODPRINT=F, PRINTCV=F, DISPLAYX=T)

*VCA*;
TITLE2 'VCA';
%lgtphcurv9(DATA=EBV.FINALCOHORT, MODEL=CONDLOG, STRATA=MATCH, TIME=TIME, CASE=CACONEW, EXPOSURE=VCA_p18, 
            SELECT=1, REFVAL=MIN, CI=1, PLOT=2, FOOTER=NONE, KLINES=T, MODPRINT=F, PRINTCV=F, DISPLAYX=T)

ODS RTF CLOSE;

