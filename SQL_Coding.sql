--- To see the data and familiarize with the Data.

SELECT * FROM `workspace`.`bigquery_db_cohort_db`.`ecom_orders`;
==================================================================================
  
--- Calculate each customer’s first purchase date:

SELECT 
  customer_id, 
  MIN( order_date) as first_order_date 
FROM `workspace`.`bigquery_db_cohort_db`.`ecom_orders` 
GROUP BY customer_id;
==================================================================================
  
--- Determine each customer’s second purchase date (if any) by selecting the earliest order date that occurs after the first purchase:
--- CTE: 
WITH rank_order AS (
  SELECT    
      customer_id,
      order_date,
      ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY order_date ASC ) AS order_rank
  FROM `workspace`.`bigquery_db_cohort_db`.`ecom_orders`

)
SELECT 
    customer_id,
    order_date AS second_purchase_date
FROM rank_order
WHERE order_rank = 2

---------------------------------------
--- Subquery:
  
SELECT customer_id, order_date
FROM (
  SELECT 
    customer_id,
    order_date,
    ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY order_date ASC) AS order_rank
  FROM `workspace`.`bigquery_db_cohort_db`.`ecom_orders`
)
WHERE order_rank = 2
  
==================================================================================
--- Combine the Results and Calculate the Days Between Purchases:

  WITH  First_order_date AS ( 
      SELECT 
          customer_id, 
          MIN(order_date) AS first_order_date 
      FROM `workspace`.`bigquery_db_cohort_db`.`ecom_orders` 
      GROUP BY customer_id                  
),
second_order_date AS(
      SELECT
        customer_id,
        second_order_date
      From (
      SELECT
        customer_id,
        order_date AS second_order_date,
        ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY order_date ASC) as order_ranked
      FROM `workspace`.`bigquery_db_cohort_db`.`ecom_orders`
      ) 
      WHERE order_ranked = 2 ) 
SELECT 
    fob.customer_id,
    fob.first_order_date,
    sod.second_order_date,
    date_diff(sod.second_order_date, fob.first_order_date) AS days_to_repeat
FROM First_order_date AS fob
LEFT JOIN second_order_date AS sod
ON fob.customer_id = sod.customer_id
WHERE sod.second_order_date IS NOT NULL
==================================================================================
--- Save the Final Result as a New Table:
  
CREATE TABLE cohort_analysis AS
WITH  First_order_date AS ( 
      SELECT 
          customer_id, 
          MIN(order_date) AS first_order_date 
      FROM `workspace`.`bigquery_db_cohort_db`.`ecom_orders` 
      GROUP BY customer_id                  
),
second_order_date AS(
      SELECT
        customer_id,
        second_order_date
      From (
      SELECT
        customer_id,
        order_date AS second_order_date,
        ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY order_date ASC) as order_ranked
      FROM `workspace`.`bigquery_db_cohort_db`.`ecom_orders`
      ) 
      WHERE order_ranked = 2 ) 
SELECT 
    fob.customer_id,
    fob.first_order_date,
    sod.second_order_date,
    date_diff(sod.second_order_date, fob.first_order_date) AS days_to_repeat
FROM First_order_date AS fob
LEFT JOIN second_order_date AS sod
ON fob.customer_id = sod.customer_id
WHERE sod.second_order_date IS NOT NULL
==================================================================================
--- Query the new table to ensure that the transformation was successful.

SELECT * FROM cohort_analysis:

==================================================================================
--- Create a Query to Compute Retention Rates:

