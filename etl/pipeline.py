from etl.extract import extract_customers, extract_orders, extract_order_items
from etl.transform import transform_customers, transform_orders, transform_order_items
from etl.load import load_customers, load_orders, load_order_items

def run_pipeline():
    print("=== ETL Pipeline Start ===")

    # Customers
    print("\n[1/3] customers")
    df_customers = extract_customers()
    df_customers = transform_customers(df_customers)
    load_customers(df_customers)

    # Orders
    print("\n[2/3] orders")
    df_orders = extract_orders()
    df_orders = transform_orders(df_orders)
    load_orders(df_orders)

    # Order items
    print("\n[3/3] order_items")
    df_order_items = extract_order_items()
    df_order_items = transform_order_items(df_order_items)
    load_order_items(df_order_items)

    print("\n=== ETL Pipeline Complete ===")

if __name__ == "__main__":
    run_pipeline()