filename trans 'H:\Thesis\ICPSR_20240\ICPSR_20240\DS0002\20240-0002-Data.STC';
libname jenny 'H:\Thesis\ICPSR_20240\ICPSR_20240\DS0002';
PROC cimport library=jenny infile=trans;
RUN;

%include "H:\Thesis\Thesis Analysis\Thesis Formatting.sas";
%include "H:\Thesis\Thesis Analysis\Severity Macro.sas";

DATA jenny.thesis;
	set jenny.Da20240p2;
RUN;

***DATA CLEANING***;

data jenny.one (keep = caseid DA31B_101 age mar3cat SEX RANCEST ED4CAT sr123 dsm_asa DSM_AGO DSM_ALA DSM_ALD DSM_ADD DSM_BIPOLARI 
DSM_BIPOLARII DSM_DYS DSM_BINGEH DSM_BUL DSM_ANO DSM_CD DSM_DRA DSM_DRD DSM_GADH DSM_IED DSM_MDDH DSM_ODD DSM_PDS DSM_PTS 
DSM_SAD DSM_SO DSM_SP da33 da34 da35 da36 NCSRWTLG NCSRWTSH SESTRAT SECLUSTR SN2 SN7 MR41_1c SN3 SN8 MR41_1D povindex sr16 sr122
D_ASA12	D_AGO12	D_ALA12	D_ALD12	D_ADD12	D_BIPOLARI12 D_BIPOLARII12 D_CD12 D_DRA12 D_DRD12 D_ALAH12 D_DYS12 D_DYSH12	D_GAD12	D_GADH12	
D_IED12	D_IEDH12 D_DRAH12 D_MDDH12	D_ODD12	D_ODDH12 D_PDS12 D_PTS12 D_ASA12 D_SO12	D_SP12 D_BINGEANY12	D_BINGEH12 D_BUL12 D_BULH12	D_ANO12 d68
SC10_5E301 SC10_5E302 SC10_5E303 SC10_5E304 SC10_5E305 SC10_5E306 SC10_5E307 SC10_5I01 SC10_5I02 SC10_5I03 SC10_5I04 SC10_5I05 SC10_5I06
SC10_5I07 SC10_5I08 SC10_5I09 SC10_5I10 SC10_5I11 SC10_7A301 SC10_7A302 SC10_8F301 SC10_8F302 SC10_8F303 SC10_8F304 SC10_8F305
SC10_8F306 SC10_8F307 SC10_8G301 SC10_8G302 PS81 PS82 PS83 PS84 PS10 PS10A M1 M7E M7N M7o PS4 SD9 SD14 SD22 SD27 SC10_14 SC10_4g
SC10_4a SC10_4b SC10_4c SC10_4d SC10_4e SC10_4f EM7_101 EM7_102 EM7_103 EM7_104 EM10 EM22a IED25G IED25h MR44A CN11 pd46 sp25
so23 ag22 g40 ied28 pt280 ea34 ad12 od10 sa27 EM23a EM23b cc72 d66a d66b d66c d66d pd44a pd44b pd44c pd44d cn10 sd10a sd23a sd23 sd10
sp23a sp23b sp23c sp23d so21a so21b so21c so21d ag20a ag20b ag20c ag20d g38a g38b g38c g38d ied26a ied26b ied26c ied26d pt278a pt278b
pt278c pt278d ea32a ea32b ea32c ea32d ad10a ad10b ad10c ad10d od8a od8b od8c od8d sa25a sa25b sa25c sa25d sc10_2 sc10_3 sr109 em7_1 cc70 cc74 cc81 cc79 cc77
sd3 sd16 mr42a sd5 sd18 ied25d ied25e ied25f su38a su38b su38c su38d su86a su86b su86c su86d SR20 SR41 SR11b SR5A SR58 SR49 SR67 SU103 SR8
D_MDE12);
	set jenny.thesis;
run;

data two;
	set jenny.one;

	IF RELATION = -8 THEN RELATION = .;
 	IF RELATION = -9 THEN RELATION = .;

*Recoding DA31B_101 into Streensland's 5 categories + Atheism/agnosticism (Relig6cat)*;

