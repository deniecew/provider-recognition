
# Packages
library(quarto)        # Provides functions for rendering Quarto documents 
library(tidyverse)     # A collection of packages for data manipulation and visualization (e.g.,dplyr, purrr, stringr, readr, tidyr, etc.)
library(janitor)       # Useful for cleaning data, especially column names (e.g., clean_names())
library(purrr)
library(readr)
library(dplyr)
library(gt)

# Check the current working directory
getwd()
# setwd("path/to/your/folder")  # Optional if you want to change the directory

# Import the CSV data file into a data frame called 'commentdata'
commentdata <- read.csv("commentdata.csv")

# Clean and preprocess the data
commentdata <- commentdata %>% 
  clean_names() %>% #standardize column names
  filter(provider_nm != "Provider New/Ungroupable") %>% #remove rows with unmapped provider name
  mutate(recdate = as.Date(recdate)) #Convert 'recdate' column to Date type


# Convert 'npi_num' column to character type (important if it contains leading zeros or non-numeric values)
  commentdata$npi_num<-as.character(commentdata$npi_num)


# Iterate over each unique NPI value in the dataset
  for (npi_val in unique(commentdata$npi_num)){
  
# Filter rows for the current NPI using dplyr to create a working subset
  subsetcomments <- commentdata %>% filter(npi_num == npi_val)
  
# Split 'resource_name' into two parts on the first space: last_nm and first_nm
# str_split_fixed returns a matrix with exactly 2 columns; assigning to new columns
  subsetcomments[c('last_nm', 'first_nm')] <- str_split_fixed(subsetcomments$resource_name, ' ', 2)
  
# Convert last and first names to title case for consistent matching (e.g., "smith" -> "Smith")
  last_nm  <- str_to_title(subsetcomments$last_nm)
  first_nm <- str_to_title(subsetcomments$first_nm)
  
# Extract the free-text response field
  x <- subsetcomments$response
# Remove all spaces from the response to normalize text before name matching
  y <- str_replace_all(x, " ", "")
  
# Check whether the last name appears in the space-stripped response
# grepl returns TRUE/FALSE per row; patterns are vectorized to align with y
  subsetcomments$check1 <- grepl(last_nm, y)
# Check whether the first name appears in the space-stripped response
  subsetcomments$check2 <- grepl(first_nm, y)
  
# Keep only the rows where either first or last name was found in the response
  named_comments <- subsetcomments %>% filter(check1 | check2)
  
# Count how many comments matched a name for this NPI
  match_count <- nrow(named_comments)
# Extract the provider name for this NPI (assumes one unique provider per NPI)
  provider    <- unique(subsetcomments$provider_nm)
# Extract the program name for this NPI (assumes one unique program per NPI)
  program     <- unique(subsetcomments$program_nm)
# Count unique dates when matched comments were received, used as a proxy for emails sent
  date_count  <- length(unique(named_comments$recdate))
  
# Append a summary row for this NPI to the cumulative results data frame
  providermatches <- rbind(
    providermatches,
    data.frame(
      program     = program,
      provider_nm = provider,
      npi_num     = npi_val,
      match_count = match_count,
      emails_sent = date_count
    )
  )
}

#Store the clean data for use in the quarto file.
save(commentdata,file="commentdata.Rdata")
save(providermatches,file="providermatches.Rdata")



# Keep only providers that have at least one matched comment
cardrun <- providermatches %>%
  filter(match_count > 0)

# Collect the unique NPI numbers from the filtered set as character values
npi_nums <- cardrun %>%
  distinct(npi_num) %>%     # ensure each NPI appears only once
  pull(npi_num) %>%         # extract the column as a vector
  as.character()            # convert to character for safe downstream use

# Collect the unique provider names from the filtered set as character values
names <- cardrun %>%
  distinct(provider_nm) %>% # ensure each provider appears only once
  pull(provider_nm) %>%     # extract the column as a vector
  as.character()            # convert to character

# Build a tibble describing the batch of Quarto renders to perform
# Each row specifies:
#  - the input template file
#  - the output HTML filename based on provider name
#  - the parameter list passed to the Quarto document for that NPI
reports <-
  tibble(
    input = "cardtemplate.qmd",            # Quarto template to render
    output_file = str_glue("{names}.html"),# Output filenames per provider
    execute_params = map(                  # Parameter list per NPI value
      npi_nums,
      ~ list(npi = .)                      # Pass 'npi' parameter into the doc
    )
  )

# 1) Render all reports by walking each row of 'reports' into quarto_render()
# pwalk passes the columns as named arguments matching quarto_render's signature
# This produces one HTML report per provider with the corresponding NPI parameter
pwalk(reports, quarto_render)

# 2) Collect all per-NPI summaries
files <- list.files("summaries", pattern = "\\.csv$", full.names = TRUE)
combined_df <- map_dfr(files, readr::read_csv)

# 3) Print one combined GT table
combined_table <- combined_df %>%
  arrange(provider_nm)

write_csv(combined_table, file = "summarytable.csv")
