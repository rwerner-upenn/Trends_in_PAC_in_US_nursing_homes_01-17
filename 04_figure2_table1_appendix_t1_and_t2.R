########## Trends in post-acute care in nursing homes: 2001 to 2017
###### Figure 2, Table 1, and Appendix Tables 1 & 2
###########################################################

## load libraries
library(tidyverse) # for data processing
library(DescTools) # for Winsorizing function
library(haven) # for reading in stata .dta file of snf-year observations
library(tableone) # for creating descriptive tables
## end libraries

## load data
# data file contains 2000-2017 SNF-year observations 
snf_yr_dat <- read_dta("<filepath>/snf_yr_trends_final.dta")
# filepath is local to Penn HSRDC server
## end data

### Figure 2
# Medicare admissions per bed in each year of the study.
# Each dot represents one nursing home. The 50th, 95th, and 99th percentiles are marked with black horizontal lines
# create plot data
snf_yr_dat %>% 
  group_by(year=snf_admsn_year) %>%
  filter(year>2000) %>% # 2001-2017 only
  mutate(admns_beds_nonhosp_w=Winsorize(admns_beds_nonhosp,probs = c(0.01,0.995),na.rm = T), 
         # winsorize the admissions per bed at the 99.5th percentile within year
         p1=quantile(admns_beds_nonhosp,0.01,na.rm=T), # first percentile (year level)
         p10=quantile(admns_beds_nonhosp,0.10,na.rm=T),
         p25=quantile(admns_beds_nonhosp,0.25,na.rm=T),
         p50=quantile(admns_beds_nonhosp,0.50,na.rm=T), # median (year level)
         p75=quantile(admns_beds_nonhosp,0.75,na.rm=T),
         p90=quantile(admns_beds_nonhosp,0.90,na.rm=T),
         p95=quantile(admns_beds_nonhosp,0.90,na.rm=T),
         p99=quantile(admns_beds_nonhosp,0.99,na.rm=T),
         pctl_group=factor(case_when(admns_beds_nonhosp<p50~"Below 50th percentile",
                                     admns_beds_nonhosp>=p50&admns_beds_nonhosp<p95~"50th to 95th percentile",
                                     admns_beds_nonhosp>=p95&admns_beds_nonhosp<p99~"95th to 99th percentile",
                                     admns_beds_nonhosp>=p99~"99th percentile & above"),
                           levels = c("Below 50th percentile",
                                      "50th to 95th percentile",
                                      "95th to 99th percentile",
                                      "99th percentile & above"))) -> fig2_dat
fig2_dat %>%  
  filter(is.na(pctl_group)==F) %>% # filter out missings
  filter(admns_beds_nonhosp_w!=max(admns_beds_nonhosp_w)) %>% # filter out the points that get winsorized (for each year)
  ggplot(aes(x=factor(snf_admsn_year),y=admns_beds_nonhosp_w)) +
  # create stripchart version
  geom_jitter(aes(color=pctl_group),alpha=0.3,position = position_jitter(0.3)) +
  geom_segment(aes(x=factor(snf_admsn_year),xend=factor(snf_admsn_year),y=p50,yend=p50),color="black",size=1,position = position_jitter(0.3)) +
  geom_segment(aes(x=factor(snf_admsn_year),xend=factor(snf_admsn_year),y=p95,yend=p95),color="black",size=1,position = position_jitter(0.3)) +
  geom_segment(aes(x=factor(snf_admsn_year),xend=factor(snf_admsn_year),y=p99,yend=p99),color="black",size=1,position = position_jitter(0.3)) +
  theme_minimal() +
  scale_x_discrete(breaks = factor(c(2001:2017))) +
  scale_y_continuous(minor_breaks = c(1:11),breaks = c(0,2,4,6,8,10,12)) +
  scale_color_manual(values=c("#999999", "#E69F00", "#56B4E9", "#009E73"), # use color-blind friendly palette
                     guide=guide_legend(reverse = T)) +
  labs(color="Nursing homes by percentile of Medicare admissions per bed",x="",
       y="Medicare admissions per bed") +
  coord_cartesian(ylim = c(0,11)) +
  theme(axis.text.x = element_text(angle=45,hjust=1,vjust=1),
        legend.position = "bottom",
        panel.grid.major = element_line(size=0.5,color = "grey"),
        panel.grid.minor = element_line(size=0.2,color="grey")) +
  guides(color=guide_legend(title.position = "top",title.hjust = 0.5,override.aes = (list(alpha=1)))) +
  ggsave("<filepath>/snf_spec_stripchart.png",width = 20,height = 20,units = "cm",dpi=300) +
  # save file as high-res .png 
  NULL

