-- Online Retail SQL Analysis
-- Dataset: Online Retail (Kaggle), Dec 2010 - Dec 2011

USE retail_project;

-- 1. Create clean table (remove cancellations, non-product rows, zero prices)
CREATE TABLE online_retail_clean AS
SELECT
  InvoiceNo, StockCode, Description, Quantity,
  STR_TO_DATE(InvoiceDate, '%m/%d/%Y %H:%i') AS InvoiceDate,
  UnitPrice, CustomerID, Country,
  Quantity * UnitPrice AS Revenue
FROM online_retail
WHERE InvoiceNo NOT LIKE 'C%'
  AND Quantity > 0
  AND UnitPrice > 0
  AND StockCode NOT IN ('AMAZONFEE','M','POST','D','DOT','BANK CHARGES','CRUK');

-- 2. Remove outlier order (80,995 units, cancelled next minute)
DELETE FROM online_retail_clean WHERE InvoiceNo = '581483';

-- 3. Data quality counts on raw table
SELECT
  SUM(InvoiceNo LIKE 'C%') AS cancellations,
  SUM(CustomerID = '' OR CustomerID IS NULL) AS missing_customer,
  SUM(UnitPrice <= 0) AS zero_price
FROM online_retail;

-- 4. Monthly revenue
SELECT DATE_FORMAT(InvoiceDate, '%Y-%m') AS month,
       ROUND(SUM(Revenue), 2) AS monthly_revenue
FROM online_retail_clean
GROUP BY month
ORDER BY month;

-- 5. Top 10 customers
SELECT CustomerID,
       COUNT(DISTINCT InvoiceNo) AS orders,
       ROUND(SUM(Revenue), 2) AS total_spent
FROM online_retail_clean
WHERE CustomerID <> ''
GROUP BY CustomerID
ORDER BY total_spent DESC
LIMIT 10;

-- 6. Repeat-purchase rate
SELECT
  COUNT(*) AS total_customers,
  SUM(orders > 1) AS repeat_customers,
  ROUND(100 * SUM(orders > 1) / COUNT(*), 1) AS repeat_rate_pct
FROM (
  SELECT CustomerID, COUNT(DISTINCT InvoiceNo) AS orders
  FROM online_retail_clean
  WHERE CustomerID <> ''
  GROUP BY CustomerID
) t;

-- 7. Top 10 products by revenue
SELECT StockCode, Description,
       SUM(Quantity) AS units_sold,
       ROUND(SUM(Revenue), 2) AS total_revenue
FROM online_retail_clean
GROUP BY StockCode, Description
ORDER BY total_revenue DESC
LIMIT 10;

-- 8. Revenue by country
SELECT Country,
       COUNT(DISTINCT InvoiceNo) AS orders,
       ROUND(SUM(Revenue), 2) AS total_revenue
FROM online_retail_clean
GROUP BY Country
ORDER BY total_revenue DESC
LIMIT 10;

-- 9. Average order value
SELECT ROUND(SUM(Revenue) / COUNT(DISTINCT InvoiceNo), 2) AS avg_order_value
FROM online_retail_clean;

-- 10. Revenue by weekday
SELECT DAYNAME(InvoiceDate) AS weekday,
       COUNT(DISTINCT InvoiceNo) AS orders,
       ROUND(SUM(Revenue), 2) AS total_revenue
FROM online_retail_clean
GROUP BY weekday
ORDER BY total_revenue DESC;

-- 11. Average spend per customer
SELECT ROUND(SUM(Revenue) / COUNT(DISTINCT CustomerID), 2) AS avg_spend_per_customer
FROM online_retail_clean
WHERE CustomerID <> '';

-- 12. UK share of revenue
SELECT ROUND(100 * SUM(CASE WHEN Country LIKE 'United Kingdom%' THEN Revenue END) / SUM(Revenue), 1) AS uk_share_pct
FROM online_retail_clean;