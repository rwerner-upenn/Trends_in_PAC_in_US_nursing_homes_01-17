/********************************************************************************************************************/
* Goal: Set up SNF Admissions file for all FFS SNF admissions, 2000-2018;
* Include all admissions, write to DTA for further processing in STATA/R
* Create date: 12/01/2020;
* Created by: Nate Apathy;
/********************************************************************************************************************/
* set library;
libname MedPar '/PATH/Medpar100/CY';
libname Denom '/PATH/Denom100';
libname Temp '/PATH/sastemp';

* filter down medpar data 2000-2018 to just SNF admissions;
data snf_2000_2018(drop=SPCLUNIT);
set  Medpar.Mp100mod_2000 (keep=BENE_ID bene_zip state_cd cnty_cd AGE_CNT SEX RACE PRVDR_NUM SPCLUNIT ADMSNDT DSCHRGDT DSCHRGCD DSTNTNCD DRG_CD UTIL_DAY DGNS_CD01-DGNS_CD10)
     Medpar.Mp100mod_2001 (keep=BENE_ID bene_zip state_cd cnty_cd AGE_CNT SEX RACE PRVDR_NUM SPCLUNIT ADMSNDT DSCHRGDT DSCHRGCD DSTNTNCD DRG_CD UTIL_DAY DGNS_CD01-DGNS_CD10)
     Medpar.Mp100mod_2002 (keep=BENE_ID bene_zip state_cd cnty_cd AGE_CNT SEX RACE PRVDR_NUM SPCLUNIT ADMSNDT DSCHRGDT DSCHRGCD DSTNTNCD DRG_CD UTIL_DAY DGNS_CD01-DGNS_CD10)
     Medpar.Mp100mod_2003 (keep=BENE_ID bene_zip state_cd cnty_cd AGE_CNT SEX RACE PRVDR_NUM SPCLUNIT ADMSNDT DSCHRGDT DSCHRGCD DSTNTNCD DRG_CD UTIL_DAY DGNS_CD01-DGNS_CD10)
     Medpar.Mp100mod_2004 (keep=BENE_ID bene_zip state_cd cnty_cd AGE_CNT SEX RACE PRVDR_NUM SPCLUNIT ADMSNDT DSCHRGDT DSCHRGCD DSTNTNCD DRG_CD UTIL_DAY DGNS_CD01-DGNS_CD10)
     Medpar.Mp100mod_2005 (keep=BENE_ID bene_zip state_cd cnty_cd AGE_CNT SEX RACE PRVDR_NUM SPCLUNIT ADMSNDT DSCHRGDT DSCHRGCD DSTNTNCD DRG_CD UTIL_DAY DGNS_CD01-DGNS_CD10)
     Medpar.Mp100mod_2006 (keep=BENE_ID bene_zip state_cd cnty_cd AGE_CNT SEX RACE PRVDR_NUM SPCLUNIT ADMSNDT DSCHRGDT DSCHRGCD DSTNTNCD DRG_CD UTIL_DAY DGNS_CD01-DGNS_CD10)
     Medpar.Mp100mod_2007 (keep=BENE_ID bene_zip state_cd cnty_cd AGE_CNT SEX RACE PRVDR_NUM SPCLUNIT ADMSNDT DSCHRGDT DSCHRGCD DSTNTNCD DRG_CD UTIL_DAY DGNS_CD01-DGNS_CD10)
     Medpar.Mp100mod_2008 (keep=BENE_ID bene_zip state_cd cnty_cd AGE_CNT SEX RACE PRVDR_NUM SPCLUNIT ADMSNDT DSCHRGDT DSCHRGCD DSTNTNCD DRG_CD UTIL_DAY DGNS_CD01-DGNS_CD10)
     Medpar.Mp100mod_2009 (keep=BENE_ID bene_zip state_cd cnty_cd AGE_CNT SEX RACE PRVDR_NUM SPCLUNIT ADMSNDT DSCHRGDT DSCHRGCD DSTNTNCD DRG_CD UTIL_DAY DGNS_CD01-DGNS_CD10)
     Medpar.Mp100mod_2010 (keep=BENE_ID bene_zip state_cd cnty_cd AGE_CNT SEX RACE PRVDR_NUM SPCLUNIT ADMSNDT DSCHRGDT DSCHRGCD DSTNTNCD DRG_CD UTIL_DAY DGNS_CD01-DGNS_CD10)
     Medpar.Mp100mod_2011 (keep=BENE_ID bene_zip state_cd cnty_cd AGE_CNT SEX RACE PRVDR_NUM SPCLUNIT ADMSNDT DSCHRGDT DSCHRGCD DSTNTNCD DRG_CD UTIL_DAY DGNS_CD01-DGNS_CD10)
     Medpar.Mp100mod_2012 (keep=BENE_ID bene_zip state_cd cnty_cd AGE_CNT SEX RACE PRVDR_NUM SPCLUNIT ADMSNDT DSCHRGDT DSCHRGCD DSTNTNCD DRG_CD UTIL_DAY DGNS_CD01-DGNS_CD10)
     Medpar.Mp100mod_2013 (keep=BENE_ID bene_zip state_cd cnty_cd AGE_CNT SEX RACE PRVDR_NUM SPCLUNIT ADMSNDT DSCHRGDT DSCHRGCD DSTNTNCD DRG_CD UTIL_DAY DGNS_CD01-DGNS_CD10)
     Medpar.Mp100mod_2014 (keep=BENE_ID bene_zip state_cd cnty_cd AGE_CNT SEX RACE PRVDR_NUM SPCLUNIT ADMSNDT DSCHRGDT DSCHRGCD DSTNTNCD DRG_CD UTIL_DAY DGNS_CD01-DGNS_CD10)
     Medpar.Mp100mod_2015 (keep=BENE_ID bene_zip state_cd cnty_cd AGE_CNT SEX RACE PRVDR_NUM SPCLUNIT ADMSNDT DSCHRGDT DSCHRGCD DSTNTNCD DRG_CD UTIL_DAY DGNS_CD01-DGNS_CD10)
	 Medpar.Mp100mod_2016 (keep=BENE_ID bene_zip state_cd cnty_cd AGE_CNT SEX RACE PRVDR_NUM SPCLUNIT ADMSNDT DSCHRGDT DSCHRGCD DSTNTNCD DRG_CD UTIL_DAY DGNS_CD01-DGNS_CD10) 
	 Medpar.Mp100mod_2017 (keep=BENE_ID bene_zip state_cd cnty_cd AGE_CNT SEX RACE PRVDR_NUM SPCLUNIT ADMSNDT DSCHRGDT DSCHRGCD DSTNTNCD DRG_CD UTIL_DAY DGNS_CD01-DGNS_CD10)
     Medpar.Mp100mod_2018 (keep=BENE_ID bene_zip state_cd cnty_cd AGE_CNT SEX RACE PRVDR_NUM SPCLUNIT ADMSNDT DSCHRGDT DSCHRGCD DSTNTNCD DRG_CD UTIL_DAY DGNS_CD01-DGNS_CD10);
