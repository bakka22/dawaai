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