import pandas as pd
import os

RAW_DIR = os.path.join(os.path.dirname(__file__), '..', 'data', 'raw')

def extract_customers() -> pd.DataFrame:
    return pd.read_csv(os.path.join(RAW_DIR, 'olist_customers_dataset.csv'))

def extract_orders() -> pd.DataFrame:
    return pd.read_csv(os.path.join(RAW_DIR, 'olist_orders_dataset.csv'))

def extract_order_items() -> pd.DataFrame:
    return pd.read_csv(os.path.join(RAW_DIR, 'olist_order_items_dataset.csv'))