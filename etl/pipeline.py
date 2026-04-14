from etl.extract import (
    extract_customers, extract_orders, extract_order_items,
    extract_reviews, extract_payments
)
from etl.transform import (
    transform_customers, transform_orders, transform_order_items,
    transform_reviews, transform_payments
)
from etl.load import (
    load_customers, load_orders, load_order_items,
    load_reviews, load_payments
)

def run_pipeline():
    print("=== ETL Pipeline Start ===")

    print("\n[1/5] customers")
    load_customers(transform_customers(extract_customers()))

    print("\n[2/5] orders")
    load_orders(transform_orders(extract_orders()))

    print("\n[3/5] order_items")
    load_order_items(transform_order_items(extract_order_items()))

    print("\n[4/5] reviews")
    load_reviews(transform_reviews(extract_reviews()))

    print("\n[5/5] payments")
    load_payments(transform_payments(extract_payments()))

    print("\n=== ETL Pipeline Complete ===")

if __name__ == "__main__":
    run_pipeline()