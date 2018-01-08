LIBNAME SOCIAL 'D:\USER\JBLASE\Social Support\DATA';
LIBNAME LIBRARY 'D:\USER\JBLASE\Social Support\DATA';

OPTIONS MPRINT;


**********;
*ABSTRACT*;
**********;

*TOTAL PARTICIPANTS, AGE AT BASELINE - RANGE AND MEDIAN*;

PROC UNIVARIATE DATA=SOCIAL.FINALCOHORT;
VAR AGE_INT;
RUN;


*********************;
***EXCLUSION TABLE***;
*********************;

ODS RTF FILE= "D:\USER\JBLASE\Social Support\OUTPUT\EXCLUSIONS - &SYSDATE..RTF";

PROC FREQ DATA=SOCIAL.INITIALCOHORT;
TABLES EXCLUSN;
FORMAT EXCLUSN EXCLU.;
RUN;

ODS RTF CLOSE;

*MORTALITY FOLLOW-UP SECTION*;

TITLE 'TOTAL NUMBER OF DEATHS';
PROC FREQ DATA=SOCIAL.FINALCOHORT;
TABLES ALLCAUSE;
FORMAT ALLCAUSE ALLCAUSE.;
RUN;


********************************************************;
***EXPOSURE AND EXPOSURE COMPONENTS BY SEX/RACE GROUP***;
********************************************************;

%MACRO EXP_COUNTS (DATASET=,DESC=);

ODS OUTPUT OneWayFreqs=FREQS;
PROC FREQ DATA=&DATASET;
TABLES MARRIED BSINDEX FRIENDREL CLUBGRP_SCALE CHURCH_SCALE/NOCUM;
RUN;
ODS OUTPUT CLOSE;


DATA TWO;
SET FREQS;

%*MARRIED*;
IF MARRIED=1 THEN DO;
    MAR_P=PUT(ROUND(PERCENT, 0.1),5.1);
    MAR_F=PUT(FREQUENCY, COMMA7.);
    MAR_FREQ=" "||STRIP(MAR_F)||" ("||STRIP(MAR_P)||")";
END;

%*BSINDEX*;
BS_P=PUT(ROUND(PERCENT, 0.1),5.1);
    BS_F=PUT(FREQUENCY, COMMA7.);
    BS_FREQ=" "||STRIP(BS_F)||" ("||STRIP(BS_P)||")";

%*FRIENDS AND RELATIVES*;
IF FRIENDREL=1 THEN DO;
    FRIENDREL_P=PUT(ROUND(PERCENT, 0.1),5.1);
    FRIENDREL_F=PUT(FREQUENCY, COMMA7.);
    FRIENDREL_FREQ=" "||STRIP(FRIENDREL_F)||" ("||STRIP(FRIENDREL_P)||")";
END;

%*CLUBGRP_SCALE*;
IF CLUBGRP_SCALE=1 THEN DO;
    CLUBGRP_SCALE_P=PUT(ROUND(PERCENT, 0.1),5.1);
    CLUBGRP_SCALE_F=PUT(FREQUENCY, COMMA7.);
    CLUBGRP_SCALE_FREQ=" "||STRIP(CLUBGRP_SCALE_F)||" ("||STRIP(CLUBGRP_SCALE_P)||")";
END;

%*CHURCH ATTENDANCE*;
IF CHURCH_SCALE=1 THEN DO;
    CHURCH_SCALE_P=PUT(ROUND(PERCENT, 0.1),5.1);
    CHURCH_SCALE_F=PUT(FREQUENCY, COMMA7.);
    CHURCH_SCALE_FREQ=" "||STRIP(CHURCH_SCALE_F)||" ("||STRIP(CHURCH_SCALE_P)||")";
END;

RUN;

ODS RTF FILE= "D:\USER\JBLASE\Social Support\OUTPUT\SOCIAL SUPPORT MEASURES &DESC - &SYSDATE..RTF";

TITLE 'PERCENTAGE MARRIED';
PROC PRINT DATA=TWO;
WHERE MARRIED=1;
VAR MAR_FREQ;
RUN;

TITLE 'OVER 6 CLOSE FRIENDS AND RELATIVES';
PROC PRINT DATA=TWO;
WHERE FRIENDREL=1;
VAR FRIENDREL_FREQ;
RUN;

