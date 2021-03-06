**********************************************************************************;
*PROGRAM: S:\USER\JBLASE\H Pylori and CRC\PROGRAM\H Pylori and CRC Analysis.SAS  *;
*PURPOSE: Analysis for H. Pylori and CRC study									 *;
*LAST MODIFIED: MAY 27, 2015 BY JENNY BLASE                                      *;
**********************************************************************************;


OPTIONS MPRINT;
LIBNAME HPY 'D:\USER\JBLASE\H Pylori and CRC\DATA';
%INCLUDE 'D:\USER\JBLASE\Macros\DESCRIPTIVE_TBL.sas'; 
%include 'D:\USER\JBLASE\From Other Analysts\LOGISTIC REGRESSION MACRO - CHRISSY.SAS'; *CHRISSY'S LOGISTIC REGRESSION MACRO*;


PROC FORMAT;

VALUE CACONEWF 0='CONTROL'
			   1='CASE';

VALUE SERONPF   0='SERO -'
			    1='SERO +';

VALUE $ TERTSF	'0'='<=33%'
				'1'='33-67%'
				'2'='>67%';

VALUE $ TERTS2F '0'='SERO -'
				'1'='<=33%'
				'2'='33-67%'
				'3'='>67%';

VALUE SEX		0 = 'Female'
				1 = 'Male';

VALUE RACENEW 1 = 'White'
			  2 = 'Black'
			  3 = 'Other/Missing';

VALUE $ SMOKE '1' = 'NEVER'
			  '2' = 'CURRENT'
			  '3' = 'FORMER'
			  '9' = 'MISSING';

VALUE BMIWHO 	0='0: <25.0 (UNDER/NORMAL)'				
			 	1='1: 25.0-<30.0 (OVERWEIGHT)'
			 	2='2: >=30.0 (OBESE)'
			 	9='9: UNKNOWN'; 

VALUE EDUCAF    1 = '1: Less than high school'
				2 = '2: High school/missing education'
				3 = '3: Some college/vocational school'
				4 = '4: College/graduate school'; 

VALUE ALC	1 = '0 DRINKS/DAY'
			2 = '<=1 DRINKS/DAY'
			3 = '>1 DRINKS/DAY'
			9 = 'MISSING';

VALUE MSF	1="MARRIED"
			2="WIDOWED"
			3="SEPARATED/DIVORCED"
			4="NEVER MARRIED"
			9="MISSING";

VALUE MEATF	0="0 SERVINGS"
			1="<1 SERVINGS"
			2=">1 SERVINGS";

VALUE YESNOF 0="NO"
			 1="YES"
			 9="MISSING";

VALUE YESNO2F	0='NO'
				1='YES'
				.='MISSING';

VALUE CPDF   1="1-4 CPD"
			 2="5-14 CPD"
			 3="15-24 CPD"
			 4="25-34 CPD"
			 5="35-44 CPD"
			 6="45+ CPD"
			 9="MISSING/FORMER/NONSMOKERS";

VALUE ASPDURF 0="NEVER"
			  1="OCCASIONAL/FORMER"
			  2="30+DAYS/MO,<5 YRS"
			  3="30+DAYS/MO,5+YRS";

VALUE ASPREGF  0 = "NO REGULAR USE"
			   1 = "1-14 PILLS/MONTH"
			   2 = "15-29 PILLS/MONTH"
			   3 = "30-59 PILLS/MONTH"
 			   4 = "60-119 PILLS/MONTH"
			   5 = "120+ PILLS/MONTH"
			   9 = "MISSING";

VALUE PAF	0="Inactive"
			1="Below recommended activity"
			2="Recommended and above"
			9="Missing";


VALUE $ POL97F	'1'="NEVER"
				'2'="BEFORE 1992"
				'3'="1992-1993"
				'4'="1994-1995"
				'5'="1996 OR AFTER"
				' '="MISSING";

VALUE POL99F	0="NEVER"
				1="BEFORE OCT 1997"
				2="OCT 1997-SEPT 1999"
				3="AFTER SEPT 1999"
				9="MISSING";

VALUE $ POL01F	'1'="NEVER"
				'2'="BEFORE OCT 1999"
				'3'="OCT 1999-SEPT 2001"
				'4'="AFTER SEPT 2001"
				' '="MISSING";

