OPTIONS MPRINT;
LIBNAME PLYMA 'D:\USER\JBLASE\NHL & Polyomavirus\Jenny\PROGRAM REVIEW\DATA';
LIBNAME LIBRARY 'D:\USER\JBLASE'; 

*METHODS STATISTICS*;

ODS RTF FILE="D:\USER\JBLASE\NHL & Polyomavirus\Jenny\PROGRAM REVIEW\OUTPUT\Methods Statistics -&SYSDATE..RTF";
*CASE ASCERTAINMENT*;
TITLE 'Case Ascertainment'; 
PROC FREQ DATA=PLYMA.FINALCOHORT; 
WHERE CACONEW=1;
TABLE  CACONEW*VERFY*DATASRC/LIST MISSING NOPERCENT;
RUN;

ODS RTF CLOSE;

*SEE QC PROGRAM FOR ICC'S AND CV'S*;

*RESULTS STATISTICS*;

ODS RTF FILE="D:\USER\JBLASE\NHL & Polyomavirus\Jenny\PROGRAM REVIEW\OUTPUT\Results Statistics -&SYSDATE..RTF";

TITLE 'CASE AND CONTROL FREQUENCIES';
PROC FREQ DATA=PLYMA.FINALCOHORT;
TABLES CACONEW; 
RUN;

*MEDIAN AGE AND AGE RANGE OF PARTICIPANTS AT BLOOD DRAW*;
TITLE 'MEDIAN AGE AND AGE RANGE OF PARTICIPANTS AT BLOOD DRAW';
PROC UNIVARIATE DATA=PLYMA.FINALCOHORT;
VAR AGELL;
RUN;

*AVERAGE AGE OF DIAGNOSIS FOR CASES*;
TITLE 'AVERAGE AGE OF DIAGNOSIS FOR CASES';
PROC UNIVARIATE DATA=PLYMA.FINALCOHORT;
WHERE CACONEW=1;
VAR AGEDX;
RUN;

*SEROPREVALENCE AMONGST CASES*; 
TITLE 'SEROPREVALENCE AMONGST CASES';
PROC FREQ DATA=PLYMA.FINALCOHORT;
WHERE CACONEW=1;
TABLES BK_VP1_NP JC_VP1_NP MCV344_VP1_NP HPyV6_VP1_NP HPyV7_VP1_NP WU_VP1_NP KI_VP1_NP TSV_VP1_NP/NOCUM; *ALL NHL CASES*;
RUN;

*SEROPREVALENCE AMONGST CONTROLS*; 
TITLE 'SEROPREVALENCE AMONGST CONTROLS';
PROC FREQ DATA=PLYMA.FINALCOHORT;
WHERE CACONEW=0;
TABLES BK_VP1_NP JC_VP1_NP MCV344_VP1_NP HPyV6_VP1_NP HPyV7_VP1_NP WU_VP1_NP KI_VP1_NP TSV_VP1_NP/NOCUM; *ALL NHL CASES*;
RUN;

PROC NPAR1WAY DATA=PLYMA.FINALCOHORT WILCOXON;
  CLASS CACONEW;
  VAR BK_VP1 JC_VP1 WU_VP1 KI_VP1 MCV344_VP1 HPyV6_VP1 HPyV7_VP1 TSV_VP1;
  TITLE "WILCOXON TEST ON MEDIANS BETWEEN CASES AND CONTROLS"; 
RUN; 

ODS RTF CLOSE;

*******************************************;
*      DESCRIPTIVE STATS IN RESULTS       *;
*******************************************;

%include 'D:\USER\JBLASE\MACROS\DESCRIPTIVE_TBL.sas';

%DESCRIPTIVE_TBL (DAT=PLYMA.FINALCOHORT, EXPOSURE=CACONEW,COVCAT= GENDER SMK97 ALC99 REGION92 BMIWHO EDUCA ,
                      COVCONT= AGELL YEARDS AGEDX, MISSVAL=, ORDER=FORMATTED, ROWCOL=COL,CHI=1,LIMIT=1,
				      PERDEC=0.1, CONTMEAS=MEANSD , PRINTOUT=0,TOTAL=0,COLWDTH=40,STARTLAB=,TITL= Population Characteristics of Polyomavirus Infection and NHL Cohort,
				      ODSTYPE=RTF,ODSSTYLE=Minimal,ODSPATH= D:\USER\JBLASE\NHL & Polyomavirus\Jenny\PROGRAM REVIEW\OUTPUT\DESCRIPTIVE TABLE - &SYSDATE..RTF,
                      ORIENT=LANDSCAPE,permdata= );


