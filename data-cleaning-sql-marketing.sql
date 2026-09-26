-- Duplicate the table so the production data remains unchanged: 
SELECT *
INTO marketing_data_copy
FROM marketing_dataset;


-- Checking if the data was copied identically. If the result is empty, then it's successfull:
(
    SELECT * FROM marketing_dataset
    EXCEPT
    SELECT * FROM marketing_data_copy
)
UNION ALL
(
    SELECT * FROM marketing_data_copy
    EXCEPT
    SELECT * FROM marketing_dataset
);



-- Checking column properties:
SELECT
    COLUMN_NAME 
    ,DATA_TYPE 
    ,IS_NULLABLE
    ,CHARACTER_MAXIMUM_LENGTH
FROM 
    INFORMATION_SCHEMA.COLUMNS
WHERE 
    TABLE_NAME = 'marketing_data_copy';



-- Checking the total number of rows:
SELECT
	COUNT(*)
FROM marketing_data_copy;


-- transforming field names to lowercase so they're easier to use in succeeding queries:
ALTER TABLE marketing_data_copy RENAME "Campaign_ID" to campaign_id;
ALTER TABLE marketing_data_copy RENAME "Customer_ID" to customer_id;
ALTER TABLE marketing_data_copy RENAME "Signup_Date" to signup_date;
ALTER TABLE marketing_data_copy RENAME "Customer_Age" to customer_age;
ALTER TABLE marketing_data_copy RENAME "Gender" to gender;
ALTER TABLE marketing_data_copy RENAME "Email_Address" to email_address;
ALTER TABLE marketing_data_copy RENAME "Region" to region;
ALTER TABLE marketing_data_copy RENAME "Campaign_Channel" to campaign_channel;
ALTER TABLE marketing_data_copy RENAME "Campaign_Status" to campaign_status;
ALTER TABLE marketing_data_copy RENAME "Ad_Spend_USD" to ad_spend_usd;
ALTER TABLE marketing_data_copy RENAME "Impressions" to impressions;
ALTER TABLE marketing_data_copy RENAME "Clicks" to clicks;
ALTER TABLE marketing_data_copy RENAME "Conversions" to conversions;
ALTER TABLE marketing_data_copy RENAME "Revenue_USD" to revenue_usd;


-- Making general observations about the data:
SELECT 
	*
FROM marketing_data_copy
LIMIT 20;


-- There are 2 fields that I think could be unique and can be used as a primary key: customer_id and campaign_id.
-- Checking if campaign_id is a unique id:
SELECT 
	COUNT(DISTINCT(campaign_id))
FROM marketing_data_copy 
HAVING COUNT(campaign_id) > 1;

SELECT 
	COUNT(DISTINCT(customer_id))
FROM marketing_data_copy 
HAVING COUNT(customer_id) > 1;

-- Since both of them are not unique, I'll introduce a primary key so that I can accurately check for duplicates.
ALTER TABLE marketing_data_copy
ADD COLUMN unique_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY;

-- Checking if the new field was placed successfully:
SELECT
	MIN(unique_id)
	,MAX(unique_id)
FROM marketing_data_copy;


-- Since the total number of rows and the max number of the new field matched, we can now check for exact duplicates:
WITH duplicate_check AS (
	SELECT 
	unique_id
	,ROW_NUMBER () OVER (
		PARTITION BY
				impressions
				,clicks
				,conversions
				,revenue_usd
				,gender
				,email_address
				,region
				,campaign_id
				,campaign_status
				,ad_spend_usd
				,campaign_channel
				,customer_id
				,signup_date
				,customer_age
				) 
		AS dupe_check
	FROM marketing_data_copy)

SELECT 
*
FROM duplicate_check
WHERE
	1=1
	AND dupe_check > 1
ORDER BY unique_id;


--There are 1000 ids with exact duplicates. We should delete exact duplicates given the current business sense:
WITH duplicate_check AS (
	SELECT 
	unique_id
	,ROW_NUMBER () OVER (
		PARTITION BY
				impressions
				,clicks
				,conversions
				,revenue_usd
				,gender
				,email_address
				,region
				,campaign_id
				,campaign_status
				,ad_spend_usd
				,campaign_channel
				,customer_id
				,signup_date
				,customer_age
				) 
		AS dupe_check
	FROM marketing_data_copy)

DELETE FROM marketing_data_copy
WHERE unique_id IN (
	SELECT unique_id 
	FROM duplicate_check
	WHERE
	1=1
	AND dupe_check > 1
	);


