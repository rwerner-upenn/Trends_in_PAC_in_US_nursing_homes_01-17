## SNF Admissions, 2000-2018
## Author: Nate Apathy
## Date: Dec 21, 2020
## Determining dual-eligibility status at admission
## Uses existing Medpar file with denominator of admissions, and determines dual-elig status for every admission
## uses "buyinXXX" variables == A, B, or C as the definition for dual-eligible
## matches admission month to buyin month, relative to Jan 1 2000
## also creates year variable for merging with ACS and LTC Focus data
## Read in Medpar file with denom, set up our Rdata file to determine dual-elig status *at admission*

############# BEGIN PROGRAM ##############
# load necessary packages
library(tidyverse)
library(lubridate)
library(data.table)
library(haven)

# month number references - for assigning a number to each admission month
mo_lookup <- readxl::read_xlsx(path="/PATH/mo_lookup.xlsx") %>%
  mutate(adm_mo=as.Date(floor_date(mo_date,"months"))) %>% setDT(key = "adm_mo")

## NOT RUN - SAVING AS RDATA ##
## full file - for initial run this reads in the DTA and saves it as a data.table for later loading of the native file type
#snf_denom <- haven::read_dta(file="/PATH/snf_adm_2000_2018_medpar_denom.dta")
#setDT(snf_denom) # sets the DT
#save(snf_denom,file="/PATH/snf_adm_2000_2018_medpar_denom.Rdata") # saves off for later loading
## END SAVE AS RDATA ##

load(file="/PATH/snf_adm_2000_2018_medpar_denom.Rdata") # this is the file we created above

# use data.table syntax to extract month of admission and year of admission
snf_denom[, `:=`(adm_mo = as.Date(floor_date(admsndt,"months")), # admission month
                 adm_yr = year(admsndt))] # admission year for merging with LTC Focus and ACS data


# merge with month numbers to get the mo_num relative to Jan 1 2000
setkeyv(snf_denom,cols=c("adm_mo"))
snf_denom[mo_lookup,"mo_num" := .(mo_num),
          on=c("adm_mo")]
colnames(snf_denom) # check that all fields are there

# take month number for the admission
# check if the field that matches "buyin" plus that month number (e.g. buyin160) is = to A B or C
# this determines dual-eligibility status (TRUE or FALSE)
snf_denom[,`:=`(dual_at_adm = get(eval(paste0("buyin",snf_denom$mo_num))) %in% c("A","B","C"))]


colnames(snf_denom)
# drop buyinXXX fields (fields 25 thru 252)
dropcols <- colnames(snf_denom)[25:252]
snf_denom[, c(dropcols) := NULL]
dim(snf_denom)
# save off the file for later merging
save(snf_denom,file="/PATH/snf_denom_duals.Rdata")

# intermittent export to DTA
haven::write_dta(snf_denom,path="/PATH/snf_adm_2000_2018_medpar_denom_dual.dta")

### merge in ACS ZIP data
# read in zip-year data
zipdat11_18 <- read_csv("/PATH/zipdat11_18.csv")
colnames(zipdat11_18)[1:2] <- c("bene_zip","adm_yr")
setDT(zipdat11_18,key=c("bene_zip","adm_yr"))
# leave years prior to 2011 missing

# set keys on snf_denom for merging more quickly in memory by reference
setkeyv(snf_denom,cols=c("bene_zip","adm_yr"))
# merge on zip and year 

snf_denom[zipdat11_18,c("med_inc_18adj", "pct_in_poverty") := .(med_inc_18adj, pct_in_poverty),
          on=c("bene_zip","adm_yr")]

### merge in LTC Focus data
## ltc focus
ltc_focus <- read_dta("/PATH/LTC_Focus_2000_2017.dta") %>% 
  mutate(prvdr_num=as.character(SNF_Prvdr_Num),
         adm_yr=year) %>%
  data.table(key=c("prvdr_num","adm_yr"))
# LTC Focus only goes through 2017, per website
colnames(ltc_focus)

# change the keys to match on LTC Focus provider number
setkeyv(snf_denom,cols=c("prvdr_num","adm_yr"))

snf_denom <- ltc_focus[snf_denom]

# export to DTA
haven::write_dta(snf_denom,path="/PATH/snf_adm00_18.dta")

# clear objects from memory/the environment
rm(snf_denom,mo_lookup,zipdat11_18,ltc_focus)
### END OF FILE ###

