-- 03_cleaning.sql
-- Builds the clean, typed "orders" table from the raw staging table.
--
-- Decision: the source dates run daily from 2022-01-01 to 2035-09-09, one order per day,
-- which means most rows are dated in the future. This looks like a generated sequence,
-- so the analysis is limited to complete years up to 2025-12-31 (1,461 orders).

CREATE TABLE orders AS
SELECT
    order_id::INT                        AS order_id,
    TO_DATE(order_date, 'MM/DD/YYYY')    AS order_date,
    customer_id::INT                     AS customer_id,
    TRIM(product_category)               AS product_category,
    TRIM(region)                         AS region,
    quantity::INT                        AS quantity,
    unit_price::NUMERIC(10,2)            AS unit_price,
    discount::NUMERIC(4,2)               AS discount,
    TRIM(payment_method)                 AS payment_method,
    delivery_days::INT                   AS delivery_days,
    customer_rating::NUMERIC(2,1)        AS customer_rating,
    revenue::NUMERIC(12,2)               AS revenue
FROM stg_orders
WHERE TO_DATE(order_date, 'MM/DD/YYYY') <= DATE '2025-12-31';

ALTER TABLE orders ADD PRIMARY KEY (order_id);
