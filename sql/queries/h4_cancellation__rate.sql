-- H4: Cancellation rate by expected wait days
-- (Aligned with 02_hypothesis_testing.ipynb H4 section)
--
-- ※ Data structure limitation:
--   canceled orders have no order_delivered_customer_date (NULL),
--   so delay_days (actual delay) cannot be calculated.
--   expected_wait_days (purchase → estimated delivery) is used as a proxy instead.
--   Results reflect the relationship between perceived wait time and cancellation behavior,
--   not actual delivery delay vs cancellation.
--
-- Wait groups (aligned with notebook pd.cut bins):
--   ~10d  :  1 ~ 10 days
--   ~20d  : 11 ~ 20 days
--   ~30d  : 21 ~ 30 days
--   ~40d  : 31 ~ 40 days
--   40d+  : 41 days +

WITH order_wait AS (
    SELECT
        o.order_id,
        o.order_status,
        EXTRACT(DAY FROM (
            o.order_estimated_delivery_date - o.order_purchase_timestamp
        ))::INT                                         AS expected_wait_days,
        CASE WHEN o.order_status = 'canceled' THEN 1 ELSE 0 END AS is_canceled
    FROM orders o
    WHERE o.order_estimated_delivery_date IS NOT NULL
      AND o.order_purchase_timestamp IS NOT NULL
),
order_wait_grouped AS (
    SELECT
        order_id,
        is_canceled,
        expected_wait_days,
        CASE
            WHEN expected_wait_days BETWEEN 1  AND 10 THEN '~10d'
            WHEN expected_wait_days BETWEEN 11 AND 20 THEN '~20d'
            WHEN expected_wait_days BETWEEN 21 AND 30 THEN '~30d'
            WHEN expected_wait_days BETWEEN 31 AND 40 THEN '~40d'
            WHEN expected_wait_days > 40               THEN '40d+'
            ELSE NULL  -- exclude rows where purchase date >= estimated delivery date
        END AS wait_group
    FROM order_wait
)
SELECT
    wait_group,
    COUNT(*)                                    AS order_count,
    SUM(is_canceled)                            AS canceled_count,
    ROUND(AVG(is_canceled) * 100, 2)            AS cancel_rate
FROM order_wait_grouped
WHERE wait_group IS NOT NULL
GROUP BY wait_group
ORDER BY
    CASE wait_group
        WHEN '~10d' THEN 1
        WHEN '~20d' THEN 2
        WHEN '~30d' THEN 3
        WHEN '~40d' THEN 4
        WHEN '40d+' THEN 5
    END;