if DA31B_101 eq 12 or DA31B_101 eq 13 then relig6cat = 1;
else if DA31B_101 eq 8 or DA31B_101 eq 9 or DA31B_101 eq 10 then relig6cat = 2;
else if DA31B_101 eq 1 or DA31B_101 eq 3 or DA31B_101 eq 4 or DA31B_101 eq 6 or DA31B_101 eq 7 then relig6cat = 3;
else if DA31B_101 eq 2 or DA31B_101 eq 5 then relig6cat = 4;
else if DA31B_101 eq 14 then relig6cat = 5;	
else if DA31B_101 eq 11 then relig6cat = 6;
else relig6cat = 7;

*Recoding relig6cat so athiest/agnostic=missing*;

if relig6cat = 6 or relig6cat=7 then relig_recode=.;
else relig_recode=relig6cat;

*Recoding age into 4 categories (age4cat)*;

if age ge 18 and age le 34 then age4cat = 1;
else if age ge 35 and age le 49 then age4cat = 2;
else if age ge 50 and age le 64 then age4cat = 3;
else if age ge 65 then age4cat = 4;
else age4cat = .;

*Recoding sex to make it a 0/1 variable*;

if sex = 2 then sex_recode=0;
else sex_recode=sex;

*Making a variable that identifies diagnosed individuals over the past 12 MONTHS (dsmdx12)*;

if D_ASA12=1 or	D_AGO12=1 or D_ALA12=1 or D_ALD12=1 or	D_ADD12=1 or D_BIPOLARI12=1 or D_BIPOLARII12=1 or D_CD12=1 or D_DRA12=1 or D_DRD12=1 or D_ALAH12=1 or 
D_DYS12=1 or D_DYSH12=1 or	D_GAD12=1 or D_GADH12=1 or D_IED12=1 or	D_IEDH12=1 or D_DRAH12=1 or D_MDDH12=1 or D_ODD12=1 or D_ODDH12=1 or D_PDS12=1 or D_PTS12=1 or 
D_ASA12=1 or D_SO12=1 or D_SP12=1 or D_BINGEH12=1 or D_BUL12=1 or D_BULH12=1 or D_ANO12=1 then dsmdx12 = 1;
else dsmdx12=0;

*Making a variable that identifies whether someone is diagnosed with a mental disorder or not (dsmdx)*;

if dsm_asa=1 or DSM_AGO=1 or DSM_ALA=1 or DSM_ALD=1 or DSM_ADD=1 or DSM_BIPOLARI=1 or DSM_BIPOLARII=1 or DSM_DYS=1 or 
DSM_BINGEH=1 or DSM_BUL=1 or DSM_ANO=1 or DSM_CD=1 or DSM_DRA=1 or DSM_DRD=1 or DSM_GADH=1 or DSM_IED=1 or DSM_MDDH=1 or 
DSM_ODD=1 or DSM_PDS=1 or DSM_PTS=1 or DSM_SAD=1 or DSM_SO=1 or DSM_SP=1 then dsmdx=1;
else dsmdx=0;

*RELIGIOSITY SCALE*;

*Recoding frequency of religious service attendance for religiosity scale (da33_scale)*;

if da33 = 1 then da33_scale = 5;
else if da33 = 2 then da33_scale = 4;
else if da33 = 3 then da33_scale = 3;
else if da33 = 4 then da33_scale = 2;
else if da33 = 5 then da33_scale = 1;
else da33_scale = .;

*Recoding importance of religion in daily life for religiosity scale (da34_scale)*;

if da34 = 1 then da34_scale = 4;
else if da34 = 2 then da34_scale = 3;
else if da34 = 3 then da34_scale = 2;
else if da34 = 4 then da34_scale = 1;
else da34_scale = .;

*Recoding religious comfort for religiosity scale (da35_scale)*;

if da35 = 1 then da35_scale = 4;
else if da35 = 2 then da35_scale = 3;
else if da35 = 3 then da35_scale = 2;
else if da35 = 4 then da35_scale = 1;
else da35_scale = .;

