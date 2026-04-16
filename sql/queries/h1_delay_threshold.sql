-- H1: Find the delay threshold where at-risk customer ratio increases significantly
-- At-risk customer = review_score <= 2 (proxy for churn)
--
-- Delay groups (aligned with 02_hypothesis_testing.ipynb bins):
--   on_time    : delay_days <= 0   (early or exact delivery)
--   slight     : 1  ~ 3 days
--   moderate   : 4  ~ 7 days
--   severe     : 8  ~ 14 days
--   extreme    : 15 days +

WITH order_delay AS (
    SELECT
        o.order_id,
        o.customer_id,
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
        CASE
            WHEN d.delay_days <= 0             THEN 'on_time'
            WHEN d.delay_days BETWEEN 1  AND 3 THEN 'slight(1~3)'
            WHEN d.delay_days BETWEEN 4  AND 7 THEN 'moderate(4~7)'
            WHEN d.delay_days BETWEEN 8  AND 14 THEN 'severe(8~14)'
            ELSE                                     'extreme(15+)'
        END                                         AS delay_group,
        CASE WHEN r.review_score <= 2 THEN 1 ELSE 0 END AS is_at_risk
    FROM order_delay d
    LEFT JOIN reviews r ON d.order_id = r.order_id
)
SELECT
    delay_group,
    COUNT(*)                                    AS order_count,
    SUM(is_at_risk)                             AS at_risk_count,
    ROUND(AVG(is_at_risk) * 100, 2)             AS at_risk_ratio
FROM order_risk
GROUP BY delay_group
ORDER BY
    CASE delay_group
        WHEN 'on_time'       THEN 1
        WHEN 'slight(1~3)'   THEN 2
        WHEN 'moderate(4~7)' THEN 3
        WHEN 'severe(8~14)'  THEN 4
        WHEN 'extreme(15+)'  THEN 5
    END;