import os
import pandas as pd
import psycopg2

# script to test query select into list
conn = psycopg2.connect(dbname="REI_Stage", 
                                user="postgres", 
                                password=os.environ["POSTGRES_PASSWORD"])
cur = conn.cursor()
command = \
"""
SELECT 
"full_address" 
FROM 
public."tempListings"
;
"""
cur.execute(command)
col_content = cur.fetchall() 
cur = conn.cursor()
cur.close()
conn.commit()

col_content = [tup[0] for tup in col_content]

print(col_content)
		
		
# unused code ################################

for listing in tempListings:
        # get addrs in dimProp
        command = \
        """
        SELECT 
        "full_address" 
        FROM 
        public."dimProperty"
        ;
        """
        cur.execute(command)
        dimprop_addresses = cur.fetchall() 
        dimprop_addresses = [tup[0] for tup in dimprop_addresses]
        # 2) # tidy this logic up, some code is redundant
        fact_cols = ["price", "bedrooms", "bathrooms", 
                         "parking_spaces", "building_size", 
                         "building_size_unit", "land_size", 
                         "land_size_unit", "sold_date", 
                         "listing_company_name", "description", 
                         "listing_download_date"]
        if listing["full_address"] not in dimprop_addresses: # if listing not in dimProperty, add to dimProperty
            # 4)
            dimprop_insert_command = \ # this is currently wrong as selecting all and not just for record - do dimProp update initially
            """
            INSERT INTO 
            public."dimProperty"  
            VALUES(
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
            ;
            ) 
            ;   
            """
            cur.execute(dimprop_insert_command)
            
        # 3)
        else:
            # add other attr to fact AND foreign keys! (TO DO!!!!!!!!!!)
            listing_subset = dict((k, listing[k]) for k in fact_cols) # NEED TO SUBSET APPLIC COLS HERE
            cols = listing_subset.keys()
            values = [listing_subset[col] for col in cols] 
            fact_insert_command = \
            """
            INSERT INTO 
            public."factListings" (%s) 
            VALUES 
            %s
            ;
            """
            cur.execute(fact_insert_command, (AsIs(",".join(cols)), tuple(values)))  
            # add details to dimProp
            # to test, 2x already in dimProperty
            # check number of distinct full_address's in tempListings - 359
            # then run below query to update dimProperty
            # should have inserted 1 less than number of distinct in tempListings - there should be 358 distinct props in dimProperty
            # 
            dimprop_insert_command = \
            """
            INSERT INTO 
            public."dimProperty"  
            VALUES(
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
            ;
            ) 
            ;
            """
            cur.execute(dimprop_insert_command) 
            # add other attr to fact
            listing_subset = dict((k, listing[k]) for k in fact_cols) # NEED TO SUBSET APPLIC COLS HERE
            cols = listing_subset.keys()
            values = [listing_subset[col] for col in cols] 
            fact_insert_command = \
            """
            INSERT INTO 
            public."factListings" (%s) 
            VALUES 
            %s
            ;
            """
            cur.execute(fact_insert_command, (AsIs(",".join(cols)), tuple(values)))  
            
# unused code ################################

            
            