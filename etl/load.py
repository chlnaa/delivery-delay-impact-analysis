import pandas as pd
from sqlalchemy import text
from etl.db import engine

def _table_has_data(table_name: str) -> bool:
    with engine.connect() as conn:
        result = conn.execute(text(f"SELECT COUNT(*) FROM {table_name}"))
        return result.scalar() > 0

def load_customers(df: pd.DataFrame) -> None:
    if _table_has_data('customers'):
        print("customers already loaded, skipping")
        return
    df.to_sql('customers', engine, if_exists='append', index=False)
    print(f"customers loaded: {len(df)} rows")

def load_orders(df: pd.DataFrame) -> None:
    if _table_has_data('orders'):
        print("orders already loaded, skipping")
        return
    df.to_sql('orders', engine, if_exists='append', index=False)
    print(f"orders loaded: {len(df)} rows")

def load_order_items(df: pd.DataFrame) -> None:
    if _table_has_data('order_items'):
        print("order_items already loaded, skipping")
        return
    df.to_sql('order_items', engine, if_exists='append', index=False)
    print(f"order_items loaded: {len(df)} rows")

def load_reviews(df: pd.DataFrame) -> None:
    if _table_has_data('reviews'):
        print("reviews already loaded, skipping")
        return
    existing = pd.read_sql('SELECT order_id FROM orders', engine)
    df = df[df['order_id'].isin(existing['order_id'])]
    df.to_sql('reviews', engine, if_exists='append', index=False)
    print(f"reviews loaded: {len(df)} rows")

def load_payments(df: pd.DataFrame) -> None:
    if _table_has_data('payments'):
        print("payments already loaded, skipping")
        return
    existing = pd.read_sql('SELECT order_id FROM orders', engine)
    df = df[df['order_id'].isin(existing['order_id'])]
    df.to_sql('payments', engine, if_exists='append', index=False)
    print(f"payments loaded: {len(df)} rows")