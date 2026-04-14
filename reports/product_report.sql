
/*
================================================================
Product Report
================================================================

Purpose:
    This report consolidates key product metrics and behaviors.

Highlights:

    Gathers essential fields such as product name, category, subcategory, and cost.
    Segments products by revenue to identify High-Performers, Mid-Range, or Low-Performers.
    Aggregates product-level metrics:

    total orders
    total sales
    total quantity sold
    total customers (unique)
    lifespan (in months)


Calculates valuable KPIs:

    recency (months since last sale)
    average order revenue (AOR)
    average monthly revenue
================================================================
*/

CREATE VIEW gold.report_products AS 
-- 1. Base query
WITH base_query AS (
    SELECT
        f.order_number,
        f.order_date,
        f.sales_amount,
        f.quantity,
        p.product_key,
        p.product_name,
        p.category,
        p.subcategory,
        f.customer_key,
        p.cost
    FROM gold.fact_sales f
    LEFT JOIN gold.dim_products p
        ON p.product_key = f.product_key
    WHERE f.order_date IS NOT NULL
),

-- 2. Product Aggregations
product_aggregations AS (
    SELECT
        product_key,
        product_name,
        category,
        subcategory,
        cost,
        COUNT(DISTINCT order_number)        AS total_orders,
        SUM(sales_amount)                   AS total_sales,
        SUM(quantity)                       AS total_quantity,
        COUNT(DISTINCT customer_key)        AS total_customers,
        MAX(order_date)                     AS last_order_date,
        DATEDIFF(month, MIN(order_date), MAX(order_date)) AS lifespan
    FROM base_query
    GROUP BY
        product_key,
        product_name,
        category,
        subcategory,
        cost
)

-- 3. Final SELECT
SELECT
    product_key,
    product_name,
    category,
    subcategory,
    cost,
    -- Revenue segmentation
    CASE
        WHEN total_sales > 50000 THEN 'High-Performer'
        WHEN total_sales >= 10000 THEN 'Mid-Range'
        ELSE 'Low-Performer'
    END AS product_segment,
    total_orders,
    total_sales,
    total_quantity,
    total_customers,
    last_order_date,
    lifespan,
    -- KPIs
    DATEDIFF(month, last_order_date, GETDATE()) AS recency,
    CASE WHEN total_orders = 0 THEN 0
         ELSE total_sales / total_orders 
     END avg_order_revenue,
    CASE WHEN lifespan = 0 THEN total_sales
         ELSE total_sales / lifespan 
     END avg_monthly_revenue
FROM product_aggregations

SELECT*
FROM gold.report_products
