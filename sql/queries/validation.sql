-- =============================================
-- 1. Row count validation
-- =============================================
SELECT 'customers'   AS table_name, COUNT(*) AS row_count FROM customers
UNION ALL
SELECT 'orders'      AS table_name, COUNT(*) AS row_count FROM orders
UNION ALL
SELECT 'order_items' AS table_name, COUNT(*) AS row_count FROM order_items;


-- =============================================
-- 2. Missing value check
-- =============================================

-- orders: nullable columns
SELECT
    COUNT(*) FILTER (WHERE order_approved_at IS NULL)             AS missing_approved_at,
    COUNT(*) FILTER (WHERE order_delivered_carrier_date IS NULL)  AS missing_carrier_date,
    COUNT(*) FILTER (WHERE order_delivered_customer_date IS NULL) AS missing_customer_date
FROM orders;


-- =============================================
-- 3. Date range check
-- =============================================
SELECT
    MIN(order_purchase_timestamp) AS earliest_order,
    MAX(order_purchase_timestamp) AS latest_order
FROM orders;


-- =============================================
-- 4. Order status distribution
-- =============================================
SELECT
    order_status,
    COUNT(*) AS count
FROM orders
GROUP BY order_status
ORDER BY count DESC;


-- =============================================
-- 5. FK integrity check
-- =============================================

-- orders → customers 참조 깨진 것 확인
SELECT COUNT(*) AS orphaned_orders
FROM orders o
LEFT JOIN customers c ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL;

-- order_items → orders 참조 깨진 것 확인
SELECT COUNT(*) AS orphaned_order_items
FROM order_items oi
LEFT JOIN orders o ON oi.order_id = o.order_id
WHERE o.order_id IS NULL;