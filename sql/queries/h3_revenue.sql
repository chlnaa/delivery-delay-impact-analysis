-- H3: Estimate revenue loss caused by delivery delays
-- Loss proxy = at-risk customers (review_score <= 2) from delayed orders × their actual payment
--
-- ※ ARPU base: delivered orders only (same as notebook merged_rev)
--   limited to orders where both delivery dates exist, not all payments
-- ※ at_risk is a proxy — unreviewed dissatisfied customers not captured
--   actual loss is likely underestimated

WITH delivered_orders AS (
    SELECT
        o.order_id,
        o.customer_id,
        CASE
            WHEN EXTRACT(DAY FROM (
                o.order_delivered_customer_date - o.order_estimated_delivery_date
            ))::INT > 0
            THEN 'delayed'
            ELSE 'on_time'
        END AS delivery_group
    FROM orders o
    WHERE o.order_delivered_customer_date IS NOT NULL
      AND o.order_estimated_delivery_date IS NOT NULL
),
order_risk AS (
    SELECT
        d.order_id,
        d.customer_id,
        d.delivery_group,
        CASE WHEN MIN(r.review_score) <= 2 THEN 1 ELSE 0 END AS is_at_risk
    FROM delivered_orders d
    LEFT JOIN reviews r ON d.order_id = r.order_id
    GROUP BY d.order_id, d.customer_id, d.delivery_group
),
revenue AS (
    SELECT
        p.order_id,
        SUM(p.payment_value) AS order_revenue
    FROM payments p
    GROUP BY p.order_id
),
arpu AS (
    SELECT
        ROUND(AVG(r.order_revenue)::NUMERIC, 2) AS avg_revenue_per_order
    FROM revenue r
    INNER JOIN delivered_orders d ON r.order_id = d.order_id
),
total_revenue AS (
    SELECT SUM(r.order_revenue) AS total
    FROM revenue r
    INNER JOIN delivered_orders d ON r.order_id = d.order_id
),
at_risk_revenue AS (
    SELECT SUM(rev.order_revenue) AS at_risk_total
    FROM order_risk risk
    JOIN revenue rev ON risk.order_id = rev.order_id
    WHERE risk.delivery_group = 'delayed'
      AND risk.is_at_risk = 1
)
SELECT
    ROUND(ar.at_risk_total::NUMERIC, 2)                              AS estimated_loss,
    ROUND(tr.total::NUMERIC, 2)                                      AS total_revenue,
    ROUND((ar.at_risk_total / tr.total * 100)::NUMERIC, 2)           AS loss_ratio_pct,
    ROUND(a.avg_revenue_per_order::NUMERIC, 2)                       AS arpu,
    CASE
        WHEN ar.at_risk_total / tr.total * 100 >= 5
        THEN 'H3 supported — loss ratio >= 5%'
        ELSE 'H3 rejected — loss ratio < 5% (proxy underestimate possible)'
    END                                                               AS judgment
FROM at_risk_revenue ar, total_revenue tr, arpu a;