-- Now let's run the previous query to check if all the duplicates have been eliminated:
WITH duplicate_check AS (
	SELECT 
	unique_id
	,ROW_NUMBER () OVER (
		PARTITION BY
				impressions
				,clicks
				,conversions
				,revenue_usd
				,gender
				,email_address
				,region
				,campaign_id
				,campaign_status
				,ad_spend_usd
				,campaign_channel
				,customer_id
				,signup_date
				,customer_age
				) 
		AS dupe_check
	FROM marketing_data_copy)

SELECT 
*
FROM duplicate_check
WHERE
	1=1
	AND dupe_check > 1
ORDER BY unique_id;


/* Seeing that the duplicates have been removed, and that 
 * the table does not need to be split into multiple tables, 
 * we now proceed to checking each column for errors. */

-- Now let's start checking the columns:
SELECT
	*
FROM marketing_data_copy
LIMIT 10;


-- Checking the campaign_id data type:
SELECT
	column_name
	,data_type
FROM information_schema.columns
WHERE
	table_name = 'marketing_data_copy'
	AND column_name = 'campaign_id';
-- campaign_id data type is varchar. No need to change it. 



-- Checking for errors in expected length of campaign_id:
SELECT
	DISTINCT(LENGTH(campaign_id))
FROM marketing_data_copy;
-- all entries have 8 characters in them. This also means it's clear of leading and trailing spaces.

-- Checking for errors in expected pattern in campaign_id:
SELECT
	campaign_id
FROM marketing_data_copy 
WHERE campaign_id 
	NOT SIMILAR TO 'CMP-[0-9][0-9][0-9][0-9]'; -- this is the campaign_id expected pattern.
-- there are no errors in the expected pattern. 


-- Checking for nulls
SELECT
	unique_id
	,campaign_id
FROM marketing_data_copy 
WHERE 
	campaign_id IS NULL;
-- there are no nulls

-- No need to check for duplicates in campaign_id since duplicates are acceptable in the current business context.



-- Now, let's check the customer_id:
SELECT
	*
FROM marketing_data_copy
LIMIT 10;

-- Checking the customer_id data type:
SELECT
	column_name
	,data_type
FROM information_schema.columns
WHERE
	column_name = 'customer_id';
-- its set as varchar, so there's no need to change it. 


-- Now let's check the length:
SELECT
	DISTINCT(LENGTH(customer_id))
FROM marketing_data_copy;
-- all of them have the same length.


-- Checking if campaign_id follows the expected pattern:
SELECT 
	customer_id
FROM marketing_data_copy 
WHERE
	customer_id NOT SIMILAR TO 'CUST-[0-9][0-9][0-9][0-9][0-9][0-9]';
-- all of the data fall into the expected pattern

	
-- Checking for duplicates:

WITH duplicate_check AS (
	SELECT
		ROW_NUMBER () OVER (PARTITION BY customer_id) AS dupe_check
		,*
	FROM marketing_data_copy)

SELECT
	*
FROM marketing_data_copy
WHERE customer_id IN (
	SELECT 	
		customer_id
	FROM duplicate_check
	WHERE dupe_check > 1)
ORDER BY customer_id;


-- There are multiple customer_id duplicates. Let's check if they are the same 
	WITH 
	duplicate_check AS (
	SELECT
		ROW_NUMBER () OVER (PARTITION BY customer_id) AS dupe_check
		,*
	FROM marketing_data_copy)
	
	,dupe_2 AS
	(SELECT 
		*
	FROM duplicate_check
	WHERE dupe_check > 1)

	,dupe_3 AS
	(SELECT
		*
	FROM duplicate_check
	WHERE
		1=1 
		AND dupe_check = 1
		AND customer_id IN (SELECT customer_id FROM dupe_2))
	
	SELECT 
				-- t1.unique_id
				-- ,t2.unique_id
				t1.impressions
				,t2.impressions
				,t1.clicks
				,t2.clicks
				,t1.conversions
				,t2.conversions
				,t1.revenue_usd
				,t2.revenue_usd
				,t1.gender
				,t2.gender
				,t1.email_address
				,t2.email_address
				,t1.region
				,t2.region
				,t1.campaign_id
				,t2.campaign_id
				,t1.campaign_status
				,t2.campaign_status
				,t1.ad_spend_usd
				,t2.ad_spend_usd
				,t1.campaign_channel
				,t2.campaign_channel
				,t1.customer_id
				,t2.customer_id
				,t1.signup_date
				,t2.signup_date
				,t1.customer_age
				,t2.customer_age
	FROM dupe_2 t1 
		JOIN dupe_3 t2 
			ON t1.customer_id = t2.customer_id
	WHERE t1.* = t2.*;
				

