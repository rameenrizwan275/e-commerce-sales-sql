-- 01_schema.sql
-- Staging table for the raw CSV import. All columns are TEXT so the file loads
-- without type errors; conversion to proper types happens in 03_cleaning.sql.

CREATE TABLE stg_orders (
    order_id         TEXT,
    order_date       TEXT,
    customer_id      TEXT,
    product_category TEXT,
    region           TEXT,
    quantity         TEXT,
    unit_price       TEXT,
    discount         TEXT,
    payment_method   TEXT,
    delivery_days    TEXT,
    customer_rating  TEXT,
    revenue          TEXT
);
