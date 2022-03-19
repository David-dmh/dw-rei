DELETE 
FROM
public."dimProperty"
;
	
INSERT INTO 
public."dimProperty"(
state_id
,full_address
,suburb
,postcode
)
VALUES 
(
(0
,'5 Leggo Place, Dunlop, ACT 2615'
,'Dunlop'
, 2615)
	,
	(
0
,'51/4 Henshall Way, Macquarie, ACT 2614'
,'Macquarie'
, 2614
)
)
;
-- VALUES 
(
0
,'51/4 Henshall Way, Macquarie, ACT 2614'
,'Macquarie'
, 2614
)
-- ;
