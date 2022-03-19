import os
import re
import datetime
import pandas as pd
import psycopg2
from psycopg2.extensions import AsIs

# 1) this script should go through each row in tempListings,
# 2) check if listing in dimProp,
# 3) if it does - do nothing since prop already being tracked
# 4) if not - add
# 5) irrespective of above add othr attrs to factListings, NB: joins likely be required to get all dim info into fact
# 6) delete tempListings after
#############################################

# 1) 


# 2)


# 3) 


# 4) 


# 5) 


# 6) 
# delete any existing data in tempListings
# cur.execute(
# """
# DELETE 
# FROM 
# public."tempListings"
# ;
# """
# )
        
        
