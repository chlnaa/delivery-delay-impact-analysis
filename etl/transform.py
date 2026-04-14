import pandas as pd

def transform_customers(df: pd.DataFrame) -> pd.DataFrame:
    df = df.rename(columns={
        'customer_zip_code_prefix': 'zip_code_prefix',
        'customer_city': 'city',
        'customer_state': 'state'
    })
    return df

def transform_orders(df: pd.DataFrame) -> pd.DataFrame:
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
    df['shipping_limit_date'] = pd.to_datetime(
        df['shipping_limit_date'], errors='coerce'
    )
    return df

def transform_reviews(df: pd.DataFrame) -> pd.DataFrame:
    datetime_cols = ['review_creation_date', 'review_answer_timestamp']
    for col in datetime_cols:
        df[col] = pd.to_datetime(df[col], errors='coerce')

    df = df.drop_duplicates(subset=['review_id'])
    df = df.dropna(subset=['order_id'])

    return df[[
        'review_id', 'order_id', 'review_score',
        'review_comment_title', 'review_comment_message',
        'review_creation_date', 'review_answer_timestamp'
    ]]

def transform_payments(df: pd.DataFrame) -> pd.DataFrame:
    df = df.drop_duplicates(subset=['order_id', 'payment_sequential'])
    df = df.dropna(subset=['order_id'])

    return df[[
        'order_id', 'payment_sequential',
        'payment_type', 'payment_installments', 'payment_value'
    ]]