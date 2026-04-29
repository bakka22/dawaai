---
name: postgresql
description: Comprehensive PostgreSQL guidance covering schema design, basic and advanced SQL, performance tuning, indexing strategies (B-tree, GIN, GiST, trigram), fuzzy search, full-text search, JSONB, geospatial, partitioning, connection pooling, transaction management, security, monitoring, and Node.js (pg) integration. Use when designing, optimizing, or troubleshooting any PostgreSQL database.
license: MIT
compatibility: PostgreSQL 12+, Node.js/Express, pg library
metadata:
  keywords: sql, indexing, performance, postgres, pg_trgm, jsonb, geospatial
---

# PostgreSQL Master Skill

You are a seasoned PostgreSQL expert and database architect. When called upon, always provide production‑ready SQL, explain the "why" behind design choices, and flag any trade‑offs (performance vs. maintainability, immediate consistency vs. eventual). Your answers must be concrete, with executable code examples, and assume the reader is building a real system, not merely a toy.

## 1. Core Philosophy & Best Practices

- **Normalize first; denormalize only for provable performance gains** – Keep data integrity; use JSONB for truly schema‑less or sparse attributes.
- **Choose the right data types** – `TEXT` vs `VARCHAR`, `UUID` vs `BIGSERIAL`, `TIMESTAMPTZ` for time zones.
- **Name objects consistently** – snake_case for tables/columns; plural table names; indexes `ix_tablename_column`.
- **Every table has a primary key** – prefer `BIGINT GENERATED ALWAYS AS IDENTITY` or `UUID` if distributed.
- **Use foreign keys** – enforce referential integrity; ON DELETE/UPDATE rules specified explicitly.
- **Migrate with versioned SQL scripts** – never hand‑alter production; use tools like `node-pg-migrate` or raw `.sql` files in version control.

## 2. Database Setup & Extensions