********************;
*      TABLE 1     *;
********************;

*CASE AND CONTROL QUARTILE FREQUENCIES BY NHL SUBTYPE*;
*USE MMNHL VARIABLE. DONT INCLUDE MM IN OTHER NHL PER LT 9/3/13*;

ODS RTF FILE="D:\USER\JBLASE\NHL & Polyomavirus\Jenny\PROGRAM REVIEW\OUTPUT\TABLE 1 FREQUENCIES - &SYSDATE..RTF";
TITLE 'CASE/CONTROL FREQUENCIES BY ANTIGEN FOR TABLE 1';
PROC FREQ DATA=PLYMA.FINALCOHORT;
TABLES CACONEW*(BK_VP1_NP BKV_QPOS JC_VP1_NP JCV_QPOS WU_VP1_NP WU_QPOS KI_VP1_NP KI_QPOS MCV344_VP1_NP MCV_QPOS HPyV6_VP1_NP HPyV6_QPOS HPyV7_VP1_NP HPyV7_QPOS TSV_VP1_NP TSV_QPOS)/LIST NOCUM NOPERCENT NOCOL NOROW;
RUN;
ODS RTF CLOSE;

***********************************************************;
* CONDITIONAL LOGISTIC REGRESSION MACRO - ALL NHL         *;
***********************************************************;

%MACRO COND_LOG (DATASET=, EXPOSURE=, REF=, OUTCOME=, CATEGORIES=, NUMBER=, OR=);

%IF &OR=1 %THEN %DO;
ODS OUTPUT ODDSRATIOS=ONE&NUMBER;
TITLE "CONDITIONAL LOGISTIC REGRESSION OF ALL NHL ON &EXPOSURE"; 
PROC LOGISTIC DATA=&DATASET;
STRATA MATCH;

%IF &CATEGORIES=1 %THEN %DO;
	CLASS &EXPOSURE (REF=&REF)/PARAM=REF;
%END;

MODEL &OUTCOME (EVENT='1: CASE') = &EXPOSURE;
RUN;
ODS OUTPUT CLOSE;

DATA TWO&NUMBER;	
			LENGTH VARIABLE $20;
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
%END;

%ELSE %DO; 
ODS OUTPUT PARAMETERESTIMATES=TCOND&NUMBER;
TITLE "TREND TEST - CONDITIONAL LOGISTIC REGRESSION OF ALL NHL ON &EXPOSURE";  
PROC LOGISTIC DATA = &DATASET;
	STRATA MATCH;
	MODEL &OUTCOME (EVENT='1: CASE') = &EXPOSURE;
RUN;
ODS OUTPUT CLOSE;

DATA EIGHT&NUMBER;
	SET TCOND&NUMBER;

	PTREND=PUT(ROUND(ProbChiSq,0.01),4.2); 
	OUTCOME="ALL NHL"; 

KEEP VARIABLE PTREND OUTCOME;

RUN;

PROC APPEND BASE=TREND&NUMBER DATA=EIGHT&NUMBER FORCE;
		RUN;
%END;

%MEND COND_LOG;

