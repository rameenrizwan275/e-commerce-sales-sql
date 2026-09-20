SELECT COUNT(*) AS row_count,
       MIN(order_date) AS first_date,
       MAX(order_date) AS last_date
FROM orders;

-- 04_analysis_views.sql
-- One view per business question. Tableau connects to the CSV exports of these views.
-- Source: the cleaned "orders" table (1,461 orders, 2022-01-01 to 2025-12-31).

-- KPI cards: headline numbers for the dashboard
CREATE OR REPLACE VIEW v_kpi_summary AS
SELECT
    COUNT(*)                          AS total_orders,
    SUM(revenue)                      AS total_revenue,
    ROUND(AVG(revenue), 2)            AS avg_order_value,
    COUNT(DISTINCT customer_id)       AS customers,
    ROUND(AVG(customer_rating), 2)    AS avg_rating,
    ROUND(AVG(delivery_days), 1)      AS avg_delivery_days
FROM orders;

-- Q1: How has revenue trended month by month, and where are the peaks and dips?
-- LAG gives month-over-month growth; the window frame gives a 3-month moving average.
CREATE OR REPLACE VIEW v_monthly_revenue AS
WITH monthly AS (
    SELECT DATE_TRUNC('month', order_date)::DATE AS month,
           COUNT(*)     AS orders,
           SUM(revenue) AS revenue
    FROM orders
    GROUP BY 1
)
SELECT
    month, orders, revenue,
    ROUND(100.0 * (revenue - LAG(revenue) OVER (ORDER BY month))
          / LAG(revenue) OVER (ORDER BY month), 1)                                        AS mom_growth_pct,
    ROUND(AVG(revenue) OVER (ORDER BY month ROWS BETWEEN 2 PRECEDING AND CURRENT ROW), 2) AS revenue_3m_avg
FROM monthly;

-- Q2: Which categories and regions drive revenue, and how has that changed over time?
CREATE OR REPLACE VIEW v_category_region_year AS
WITH yearly AS (
    SELECT
        EXTRACT(YEAR FROM order_date)::INT AS order_year,
        product_category,
        region,
        COUNT(*)                 AS orders,
        SUM(revenue)             AS revenue,
        ROUND(AVG(revenue), 2)   AS avg_order_value
    FROM orders
    GROUP BY 1, 2, 3
)
SELECT
    order_year, product_category, region, orders, revenue, avg_order_value,
    ROUND(100.0 * revenue / SUM(revenue) OVER (PARTITION BY order_year), 1) AS pct_of_year_revenue
FROM yearly;

-- Q3: Do higher discounts increase quantity enough to offset the lost revenue?
CREATE OR REPLACE VIEW v_discount_tiers AS
WITH tiered AS (
    SELECT
        CASE
            WHEN discount = 0     THEN '1. None'
            WHEN discount <= 0.10 THEN '2. Low (up to 10%)'
            WHEN discount <= 0.20 THEN '3. Medium (11-20%)'
            ELSE                       '4. High (over 20%)'
        END AS discount_tier,
        quantity, unit_price, revenue
    FROM orders
)
SELECT
    discount_tier,
    COUNT(*)                                            AS orders,
    ROUND(AVG(quantity), 2)                             AS avg_quantity,
    ROUND(AVG(revenue), 2)                              AS avg_order_revenue,
    ROUND(SUM(quantity * unit_price), 2)                AS revenue_before_discount,
    SUM(revenue)                                        AS revenue_after_discount,
    ROUND(SUM(quantity * unit_price) - SUM(revenue), 2) AS discount_given
FROM tiered
GROUP BY discount_tier;

-- Q4: How do delivery days affect customer ratings?
CREATE OR REPLACE VIEW v_delivery_rating AS
SELECT
    CASE
        WHEN delivery_days <= 3 THEN '1. 1-3 days'
        WHEN delivery_days <= 6 THEN '2. 4-6 days'
        WHEN delivery_days <= 9 THEN '3. 7-9 days'
        ELSE                         '4. 10+ days'
    END AS delivery_bucket,
    COUNT(*)                        AS orders,
    ROUND(AVG(customer_rating), 2)  AS avg_rating
FROM orders
GROUP BY 1;

-- Q5: How does the payment method mix vary by region?
CREATE OR REPLACE VIEW v_payment_region AS
SELECT
    region,
    payment_method,
    COUNT(*)                 AS orders,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (PARTITION BY region), 1) AS pct_of_region_orders,
    SUM(revenue)             AS revenue,
    ROUND(AVG(revenue), 2)   AS avg_order_value
FROM orders
GROUP BY region, payment_method;

SELECT * FROM v_kpi_summary;
SELECT COUNT(*) FROM v_monthly_revenue;
