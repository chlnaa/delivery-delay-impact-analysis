import pandas as pd
from etl.db import engine

def load_customers(df: pd.DataFrame) -> None:
    df.to_sql('customers', engine, if_exists='append', index=False)
    print(f"✅ customers loaded: {len(df)} rows")

def load_orders(df: pd.DataFrame) -> None:
    df.to_sql('orders', engine, if_exists='append', index=False)
    print(f"✅ orders loaded: {len(df)} rows")

def load_order_items(df: pd.DataFrame) -> None:
    df.to_sql('order_items', engine, if_exists='append', index=False)
    print(f"✅ order_items loaded: {len(df)} rows")