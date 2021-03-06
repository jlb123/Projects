LIBNAME PAGE "D:\USER\JBLASE\Hema Malignancies & Parents Age\DATA";
LIBNAME LIBRARY 'D:\USER\JBLASE'; 

*********************************************************************;
*	CHECKING PH ASSUMPTION WITH WALD AND THEN LIKLIHOOD RATIO TEST	*;
*********************************************************************;

*COLLAPSING TOP 2 CATEGORIES OF FATHERS AGE AND CHECKING PH ASSUMPTION*;
*P-VALUE: 0.2552*;

*****************;
*	WALD TEST	*;
*****************;

*FATHER'S AGE AT BIRTH*;
PROC PHREG DATA=PAGE.FINALCOHORT NOSUMMARY;
            CLASS FAGEBTH_4CAT MAGEBTH_4CAT RACENEW EDUCA/REF=FIRST ORDER=INTERNAL;
            MODEL FAILNEW*ALL_HEMA(0)=FAGEBTH_4CAT MAGEBTH_4CAT RACENEW EDUCA SEX_NEW SIBS TIMEINT2 TIMEINT3 TIMEINT4/RL; 
				
			TIMEINT2=0; TIMEINT3=0; TIMEINT4=0;
                 IF FAGEBTH_4CAT=2 THEN TIMEINT2=FAILNEW;
            ELSE IF FAGEBTH_4CAT=3 THEN TIMEINT3=FAILNEW;
            ELSE IF FAGEBTH_4CAT=4 THEN TIMEINT4=FAILNEW;

Test_for_Proportionality: TEST TIMEINT2,TIMEINT3,TIMEINT4;

            STRATA AGE92M; 

TITLE 'MODEL INTERACTION BETWEEN 4 CATEGORY FATHERS AGE AT BIRTH AND TIME, MULTIVARIABLE-ADJUSTED';

RUN;

*4 CATEGORY FATHERS AGE*;

*****************************************************************;
*   -2LL TEST													*;
*****************************************************************;
***REDUCED MODEL;
PROC PHREG DATA=PAGE.FINALCOHORT NOSUMMARY MULTIPASS;
CLASS FAGEBTH_4CAT MAGEBTH_4CAT RACENEW EDUCA/REF=FIRST ORDER=INTERNAL;
            MODEL FAILNEW*ALL_HEMA(0)=FAGEBTH_4CAT MAGEBTH_4CAT RACENEW EDUCA SEX_NEW SIBS/RL; 
 
STRATA AGE92M;
TITLE 'MULIVARIATE-ADJUSTED REDUCED MODEL';
ODS OUTPUT FITSTATISTICS=FIT GLOBALTESTS=DEG;  
RUN;

DATA RED1 (KEEP=MERGEVAR MODELR); 
SET FIT;
IF CRITERION='-2 LOG L';
MODELR=WITHCOVARIATES;
MERGEVAR=2;
RUN;

DATA RED2 (KEEP=MERGEVAR RDF); 
SET DEG;	
IF TEST='Likelihood Ratio';
RDF=DF;
MERGEVAR=2;
RUN;

DATA REDUCED (KEEP=MERGEVAR	MODELR RDF);
MERGE RED1 RED2;
BY MERGEVAR;
PROC PRINT DATA=REDUCED NOOBS;
RUN;

***INTERACTION MODEL;
PROC PHREG DATA=PAGE.FINALCOHORT NOSUMMARY MULTIPASS;
CLASS FAGEBTH_4CAT MAGEBTH_4CAT RACENEW EDUCA/REF=FIRST ORDER=INTERNAL;
MODEL FAILNEW*ALL_HEMA(0)=FAGEBTH_4CAT MAGEBTH_4CAT RACENEW EDUCA SEX_NEW SIBS TIMEINT2 TIMEINT3 TIMEINT4/RL; 
				
			*DEFINE INTERACTION BETWEEN FATHERS AGE AT BIRTH AND FOLLOW-UP TIME;
			TIMEINT2=0; TIMEINT3=0; TIMEINT4=0;
                 IF FAGEBTH_4CAT=2 THEN TIMEINT2=FAILNEW;
            ELSE IF FAGEBTH_4CAT=3 THEN TIMEINT3=FAILNEW;
            ELSE IF FAGEBTH_4CAT=4 THEN TIMEINT4=FAILNEW;
			
STRATA AGE92M;
TITLE 'MULIVARIATE-ADJUSTED INTERACTION MODEL';
ODS OUTPUT FITSTATISTICS=FIT GLOBALTESTS=DEG;  
RUN;

DATA FULL1 (KEEP=MERGEVAR MODELF); 
SET FIT;
IF CRITERION='-2 LOG L';
MODELF=WITHCOVARIATES;
MERGEVAR=2;
RUN;

DATA FULL2 (KEEP=MERGEVAR FDF); 
SET DEG;	
IF TEST='Likelihood Ratio';
FDF=DF;
MERGEVAR=2;
RUN;

DATA FULMOD (KEEP=MERGEVAR MODELF FDF);
MERGE FULL1 FULL2;
BY MERGEVAR;
RUN;