VALUE $ POL03F	'1'="NEVER"
				'2'="BEFORE OCT 2001"
				'3'="OCT 2001-JULY 2003"
				'4'="AFTER JULY 2003"
				' '="MISSING";

VALUE $ STATF '1'="ALWAYS NEVER"
			  '2'="CURRENT"
			  '3'="EVER, NOT CURRENT"
			  '9'="MISSING";

VALUE $ COLSCREEN	'1'='NONE, PAST 2 YRS'
					'2'='SX, PAST 2 YRS'
					'3'='ROUTINE, PAST 2 YRS'
					'4'='SX AND ROUTINE, PAST 2 YRS'
					' '='MISSING';

VALUE $ EVRSIGF	'0'='NEVER'
				'1'='EVER/NONE PAST 2 YRS'
				'2'='SX, PAST 2 YRS'
				'3'='ROUTINE, PAST 2 YRS'
				'4'='SX AND ROUTINE, PAST 2 YRS'
				' '='MISSING';

VALUE	POLYPF	0="NEVER"
				1="BEFORE 1992"
				2="1992-1993"
				3="1994-1995"
				4="1996 OR AFTER"
				5="BEFORE OCT 1997"
				6="OCT 1997-SEPT 1999"
				7="AFTER SEPT 1999"
				.="MISSING";
RUN;

***************;
*	METHODS	  *;
***************;
ODS RTF FILE="D:\USER\JBLASE\H Pylori and CRC\PROGRAM REVIEW\NEW OUTPUT\METHODS AND RESULTS STATS - &SYSDATE..RTF";

TITLE 'DATA SOURCE FOR ALL CASES';
PROC FREQ DATA=HPY.FINALCOHORT;
WHERE CACONEW=1;
TABLES ASCERTAIN;
RUN;

*************;
*	RESULTS	*;
*************;


TITLE 'CASE AND CONTROL NUMBERS';
PROC FREQ DATA=HPY.FINALCOHORT;
TABLES CACONEW;
FORMAT CACONEW CACONEWF.;
RUN;

TITLE 'AGE RANGE/MEDIAN AT BLOOD DRAW';
PROC UNIVARIATE DATA=HPY.FINALCOHORT;
VAR AGELL;
RUN;

TITLE 'H PYLORI SEROPREVALENCE';
PROC FREQ DATA=HPY.FINALCOHORT;
TABLES HP_CLASS/LIST;
FORMAT HP_CLASS SERONPF.;
RUN;

TITLE "SEROPREVALENCE AMONG CONTROLS";
PROC FREQ DATA=HPY.FINALCOHORT;
WHERE CACONEW=0;
TABLES HP_CLASS/LIST;
FORMAT HP_CLASS SERONPF.;
RUN;

TITLE "SEROPREVALENCE AMONG CASES";
PROC FREQ DATA=HPY.FINALCOHORT;
WHERE CACONEW=1;
TABLES HP_CLASS/LIST;
FORMAT HP_CLASS SERONPF.;
RUN;

ODS RTF CLOSE;

*STRATIFIED BY CACO STATUS*;
%DESCRIPTIVE_TBL (DAT= HPY.FINALCOHORT, EXPOSURE=CACONEW, COVCAT= SEX RACENEW BMIWHO EDUCA STAT99 ALC99 MAR_STAT FAMHX99N SCREEN99 MEAT99_CAT RSCREEN99 ANTIB99 RCOLPOL99 PA99 ULCOL01
					  HRT6GRP99 CPD99N ALLASP99 ALLASP3099 HPYANTI,COVCONT=YEARDS AGEDX BMI99 MEAT99 DUR99N, ORDER=FORMATTED, ROWCOL=COL,CHI=1,LIMIT=1,
				      PERDEC=0.1, CONTMEAS=MEANSD , PRINTOUT=0,TOTAL=0,COLWDTH=40,STARTLAB=,TITL= H Pylori Descriptive Stats by CACO Status,
				      ODSTYPE=RTF,ODSSTYLE=Minimal,ODSPATH= D:\USER\JBLASE\H Pylori and CRC\PROGRAM REVIEW\NEW OUTPUT\TABLE1 STRATIFIED BY CACO STATUS &SYSDATE..RTF,
                      ORIENT=LANDSCAPE); 


