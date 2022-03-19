-- number of properties to consider adding to dimProperty
SELECT count(DISTINCT(full_address))
FROM 
public."tempListings"
;