-- SECTION 1 — DATA VALIDATION & CLEANING (SQL) 
use amazon;
-- Step 1 — Check Row Count
SELECT COUNT(*) AS total_rows
FROM amazon_sales;

-- Step 2 — Check for Null Values
SELECT 
    SUM(CASE WHEN Category IS NULL THEN 1 ELSE 0 END) AS null_category,
    SUM(CASE WHEN Date IS NULL THEN 1 ELSE 0 END) AS null_date,
    SUM(CASE WHEN Qty IS NULL THEN 1 ELSE 0 END) AS null_qty,
    SUM(CASE WHEN Amount IS NULL THEN 1 ELSE 0 END) AS null_amount
FROM amazon_sales;



-- Step 3 - Understanding column unnamed : 22
DESCRIBE amazon_sales;

-- Step 4 - check distinct values
SELECT DISTINCT `Unnamed: 22`
FROM amazon_sales;

-- Step 5 - Count non null values
SELECT COUNT(*) 
FROM amazon_sales
WHERE `Unnamed: 22` IS NOT NULL;

-- Step 6 - Removing unnamed : 22 Column
ALTER TABLE amazon_sales
DROP COLUMN `Unnamed: 22`;

-- Step 7 — Check Negative or Zero Amount
SELECT count(*) negative_or_zero_amount
FROM amazon_sales
WHERE Amount <= 0;

-- 7.1 Calculating percentage of these rows in our dataset
SELECT 
    (2343 / 128975) * 100 AS percentage; 
    -- These negative or zero amount rows cover 1.81% of our dataset
    
-- 7.2 Investigating why these negative or zero amount rows exist
SELECT Status, COUNT(*) AS count_rows
FROM amazon_sales
WHERE Amount <= 0
GROUP BY Status;

-- Investigation of Zero / Negative Amount Rows
-- Found 2,343 rows (~1.8% of dataset) where Amount <= 0.
-- These rows are not limited to cancelled orders.
-- Many are marked as 'Shipped' or 'Delivered to Buyer',
-- suggesting refunds, reconciliation adjustments,
-- return processing entries, or zero-value transactions.
--
-- Decision:
-- We will NOT delete these rows.
-- Instead, we will filter using:
--   Status LIKE 'Shipped%' AND Amount > 0
-- when calculating revenue metrics.
--
-- This preserves raw data integrity while ensuring
-- accurate revenue calculations.

-- Section 2 - Core Revenue Metrics

-- Step 1 — Clean Revenue Base
SELECT 
    COUNT(*) AS valid_sales_rows
FROM amazon_sales
WHERE Status LIKE 'Shipped%' 
AND Amount > 0;

-- Revenue Base Definition
-- Out of 128,975 total rows, 107,160 rows qualify as valid sales.
-- Valid sales are defined as:
--   Status LIKE 'Shipped%' (fulfilled orders)
--   AND Amount > 0 (actual revenue-generating transactions)

SELECT 
    ROUND(107160 / 128975 * 100, 2) AS valid_sales_percentage;
    
-- Approximately 83% of the dataset represents valid revenue entries.
-- The remaining ~17% consists of returns, adjustments, pending orders,
-- and non-revenue operational records.
--
-- All revenue KPIs will be calculated using this filtered base.	

-- Step 2 — Total Net Revenue
SELECT 
    ROUND(SUM(Amount), 2) AS total_revenue
FROM amazon_sales
WHERE Status LIKE 'Shipped%' 
AND Amount > 0;



    
    