```sql
-- Enable essential extensions
CREATE EXTENSION IF NOT EXISTS pg_trgm;        -- trigram fuzzy matching
CREATE EXTENSION IF NOT EXISTS unaccent;       -- ignore accents (use with pg_trgm)
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";    -- UUID generation
CREATE EXTENSION IF NOT EXISTS postgis;        -- geospatial (if needed)
Key usage: pg_trgm + unaccent for Arabic/English fuzzy search (see Section 5).
Check installed extensions:

sql
SELECT extname FROM pg_extension;
3. Schema Design Patterns
3.1 Users, Pharmacies, Inventory (as in Dawaai)
sql
CREATE TABLE users (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  phone TEXT NOT NULL UNIQUE,
  role TEXT NOT NULL CHECK (role IN ('customer', 'pharmacist', 'driver', 'admin')),
  refresh_token_hash TEXT,
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE pharmacies (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  owner_id BIGINT NOT NULL REFERENCES users(id),
  name TEXT NOT NULL,
  lat DOUBLE PRECISION NOT NULL,
  lng DOUBLE PRECISION NOT NULL,
  city TEXT NOT NULL,
  is_approved BOOLEAN DEFAULT false,
  opening_time TIME DEFAULT '08:00',
  closing_time TIME DEFAULT '22:00'
  -- For spatial indexing use PostGIS geometry column later
);

CREATE TABLE medication_master (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  name TEXT NOT NULL,
  active_ingredient TEXT NOT NULL,
  synonyms JSONB DEFAULT '[]',   -- e.g., ["Panadol", "Paracetamol", "بندول"]
  is_flagged BOOLEAN DEFAULT false
);

CREATE TABLE pharmacy_inventory (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  pharmacy_id BIGINT REFERENCES pharmacies(id) ON DELETE CASCADE,
  medication_id BIGINT REFERENCES medication_master(id),
  is_in_stock BOOLEAN DEFAULT true,
  price NUMERIC(10,2) CHECK (price >= 0),
  UNIQUE (pharmacy_id, medication_id)
);
3.2 Audit Trail
Add created_at, updated_at columns automatically:

sql
-- trigger function
CREATE OR REPLACE FUNCTION update_modified_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- apply to any table needing it
CREATE TRIGGER trg_users_updated
  BEFORE UPDATE ON users
  FOR EACH ROW EXECUTE FUNCTION update_modified_column();
4. Basic & Intermediate Query Techniques
Window functions for rankings and running totals.

Common Table Expressions (CTEs) with WITH ... AS for readability, but know they are optimisation fences in PG <12; use MATERIALIZED / NOT MATERIALIZED hints in PG12+.

Lateral joins for correlated subqueries that return multiple columns.

Aggregate filters – COUNT(*) FILTER (WHERE status = 'completed').

JSONB operations for synonyms array: synonyms @> '"Panadol"'::jsonb or synonyms ? 'Panadol'.

Example: find active quote responses count per pharmacy:

sql
SELECT pharmacy_id, COUNT(*) FILTER (WHERE status = 'submitted') AS bids
FROM quote_responses
GROUP BY pharmacy_id;
5. Text Search & Fuzzy Matching (Crucial for Arabic)
5.1 Trigram Indexes and similarity()
sql
CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE INDEX idx_med_name_trgm ON medication_master USING GIN (name gin_trgm_ops);
CREATE INDEX idx_med_ingredient_trgm ON medication_master USING GIN (active_ingredient gin_trgm_ops);
Search with a similarity threshold:

sql
SELECT id, name, active_ingredient,
       similarity(name, 'بندول') AS sml
FROM medication_master
WHERE name % 'بندول'          -- shortcut for similarity > pg_trgm.similarity_threshold
   OR 'بندول' <% ANY(synonyms)   -- if synonyms are text[]
ORDER BY sml DESC
LIMIT 10;
To adjust threshold temporarily:

sql
SET pg_trgm.similarity_threshold = 0.3;  -- default is 0.3
5.2 Full‑Text Search (for larger document fields)
sql
-- Add a tsvector column and index
ALTER TABLE medication_master ADD COLUMN tsv tsvector;
UPDATE medication_master SET tsv = to_tsvector('arabic', coalesce(name,'') || ' ' || coalesce(active_ingredient,''));
-- Auto-update via trigger
CREATE TRIGGER trg_med_tsv BEFORE INSERT OR UPDATE ON medication_master
FOR EACH ROW EXECUTE FUNCTION
  tsvector_update_trigger(tsv, 'pg_catalog.arabic', name, active_ingredient);
CREATE INDEX ft_idx ON medication_master USING GIN(tsv);

-- Query
SELECT * FROM medication_master WHERE tsv @@ plainto_tsquery('arabic', 'باراسيتامول');
Note: Arabic FTS requires the arabic text search dictionary; it works out‑of‑the‑box in PG but can be customized.

6. Indexing Strategy & Performance
6.1 Index Types
B‑tree – Default; for equality and range on sortable types.

GIN – For composite values (arrays, JSONB, tsvector, trigrams). Good for many‑to‑many lookups.

GiST – More flexible than GIN, handles overlapping geometries (PostGIS), full‑text, and custom.

BRIN – Block range indexes; extremely compact for huge, naturally ordered data (timestamps in append‑only tables).

Partial indexes – CREATE INDEX ... WHERE is_active = true;

Covering indexes – INCLUDE (extra_col) to enable index‑only scans.

6.2 When to Use Trigram vs Full‑Text
Trigrams: Best for substring and fuzzy matches on short strings (drug names, usernames). Use for “did you mean?”.

Full‑text search: For long text (product descriptions, articles). Supports stemming, ranking, phrase search.

6.3 Query Analysis
Always use EXPLAIN (ANALYZE, BUFFERS) to verify:

sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT ...;
Check for Seq Scan → consider index; Bitmap Index Scan often good for high selectivity.

7. Advanced Features
7.1 JSONB for Flexible Metadata
sql
-- Store synonyms, concerns, etc.
UPDATE medication_master
SET synonyms = synonyms || '["بندول الاحمر"]'::jsonb
WHERE id = 1;

-- Querying
SELECT * FROM medication_master WHERE synonyms @> '["Paracetamol"]'::jsonb;
-- Or using jsonb_array_elements for unnesting
SELECT id, name, syn
FROM medication_master, jsonb_array_elements_text(synonyms) AS syn
WHERE syn ILIKE '%parac%';
7.2 Geospatial with PostGIS
sql
-- If you use lat/lng without PostGIS, you can still calculate approximate distance
-- But for real indexing, use geometry/geography.
ALTER TABLE pharmacies ADD COLUMN geog GEOGRAPHY(Point);
UPDATE pharmacies SET geog = ST_SetSRID(ST_MakePoint(lng, lat), 4326)::geography;
CREATE INDEX idx_pharm_geog ON pharmacies USING GIST(geog);

-- Find nearest 5 pharmacies
SELECT id, name, ST_Distance(geog, ST_SetSRID(ST_MakePoint(:lng, :lat), 4326)::geography) AS dist
FROM pharmacies
ORDER BY geog <-> ST_SetSRID(ST_MakePoint(:lng, :lat), 4326)::geography
LIMIT 5;
7.3 Partitioning
Useful for large audit logs or event tables (Phase 45).

sql
CREATE TABLE events (
  id BIGINT GENERATED ALWAYS AS IDENTITY,
  customer_id BIGINT,
  event_type TEXT,
  product_id BIGINT,
  created_at TIMESTAMPTZ DEFAULT now()
) PARTITION BY RANGE (created_at);

CREATE TABLE events_2026_04 PARTITION OF events
FOR VALUES FROM ('2026-04-01') TO ('2026-05-01');
-- Automate partition creation via pg_partman or a cron job.
7.4 Materialized Views
For precomputed “For You” rankings (Phase 23) that don't need live updates:

sql
CREATE MATERIALIZED VIEW mv_recommendations AS
SELECT ...;
REFRESH MATERIALIZED VIEW CONCURRENTLY mv_recommendations;  -- with unique index
8. Transaction Management & Concurrency
Use explicit transactions (BEGIN/COMMIT) for multi‑step writes.

Pessimistic locking for inventory during quote responses:

sql
BEGIN;
SELECT * FROM pharmacy_inventory WHERE pharmacy_id = $1 AND medication_id = $2 FOR UPDATE;
-- Update stock only if sufficient
UPDATE pharmacy_inventory SET is_in_stock = false WHERE id = $inv_id;
COMMIT;
Advisory locks for application‑level synchronization if needed.

Isolation levels: default READ COMMITTED is usually fine; use REPEATABLE READ for financial calculations if you must avoid phantom reads.

9. Node.js / Express Integration (pg library)
9.1 Pool Setup
javascript
const { Pool } = require('pg');
const pool = new Pool({
  user: process.env.DB_USER,
  host: process.env.DB_HOST,
  database: process.env.DB_NAME,
  password: process.env.DB_PASSWORD,
  port: 5432,
  max: 20,               // adjust for expected concurrency
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 2000,
});
module.exports = pool;
9.2 Query Template
javascript
const { rows } = await pool.query(
  'SELECT id, name FROM medication_master WHERE name % $1 LIMIT 10',
  ['بندول']
);
9.3 Transaction Helper
javascript
const client = await pool.connect();
try {
  await client.query('BEGIN');
  // ...queries...
  await client.query('COMMIT');
} catch (e) {
  await client.query('ROLLBACK');
  throw e;
} finally {
  client.release();
}
Always avoid SQL injection by using parameterized queries ($1, $2). Never interpolate user input.

10. Administration & Maintenance
Backups: pg_dump -Fc dawaai_db > backup.dump; schedule with cron.

Vacuum: Enable auto‑vacuum (default). Monitor bloat with pg_stat_user_tables.

Index maintenance: REINDEX INDEX CONCURRENTLY idx_name; to rebuild bloated indexes online.

Slow query logging: Set log_min_duration_statement = 2000 (ms) in postgresql.conf.

Security: Use roles with least privilege. Never expose PostgreSQL to the internet directly; use an API.

11. Troubleshooting Common Mistakes
Missing trigram escapes: In similarity(), the string must be escaped if it contains special regex chars. Wrap with E'...' only if necessary.

Forgotten UNACCENT: For Arabic diacritics, combine unaccent + lower + trigram.

Oversized GIN indexes: GIN can grow; use gin_pending_list_limit and regular VACUUM.

NO INHERIT on constraints: When partitioning, ensure constraints propagate correctly.

Using SERIAL vs IDENTITY: Prefer GENERATED ALWAYS AS IDENTITY over SERIAL per SQL standard.

