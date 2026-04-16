import pandas as pd
import numpy as np
from datetime import timedelta
from sqlalchemy import text
import sys
import os

sys.path.append(os.path.abspath('../..'))
from etl.db import engine

np.random.seed(42)

# ── 1. Load existing data ─────────────────────────────────────────
orders  = pd.read_sql('SELECT * FROM orders',  engine)
reviews = pd.read_sql('SELECT * FROM reviews', engine)

# ── 2. Preprocessing ─────────────────────────────────────────────
delivered = orders.dropna(subset=[
    'order_delivered_customer_date',
    'order_estimated_delivery_date'
]).copy()

delivered['delay_days'] = (
    delivered['order_delivered_customer_date'] -
    delivered['order_estimated_delivery_date']
).dt.days

review_agg = reviews.groupby('order_id').agg(
    review_score=('review_score', 'min')
).reset_index()

merged = delivered.merge(review_agg, on='order_id', how='left')

# ── 3. Simulate repurchase probability ───────────────────────────
# Assign repurchase probability based on review score and delay status
def repurchase_prob(row):
    score = row['review_score']
    delay = row['delay_days']
    if pd.isna(score):
        base = 0.15
    elif score >= 4:
        base = 0.40
    elif score == 3:
        base = 0.20
    else:
        base = 0.08          # score <= 2 (at-risk)

    if delay > 0:
        base *= 0.6          # 40% reduction in repurchase rate if delayed
    return base

merged['repurchase_prob'] = merged.apply(repurchase_prob, axis=1)
merged['is_repurchase']   = np.random.binomial(1, merged['repurchase_prob'])

# ── 4. Generate event logs ───────────────────────────────────────
records = []

for _, row in merged.iterrows():
    cid = row['customer_id']
    oid = row['order_id']
    base_ts = row['order_purchase_timestamp']

    # event 1: order_placed
    records.append({
        'customer_id':     cid,
        'order_id':        oid,
        'event_type':      'order_placed',
        'event_timestamp': base_ts,
        'delay_days':      None,
        'review_score':    None,
        'is_repurchase':   False,
    })

    # event 2: order_delivered
    records.append({
        'customer_id':     cid,
        'order_id':        oid,
        'event_type':      'order_delivered',
        'event_timestamp': row['order_delivered_customer_date'],
        'delay_days':      int(row['delay_days']),
        'review_score':    None,
        'is_repurchase':   False,
    })

    # event 3: review_submitted (only if review exists)
    if pd.notna(row['review_score']):
        records.append({
            'customer_id':     cid,
            'order_id':        oid,
            'event_type':      'review_submitted',
            'event_timestamp': row['order_delivered_customer_date'] + timedelta(days=2),
            'delay_days':      int(row['delay_days']),
            'review_score':    int(row['review_score']),
            'is_repurchase':   False,
        })

    # event 4: repurchase (simulated)
    if row['is_repurchase']:
        repurchase_ts = row['order_delivered_customer_date'] + timedelta(
            days=int(np.random.randint(7, 60))
        )
        records.append({
            'customer_id':     cid,
            'order_id':        None,   # no order_id since this is a new order
            'event_type':      'repurchase',
            'event_timestamp': repurchase_ts,
            'delay_days':      None,
            'review_score':    None,
            'is_repurchase':   True,
        })

# ── 5. Convert to DataFrame ──────────────────────────────────────
event_df = pd.DataFrame(records)
event_df['event_timestamp'] = pd.to_datetime(event_df['event_timestamp'])

print(f"total events : {len(event_df):,}")
print(event_df['event_type'].value_counts())
print(f"repurchase   : {event_df['is_repurchase'].sum():,}")

# ── 6. Load into DB ──────────────────────────────────────────────
with engine.begin() as conn:
    conn.execute(text("TRUNCATE TABLE event_logs RESTART IDENTITY"))

event_df.to_sql(
    'event_logs',
    engine,
    if_exists='append',
    index=False,
    method='multi',
    chunksize=1000,
)

print("event_logs loaded successfully.")