***********************************************************;
* CONDITIONAL LOGISTIC REGRESSION - ALL NHL               *;
***********************************************************;
*SEROPOSITIVE/SERONEGATIVE EXPOSURE*;
%COND_LOG (EXPOSURE=BK_VP1_NP, DATASET=PLYMA.FINALCOHORT, OUTCOME=CACONEW, NUMBER=1, OR=1)
%COND_LOG (EXPOSURE=JC_VP1_NP, DATASET=PLYMA.FINALCOHORT, OUTCOME=CACONEW, NUMBER=1, OR=1)
%COND_LOG (EXPOSURE=WU_VP1_NP, DATASET=PLYMA.FINALCOHORT, OUTCOME=CACONEW, NUMBER=1, OR=1)
%COND_LOG (EXPOSURE=KI_VP1_NP, DATASET=PLYMA.FINALCOHORT, OUTCOME=CACONEW, NUMBER=1, OR=1)
%COND_LOG (EXPOSURE=MCV344_VP1_NP, DATASET=PLYMA.FINALCOHORT, OUTCOME=CACONEW, NUMBER=1, OR=1)
%COND_LOG (EXPOSURE=HPyV6_VP1_NP, DATASET=PLYMA.FINALCOHORT, OUTCOME=CACONEW, NUMBER=1, OR=1)
%COND_LOG (EXPOSURE=HPyV7_VP1_NP, DATASET=PLYMA.FINALCOHORT, OUTCOME=CACONEW, NUMBER=1, OR=1)
%COND_LOG (EXPOSURE=TSV_VP1_NP, DATASET=PLYMA.FINALCOHORT, OUTCOME=CACONEW, NUMBER=1, OR=1)
;

*CONDITIONAL LOGISTIC MODELS FOR SEROPOSITIVE QUARTILES*;
%COND_LOG (EXPOSURE=BKV_QPOS, DATASET=PLYMA.FINALCOHORT, NUMBER=1, CATEGORIES=1, REF='1. <=25%', OUTCOME=CACONEW, OR=1)
%COND_LOG (EXPOSURE=JCV_QPOS, DATASET=PLYMA.FINALCOHORT, NUMBER=1, CATEGORIES=1, REF='1. <=25%', OUTCOME=CACONEW, OR=1)
%COND_LOG (EXPOSURE=WU_QPOS, DATASET=PLYMA.FINALCOHORT, NUMBER=1, CATEGORIES=1, REF='1. <=25%', OUTCOME=CACONEW, OR=1)
%COND_LOG (EXPOSURE=KI_QPOS, DATASET=PLYMA.FINALCOHORT, NUMBER=1, CATEGORIES=1, REF='1. <=25%', OUTCOME=CACONEW, OR=1)
%COND_LOG (EXPOSURE=MCV_QPOS, DATASET=PLYMA.FINALCOHORT, NUMBER=1, CATEGORIES=1, REF='1. <=25%', OUTCOME=CACONEW, OR=1)
%COND_LOG (EXPOSURE=HPyV6_QPOS, DATASET=PLYMA.FINALCOHORT, NUMBER=1, CATEGORIES=1, REF='1. <=25%', OUTCOME=CACONEW, OR=1)
%COND_LOG (EXPOSURE=HPyV7_QPOS, DATASET=PLYMA.FINALCOHORT, NUMBER=1, CATEGORIES=1, REF='1. <=25%', OUTCOME=CACONEW, OR=1)
%COND_LOG (EXPOSURE=TSV_QPOS, DATASET=PLYMA.FINALCOHORT, NUMBER=1, CATEGORIES=1, REF='1. <=25%', OUTCOME=CACONEW, OR=1)
;

ODS RTF FILE="D:\USER\JBLASE\NHL & Polyomavirus\Jenny\PROGRAM REVIEW\OUTPUT\ALL NHL ORS - &SYSDATE..RTF";
TITLE 'CONDITIONAL ANALYSIS - ALL NHL - SERO+ VS SERO- AND QUARTILES AMONG SERO+';
PROC PRINT DATA=COND_LOG1; RUN;
ODS RTF CLOSE;

*TRYING CONDITIONAL ANALYSIS FOR HPyV6_QPOS USING PHREG BECAUSE OF ERROR MESSAGE USING LOGISTIC*;
*USING TIME VARIABLE THAT WAS USED FOR SPLINES*;
*THIS GAVE SAME RESULTS AS PROC LOGISTIC - MEMO ON THIS*;
ODS RTF FILE="D:\USER\JBLASE\NHL & Polyomavirus\Jenny\PROGRAM REVIEW\OUTPUT\NRRIDG ERROR - &SYSDATE..RTF";
PROC PHREG DATA=PLYMA.FINALCOHORT;
  CLASS HPyV6_QPOS (REF='1. <=25%')/PARAM=REF;
  MODEL TIME*CACONEW (0) = HPyV6_QPOS/TIES=DISCRETE RISKLIMITS;
  STRATA MATCH;