where (substr(PRVDR_NUM,3,2) in ('50','51','52','53','54','55','56','57','58','59','60','61','62','63','64')) & SPCLUNIT not in ('U','W','Y','Z');
run; *46,727,570;

data temp.snf_2000_2018;
set snf_2000_2018;
output;
run;

*Export data set to Stata file;
proc export data=snf_2000_2018
                        outfile="/PATH/snf_adm_2000_2018_medpar.dta" dbms=dta replace;
run;

/***********************************************************************************************
Step 2: Use Medicare Beneficiary Summary Files to determine dual-eligibility status
***********************************************************************************************/
*Use macro to read in Denominator files;
*2000 - 2006;
%macro denom1(start_yr,end_yr);
%do i=&start_yr %to &end_yr;

%let j=%eval(1+(&i-2000)*12);
%let k=%eval(&j+11);

data Dn100mod_new_&i; set Denom.Dn100mod_&i; RFRNC_YR=&i; run;

data Dn100mod_&i(drop=BUYIN_MO);
set Dn100mod_new_&i(rename=(BUYIN01=BUYIN1 BUYIN02=BUYIN2 BUYIN03=BUYIN3 BUYIN04=BUYIN4 BUYIN05=BUYIN5
                            BUYIN06=BUYIN6 BUYIN07=BUYIN7 BUYIN08=BUYIN8 BUYIN09=BUYIN9));
rename BUYIN1-BUYIN12=BUYIN&j-BUYIN&k ;
keep BENE_ID BUYIN: ;
run;

proc sort data=Dn100mod_&i; by BENE_ID; run;

%end;
%mend denom1;

%denom1(2000,2006);

*2007 - 2018;
%macro denom2(start_yr,end_yr);
%do i=&start_yr %to &end_yr;

%let j=%eval(1+(&i-2000)*12);
%let k=%eval(&j+11);

data Dn100mod_&i(drop=BUYIN_MO);
set Denom.Dn100mod_&i(rename=(BUYIN01=BUYIN1 BUYIN02=BUYIN2 BUYIN03=BUYIN3 BUYIN04=BUYIN4 BUYIN05=BUYIN5
                              BUYIN06=BUYIN6 BUYIN07=BUYIN7 BUYIN08=BUYIN8 BUYIN09=BUYIN9));
rename BUYIN1-BUYIN12=BUYIN&j-BUYIN&k ;
keep BENE_ID BUYIN: ;
run;

proc sort data=Dn100mod_&i; by BENE_ID; run;

%end;
%mend denom2;

%denom2(2007,2018);

data Dn100mod_2000_2018;
merge Dn100mod_2000 Dn100mod_2001 Dn100mod_2002 Dn100mod_2003 Dn100mod_2004 Dn100mod_2005 Dn100mod_2006 Dn100mod_2007 Dn100mod_2008
      Dn100mod_2009 Dn100mod_2010 Dn100mod_2011 Dn100mod_2012 Dn100mod_2013 Dn100mod_2014 Dn100mod_2015 Dn100mod_2016 Dn100mod_2017 Dn100mod_2018;
by BENE_ID;
where bene_id^="";
run; *100,483,952;

data temp.Dn100mod_2000_2018;
set Dn100mod_2000_2018;
by bene_id ;
output;
run;

*Merge MedPAR data with MBSF to determine Medicare enrollment status;
proc sql;
create table snf_2000_2018_denom as
select medpar.*, denom.*
from temp.snf_2000_2018 as medpar
inner join temp.Dn100mod_2000_2018 as denom
on medpar.BENE_ID=denom.BENE_ID;
quit; *46,954,754;

*Export data set to Stata file;
proc export data=snf_2000_2018_denom
                        outfile="/PATH/snf_adm_2000_2018_medpar_denom.dta" dbms=dta replace;
run;

******************************************************