TITLE 'CLUB OR GROUP PARTICIPATION AT LEAST 1/MONTH';
PROC PRINT DATA=TWO;
WHERE CLUBGRP_SCALE=1;
VAR CLUBGRP_SCALE_FREQ;
RUN;

TITLE 'CHURCH AT LEAST 1/MONTH';
PROC PRINT DATA=TWO;
WHERE CHURCH_SCALE=1;
VAR CHURCH_SCALE_FREQ;
RUN;

TITLE 'BERKMAN-SYME INDEX';
PROC PRINT DATA=TWO;
WHERE BSINDEX NE .;
VAR BSINDEX BS_FREQ;
RUN;

ODS RTF CLOSE;

TITLE;

%MEND EXP_COUNTS;

%EXP_COUNTS(DATASET=SOCIAL.BLKMALE,DESC= BLACK MALES);
%EXP_COUNTS(DATASET=SOCIAL.BLKFEM,DESC= BLACK FEMALES);
%EXP_COUNTS(DATASET=SOCIAL.WHTMALE,DESC= WHITE MALES);
%EXP_COUNTS(DATASET=SOCIAL.WHTFEM,DESC= WHITE FEMALES);




******************************************************************************;
***SOCIAL SUPPORT INDEX BY COVARIATE TABLES - STRATIFIED BY RACE/SEX GROUPS***;
******************************************************************************;

%INCLUDE 'D:\USER\JBLASE\Macros\DESCRIPTIVE_TBL.sas';

*BLACK MALES*;
%DESCRIPTIVE_TBL (DAT=SOCIAL.BLKMALE, EXPOSURE=BSINDEX, COVCAT=ALLCAUSE ALLVAS ALLCAN SMOKENEW EDUNEW DB82 occnow FAMHX ASPGRP PA82 REGION,
                      COVCONT=AGE_INT DRINKS BMI82 COFFEET REDPRC82, ORDER=FORMATTED, ROWCOL=COL,CHI=1,LIMIT=1,
                      PERDEC=0.1, CONTMEAS=MEANSD, PRINTOUT=0,TOTAL=0,COLWDTH=40,STARTLAB=,TITL=Social Support and Mortality Cohort in Black Males,
                      ODSTYPE=RTF,ODSSTYLE=Minimal,ODSPATH=D:\USER\JBLASE\Social Support\OUTPUT\Table1 BLACK MALES &SYSDATE..RTF,ORIENT=LANDSCAPE,PERMDATA=SOCIAL.BLKMALEN);

*BLACK FEMALES*;
%DESCRIPTIVE_TBL (DAT=SOCIAL.BLKFEM, EXPOSURE=BSINDEX, COVCAT=ALLCAUSE ALLVAS ALLCAN SMOKENEW EDUNEW DB82 occnow FAMHX ASPGRP PA82 REGION,
                      COVCONT=AGE_INT DRINKS BMI82 COFFEET REDPRC82, ORDER=FORMATTED, ROWCOL=COL,CHI=1,LIMIT=1,
                      PERDEC=0.1, CONTMEAS=MEANSD, PRINTOUT=0,TOTAL=0,COLWDTH=40,STARTLAB=,TITL=Social Support and Mortality Cohort in Black Females,
                      ODSTYPE=RTF,ODSSTYLE=Minimal,ODSPATH=D:\USER\JBLASE\Social Support\OUTPUT\Table1 BLACK FEMALES &SYSDATE..RTF,ORIENT=LANDSCAPE,PERMDATA=SOCIAL.BLKFEMN);

*WHITE MALES*;
%DESCRIPTIVE_TBL (DAT=SOCIAL.WHTMALE, EXPOSURE=BSINDEX, COVCAT=ALLCAUSE ALLVAS ALLCAN SMOKENEW EDUNEW DB82 occnow FAMHX ASPGRP PA82 REGION,
                      COVCONT=AGE_INT DRINKS BMI82 COFFEET REDPRC82, ORDER=FORMATTED, ROWCOL=COL,CHI=1,LIMIT=1,
                      PERDEC=0.1, CONTMEAS=MEANSD, PRINTOUT=0,TOTAL=0,COLWDTH=40,STARTLAB=,TITL=Social Support and Mortality Cohort in White Men,
                      ODSTYPE=RTF,ODSSTYLE=Minimal,ODSPATH=D:\USER\JBLASE\Social Support\OUTPUT\Table1 WHITE MALES &SYSDATE..RTF,ORIENT=LANDSCAPE,PERMDATA=SOCIAL.WHTMALEN);

