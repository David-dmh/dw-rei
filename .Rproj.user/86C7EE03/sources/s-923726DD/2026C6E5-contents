setwd(Sys.getenv("dw-rei"))

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

# ?register_google
register_google(key=Sys.getenv("Google_Maps_Platform_API_Key"))
#
# r DB connection - need to point to prod}
con <- dbConnect(RPostgres::Postgres(),
                 host="localhost",
                 port="5432",
                 dbname="REI_Prod",
                 user="postgres",
                 password=Sys.getenv("REI_Prod_password"))
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
dimProperty_fll <- read.csv("data/geocoded_loc_ref.csv")
# dimProperty_fll

# if no cache at all in data/ dir
if(!file.exists("data/geocoded_loc_ref.csv")){
  # no cache - gen new cache
  dimProperty_fll <- mutate_geocode(subset(dimProperty, 
                                           select=c("full_address")), 
                                    full_address)
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
            "data/geocoded_loc_ref.csv",
            row.names=FALSE)
}
#
# # Comp between cached and dimProp}
# # dim(dimProperty)[1]
# # dim(dimProperty_fll)[1]
#
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
# to_geocode

if(dim(to_geocode)[1] != 0){
  # single run - working
  df_dimProperty_fll_temp <- data.frame(to_geocode, stringsAsFactors=FALSE)
  colnames(df_dimProperty_fll_temp) <- c("full_address")
  df_dimProperty_fll_new <- mutate_geocode(df_dimProperty_fll_temp, 
                                           full_address)
  colnames(df_dimProperty_fll_new) <- c("full_address", "longitude", "latitude")
  # df_dimProperty_fll_new
}

if(exists("df_dimProperty_fll_new")){
  # non-empty = write
  # merge with cached if above results are non-empty
  dimProperty_fll_merged <- merge(x=dimProperty_fll,
                                  y=df_dimProperty_fll_new,
                                  by="full_address",
                                  all=TRUE)

  # reformat
  skew_rows <- which(!is.na(dimProperty_fll_merged[, 4]))

  # shift .y's left
  if(length(skew_rows) != 0){
    for(i in skew_rows){
      dimProperty_fll_merged[i, 2:3] <- dimProperty_fll_merged[i, 4:5]
    }
  }

  colnames(dimProperty_fll_merged)[2:3] <- c("longitude", "latitude")
  # discard old columnns
  dimProperty_fll_merged <- subset(dimProperty_fll_merged,
                                   select=c("full_address", 
                                            "longitude", 
                                            "latitude"))
  # # update cache
  write.csv(
    dimProperty_fll_merged,"data/geocoded_loc_ref.csv",
    row.names=FALSE)
  # view new
  # dimProperty_fll_merged
}

# # this data ready for analysis, just need to exclude nulls (if applicable) for plot
# df <- read.csv("data/geocoded_loc_ref.csv")
# # df
# 
# # remove nulls (if blanks in cache)
# df <- sqldf("
#           SELECT
#           *
#           FROM
#           df
#           WHERE
#           (longitude IS NOT NULL OR latitude IS NOT NULL)
#           AND
#           (latitude < -10.360438)
#           AND
#           (latitude < -10.360438)
#           AND
#           (latitude > -45.599262)
#           AND
#           (longitude > 111.861226)
#           AND
#           (longitude < 155.542866)
#           ;
#           ")
# df
# AU
# UB and LB = -10.360438 <-> -45.599262 (latitude range)
# LB and RB = 111.861226 <-> 155.542866 (longitude range)

# check that the geocoding done correctly with mapview
# locations_sf <- st_as_sf(df, 
#                          coords=c("longitude", "latitude"), 
#                          crs=4326)
# locations_sf

# mapview(locations_sf)
