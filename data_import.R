library(rdataretriever)
library(dplyr)
library(DBI)

# TODO:
# 1. Initial filter of routes for weather issues
# 2. Initial filter of routes for time length?
# 3. Initial filter of species (unknown water,etc)

# Check to see if the BBS database is already installed
if (!("BBS.sqlite" %in% list.files())){
  rdataretriever::install(dataset = "breed-bird-survey", 
                          connection = "sqlite", 
                          db_file = "BBS.sqlite")
}

con = dbConnect(RSQLite::SQLite(), "BBS.sqlite")

counts = tbl(con, "breed_bird_survey_counts")