*WHITE FEMALES*;
%DESCRIPTIVE_TBL (DAT=SOCIAL.WHTFEM, EXPOSURE=BSINDEX, COVCAT=ALLCAUSE ALLVAS ALLCAN SMOKENEW EDUNEW DB82 occnow FAMHX ASPGRP PA82 REGION,
                      COVCONT=AGE_INT DRINKS BMI82 COFFEET REDPRC82, ORDER=FORMATTED, ROWCOL=COL,CHI=1,LIMIT=1,
                      PERDEC=0.1, CONTMEAS=MEANSD, PRINTOUT=0,TOTAL=0,COLWDTH=40,STARTLAB=,TITL=Social Support and Mortality Cohort in White Women,
                      ODSTYPE=RTF,ODSSTYLE=Minimal,ODSPATH=D:\USER\JBLASE\Social Support\OUTPUT\Table1 WHITE FEMALES &SYSDATE..RTF,ORIENT=LANDSCAPE,PERMDATA=SOCIAL.WHTFEMN);


%MACRO WTF;
%LET DATALIST=SOCIAL.BLKMALEN SOCIAL.BLKFEMN SOCIAL.WHTMALEN SOCIAL.WHTFEMN;
%DO A=1 %TO 4;
		%LET DATASET=%SCAN(&DATALIST, &A, %STR( ));

DATA %SUBSTR(&DATASET,8) (KEEP=STRAT0_P STRAT1_P STRAT2_P STRAT3_P STRAT4_P VALUE2);
LENGTH VALUE $ 60;
SET &DATASET;

*DO FOR OUTCOMES*;
*KEEPING ONLY FREQS (NOT PERCENTAGES)*;

IF _N_ IN (6,7) THEN VAR='ALLCAUSE';
IF _N_ IN (10,11) THEN VAR='ALLVAS';
IF _N_ IN (14,15) THEN VAR='ALLCAN';


IF VAR IN ('ALLCAUSE','ALLCAN','ALLVAS') AND VALUE='1' THEN DO;
	STRAT0_P=SCAN(STRATA0,1,' ');
	STRAT1_P=SCAN(STRATA1,1,' ');
	STRAT2_P=SCAN(STRATA2,1,' ');
	STRAT3_P=SCAN(STRATA3,1,' ');
	STRAT4_P=SCAN(STRATA4,1,' ');
END;

*DO FOR COVARIATES*;

IF VAR NOT IN ('ALLCAUSE','ALLCAN','ALLVAS') THEN DO; 	
	STRAT0_P=SCAN(STRATA0,-1,'( )');
	STRAT1_P=SCAN(STRATA1,-1,'( )');
	STRAT2_P=SCAN(STRATA2,-1,'( )');
	STRAT3_P=SCAN(STRATA3,-1,'( )');
	STRAT4_P=SCAN(STRATA4,-1,'( )');
END;

%*FEMALE DATASETS*;
%IF &DATASET=SOCIAL.BLKFEMN OR &DATASET=SOCIAL.WHTFEMN %THEN %DO;

IF _N_=72 THEN DO;
	VALUE='Mean Age, years (SD)';
	STRAT0_P=STRATA0;
	STRAT1_P=STRATA1;
	STRAT2_P=STRATA2;
	STRAT3_P=STRATA3;
	STRAT4_P=STRATA4;
END;

IF _N_=75 THEN DO;
	VALUE='Mean drinks/day (SD)';
	STRAT0_P=STRATA0;
	STRAT1_P=STRATA1;
	STRAT2_P=STRATA2;
	STRAT3_P=STRATA3;
	STRAT4_P=STRATA4;
END;

IF _N_=78 THEN DO;
	VALUE='Mean BMI (SD)';
	STRAT0_P=STRATA0;
	STRAT1_P=STRATA1;
	STRAT2_P=STRATA2;
	STRAT3_P=STRATA3;
	STRAT4_P=STRATA4;
END;

IF _N_=81 THEN DO;
	VALUE='Mean total coffee consumption/day (SD)';
	STRAT0_P=STRATA0;
	STRAT1_P=STRATA1;
	STRAT2_P=STRATA2;
	STRAT3_P=STRATA3;
	STRAT4_P=STRATA4;
END;

IF _N_=84 THEN DO;
	VALUE='Mean red and processed meat intake/week (SD)';
	STRAT0_P=STRATA0;
	STRAT1_P=STRATA1;
	STRAT2_P=STRATA2;
	STRAT3_P=STRATA3;
	STRAT4_P=STRATA4;