/* Since none of the customer_id duplicates are exact copies with respect to 
 * other personally identifiable columns (i.e. age, region, signup_date, etc) 
 * we're going to assume that these are errors in customer_id and so we're 
 * going to use the generated primary key earlier for the sake of this analysis.
 */

-- Onto the next column:
SELECT
	column_name
	,data_type
FROM information_schema.columns
WHERE
	table_name = 'marketing_data_copy'
	AND column_name = 'signup_date';
-- Since signup_date is currently set as a varchar, we need to change it to datetime.

-- Let's check first if the dates have the same length:
SELECT
	DISTINCT(LENGTH(signup_date))
FROM marketing_data_copy mdc;
-- There are dates that have 10 characters, 12 characters, and 0 characters. We need to do some formatting:

SELECT
	signup_date 
FROM marketing_data_copy 
WHERE LENGTH(signup_date) = 10;
-- the dates have different formatting. We'll address them in a while.

SELECT
	DISTINCT(signup_date)
FROM marketing_data_copy 
WHERE LENGTH(signup_date) = 12;
-- here, we only have INVALID_DATE. We can just turn this to nulls.

SELECT
	DISTINCT(signup_date)
FROM marketing_data_copy 
WHERE LENGTH(signup_date) = 0;
-- these are non-null blanks. We should turn them to nulls.


-- Let's first turn the invalid dates and blanks to nulls:
BEGIN;
UPDATE marketing_data_copy 
SET signup_date = NULL
WHERE
	LENGTH(signup_date) = 12
	OR LENGTH(signup_date) = 0;
COMMIT;

-- Now that we've turned them to nulls, let's address the formatting:
CREATE OR REPLACE FUNCTION parse_date(val TEXT) 
RETURNS DATE AS $$
BEGIN

    RETURN TO_DATE(val, 'YYYY-MM-DD');
EXCEPTION WHEN others THEN
    BEGIN
       
        RETURN TO_DATE(val, 'MM/DD/YYYY');
    EXCEPTION WHEN others THEN
        BEGIN
            
            RETURN TO_DATE(val, 'DD/MM/YYYY');
        EXCEPTION WHEN others THEN
            BEGIN
                
                RETURN TO_DATE(val, 'DD-MM-YYYY');
            EXCEPTION WHEN others THEN
                
                RETURN NULL;
            END;
        END;
    END;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

SELECT 
	signup_date
	,parse_date(signup_date) AS clean_date
FROM marketing_data_copy;

-- Now that we see that the parser works, let's use it to update the table:
BEGIN;
UPDATE marketing_data_copy
	SET signup_date = parse_date(signup_date);
COMMIT;

-- checking if it worked:
SELECT
	DISTINCT(signup_date)
FROM marketing_data_copy mdc
ORDER BY signup_date;

-- now that we've liminated invalid dates, let's transform all dates into one format:
SELECT
	TO_DATE(signup_date, 'YYYY-MM-DD')
FROM marketing_data_copy
ORDER BY signup_date;

UPDATE marketing_data_copy
SET signup_date = TO_DATE(signup_date, 'YYYY-MM-DD');

-- changing the column data type:
ALTER TABLE marketing_data_copy 
ALTER COLUMN signup_date TYPE date
USING signup_date::date;

-- checking if it was changed:
SELECT 
	column_name
	,data_type
FROM information_schema.columns
WHERE table_name = 'marketing_data_copy';

-- Now let's check for invalid date ranges, according to busines logic:
SELECT
	DISTINCT(signup_date)
FROM marketing_data_copy
ORDER BY signup_date;


-- There's one invalid date we should remove and turn to null.
UPDATE marketing_data_copy 
SET signup_date = NULL 
WHERE signup_date = '0001-01-01';


-- Now that the dates are clear, let's check customer_age next:
SELECT
	column_name
	,data_type
FROM information_schema.columns
WHERE
	table_name = 'marketing_data_copy'
	AND column_name = 'customer_age';

-- customer_age is a varchar. Let's inspect the data to see if we can immediately change it to numeric:
SELECT
	DISTINCT(customer_age)
FROM marketing_data_copy mdc
ORDER BY customer_age;

