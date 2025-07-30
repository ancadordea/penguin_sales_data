# SQL Questions
# The data consists of six tables:
# •	sales: sales for an online retail platform in the month of February
# •	glance_views: page views for an online retail platform in the month of February
# •	sales_rank: scraped data from an online retail platform in the month of Feburary
# •	asin_lookup: a mapping from product keys in the metadata table to online retail platform IDs used by the sales_rank data
# •	price_changes: a list of price changes made for books in the dataset in the month of February

# 1.	Select sales data for the 15th February for all titles where the division is Penguin Press
# •	The output columns should be activity_day, isbn, product_title, division, imprint, and ordered_units
SELECT activity_day, isbn, product_title, division, imprint, ordered_units
FROM stg_sales_data.stg_metadata AS m
JOIN stg_sales_data.stg_sales AS s
	ON m.product_id = s.product_id
WHERE activity_day = '2023-02-15' AND division = 'Penguin Press';

# 2.	Print the daily revenue for each product, where revenue is unit price * ordered_units
# •	The output columns should be activity_day, isbn, ordered_units, price, and revenue
SELECT activity_day, 
isbn, 
ordered_units, 
price,
(price * ordered_units) AS revenue
FROM stg_sales_data.stg_metadata AS m
JOIN stg_sales_data.stg_sales AS s
		ON m.product_id = s.product_id
;

# 3.	Select sales data for the 15th February for all titles where the division is Penguin Press, and add the sales_rank column from the sales_rank table
# •	The output columns should be activity_day, isbn, product_title, division, imprint, ordered_units, and sales_rank
SELECT activity_day, isbn, product_title, division, imprint, ordered_units, sales_rank
FROM stg_sales_data.stg_sales AS s
JOIN stg_sales_data.stg_metadata AS m
	ON m.product_id = s.product_id
JOIN stg_sales_data.stg_asinlookup AS a
	ON m.product_id = a.product_id
JOIN stg_sales_data.stg_sales_rank AS r
	ON a.asin = r.asin
WHERE activity_day = '2023-02-15' AND division = 'Penguin Press';

# 4.	Summarize each division's sales over the month of February, sorting from most to least sales
# •	The output columns should be division and total_ordered_units
SELECT division, 
SUM(ordered_units) AS total_ordered_units
FROM stg_sales_data.stg_sales AS s
JOIN stg_sales_data.stg_metadata AS m
	ON m.product_id = s.product_id
GROUP BY division
ORDER BY total_ordered_units DESC;

# 5.	List the top five most common categories appearing in the sales_rank data, along with the number of times they appear, and their mean sales rank
# •	The output columns should be category, category_count for the number of occurrences of the category, and avg_sales_rank for the mean sales rank
# •	Mean sales rank should be rounded down and cast to an integer
# •	Categories with the same rank should be ordered by ascending average sales rank

# For preprocessed data
SELECT category, 
COUNT(*) AS category_count,
FLOOR(AVG(sales_rank)) AS avg_sales_rank 
FROM stg_sales_data.stg_sales_rank
GROUP BY category
ORDER BY category_count DESC,avg_sales_rank ASC
LIMIT 5;

# For data before standardising the categories for dashboard
SELECT category, 
COUNT(*) AS category_count,
FLOOR(AVG(sales_rank)) AS avg_sales_rank 
FROM sales_data.stg_sales_rank
GROUP BY category
ORDER BY category_count DESC,avg_sales_rank ASC
LIMIT 5;

# 6.	Select the isbn, product_title and mean sales_rank for each product
# •	The output columns should be isbn, product_title and avg_sales_rank for the mean sales rank
SELECT isbn, product_title, 
FLOOR(AVG(sales_rank)) AS avg_sales_rank 
FROM stg_sales_data.stg_metadata AS m
JOIN stg_sales_data.stg_asinlookup AS a
	ON m.product_id = a.product_id
JOIN stg_sales_data.stg_sales_rank AS r
	ON a.asin = r.asin
GROUP BY isbn, product_title
ORDER BY avg_sales_rank; # for better visualisation

