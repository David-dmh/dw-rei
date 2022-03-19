/*table created*/
DROP TABLE public."dimState"; 
CREATE TABLE public."dimState" (
	state_id INTEGER PRIMARY KEY NOT NULL
	
	,state_name TEXT
	,associated_taxes NUMERIC
	,associated_average_utilities_cost NUMERIC
	,associated_renters_insurance_cost NUMERIC
);

/*table created*/
DROP TABLE public."dimProperty"; 
CREATE TABLE public."dimProperty" (
	property_id SERIAL PRIMARY KEY NOT NULL
	,state_id INTEGER
	,CONSTRAINT fk_state_id FOREIGN KEY (state_id) REFERENCES public."dimState" (state_id)
	,full_address TEXT
	,suburb TEXT
	,postcode TEXT
);

/*table created*/
DROP TABLE public."dimPurchaseTerms"; 
CREATE TABLE public."dimPurchaseTerms" (
	purchase_terms_id INTEGER PRIMARY KEY NOT NULL
	
	,closing_cost_percent NUMERIC
	,downpayment_percent NUMERIC

);

/*table created*/
DROP TABLE public."dimAcceptanceCriteria"; 
CREATE TABLE public."dimAcceptanceCriteria" (
	acceptance_criteria_id INTEGER PRIMARY KEY NOT NULL
	
	,cashflow NUMERIC
	,return_on_investment NUMERIC
);

/*table created*/
DROP TABLE public."dimLoanTerms"; 
CREATE TABLE public."dimLoanTerms" (
	loan_term_id INTEGER PRIMARY KEY NOT NULL
	
	,loan_interest_rate NUMERIC
	,loan_period NUMERIC
);

/*table created*/
DROP TABLE public."dimExpensePercentages"; 
CREATE TABLE public."dimExpensePercentages" (
	expense_percentages_id INTEGER PRIMARY KEY NOT NULL
	
	,vacancy NUMERIC
	,management NUMERIC
	,maintainance NUMERIC
	,capital_expenditure NUMERIC
);

/*table created*/
DROP TABLE public."factListings"; 
CREATE TABLE public."factListings" (
	property_id INTEGER
	,CONSTRAINT fk_property_id FOREIGN KEY (property_id) REFERENCES public."dimProperty" (property_id)

	,purchase_terms_id INTEGER
	,CONSTRAINT fk_purchase_terms_id FOREIGN KEY (purchase_terms_id) REFERENCES public."dimPurchaseTerms" (purchase_terms_id)
	
	,acceptance_criteria_id INTEGER
	,CONSTRAINT fk_acceptance_criteria_id FOREIGN KEY (acceptance_criteria_id) REFERENCES public."dimAcceptanceCriteria" (acceptance_criteria_id)
	
	,loan_term_id INTEGER
	,CONSTRAINT fk_loan_term_id FOREIGN KEY (loan_term_id) REFERENCES public."dimLoanTerms" (loan_term_id)
	
	,expense_percentages_id INTEGER
	,CONSTRAINT fk_expense_percentages_id FOREIGN KEY (expense_percentages_id) REFERENCES public."dimExpensePercentages" (expense_percentages_id)
	
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

/*table created*/
DROP TABLE public."tempListings"; 
CREATE TABLE public."tempListings" (
	full_address TEXT
	,suburb TEXT
	,"state" TEXT
	,postcode TEXT
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
