/*============================================================================================================
  Project Name     : CRC & H. PYLORI
  PI               : LAUREN TERAS
  Program Objective: QC CHECK FOR H. PYLORI
  Dataset used     : HPY.LABDATA
  Last update      : 5/27/15 BY JENNY BLASE
  ===========================================================================================================*/
   
* NOTE: RUN THIS PROGRAM LOCALLY *;

options nodate center pageno=1 ls=85 ps=70 nofmterr mprint;

dm  'out; clear; log; clear;';        *----- CLEARING LOG & OUTPUT WINDOWS ; 

LIBNAME HPY 'S:\USER\JBLASE\H Pylori and CRC\DATA'; 
%include 'S:\USER\LTERAS\Programs\Infection_NHL\QC\QC-Check-macro.sas'; 
 

*=========================== Program starts here ================================================================; 
/**/
/*PROC IMPORT   OUT= HPY.LABDATA*/
/*              DATAFILE= "S:\USER\JBLASE\H Pylori and CRC\DATA\Transferfile L Teras CRC.XLSX" */
/*              DBMS=EXCELCS REPLACE;*/
/*			  SHEET="study data$"; */
/*			  RANGE="A4:AZ1551";*/
/*RUN;*/
/**/

*PULLING OUT QC OBSERVATIONS ONLY*;
DATA QCONLY;
SET HPY.plate_id_info_all_jenny3;

IF CaCoQC='5';

RUN;

PROC SORT DATA=HPY.LABDATA OUT=LABDATASORT; BY CURRENT_LABEL; RUN;
PROC SORT DATA=QCONLY OUT=QCSORT; BY CURRENT_LABEL; RUN;

*FROM RECEIVED FILE, SELECT SUBJECTS WITH SAME BARCODE IN THE QC FILE; 
*58 BARCODES; 

DATA QCFINAL;
MERGE QCSORT (IN=INQCS)
LABDATASORT (RENAME=(HP_10__G27_=HP10_G27 HP_73_=HP73 HP_231=HP231 HP_243_=HP243 HP_305_=HP305 HP_410_=HP410 HP_537_=HP537 HP_547_1=HP547_1 HP_547_2_=HP547_2 HP_695_1_=HP695_1 HP_695_2_=HP695_2
						HP_875_=HP875 HP_887_1_=HP887_1 HP_887_2_=HP887_2 HP_1098_=HP1098 HP_1104_=HP1104 HP_1564_=HP1564 cagA_G27__subfragment=CAGA_G27 cagA_F32__subfragment=CAGA_F32 
						homB_1__J99__=HOMB1_J99 homB_2__J99__=HOMB2_J99 HomB__J99_=HOMB_J99 HPyV_9_VP1=HPYV9 HPyV_10_VP1=HPYV10 HPyV_10_T_antigen=HPYV10T_ANT EBNA_truncated=EBNA
						pp150_Nter=PP150));
BY Current_Label;
IF INQCS;

P_53=INPUT(p53,2.); *CONVERTING THIS ANTIGEN FROM CHARACTER TO NUMERIC*;

RUN;

proc sort data = QCFINAL; by subjid plate; run;


%MACRO QCDATASETS;

%LET ANTLIST=HP10_G27 HP73 HP231 HP243 HP305 HP410 HP537 HP547 HP695 HP875 HP887 HP1098 HP1104 HP1564 HOMB_J99;
	%DO A=1 %TO 15;
		%LET ANTIGEN=%SCAN(&ANTLIST, &A, %STR( ));

DATA QC&ANTIGEN;
SET QCFINAL;
WHERE &ANTIGEN>1;
LOG_&ANTIGEN = LOG(&ANTIGEN); 
RUN;

%QCCHECK (QC&ANTIGEN,LOG_&ANTIGEN,PLATE);

%END;

%MEND QCDATASETS;

TITLE2'H. PYLORI ANTIGENS AND CRC QC ANALYSIS'; 
OPTIONS ORIENTATION=PORTRAIT;
ODS RTF STYLE=JOURNAL BODYTITLE FILE="S:\USER\JBLASE\H Pylori and CRC\PROGRAM REVIEW\OUTPUT\LOG QC GRAPHS-&SYSDATE..RTF"  STARTPAGE=NO;
%QCDATASETS;
ODS RTF CLOSE; 
TITLE;