# 7.	For each ISBN, find the day with the greatest increase in ordered_units over the previous day
# •	The output columns should be activity_day, isbn, and the difference in ordered_units as units_diff
WITH CTE_ordered_units AS
(
SELECT activity_day,
isbn, 
ordered_units,
(ordered_units - LAG(ordered_units) OVER(PARTITION BY isbn ORDER BY activity_day)) AS units_diff
FROM stg_sales_data.stg_metadata AS m
JOIN stg_sales_data.stg_sales AS s
	ON m.product_id = s.product_id
), 
ranked AS (
SELECT *,
ROW_NUMBER() OVER (PARTITION BY isbn ORDER BY units_diff DESC) AS row_num
FROM CTE_ordered_units
)
SELECT activity_day, isbn, units_diff
FROM ranked
WHERE row_num = 1;

# 8.	For ISBN 9781364764951, compute a running total of sales over the month and the mean average sales over the previous seven days
# •	The output columns should be activity_day, isbn, product_title, ordered_units, running_total and mean_sales
SELECT activity_day, 
isbn, 
product_title, 
ordered_units, 
SUM(ordered_units) OVER (PARTITION BY isbn ORDER BY activity_day) AS running_total, 
AVG(ordered_units) OVER (PARTITION BY isbn ORDER BY activity_day ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS mean_sales
FROM stg_sales_data.stg_metadata AS m
JOIN stg_sales_data.stg_sales AS s
	ON m.product_id = s.product_id
WHERE isbn = 9781364764951
ORDER BY activity_day;

# 9.	In every instance where a title's sales rank is above the 90th percentile for that day, select the product information, sales rank, and ordered units
# •	The output columns should be activity_day, isbn, product_title, sales_rank, and ordered_units
# •	The output should be ordered by activity_day
WITH daily_90th AS (
  SELECT 
    DATE(r.timestamp) AS activity_day,
    SUBSTRING_INDEX(
      GROUP_CONCAT(r.sales_rank ORDER BY r.sales_rank), ',', 
      FLOOR(0.9 * COUNT(*))
    ) AS p90_rank_str
  FROM stg_sales_data.stg_sales_rank r
  GROUP BY DATE(r.timestamp)
),
daily_cutoff AS (
  SELECT
    activity_day,
    CAST(SUBSTRING_INDEX(p90_rank_str, ',', -1) AS UNSIGNED) AS p90_rank
  FROM daily_90th
)
SELECT
  DATE(r.timestamp) AS activity_day,
  m.isbn,
  m.product_title,
  r.sales_rank,
  s.ordered_units
FROM stg_sales_data.stg_sales_rank AS r
JOIN stg_sales_data.stg_asinlookup AS a 
	ON r.asin = a.asin
JOIN stg_sales_data.stg_sales AS s 
	ON s.product_id = a.product_id AND s.activity_day = DATE(r.timestamp)
JOIN stg_sales_data.stg_metadata AS m 
	ON m.product_id = s.product_id
JOIN daily_cutoff AS d 
	ON d.activity_day = DATE(r.timestamp)
WHERE r.sales_rank > d.p90_rank
ORDER BY activity_day;

# 10.	The price_changes table contains a listing of price changes made to each of the products in the metadata table. Calculate sales before and after the change_date in the price_changes table, showing the difference in sales, and the percentage change.
# •	The output columns should be product_id, bef_sales for sales up to and including the change_date, aft_sales for sales after the change_date, diff for the difference in sales, and pct for the percentage change between bef_sales and aft_sales
WITH sales_price_change AS 
(
SELECT
p.product_id,
change_date,
s.activity_day,
ordered_units
FROM stg_sales_data.stg_price_changes AS p
JOIN stg_sales_data.stg_sales AS s
	ON p.product_id = s.product_id
),
aggregated AS 
(
SELECT 
product_id,
change_date,
SUM(CASE WHEN activity_day <= change_date THEN ordered_units ELSE 0 END) AS bef_sales,
SUM(CASE WHEN activity_day > change_date THEN ordered_units ELSE 0 END) AS aft_sales
FROM sales_price_change
GROUP BY product_id, change_date
)
SELECT
product_id,
bef_sales,
aft_sales,
(aft_sales - bef_sales) AS diff,
ROUND(CASE WHEN bef_sales = 0 THEN NULL ELSE ((aft_sales - bef_sales) * 100) /bef_sales END, 2) AS pct
FROM aggregated;

