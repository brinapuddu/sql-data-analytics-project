# Retail Sales Intelligence Project
###  *Customer Behaviour & Product Revenue Analysis*

---

A complete end-to-end data analytics project using SQL on a retail sales database. The project follows a structured 12-step analytics framework covering Exploratory Data Analysis, Advanced Analytics, and final Reporting.

---

## Project Roadmap

The project is structured around two tracks - **Exploratory Data Analysis (EDA)** and **Advanced Analytics** - culminating in a final **Reporting** layer.

```
Data Analytics
│
├── Exploratory Data Analysis (EDA)
│   ├── 01 - Database Exploration
│   ├── 02 - Dimensions Exploration
│   ├── 03 - Date Exploration
│   ├── 04 - Measures Exploration (Big Numbers)
│   ├── 05 - Magnitude
│   └── 06 - Ranking (Top N / Bottom N)
│
├── Advanced Analytics
│   ├── 07 - Change-Over-Time / Trends
│   ├── 08 - Cumulative Analysis
│   ├── 09 - Performance Analysis
│   ├── 10 - Part-to-Whole (Proportional)
│   └── 11 - Data Segmentation
│
└── 12 - Reporting ← current stage
```

### Step-by-step breakdown

| Step | Phase | Type | Description |
|------|-------|------|-------------|
| 01 | EDA | Database Exploration | Inspected schemas, tables, and relationships across the gold layer |
| 02 | EDA | Dimensions Exploration | Explored categorical fields: customer names, product categories, subcategories |
| 03 | EDA | Date Exploration | Analysed order date ranges, customer birthdates, and temporal coverage |
| 04 | EDA | Measures Exploration | Identified key numeric measures: sales amount, quantity, cost |
| 05 | EDA | Magnitude | Quantified scale of data - total customers, products, orders, and revenue |
| 06 | EDA | Ranking | Ranked top and bottom performing products and customers by revenue |
| 07 | Advanced | Change-Over-Time | Analysed sales trends over time to identify growth and seasonal patterns |
| 08 | Advanced | Cumulative Analysis | Built running totals to understand revenue accumulation over the customer lifecycle |
| 09 | Advanced | Performance Analysis | Benchmarked products and customers against averages and targets |
| 10 | Advanced | Part-to-Whole | Calculated revenue share by category, subcategory, and segment |
| 11 | Advanced | Data Segmentation | Segmented customers (VIP / Regular / New) and products (High / Mid / Low) |
| 12 | Reporting | Final Report | Built gold-layer customer and product report views for business consumption |

---

## Data Architecture

The project queries from a **gold layer** in a medallion architecture, joining two core tables:

```sql
gold.fact_sales        -- transactional data (orders, sales amounts, quantities)
gold.dim_customers     -- customer dimension (names, birthdates, customer keys)
gold.dim_products      -- product dimension (names, categories, cost)
```

---

## SQL Reports Built

### Customer Report (`gold.report_customers`)

A CTE-based report that consolidates all customer-level metrics and behaviours.

