/*
-----------------------------------------------------------------------------------------------------
Part-to-whole analysis SQL script for product categories on the gold schema.
Covers category-level sales aggregated via a CTE, compared against overall total sales
using a window function to calculate and rank each category's percentage contribution
to total revenue.
-----------------------------------------------------------------------------------------------------
*/

--Which categories contribute the most to overall sales?
WITH category_sales AS (
    SELECT
    SUM(s.sales_amount) as category_sales,
    p.category
    FROM gold.fact_sales s
    LEFT JOIN gold.dim_products p
    ON s.product_key = p.product_key
    GROUP BY p.category
)
SELECT 
category_sales,
category,
SUM(category_sales) OVER() as total_sales, 
CONCAT(ROUND((CAST(category_sales AS FLOAT)/SUM(category_sales) OVER())*100, 2), '%')as pct_contribution
FROM 
category_sales
ORDER BY pct_contribution DESC;
