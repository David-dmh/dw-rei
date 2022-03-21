
/*table created*/
DROP TABLE IF EXISTS public."factListings"; 
CREATE TABLE public."factListings" (
	property_id INTEGER
	,CONSTRAINT fk_property_id FOREIGN KEY (property_id) REFERENCES public."dimProperty" (property_id)

	-- ,purchase_terms_id INTEGER
	-- ,CONSTRAINT fk_purchase_terms_id FOREIGN KEY (purchase_terms_id) REFERENCES public."dimPurchaseTerms" (purchase_terms_id)
	
	-- ,acceptance_criteria_id INTEGER
	-- ,CONSTRAINT fk_acceptance_criteria_id FOREIGN KEY (acceptance_criteria_id) REFERENCES public."dimAcceptanceCriteria" (acceptance_criteria_id)
	
	-- ,loan_term_id INTEGER
	-- ,CONSTRAINT fk_loan_term_id FOREIGN KEY (loan_term_id) REFERENCES public."dimLoanTerms" (loan_term_id)
	
	-- ,expense_percentages_id INTEGER
	-- ,CONSTRAINT fk_expense_percentages_id FOREIGN KEY (expense_percentages_id) REFERENCES public."dimExpensePercentages" (expense_percentages_id)
	
	,price NUMERIC
	,bedrooms NUMERIC
	,bathrooms NUMERIC
	,parking_spaces NUMERIC
	,building_size NUMERIC
	,building_size_unit TEXT
	,land_size NUMERIC
	,land_size_unit TEXT
	,sold_date TEXT
	,listing_company_name TEXT
	,description TEXT
	,listing_download_date TEXT
)
;

-- /*table created*/
-- DROP TABLE IF EXISTS public."tempListings"; 
-- CREATE TABLE public."tempListings" (
	-- full_address TEXT
	-- ,suburb TEXT
	-- ,"state" TEXT
	-- ,postcode TEXT
	-- ,price NUMERIC
	-- ,bedrooms NUMERIC
	-- ,bathrooms NUMERIC
	-- ,parking_spaces NUMERIC
	-- ,building_size NUMERIC
	-- ,building_size_unit TEXT
	-- ,land_size NUMERIC
	-- ,land_size_unit TEXT
	-- ,sold_date TEXT
	-- ,listing_company_name TEXT
	-- ,description TEXT
	-- ,listing_download_date TEXT
-- )
-- ;

/*table created*/
DROP TABLE IF EXISTS public."dimProperty"; 
CREATE TABLE public."dimProperty" (
	property_id SERIAL PRIMARY KEY NOT NULL
	,state_id INTEGER
	,CONSTRAINT fk_state_id FOREIGN KEY (state_id) REFERENCES public."dimState" (state_id)
	,full_address TEXT
	,suburb TEXT
	,postcode TEXT
);

/*table created*/
DROP TABLE IF EXISTS public."dimState"; 
CREATE TABLE public."dimState" (
	state_id INTEGER PRIMARY KEY NOT NULL
	,state_name TEXT
	,associated_taxes NUMERIC
	,associated_average_utilities_cost NUMERIC
	,associated_renters_insurance_cost NUMERIC
);

INSERT INTO 
public."dimState"(
state_id, state_name, associated_taxes, associated_average_utilities_cost, associated_renters_insurance_cost)
VALUES 
(0, 'ACT', 1.00, 2600, 332)
;
	
INSERT INTO 
public."dimState"(
state_id, state_name, associated_taxes, associated_average_utilities_cost, associated_renters_insurance_cost)
VALUES 
(1, 'NSW', 1.60, 2244, 431)
;
	
INSERT INTO 
public."dimState"(
state_id, state_name, associated_taxes, associated_average_utilities_cost, associated_renters_insurance_cost)
VALUES 
(2, 'NT', 0.00, 2200, 310)
;
	
INSERT INTO 
public."dimState"(
state_id, state_name, associated_taxes, associated_average_utilities_cost, associated_renters_insurance_cost)
VALUES (3, 'QLD', 2.75, 2040, 450)
;
	
INSERT INTO 
public."dimState"(
state_id, state_name, associated_taxes, associated_average_utilities_cost, associated_renters_insurance_cost)
VALUES (4, 'SA', 2.40, 3360, 336)
;

INSERT INTO 
public."dimState"(
state_id, state_name, associated_taxes, associated_average_utilities_cost, associated_renters_insurance_cost)
VALUES (5, 'TAS', 1.50, 2000, 313)
;

INSERT INTO 
public."dimState"(
state_id, state_name, associated_taxes, associated_average_utilities_cost, associated_renters_insurance_cost)
VALUES (6, 'VIC', 2.55, 2484, 377)
;

INSERT INTO 
public."dimState"(
state_id, state_name, associated_taxes, associated_average_utilities_cost, associated_renters_insurance_cost)
VALUES (7, 'WA', 2.67, 2328, 392)
;

/*table to be recreated*/
DROP TABLE IF EXISTS public."PurchaseTerms"; 
CREATE TABLE public."PurchaseTerms" (
	purchase_terms_id INTEGER PRIMARY KEY NOT NULL
	,closing_cost_percent NUMERIC
	,downpayment_percent NUMERIC

);

INSERT INTO 
public."PurchaseTerms"
(
purchase_terms_id
,closing_cost_percent
,downpayment_percent)
VALUES 
(
0
,5
,2)
;

/*table created*/
DROP TABLE IF EXISTS public."AcceptanceCriteria"; 
CREATE TABLE public."AcceptanceCriteria" (
	acceptance_criteria_id INTEGER PRIMARY KEY NOT NULL
	,cashflow NUMERIC
	,return_on_investment NUMERIC
);

INSERT INTO 
public."AcceptanceCriteria"
(
acceptance_criteria_id
,cashflow
,return_on_investment
)
VALUES 
(0
,1
,25
)
;

/*table created*/
DROP TABLE IF EXISTS public."LoanTerms"; 
CREATE TABLE public."LoanTerms" (
	loan_terms_id INTEGER PRIMARY KEY NOT NULL
	,loan_interest_rate NUMERIC
	,loan_period NUMERIC
);

INSERT INTO 
public."LoanTerms"
(
loan_terms_id
,loan_interest_rate
,loan_period
)
VALUES (
0
,5
,30
)
;

/*table created*/
DROP TABLE IF EXISTS public."ExpensePercentages"; 
CREATE TABLE public."ExpensePercentages" (
	expense_percentages_id INTEGER PRIMARY KEY NOT NULL
	,vacancy NUMERIC
	,management NUMERIC
	,maintainance NUMERIC
	,capital_expenditure NUMERIC
);

INSERT INTO 
public."ExpensePercentages"
(
expense_percentages_id
,vacancy
,management
,maintainance
,capital_expenditure)
VALUES 
(0
,5
,10
,5
,5
)
;
