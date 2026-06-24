-- Demo source schema for the Docker-in-Docker simulation.
-- The Postgres container starts with wal_level=logical from compose.

CREATE TABLE IF NOT EXISTS public.orders (
    id           SERIAL PRIMARY KEY,
    customer     TEXT        NOT NULL,
    amount_cents INTEGER     NOT NULL,
    status       TEXT        NOT NULL DEFAULT 'pending',
    created_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);

INSERT INTO public.orders (customer, amount_cents, status) VALUES
    ('alice', 1299, 'paid'),
    ('bob', 4999, 'pending'),
    ('carol', 799, 'shipped')
ON CONFLICT DO NOTHING;

ALTER TABLE public.orders REPLICA IDENTITY FULL;