WITH first_order AS (
    -- Get each customer's first purchase date
    SELECT 
        customer_id, 
        MIN(order_date) AS first_purchase_date
    FROM workspace.bigquery_db_cohort_db.ecom_orders
    GROUP BY customer_id
),
second_order AS (
    -- Get each customer's second purchase date by ranking orders
    SELECT 
        customer_id, 
        order_date AS second_purchase_date
    FROM (
        SELECT 
            customer_id, 
            order_date,
            ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY order_date) AS order_rank
        FROM workspace.bigquery_db_cohort_db.ecom_orders
    ) tmp
    WHERE order_rank = 2  -- Select only the second purchase
),
cohorts AS (
    -- Compute retention time and cohort grouping
    SELECT 
        f.customer_id,
        DATE_TRUNC('month', f.first_purchase_date) AS cohort_month,
        f.first_purchase_date,
        s.second_purchase_date,
        FLOOR(DATE_DIFF(s.second_purchase_date, f.first_purchase_date)/30) AS months_until_second_order
    FROM first_order f
    LEFT JOIN second_order s 
        ON f.customer_id = s.customer_id
)
SELECT 
    cohort_month,
    COUNT(DISTINCT customer_id) AS total_customers,
    COUNT(DISTINCT CASE WHEN months_until_second_order = 1 THEN customer_id END) AS retained_1_month,
    COUNT(DISTINCT CASE WHEN months_until_second_order = 2 THEN customer_id END) AS retained_2_months,
    COUNT(DISTINCT CASE WHEN months_until_second_order = 3 THEN customer_id END) AS retained_3_months,
    -- Compute retention rates
    ROUND(100 * COUNT(DISTINCT CASE WHEN months_until_second_order = 1 THEN customer_id END) / COUNT(DISTINCT customer_id), 2) AS retention_1_month_pct,
    ROUND(100 * COUNT(DISTINCT CASE WHEN months_until_second_order = 2 THEN customer_id END) / COUNT(DISTINCT customer_id), 2) AS retention_2_months_pct,
    ROUND(100 * COUNT(DISTINCT CASE WHEN months_until_second_order = 3 THEN customer_id END) / COUNT(DISTINCT customer_id), 2) AS retention_3_months_pct
FROM cohorts
GROUP BY cohort_month
ORDER BY cohort_month;

==================================================================================
--- Create a Query to Compute Repeat Purchase Rates:

WITH CustomerOrders AS (
    -- Get each customer's first purchase date and total number of orders
    SELECT 
        customer_id, 
        MIN(order_date) AS first_purchase_date, 
        COUNT(order_id) AS total_orders
    FROM workspace.bigquery_db_cohort_db.ecom_orders
    GROUP BY customer_id
),
CohortAnalysis AS (
    -- Extract the cohort month and year from the first purchase date
    SELECT 
        DATE_TRUNC('month', first_purchase_date) AS cohort_month,
        COUNT(DISTINCT customer_id) AS total_customers,
        COUNT(DISTINCT CASE WHEN total_orders >= 2 THEN customer_id END) AS repeat_2nd_order,
        COUNT(DISTINCT CASE WHEN total_orders >= 3 THEN customer_id END) AS repeat_3rd_order,
        COUNT(DISTINCT CASE WHEN total_orders >= 4 THEN customer_id END) AS repeat_4th_order
    FROM CustomerOrders
    GROUP BY cohort_month
)
-- Compute repeat purchase rates
SELECT 
    cohort_month,
    total_customers,
    repeat_2nd_order,
    repeat_3rd_order,
    repeat_4th_order,
    ROUND(100.0 * repeat_2nd_order / total_customers, 2) AS repeat_2nd_order_rate,
    ROUND(100.0 * repeat_3rd_order / total_customers, 2) AS repeat_3rd_order_rate,
    ROUND(100.0 * repeat_4th_order / total_customers, 2) AS repeat_4th_order_rate
FROM CohortAnalysis
ORDER BY cohort_month;
==================================================================================
--- Create a Query to Compute Cohort Size:
WITH FirstPurchase AS (
    -- Get each customer's first purchase date
    SELECT 
        customer_id, 
        MIN(order_date) AS first_purchase_date
    FROM workspace.bigquery_db_cohort_db.ecom_orders
    GROUP BY customer_id
)
-- Count new customers per month
SELECT 
    DATE_TRUNC('month', first_purchase_date) AS cohort_month,
    COUNT(DISTINCT customer_id) AS new_customers
FROM FirstPurchase
GROUP BY cohort_month
ORDER BY cohort_month;