END;

ELSE IF _N_=17 THEN VALUE='Smoking Status (%)';
ELSE IF _N_=27 THEN VALUE='Education (%)';
ELSE IF _N_=36 THEN VALUE='Diabetes (%)';
ELSE IF _N_=40 THEN VALUE='Currently employed (%)';
ELSE IF _N_=45 THEN VALUE='Family history of cancer (%)';
ELSE IF _N_=47 THEN VALUE='Aspirin use (%)';
ELSE IF _N_=55 THEN VALUE='Physical activity';


%END;

%*MALE DATASETS*; 
%*FOR MALES WE HAVE A CATEGORY FOR EVER CIGAR/PIPE AND FOR FEMALES WE DO NOT SO OUTPUT IS SLIGHTLY DIFFERENT*;

%IF &DATASET=SOCIAL.BLKMALEN OR &DATASET=SOCIAL.WHTMALEN %THEN %DO;

IF _N_=73 THEN DO;
	VALUE='Mean Age, years (SD)';
	STRAT0_P=STRATA0;
	STRAT1_P=STRATA1;
	STRAT2_P=STRATA2;
	STRAT3_P=STRATA3;
	STRAT4_P=STRATA4;
END;

IF _N_=76 THEN DO;
	VALUE='Mean drinks/day (SD)';
	STRAT0_P=STRATA0;
	STRAT1_P=STRATA1;
	STRAT2_P=STRATA2;
	STRAT3_P=STRATA3;
	STRAT4_P=STRATA4;
END;

IF _N_=79 THEN DO;
	VALUE='Mean BMI (SD)';
	STRAT0_P=STRATA0;
	STRAT1_P=STRATA1;
	STRAT2_P=STRATA2;
	STRAT3_P=STRATA3;
	STRAT4_P=STRATA4;
END;

IF _N_=82 THEN DO;
	VALUE='Mean total coffee consumption/day (SD)';
	STRAT0_P=STRATA0;
	STRAT1_P=STRATA1;
	STRAT2_P=STRATA2;
	STRAT3_P=STRATA3;
	STRAT4_P=STRATA4;
END;

IF _N_=85 THEN DO;
	VALUE='Mean red and processed meat intake/week (SD)';
	STRAT0_P=STRATA0;
	STRAT1_P=STRATA1;
	STRAT2_P=STRATA2;
	STRAT3_P=STRATA3;
	STRAT4_P=STRATA4;
END;


ELSE IF _N_=17 THEN VALUE='Smoking Status (%)';
ELSE IF _N_=28 THEN VALUE='Education (%)';
ELSE IF _N_=37 THEN VALUE='Diabetes (%)';
ELSE IF _N_=41 THEN VALUE='Currently employed (%)';
ELSE IF _N_=46 THEN VALUE='Family history of cancer (%)';
ELSE IF _N_=48 THEN VALUE='Aspirin use (%)';
ELSE IF _N_=56 THEN VALUE='Physical activity';

%END;

IF VAR='REGION' THEN VALUE='Region';
IF VAR='ALLCAUSE' AND VALUE='1' THEN VALUE='All cause deaths';
IF VAR='ALLVAS' AND VALUE='1' THEN VALUE='CVD deaths';
IF VAR='ALLCAN' AND VALUE='1' THEN VALUE='Cancer deaths';

VALUE2=VALUE;

IF ANYDIGIT(VALUE) NE 0 THEN DO;
	VALUE2=SUBSTR(VALUE,3);
END;

IF (VALUE=' ' AND STRAT0_P=' ') THEN DELETE;
ELSE IF STRAT0_P IN ('%','SD') THEN DELETE;
ELSE IF VALUE IN ('0','9','0:No') THEN DELETE;

RUN;

%END;
%MEND WTF;

%WTF;

ODS TAGSETS.EXCELXP PATH="D:\USER\JBLASE\Social Support\OUTPUT" FILE="SSI BY COVARIATE TABLE - &SYSDATE..XLS"
STYLE=PRINTER;

ODS TAGSETS.EXCELXP OPTIONS (EMBEDDED_TITLES='yes'
							 EMBEDDED_FOOTNOTES='yes'
							 SHEET_NAME='BLACK MEN');