-- there are negative values, there are range issues, and there are ages which are typed out. 
BEGIN;
UPDATE marketing_data_copy
SET customer_age = (
	CASE
		WHEN customer_age = '' THEN NULL
		WHEN customer_age = 'N/A' THEN NULL
		WHEN customer_age = 'UNKNOWN' THEN NULL
		WHEN customer_age = 'thirty-five' THEN '35'
		WHEN customer_age = 'twenty-eight' THEN '28'
		ELSE customer_age
	END);
COMMIT;


-- Changing the customer_age to numeric:
ALTER TABLE marketing_data_copy 
ALTER COLUMN customer_age TYPE integer
USING customer_age::integer;

-- Addressing range constraints:
BEGIN;
UPDATE marketing_data_copy
SET customer_age = (
	CASE
		WHEN customer_age < 0 THEN NULL
		WHEN customer_age > 100 THEN NULL
		ELSE customer_age
	END);

SELECT
	DISTINCT(customer_age)
FROM marketing_data_copy mdc;
COMMIT;



-- Now let's check the gender column
SELECT
	DISTINCT(gender)
FROM marketing_data_copy;

-- pattern matching:
UPDATE marketing_data_copy
SET gender = TRIM(gender);

-- fixing categories:
WITH genders AS (
	SELECT
		CASE 
			WHEN gender IN ('N', '', 'Unknown') THEN NULL
			WHEN gender IN ('Male', 'M', 'male') THEN 'male'
			WHEN gender IN ('Female', 'F', 'female') THEN 'female'
			WHEN gender IN ('Non-Binary', 'non-binary') THEN 'non-binary'
			ELSE gender
		END AS gender_categ
	FROM marketing_data_copy)
	
SELECT 
	DISTINCT(gender_categ)
FROM genders;

BEGIN;
UPDATE marketing_data_copy
SET gender = (
		CASE 
			WHEN gender IN ('N', '', 'Unknown') THEN NULL
			WHEN gender IN ('Male', 'M', 'male') THEN 'male'
			WHEN gender IN ('Female', 'F', 'female') THEN 'female'
			WHEN gender IN ('Non-Binary', 'non-binary') THEN 'non-binary'
			ELSE gender
		END);

SELECT
	DISTINCT(gender)
FROM marketing_data_copy;
COMMIT;

-- now for email addresses:
UPDATE marketing_data_copy mdc
SET email_address = TRIM(email_address);

SELECT
	email_address
FROM marketing_data_copy 
WHERE email_address !~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$';

BEGIN;
UPDATE marketing_data_copy 
SET email_address = (
	CASE
		WHEN email_address !~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$' THEN NULL 
		ELSE email_address
	END
	);

SELECT
	email_address
FROM marketing_data_copy 
WHERE email_address !~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$';


-- now for the region:
SELECT
	DISTINCT(region)
FROM marketing_data_copy;

BEGIN;
UPDATE marketing_data_copy
SET region = TRIM(region);

COMMIT;


-- fixing categories:
WITH region_fix AS (
	SELECT
	CASE
		WHEN region IN ('North America', 'north america') THEN 'NA'
		WHEN region IN ('Latin America', 'latin america') THEN 'LATAM'
		WHEN region IN ('Middle East','middle east') THEN 'ME'
		WHEN region IN ('Europe','europe') THEN 'EU'
		WHEN region IN ('Asia-Pacific','asia-pacific') THEN 'APAC'
		ELSE region
	END AS regions
	
FROM marketing_data_copy)

SELECT
	DISTINCT(regions)
FROM region_fix;

BEGIN;
UPDATE marketing_data_copy 
SET region = (
	CASE
		WHEN region IN ('North America', 'north america') THEN 'NA'
		WHEN region IN ('Latin America', 'latin america') THEN 'LATAM'
		WHEN region IN ('Middle East','middle east') THEN 'ME'
		WHEN region IN ('Europe','europe') THEN 'EU'
		WHEN region IN ('Asia-Pacific','asia-pacific') THEN 'APAC'
		ELSE region
	END
	);

SELECT 
	DISTINCT(region)
FROM marketing_data_copy;
COMMIT;


-- Now for the campaign_channel:
SELECT
	campaign_channel
	,COUNT(campaign_channel)
FROM marketing_data_copy
GROUP BY campaign_channel;

UPDATE marketing_data_copy 
SET campaign_channel = TRIM(campaign_channel);

