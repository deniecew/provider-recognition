library(dplyr)
library(stringr)

load("C:/Users/4477078/OneDrive - Moffitt Cancer Center/provider_recognition/commentdata.Rdata")

matches_df <- data.frame(provider_nm = character(), npi_num = character(), match_count = integer(), 
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
  # Store result in the data frame
  # Print number of matching comments
  # print(paste("Provider:", unique(subsetcomments$provider_nm), "NPI:", npi_val, "- Matches:", nrow(named_comments)))
  matches_df <- rbind(matches_df, data.frame(provider = provider, npi_num = npi_val, match_count = match_count))
}

print(matches_df)

write.csv(matches_df, "provider_shoutouts.csv", row.names = FALSE)
