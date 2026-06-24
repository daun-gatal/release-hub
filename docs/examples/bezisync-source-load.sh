#!/bin/sh
set -u

PGHOST="${PGHOST:-source-postgres}"
PGUSER="${PGUSER:-bezisync}"
PGDATABASE="${PGDATABASE:-appdb}"
LOAD_INTERVAL="${LOAD_INTERVAL:-5}"
MAX_ROWS="${MAX_ROWS:-100}"
export PGPASSWORD="${PGPASSWORD:-password}"

psql_src() {
  psql -h "$PGHOST" -U "$PGUSER" -d "$PGDATABASE" "$@"
}

echo "source-load: waiting for ${PGHOST}/${PGDATABASE} ..."
until psql_src -c 'SELECT 1' >/dev/null 2>&1; do
  sleep 2
done
echo "source-load: emitting changes every ${LOAD_INTERVAL}s"

while true; do
  psql_src -q -v "max_rows=${MAX_ROWS}" <<'SQL' || echo "source-load: psql error; retrying"
INSERT INTO public.orders (customer, amount_cents, status)
VALUES (
  (ARRAY['alice','bob','carol','dave','erin','frank','grace','heidi'])[floor(random()*8)+1],
  floor(random()*9900)::int + 100,
  (ARRAY['pending','paid','shipped','refunded'])[floor(random()*4)+1]
);

UPDATE public.orders
   SET status = (ARRAY['pending','paid','shipped','refunded'])[floor(random()*4)+1],
       amount_cents = amount_cents + 1
 WHERE id = (SELECT id FROM public.orders ORDER BY random() LIMIT 1);

DELETE FROM public.orders
 WHERE id IN (
   SELECT id FROM public.orders ORDER BY id DESC OFFSET :max_rows
 );
SQL
  sleep "$LOAD_INTERVAL"
done
