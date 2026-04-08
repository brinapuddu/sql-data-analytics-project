/*
-----------------------------------------------------------------------------------------------------
Analytical SQL script for sales trend analysis on the gold schema.
Covers change over time analysis aggregating monthly sales, customer counts, and quantity,
and cumulative analysis calculating a running total of sales over time using a window function.
-----------------------------------------------------------------------------------------------------
*/

--Change over time analysis 
SELECT 
DATETRUNC(MONTH, order_date) as order_date, 
SUM(sales_amount) as total_sales,
COUNT(DISTINCT customer_key) as total_customers, 
SUM(quantity) as total_quantity
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY DATETRUNC(MONTH, order_date) 
ORDER BY DATETRUNC(MONTH, order_date);

---------------------
--Cumulative Analysis
---------------------
--Calculate the total sales per month and running total of sales over time 
SELECT 
order_date, 
total_sales, 
SUM(total_sales) OVER (ORDER BY order_date) as running_total 
FROM 
    (
    SELECT
    
    DATETRUNC(MONTH, order_date) as order_date, 
    SUM(sales_amount) as total_sales
    FROM gold.fact_sales
    WHERE order_date IS NOT NULL
    GROUP BY DATETRUNC(MONTH, order_date) 
    )t; 