WITH campaign_category AS (
SELECT 
	CASE
		WHEN campaign_channel IN ('PaidSearch' , 'paid search') THEN 'Paid Search'
		WHEN campaign_channel IN ('display ads' , 'Display_Ads' ) THEN 'Display Ads'
		WHEN campaign_channel IN ('Affilate' , 'affiliate' ) THEN 'Affiliate'
		WHEN campaign_channel IN ('Socal Media' , 'social media' ) THEN 'Social Media'
		WHEN campaign_channel IN ('Emial Marketing' , 'email marketing' ) THEN 'Email Marketing'
		WHEN campaign_channel IN ('S.E.O.' , 'seo' ) THEN 'SEO'
		ELSE campaign_channel
	END AS campaign_c
FROM marketing_data_copy)

SELECT
	campaign_c
	,COUNT(campaign_c)
FROM campaign_category
GROUP BY campaign_c;

BEGIN;
UPDATE marketing_data_copy
SET campaign_channel = (
	CASE
		WHEN campaign_channel IN ('PaidSearch' , 'paid search') THEN 'Paid Search'
		WHEN campaign_channel IN ('display ads' , 'Display_Ads' ) THEN 'Display Ads'
		WHEN campaign_channel IN ('Affilate' , 'affiliate' ) THEN 'Affiliate'
		WHEN campaign_channel IN ('Socal Media' , 'social media' ) THEN 'Social Media'
		WHEN campaign_channel IN ('Emial Marketing' , 'email marketing' ) THEN 'Email Marketing'
		WHEN campaign_channel IN ('S.E.O.' , 'seo' ) THEN 'SEO'
		ELSE campaign_channel
	END
	);

SELECT
	DISTINCT(campaign_channel)
FROM marketing_data_copy;
COMMIT;


-- now for campaign_status:
SELECT
	DISTINCT(campaign_status)
FROM marketing_data_copy;

UPDATE marketing_data_copy 
SET campaign_status = TRIM(campaign_status);

WITH campaign_status_fix AS (
	SELECT
		CASE
			WHEN campaign_status IN ('ACTIVE' , 'active') THEN 'Active'
			WHEN campaign_status IN ('PAUSED') THEN 'Paused'
			WHEN campaign_status IN ('cancelled' , 'CANCELLED') THEN 'Cancelled'
			WHEN campaign_status IN ('paused' , 'Pawsed') THEN 'Paused'
			WHEN campaign_status IN ('COMPLETED' , 'completed') THEN 'Completed'
			ELSE campaign_status
		END AS campaign_s
	FROM marketing_data_copy) 

SELECT
	DISTINCT(campaign_s)
FROM campaign_status_fix;

BEGIN;
UPDATE marketing_data_copy 
SET campaign_status = (
	CASE
		WHEN campaign_status IN ('ACTIVE' , 'active') THEN 'Active'
		WHEN campaign_status IN ('PAUSED') THEN 'Paused'
		WHEN campaign_status IN ('cancelled' , 'CANCELLED') THEN 'Cancelled'
		WHEN campaign_status IN ('paused' , 'Pawsed') THEN 'Paused'
		WHEN campaign_status IN ('COMPLETED' , 'completed') THEN 'Completed'
		ELSE campaign_status
	END
);

SELECT
	DISTINCT(campaign_status)
FROM marketing_data_copy;
COMMIT;


-- Now for the ad_spend_usd:
SELECT
	column_name
	,data_type
FROM information_schema.columns
WHERE
	column_name = 'ad_spend_usd';

UPDATE marketing_data_copy
SET ad_spend_usd = TRIM(ad_spend_usd);

SELECT
	ad_spend_usd 
FROM marketing_data_copy
WHERE 
	ad_spend_usd IS NOT NULL
	AND ad_spend_usd != ''
ORDER BY ad_spend_usd;

SELECT
	ad_spend_usd 
FROM marketing_data_copy
WHERE 
	ad_spend_usd IS NOT NULL
	AND ad_spend_usd != ''
ORDER BY ad_spend_usd;

SELECT
	ad_spend_usd 
FROM marketing_data_copy
WHERE 
	ad_spend_usd !~* '^[0-9]*$'

ORDER BY ad_spend_usd;

-- There are negative numbers and there are numbers with $ in the beginning. Let's remove the dollar sign:
SELECT 
	SUBSTRING(ad_spend_usd FROM 2)
FROM marketing_data_copy 
WHERE ad_spend_usd LIKE '$%';

BEGIN;
UPDATE marketing_data_copy 
SET ad_spend_usd = SUBSTRING(ad_spend_usd FROM 2)
WHERE ad_spend_usd LIKE '$%';

