## Penguin Sales Project

This repository contains the code and instructions for the sales data pipeline, from raw Excel sheets to visualisations in Power BI. The process includes:

1. **Raw Data and Extract**: Convert multiple-sheet XLSX into individual CSV files using Python script
2. **Process csv data**: 
    * Import CSVs into a MySQL `raw_sales_data` database
    * Create MySQL database for raw and staging data
    * Create tables and load data (raw) and copy tables and data for staging
    * Perform data cleaning, deduplication, and standardisation in staging
3. **Export**: Export cleaned tables for modelling and visualisation in Power BI.

---

### Table of Contents

* [Prerequisites](#prerequisites)
* [Project Structure](#project-structure)
* [Step 1: Extract XLSX to CSV](#step-1-extract-xlsx-to-csv)
* [Step 2: Load CSVs into MySQL](#step-2-load-csvs-into-mysql)
* [Step 3: Stage Data](#step-3-stage-data)
* [Step 4: Data Cleaning](#step-4-data-cleaning)
* [Step 5: Export for Power BI](#step-5-export-for-power-bi)

---

## Prerequisites

* Python 3.8+
* `pandas` library
* MySQL Server with `LOCAL INFILE` enabled
* Power BI Desktop

## Project Structure

```bash
penguin_sales_data/
├── 1.raw_data/ # Original Excel workbook and raw files
├── 2.processed_csv_data/ # CSVs generated after Python extraction
├── 3.sql_cleaned_data/ # SQL scripts and cleaned SQL data outputs
├── anca_sales_dashboard_penguin.pbix # Power BI dashboard
├── sql_task_answers.sql # SQL task answers
├── sql_task_questions.docx # SQL task questions
└── README.md  
```

## Extract XLSX to CSV

1. Install dependencies:
```bash
pip install pandas openpyxl
```

2. Run the extraction script:
```bash
python3 1.raw_data/processing_to_csv.py
```

The script reads each sheet and writes a separate CSV in `2.processed_data`, e.g., `glanceviews.csv`, `sales.csv`, `sales_rank.csv`, `metadata.csv`, `asinlookup.csv`, and `price_change.csv`.

## Load CSVs into MySQL

1. Connect to MySQL with local infile support:

   ```bash
   mysql --local-infile=1 -u root -p
   ```
2. Create the raw data database and tables:

   ```bash
   CREATE DATABASE raw_sales_data;
   USE raw_sales_data;

   CREATE TABLE raw_glanceviews (
     activity_day DATE,
     product_id INT,
     glance_views INT
   );
   -- Repeat for raw_sales, raw_sales_rank, raw_metadata, raw_asinlookup, raw_price_change
   ```
3. Load each CSV into its corresponding table:

   ```bash
   LOAD DATA LOCAL INFILE 'glanceviews.csv'
   INTO TABLE raw_glanceviews
   CHARACTER SET utf8mb4
   FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
   LINES TERMINATED BY '\n'
   IGNORE 1 ROWS;
   -- Repeat for other tables
   ```

## Stage Data

1. Create the staging database and duplicate table schemas:

   ```bash
   CREATE DATABASE stg_sales_data;
   USE stg_sales_data;

   CREATE TABLE stg_glanceviews (
     activity_day DATE,
     product_id INT,
     glance_views INT
   );
   -- Repeat for other tables
   ```
2. Load staged CSVs (same as raw) into staging tables:

   ```bash
   LOAD DATA LOCAL INFILE 'glanceviews.csv'
   INTO TABLE stg_glanceviews
   CHARACTER SET utf8mb4
   FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
   LINES TERMINATED BY '\n'
   IGNORE 1 ROWS;
   ```

## Data Cleaning

Inside the `stg_sales_data` schema:

### Standardise Column Names

```sql
ALTER TABLE stg_sales_rank
  CHANGE COLUMN stockmessage stock_message VARCHAR(100);
```

### Remove Duplicates

* **Lookup tables** (`stg_asinlookup`, `stg_metadata`, `stg_price_change`): no duplicates found.
* **glanceviews** and **sales**: verify no duplicate `(activity_day, product_id)`.
* **sales\_rank**: identify and delete exact duplicate rows:

  ```sql
  ALTER TABLE stg_sales_rank ADD COLUMN row_id INT AUTO_INCREMENT PRIMARY KEY;
  DELETE FROM stg_sales_rank
  WHERE row_id IN (
    SELECT row_id FROM (
      SELECT row_id,
        ROW_NUMBER() OVER (PARTITION BY
          `timestamp`, sales_rank, asin, category,
          pages, stock_message, avg_review_score, no_reviews
        ORDER BY `timestamp`
      ) AS rn
      FROM stg_sales_rank
    ) t
    WHERE rn > 1
  );
  ALTER TABLE stg_sales_rank DROP COLUMN row_id;
  ```

### Standardise Data Values

* Trim trailing periods from `stock_message` and replace blanks with `Unknown`
* Drop redundant `region` column (only UK data)
* Delete rows with missing critical fields (e.g., category)
* Standardise category names via `UPDATE ... CASE`

## Power BI

1. Export cleaned tables to CSV:
2. In Power BI:

   * Load `sales_clean.csv`, `price_change_clean.csv`, and `metadata_lookup.csv`.
   * In the **Model** view, create relationships:
    e.g.
     * `sales.product_id` ➔ `price_change.product_id`
     * `sales.product_id` ➔ `metadata_lookup.product_id`
   * Build DAX measures (e.g., `TotalUnits = SUM(sales.ordered_units)`).
   * Create visualisations
