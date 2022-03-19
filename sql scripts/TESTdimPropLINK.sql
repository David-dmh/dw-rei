SELECT
tl."full_address"
,tl."price"
FROM
public."tempListings" tl
INNER JOIN 
public."dimProperty" dp
ON tl."full_address" = dp."full_address";
;
