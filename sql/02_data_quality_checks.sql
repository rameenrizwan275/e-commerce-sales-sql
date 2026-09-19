-- 02_data_quality_checks.sql
-- Quality checks run on the raw staging table before cleaning.
-- Expected results are noted in each comment.

-- Check 1: row count and date range
-- Expect: 5000 rows, 2022-01-01 to 2035-09-09 (later dates are simulated / in the future)
SELECT COUNT(*) AS row_count,
       MIN(TO_DATE(order_date, 'MM/DD/YYYY')) AS first_date,
       MAX(TO_DATE(order_date, 'MM/DD/YYYY')) AS last_date
FROM stg_orders;

-- Check 2: duplicate order IDs
-- Expect: 0
SELECT COUNT(*) - COUNT(DISTINCT order_id) AS duplicate_order_ids
FROM stg_orders;

-- Check 3: missing values in key columns
-- Expect: 0 in every column
SELECT
    COUNT(*) FILTER (WHERE NULLIF(TRIM(order_id), '') IS NULL)        AS missing_order_id,
    COUNT(*) FILTER (WHERE NULLIF(TRIM(customer_id), '') IS NULL)     AS missing_customer_id,
    COUNT(*) FILTER (WHERE NULLIF(TRIM(revenue), '') IS NULL)         AS missing_revenue,
    COUNT(*) FILTER (WHERE NULLIF(TRIM(customer_rating), '') IS NULL) AS missing_rating
FROM stg_orders;

-- Check 4: revenue should equal quantity x unit_price x (1 - discount)
-- Expect: 0 mismatches (tolerance of 0.01 for rounding)
SELECT COUNT(*) AS revenue_mismatches
FROM stg_orders
WHERE ABS(revenue::NUMERIC
          - quantity::NUMERIC * unit_price::NUMERIC * (1 - discount::NUMERIC)) > 0.01;

-- Check 5: impossible values
-- Expect: 0 in every column
SELECT
    COUNT(*) FILTER (WHERE quantity::INT <= 0)                             AS bad_quantity,
    COUNT(*) FILTER (WHERE unit_price::NUMERIC <= 0)                       AS bad_price,
    COUNT(*) FILTER (WHERE discount::NUMERIC < 0 OR discount::NUMERIC > 1) AS bad_discount,
    COUNT(*) FILTER (WHERE delivery_days::INT < 0)                         AS bad_delivery,
    COUNT(*) FILTER (WHERE customer_rating::NUMERIC NOT BETWEEN 1 AND 5)   AS bad_rating
FROM stg_orders;
