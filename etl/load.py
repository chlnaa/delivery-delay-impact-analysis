import pandas as pd
from etl.db import engine

def load_customers(df: pd.DataFrame) -> None:
    df.to_sql('customers', engine, if_exists='append', index=False)
    print(f"customers loaded: {len(df)} rows")

def load_orders(df: pd.DataFrame) -> None:
    df.to_sql('orders', engine, if_exists='append', index=False)
    print(f"orders loaded: {len(df)} rows")

def load_order_items(df: pd.DataFrame) -> None:
    df.to_sql('order_items', engine, if_exists='append', index=False)
    print(f"order_items loaded: {len(df)} rows")

def load_reviews(df: pd.DataFrame) -> None:
    # Filter to order_ids that exist in orders table to prevent FK violation
    existing = pd.read_sql('SELECT order_id FROM orders', engine)
    df = df[df['order_id'].isin(existing['order_id'])]
    df.to_sql('reviews', engine, if_exists='append', index=False)
    print(f"reviews loaded: {len(df)} rows")

def load_payments(df: pd.DataFrame) -> None:
    # Filter to order_ids that exist in orders table to prevent FK violation
    existing = pd.read_sql('SELECT order_id FROM orders', engine)
    df = df[df['order_id'].isin(existing['order_id'])]
    df.to_sql('payments', engine, if_exists='append', index=False)
    print(f"payments loaded: {len(df)} rows")