*********************;
*TABLE 1 AND TABLE 2*;
*********************;

*******************************************;
*COLORECTAL MODELS FOR TABLE 1 AND TABLE 2*;
*******************************************;

%MACRO BASIC_MODELS;

%*SEROPOSITIVE VS SERONEGATIVE MODELS*;
%LET NPANTLIST=GroEl_NP UreA_NP HP0231_NP NapA_NP HP0305_NP HpaA_NP CagM_NP CagA_NP HyuA_NP Catalase_NP VacA_NP HcpC_NP Cad_NP Omp_NP HOMB_NP HP_class;

	%DO A=1 %TO 16;
		%LET NPANTIGEN=%SCAN(&NPANTLIST, &A, %STR( ));

%*NON-STRATIFIED MODEL*;
%LOGMODS (DATASET=HPY.FINALCOHORT,CASE=CACONEW,EXP=&NPANTIGEN,EXPF=SERONPF,EXPTYPE=CAT,REF=0,MODTYPE=CLR,STRATA=MATCH);

PROC APPEND BASE=NP_OR DATA=CACONEW_&NPANTIGEN._CLR FORCE; RUN;

%END;

%*MODELS WITH TERTILES*;
%LET TERTANTLIST=GroEl_TERT UreA_TERT HP0231_TERT NapA_TERT HP0305_TERT HpaA_TERT CagM_TERT CagA_TERT HyuA_TERT Catalase_TERT VacA_TERT HcpC_TERT Cad_TERT Omp_TERT HOMB_TERT;

	%DO A=1 %TO 15;
		%LET TERTANTIGEN=%SCAN(&TERTANTLIST, &A, %STR( ));

%LOGMODS (DATASET=HPY.FINALCOHORT,CASE=CACONEW,EXP=&TERTANTIGEN,EXPF=TERTS2F,EXPTYPE=CAT,REF=0,MODTYPE=CLR,STRATA=MATCH);

PROC APPEND BASE=TERT_OR DATA=CACONEW_&TERTANTIGEN._CLR FORCE; RUN;

%END;

%MEND BASIC_MODELS;

%BASIC_MODELS;

ODS RTF FILE="D:\USER\JBLASE\H Pylori and CRC\PROGRAM REVIEW\NEW OUTPUT\BASIC MODELS NP AND TERTILES - &SYSDATE..RTF";

TITLE "CLR MODELS, SEROPOSITIVE VS SERONEGATIVE";
PROC PRINT DATA=NP_OR; VAR CASES CONTROLS ORCI EXPCAT EXPLBL; RUN;
TITLE "CLR MODELS, TERTILES AMONG SEROPOSITIVES";
PROC PRINT DATA=TERT_OR; VAR ORCI EXPCAT EXPLBL; RUN;

ODS RTF CLOSE;

****************************;
*TABLE 1 - COLON CASES ONLY*;
****************************;
*NOTE: ONE PERSON HAD VERIFIED COLON AND RECTAL CANCERS (IM ASSUMING ON THE SAME DAY?) SO THAT PERSON GETS COUNTED IN EACH SEPERATE ANALYSIS OF COLON AND RECTAL*;

*COLON CASES AND MATCHING CONTROLS*;

PROC SORT DATA=HPY.FINALCOHORT OUT=HPYFINAL; BY MATCH; RUN;

*ONLY COLON CASES*;
DATA COLONONLY;
SET HPYFINAL;
	IF COLONCA=1;
RUN;

DATA COLON;
	MERGE COLONONLY (IN=A) HPYFINAL;
	BY MATCH;
	IF A;
RUN;


*COLON ONLY CASES*;
%MACRO COLON_MODELS;

%*SEROPOSITIVE VS SERONEGATIVE MODELS*;
%LET NPANTLIST=GroEl_NP UreA_NP HP0231_NP NapA_NP HP0305_NP HpaA_NP CagM_NP CagA_NP HyuA_NP Catalase_NP VacA_NP HcpC_NP Cad_NP Omp_NP HOMB_NP;

	%DO A=1 %TO 15;
		%LET NPANTIGEN=%SCAN(&NPANTLIST, &A, %STR( ));