RUN;
ODS RTF CLOSE;

*TREND TEST - ALL NHL - QUARTILES AMONGST SEROPOSITIVES*;

%COND_LOG (EXPOSURE=BK_TREND_QPOS, DATASET=PLYMA.FINALCOHORT, NUMBER=1, OUTCOME=CACONEW)
%COND_LOG (EXPOSURE=JC_TREND_QPOS, DATASET=PLYMA.FINALCOHORT, NUMBER=1, OUTCOME=CACONEW)
%COND_LOG (EXPOSURE=WU_TREND_QPOS, DATASET=PLYMA.FINALCOHORT, NUMBER=1, OUTCOME=CACONEW)
%COND_LOG (EXPOSURE=KI_TREND_QPOS, DATASET=PLYMA.FINALCOHORT, NUMBER=1, OUTCOME=CACONEW)
%COND_LOG (EXPOSURE=MCV344_TREND_QPOS, DATASET=PLYMA.FINALCOHORT, NUMBER=1, OUTCOME=CACONEW)
%COND_LOG (EXPOSURE=HPyV6_TREND_QPOS, DATASET=PLYMA.FINALCOHORT, NUMBER=1, OUTCOME=CACONEW)
%COND_LOG (EXPOSURE=HPyV7_TREND_QPOS, DATASET=PLYMA.FINALCOHORT, NUMBER=1, OUTCOME=CACONEW)
%COND_LOG (EXPOSURE=TSV_TREND_QPOS, DATASET=PLYMA.FINALCOHORT, NUMBER=1, OUTCOME=CACONEW)
;

ODS RTF FILE="D:\USER\JBLASE\NHL & Polyomavirus\Jenny\PROGRAM REVIEW\OUTPUT\ALL NHL TRENDS - &SYSDATE..RTF";
TITLE 'TREND TEST - ALL NHL - QUARTILES AMONG SERO+';
PROC PRINT DATA=TREND1; RUN;
ODS RTF CLOSE;

*TABLE 1 QUARTILE MEDIAN NUMBERS WERE GENERATED IN COHORT PROGRAM. SEE DOCUMENT FOR OUTPUT: MEDIANS FOR TREND TEST - 16SEP14.RTF;

********************;
*      TABLE 2     *;
********************;

ODS RTF FILE="D:\USER\JBLASE\NHL & Polyomavirus\Jenny\PROGRAM REVIEW\OUTPUT\TABLE 2 FREQUENCIES - &SYSDATE..RTF";
TITLE 'SUBTYPE CASE/CONTROL FREQUENCIES BY ANTIGEN FOR TABLE 2';
PROC FREQ DATA=PLYMA.FINALCOHORT;
WHERE SUB1CAT NE 5;
TABLES SUB1CAT*(BK_VP1_NP BKV_MED JC_VP1_NP JCV_MED WU_VP1_NP WU_MED KI_VP1_NP KI_MED MCV344_VP1_NP MCV_MED HPyV6_VP1_NP HPyV6_MED HPyV7_VP1_NP HPyV7_MED TSV_VP1_NP TSV_MED)/LIST NOCUM NOPERCENT NOCOL NOROW;
RUN;
ODS RTF CLOSE;

***********************************************************************;
*               POLYTOMOUS LOGISTIC REGRESSION MACRO                  *;
***********************************************************************;

%MACRO POLY (EXPOSURE=, DATASET=, NUMBER=, OR=, CLASS= ); 

%IF &OR=1 %THEN %DO;

ODS OUTPUT  OddsRatios =THREE&NUMBER;
TITLE "MULTINOMIAL REGRESSION OF &EXPOSURE";  
PROC LOGISTIC DATA = &DATASET DESCENDING;
CLASS &EXPOSURE AGELL_CAT RACENEW/PARAM=REF REF=FIRST ORDER=INTERNAL;
MODEL SUB1CAT (REF='Control')= &EXPOSURE SEX_NEW AGELL_CAT DRAWDATE_CAT RACENEW/LINK=GLOGIT RL;
RUN;
ODS OUTPUT CLOSE;