*Recoding religious decision-making for religiosity scale (da36_scale)*;

if da36 = 1 then da36_scale = 4;
else if da36 = 2 then da36_scale = 3;
else if da36 = 3 then da36_scale = 2;
else if da36 = 4 then da36_scale = 1;
else da36_scale = .;

*SOCIAL NETWORK*;

*Recoding how much you can rely on relatives that dont live w/ you for serious problem (SN2_scale)*;
if sn2 = 1 then sn2_scale = 4;
else if sn2 = 2 then sn2_scale = 3;
else if sn2 = 3 then sn2_scale = 2;
else if sn2 = 4 then sn2_scale = 1;
else sn2_scale = .;

*Recoding how much you can rely on friends for serious problem (SN7_scale)*;
if sn7 = 1 then sn7_scale = 4;
else if sn7 = 2 then sn7_scale = 3;
else if sn7 = 3 then sn7_scale = 2;
else if sn7 = 4 then sn7_scale = 1;
else sn7_scale = .;

*Recoding how much you can rely on spouse/partner for serious problem (MR41_1c_scale)*;
if MR41_1c = 1 then MR41_1c_scale = 4;
else if MR41_1c = 2 then MR41_1c_scale = 3;
else if MR41_1c = 3 then MR41_1c_scale = 2;
else if MR41_1c = 4 then MR41_1c_scale = 1;
else MR41_1c_scale = .;

*Recoding how much you can rely on relatives that dont live w/ you to discuss worries (SN3_scale)*;
if SN3 = 1 then SN3_scale = 4;
else if SN3 = 2 then SN3_scale = 3;
else if SN3 = 3 then SN3_scale = 2;
else if SN3 = 4 then SN3_scale = 1;
else SN3_scale = .;

*Recoding how much you can rely on friends to discuss worries (SN8_scale)*;
if SN8 = 1 then SN8_scale = 4;
else if SN8 = 2 then SN8_scale = 3;
else if SN8 = 3 then SN8_scale = 2;
else if SN8 = 4 then SN8_scale = 1;
else SN8_scale = .;

*Recoding how much you can rely on spouse/partner to discuss worries (MR41_1D_scale)*;
if MR41_1D = 1 then MR41_1D_scale = 4;
else if MR41_1D = 2 then MR41_1D_scale = 3;
else if MR41_1D = 3 then MR41_1D_scale = 2;
else if MR41_1D = 4 then MR41_1D_scale = 1;
else MR41_1D_scale = .;

*Recoding sr122 (whether someone thought they needed help) to make -8 & -9 to missing and changing to 0/1*;

if sr122 eq -8 or sr122 eq -9 then sr122_recode = .;
else if sr122 eq 5 then sr122_recode=0;
else sr122_recode = sr122;

*Recoding sr123 (reason for not seeking help) to make -8 & -9 to missing*;

if sr123 eq -8 then sr123_recode = .;
else if sr123 eq -9 then sr123_recode = .;
else sr123_recode = sr123;

*Recoding diagnoses into diagnostic classes (dxclass)*;

if DSM_PDS=1 or DSM_GADH=1 or DSM_AGO=1 or DSM_SP=1 or DSM_SO=1 or DSM_PTS=1 or	DSM_SAD=1 or DSM_ASA=1 then dxclass = 1;
else if DSM_MDDH=1 or DSM_DYS=1 or DSM_BIPOLARI=1 or DSM_BIPOLARII=1 then dxclass = 2;
else if DSM_ODD=1 or DSM_CD=1 or DSM_ADD=1 or DSM_IED=1 then dxclass =3;
else if DSM_ALA=1 or DSM_ALD=1 or DSM_DRA=1 or	DSM_DRD=1 then dxclass = 4;
else if DSM_BINGEH=1 or DSM_BUL=1 or DSM_ANO=1 then dxclass = 5;
else dxclass=.;

*Creating 2 indicator variables for a chi square test*;

*Indicator to compare no religion/athiest (norelig_athiest)*;

if relig6cat = 7 then norelig_athiest = 1;
else if relig6cat = 6 then norelig_athiest = 0;
else norelig_athiest = .; 