SELECT
	ad_spend_usd 
FROM marketing_data_copy
WHERE ad_spend_usd LIKE '$%';

-- addressing values with commas in them:
UPDATE marketing_data_copy 
SET ad_spend_usd = REPLACE(ad_spend_usd, ',', '')
WHERE ad_spend_usd LIKE '%,%';

-- addressing nulls:
UPDATE marketing_data_copy 
SET ad_spend_usd = NULL
WHERE ad_spend_usd = '';

-- change data type:
ALTER TABLE marketing_data_copy 
ALTER COLUMN ad_spend_usd TYPE decimal
USING ad_spend_usd::decimal;

-- checking if data type change is successful:
SELECT
	column_name
	,data_type
FROM information_schema.columns
WHERE
	column_name = 'ad_spend_usd';

-- checking for range constraints:
SELECT
	MIN(ad_spend_usd)
	,MAX(ad_spend_usd)
FROM marketing_data_copy;

-- turning negative values to absolute value:
BEGIN;
UPDATE marketing_data_copy 
SET ad_spend_usd = abs(ad_spend_usd);

SELECT
	MIN(ad_spend_usd)
	,MAX(ad_spend_usd)
	,AVG(ad_spend_usd)
	,STDDEV(ad_spend_usd)
FROM marketing_data_copy;
COMMIT;

/* for impressions, clicks, and conversions, we'll need to crossfield validation 
 * after checking each column. 
 */


-- for impressions:
SELECT
	column_name
	,data_type
FROM information_schema.columns
WHERE
	column_name = 'impressions';


SELECT
	MIN(impressions)
	,MAX(impressions)
	,AVG(impressions)
	,STDDEV(impressions)
FROM marketing_data_copy;


-- for clicks:
SELECT
	column_name
	,data_type
FROM information_schema.columns
WHERE
	column_name = 'clicks';


SELECT
	MIN(clicks)
	,MAX(clicks)
	,AVG(clicks)
	,STDDEV(clicks)
FROM marketing_data_copy;

-- for coversions:
SELECT
	column_name
	,data_type
FROM information_schema.columns
WHERE
	column_name = 'conversions';


SELECT
	MIN(conversions)
	,MAX(conversions)
	,AVG(conversions)
	,STDDEV(conversions)
FROM marketing_data_copy;



/* For the crossfield validation, we need to ensure that funnel logic is intact.
 * This means that ideally: impressions > clicks > conversions.
 */

SELECT
	unique_id
	,clicks
	,impressions
	,conversions
FROM marketing_data_copy
WHERE 
	impressions < clicks
ORDER BY unique_id;

SELECT
	unique_id
	,clicks
	,impressions
	,conversions
FROM marketing_data_copy
WHERE 
	clicks < conversions
ORDER BY unique_id;

SELECT
	unique_id
	,clicks
	,impressions
	,conversions
FROM marketing_data_copy
WHERE 
	impressions < conversions
ORDER BY unique_id;

-- deleting the values from our table:
BEGIN;
DELETE FROM marketing_data_copy 
	WHERE 
	impressions < clicks
	OR clicks < conversions;


SELECT
	unique_id
	,clicks
	,impressions
	,conversions
FROM marketing_data_copy
WHERE 
	impressions > clicks
ORDER BY unique_id; 
COMMIT;


-- Now for revenue_usd:
SELECT
	column_name
	,data_type 
FROM information_schema.columns
WHERE column_name = 'revenue_usd';

SELECT
	MIN(revenue_usd)
	,MAX(revenue_usd)
	,AVG(revenue_usd)
	,STDDEV(revenue_usd)
FROM marketing_data_copy;


-- crossfield validation: conversions == 0 but revenue > 0
SELECT
	unique_id
	,conversions
	,revenue_usd
FROM marketing_data_copy 
WHERE 
	conversions = 0
	AND revenue_usd > 0;

-- deleting entries that doesn't meet the conditions above:
BEGIN;
DELETE FROM marketing_data_copy 
WHERE 
	conversions = 0
	AND revenue_usd > 0;

SELECT
	unique_id
	,conversions
	,revenue_usd
FROM marketing_data_copy 
WHERE 
	conversions = 0
	AND revenue_usd > 0;

SELECT
	unique_id
	,conversions
	,revenue_usd
FROM marketing_data_copy 
WHERE 
	conversions != 0;
COMMIT;

-- now that the data has been cleaned we can start the analysis.