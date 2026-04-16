-- H2: Compare at-risk ratio between delayed vs on-time delivery customers
-- (Renamed from h2_repurchase_rate.sql — actual analysis is at-risk ratio comparison,
--  not repurchase rate. Aligned with 02_hypothesis_testing.ipynb H2 section.)
--
-- At-risk customer = review_score <= 2 (proxy for churn)
-- Delivery group  : delayed = delay_days > 0, on_time = delay_days <= 0

WITH order_delay AS (
    SELECT
        o.order_id,
        EXTRACT(DAY FROM (
            o.order_delivered_customer_date - o.order_estimated_delivery_date
        ))::INT AS delay_days
    FROM orders o
    WHERE o.order_delivered_customer_date IS NOT NULL
      AND o.order_estimated_delivery_date IS NOT NULL
),
order_risk AS (
    SELECT
        d.order_id,
        CASE WHEN d.delay_days > 0 THEN 'delayed' ELSE 'on_time' END AS delivery_group,
        CASE WHEN r.review_score <= 2 THEN 1 ELSE 0 END AS is_at_risk
    FROM order_delay d
    LEFT JOIN reviews r ON d.order_id = r.order_id
)
SELECT
    delivery_group,
    COUNT(*)                            AS order_count,
    SUM(is_at_risk)                     AS at_risk_count,
    ROUND(AVG(is_at_risk) * 100, 2)     AS at_risk_ratio
FROM order_risk
GROUP BY delivery_group
ORDER BY delivery_group;