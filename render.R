library(quarto)
library(tidyverse)

load("C:/Users/4477078/OneDrive - Moffitt Cancer Center/provider_recognition/commentdata.Rdata")

npi_nums<-commentdata %>%
  distinct(npi_num) %>%
  pull(npi_num) %>%
  as.character()
  

names<-commentdata %>%
  distinct(provider_nm) %>%
  pull(provider_nm) %>%
  as.character()

reports<-
  tibble(
    input="cardtemplate.qmd",
    output_file = str_glue("{names}.html"),
    execute_params=map(npi_nums,~list(npi=.))
  )


pwalk(reports,quarto_render)