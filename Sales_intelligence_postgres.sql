--- Renaming Columns

ALTER TABLE salesdw.dim_product RENAME COLUMN product_id TO "Product_ID";
ALTER TABLE salesdw.dim_product RENAME COLUMN category TO "Category";
ALTER TABLE salesdw.dim_product RENAME COLUMN sub_category TO "Sub_category";

ALTER TABLE salesdw.dim_location RENAME COLUMN location_id TO "Location_ID";
ALTER TABLE salesdw.dim_location RENAME COLUMN city TO "City";
ALTER TABLE salesdw.dim_location RENAME COLUMN state TO "State";

ALTER TABLE salesdw.dim_payment RENAME COLUMN payment_id TO "Payment_ID";
ALTER TABLE salesdw.dim_payment RENAME COLUMN payment_mode TO "Payment_mode";

ALTER TABLE salesdw.dim_date RENAME COLUMN order_date TO "Order_date";
ALTER TABLE salesdw.dim_date RENAME COLUMN date_id TO "Date_ID";
ALTER TABLE salesdw.dim_date RENAME COLUMN year TO "Year";
ALTER TABLE salesdw.dim_date RENAME COLUMN month TO "Month";

ALTER TABLE salesdw.fact_sales RENAME COLUMN order_id TO "Order_ID";
ALTER TABLE salesdw.fact_sales RENAME COLUMN date_id TO "Date_ID";
ALTER TABLE salesdw.fact_sales RENAME COLUMN customer_id TO "Customer_ID";
ALTER TABLE salesdw.fact_sales RENAME COLUMN product_id TO "Product_ID";
ALTER TABLE salesdw.fact_sales RENAME COLUMN location_id TO "Location_ID";
ALTER TABLE salesdw.fact_sales RENAME COLUMN payment_id TO "Payment_ID";
ALTER TABLE salesdw.fact_sales RENAME COLUMN quantity TO "Quantity";
ALTER TABLE salesdw.fact_sales RENAME COLUMN amount TO "Amount";
ALTER TABLE salesdw.fact_sales RENAME COLUMN profit TO "Profit";

ALTER TABLE salesdw."Fact_Sales" RENAME TO fact_sales;


--- JOINS
---1. Which product categories perform best in each location based on total sales

SELECT 
    dp."Category",
    dl."State",
    SUM(fs."Amount") AS total_sales
FROM salesdw.fact_sales fs
JOIN salesdw.dim_product dp ON fs."Product_ID" = dp."Product_ID"
JOIN salesdw.dim_location dl ON fs."Location_ID" = dl."Location_ID"
GROUP BY dp."Category", dl."State"
ORDER BY dl."State", total_sales DESC;


---2. What is the average order amount for each city
SELECT 
    dl."City",
    AVG(fs."Amount") AS avg_order_amount
FROM salesdw.fact_sales fs
JOIN salesdw.dim_location dl ON fs."Location_ID" = dl."Location_ID"
GROUP BY dl."City"
ORDER BY avg_order_amount DESC;

---RANKING 
---3.Rank cities by total revenue

SELECT 
    dl."City",
    SUM(fs."Amount") AS total_revenue,
    RANK() OVER (ORDER BY SUM(fs."Amount") DESC) AS revenue_rank
FROM salesdw.fact_sales fs
JOIN salesdw.dim_location dl ON fs."Location_ID" = dl."Location_ID"
GROUP BY dl."City";


--- WINDOW FUNCTIONS
---4. Top 3 selling products in each category by quantity sold

SELECT 
    dl."City",
    SUM(fs."Amount") AS total_revenue,
    RANK() OVER (ORDER BY SUM(fs."Amount") DESC) AS revenue_rank
FROM salesdw.fact_sales fs
JOIN salesdw.dim_location dl ON fs."Location_ID" = dl."Location_ID"
GROUP BY dl."City";

--- CASE
---5. Classify each sale as “High”, “Medium”, or “Low” based on profit margin
SELECT 
    fs."Order_ID",
    fs."Amount",
    fs."Profit",
    CASE 
        WHEN fs."Amount" = 0 THEN 'Undefined'
        WHEN fs."Profit" / fs."Amount" > 0.3 THEN 'High'
        WHEN fs."Profit" / fs."Amount" >= 0.1 AND fs."Profit" / fs."Amount" <= 0.3 THEN 'Medium'
        ELSE 'Low'
    END AS profit_category
FROM salesdw.fact_sales fs;

--6. Label products as “EXPENSIVE” if unit price > 500
SELECT 
    fs."Order_ID",
    dp."Product_ID",
    fs."Amount" / NULLIF(fs."Quantity", 0) AS unit_price,
    CASE 
        WHEN fs."Amount" / NULLIF(fs."Quantity", 0) > 500 THEN 'Expensive'
        ELSE 'Standard'
    END AS product_tier
FROM salesdw.fact_sales fs
JOIN salesdw.dim_product dp ON fs."Product_ID" = dp."Product_ID";

--- AGGREGATIONS & SUBQUERIES
--- 7.Average monthly sales per product
SELECT 
    dp."Product_ID",
    dd."Month",
    dd."Year",
    AVG(fs."Amount") AS avg_monthly_sales
FROM salesdw.fact_sales fs
JOIN salesdw.dim_product dp ON fs."Product_ID" = dp."Product_ID"
JOIN salesdw.dim_date dd ON fs."Date_ID" = dd."Date_ID"
GROUP BY dp."Product_ID", dd."Year", dd."Month"
ORDER BY dp."Product_ID", dd."Year", dd."Month";

--- 8.Total profit per state in the last quarter
SELECT 
    dl."State",
    SUM(fs."Profit") AS total_profit
FROM salesdw.fact_sales fs
JOIN salesdw.dim_location dl ON fs."Location_ID" = dl."Location_ID"
JOIN salesdw.dim_date dd ON fs."Date_ID" = dd."Date_ID"
WHERE dd."Order_date" >= DATE_TRUNC('quarter', CURRENT_DATE - INTERVAL '3 months')
GROUP BY dl."State"
ORDER BY total_profit DESC;

---9. States with revenue > 95th percentile

WITH state_sales AS (
    SELECT 
        dl."State",
        SUM(fs."Amount") AS total_revenue
    FROM salesdw.fact_sales fs
    JOIN salesdw.dim_location dl ON fs."Location_ID" = dl."Location_ID"
    GROUP BY dl."State"
),
threshold AS (
    SELECT PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY total_revenue) AS revenue_cutoff
    FROM state_sales
)
SELECT ss."State", ss.total_revenue
FROM state_sales ss
JOIN threshold t ON true  
WHERE ss.total_revenue > t.revenue_cutoff
ORDER BY ss.total_revenue DESC;