# Figure 2 note re: winsorization
# the top 0.5 percentof the distribution in each year is not shown
# this excludes between:
fig2_dat %>% 
  filter(is.na(admns_beds_nonhosp)==F) %>%
  group_by(year=snf_admsn_year) %>%
  mutate(wins_flag=if_else(admns_beds_nonhosp_w==max(admns_beds_nonhosp_w,na.rm = T),1,0)) %>%
  group_by(year,wins_flag) %>% tally() %>% filter(wins_flag==1) 
# filters between 62 (2001) and 70 (2017) each year

# full sample n
fig2_dat %>% 
  filter(is.na(pctl_group)==F) %>% 
  ungroup() %>% 
  summarize(n_distinct(accpt_id))
# 15,563 nursing homes

### Table 1
## Nursing home and patient characteristics by Medicare admissions per bed percentiles in 2001 and 2017
# only 2001 and 2017
fig2_dat %>% 
  filter(is.na(pctl_group)==F) %>%
  filter(snf_admsn_year %in% c(2001,2017)) %>%
  mutate(pctl_group2=factor(if_else(pctl_group %in% c("99th percentile & above","95th to 99th percentile"),
                             "95th percentile & above",paste0(pctl_group)),
                            levels = c("Below 50th percentile","50th to 95th percentile","95th percentile & above"))) -> t1_dat

## Table for 2001
CreateTableOne(vars=c("snf_bed_cnt","snf_for_profit","snf_in_chain", # SNF characteristics
                      "snf_rn_hrppd","snf_lpn_hrppd","snf_cna_hrppd","snf_rntonr", # staffing levels
                      "age_cnt","female","white","black","hispanic","dual_at_adm"), # patient demographics
               strata = "pctl_group2",test=F,
               data=(t1_dat%>%filter(year==2001))) %>% print(contDigits=4)

## Table for 2017
CreateTableOne(vars=c("snf_bed_cnt","snf_for_profit","snf_in_chain", # SNF characteristics
                      "snf_rn_hrppd","snf_lpn_hrppd","snf_cna_hrppd","snf_rntonr", # staffing levels
                      "age_cnt","female","white","black","hispanic","dual_at_adm"), # patient demographics
               strata = "pctl_group2",test=F,
               data=(t1_dat%>%filter(year==2017))) %>% print(contDigits=4)


### Appendix Table 1
# Nursing home and patient characteristics, stratified by their entry or exit status over the study period
# all years, pooled
# total n of nursing homes
fig2_dat %>% 
  filter(is.na(pctl_group)==F) %>%
  CreateTableOne(vars=c("admns_beds_nonhosp","snf_bed_cnt","snf_for_profit","snf_in_chain",
                      "snf_rn_hrppd","snf_lpn_hrppd","snf_cna_hrppd","snf_rntonr",
                      "age_cnt","female","white","black","hispanic","dual_at_adm"),
               strata = "nh_status", # rather than "pctl_group2"
               factorVars = c("snf_for_profit","snf_in_chain"),
               data=.,
               test=F) %>% print(contDigits=4)

# get n of nursing homes by status for table, since nursing homes are double-counted if they both entered and exited during study period
fig2_dat %>% filter(is.na(pctl_group)==F) %>%
  group_by(nh_status) %>% 
  summarize(n_snfs=n_distinct(accpt_id))


### Appendix Table 2
# Nursing home characteristics for nursing homes with no medicare admissions compared to all other nursing homes, 2017 only
t1_dat %>% 
  filter(is.na(pctl_group)==F) %>%
  filter(year==2017) %>%
  mutate(zero_mcr=if_else(snf_pct_medicare_adj==0,"Zero-Medicare","All Other SNFs")) %>% 
  tableone::CreateTableOne(vars = c("snf_bed_cnt","snf_for_profit","snf_in_chain","snf_rn_hrppd","snf_lpn_hrppd",
                                    "snf_cna_hrppd","snf_rntonr"),
                           strata = "zero_mcr")

