-- "WITH fl_price AS (SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 100) SELECT listing_download_date AS Listing_Date, percentile_cont(0.5) WITHIN GROUP (ORDER BY fl.price) AS Median_Price FROM public.\"factListings\" fl LEFT OUTER JOIN public.\"dimProperty\" dp ON fl.\"property_id\" = dp.\"property_id\" WHERE dp.\"state_id\" IN %s GROUP BY fl.listing_download_date;",

-- WITH 
-- fl_price AS 
-- (
-- SELECT 
-- 1   
-- UNION ALL
-- SELECT 
-- 2
-- UNION ALL
-- SELECT 
-- 100
-- )
-- SELECT
-- listing_download_date AS Listing_Date
-- ,percentile_cont(0.5) WITHIN GROUP (ORDER BY fl.price) AS Median_Price
-- FROM
-- public.\"factListings\" fl 
-- LEFT OUTER JOIN 
-- public.\"dimProperty\" dp 
-- ON 
-- fl.\"property_id\" = dp.\"property_id\" 
-- WHERE dp.\"state_id\" IN (2)
-- GROUP BY
-- fl.listing_download_date
-- ;
-- 

WITH 
fl_price AS 
(
SELECT 
1   
UNION ALL
SELECT 
2
UNION ALL
SELECT 
100
)
SELECT
listing_download_date AS Listing_Date
,percentile_cont(0.5) WITHIN GROUP (ORDER BY fl.price) AS Median_Price
FROM
public."factListings" fl 
LEFT OUTER JOIN 
public."dimProperty" dp 
ON 
fl."property_id" = dp."property_id" 
WHERE dp."state_id" IN (2)
GROUP BY
fl.listing_download_date
;

-- WITH 
-- fl_price AS 
-- (
-- SELECT 
-- 1   
-- UNION ALL
-- SELECT 
-- 2
-- UNION ALL
-- SELECT 
-- 100
-- )
-- SELECT
-- percentile_cont(0.5) WITHIN GROUP (ORDER BY fl.price)
-- FROM
-- public."factListings" fl 
-- LEFT OUTER JOIN 
-- public."dimProperty" dp 
-- ON 
-- fl."property_id" = dp."property_id" 
-- WHERE dp."state_id" IN (2)
-- ;
-- 

-- WITH 
-- fl_price AS 
-- (
-- SELECT 
-- 1   
-- UNION ALL
-- SELECT 
-- 2
-- UNION ALL
-- SELECT 
-- 100
-- )
-- SELECT
-- percentile_cont(0.5) WITHIN GROUP 
-- (
-- ORDER BY fl.\"price\"
-- )
-- FROM
-- PUBLIC.\"factListings\" fl 
-- LEFT OUTER JOIN 
-- PUBLIC.\"dimProperty\" dp 
-- ON 
-- fl.\"property_id\" = dp.\"property_id\" 
-- WHERE dp.\"state_id\" IN (2)
-- ;
-- 