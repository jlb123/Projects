
**************RUN METAS LOCALLY**************;
*************************************************************;
*				  META ANALYSIS - ALL STUDIES				*;
*************************************************************;
OPTIONS MACROGEN;

%INCLUDE "S:\USER\JBLASE\MACROS\poolrr.sas"; *POOLRR MACRO MODIFIED BY BRIAN*;
%INCLUDE "S:\USER\JBLASE\MACROS\forest.sas"; *FOREST MACRO MODIFIED BY BRIAN*;

*ALL STUDIES WITH ALL NHL AS OUTCOME*;
PROC IMPORT OUT= WORK.allnhl 
            DATAFILE= "H:\EBV\Meta-analysis\Meta Analysis Data.xlsx" 
            DBMS=EXCELCS REPLACE;
     		SHEET="All NHL$"; 
			RANGE = "B1:I18"; 
RUN;
;  
PROC PRINT DATA=ALLNHL; RUN;

*PROSPECTIVE STUDIES*;
PROC IMPORT OUT= WORK.PROSP 
            DATAFILE= "H:\EBV\Meta-analysis\Meta Analysis Data.xlsx" 
            DBMS=EXCEL REPLACE;
     		SHEET="Prospective$";  GETNAMES=YES;  MIXED=NO;  SCANTEXT=YES;  USEDATE=YES;  SCANTIME=YES;  
RUN;
;
PROC PRINT DATA=PROSP; RUN;

*I-SQUARE AND Q-TEST*;
ODS RTF STYLE=JOURNAL FILE = "S:\USER\JBLASE\EBV Program Review\OUTPUT\META EA AND VCA, I-SQUARE AND Q TEST &sysdate..RTF";

*ALL NHL ON EA*;
%poolrr(data=allnhl,title=EA - NHL,cat= (type=1),plot=1,msize=,msex=,mtype=);
%forest(title=,msize=,msex=,mtype=);

*ALL NHL ON VCA*;
%poolrr(data=allnhl,title=VCA - NHL,cat= (type=2),plot=1,msize=,msex=,mtype=);
%forest(title=,msize=,msex=,mtype=);

*ALL NHL ON EA - PROSPECTIVE*;
%poolrr(data=PROSP,title=EA PROSPECTIVE,cat= (type=1),plot=1,msize=,msex=,mtype=);
%forest(title=,msize=,msex=,mtype=);

*ALL NHL ON VCA - PROSPECTIVE*;
%poolrr(data=PROSP,title=VCA PROSPECTIVE,cat= (type=2),plot=1,msize=,msex=,mtype=);
%forest(title=,msize=,msex=,mtype=);

ODS RTF CLOSE;
