# e-commerce-sales-sql
SQL analysis and Tableau dashboard of 4 years of synthetic e-commerce orders.

# E-commerce Sales Analysis (SQL + Tableau)

An end-to-end analysis of 1,461 synthetic e-commerce orders (2022-2025): data quality checks and cleaning in PostgreSQL, analytical SQL views, and an interactive Tableau dashboard.

![Dashboard](dashboard/E-commerce Dashboard Screenshot.png)

**[View the interactive dashboard on Tableau Public](https://public.tableau.com/views/e-commerce_17899039055670/E-commerceDashboard?:language=en-GB&publish=yes&:sid=&:redirect=auth&:display_count=n&:origin=viz_share_link)**

## Business questions

1. How has revenue trended month by month?
2. Which product categories and regions drive the most revenue?
3. Do higher discounts increase quantity enough to offset the lost revenue?
4. Does delivery time affect customer ratings?
5. How does the payment method mix vary by region?

## Key findings

*These findings describe this synthetic dataset, not real customers.*

- **Revenue is flat to slightly declining.** Annual revenue fell from about 371.8K in 2022 to 349.8K in 2025 (roughly -6%). Monthly revenue is volatile, ranging from about 21K to 42K with no clear seasonal pattern.
- **Electronics leads.** It accounts for about 36% of revenue, followed by Clothing (28%), Home (22%), and Beauty (14%).
- **Discounts cost revenue without raising volume.** Average quantity per order stays at about 4.0 in every discount tier, while average order revenue falls from about 1,151 (low discounts) to 882 (over 20%). Orders discounted over 20% make up about 45% of all orders and about 69% of the total discount given (roughly 321.6K, or 18% of pre-discount sales).
- **Delivery time doesn't affect ratings.** Average rating is between 2.89 and 3.07 across all delivery-time buckets.
- **Payment mix is similar everywhere.** Card is 42-47% of orders in every region, COD 35-38%, and Wallet 16-22%.

**Recommendation:** test reducing the deepest discounts (over 20%), since the data shows no volume benefit from them.

## Data

- **Source:** synthetic e-commerce orders dataset from [Kaggle](https://www.kaggle.com/datasets/abbas829/ecommerce-sales-dataset).
- **Size:** 5,000 rows in the raw file, 1,461 analysed.
- **Period used:** 1 Jan 2022 to 31 Dec 2025. The raw file has one order per day through 2035, so rows dated after 2025 (mostly in the future) were excluded.
- **Columns:** order_id, order_date, customer_id, product_category, region, quantity, unit_price, discount, payment_method, delivery_days, customer_rating, revenue.

## Approach

1. **Staging:** loaded the raw CSV into a text-only staging table (`01_schema.sql`).
2. **Quality checks:** row counts, duplicate IDs, missing values, impossible values, and a check that `revenue = quantity x unit_price x (1 - discount)` on every row (`02_data_quality_checks.sql`). No problems were found.
3. **Cleaning:** converted types, parsed dates, and applied the date cutoff (`03_cleaning.sql`).
4. **Analysis:** one SQL view per business question, using CTEs, window functions (`LAG`, moving averages, percent of total), and `CASE WHEN` segmentation (`04_analysis_views.sql`).
5. **Dashboard:** exported the views as CSVs and built the dashboard in Tableau Public.

## Repository structure

```
├── data/ecommerce.csv           raw dataset
├── sql/
│   ├── 01_schema.sql            staging table
│   ├── 02_data_quality_checks.sql
│   ├── 03_cleaning.sql          clean, typed orders table
│   └── 04_analysis_views.sql    six analytical views
└── dashboard/
    ├── dashboard_screenshot.png
    └── exports/                 CSVs of each view, used by Tableau
```

## How to reproduce

1. Create a PostgreSQL database and run `sql/01_schema.sql`.
2. Import `data/ecommerce.csv` into `stg_orders`.
3. Run `sql/02_data_quality_checks.sql` and review the results.
4. Run `sql/03_cleaning.sql`, then `sql/04_analysis_views.sql`.
5. Export the views to CSV, or use the files in `dashboard/exports/`, and connect them in Tableau.

## Tools

PostgreSQL, DBeaver, Tableau Public, GitHub

## Limitations

- The data is synthetic, so it has little natural structure (no seasonality, and no relationships between delivery time, discounts, and ratings). The analysis is real, but the business conclusions should not be generalised.
- The source is one flat table, so there are no joins. The SQL focuses on aggregation, window functions, and segmentation.
- Dates were generated as one order per day, so daily analysis is meaningless and monthly aggregation is used instead.
- There is no cost data, so the analysis covers revenue, not profit.
- `region` varies within a customer, so it is treated as an order attribute rather than a customer attribute.
