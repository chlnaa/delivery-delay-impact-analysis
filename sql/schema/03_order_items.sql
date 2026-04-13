CREATE TABLE IF NOT EXISTS order_items (
    order_id             VARCHAR(50)   NOT NULL REFERENCES orders(order_id),
    order_item_id        INTEGER       NOT NULL,
    product_id           VARCHAR(50),
    seller_id            VARCHAR(50),
    shipping_limit_date  TIMESTAMP,
    price                NUMERIC(10,2) NOT NULL,
    freight_value        NUMERIC(10,2) NOT NULL,
    PRIMARY KEY (order_id, order_item_id)
);