%*NON-STRATIFIED MODEL*;
%LOGMODS (DATASET=COLON,CASE=CACONEW,EXP=&NPANTIGEN,EXPF=SERONPF,EXPTYPE=CAT,REF=0,MODTYPE=CLR,STRATA=MATCH);


PROC APPEND BASE=COLON_OR DATA=CACONEW_&NPANTIGEN._CLR FORCE; RUN;

%END;

%MEND COLON_MODELS;

%COLON_MODELS;

*MODEL DID NOT CONVERGE FOR CATALASE - RERUN USING PHREG*;
ODS OUTPUT ParameterEstimates=CATALASE_HRS;
PROC PHREG DATA=COLON;
  CLASS CATALASE_NP (REF='0')/PARAM=REF;
  MODEL TIME*CACONEW (0) = CATALASE_NP/TIES=DISCRETE RISKLIMITS;
  STRATA MATCH;
RUN;

ODS RTF FILE="D:\USER\JBLASE\H Pylori and CRC\PROGRAM REVIEW\NEW OUTPUT\COLON CASES CLR MODELS - &SYSDATE..RTF";

TITLE 'CONDITIONAL LOGISTIC REGRESSION - AMONG COLON CASES ONLY';
PROC PRINT DATA=COLON_OR; VAR CASES CONTROLS ORCI EXPCAT EXPLBL; RUN;

TITLE 'RERUN OF CATALASE_NP IN PHREG SINCE DID NOT CONVERGE IN LOGISTIC';
PROC PRINT DATA=CATALASE_HRS; RUN;

ODS RTF CLOSE;


*****************************;
*TABLE 1 - RECTAL CASES ONLY*;
*****************************;

DATA RECONLY;
SET HPY.FINALCOHORT;
	IF RECTALCA=1;
RUN;

PROC SORT DATA=RECONLY; BY MATCH; RUN;

DATA RECTAL;
	MERGE RECONLY (IN=A) HPYFINAL;
	BY MATCH;
	IF A;
RUN;

%MACRO RECTAL_MODELS;

%*SEROPOSITIVE VS SERONEGATIVE MODELS*;
%LET NPANTLIST=GroEl_NP UreA_NP HP0231_NP NapA_NP HP0305_NP HpaA_NP CagM_NP CagA_NP HyuA_NP Catalase_NP VacA_NP HcpC_NP Cad_NP Omp_NP HOMB_NP;

	%DO A=1 %TO 15;
		%LET NPANTIGEN=%SCAN(&NPANTLIST, &A, %STR( ));

%*NON-STRATIFIED MODEL*;
%LOGMODS (DATASET=RECTAL,CASE=CACONEW,EXP=&NPANTIGEN,EXPF=SERONPF,EXPTYPE=CAT,REF=0,MODTYPE=CLR,STRATA=MATCH);

PROC APPEND BASE=RECTAL_OR DATA=CACONEW_&NPANTIGEN._CLR FORCE; RUN;

%END;

%MEND RECTAL_MODELS;

%RECTAL_MODELS;


*MODEL DID NOT CONVERGE FOR HCPC - RERUN USING PHREG*;
ODS OUTPUT ParameterEstimates=HCPC_HRS;
PROC PHREG DATA=RECTAL;
  CLASS HcpC_NP (REF='0')/PARAM=REF;
  MODEL TIME*CACONEW (0) =HcpC_NP/TIES=DISCRETE RISKLIMITS;
  STRATA MATCH;
RUN;
ODS OUTPUT CLOSE;

*MODEL DID NOT CONVERGE FOR NAPA - RERUN USING PHREG*;
ODS OUTPUT ParameterEstimates=NAPA_HRS;
PROC PHREG DATA=RECTAL;
  CLASS NAPA_NP (REF='0')/PARAM=REF;
  MODEL TIME*CACONEW (0) =NAPA_NP/TIES=DISCRETE RISKLIMITS;
  STRATA MATCH;
RUN;
ODS OUTPUT CLOSE;

ODS RTF FILE="D:\USER\JBLASE\H Pylori and CRC\PROGRAM REVIEW\NEW OUTPUT\RECTAL CASES CLR MODELS - &SYSDATE..RTF";
TITLE 'CONDITIONAL LOGISTIC REGRESSION - AMONG RECTAL CASES ONLY';
PROC PRINT DATA=RECTAL_OR; VAR CASES CONTROLS ORCI EXPCAT EXPLBL; RUN;

