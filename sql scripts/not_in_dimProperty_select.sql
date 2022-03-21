-- this query returns table of properties to insert into dimProperty
DROP VIEW IF EXISTS 
query_results
;
CREATE VIEW
query_results
AS
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

SELECT
DISTINCT
*
FROM
query_results
;
