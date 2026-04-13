CREATE TABLE IF NOT EXISTS customers (
    customer_id           VARCHAR(50)  PRIMARY KEY,
    customer_unique_id    VARCHAR(50)  NOT NULL,
    zip_code_prefix       INTEGER,
    city                  VARCHAR(100),
    state                 CHAR(2)
);