TITLE 'RERUN OF HCPC_NP IN PHREG SINCE DID NOT CONVERGE IN LOGISTIC';
PROC PRINT DATA=HCPC_HRS; RUN;

TITLE 'RERUN OF NAPA_NP IN PHREG SINCE DID NOT CONVERGE IN LOGISTIC';
PROC PRINT DATA=NAPA_HRS; RUN;

ODS RTF CLOSE;

*FREQUENCIES AND PERCENTAGES FOR TABLES 1 AND 2;

%MACRO CRC_FREQS (DATASET=,CACO=,ANT=,CASELBL=);

%*SEROPOSITIVE VS SERONEGATIVE MODELS*;
%IF &ANT=NP %THEN %LET NPANTLIST=GroEl_NP UreA_NP HP0231_NP NapA_NP HP0305_NP HpaA_NP CagM_NP CagA_NP HyuA_NP Catalase_NP VacA_NP HcpC_NP Cad_NP Omp_NP HOMB_NP;
%ELSE %LET NPANTLIST=GroEl_TERT UreA_TERT HP0231_TERT NapA_TERT HP0305_TERT HpaA_TERT CagM_TERT CagA_TERT HyuA_TERT Catalase_TERT VacA_TERT HcpC_TERT 
			Cad_TERT Omp_TERT HOMB_TERT;

	%DO A=1 %TO 15;
		%LET NPANTIGEN=%SCAN(&NPANTLIST, &A, %STR( ));


ODS OUTPUT OneWayFreqs=FREQS_&NPANTIGEN;
PROC FREQ DATA=&DATASET;
WHERE CACONEW=&CACO;
TABLES &NPANTIGEN/LIST MISSING NOCUM;
RUN;
ODS OUTPUT CLOSE;

DATA FREQS2_&NPANTIGEN;
SET FREQS_&NPANTIGEN;

FREQPER=FREQUENCY||" ("||STRIP(ROUND(PERCENT,.1))||")";

DROP F_&NPANTIGEN FREQUENCY PERCENT;

RUN;

%END;

ODS RTF FILE="D:\USER\JBLASE\H Pylori and CRC\PROGRAM REVIEW\NEW OUTPUT\&CASELBL FREQUENCIES &ANT ANTIGEN &DATASET - &SYSDATE..RTF";
%IF &ANT=NP %THEN %LET NPANTLIST=GroEl_NP UreA_NP HP0231_NP NapA_NP HP0305_NP HpaA_NP CagM_NP CagA_NP HyuA_NP Catalase_NP VacA_NP HcpC_NP Cad_NP Omp_NP HOMB_NP;
%ELSE %LET NPANTLIST=GroEl_TERT UreA_TERT HP0231_TERT NapA_TERT HP0305_TERT HpaA_TERT CagM_TERT CagA_TERT HyuA_TERT Catalase_TERT VacA_TERT HcpC_TERT Cad_TERT Omp_TERT HOMB_TERT;


	%DO A=1 %TO 15;
		%LET NPANTIGEN=%SCAN(&NPANTLIST, &A, %STR( ));

TITLE "&CASELBL FREQUENCIES/PERCENTAGES FOR &ANT ANTIGEN - &DATASET";
PROC PRINT DATA=FREQS2_&NPANTIGEN; RUN;

	%END;
ODS RTF CLOSE;

TITLE;

%MEND CRC_FREQS;

*ALL CASE AND CONTROL FREQUENCIES FOR TABLES 1 AND 2*;
%CRC_FREQS (DATASET=COLON, CACO=1, ANT=NP, CASELBL=CASE); 
%CRC_FREQS (DATASET=RECTAL, CACO=1, ANT=NP, CASELBL=CASE); 
%CRC_FREQS (DATASET=HPY.FINALCOHORT, ANT=NP, CACO=1, CASELBL=CASE); 
%CRC_FREQS (DATASET=HPY.FINALCOHORT, ANT=TERT, CACO=1, CASELBL=CASE); 
%CRC_FREQS (DATASET=HPY.FINALCOHORT, ANT=NP, CACO=0, CASELBL=CONTROL); 
%CRC_FREQS (DATASET=HPY.FINALCOHORT, ANT=TERT, CACO=0, CASELBL=CONTROL); 



