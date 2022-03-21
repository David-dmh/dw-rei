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