TITLE 'BLACK MEN';
PROC PRINT DATA=BLKMALEN NOOBS STYLE(HEADER)=[JUST=CENTER];
VAR VALUE2;
VAR STRAT4_P STRAT3_P STRAT2_P STRAT1_P STRAT0_P/STYLE={TAGATTR='format:#,##'};
RUN;QUIT; 

ODS TAGSETS.EXCELXP OPTIONS (EMBEDDED_TITLES='yes'
							 EMBEDDED_FOOTNOTES='yes'
							 SHEET_NAME='BLACK WOMEN');
TITLE 'BLACK WOMEN';
PROC PRINT DATA=BLKFEMN NOOBS STYLE(HEADER)=[JUST=CENTER];
VAR VALUE2;
VAR STRAT4_P STRAT3_P STRAT2_P STRAT1_P STRAT0_P/STYLE={TAGATTR='format:#,##'};
RUN;QUIT; 

ODS TAGSETS.EXCELXP OPTIONS (EMBEDDED_TITLES='yes'
							 EMBEDDED_FOOTNOTES='yes'
							 SHEET_NAME='WHITE MEN');
TITLE 'WHITE MEN';
PROC PRINT DATA=WHTMALEN NOOBS STYLE(HEADER)=[JUST=CENTER];
VAR VALUE2;
VAR STRAT4_P STRAT3_P STRAT2_P STRAT1_P STRAT0_P/STYLE={TAGATTR='format:#,##'};
RUN;QUIT; 

ODS TAGSETS.EXCELXP OPTIONS (EMBEDDED_TITLES='yes'
							 EMBEDDED_FOOTNOTES='yes'
							 SHEET_NAME='WHITE WOMEN');
TITLE 'WHITE WOMEN';
PROC PRINT DATA=WHTFEMN NOOBS STYLE(HEADER)=[JUST=CENTER];
VAR VALUE2;
VAR STRAT4_P STRAT3_P STRAT2_P STRAT1_P STRAT0_P/STYLE={TAGATTR='format:#,##'};
RUN;QUIT;

ODS TAGSETS.EXCELXP CLOSE;

***********************************************************************************************************;
*ALL CAUSE, CANCER, AND CVD MORTALITY MODELS BY RACE/SEX GROUPS AND FOLLOW UP TIME (TABLE 1 TAB IN WORKBOOK)
*ALL CAUSE, CANCER, AND CVD MORTALITY MODELS IN ENTIRE COHORT BY FOLLOW UP TIME (TABLE 2 TAB IN WORKBOOK)*;
***********************************************************************************************************;

%INCLUDE 'D:\USER\CCLEMENTS\MACROS\SURVMODS.sas'; *CHRISSY'S SURVMODS MACRO*;

*CL: 1=ALL CAUSE MORTALITY*
	 2=ALL CANCER MORTALITY
	 3=ALL VASCULAR MORTALITY*;

%MACRO JBLAY (CL=);

%LET FAILLIST=FAIL1B_MO FAIL2B_MO FAIL3B_MO FAILAGELIM_MO;
%LET STRATLIST=SEX=0 AND BLACK=1-SEX=1 AND BLACK=1-SEX=0 AND WHITE=1-SEX=1 AND WHITE=1;
%LET LABELIST=BLKMEN BLKWOMEN WHTMEN WHTWOMEN;

%IF &CL=1 %THEN %LET CASELIST=CORE1B CORE2B CORE3B ALLCAUSE;
%ELSE %IF &CL=2 %THEN %LET CASELIST=CORE1B_CCR CORE2B_CCR CORE3B_CCR ALLCAN;
%ELSE %IF &CL=3 %THEN %LET CASELIST=CORE1B_VAS CORE2B_VAS CORE3B_VAS ALLVAS;


%DO A=1 %TO 4;
		%LET STRATMAC=%SCAN(&STRATLIST, &A, %STR(-));
		%LET SLABEL=%SCAN(&LABELIST, &A, %STR( ));

%DO B=1 %TO 4;
		%LET CASEVAR=%SCAN(&CASELIST, &B, %STR( ));
		%LET FAILVAR=%SCAN(&FAILLIST, &B, %STR( ));
				
%SURVMODS(DATASET=SOCIAL.FINALCOHORT,FAIL=&FAILVAR,CASE=&CASEVAR,EXP=BSINDEX,REF=0,CONTEXP=, COV=SMOKENEW EDUNEW BMI DB82, STRAT=&STRATMAC, STRATLBL=&SLABEL, AA=0,
STRATA=AGE_INT, ACROSS= , TOTAL= )  

