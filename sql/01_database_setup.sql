-- ============================================================================
-- Netflix Content Analysis - Database Setup
-- ============================================================================
-- This script creates the PostgreSQL database schema for the Netflix
-- content analysis project. It uses a normalized structure with 8 tables
-- to demonstrate multi-table JOINs and proper relational design.
--
-- Usage:
--   1. Create database: CREATE DATABASE netflix_analysis;
--   2. Connect: \c netflix_analysis
--   3. Run this script: \i sql/01_database_setup.sql
-- ============================================================================

-- ============================================================================
-- Drop existing tables (for clean re-runs)
-- ============================================================================
DROP TABLE IF EXISTS title_genres CASCADE;
DROP TABLE IF EXISTS title_countries CASCADE;
DROP TABLE IF EXISTS title_cast CASCADE;
DROP TABLE IF EXISTS title_directors CASCADE;
DROP TABLE IF EXISTS genres CASCADE;
DROP TABLE IF EXISTS countries CASCADE;
DROP TABLE IF EXISTS people CASCADE;
DROP TABLE IF EXISTS titles CASCADE;

-- ============================================================================
-- Table 1: titles
-- The main fact table containing core information about each Netflix title.
-- ============================================================================
CREATE TABLE titles (
    show_id         VARCHAR(10) PRIMARY KEY,
    title           VARCHAR(500) NOT NULL,
    type            VARCHAR(20) NOT NULL,          -- 'Movie' or 'TV Show'
    release_year    INTEGER NOT NULL,
    date_added      DATE,
    rating          VARCHAR(20),                    -- e.g., 'TV-MA', 'PG-13'
    duration        VARCHAR(50),                    -- Original string: '90 min' or '3 Seasons'
    duration_value  INTEGER,                        -- Numeric part: 90 or 3
    duration_unit   VARCHAR(20),                    -- Unit part: 'min' or 'Seasons'
    description     TEXT
);

-- ============================================================================
-- Table 2: people
-- Lookup table for all people (directors and cast members).
-- A single table avoids duplicating person records across roles.
-- ============================================================================
CREATE TABLE people (
    person_id   SERIAL PRIMARY KEY,
    person_name VARCHAR(300) NOT NULL UNIQUE
);

-- ============================================================================
-- Table 3: title_directors
-- Junction table linking titles to their directors (many-to-many).
-- A title can have multiple directors; a director can work on multiple titles.
-- ============================================================================
CREATE TABLE title_directors (
    show_id     VARCHAR(10) NOT NULL REFERENCES titles(show_id),
    person_id   INTEGER NOT NULL REFERENCES people(person_id),
    PRIMARY KEY (show_id, person_id)
);

-- ============================================================================
-- Table 4: title_cast
-- Junction table linking titles to their cast members (many-to-many).
-- ============================================================================
CREATE TABLE title_cast (
    show_id     VARCHAR(10) NOT NULL REFERENCES titles(show_id),
    person_id   INTEGER NOT NULL REFERENCES people(person_id),
    PRIMARY KEY (show_id, person_id)
);

-- ============================================================================
-- Table 5: countries
-- Lookup table for all countries.
-- ============================================================================
CREATE TABLE countries (
    country_id   SERIAL PRIMARY KEY,
    country_name VARCHAR(200) NOT NULL UNIQUE
);

-- ============================================================================
-- Table 6: title_countries
-- Junction table linking titles to countries (many-to-many).
-- A title can be produced in multiple countries.
-- ============================================================================
CREATE TABLE title_countries (
    show_id     VARCHAR(10) NOT NULL REFERENCES titles(show_id),
    country_id  INTEGER NOT NULL REFERENCES countries(country_id),
    PRIMARY KEY (show_id, country_id)
);

-- ============================================================================
-- Table 7: genres
-- Lookup table for all genres (called "listed_in" in the raw dataset).
-- ============================================================================
CREATE TABLE genres (
    genre_id   SERIAL PRIMARY KEY,
    genre_name VARCHAR(200) NOT NULL UNIQUE
);

-- ============================================================================
-- Table 8: title_genres
-- Junction table linking titles to genres (many-to-many).
-- A title can belong to multiple genres; a genre can have many titles.
-- ============================================================================
CREATE TABLE title_genres (
    show_id     VARCHAR(10) NOT NULL REFERENCES titles(show_id),
    genre_id    INTEGER NOT NULL REFERENCES genres(genre_id),
    PRIMARY KEY (show_id, genre_id)
);


-- ============================================================================
-- INDEXES
-- ============================================================================
-- These indexes improve performance for common query patterns.

-- Index on type: frequently used in WHERE and GROUP BY to filter Movies/TV Shows
CREATE INDEX idx_titles_type ON titles(type);

-- Index on release_year: used in range queries, GROUP BY, and ORDER BY
CREATE INDEX idx_titles_release_year ON titles(release_year);

-- Index on rating: used in GROUP BY for rating distribution analysis
CREATE INDEX idx_titles_rating ON titles(rating);

-- Index on date_added: used for time-series analysis of when content was added
CREATE INDEX idx_titles_date_added ON titles(date_added);

-- Index on people name: speeds up lookups when searching for specific people
CREATE INDEX idx_people_name ON people(person_name);

-- Index on genre name: speeds up genre-based filtering
CREATE INDEX idx_genres_name ON genres(genre_name);

-- Index on country name: speeds up country-based filtering
CREATE INDEX idx_countries_name ON countries(country_name);


-- ============================================================================
-- SCHEMA RELATIONSHIPS (for documentation)
-- ============================================================================
/*
    Entity-Relationship Summary:
    
    titles (1) ──── (M) title_directors (M) ──── (1) people
    titles (1) ──── (M) title_cast      (M) ──── (1) people
    titles (1) ──── (M) title_countries  (M) ──── (1) countries
    titles (1) ──── (M) title_genres     (M) ──── (1) genres

    - titles is the central fact table
    - people stores both directors and cast (distinguished by junction table)
    - Each junction table implements a many-to-many relationship
    - This normalization eliminates redundant data storage and enables
      clean multi-table JOINs for analysis
*/


-- ============================================================================
-- DATA LOADING INSTRUCTIONS
-- ============================================================================
/*
    Option 1: Use the Python loading script (recommended)
    -----------------------------------------------------
    The src/analysis.py script includes functions to:
    1. Read the cleaned CSV
    2. Parse multi-value columns (director, cast, country, listed_in)
    3. Insert data into all normalized tables
    
    Run: python src/analysis.py --load-data

    Option 2: Use COPY for the flat titles table only
    -------------------------------------------------
    If you just want the main titles table without normalization:
    
    COPY titles(show_id, title, type, release_year, date_added, rating,
                duration, duration_value, duration_unit, description)
    FROM '/path/to/netflix_cleaned.csv'
    WITH (FORMAT csv, HEADER true);
    
    Note: This only loads the titles table. The junction tables
    (title_directors, title_cast, etc.) require parsing the comma-
    separated values in director, cast, country, and listed_in columns.
    The Python script handles this automatically.
*/

SELECT 'Database schema created successfully!' AS status;