DATA FOUR&NUMBER;
	SET THREE&NUMBER (WHERE=(SUBSTR(EFFECT,1,LENGTH("&EXPOSURE"))="&EXPOSURE"));

RUN;

PROC SORT DATA=FOUR&NUMBER OUT=FIVE&NUMBER; BY RESPONSE; RUN;

DATA SIX&NUMBER;
			LENGTH OR_CI $25 VARIABLE $15;	
			SET FIVE&NUMBER;	
			VARIABLE=EFFECT; 

			RR=PUT(OddsRatioEst, 4.2);
			Lcl=PUT(LOWERCL, 4.2);
			Ucl=PUT(UPPERCL, 4.2);

			OR_CI=RR||" ("||Lcl||", "||Ucl||")";   
			OUTCOME=RESPONSE; 

			KEEP VARIABLE OR_CI OUTCOME ;
		RUN;

		PROC SQL;
			INSERT INTO SIX&NUMBER VALUES("  "," ", " "); *INSERT DEFAULT OR FOR REFERENT;
		QUIT;

		PROC APPEND BASE=POLY&NUMBER DATA=SIX&NUMBER FORCE;
		RUN;

%END;

%ELSE %DO; 
ODS OUTPUT PARAMETERESTIMATES=TPOLY&NUMBER;
TITLE "TREND TEST - MULTINOMIAL REGRESSION OF &EXPOSURE";  
PROC LOGISTIC DATA = &DATASET DESCENDING;
	CLASS AGELL_CAT RACENEW/PARAM=REF REF=FIRST ORDER=INTERNAL;
	MODEL SUB1CAT (REF='Control')= &EXPOSURE SEX_NEW AGELL_CAT DRAWDATE_CAT RACENEW/LINK=GLOGIT RL;
RUN;
ODS OUTPUT CLOSE;

DATA SEVEN&NUMBER;
	SET TPOLY&NUMBER (WHERE=(SUBSTR(VARIABLE,1,LENGTH("&EXPOSURE"))="&EXPOSURE"));

	PTREND=PUT(ROUND(ProbChiSq,0.01),4.2); 
	OUTCOME=RESPONSE; 

KEEP VARIABLE PTREND OUTCOME;

RUN;

PROC APPEND BASE=POLYTREND&NUMBER DATA=SEVEN&NUMBER FORCE;
		RUN;
%END;
%MEND POLY;

*************************************************************;
*ANALYSIS USING MEDIAN CUTPOINTS - PER SUE AND LT 4/28/14	*;
*ONLY USING SEROPOSITIVES IN TWO GROUPS			 			*;
*************************************************************;

****************************************************************************;
*  POLYTOMOUS LOGISTIC REGRESSION FOR NHL SUBTYPES - SERO-/SERO+           *;
****************************************************************************;

%POLY (EXPOSURE=BK_VP1_NP, DATASET=PLYMA.FINALCOHORT, NUMBER=1, OR=1)
%POLY (EXPOSURE=JC_VP1_NP, DATASET=PLYMA.FINALCOHORT, NUMBER=1, OR=1)
%POLY (EXPOSURE=MCV344_VP1_NP, DATASET=PLYMA.FINALCOHORT, NUMBER=1, OR=1)
%POLY (EXPOSURE=HPyV6_VP1_NP, DATASET=PLYMA.FINALCOHORT, NUMBER=1, OR=1)
%POLY (EXPOSURE=HPyV7_VP1_NP, DATASET=PLYMA.FINALCOHORT, NUMBER=1, OR=1)
;

* POLYTOMOUS LOGISTIC REGRESSION FOR NHL SUBTYPES - USING MEDIANS *;			
%POLY (EXPOSURE=BKV_MED, DATASET=PLYMA.FINALCOHORT, NUMBER=1, OR=1)
%POLY (EXPOSURE=JCV_MED, DATASET=PLYMA.FINALCOHORT, NUMBER=1, OR=1)
%POLY (EXPOSURE=WU_MED, DATASET=PLYMA.FINALCOHORT, NUMBER=1, OR=1)
%POLY (EXPOSURE=KI_MED, DATASET=PLYMA.FINALCOHORT, NUMBER=1, OR=1)
%POLY (EXPOSURE=MCV_MED, DATASET=PLYMA.FINALCOHORT, NUMBER=1, OR=1)
%POLY (EXPOSURE=HPyV6_MED, DATASET=PLYMA.FINALCOHORT, NUMBER=1, OR=1)
%POLY (EXPOSURE=HPyV7_MED, DATASET=PLYMA.FINALCOHORT, NUMBER=1, OR=1)
;

