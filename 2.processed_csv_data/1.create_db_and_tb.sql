# Load raw data
CREATE DATABASE raw_sales_data;

CREATE TABLE raw_sales_data.raw_glanceviews (
  activity_day DATE,
  product_id INT,
  glance_views INT
);

LOAD DATA LOCAL INFILE 'glanceviews.csv'
INTO TABLE raw_sales_data.raw_glanceviews
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' 
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(activity_day, product_id, glance_views);

CREATE TABLE raw_sales_data.raw_sales_rank (
    timestamp DATETIME,
    sales_rank INT,
    asin VARCHAR(20),
    category VARCHAR(100),
    region VARCHAR(100),
    pages INT,
    stockmessage VARCHAR(100),
    avg_review_score DOUBLE,
    no_reviews INT
);

LOAD DATA LOCAL INFILE 'salesrank.csv'
INTO TABLE raw_sales_data.raw_sales_rank
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' 
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(timestamp, sales_rank, asin, category, region, pages, stockmessage, avg_review_score, no_reviews);


CREATE TABLE raw_sales_data.raw_sales (
    activity_day DATE,
    product_id INT,
    ordered_units INT
);

LOAD DATA LOCAL INFILE 'sales.csv'
INTO TABLE raw_sales_data.raw_sales
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' 
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(activity_day, product_id, ordered_units);


CREATE TABLE raw_sales_data.raw_metadata (
    product_id INT,
    isbn VARCHAR(20),
    product_title VARCHAR(300),
    author_name VARCHAR(100),
    price DOUBLE,
    format VARCHAR(100),
    division VARCHAR(100),
    imprint VARCHAR(100)
);

LOAD DATA LOCAL INFILE 'metadata.csv'
INTO TABLE raw_sales_data.raw_metadata
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' 
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(product_id, isbn, product_title, author_name, price, format, division, imprint);


CREATE TABLE raw_sales_data.raw_price_changes (
    product_id INT,
    change_date DATE,
    price_from DOUBLE,
    price_to DOUBLE
);

LOAD DATA LOCAL INFILE 'pricechanges.csv'
INTO TABLE raw_sales_data.raw_price_changes
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' 
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(product_id, change_date, price_from, price_to);

CREATE TABLE raw_sales_data.raw_asinlookup (
    product_id INT,
    asin VARCHAR(20)
);

LOAD DATA LOCAL INFILE 'asinlookup.csv'
INTO TABLE raw_sales_data.raw_asinlookup
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' 
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(product_id, asin);

# Staging data
CREATE DATABASE stg_sales_data;

CREATE TABLE stg_sales_data.stg_glanceviews (
  activity_day DATE,
  product_id INT,
  glance_views INT
);

LOAD DATA LOCAL INFILE 'glanceviews.csv'
INTO TABLE stg_sales_data.stg_glanceviews
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' 
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(activity_day, product_id, glance_views);

CREATE TABLE stg_sales_data.stg_sales_rank (
	timestamp DATETIME,
    sales_rank INT,
    asin VARCHAR(20),
    category VARCHAR(100),
    region VARCHAR(100),
    pages INT,
    stockmessage VARCHAR(100),
    avg_review_score DOUBLE,
    no_reviews INT
);

LOAD DATA LOCAL INFILE 'salesrank.csv'
INTO TABLE stg_sales_data.stg_sales_rank
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' 
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(timestamp, sales_rank, asin, category, region, pages, stockmessage, avg_review_score, no_reviews);


CREATE TABLE stg_sales_data.stg_sales (
    activity_day DATE,
    product_id INT,
    ordered_units INT
);

LOAD DATA LOCAL INFILE 'sales.csv'
INTO TABLE stg_sales_data.stg_sales
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' 
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(activity_day, product_id, ordered_units);


CREATE TABLE stg_sales_data.stg_metadata (
    product_id INT,
    isbn VARCHAR(20),
    product_title VARCHAR(300),
    author_name VARCHAR(100),
    price DOUBLE,
    format VARCHAR(100),
    division VARCHAR(100),
    imprint VARCHAR(100)
);

LOAD DATA LOCAL INFILE 'metadata.csv'
INTO TABLE stg_sales_data.stg_metadata
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' 
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(product_id, isbn, product_title, author_name, price, format, division, imprint);


CREATE TABLE stg_sales_data.stg_price_changes (
    product_id INT,
    change_date DATE,
    price_from DOUBLE,
    price_to DOUBLE
);

LOAD DATA LOCAL INFILE 'pricechanges.csv'
INTO TABLE stg_sales_data.stg_price_changes
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' 
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(product_id, change_date, price_from, price_to);

CREATE TABLE stg_sales_data.stg_asinlookup (
    product_id INT,
    asin VARCHAR(20)
);

LOAD DATA LOCAL INFILE 'asinlookup.csv'
INTO TABLE stg_sales_data.stg_asinlookup
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' 
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(product_id, asin);



-- SEPRATE DATABASE FOR QUESTION 5(SQL ANSWERS SCRIPT):
CREATE DATABASE sales_data;

CREATE TABLE sales_data.stg_sales_rank (
	timestamp DATETIME,
    sales_rank INT,
    asin VARCHAR(20),
    category VARCHAR(100),
    region VARCHAR(100),
    pages INT,
    stockmessage VARCHAR(100),
    avg_review_score DOUBLE,
    no_reviews INT
);

LOAD DATA LOCAL INFILE 'salesrank.csv'
INTO TABLE sales_data.stg_sales_rank
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' 
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(timestamp, sales_rank, asin, category, region, pages, stockmessage, avg_review_score, no_reviews);