DATA &CASEVAR._BSINDEX_&SLABEL._NEW (KEEP=MVHRCI CASES STRATLBL EXPLBL CASELBL);
SET &CASEVAR._BSINDEX_&SLABEL;

*USING THIS TO ONLY GET CASES AND NOT PYEARS*;
CASES=SCAN(CASEPYR,1,' ');

RUN;

PROC APPEND BASE= 
	%IF &CL=1 %THEN ALLCAUSEM; 
	%ELSE %IF &CL=2 %THEN ALLCANCER; 
	%ELSE %IF &CL=3 %THEN ALLVASCULAR;  
DATA=&CASEVAR._BSINDEX_&SLABEL._NEW FORCE; RUN;

%END;
%END;

%***SEPERATE TABLE WITH JUST RIGHT COLUMN FROM OLD TABLE, ALL OUTCOMES IN THIS TABLE***; 
%*POPULATION IS ENTIRE COHORT (CONTROLLING FOR SEX AND RACE)*;

%DO C=1 %TO 4;
		%LET CASEVAR=%SCAN(&CASELIST, &C, %STR( ));
		%LET FAILVAR=%SCAN(&FAILLIST, &C, %STR( ));
				
%SURVMODS(DATASET=SOCIAL.FINALCOHORT,FAIL=&FAILVAR,CASE=&CASEVAR,EXP=BSINDEX,REF=0,CONTEXP=, COV=SMOKENEW EDUNEW BMI DB82 BLACK SEX, STRAT=, STRATLBL=, AA=0,
STRATA=AGE_INT, ACROSS= , TOTAL= );

DATA &CASEVAR._BSINDEX_NEW (KEEP=MVHRCI CASES STRATLBL EXPLBL CASELBL);
SET &CASEVAR._BSINDEX;

*USING THIS TO ONLY GET CASES AND NOT PYEARS*;
CASES=SCAN(CASEPYR,1,' ');

RUN;

PROC APPEND BASE= 
	%IF &CL=1 %THEN ALLCAUSEM_TOT; 
	%ELSE %IF &CL=2 %THEN ALLCANCER_TOT; 
	%ELSE %IF &CL=3 %THEN ALLVASCULAR_TOT;  
DATA=&CASEVAR._BSINDEX_NEW FORCE; RUN;

%END;


%MEND JBLAY;

%JBLAY (CL=1);
%JBLAY (CL=2);
%JBLAY (CL=3);


*OUTPUTTING TABLES 1 AND 2*;

ODS TAGSETS.EXCELXP PATH="D:\USER\JBLASE\Social Support\OUTPUT" FILE="TABLES 1 AND 2 - &SYSDATE..XLS"
STYLE=PRINTER;

ODS TAGSETS.EXCELXP OPTIONS(SHEET_NAME='TABLE 1 - ALL CAUSE');
PROC PRINT DATA=ALLCAUSEM NOOBS STYLE(HEADER)=[JUST=CENTER];
VAR CASELBL/STYLE={JUST=CENTER};
VAR CASES/STYLE={TAGATTR='format:#,##' JUST=CENTER};
VAR EXPLBL; 
VAR MVHRCI STRATLBL/STYLE={JUST=CENTER};

RUN;QUIT; 

ODS TAGSETS.EXCELXP OPTIONS(SHEET_NAME='TABLE 1 - ALL CANCER');
PROC PRINT DATA=ALLCANCER NOOBS STYLE(HEADER)=[JUST=CENTER];
VAR CASELBL/STYLE={JUST=CENTER};
VAR CASES/STYLE={TAGATTR='format:#,##' JUST=CENTER};
VAR EXPLBL; 
VAR MVHRCI STRATLBL/STYLE={JUST=CENTER};
RUN; QUIT; 

ODS TAGSETS.EXCELXP OPTIONS(SHEET_NAME='TABLE 1 - ALL CARDIOVASCULAR DISEASE');
PROC PRINT DATA=ALLVASCULAR NOOBS STYLE(HEADER)=[JUST=CENTER];
VAR CASELBL/STYLE={JUST=CENTER};
VAR CASES/STYLE={TAGATTR='format:#,##' JUST=CENTER};
VAR EXPLBL MVHRCI STRATLBL/STYLE={JUST=CENTER};
RUN; QUIT; 

