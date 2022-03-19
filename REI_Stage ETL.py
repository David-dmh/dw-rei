# this script should do the following (done iteratively for states):
# scrape for WA as an example and put into tempListings
# for each in tempListings, load or update into dimProperty and place other attrs into factListings

from realestate_com_au import RealestateComAu
import pickle
import os
import re
import datetime
import pandas as pd
import psycopg2
from psycopg2.extensions import AsIs


def format_clean_enrich(listings):
    """
    Format by keeping only certain keys.
    Clean descriptions. 
    Enrich by adding timestamp.
    """
    keys_to_keep = ["full_address", 
                    "suburb",
                    "state",
                    "postcode",
                    "price",
                    "bedrooms",
                    "bathrooms",
                    "parking_spaces",
                    "building_size",
                    "building_size_unit",
                    "land_size",
                    "land_size_unit",
                    "listing_company_name",
                    "sold_date",
                    "description"]
    
    # loop through each listing in listings list
    listings_fixed = []
    for l in listings:        
        l = l.__dict__ # make dict
        l = {k: v for k, v in l.items() if k in keys_to_keep} # keep only desired keys
        pattern = "<[A-Za-z]+\/{0,1}>" # clean listing description
        if l["description"] is not None:
            l["description"] = re.sub(pattern=pattern, 
                                      repl="", 
                                      string=l["description"])
        # add download datestamp
        l["listing_download_date"] = str(datetime.datetime.now().date())
        
        # clean building size - remove spaces, commas and convert to float
        if l["building_size"] is not None and isinstance(l["building_size"], str):
            l["building_size"] = l["building_size"]\
            .replace(",", "")\
            .replace(" ", "")
            l["building_size"] = float(l["building_size"])
       
        # clean land size "
        if l["land_size"] is not None and isinstance(l["land_size"], str):
            l["land_size"] = l["land_size"]\
            .replace(",", "")\
            .replace(" ", "")
            l["land_size"] = float(l["land_size"])
        
        listings_fixed.append(l)
        
    return listings_fixed

###################################################
# 1, 2, 3 )
###################################################

api = RealestateComAu()

# get property listings for these states
locs = ["ACT"]
for loc in locs:
    print(f"Starting {loc} ETL ...")
    print(f"Scraping: {loc} ...")
    listings = api.search(locations=[loc], # locations=["seventeen seventy, qld 4677"], 
                          channel="buy",
                          surrounding_suburbs=True,
                          exclude_no_sale_price=True,
                          furnished=False,
                          pets_allowed=True,
                          ex_under_contract=True,
                          min_price=0,
                          max_price=-1,
                          min_bedrooms=0,
                          max_bedrooms=-1,
                          property_types=["house", "unit apartment"],  # "house", "unit apartment", "townhouse", "villa", "land", "acreage", "retire", "unitblock",
                          min_bathrooms=0,
                          min_carspaces=0,
                          min_land_size=0,
                          construction_status=None,  # NEW, ESTABLISHED
                          keywords=[],
                          exclude_keywords=[])
    print("Number of listings found: ", len(listings) , "...")
    print("Cleaning...")
    listings = format_clean_enrich(listings)
    print("Done...")
    
    # put listings into tempListings table
    print("Adding to db...")
    try:
        conn = psycopg2.connect(dbname="REI_Stage", 
                                user="postgres", 
                                password=os.environ["POSTGRES_PASSWORD"])
                             
        cur = conn.cursor()
        
        # iteratively insert newly scraped listings - fix this
        for listing in listings:
            columns = listing.keys()
            values = [listing[column] for column in columns]
            templistings_insert_command = \
            """
            INSERT INTO 
            public."tempListings" (%s) 
            VALUES 
            %s
            ;
            """
            cur.execute(templistings_insert_command, (AsIs(",".join(columns)), tuple(values)))  
        
        # remove NULLS for key columns
        NB_cols = ["full_address", 
            "suburb", 
            "state", 
            "postcode", 
            "price"]
            
        for col in NB_cols:
            cur.execute(
            f"""
            DELETE 
            FROM 
            public."tempListings" 
            WHERE "{col}" IS NULL
            ;
            """
            )
    
        # cleaning - replace -1.0 with NULL for land_size (scraper issue workaround)
        cur.execute(
        """
        UPDATE 
        public."tempListings"
        SET 
        "land_size" = NULL
        WHERE
        "land_size" = -1.0
        ;
        """
        )
        
    except (Exception, psycopg2.DatabaseError) as error:
        # print(cur.mogrify(insert_command, (AsIs(",".join(columns)), tuple(values))))
        print(error)
    
    cur.close()
    conn.commit()
    print("...Done")
    
    print(f"Loading {loc} records from tempListings into Stage DW...")
    
    # 1) udate dimProperty,
    # 2) update factListings
    # 3) delete tempListings for current loc after, then resumes for loop (next state)
    #############################################

    # 1) 
    cur.execute(
    """
    INSERT INTO
    public."dimProperty"
    (
    state_id
    ,full_address
    ,suburb
    ,postcode
    )
    SELECT 
    ds.state_id
    ,tl.full_address
    ,tl.suburb
    ,tl.postcode
    FROM
    public."tempListings" tl
    INNER JOIN
    public."dimState" ds
    ON 
    ds.state_name = tl.state
    WHERE
    tl.full_address
    NOT IN
    (SELECT 
    full_address
    FROM
    public."dimProperty"
    )
    ;
    """
    )
   
    # 2)
    cur.execute(
    """
    INSERT INTO
    public."factListings"
    (
    "property_id"
    ,"price"
    ,"bedrooms"
    ,"bathrooms"
    ,"parking_spaces"
    ,"building_size"
    ,"building_size_unit"
    ,"land_size"
    ,"land_size_unit"
    ,"sold_date"
    ,"listing_company_name"
    ,"description"
    ,"listing_download_date"
    )
    SELECT
    dp."property_id"
    ,tl."price"
    ,tl."bedrooms"
    ,tl."bathrooms"
    ,tl."parking_spaces"
    ,tl."building_size"
    ,tl."building_size_unit"
    ,tl."land_size"
    ,tl."land_size_unit"
    ,tl."sold_date"
    ,tl."listing_company_name"
    ,tl."description"
    ,tl."listing_download_date"
    FROM
    public."tempListings" tl
    INNER JOIN
    public."dimProperty" dp
    ON tl."full_address" = dp."full_address"
    ;
    """
    )
   
    # 3) 
    # delete any existing data in tempListings - clean for next state
    cur.execute(
    """
    DELETE 
    FROM 
    public."tempListings"
    ;
    """
    )

    # now all items scraped should have been added to Stage DW (this single script does stage ETL)
    # now need to perform data quality checks / validations before copying DW as is (?*) to Prod DW
    # * supe up for high speed transactions - optimise - can nicely test performace since will have exact same
    # data in both stage and prod but prod should be optimised for quick reads
