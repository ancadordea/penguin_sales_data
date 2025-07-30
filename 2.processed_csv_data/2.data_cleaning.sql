# Data cleaning

# Standardise column names
ALTER TABLE stg_sales_data.stg_sales_rank
CHANGE COLUMN stockmessage stock_message VARCHAR(100);

# 1. Duplicates 

SELECT product_id, COUNT(*) AS count
FROM stg_sales_data.stg_asinlookup
GROUP BY product_id
HAVING COUNT(*) > 1;

SELECT product_id, COUNT(*) AS count
FROM stg_sales_data.stg_metadata
GROUP BY product_id
HAVING COUNT(*) > 1;

SELECT product_id, COUNT(*) AS count
FROM stg_sales_data.stg_price_change
GROUP BY product_id
HAVING COUNT(*) > 1;

# => asinlookup, metadata, pricechange -- no duplicates

SELECT *
FROM stg_sales_data.stg_glanceviews
ORDER BY activity_day, product_id; 

SELECT
	activity_day,
    product_id,
    COUNT(*) as ct
FROM stg_sales_data.stg_glanceviews
GROUP BY activity_day, product_id
HAVING COUNT(*) > 1 ;  # no duplicates

# sales table
SELECT *
FROM stg_sales_data.stg_sales
ORDER BY activity_day, product_id;

SELECT 
	activity_day,
    product_id,
    COUNT(*) as ct
FROM stg_sales_data.stg_sales
GROUP BY activity_day, product_id
HAVING COUNT(*) > 1; # no duplicates

# sales_rank table
SELECT *
FROM stg_sales_data.stg_sales_rank
ORDER BY timestamp, asin;

SELECT *
FROM (
	SELECT *,
    ROW_NUMBER() OVER (PARTITION BY 
    `timestamp`, 
    sales_rank, 
    asin, 
    category,
    region,
    pages,
    stock_message,
    avg_review_score,
    no_reviews
    ORDER BY `timestamp`
    ) AS row_num
    FROM stg_sales_data.stg_sales_rank ) AS t
    WHERE row_num > 1
	ORDER BY `timestamp`, asin;

# Removing the duplicates
ALTER TABLE stg_sales_data.stg_sales_rank ADD COLUMN row_id INT AUTO_INCREMENT PRIMARY KEY;

DELETE FROM stg_sales_data.stg_sales_rank
WHERE row_id IN (
	SELECT row_id FROM (
		SELECT row_id,
			ROW_NUMBER() OVER (
				PARTITION BY `timestamp`, sales_rank, asin, category, region, pages, stock_message, avg_review_score, no_reviews
                ORDER BY `timestamp`
			) AS row_num
		FROM stg_sales_data.stg_sales_rank
	) AS ranked
    WHERE row_num > 1
    );
    
# SET SQL_SAFE_UPDATES = 0; -- to disable Safe Update Mode 

ALTER TABLE stg_sales_data.stg_sales_rank DROP COLUMN row_id;

# 2. Standardise data 

# sales_rank in stock -- get rid of in stock.

UPDATE stg_sales_data.stg_sales_rank 
SET stock_message = TRIM(TRAILING '.' FROM TRIM(stock_message));

SELECT *
FROM stg_sales_data.stg_sales_rank;

# region column from sales_rank
SELECT DISTINCT region
FROM stg_sales_data.stg_sales_rank; -- only UK -- redudant to have column for it

ALTER TABLE stg_sales_data.stg_sales_rank
DROP COLUMN region;

# Check nulls/populate with data where nulls

SELECT *
FROM stg_sales_data.stg_sales_rank
WHERE
	`timestamp` IS NULL OR 
    sales_rank IS NULL OR sales_rank = '' OR
    asin IS NULL OR asin = '' OR
    category IS NULL OR category = '' OR
    pages IS NULL OR pages = '' OR
    stock_message IS NULL OR stock_message = '' OR
    avg_review_score IS NULL OR avg_review_score = '' OR
    no_reviews IS NULL OR no_reviews = '';
    
# try populate missing category and page rows:

# for category column:
-- checked asin in the asinlookup table -- identified product id and match it with metadata entry
	-- 1st missing row book: economics of human birthdays 

# check back into sales_rank to check if there is another enry with the same asin 
SELECT DISTINCT category, asin
FROM stg_sales_data.stg_sales_rank
ORDER BY asin; 
	-- for first missing book category:  fiction => so will label this as fiction 
		-- for 2nd: society of death -- another enry of same asin in sales_rank is biographies & memoirs => will populate the category for the missing value as a biography
    
# However, since this is randomised -- these books don't exist (googled and couldn't find authors or book titles) => could not look up the page number
-- => will drop these rows 

DELETE FROM stg_sales_data.stg_sales_rank
WHERE category IS NULL OR category = '';

# case when in stock = blank -- then populate as "unknown"

UPDATE stg_sales_data.stg_sales_rank
SET stock_message = 'Unknown'
WHERE stock_message IS NULL OR stock_message = '';

# standardise categories
SELECT DISTINCT category
FROM stg_sales_data.stg_sales_rank;

UPDATE stg_sales_data.stg_sales_rank
SET category = REPLACE(category, ' (Books)', '')
WHERE category LIKE '%(Books)%';

UPDATE stg_sales_data.stg_sales_rank
SET category = REPLACE(category, '&', 'and')
WHERE category LIKE '%&%';

UPDATE stg_sales_data.stg_sales_rank
SET category = CASE
  WHEN category IN (
    'Emotional Self Help',
    'Self Help Stress Management',
    'Practical and Motivational Self Help',
    'Stress',
    'Applied Psychotherapy',
    'Popular Psychology',
    'Psychology and Mental Health',
    'Art Relaxation and Therapy'
  ) THEN 'Self Help/Psychology'

  WHEN category IN (
    'Medicine and Nursing',
    'Medical Sciences A-Z',
    'General Medical Issues Guides',
    'Higher Education of Biological Sciences'
  ) THEN 'Medical/Science'

  WHEN category IN (
    'Biographies and Memoirs',
    'Women''s Biographies'
  ) THEN 'Biographies'

  WHEN category IN (
    'Fiction',
    'Literary Fiction',
    'Romance'
  ) THEN 'Fiction'

  WHEN category IN (
    'Healthy Eating',
    'Italian Food and Drink',
    'Festive and Seasonal Dishes',
    'Quick and Easy Meals',
    'Weight Control Nutrition',
    'Barbecues',
    'Spirits and Cocktails'
  ) THEN 'Food and Drink'

  WHEN category IN (
    'Families and Parents',
    'Home and Garden'
  ) THEN 'Lifestyle/Family'

  WHEN category IN ('Tarot') THEN 'Tarot'
  
END;

SELECT asin, COUNT(asin)
FROM stg_sales_data.stg_sales_rank
GROUP BY asin;

# merge asinlookup with metadata

SELECT m.product_id, isbn, product_title, author_name, price, format, division, imprint, asin
FROM stg_sales_data.stg_metadata AS m
JOIN stg_sales_data.stg_asinlookup AS a
	ON m.product_id = a.product_id
;


