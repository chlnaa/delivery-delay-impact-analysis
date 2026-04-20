CREATE TABLE  IF NOT EXISTS payments (
	order_id text NULL,
	payment_sequential int8 NULL,
	payment_type text NULL,
	payment_installments int8 NULL,
	payment_value float8 NULL
);