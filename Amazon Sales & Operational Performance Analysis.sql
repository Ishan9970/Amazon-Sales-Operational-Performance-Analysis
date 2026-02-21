-- Section 1 — DATA VALIDATION & CLEANING (SQL) 
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

-- Section 2 - CORE REVENUE METRICS

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

-- Total Net Revenue Calculation
-- Using only fulfilled and positive-value transactions,
-- the business generated 71,050,985 in total revenue.
--
-- This represents actual realized revenue,
-- excluding returns, pending orders, and adjustments.



-- Step 3 — Total Unique Orders
SELECT 
    COUNT(DISTINCT `Order ID`) AS total_orders
FROM amazon_sales
WHERE Status LIKE 'Shipped%'
AND Amount > 0;

-- Unique Orders Analysis
-- The dataset contains 99,907 distinct fulfilled orders.
--
-- With total revenue of 71,050,985,
-- this allows us to compute Average Order Value (AOV),
-- a critical ecommerce KPI measuring revenue per transaction.
--
-- AOV helps evaluate:
-- - Customer purchasing behavior
-- - Basket size strength
-- - Pricing strategy effectiveness

-- Step 4 — Average Order Value (AOV)

SELECT 
    ROUND(SUM(Amount) / COUNT(DISTINCT `Order ID`), 2) AS avg_order_value
FROM amazon_sales
WHERE Status LIKE 'Shipped%'
AND Amount > 0;

-- AOV = Total Revenue / Total Unique Orders
--
-- The business has an Average Order Value of 711.17.
--
-- This indicates that on average,
-- each completed order generates 711.17 in revenue.


-- Step 5 - Total Units Sold
SELECT 
    SUM(Qty) AS total_units_sold
FROM amazon_sales
WHERE Status LIKE 'Shipped%'
AND Amount > 0;

-- Total Units Sold
-- The business sold 107,569 units across 99,907 completed orders.
--
-- This indicates that most transactions consist of single-item purchases,
-- with limited multi-unit basket expansion.
--
-- This insight will be confirmed by calculating
-- average units per order next.

-- Step 6 — Average Units per Order

SELECT 
    ROUND(SUM(Qty) / COUNT(DISTINCT `Order ID`), 2) AS avg_units_per_order
FROM amazon_sales
WHERE Status LIKE 'Shipped%'
AND Amount > 0;

-- Average Units per Order Calculation
-- Average Units per Order = Total Units Sold / Total Orders
--
-- The result is 1.08 units per order.
--
-- This indicates that most customers purchase a single item per transaction,
-- with minimal multi-item bundling.
--
-- This suggests an opportunity to increase basket size
-- through cross-selling or bundling strategies.


-- Section 3 - CATEGORY ANALYSIS 

-- Step 1 - Category Segmentation

SELECT 
    Category,
    COUNT(DISTINCT `Order ID`) AS Orders,
    SUM(Qty) AS Units_Sold,
    ROUND(SUM(Amount), 2) AS Revenue
FROM amazon_sales
WHERE Status LIKE 'Shipped%'
AND Amount > 0
GROUP BY Category
ORDER BY Revenue DESC;

-- Category-Level Revenue Analysis
-- Revenue is heavily concentrated in the top three categories:
-- Set, Kurta, and Western Dress.
--
-- Set category alone generates 35.4M revenue,
-- representing the dominant revenue driver.
--
-- Kurta contributes 19.3M,
-- followed by Western Dress at 10.08M.
--
-- Lower-tier categories such as Saree, Bottom, and Dupatta
-- contribute minimal revenue, indicating limited demand
-- or narrow product assortment.
--
-- The business appears to be strongly concentrated
-- around ethnic and semi-ethnic apparel segments.


-- Step 2 - Category Profitability Strength

SELECT 
    Category,
    ROUND(SUM(Amount) / COUNT(DISTINCT `Order ID`), 2) AS avg_order_value
FROM amazon_sales
WHERE Status LIKE 'Shipped%'
AND Amount > 0
GROUP BY Category
ORDER BY avg_order_value DESC;

-- Category-Level Average Order Value Analysis
-- Saree has the highest AOV (940.11), followed by Set (898.07)
-- and Western Dress (804.86).
--
-- Although Set generates the highest total revenue,
-- Saree represents the most premium category in terms of
-- revenue per transaction.
--
-- Kurta, despite being the second-largest revenue contributor,
-- has a moderate AOV (500.11), indicating it is volume-driven
-- rather than premium-priced.
--
-- Lower-tier categories such as Bottom and Dupatta
-- operate in lower price brackets.


-- Step 3 - Category Revenue Share %

SELECT 
    Category,
    ROUND(SUM(Amount) / 71050985 * 100, 2) AS revenue_share_pct
