CREATE TABLE IF NOT EXISTS reviews (
    review_id                VARCHAR(50) PRIMARY KEY,
    order_id                 VARCHAR(50) NOT NULL REFERENCES orders(order_id),
    review_score             SMALLINT CHECK (review_score BETWEEN 1 AND 5),
    review_comment_title     TEXT,
    review_comment_message   TEXT,
    review_creation_date     TIMESTAMP,
    review_answer_timestamp  TIMESTAMP
);