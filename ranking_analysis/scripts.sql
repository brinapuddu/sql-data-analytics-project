
------------------------------------------------
PRODUCT & CUSTOMER PERFORMANCE ANALYSIS
-- Identifies top/bottom performing products
-- by revenue and most/least active customers
-- by orders and revenue.
------------------------------------------------
  
--Which 5 products generate the highest revenue?
SELECT TOP 5
p.product_name, 
sum(s.sales_amount) total_revenue 
FROM gold.fact_sales s
LEFT JOIN gold.dim_products p
ON p.product_key = s.product_key
GROUP BY p.product_name
ORDER BY total_revenue DESC;


--Which 5 Products generate the lowest revenue?
SELECT TOP 5
p.product_name, 
sum(s.sales_amount) total_revenue 
FROM gold.fact_sales s
LEFT JOIN gold.dim_products p
ON p.product_key = s.product_key
GROUP BY p.product_name
ORDER BY total_revenue ASC;

--Find the top 10 customers who have granted the highest revenue 
SELECT TOP 10
c.customer_key,
c.first_name, 
c.last_name, 
sum(s.sales_amount) total_revenue 
FROM gold.fact_sales s
LEFT JOIN gold.dim_customers C
ON s.customer_key = c.customer_key
GROUP BY c.customer_key, c.first_name, c.last_name
ORDER BY total_revenue DESC;

-- Who are the 3 customers with the fewest placed orders?
SELECT TOP 3
c.customer_key,
c.first_name, 
c.last_name, 
count(s.order_number) total_orders
FROM gold.fact_sales s
LEFT JOIN gold.dim_customers C
ON s.customer_key = c.customer_key
GROUP BY c.customer_key, c.first_name, c.last_name
ORDER BY total_orders ASC;
