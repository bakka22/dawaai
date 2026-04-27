-- Phase 1: Database Setup & Fuzzy Search
-- Run: psql -U postgres -d dawaai_db -f schema.sql

-- Enable pg_trgm extension for fuzzy text search
CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- Users table for authentication (customer, pharmacist, admin)
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    phone VARCHAR(20) UNIQUE NOT NULL,
    role VARCHAR(20) NOT NULL CHECK (role IN ('customer', 'pharmacist', 'admin')),
    refresh_token_hash TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Index for phone lookups (login)
CREATE INDEX idx_users_phone ON users(phone);

-- Phase 2: Pharmacy & Inventory

-- Medications master table (created early as dependency)
CREATE TABLE medications (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    active_ingredient VARCHAR(255),
    synonyms JSONB DEFAULT '[]',
    is_flagged BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Pharmacies table (owner references users)
CREATE TABLE pharmacies (
    id SERIAL PRIMARY KEY,
    owner_id INTEGER NOT NULL REFERENCES users(id),
    name VARCHAR(255) NOT NULL,
    lat DECIMAL(10, 8),
    lng DECIMAL(11, 8),
    is_approved BOOLEAN DEFAULT FALSE,
    city VARCHAR(100),
    address TEXT,
    phone VARCHAR(20),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Pharmacy inventory (links pharmacy to medications)
CREATE TABLE pharmacy_inventory (
    id SERIAL PRIMARY KEY,
    pharmacy_id INTEGER NOT NULL REFERENCES pharmacies(id) ON DELETE CASCADE,
    medication_id INTEGER NOT NULL REFERENCES medications(id) ON DELETE CASCADE,
    is_in_stock BOOLEAN DEFAULT TRUE,
    price DECIMAL(10, 2),
    quantity INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(pharmacy_id, medication_id)
);

-- Indexes for pharmacy lookups
CREATE INDEX idx_pharmacies_owner ON pharmacies(owner_id);
CREATE INDEX idx_pharmacies_city ON pharmacies(city);
CREATE INDEX idx_pharmacies_approved ON pharmacies(is_approved);
CREATE INDEX idx_pharmacy_inventory_pharmacy ON pharmacy_inventory(pharmacy_id);
CREATE INDEX idx_pharmacy_inventory_medication ON pharmacy_inventory(medication_id);

-- Phase 3: Master Meds & Trigram Indexes
-- GIN Trigram indexes for fuzzy medication search
CREATE INDEX idx_meds_name_trgm ON medications USING gin(name gin_trgm_ops);
CREATE INDEX idx_meds_active_ingredient_trgm ON medications USING gin(active_ingredient gin_trgm_ops);

-- Phase 4: Quotes (Broadcast Ready)

-- Quotes table with 20-min TTL (expires_at)
CREATE TABLE quotes (
    id SERIAL PRIMARY KEY,
    customer_id INTEGER NOT NULL REFERENCES users(id),
    status VARCHAR(20) NOT NULL DEFAULT 'BROADCASTING' 
        CHECK (status IN ('BROADCASTING', 'EXPIRED', 'ACCEPTED', 'COMPLETED', 'CANCELLED')),
    expires_at TIMESTAMP NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Quote responses (pharmacy bids)
CREATE TABLE quote_responses (
    id SERIAL PRIMARY KEY,
    quote_id INTEGER NOT NULL REFERENCES quotes(id) ON DELETE CASCADE,
    pharmacy_id INTEGER NOT NULL REFERENCES pharmacies(id) ON DELETE CASCADE,
    total_price DECIMAL(10, 2),
    notes TEXT,
    status VARCHAR(20) DEFAULT 'PENDING'
        CHECK (status IN ('PENDING', 'ACCEPTED', 'REJECTED', 'EXPIRED')),
    responded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(quote_id, pharmacy_id)
);

-- Indexes for quote lookups
CREATE INDEX idx_quotes_customer ON quotes(customer_id);
CREATE INDEX idx_quotes_status ON quotes(status);
CREATE INDEX idx_quotes_expires ON quotes(expires_at);
CREATE INDEX idx_quote_responses_quote ON quote_responses(quote_id);
CREATE INDEX idx_quote_responses_pharmacy ON quote_responses(pharmacy_id);