```sql
WITH base_query AS (
    SELECT
        f.order_number,
        f.product_key,
        f.order_date,
        f.sales_amount,
        f.quantity,
        c.customer_key,
        c.customer_number,
        CONCAT(c.first_name, ' ', c.last_name)  AS customer_name,
        DATEDIFF(YEAR, c.birthdate, GETDATE())   AS age
    FROM gold.fact_sales f
    LEFT JOIN gold.dim_customers c
        ON c.customer_key = f.customer_key
    WHERE order_date IS NOT NULL
),
customer_aggregations AS (
    SELECT
        customer_key,
        customer_number,
        customer_name,
        age,
        COUNT(DISTINCT order_number)                              AS total_orders,
        SUM(sales_amount)                                         AS total_sales,
        SUM(quantity)                                             AS total_quantity,
        COUNT(DISTINCT product_key)                               AS total_products,
        MAX(order_date)                                           AS last_order_date,
        DATEDIFF(month, MIN(order_date), MAX(order_date))         AS lifespan
    FROM base_query
    GROUP BY customer_key, customer_number, customer_name, age
)
SELECT
    customer_key,
    customer_number,
    customer_name,
    CASE
        WHEN age < 20                  THEN 'Under 20'
        WHEN age BETWEEN 20 AND 29     THEN '20-29'
        WHEN age BETWEEN 30 AND 39     THEN '30-39'
        WHEN age BETWEEN 40 AND 49     THEN '40-49'
        ELSE                                '50 and above'
    END AS age_group,
    CASE
        WHEN lifespan >= 12 AND total_sales > 5000  THEN 'VIP'
        WHEN lifespan >= 12 AND total_sales <= 5000 THEN 'Regular'
        ELSE                                             'New'
    END AS customer_segment,
    total_orders,
    total_sales,
    total_quantity,
    total_products,
    last_order_date,
    lifespan,
    DATEDIFF(month, last_order_date, GETDATE())             AS recency,
    CASE WHEN total_orders = 0 THEN 0
         ELSE total_sales / total_orders END                AS avg_order_revenue,
    CASE WHEN lifespan = 0 THEN total_sales
         ELSE total_sales / lifespan END                    AS avg_monthly_revenue
FROM customer_aggregations
```

**Fields produced:**

| Field | Description |
|-------|-------------|
| `age_group` | Bucketed age bands (Under 20, 20-29, 30-39, 40-49, 50+) |
| `customer_segment` | VIP / Regular / New based on lifespan and spend |
| `total_orders` | Count of distinct orders |
| `total_sales` | Lifetime revenue |
| `total_quantity` | Units purchased |
| `total_products` | Distinct products bought |
| `last_order_date` | Date of most recent purchase |
| `lifespan` | Months between first and last order |
| `recency` | Months since last purchase |
| `avg_order_revenue` | Average revenue per order |
| `avg_monthly_revenue` | Average monthly spend |

---

### Product Report (`gold.report_products`)

```sql
WITH base_query AS (
    SELECT
        f.order_number,
        f.order_date,
        f.sales_amount,
        f.quantity,
        f.customer_key,
        p.product_key,
        p.product_name,
        p.category,
        p.subcategory,
        p.cost
    FROM gold.fact_sales f
    LEFT JOIN gold.dim_products p
        ON p.product_key = f.product_key
    WHERE f.order_date IS NOT NULL
),
product_aggregations AS (
    SELECT
        product_key,
        product_name,
        category,
        subcategory,
        cost,
        COUNT(DISTINCT order_number)                              AS total_orders,
        SUM(sales_amount)                                         AS total_sales,
        SUM(quantity)                                             AS total_quantity,
        COUNT(DISTINCT customer_key)                              AS total_customers,
        MAX(order_date)                                           AS last_order_date,
        DATEDIFF(month, MIN(order_date), MAX(order_date))         AS lifespan
    FROM base_query
    GROUP BY product_key, product_name, category, subcategory, cost
)
SELECT
    product_key,
    product_name,
    category,
    subcategory,
    cost,
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
    DATEDIFF(month, last_order_date, GETDATE())             AS recency,
    CASE WHEN total_orders = 0 THEN 0
         ELSE total_sales / total_orders END                AS avg_order_revenue,
    CASE WHEN lifespan = 0 THEN total_sales
         ELSE total_sales / lifespan END                    AS avg_monthly_revenue
FROM product_aggregations
```

**Segmentation logic:**

| Segment | Condition |
|---------|-----------|
| `High-Performer` | Total sales > $50,000 |
| `Mid-Range` | Total sales between $10,000 and $50,000 |
| `Low-Performer` | Total sales < $10,000 |

---

## Results & Insights

### Executive Overview

| Metric | Value |
|--------|-------|
| Total Revenue | $29.4M |
| Total Customers | 18,482 |
| Total Products | 130 SKUs |
| Avg Revenue per Customer | $1,588 |

---

### Customer Insights