*Indicator to compare no religion/no preference (norelig_nopref)*;

if relig6cat = 7 then norelig_nopref = 1;
else if relig6cat = 1 then norelig_nopref = 0;
else norelig_nopref = .; 

*Recoding outcome variable for chi square test (sr123_frecode)*;

if dsmdx = 0 then sr123_frecode= .;
else sr123_frecode = sr123_recode;

*Recoding race into 4 categories (race4cat)*;

if rancest eq 11 then race4cat = 1;
else if rancest eq 9 or rancest eq 10 then race4cat = 2;
else if rancest eq 7 or rancest eq 8 then race4cat = 3;
else if  rancest eq 4 or rancest eq 12 then race4cat = 4;
else race4cat = .;

*Recoding poverty level into 4 categories (pov4cat)*;
if povindex gt . and povindex le 1 then pov4cat = 1;
else if povindex gt 1 and povindex le 3 then pov4cat = 2;
else if povindex gt 3 and povindex le 5 then pov4cat = 3;
else if povindex gt 5 then pov4cat = 4;
else pov4cat = .;

*Creating a new variable for people diagnosed with 12 month disorder and who answered sr122_recode*;

if dsmdx12 = 1 and sr122_recode ne . then part1 = 1;
else part1 = 0;

*Creating a new variable for people diagnosed with 12 month disorder and who answered sr123_recode*;

if dsmdx12 = 1 and (sr123_recode ge 1 and sr123_recode le 3) then part2 = 1;
else part2 = 0;

*Recode of sr123_recode to get rid of 'other' category*;

if sr123_recode = 4 then sr123_out = .;
else sr123_out = sr123_recode;

run;

data three;
	set two;

*Calculating mean of religiosity scores for those with 2 or less missing values (scalemean)*;

if nmiss(of da33_scale da34_scale da35_scale da36_scale) le 2 and nmiss(of da33_scale da34_scale da35_scale da36_scale)
gt . then scalemean=mean(of da33_scale da34_scale da35_scale da36_scale);
else scalemean=.;

*Substituting mean in for observations with 2 or less missing values*;

da33_sub= .;
da34_sub= .;
da35_sub= .;
da36_sub= .;

if da33_scale = . then da33_sub = scalemean;
else da33_sub = da33_scale;

if da34_scale = . then da34_sub = scalemean;
else da34_sub = da34_scale;

if da35_scale = . then da35_sub = scalemean;
else da35_sub = da35_scale;

if da36_scale = . then da36_sub = scalemean;
else da36_sub = da36_scale;

*Creating a summary religiosity score variable (relig_score)*;

if nmiss(of da33_sub da34_sub da35_sub da36_sub) gt 2 then relig_score = .; 
else relig_score = sum(of da33_sub da34_sub da35_sub da36_sub); 

label relig_score = 'Score of religiosity';

*Creating 3 level categorical religiosity variable - cutpoints are 9.6 & 13.1 (relig3cat)*;

if relig_score gt . and relig_score lt 9.6 then relig3cat = 1;
else if relig_score ge 9.6 and relig_score le 13.1 then relig3cat = 2;
else if relig_score gt 13.1 then relig3cat = 3;
else relig3cat = .;

*Creating social network average score (soc_score)*;
soc_score=sum(of sn2_scale sn7_scale MR41_1c_scale SN3_scale SN8_scale MR41_1D_scale);

*Creating categorical variable for social network in tertiles;
if soc_score ge 1 and soc_score le 11.3 then soc3cat = 1;
else if soc_score gt 11.3 and soc_score le 14.8 then soc3cat = 2; 
else if soc_score gt 14.8 then soc3cat = 3; 
else soc3cat = .;

*Examining number of observations with 2 values missing for imputation - CAN ERASE EVENTUALLY*;

if nmiss(of da33_scale da34_scale da35_scale da36_scale) eq 2 then miss2=1;
else miss2 = .;

*Recoding relig6cat to missing category (7)*;

if relig6cat=7 then relig_missing= .;
else relig_missing=relig6cat;

run;


