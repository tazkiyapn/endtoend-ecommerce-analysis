-- =============================================
-- Brazilian E-commerce Analytics Project - Data Preparation
-- =============================================

-- cek struktur dan ukuran data
SHOW TABLES;

SELECT 
	'orders' AS table_name, 
    COUNT(*) AS total_rows FROM orders
UNION ALL
SELECT 
	'order_items', 
    COUNT(*) FROM order_items
UNION ALL
SELECT 
	'order_reviews', 
    COUNT(*) FROM order_reviews
UNION ALL
SELECT 
	'order_payments', 
    COUNT(*) FROM order_payments
UNION ALL
SELECT 
	'customers', 
    COUNT(*) FROM customers
UNION ALL
SELECT 
	'products', 
    COUNT(*) FROM products;

-- cek missing value
SELECT
    COUNT(*) AS total_orders,
    SUM(CASE WHEN order_delivered_customer_date IS NULL THEN 1 ELSE 0 END) AS missing_delivered_date,
    SUM(CASE WHEN order_approved_at IS NULL THEN 1 ELSE 0 END) AS missing_approved_date,
    SUM(CASE WHEN order_estimated_delivery_date IS NULL THEN 1 ELSE 0 END) AS missing_estimated_date
FROM orders;

SELECT order_status, COUNT(*) AS jumlah
FROM orders
WHERE order_delivered_customer_date IS NULL
GROUP BY order_status
ORDER BY jumlah DESC;

SELECT
    COUNT(*) AS total_reviews,
    SUM(CASE WHEN review_score IS NULL THEN 1 ELSE 0 END) AS missing_score,
    SUM(CASE WHEN review_comment_message IS NULL THEN 1 ELSE 0 END) AS missing_comment
FROM order_reviews;

-- cek order_id yang > 1 di reviews 
SELECT order_id, COUNT(*) AS jumlah
FROM order_reviews
GROUP BY order_id
HAVING COUNT(*) > 1;

SELECT COUNT(*) AS total_rows FROM order_reviews;
SELECT COUNT(DISTINCT order_id) AS unique_orders_reviewed FROM order_reviews;

SELECT order_id, review_id, review_score, review_creation_date, review_answer_timestamp
FROM order_reviews
WHERE order_id IN (
    SELECT order_id FROM order_reviews GROUP BY order_id HAVING COUNT(*) > 1
)
ORDER BY order_id, review_creation_date
LIMIT 20;

-- cek duplikat exact row
SELECT order_id, review_id, COUNT(*) 
FROM order_reviews
GROUP BY order_id, review_id, review_score
HAVING COUNT(*) > 1;

SELECT order_status, COUNT(*) AS jumlah,
       ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM orders), 2) AS persentase
FROM orders
GROUP BY order_status
ORDER BY jumlah DESC;

-- order yang tidak punya order_items (potensi data tidak lengkap)
SELECT COUNT(*) AS orders_without_items
FROM orders o
LEFT JOIN order_items oi ON o.order_id = oi.order_id
WHERE oi.order_id IS NULL;

SELECT o.order_status, COUNT(*) AS jumlah
FROM orders o
LEFT JOIN order_items oi ON o.order_id = oi.order_id
WHERE oi.order_id IS NULL
GROUP BY o.order_status;

-- order delivered yang tidak punya review
SELECT COUNT(*) AS delivered_without_review
FROM orders oS
LEFT JOIN order_reviews r ON o.order_id = r.order_id
WHERE o.order_status = 'delivered' AND r.order_id IS NULL;

SELECT 
    MIN(order_purchaseS_timestamp) AS earliest_order,
    MAX(order_purchase_timestamp) AS latest_order
FROM orders;

