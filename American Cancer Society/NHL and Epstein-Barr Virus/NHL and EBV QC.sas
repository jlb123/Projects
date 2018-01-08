*QUALITY CONTROL PROGRAM STARTS HERE*;

/*============================================================================================================
  Project Name     : NHL & EBV
  PI               : LAUREN TERAS
  Program Objective: QC CHECK FOR EBV ( ZEBRA, EA, VCA, and EBNA)
  Dataset used     : 
  Last update      : 6/28/2013 - RUN ON JENNY BLASE S-DRIVE
					 7/10/2013 - Edited by Jenny Blase
  ===========================================================================================================*/
   
* NOTE: RUN THIS PROGRAM LOCALLY *;


FOOTNOTE1  " "; 
FOOTNOTE2  " ";

options nodate center pageno=1 ls=85 ps=70 nofmterr MACROGEN;

dm  'out; clear; log; clear;';        *----- CLEARING LOG & OUTPUT WINDOWS ; 

LIBNAME EBV 'S:\USER\JBLASE\EBV Program Review\DATA';  

*=========================== Program starts here ================================================================; 

PROC IMPORT   OUT= EBV.INFNHL1000
              DATAFILE= "S:\USER\JBLASE\EBV Program Review\DATA\infect-nhl-1000dil.xls" 
              DBMS=EXCEL REPLACE;
			  RANGE = "A1:AY918"; 
RUN;

PROC SQL; 
SELECT  COUNT(DISTINCT PLATE), COUNT(DISTINCT BARCODE), COUNT(*) 
        INTO :NUMPLT, :NUMID, :NUMROW
FROM EBV.INFNHL1000
; 
QUIT; 

*CREATING A TEMPORARY DATASET FROM THE PERMANENT DATASET INFNHL1000*;

DATA INFNHL1000_TEMP;
SET EBV.INFNHL1000;
RUN;

* QC SUBJECTS, NEED TO BE TAKE OUT FROM THE RECEIVED FILES AND RUN QC PROGRAM ON THEM; 
DATA EBV.QCS QCS; 
SET EBV.shiplocs_batch_qcs_12mar12; 
RUN; 


PROC SQL; 
SELECT  COUNT(DISTINCT PLATE), COUNT(DISTINCT BARCODE), COUNT (DISTINCT SUBJID), COUNT(*) 
        INTO :NUMPLTQC, :NUMLABQC, :NUMIDQC, :NUMROWQC
FROM QCS
; 
QUIT; 


options nosource; 

	%put *======== DATA DESCRIPTION  =============*; 
	%PUT ===RECEIVED FILE ; 
	%PUT ---NUMBER OF PLATES = %LEFT(&NUMPLT) ; 
	%PUT ---NUMBER OF BARCODE= %LEFT(&NUMID) ; 
	%PUT ---NUMBER OF ROWS = %LEFT(&NUMROW) ; 
    %put                                    ; 
	%PUT ===QC FILE ; 
	%PUT ---NUMBER OF PLATES = %LEFT(&NUMPLTQC); 
	%PUT ---NUMBER OF BARCODE = %LEFT(&NUMLABQC); 
	%PUT ---NUMBER OF ID = %LEFT(&NUMIDQC); 
	%PUT ---NUMBER OF ROW = %LEFT(&NUMROWQC); 
	%PUT *========================================*; 

options source; 


*FROM RECEIVED FILE, SELECT SUBJECTS WITH SAME BARCODE IN THE QC FILE; 
*56 BARCODES; 

PROC SQL; 
CREATE TABLE QCFILE1000 AS 
SELECT INFNHL1000_TEMP.* , QCS.SUBJID
FROM INFNHL1000_TEMP, QCS
 WHERE  INFNHL1000_TEMP.BARCODE = QCS.BARCODE
; 
QUIT; 

*PROC MEANS RESULTS; 

%include 'S:\USER\LTERAS\Programs\Infection_NHL\QC\QC-Check-macro.sas'; 

TITLE2'QC ANALYSIS'; 

OPTIONS ORIENTATION=PORTRAIT;
ODS RTF STYLE=JOURNAL BODYTITLE FILE="S:\USER\JBLASE\EBV Program Review\OUTPUT\LOG QC GRAPHS-&SYSDATE..RTF"  STARTPAGE=NO ;

proc sort data = QCFILE1000;
by subjid plate;
run;

*****EPSTEIN BARR VIRUS******;
**Zebra**;	

DATA QCZEBRA;
SET QCFILE1000;
WHERE ZEBRA>1;
LOG_ZEBRA = LOG(ZEBRA); 
RUN;

PROC PRINT DATA=QCZEBRA;
VAR subjid plate ZEBRA LOG_ZEBRA;
RUN;

/*%QCCHECK (QCZEBRA,ZEBRA, PLATE);*/
%QCCHECK (QCZEBRA,LOG_ZEBRA, PLATE);

**EBNA truncated**;
DATA QCEBNA_truncated;
SET QCFILE1000;
WHERE EBNA_truncated>1;
LOG_EBNA_truncated = LOG(EBNA_truncated); 
RUN;

PROC PRINT DATA=QCEBNA_truncated;
VAR subjid plate EBNA_truncated LOG_EBNA_truncated;
RUN;

%QCCHECK (QCEBNA_truncated,LOG_EBNA_truncated, PLATE);

**EA-D**;

DATA QCEA_D;
SET QCFILE1000;
WHERE EA_D>1;
LOG_EA_D = LOG(EA_D); 
RUN;

PROC PRINT DATA=QCEA_D; 
VAR subjid plate EA_D  LOG_EA_D;
RUN;

%QCCHECK (QCEA_D,LOG_EA_D, PLATE);

**VCA p18**;

DATA QCVCA_P18;
SET QCFILE1000;
WHERE VCA_P18>1;
LOG_VCA_P18 = LOG(VCA_P18); 
RUN;

PROC PRINT DATA=QCVCA_P18;
VAR subjid plate VCA_P18 LOG_VCA_P18;
RUN;

%QCCHECK (QCVCA_P18,LOG_VCA_P18, PLATE);

ODS RTF CLOSE; 
