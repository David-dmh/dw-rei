from realestate_com_au import RealestateComAu
import pickle
import os
import re
import datetime

# this modified etl script should take in a listing limit and desired state all optional
# first do a take on like before with large number of listings to populate
# then do batch loads every day with latest props, schedule for 6am
# this data should go into single listings table in stage db

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
        l["listing_download_date"] = str(datetime.datetime.now().date())
        listings_fixed.append(l)
        
    return listings_fixed


api = RealestateComAu()

# get property listings for all states
locs = ["ACT", "NSW", "NT", "QLD", "SA", "TAS", "VIC", "WA"]
for loc in locs:
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
                          property_types=["house", "unit apartment"],  # "house", "unit apartment", "townhouse", 
                          # "villa", "land", "acreage", "retire", "unitblock",
                          min_bathrooms=0,
                          min_carspaces=0,
                          min_land_size=0,
                          construction_status=None,  # NEW, ESTABLISHED
                          keywords=[],
                          exclude_keywords=[])

    print("Cleaning...")
    listings = format_clean_enrich(listings)
    print("...Done")
    print("Saving...")
    date = str(datetime.datetime.now().date())
    with open(f"state_data/{date}_{loc}.txt", 'wb') as f:
        pickle.dump(listings, f)

    print("...Done")