#### Segment breakdown

| Segment | Customers | Total Revenue | Avg Revenue / Customer |
|---------|-----------|---------------|------------------------|
| VIP | 1,653 (9%) | $10.8M (37%) | $6,510 |
| Regular | 2,200 (12%) | $7.5M (26%) | $3,411 |
| New | 14,629 (79%) | $11.1M (38%) | $758 |

#### Age distribution

| Age Group | Customers |
|-----------|-----------|
| 50 and above | 12,846 (69%) |
| 40–49 | 5,636 (31%) |

#### Key findings

- **VIP leverage:** VIP customers are only 9% of the base but drive 37% of revenue at $6,510 average spend - 8.6× more than New customers. Retention of this cohort is the single highest-priority action.
- **New customer opportunity:** 79% of customers are classified as New with an average spend of just $758. Converting even 10% of New customers to Regular would add approximately $2.6M in incremental revenue.
- **Mature customer base:** 100% of customers are aged 40 or above, with 69% aged 50+. There is zero representation from under-40 demographics, indicating a gap in younger audience acquisition.
- **High recency:** Average recency is 87 months, meaning customers have not purchased in over 7 years on average. This reflects the historical nature of the dataset rather than an active buyer base.

---

### Product Insights

#### Revenue by category

| Category | Revenue | Share |
|----------|---------|-------|
| Bikes | $28.3M | 96% |
| Accessories | $700K | 2% |
| Clothing | $340K | 1% |

#### Revenue by subcategory (top 5)

| Subcategory | Revenue |
|-------------|---------|
| Road Bikes | $14.5M |
| Mountain Bikes | $9.9M |
| Touring Bikes | $3.8M |
| Tires and Tubes | $244K |
| Helmets | $225K |

#### Product segment breakdown

| Segment | Products | Total Revenue | Share |
|---------|----------|---------------|-------|
| High-Performer | 66 (51%) | $27.6M | 94% |
| Mid-Range | 58 (45%) | $1.7M | 6% |
| Low-Performer | 6 (5%) | $36K | <1% |

#### Key findings

- **Bikes dominate:** Bikes represent 96% of all revenue. Road Bikes and Mountain Bikes alone account for 83% of total sales - the business is effectively a bikes company.
- **Product concentration risk:** High-Performer products (51% of catalogue) drive 94% of revenue. The top 10 products are all bikes, led by the Mountain-200 and Road-150 ranges.
- **Low-Performer candidates:** Just 6 SKUs generate under $36K combined. These are strong candidates for discontinuation or promotional review.
- **Accessories and Clothing underperform:** Despite broadening the catalogue, non-bike categories generate just 3% of revenue combined, suggesting limited cross-sell success.

---

## Recommendations

1. **Protect the VIP segment** - implement a dedicated loyalty or retention programme for the 1,653 VIP customers who contribute $10.8M in revenue.
2. **Activate New customers** - build a post-purchase nurture campaign to move New customers toward their first repeat order and into the Regular bracket.
3. **Invest in Road and Mountain Bikes** - these two subcategories alone drive $24.4M. Ensuring stock depth and product development here is the highest-impact commercial lever.
4. **Review Low-Performer SKUs** - 6 products generating under $36K combined should be evaluated for removal to simplify the catalogue.
5. **Explore younger demographics** - with 0% of customers under 40, there is an untapped market segment worth investigating through targeted acquisition campaigns.
6. **Investigate recency** - average last purchase was over 7 years ago. A re-engagement or win-back campaign targeting lapsed customers could unlock significant latent value.

---

## Tech Stack

- **Database:** SQL Server (T-SQL)
- **Architecture:** Medallion (Bronze → Silver → Gold)
- **Query patterns:** CTEs, window functions, CASE segmentation, DATEDIFF, aggregations
- **Output:** Gold-layer reporting views ready for BI tool consumption

---

*Project built following the 12-step Data Analytics framework. All analysis performed on the gold layer of a retail sales data warehouse.*