ODS TAGSETS.EXCELXP OPTIONS(SHEET_NAME='TABLE 2 - ALL CAUSE TOTAL POPULATION');
PROC PRINT DATA=ALLCAUSEM_TOT NOOBS STYLE(HEADER)=[JUST=CENTER];
VAR CASELBL/STYLE={JUST=CENTER};
VAR CASES/STYLE={TAGATTR='format:#,##' JUST=CENTER};
VAR EXPLBL;
VAR MVHRCI STRATLBL/STYLE={JUST=CENTER};
RUN; QUIT; 

ODS TAGSETS.EXCELXP OPTIONS(SHEET_NAME='TABLE 2 - ALL CANCER TOTAL POPULATION');
PROC PRINT DATA=ALLCANCER_TOT NOOBS STYLE(HEADER)=[JUST=CENTER];
VAR CASELBL/STYLE={JUST=CENTER};
VAR CASES/STYLE={TAGATTR='format:#,##' JUST=CENTER};
VAR EXPLBL MVHRCI STRATLBL/STYLE={JUST=CENTER};
RUN; QUIT; 

ODS TAGSETS.EXCELXP OPTIONS(SHEET_NAME='TABLE 2 - ALL CVD TOTAL POPULATION');
PROC PRINT DATA=ALLVASCULAR_TOT NOOBS STYLE(HEADER)=[JUST=CENTER];
VAR CASELBL/STYLE={JUST=CENTER};
VAR CASES/STYLE={TAGATTR='format:#,##' JUST=CENTER};
VAR EXPLBL MVHRCI STRATLBL/STYLE={JUST=CENTER};
RUN; QUIT; 

ODS TAGSETS.EXCELXP CLOSE;

ODS LISTING;



*********************************************************************;
***THIRD TABLE. 4 COMPONENT EXPOSURE, STRATIFIED BY SEX/RACE GROUP*** 
*********************************************************************;
*NOTE - WHEN RUNNING FOR ENTIRE COHORT, CONTROL FOR RACE AND SEX!!!*;
*MACRO FOR MULTIPLE EXPOSURES*;
*THE TABLE FOR THIS IS IN THE WORKBOOK ENTITLED 'TABLES 1 AND 2 - 08DEC15' AND THIS IS IN THE TAB ENTITLED 'TABLE 3' - IT WAS ORIGINALLY OUTPUT TO A WORD DOCUMENT BUT I 
COPIED AND PASTED INTO THE WORKBOOK TO PUT IT ALL TOGETHER*;

%MACRO FOURCOVARS (EXP=,DESC=,CL=);

%LET FAILLIST=FAIL1B_MO FAIL2B_MO FAIL3B_MO FAILAGELIM_MO;
%LET DATALIST=SOCIAL.BLKMALE SOCIAL.BLKFEM SOCIAL.WHTMALE SOCIAL.WHTFEM;

%IF &CL=1 %THEN %LET CASELIST=CORE1B CORE2B CORE3B ALLCAUSE;
%ELSE %IF &CL=2 %THEN %LET CASELIST=CORE1B_CCR CORE2B_CCR CORE3B_CCR ALLCAN;
%ELSE %IF &CL=3 %THEN %LET CASELIST=CORE1B_VAS CORE2B_VAS CORE3B_VAS ALLVAS;

%DO A=1 %TO 4;
		%LET DATASET=%SCAN(&DATALIST, &A, %STR( ));

%DO B=1 %TO 4;
		%LET CASEVAR=%SCAN(&CASELIST, &B, %STR( ));
		%LET FAILVAR=%SCAN(&FAILLIST, &B, %STR( ));

ODS OUTPUT PARAMETERESTIMATES=%SUBSTR(&DATASET,8)_&CASEVAR._TEMP;
PROC PHREG DATA=&DATASET;
CLASS SMOKENEW EDUNEW BMI (REF='2: 18.5-<25')&EXP/PARAM=REF REF=FIRST ORDER=FORMATTED;
MODEL &FAILVAR*&CASEVAR(0)=&EXP SMOKENEW EDUNEW BMI DB82/RL;
STRATA AGE_INT;
WHERE &FAILVAR NE .;
RUN;
ODS OUTPUT CLOSE;

DATA %SUBSTR(&DATASET,8)_&CASEVAR._NEW;
    SET %SUBSTR(&DATASET,8)_&CASEVAR._TEMP;