FROM amazon_sales
WHERE Status LIKE 'Shipped%'
AND Amount > 0
GROUP BY Category
ORDER BY revenue_share_pct DESC;

-- Category Revenue Share Analysis
-- The Set category alone contributes 49.87% of total revenue.
-- Kurta contributes 27.13%, and Western Dress 14.19%.
--
-- The top 3 categories together account for over 91% of total revenue.
--
-- Remaining categories collectively contribute less than 9%,
-- indicating extreme revenue concentration.
--
-- This suggests high strategic dependency on a narrow product portfolio.


-- Section 4 - TIME-BASED ANALYSIS
    
    SELECT 
    DATE_FORMAT(Date, '%Y-%m') AS YearMonth,
    ROUND(SUM(Amount), 2) AS monthly_revenue
FROM amazon_sales
WHERE Status LIKE 'Shipped%'
AND Amount > 0
GROUP BY YearMonth
ORDER BY YearMonth;

-- Monthly Revenue Trend Analysis
-- Revenue peaks in April (26.23M),
-- followed by gradual decline in May (23.95M)
-- and June (20.77M).
--
-- March revenue (94,810) appears significantly lower,
-- likely due to incomplete data for that month.
--
-- This suggests a strong seasonal spike in early Q2,
-- followed by moderate normalization.

-- Date Time Range Validation
    SELECT 
    MIN(Date) AS earliest_date,
    MAX(Date) AS latest_date
FROM amazon_sales;

-- Data Time Range Validation
-- The dataset spans from 2022-03-31 to 2022-06-29.
--
-- This means:
-- - March data is incomplete (only one day)
-- - April and May represent full months
-- - June is nearly complete
--
-- Therefore, revenue comparisons should focus primarily
-- on April, May, and June.
--
-- March revenue should not be used for trend analysis.


SELECT 
    DATE_FORMAT(Date, '%Y-%m') AS YearMonth,
    Category,
    ROUND(SUM(Amount), 2) AS monthly_category_revenue
FROM amazon_sales
WHERE Status LIKE 'Shipped%'
AND Amount > 0
GROUP BY YearMonth, Category
ORDER BY YearMonth, monthly_category_revenue DESC;

-- Monthly Category Revenue Analysis
-- Revenue peaked in April across major categories.
-- From April to June, revenue shows consistent decline
-- in Set, Kurta, and Western Dress categories.
--
-- Set category dropped from 14.12M (April)
-- to 9.73M (June).
--
-- Kurta declined from 7.24M (April)
-- to 5.88M (June).
--
-- Western Dress fluctuated but remained below April peak.
--
-- The overall business revenue decline from April to June
-- is primarily driven by weakening performance in Set and Kurta,
-- which together contribute ~77% of total revenue.


-- Is the decline due to:
-- Lower Order Volume or
-- Lower Average Selling Price ?

SELECT 
    DATE_FORMAT(Date, '%Y-%m') AS YearMonth,
    Category,
    ROUND(SUM(Amount) / SUM(Qty), 2) AS avg_selling_price
FROM amazon_sales
WHERE Status LIKE 'Shipped%'
AND Amount > 0
GROUP BY YearMonth, Category
ORDER BY YearMonth, Category;

-- Average Selling Price (ASP) by Category and Month
-- Revenue decline from April to June is NOT driven by price reduction.
-- In most major categories, average selling price either increased
-- or remained stable across months.
--
-- Therefore, revenue contraction is primarily volume-driven,
-- not price-driven.


SELECT 
    DATE_FORMAT(Date, '%Y-%m') AS YearMonth,
    Category,
    SUM(Qty) AS monthly_units
FROM amazon_sales
WHERE Status LIKE 'Shipped%'
AND Amount > 0
GROUP BY YearMonth, Category
ORDER BY YearMonth, Category;

-- Monthly Units Sold by Category
-- Revenue decline from April to June is confirmed to be volume-driven.
--
-- Set units declined from:
-- 16,847 (April) → 13,377 (May) → 11,324 (June)
--
-- Kurta units declined from:
-- 16,451 (April) → 12,636 (May) → 12,385 (June)
--
-- Since average selling prices remained stable or increased,
-- the revenue contraction is caused by reduced sales volume.


-- Section 5 - CUSTOMER SEGMENTATION


SELECT 
    DATE_FORMAT(Date, '%Y-%m') AS YearMonth,
    COUNT(DISTINCT `Order ID`) AS monthly_orders
FROM amazon_sales
WHERE Status LIKE 'Shipped%'
AND Amount > 0
GROUP BY YearMonth
ORDER BY YearMonth;


-- Monthly Order Trend Analysis
-- Order volume declined consistently after April:
-- April: 38,246 orders
-- May:   32,942 orders
-- June:  28,579 orders
--
-- This confirms that the revenue decline observed
-- from April to June is driven by a reduction in order volume,
-- not pricing changes.
--
-- Customer purchasing activity weakened after April peak.


