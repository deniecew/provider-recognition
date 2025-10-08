library(tidytext)
library(tidyverse)
library(janitor)
library(dplyr)
library(gt)

#import & clean data

commentdata <- read.csv("C:/Users/4477078/OneDrive - Moffitt Cancer Center/provider_recognition/commentdata.csv")

commentdata <- commentdata %>% 
  clean_names() %>%
  filter(provider_nm != "Provider New/Ungroupable")

commentdata$npi_num<-as.character(commentdata$npi_num)
  
save(commentdata,file="C:/Users/4477078/OneDrive - Moffitt Cancer Center/provider_recognition/commentdata.Rdata")


# commentdata %>%
#   summarise(distinct_npi = n_distinct(npi_num))
# 
# commentdata %>%
#   summarise(distinct_provider = n_distinct(provider_nm))
#   
# 
# df <- commentdata %>%
#   distinct (provider_nm, npi_num)
  