proc freq data = three;
tables relig6cat*relig_recode;
run;

proc print data=three (obs=1000);
var spectx sr20 sr41 sr11b sr5a sr58 sr49 sr67 su103 sr8;
run;

*Sorting the data to find tertiles and quantiles*;

proc sort data = three;
by part1;
run;

*Finding tertiles of religiosity score to divide into low, medium and high categories for those with diagnoses*;

proc surveymeans data = three quantile = (.333 .667);
	weight ncsrwtlg;
	by part1;
	strata SESTRAT; 
	cluster SECLUSTR;
	var relig_score;
run;

*Finding quarters of income measure for those in the sample*;

proc surveymeans data = three quantile = (.25 .5 .75);
	weight ncsrwtlg;
	by part1;
	strata SESTRAT; 
	cluster SECLUSTR;
	var povindex;
run;

*Finding median of social network score to divide into low, medium and high categories for those with 12 month diagnoses*;
*Cutpoints for tertiles (11.3 & 14.8)*; 

proc surveymeans data = three quantile = (.333 .667) missing;
	weight ncsrwtlg;
	by part1;
	strata SESTRAT; 
	cluster SECLUSTR;
	var soc_score;
run;

proc freq data = two;
tables sex;
run;

**MK's crazy SUDAAN code for chi square test between Athiest/Agnostic & No Religion (norelig_athiest)**;

proc crosstab data=two filetype=sas deft1 notsorted;
nest sestrat seclustr ;
weight NCSRWTLG ;
class norelig_athiest sr123_recode / nofreq ;
tables norelig_athiest*sr123_recode ;
subpopn dsmdx12=1;
print / style=nchs ;
test chisq llchisq ;
run ;

**MK's crazy SUDAAN code for chi square test between No Religious Preference & No Religion (norelig_nopref)**;

proc crosstab data=two filetype=sas deft1 notsorted;
nest sestrat seclustr ;
weight NCSRWTLG ;
class norelig_nopref sr123_recode / nofreq ;
tables norelig_nopref*sr123_recode ;
subpopn dsmdx12=1;
print / style=nchs ;
test chisq llchisq ;
run ;

*USE THIS ONE*;

proc crosstab data=dsn3 filetype=sas deft1 notsorted;
nest sestrat seclustr ;
weight NCSRWTLG ;
class  pov4cat relig3cat/ nofreq;
tables pov4cat*relig3cat;
subpopn part1=1;
print / style=nchs ;
test chisq llchisq ;
run ;

sex age4cat race4cat ed4cat mar3cat pov4cat soc3cat relig6cat  relig3cat


*UNIVARIATE STATS*;

proc surveyfreq data = two missing;
weight NCSRWTlg;
strata SESTRAT; 
cluster SECLUSTR;
tables dsmdx12*sr122_recode*sex/row;
format dsmdx12 dsmdx. sex sex. sr122_recode yesno.;
run;

*Use this for univariate*;

proc surveyfreq data = dsn3 missing;
weight NCSRWTlg;
strata SESTRAT; 
cluster SECLUSTR;
tables part2*severity/row;
format part2 yesno. severity severity.;
run;

*USE THIS ONE for bivariate*;

proc surveyfreq data = dsn3 missing;
weight NCSRWTlg;
strata SESTRAT; 
cluster SECLUSTR;
tables part2*severity*relig3cat/row;
format part2 partone. relig3cat relig3cat. severity severity.;
run;
 
sex age4cat race4cat ed4cat mar3cat pov4cat soc3cat relig6cat  relig3cat


proc surveyfreq data = three missing;
weight NCSRWTlg;
strata SESTRAT; 
cluster SECLUSTR;
tables dsmdx12*mar3cat/row;
format dsmdx12 dsmdx. mar3cat mar3cat.;
run;

*COLLINEARITY MACRO CODING*;