ODS RTF FILE="D:\USER\JBLASE\NHL & Polyomavirus\Jenny\PROGRAM REVIEW\OUTPUT\NHL SUBTYPES ORS - &SYSDATE..RTF";
TITLE 'NHL SUBTYPES POLYTOMOUS UNCONDITIONAL - SERO+/SERO- AND MEDIANS';
PROC PRINT DATA=POLY1; 
WHERE OUTCOME NE 'Multiple Myeloma';
RUN;
ODS RTF CLOSE;

*RUNNING TSV_MED SEPERATLEY BC GOT BELOW WARNING MESSAGE. REMOVED DRAWDATE_CAT AND RERAN MODEL WITH BELOW CODE WHICH WAS ERROR FREE.*;

*WARNING: There is possibly a quasi-complete separation of data points. The maximum likelihood estimate may not exist. WARNING: The LOGISTIC procedure continues in 
spite of the above warning. Results shown are based on the last maximum likelihood iteration. Validity of the model fit is questionable.;

ODS OUTPUT ODDSRATIOS=TSV_OR;
PROC LOGISTIC DATA = plyma.finalcohort DESCENDING;
CLASS tsv_med AGELL_CAT RACENEW/PARAM=REF REF=FIRST ORDER=INTERNAL;
MODEL SUB1CAT (REF='Control')= tsv_med SEX_NEW AGELL_CAT RACENEW/LINK=GLOGIT RL;
RUN;
ODS OUTPUT CLOSE;

DATA TSV_OR2; 
SET TSV_OR;

WHERE SUBSTR(EFFECT,1,7)='TSV_MED'; 

LCL=ROUND(LOWERCL,0.01);
UCL=ROUND(UPPERCL, 0.01);
OR=ROUND(OddsRatioEst, 0.01);

RUN;

ODS RTF FILE="D:\USER\JBLASE\NHL & Polyomavirus\Jenny\PROGRAM REVIEW\OUTPUT\NHL SUBTYPES TSV MEDIANS - &SYSDATE..RTF";
TITLE 'NHL SUBTYPES POLYTOMOUS UNCONDITIONAL - TSV MEDIANS';

PROC PRINT DATA=TSV_OR2; 
WHERE RESPONSE NE 'Multiple Myeloma';
VAR EFFECT OR LCL UCL RESPONSE; 
RUN;

ODS RTF CLOSE;

*TABLE 2 MEDIAN NUMBERS WERE GENERATED IN COHORT PROGRAM. SEE DOCUMENT FOR OUTPUT: MEDIAN CUTPOINTS - 16SEP14;

*************;
*	SPLINES	*;
*************;
*RUN LOCALLY*;

LIBNAME PLYMA 'S:\USER\JBLASE\NHL & Polyomavirus\Jenny\PROGRAM REVIEW\DATA';
%INCLUDE 'S:\USER\JBLASE\Macros\lgtphcurv9.sas';
LIBNAME LIBRARY 'S:\USER\JBLASE'; 
OPTIONS MPRINT;

*Restricted cubic splines did not suggest any nonlinearity in the associations of polyomavirus antibody levels and risk of NHL or NHL subtypes*;

ODS RTF FILE="S:\USER\JBLASE\NHL & Polyomavirus\Jenny\PROGRAM REVIEW\OUTPUT\ALL SPLINES EXCEPT TSV - &SYSDATE..RTF"; 

*BKV*;
TITLE2 'BKV';
%lgtphcurv9(DATA=PLYMA.FINALCOHORT, MODEL=CONDLOG, STRATA=MATCH, TIME=TIME, CASE=CACONEW, EXPOSURE=BK_VP1, 
            SELECT=1, REFVAL=MIN, CI=1, PLOT=2, FOOTER=NONE, KLINES=T, MODPRINT=F, PRINTCV=F, DISPLAYX=T)