DATA MVTEST (KEEP=MERGEVAR MODELR RDF MODELF FDF CHIVAL DF PVAL); 
MERGE REDUCED FULMOD; 
BY MERGEVAR;

CHIVAL=(MODELR-MODELF);
DF=(FDF-RDF);
PVALUE=1-PROBCHI(CHIVAL,DF);
PVAL=PUT(ROUND(PVALUE,0.001),5.3);

PROC PRINT DATA=MVTEST NOOBS;
RUN;

PROC FORMAT;
VALUE MERGEVAR
	1='Age-adjusted'
	2='Fully-adjusted';
run;

DATA LLTEST;
SET MVTEST;
format mergevar mergevar.;
PROC PRINT DATA=LLTEST;
RUN;

*LINDSAY'S DEMO TEMPLATE;
ODS PATH WORK.TEMPLAT(UPDATE)
SASUSR.TEMPLAT(UPDATE) SASHELP.TMPLMST(READ);
PROC TEMPLATE;
DEFINE STYLE STYLES.DEMO;
PARENT=STYLES.MINIMAL;
STYLE TABLE /
	FRAME=HSIDES
	RULES=GROUP
	CELLPADDING=2
	CELLSPACING=10
	JUST=L;
STYLE HEADER /
	JUST=L
	CELLPADDING=5;
STYLE DATAEMPHASIS /
	FONT_FACE = "ARIAL, HELVETICA, SANS-SERIF"
	FONT_SIZE=2
	FONT_WEIGHT = BOLD;
END;  

ODS RTF FILE="D:\USER\JBLASE\Hema Malignancies & Parents Age\PROGRAM REVIEW\OUTPUT\PHCHECK FATHERS_&SYSDATE..RTF" 
	STYLE=DEMO;
TITLE 'FATHERS AGE AND ALL HEME';
title2 '-2LL Test of Proportional Hazards Assumption';
PROC REPORT DATA=LLTEST HEADLINE HEADSKIP CENTER
STYLE(REPORT)={JUST=CENTER} SPLIT='~';
COLUMNS MERGEVAR MODELR RDF MODELF FDF CHIVAL DF PVAL;
DEFINE MERGEVAR/DISPLAY LEFT " ";
DEFINE MODELR/DISPLAY LEFT "-2logL Base";
DEFINE RDF/DISPLAY LEFT "df";
DEFINE MODELF/DISPLAY LEFT "-2logL Interaction";
DEFINE FDF/DISPLAY LEFT "df";
DEFINE CHIVAL/DISPLAY LEFT "Chi-square";
DEFINE DF/DISPLAY LEFT "df";
DEFINE PVAL/DISPLAY LEFT "p-value";
RUN;
ODS RTF CLOSE;

PROC DATASETS LIB=WORK NOLIST KILL;
QUIT;
RUN;

TITLE;
TITLE2;
TITLE3;

*WALD TEST FOR CATEGORICAL MOTHERS AGE AT BIRTH*;

PROC PHREG DATA=PAGE.FINALCOHORT NOSUMMARY;
            CLASS FAGEBTH_4CAT MAGEBTH_4CAT RACENEW EDUCA/REF=FIRST ORDER=INTERNAL;
            MODEL FAILNEW*ALL_HEMA(0)=FAGEBTH_4CAT MAGEBTH_4CAT RACENEW EDUCA SEX_NEW SIBS TIMEINT2 TIMEINT3 TIMEINT4/RL; 
				
			TIMEINT2=0; TIMEINT3=0; TIMEINT4=0; TIMEINT5=0;
                 IF MAGEBTH_4CAT=2 THEN TIMEINT2=FAILNEW;
            ELSE IF MAGEBTH_4CAT=3 THEN TIMEINT3=FAILNEW;
            ELSE IF MAGEBTH_4CAT=4 THEN TIMEINT4=FAILNEW;

Test_for_Proportionality: TEST TIMEINT2,TIMEINT3,TIMEINT4;

            STRATA AGE92M; 

TITLE 'MODEL INTERACTION BETWEEN 4 CATEGORY MOTHERS AGE AT BIRTH AND TIME, MULTIVARIABLE-ADJUSTED';

            RUN;

*4 CATEGORY MOTHERS AGE*;

*****************************************************************;
*   -2LL TEST													*;
*****************************************************************;
***REDUCED MODEL;
PROC PHREG DATA=PAGE.FINALCOHORT NOSUMMARY MULTIPASS;
CLASS FAGEBTH_4CAT MAGEBTH_4CAT RACENEW EDUCA/REF=FIRST ORDER=INTERNAL;
            MODEL FAILNEW*ALL_HEMA(0)=FAGEBTH_4CAT MAGEBTH_4CAT RACENEW EDUCA SEX_NEW SIBS/RL; 
 
STRATA AGE92M;
TITLE 'MULIVARIATE-ADJUSTED REDUCED MODEL';
ODS OUTPUT FITSTATISTICS=FIT GLOBALTESTS=DEG;  
RUN;

DATA RED1 (KEEP=MERGEVAR MODELR); 
SET FIT;
IF CRITERION='-2 LOG L';
MODELR=WITHCOVARIATES;
MERGEVAR=2;
RUN;

