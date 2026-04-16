CREATE TABLE IF NOT EXISTS event_logs (
    event_id        SERIAL PRIMARY KEY,
    customer_id     VARCHAR(50) NOT NULL,
    order_id        VARCHAR(50),
    event_type      VARCHAR(30) NOT NULL,
    event_timestamp TIMESTAMP   NOT NULL,
    delay_days      INT,
    review_score    INT,
    is_repurchase   BOOLEAN     NOT NULL DEFAULT FALSE
);

CREATE INDEX IF NOT EXISTS idx_event_logs_customer_id
    ON event_logs (customer_id);

CREATE INDEX IF NOT EXISTS idx_event_logs_event_type
    ON event_logs (event_type);