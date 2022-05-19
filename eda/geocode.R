renv::activate()

library(Rcpp)
library(plyr)
library(RPostgres)
library(DBI)
library(tidyverse)
library(ggmap)
library(sqldf)
library(sf)
library(mapview)

setwd(dirname(rstudioapi::getActiveDocumentContext()$path))

# ?register_google
register_google(key=Sys.getenv("Google_Maps_Platform_API_Key"))

# r DB connection - need to point to prod}
con <- dbConnect(RPostgres::Postgres(), 
                 host="localhost",
                 port="5432",
                 dbname="REI_Prod",
                 user="postgres",
                 password=rstudioapi::askForPassword("Database password"))
# dbExistsTable(con, "factListings")

# Get data
# df_factListings <- dbGetQuery(con, "
# 
# SELECT 
# * 
# FROM 
# public.\"factListings\"
# ;
# ")
dimProperty <- dbGetQuery(con, "
SELECT 
* 
FROM 
public.\"dimProperty\"
;
")
# dimProperty

# # Get existing geocoded values from cache}
dimProperty_fll <- read.csv("geocoded_loc_ref.csv")
# dimProperty_fll

if(!file.exists("geocoded_loc_ref.csv")){
  # no cache - gen new cache
  dimProperty_fll <- mutate_geocode(subset(dimProperty, select=c("full_address")), full_address)
  colnames(dimProperty_fll) <- c("full_address", "longitude", "latitude")
  
  # geocode failed:
  sqldf("
            SELECT
            *
            FROM
            dimProperty_fll
            WHERE
            (longitude IS NULL AND latitude IS NULL)
            ;
            ")
  
  # save scrape
  write.csv(dimProperty_fll,
            "C:/Users/User/Documents/FINANCES_CAREER/ONLINE_BUSINESS/Backend_API_v2/eda/geocoded_loc_ref.csv",
            row.names=FALSE)
}

# Comp between cached and dimProp}
# dim(dimProperty)[1]
# dim(dimProperty_fll)[1]

# to geocode:
# - previously failed-to-geocode records (not written to cache file)
# - new properties recently added to dimProperty
# may need to add failures to cache if always fail to geocode as this may 
# cause slow processing times as the dimension grows
to_geocode <- sqldf("
          SELECT
          full_address
          FROM
          dimProperty
          
          EXCEPT
          
          SELECT
          full_address
          FROM
          dimProperty_fll
          ;
          ")
to_geocode





