*JC*;
TITLE2 'JC';
%lgtphcurv9(DATA=PLYMA.FINALCOHORT, MODEL=CONDLOG, STRATA=MATCH, TIME=TIME, CASE=CACONEW, EXPOSURE=JC_VP1, 
            SELECT=1, REFVAL=MIN, CI=1, PLOT=2, FOOTER=NONE, KLINES=T, MODPRINT=F, PRINTCV=F, DISPLAYX=T)

*MCV*;
TITLE2 'MCV';
%lgtphcurv9(DATA=PLYMA.FINALCOHORT, MODEL=CONDLOG, STRATA=MATCH, TIME=TIME, CASE=CACONEW, EXPOSURE=MCV344_VP1, 
            SELECT=1, REFVAL=MIN, CI=1, PLOT=2, FOOTER=NONE, KLINES=T, MODPRINT=F, PRINTCV=F, DISPLAYX=T)

*HPyV6*;
TITLE2 'HPyV6';
%lgtphcurv9(DATA=PLYMA.FINALCOHORT, MODEL=CONDLOG, STRATA=MATCH, TIME=TIME, CASE=CACONEW, EXPOSURE=HPyV6_VP1, 
            SELECT=1, REFVAL=MIN, CI=1, PLOT=2, FOOTER=NONE, KLINES=T, MODPRINT=F, PRINTCV=F, DISPLAYX=T)

*HPyV7*;
TITLE2 'HPyV7';
%lgtphcurv9(DATA=PLYMA.FINALCOHORT, MODEL=CONDLOG, STRATA=MATCH, TIME=TIME, CASE=CACONEW, EXPOSURE=HPyV7_VP1, 
            SELECT=1, REFVAL=MIN, CI=1, PLOT=2, FOOTER=NONE, KLINES=T, MODPRINT=F, PRINTCV=F, DISPLAYX=T)

*WU*;
TITLE2 'WU';
%lgtphcurv9(DATA=PLYMA.FINALCOHORT, MODEL=CONDLOG, STRATA=MATCH, TIME=TIME, CASE=CACONEW, EXPOSURE=WU_VP1, 
            SELECT=1, REFVAL=MIN, CI=1, PLOT=2, FOOTER=NONE, KLINES=T, MODPRINT=F, PRINTCV=F, DISPLAYX=T)

*KI*;
TITLE2 'KI';
%lgtphcurv9(DATA=PLYMA.FINALCOHORT, MODEL=CONDLOG, STRATA=MATCH, TIME=TIME, CASE=CACONEW, EXPOSURE=KI_VP1, 
            SELECT=1, REFVAL=MIN, CI=1, PLOT=2, FOOTER=NONE, KLINES=T, MODPRINT=F, PRINTCV=F, DISPLAYX=T)

ODS RTF CLOSE;  

*Though an association was observed for TSV and CLL/SLL, and an inverse trend was suggested for TSV and NHL overall (p=0.03), spline analyses did not 
detect any linear or non-linear associations...*;

*****************;
*	TSV SPLINES	*;
*****************;

ODS RTF FILE="S:\USER\JBLASE\NHL & Polyomavirus\Jenny\PROGRAM REVIEW\OUTPUT\TSV SPLINE - &SYSDATE..RTF"; 
*TSV_VP1*;
%lgtphcurv9(DATA=PLYMA.FINALCOHORT, MODEL=CONDLOG, STRATA=MATCH, TIME=TIME, CASE=CACONEW, EXPOSURE=TSV_VP1, 
            KNOT= 250 611 3342 6257 8843 13340, SELECT=1, REFVAL=MIN, CI=1, PLOT=2, FOOTER=NONE,
            KLINES=T, MODPRINT=F, PRINTCV=F, DISPLAYX=T, AXORDV=0.1 TO 2 BY .1)

ODS RTF CLOSE;

*NOTE: THE TSV SPLINE WAS DONE A LITTLE DIFFERENTLY THAN THE OTHERS BECAUSE LAUREN PICKED SOME KNOTS. WHEN I DID IT THE SAME AS THE OTHERS I GOT THE SAME ANSWERS SO I LEFT IT AS IS*;