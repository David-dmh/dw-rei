-- insert relevant data into factListings
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

