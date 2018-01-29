*1. Final Model - 2 exposures & NCSRWTSH weight*;

proc surveylogistic data = dsn3;
class relig3cat (ref = '1') relig6cat (ref = '1') age4cat (ref = '1') race4cat (ref = '1') ed4cat (ref = '1') mar3cat (ref = '1') pov4cat (ref = '1') 
soc3cat (ref = '1') severity (ref = '1')/ param=ref;
model sr122_recode (event = '1') = relig6cat relig3cat sex age4cat race4cat ed4cat mar3cat pov4cat soc3cat severity relig6cat*sex relig6cat*mar3cat 
relig6cat*pov4cat relig6cat*soc3cat relig6cat*severity relig6cat*race4cat relig6cat*relig3cat
relig3cat*soc3cat;
weight NCSRWTsh;
strata SESTRAT; 
cluster SECLUSTR;
domain part1;
title "Output Model 1 - 2 exposures and NCSRWTSH weight";
run;

*2. Final Model - 2 exposures & NCSRWTLG weight*;

proc surveylogistic data = dsn3;
class relig3cat (ref = '1') relig6cat (ref = '1') age4cat (ref = '1') race4cat (ref = '1') ed4cat (ref = '1') mar3cat (ref = '1') pov4cat (ref = '1') 
soc3cat (ref = '1') severity (ref = '1')/ param=ref;
model sr122_recode (event = '1') = relig6cat relig3cat sex age4cat race4cat ed4cat mar3cat pov4cat soc3cat severity relig6cat*sex 
relig6cat*race4cat relig6cat*mar3cat relig6cat*pov4cat relig6cat*soc3cat relig6cat*severity relig6cat*relig3cat relig3cat*pov4cat relig3cat*soc3cat;
weight NCSRWTLG;
strata SESTRAT; 
cluster SECLUSTR;
domain part1;
title "Output Model 2 - 2 exposures and NCSRWTLG weight";
run;

*3. Final Model - 1 exposure (relig3cat) & NCSRWTLG weight*;

proc surveylogistic data = dsn3;
class relig3cat (ref = '1') age4cat (ref = '1') race4cat (ref = '1') ed4cat (ref = '1') mar3cat (ref = '1') pov4cat (ref = '1') 
soc3cat (ref = '1') severity (ref = '1')/ param=ref;
model sr122_recode (event = '1') = relig3cat sex age4cat race4cat ed4cat mar3cat pov4cat soc3cat severity  
relig3cat*race4cat relig3cat*mar3cat relig3cat*severity ;
weight NCSRWTlg;
strata SESTRAT; 
cluster SECLUSTR;
domain part1;
title "Output Model 3 - relig3cat and NCSRWTLG weight";
run;

*4. Final Model - 1 exposure (relig3cat) & NCSRWTSH weight*;

proc surveylogistic data = dsn3;
class relig3cat (ref = '1') age4cat (ref = '1') race4cat (ref = '1') ed4cat (ref = '1') mar3cat (ref = '1') pov4cat (ref = '1') 
soc3cat (ref = '1') severity (ref = '1')/ param=ref;
model sr122_recode (event = '1') = relig3cat sex age4cat race4cat ed4cat mar3cat pov4cat soc3cat severity  
relig3cat*race4cat relig3cat*mar3cat relig3cat*severity ;
weight NCSRWTSH;
strata SESTRAT; 
cluster SECLUSTR;
domain part1;
title "Output Model 4 - relig3cat and NCSRWTSH weight";
run;

*5. Final Model - 1 exposure (relig6cat) & NCSRWTLG weight*;
*All interactions were significant, none were dropped - this was the same with NCSRWTSH so it was not included*;

proc surveylogistic data = dsn3;
class relig6cat (ref = '1') age4cat (ref = '1') race4cat (ref = '1') ed4cat (ref = '1') mar3cat (ref = '1') pov4cat (ref = '1') 
soc3cat (ref = '1') severity (ref = '1')/ param=ref;
model sr122_recode (event = '1') = relig6cat sex age4cat race4cat ed4cat mar3cat pov4cat soc3cat severity relig6cat*sex relig6cat*age4cat 
relig6cat*race4cat relig6cat*ed4cat relig6cat*mar3cat relig6cat*pov4cat relig6cat*soc3cat relig6cat*severity ;
weight NCSRWTlg;
strata SESTRAT; 
cluster SECLUSTR;
domain part1;
title "Output Model 5 - relig6cat and NCSRWTLG weight";
run;