DATA RED2 (KEEP=MERGEVAR RDF); 
SET DEG;	
IF TEST='Likelihood Ratio';
RDF=DF;
MERGEVAR=2;
RUN;

DATA REDUCED (KEEP=MERGEVAR	MODELR RDF);
MERGE RED1 RED2;
BY MERGEVAR;
PROC PRINT DATA=REDUCED NOOBS;
RUN;

***INTERACTION MODEL;
PROC PHREG DATA=PAGE.FINALCOHORT NOSUMMARY MULTIPASS;
CLASS FAGEBTH_4CAT MAGEBTH_4CAT RACENEW EDUCA/REF=FIRST ORDER=INTERNAL;
MODEL FAILNEW*ALL_HEMA(0)=FAGEBTH_4CAT MAGEBTH_4CAT RACENEW EDUCA SEX_NEW SIBS TIMEINT2 TIMEINT3 TIMEINT4/RL; 
				
			*DEFINE INTERACTION BETWEEN FATHERS AGE AT BIRTH AND FOLLOW-UP TIME;
			TIMEINT2=0; TIMEINT3=0; TIMEINT4=0;
                 IF MAGEBTH_4CAT=2 THEN TIMEINT2=FAILNEW;
            ELSE IF MAGEBTH_4CAT=3 THEN TIMEINT3=FAILNEW;
            ELSE IF MAGEBTH_4CAT=4 THEN TIMEINT4=FAILNEW;
			
STRATA AGE92M;
TITLE 'MULIVARIATE-ADJUSTED INTERACTION MODEL';
ODS OUTPUT FITSTATISTICS=FIT GLOBALTESTS=DEG;  
RUN;

DATA FULL1 (KEEP=MERGEVAR MODELF); 
SET FIT;
IF CRITERION='-2 LOG L';
MODELF=WITHCOVARIATES;
MERGEVAR=2;
RUN;

DATA FULL2 (KEEP=MERGEVAR FDF); 
SET DEG;	
IF TEST='Likelihood Ratio';
FDF=DF;
MERGEVAR=2;
RUN;

DATA FULMOD (KEEP=MERGEVAR MODELF FDF);
MERGE FULL1 FULL2;
BY MERGEVAR;
RUN;

DATA MVTEST (KEEP=MERGEVAR MODELR RDF MODELF FDF CHIVAL DF PVAL); 
MERGE REDUCED FULMOD; 
BY MERGEVAR;

CHIVAL=(MODELR-MODELF);
DF=(FDF-RDF);
PVALUE=1-PROBCHI(CHIVAL,DF);
PVAL=PUT(ROUND(PVALUE,0.001),5.3);

PROC PRINT DATA=MVTEST NOOBS;
RUN;

PROC FORMAT;
VALUE MERGEVAR
	1='Age-adjusted'
	2='Fully-adjusted';
run;

DATA LLTEST;
SET MVTEST;
format mergevar mergevar.;
PROC PRINT DATA=LLTEST;
RUN;

*LINDSAY'S DEMO TEMPLATE;
ODS PATH WORK.TEMPLAT(UPDATE)
SASUSR.TEMPLAT(UPDATE) SASHELP.TMPLMST(READ);
PROC TEMPLATE;
DEFINE STYLE STYLES.DEMO;
PARENT=STYLES.MINIMAL;
STYLE TABLE /
	FRAME=HSIDES
	RULES=GROUP
	CELLPADDING=2
	CELLSPACING=10
	JUST=L;
STYLE HEADER /
	JUST=L
	CELLPADDING=5;
STYLE DATAEMPHASIS /
	FONT_FACE = "ARIAL, HELVETICA, SANS-SERIF"
	FONT_SIZE=2
	FONT_WEIGHT = BOLD;
END;  

ODS RTF FILE="D:\USER\JBLASE\Hema Malignancies & Parents Age\PROGRAM REVIEW\OUTPUT\PHCHECK MOTHERS_&SYSDATE..RTF" 
	STYLE=DEMO;
TITLE 'MOTHERS AGE AND ALL HEME';
title2 '-2LL Test of Proportional Hazards Assumption';
PROC REPORT DATA=LLTEST HEADLINE HEADSKIP CENTER
STYLE(REPORT)={JUST=CENTER} SPLIT='~';
COLUMNS MERGEVAR MODELR RDF MODELF FDF CHIVAL DF PVAL;
DEFINE MERGEVAR/DISPLAY LEFT " ";
DEFINE MODELR/DISPLAY LEFT "-2logL Base";
DEFINE RDF/DISPLAY LEFT "df";
DEFINE MODELF/DISPLAY LEFT "-2logL Interaction";
DEFINE FDF/DISPLAY LEFT "df";
DEFINE CHIVAL/DISPLAY LEFT "Chi-square";
DEFINE DF/DISPLAY LEFT "df";
DEFINE PVAL/DISPLAY LEFT "p-value";
RUN;
ODS RTF CLOSE;

PROC DATASETS LIB=WORK NOLIST KILL;
QUIT;
RUN;

TITLE;
TITLE2;
TITLE3;
