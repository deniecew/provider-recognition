
# Packages
library(quarto)        # for quarto_render()
library(tidyverse)     # dplyr, purrr, stringr, readr, tidyr, etc.
library(janitor)       # for clean_names()


getwd()
# setwd("path/to/your/folder")  # Optional if you want to change the directory

# Import Data Files
commentdata <- read.csv("commentdata.csv")

#Clean Data Files
commentdata <- commentdata %>% 
  clean_names() %>%
  filter(provider_nm != "Provider New/Ungroupable") %>%
  mutate(recdate = as.Date(recdate, format = "%m/%d/%Y"))


commentdata$npi_num<-as.character(commentdata$npi_num)



#filter providers with comments
providermatches <- data.frame(provider_nm  = character(), npi_num = character(), match_count = integer(), 
                              stringsAsFactors = FALSE)

for (npi_val in unique(commentdata$npi_num)){
  
  # Proper filtering using dplyr
  subsetcomments <- commentdata %>% filter(npi_num == npi_val)
  
  # Split resource_name into last and first names
  subsetcomments[c('last_nm', 'first_nm')] <- str_split_fixed(subsetcomments$resource_name, ' ', 2)
  
  # Title-case the names
  last_nm <- str_to_title(subsetcomments$last_nm)
  first_nm <- str_to_title(subsetcomments$first_nm)
  
  # Clean response text
  x <- subsetcomments$response
  y <- str_replace_all(x, " ", "")
  
  # Check for name matches
  subsetcomments$check1 <- grepl(last_nm, y)
  subsetcomments$check2 <- grepl(first_nm, y)
  
  # Filter rows where either name is found
  named_comments <- subsetcomments %>% filter(check1 | check2)
  
  match_count<-nrow(named_comments)
  provider<-unique(subsetcomments$provider_nm)
  program<-unique(subsetcomments$program_nm)
  date_count<-length(unique(named_comments$recdate))
  
  providermatches <- rbind(providermatches, data.frame(program_n = program, provider_nm = provider, npi_num = npi_val, match_count = match_count, emails_sent = date_count))
}

save(commentdata,file="commentdata.Rdata")
save(providermatches,file="providermatches.Rdata")

#
cardrun <- providermatches %>%
  filter(match_count > 0)

npi_nums<-cardrun %>%
  distinct(npi_num) %>%
  pull(npi_num) %>%
  as.character()


names<-cardrun %>%
  distinct(provider_nm) %>%
  pull(provider_nm) %>%
  as.character()

reports<-
  tibble(
    input="cardtemplate.qmd",
    output_file = str_glue("{names}.html"),
    execute_params=map(npi_nums,~list(npi=.))
  )

#Create Automated Reports
pwalk(reports,quarto_render)