LENGTH CI OUTCOME $15 RRCI $25;
%IF &EXP=MARRIED FRIENDREL CLUBGRP_SCALE CHURCH_SCALE %THEN %DO;
    IF PARAMETER IN ("MARRIED","FRIENDREL", "CLUBGRP_SCALE","CHURCH_SCALE");
%END;
%ELSE %IF &EXP=MARRIED BSINDEX_3COMP %THEN %DO;
    IF PARAMETER IN ("MARRIED", "BSINDEX_3COMP");
%END;
    RR=PUT(ROUND(HAZARDRATIO,0.01),4.2);
    LL=PUT(ROUND(HRLOWERCL,0.01),4.2);
    UL=PUT(ROUND(HRUPPERCL,0.01),4.2);
    CI=CAT(LL,", ",UL);
    RRCI=CAT(RR," (",(TRIM(CI)),")");
    PVALUE=PROBCHISQ;
    OUTCOME="&CASEVAR";
    FORMAT PVALUE BEST6.4;
    MERGEVAR=1*(SUBSTR(CLASSVAL0,1,1));
RUN;

PROC SORT DATA=%SUBSTR(&DATASET,8)_&CASEVAR._NEW; BY ClassVal0; RUN;

%DO C=1 %TO %SYSFUNC(COUNTW(&EXP));
        %LET EXP4=%SCAN(&EXP, &C, %STR( ));

     PROC FREQ DATA=&DATASET;
     TABLES &EXP4/ NOPERCENT NOCUM;
     WHERE &CASEVAR=1 AND &FAILVAR NE .;
     ODS OUTPUT OneWayFreqs=%SUBSTR(&DATASET,8)_&CASEVAR._%SUBSTR(&EXP4,1,4);
     RUN;
     ODS OUTPUT CLOSE;

    DATA %SUBSTR(&DATASET,8)_&CASEVAR._%SUBSTR(&EXP4,1,4)_R;
    SET %SUBSTR(&DATASET,8)_&CASEVAR._%SUBSTR(&EXP4,1,4);
        LENGTH VARNAME $25;
        VARNAME="&EXP4";
    RUN;

PROC SORT DATA=%SUBSTR(&DATASET,8)_&CASEVAR._%SUBSTR(&EXP4,1,4)_R; BY F_&EXP4; RUN;

%END;

DATA %SUBSTR(&DATASET,8)_&CASEVAR._FINAL (KEEP=EXPVAR CASE_FREQ RRCI VARNAME);
MERGE   %SUBSTR(&DATASET,8)_&CASEVAR._NEW (RENAME=(ClassVal0=EXPVAR))
            %DO C=1 %TO %SYSFUNC(COUNTW(&EXP));
                %LET EXP4=%SCAN(&EXP, &C, %STR( ));
        %SUBSTR(&DATASET,8)_&CASEVAR._%SUBSTR(&EXP4,1,4)_R (RENAME=(F_&EXP4=EXPVAR))
            %END;
            ;
BY EXPVAR;

IF RRCI=' ' THEN RRCI='1.00 (ref)';
CASE_FREQ=PUT(FREQUENCY, COMMA7.);

RUN;

PROC SORT DATA=%SUBSTR(&DATASET,8)_&CASEVAR._FINAL; BY VARNAME; RUN;

%END;
%END;

ODS RTF FILE= "D:\USER\JBLASE\Social Support\OUTPUT\&DESC - &SYSDATE..RTF";

%DO A=1 %TO 4;
        %LET DATASET=%SCAN(&DATALIST, &A, %STR( ));

%DO B=1 %TO 4;
		%LET CASEVAR=%SCAN(&CASELIST, &B, %STR( ));
    
TITLE "%SUBSTR(&DATASET,8), &CASEVAR, &DESC";
PROC PRINT DATA=%SUBSTR(&DATASET,8)_&CASEVAR._FINAL; VAR EXPVAR CASE_FREQ RRCI; RUN;

%END;
%END;

ODS RTF CLOSE;

%MEND FOURCOVARS;

%FOURCOVARS (EXP=MARRIED FRIENDREL CLUBGRP_SCALE CHURCH_SCALE, DESC=FOUR SCALE COMPONENTS, CL=1); *ALL CAUSE MORTALITY*;
%FOURCOVARS (EXP=MARRIED FRIENDREL CLUBGRP_SCALE CHURCH_SCALE, DESC=FOUR SCALE COMPONENTS CANCER, CL=2); *ALL CANCER MORTALITY*;