ods output surveylogistic.covb=dsn3;  
proc surveylogistic data = dsn3 noprint;
class relig6cat relig3cat age4cat race4cat ed4cat mar3cat pov4cat soc3cat severity/ param=ref;
model sr122_recode (event = '1') = relig6cat relig3cat sex age4cat race4cat ed4cat mar3cat pov4cat soc3cat severity relig6cat*sex
relig6cat*age4cat relig6cat*ed4cat relig6cat*mar3cat relig6cat*pov4cat relig6cat*soc3cat relig6cat*severity relig6cat*race4cat relig6cat*relig3cat relig3cat*sex relig3cat*age4cat
relig3cat*ed4cat relig3cat*mar3cat relig3cat*pov4cat relig3cat*soc3cat relig3cat*severity relig3cat*race4cat/covb;
weight NCSRWTlg;
strata SESTRAT; 
cluster SECLUSTR;
run;

Title1 "Thesis collinearity assessment, full model";
%include "H:\Thesis\Thesis Analysis\collin_2011.sas";
%Collin(COVDSN=dsn3,PROCDR=SURVEYLOGISTIC,OUTPUT=dsn3results);


*Can add contrast (or oddsratio stmt - Lab 2 - slide 63) stmt when necessary; 
*contrast 'odds ratio for former smokers vs. nonsmokers among lean'former 1 lean_former 1/estimate = both;
*oddsratio variable/at (age=(0,1) ecg=(0,1)) cl=both (see if this works in surveylogistic or only regular logistic;
*title 'Full model with interactions';


*FULL MODEL - DO NOT ALTER! 2 EXPOSURES*;

proc surveylogistic data = dsn3;
class relig3cat (ref = '1') relig6cat (ref = '1') age4cat (ref = '1') race4cat (ref = '1') ed4cat (ref = '1') mar3cat (ref = '1') pov4cat (ref = '1') 
soc3cat (ref = '1') severity (ref = '1')/ param=ref;
model sr122_recode (event = '1') = relig6cat relig3cat sex age4cat race4cat ed4cat mar3cat pov4cat soc3cat severity relig6cat*sex relig6cat*age4cat 
relig6cat*race4cat relig6cat*ed4cat relig6cat*mar3cat relig6cat*pov4cat relig6cat*soc3cat relig6cat*severity relig6cat*relig3cat relig3cat*sex relig3cat*age4cat 
relig3cat*race4cat relig3cat*ed4cat relig3cat*mar3cat relig3cat*pov4cat relig3cat*soc3cat relig3cat*severity ;
weight NCSRWTlg;
strata SESTRAT; 
cluster SECLUSTR;
domain part1;
run;

*Polytomous Coding for Part 2- DO NOT ALTER*;

proc surveylogistic data = dsn3;
class relig3cat (ref = '1') sex_recode (ref = '1') race4cat (ref = '1') age4cat (ref = '1') 
ed4cat (ref = '1') mar3cat (ref = '1') pov4cat (ref = '1') soc3cat (ref = '1') severity (ref = '1')/ param=ref;
model sr123_out (ref=first) = relig3cat sex_recode age4cat race4cat ed4cat mar3cat pov4cat soc3cat severity/link=glogit;
weight NCSRWTlg;
strata SESTRAT; 
cluster SECLUSTR;
domain part2;
run;

*Binary outcome - DO NOT ALTER!*;

proc surveylogistic data = dsn3;
class relig3cat (ref = '1') sex_recode (ref = '1') race4cat (ref = '1') age4cat (ref = '1') 
ed4cat (ref = '1') mar3cat (ref = '1') pov4cat (ref = '1') soc3cat (ref = '1') severity (ref = '1')/ param=ref;
model sr122_recode (event='1') = relig3cat sex_recode age4cat race4cat ed4cat mar3cat pov4cat soc3cat severity;
weight NCSRWTlg;
strata SESTRAT; 
cluster SECLUSTR;
domain part1;
run;

*BINARY OUTCOME - ALTER THIS!*;

proc surveylogistic data = dsn3;
class relig3cat(ref = '1') sex_recode (ref = '1') age4cat (ref = '1') severity (ref = '1')/ param=ref;
model sr122_recode (event='1') = relig3cat sex_recode age4cat severity;
weight NCSRWTlg;
strata SESTRAT; 
cluster SECLUSTR;
domain part1;
run;
        
  race4cat race4cat (ref = '1') 

*Polyomous - Alter this guy!*;

proc surveylogistic data = dsn3;
class relig3cat (ref = '1') severity (ref = '1')/ param=ref;
model sr123_out (ref=first) = relig3cat severity/link=glogit;
weight NCSRWTlg;
strata SESTRAT; 
cluster SECLUSTR;
domain part2;
run;

soc3cat	soc3cat (ref = '1')
 

*Sudaan code full model with relig6cat - DO NOT ALTER*;

proc rlogist data=dsn3 filetype=sas deft1 notsorted;  
nest sestrat seclustr; 
subpopn part1=1;
weight ncsrwtlg; 
class relig3cat relig6cat relig_missing age4cat race4cat ed4cat mar3cat pov4cat soc3cat severity/ nofreq ; 
reflevel relig3cat=1 relig6cat=1 age4cat=1 race4cat=1 ed4cat=1 mar3cat=1 pov4cat=1 soc3cat=1 severity=1; 
model sr122_recode = relig6cat relig3cat sex age4cat race4cat ed4cat mar3cat pov4cat soc3cat severity relig6cat*sex relig6cat*age4cat 
relig6cat*race4cat relig6cat*ed4cat relig6cat*mar3cat relig6cat*pov4cat relig6cat*soc3cat relig6cat*severity relig6cat*relig3cat relig3cat*sex relig3cat*age4cat 
relig3cat*race4cat relig3cat*ed4cat relig3cat*mar3cat relig3cat*pov4cat relig3cat*soc3cat relig3cat*severity; 
run ;

*Final model with relig6cat*;

proc rlogist data=dsn3 filetype=sas deft1 notsorted;  
nest sestrat seclustr; 
subpopn part1=1;
weight ncsrwtlg; 
class relig3cat relig6cat relig_missing age4cat race4cat ed4cat mar3cat pov4cat soc3cat severity/ nofreq ; 
reflevel relig3cat=1 relig6cat=1 age4cat=1 race4cat=1 ed4cat=1 mar3cat=1 pov4cat=1 soc3cat=1 severity=1; 
model sr122_recode = relig6cat relig3cat sex age4cat race4cat ed4cat mar3cat pov4cat soc3cat severity relig6cat*sex relig6cat*age4cat 
relig6cat*race4cat relig6cat*pov4cat relig6cat*soc3cat relig6cat*severity relig6cat*relig3cat relig3cat*soc3cat; 
run ;

*Final Model with relig_missing*;

proc rlogist data=dsn3 filetype=sas deft1 notsorted;  
nest sestrat seclustr; 
subpopn part1=1;
weight ncsrwtlg; 
class relig3cat relig_missing age4cat race4cat ed4cat mar3cat pov4cat soc3cat severity sex/ nofreq ; 
reflevel relig3cat=1 relig_missing=1 age4cat=1 race4cat=1 ed4cat=1 mar3cat=1 pov4cat=1 soc3cat=1 severity=1 sex=1; 
model sr122_recode = relig_missing relig3cat sex age4cat race4cat ed4cat mar3cat pov4cat soc3cat severity 
relig_missing*race4cat relig_missing*pov4cat; 
run ;












*Alex's code*;
PROC SURVEYLOGISTIC DATA = brfss; 
weight _finalwt; 
class sex (ref = '1') marital (ref = '1') employment (ref = '1') _AGE_G (ref = '6') race2 (ref = '1') _EDUCAG (ref = '4') _INCOMG (ref = '5') 
_SMOKER3 (ref = '4') alc_status (ref = '0') _BMI4CAT(ref = '1') PERSDOC2 (ref = '1') CHECKUP1 (ref = '1')/param = ref; 
MODEL checkup (event = '0')= hlthplan sex marital employment _AGE_G race2 _EDUCAG _INCOMG EXERANY2 _SMOKER3 alc_status _BMI4CAT emt_lack _RFHLTH lifesatisfy QLACTLM2 _PHYSHLTH_poor _frqmentd
diabetes cvd chd stroke ever_asthma current_asthma;
by region; 
RUN;

