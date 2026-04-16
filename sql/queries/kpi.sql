-- =============================================================
-- KPI Dashboard Query
-- Dataset : Olist Brazilian E-Commerce
-- Updated : 2026-04
-- =============================================================
-- KPIs
--   1. ARPU               — Average Revenue Per Order (delivered orders only)
--   2. delivery_delay_rate — ratio of delayed deliveries
--   3. at_risk_ratio       — ratio of at-risk customers (review_score <= 2, proxy for churn)
--   4. cancellation_rate   — ratio of canceled orders
--
-- Denominator policy
--   ARPU / delay rate / at-risk ratio : delivered orders with both dates present (same base as h2, h3)
--   cancellation rate                 : all orders regardless of status (cancellations occur before delivery)
-- =============================================================

WITH delivered_orders AS (
    -- delay: EXTRACT(DAY)::INT > 0  (timestamp direct comparison excluded;
    -- order_estimated_delivery_date has no time component → same-day delivery
    -- would be misclassified as delayed)
    SELECT
        o.order_id,
        o.customer_id,
        o.order_status,
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
order_revenue AS (
    SELECT
        p.order_id,
        SUM(p.payment_value) AS order_value
    FROM payments p
    GROUP BY p.order_id
),
order_risk AS (
    -- MIN(review_score) + GROUP BY to deduplicate orders with multiple reviews
    -- orders without a review are treated as is_at_risk = 0 (churn risk underestimated)
    SELECT
        d.order_id,
        d.delivery_group,
        CASE WHEN MIN(r.review_score) <= 2 THEN 1 ELSE 0 END AS is_at_risk
    FROM delivered_orders d
    LEFT JOIN reviews r ON d.order_id = r.order_id
    GROUP BY d.order_id, d.delivery_group
),
all_orders AS (
    SELECT
        order_id,
        CASE WHEN order_status = 'canceled' THEN 1 ELSE 0 END AS is_canceled
    FROM orders
),
kpi_arpu AS (
    SELECT
        COUNT(rev.order_id)                    AS arpu_base_orders,
        ROUND(SUM(rev.order_value)::NUMERIC, 2) AS total_revenue,
        ROUND(AVG(rev.order_value)::NUMERIC, 2) AS arpu
    FROM order_revenue rev
    INNER JOIN delivered_orders d ON rev.order_id = d.order_id
),
kpi_delay AS (
    SELECT
        COUNT(*)                                                     AS evaluable_orders,
        SUM(CASE WHEN delivery_group = 'delayed' THEN 1 ELSE 0 END) AS delayed_orders,
        ROUND(
            SUM(CASE WHEN delivery_group = 'delayed' THEN 1 ELSE 0 END)
            * 100.0 / COUNT(*), 2)                                   AS delivery_delay_rate
    FROM delivered_orders
),
kpi_at_risk AS (
    -- evaluable_orders: all delivered orders (denominator for at_risk_ratio)
    -- at_risk_delayed_orders: used only for at_risk_ratio_in_delayed (H2 reproduction)
    SELECT
        COUNT(*)                                                            AS evaluable_orders,
        SUM(is_at_risk)                                                     AS at_risk_orders,
        ROUND(AVG(is_at_risk) * 100, 2)                                     AS at_risk_ratio,
        SUM(CASE WHEN delivery_group = 'delayed' AND is_at_risk = 1
            THEN 1 ELSE 0 END)                                              AS at_risk_delayed_orders
    FROM order_risk
),
kpi_cancel AS (
    SELECT
        COUNT(*)                                               AS total_orders,
        SUM(is_canceled)                                       AS canceled_orders,
        ROUND(SUM(is_canceled) * 100.0 / COUNT(*), 2)         AS cancellation_rate
    FROM all_orders
)
SELECT
    a.arpu_base_orders,
    a.total_revenue,
    a.arpu,
    d.evaluable_orders,
    d.delayed_orders,
    d.delivery_delay_rate,
    r.at_risk_orders,
    r.at_risk_ratio,
    c.total_orders,
    c.canceled_orders,
    c.cancellation_rate,
    -- ※ denominator = delayed_orders (not at_risk_orders)
    -- reproduces H2 result: at-risk ratio within delayed group (~60.61%)
    ROUND(
    r.at_risk_delayed_orders * 100.0 / NULLIF(d.delayed_orders, 0),2) AS at_risk_ratio_in_delayed                                                
FROM kpi_arpu   a
CROSS JOIN kpi_delay   d
CROSS JOIN kpi_at_risk r
CROSS JOIN kpi_cancel  c;