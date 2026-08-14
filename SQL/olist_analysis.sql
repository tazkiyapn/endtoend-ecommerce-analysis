-- view 1: order delivered yang valid untuk analisis umum (gmv, RFM, dll)
CREATE VIEW vw_delivered_orders AS
SELECT 
    o.order_id,
    o.customer_id,
    o.order_purchase_timestamp,
    o.order_delivered_customer_date,
    o.order_estimated_delivery_date
FROM orders o
WHERE o.order_status = 'delivered';

-- view 2: khusus untuk analisis delivery delay, exclude 8 anomali
CREATE VIEW vw_delivery_delay AS
SELECT 
    o.order_id,
    o.order_delivered_customer_date,
    o.order_estimated_delivery_date,
    DATEDIFF(o.order_delivered_customer_date, o.order_estimated_delivery_date) AS delay_days
FROM orders o
WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL;

-- view 3: review yang sudah dibersihkan dari duplikat
CREATE VIEW vw_order_reviews_clean AS
SELECT *
FROM (
    SELECT *,
        ROW_NUMBER() OVER (PARTITION BY order_id ORDER BY review_creation_date DESC) AS rn
    FROM order_reviews
) t
WHERE rn = 1;

SELECT order_id, COUNT(*) 
FROM vw_order_reviews_clean 
GROUP BY order_id 
HAVING COUNT(*) > 1;

-- KPI
-- total gmv
SELECT SUM(oi.price) AS total_gmv
FROM vw_delivered_orders v
JOIN order_items oi ON v.order_id = oi.order_id;

-- total orders (delivered)
SELECT COUNT(DISTINCT order_id) AS total_orders
FROM vw_delivered_orders;

-- average order value (aov)
WITH order_value AS (
    SELECT v.order_id, SUM(oi.price) AS order_total
    FROM vw_delivered_orders v
    JOIN order_items oi ON v.order_id = oi.order_id
    GROUP BY v.order_id
)
SELECT ROUND(AVG(order_total), 2) AS avg_order_value
FROM order_value;

-- average review score
SELECT ROUND(AVG(review_score), 2) AS avg_review_score
FROM vw_order_reviews_clean;

-- on-time-delivered rate
SELECT
    ROUND(
        SUM(CASE WHEN delay_days <= 0 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2
    ) AS on_time_delivery_pct
FROM vw_delivery_delay;

-- repeat customer rate
WITH customer_orders AS (
    SELECT c.customer_unique_id, COUNT(DISTINCT v.order_id) AS total_orders
    FROM vw_delivered_orders v
    JOIN customers c ON v.customer_id = c.customer_id
    GROUP BY c.customer_unique_id
)
SELECT
    ROUND(
        SUM(CASE WHEN total_orders > 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2
    ) AS repeat_customer_pct
FROM customer_orders;

SELECT COUNT(DISTINCT customer_unique_id) as jumlah_cust FROM customers;

-- Jumlah order delivered yang memiliki review
SELECT
    ROUND(
        (SELECT COUNT(DISTINCT r.order_id)
         FROM vw_order_reviews_clean r
         JOIN vw_delivered_orders v ON r.order_id = v.order_id) * 100.0
        / (SELECT COUNT(*) FROM vw_delivered_orders), 2
    ) AS review_coverage_pct;
    

-- BQ1: monthly gmv
WITH monthly_gmv AS (
    SELECT
        DATE_FORMAT(v.order_purchase_timestamp, '%Y-%m') AS order_month,
        SUM(oi.price) AS total_gmv,
        COUNT(DISTINCT v.order_id) AS total_orders
    FROM vw_delivered_orders v
    JOIN order_items oi ON v.order_id = oi.order_id
    GROUP BY order_month
)
SELECT
    order_month,
    total_gmv,
    total_orders,
    LAG(total_gmv) OVER (ORDER BY order_month) AS prev_month_gmv,
    ROUND(
        (total_gmv - LAG(total_gmv) OVER (ORDER BY order_month))
        / LAG(total_gmv) OVER (ORDER BY order_month) * 100, 2
    ) AS growth_pct
FROM monthly_gmv
ORDER BY order_month;


-- BQ2: category performance
SELECT
    p.product_category_name,
    COUNT(DISTINCT oi.order_id) AS total_orders,
	COUNT(oi.order_item_id) AS items_sold,
    ROUND(AVG(oi.price),2) AS avg_price,
    SUM(oi.price) AS total_gmv,
    ROUND(AVG(r.review_score), 2) AS avg_review_score
FROM vw_delivered_orders v
JOIN order_items oi ON v.order_id = oi.order_id
JOIN products p ON oi.product_id = p.product_id
JOIN vw_order_reviews_clean r ON v.order_id = r.order_id
GROUP BY p.product_category_name
ORDER BY total_gmv DESC, avg_review_score ASC
;

-- BQ3: delivery & review
SELECT
    CASE WHEN d.delay_days > 0 THEN 'Late' ELSE 'On Time / Early' END AS delivery_status,
    COUNT(*) AS total_orders,
    ROUND(AVG(r.review_score), 2) AS avg_review_score,
    ROUND(AVG(d.delay_days), 1) AS avg_delay_days
FROM vw_delivery_delay d
JOIN vw_order_reviews_clean r ON d.order_id = r.order_id
GROUP BY delivery_status;

SELECT d.order_id, d.delay_days, r.review_score
FROM vw_delivery_delay d
JOIN vw_order_reviews_clean r ON d.order_id = r.order_id;

-- BQ4: segmentasi customer
WITH customer_rfm AS (
    SELECT
        c.customer_unique_id,
        DATEDIFF(
            (SELECT MAX(order_purchase_timestamp) FROM vw_delivered_orders),
            MAX(v.order_purchase_timestamp)
        ) AS recency_days,
        COUNT(DISTINCT v.order_id) AS frequency,
        SUM(oi.price) AS monetary
    FROM vw_delivered_orders v
    JOIN customers c ON v.customer_id = c.customer_id
    JOIN order_items oi ON v.order_id = oi.order_id
    GROUP BY c.customer_unique_id
)
SELECT
    customer_unique_id,
    recency_days,
    frequency,
    monetary,
    NTILE(4) OVER (ORDER BY recency_days DESC) AS recency_score,
    NTILE(4) OVER (ORDER BY frequency ASC) AS frequency_score,
    NTILE(4) OVER (ORDER BY monetary ASC) AS monetary_score
FROM customer_rfm;

