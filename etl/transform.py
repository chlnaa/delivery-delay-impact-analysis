import pandas as pd

def transform_customers(df: pd.DataFrame) -> pd.DataFrame:
    # Rename columns to match DB schema
    df = df.rename(columns={
        'customer_zip_code_prefix': 'zip_code_prefix',
        'customer_city': 'city',
        'customer_state': 'state'
    })
    return df

def transform_orders(df: pd.DataFrame) -> pd.DataFrame:
    # Convert timestamp columns from string to datetime
    timestamp_cols = [
        'order_purchase_timestamp',
        'order_approved_at',
        'order_delivered_carrier_date',
        'order_delivered_customer_date',
        'order_estimated_delivery_date'
    ]
    for col in timestamp_cols:
        df[col] = pd.to_datetime(df[col], errors='coerce')
    return df

def transform_order_items(df: pd.DataFrame) -> pd.DataFrame:
    # Convert shipping_limit_date from string to datetime
    df['shipping_limit_date'] = pd.to_datetime(
        df['shipping_limit_date'], errors='coerce'
    )
    return df