-- SECTION 5 — GEOGRAPHIC PERFORMANCE ANALYSIS
SELECT 
    `ship-state`,
    ROUND(SUM(Amount), 2) AS Revenue,
    COUNT(DISTINCT `Order ID`) AS Orders
FROM amazon_sales
WHERE Status LIKE 'Shipped%'
AND Amount > 0
GROUP BY `ship-state`
ORDER BY Revenue DESC
LIMIT 10;


-- State-Level Revenue Analysis
-- Revenue is concentrated in a few major states.
--
-- Maharashtra leads with 12.12M revenue across 17,426 orders.
-- Karnataka follows with 9.56M revenue.
-- Telangana, Uttar Pradesh, and Tamil Nadu
-- form the next revenue tier.
--
-- The top 5 states contribute a significant portion
-- of total business revenue.


SELECT 
    `ship-state`,
    ROUND(SUM(Amount) / COUNT(DISTINCT `Order ID`), 2) AS avg_order_value
FROM amazon_sales
WHERE Status LIKE 'Shipped%'
AND Amount > 0
GROUP BY `ship-state`
ORDER BY avg_order_value DESC
LIMIT 10;

-- State-Level Average Order Value (AOV) Analysis
-- Smaller states such as Ladakh and Nagaland show
-- higher Average Order Value.
--
-- However, these states do not contribute high total revenue.
-- High AOV in low-volume regions may be influenced
-- by small sample size effects.
--
-- Therefore, revenue concentration is primarily driven by
-- order volume in large states rather than pricing differences.

--  SECTION 6 — B2B vs B2C Business Mix 

SELECT 
    B2B,
    COUNT(DISTINCT `Order ID`) AS Orders,
    ROUND(SUM(Amount), 2) AS Revenue,
    ROUND(SUM(Amount) / COUNT(DISTINCT `Order ID`), 2) AS AOV
FROM amazon_sales
WHERE Status LIKE 'Shipped%'
AND Amount > 0
GROUP BY B2B;

-- B2B vs B2C Revenue Analysis
-- The business is overwhelmingly B2C-driven.
--
-- B2C (False) accounts for:
-- 99,183 orders and 70.49M in revenue.
--
-- B2B (True) accounts for:
-- 724 orders and 0.56M in revenue.
--
-- B2B represents less than 1% of total revenue.
--
-- Although B2B shows slightly higher AOV (768 vs 711),
-- its contribution to total revenue is minimal.


-- SECTION 7-  FULFILMENT CHANNEL ANALYSIS 

SELECT 
    Fulfilment,
    COUNT(DISTINCT `Order ID`) AS Orders,
    ROUND(SUM(Amount), 2) AS Revenue,
    ROUND(SUM(Amount) / COUNT(DISTINCT `Order ID`), 2) AS AOV
FROM amazon_sales
WHERE Status LIKE 'Shipped%'
AND Amount > 0
GROUP BY Fulfilment;

-- Fulfilment Channel Analysis
-- Amazon-fulfilled orders account for 71,193 transactions
-- generating 50.32M in revenue.
--
-- Merchant-fulfilled orders account for 28,714 transactions
-- generating 20.73M in revenue.
--
-- Amazon fulfilment contributes approximately 71% of total revenue,
-- indicating strong reliance on platform logistics.
--
-- Merchant fulfilment shows slightly higher AOV (721.83 vs 706.87),
-- suggesting marginally higher order value when handled directly.

-- SECTION 8 — Category × Fulfilment Segmentation

SELECT 
    Category,
    Fulfilment,
    COUNT(DISTINCT `Order ID`) AS Orders,
    ROUND(SUM(Amount), 2) AS Revenue
FROM amazon_sales
WHERE Status LIKE 'Shipped%'
AND Amount > 0
GROUP BY Category, Fulfilment
ORDER BY Category, Revenue DESC;

-- Category and Fulfilment Analysis
-- Most major categories are predominantly Amazon-fulfilled.
--
-- Set category:
-- Amazon: 28,425 orders | 25.57M revenue
-- Merchant: 11,033 orders | 9.86M revenue
--
-- Kurta category:
-- Amazon: 28,222 orders | 14.07M revenue
-- Merchant: 10,322 orders | 5.20M revenue
--
-- Western Dress shows relatively balanced fulfilment distribution.
--
-- Overall, Amazon fulfilment dominates across all major categories,
-- indicating operational dependency on platform logistics.


-- Exporting Cleaned Dataset for further analysis using Python
SELECT *
FROM amazon_sales
WHERE Status LIKE 'Shipped%'
AND Amount > 0;

