/*
-----------------------------------------------------------------------------------------------------
Exploratory SQL script for the gold schema. 

Covers schema inspection (INFORMATION_SCHEMA), dimension exploration (customers, products, dates), 
and key business metrics including total sales, quantity, average price, 
order, and customer counts. Includes a summary report combining all 
metrics via UNION ALL.
----------------------------------------------------------------------------------------------------
*/
  
--Explore all objects in the database
SELECT* FROM INFORMATION_SCHEMA.TABLES;

-- Explore all columns in the database 
SELECT* FROM INFORMATION_SCHEMA.COLUMNS;

-- Explore dimensions: countries where our customers come from
SELECT DISTINCT country FROM gold.dim_customers;

-- Explore all categories: The Major Divisions
SELECT DISTINCT category, subcategory, product_name FROM gold.dim_products;

--Explore dates 
SELECT 
MIN(order_date) as first_order,
MAX(order_date) as last_order, 
DATEDIFF(year, MIN(order_date), MAX(order_date)) AS order_range_year
FROM gold.fact_sales;

-- Find the youngest and the oldest customer 
SELECT 
MIN(birthdate) AS oldest_birthdate,
MAX(birthdate) AS youngest_birthdate,
DATEDIFF(year, MIN(birthdate), GETDATE()) AS oldest_age,
DATEDIFF(year, MAX(birthdate), GETDATE()) AS youngest_age
FROM 
gold.dim_customers;

----------------------
--Measure Exploration 
----------------------
  
-- Find the total sales
SELECT
SUM(sales_amount) as total_sales
FROM gold.fact_sales;

--Show how many items are sold
SELECT
SUM(quantity) as total_quantity
FROM gold.fact_sales;

--Find the average selling price 
SELECT
AVG(price) as avg_price
FROM gold.fact_sales;

--Find the total number of orders
SELECT 
COUNT(DISTINCT order_number) as total_orders
FROM gold.fact_sales;

--Find the total number of products
SELECT 
COUNT(product_key) as total_products
FROM gold.dim_products;

--Find the total number of customers 
SELECT 
COUNT(DISTINCT customer_key) as total_customers
FROM gold.dim_customers;

--Find the total number of customers who have placed an order
SELECT 
COUNT(DISTINCT customer_key) as total_customers
FROM gold.fact_sales;

--Generate a report that shows all key metrics of the business 
SELECT 'Total sales' AS measure_name, SUM(quantity) as measure_value FROM gold.fact_sales
UNION ALL
SELECT 'Total Quantity', SUM(quantity) FROM gold.fact_sales
UNION ALL
SELECT 'Average Price', AVG(price) as avg_price FROM gold.fact_sales
UNION ALL
SELECT 'Number of Orders', COUNT(DISTINCT order_number) FROM gold.fact_sales
UNION ALL
SELECT 'Number of Products', COUNT(product_key) FROM gold.dim_products
UNION ALL
SELECT 'Number of Customers', COUNT(DISTINCT customer_key) as total_customers FROM gold.dim_customers; 

