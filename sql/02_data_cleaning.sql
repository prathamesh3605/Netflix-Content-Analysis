-- ============================================================================
-- Netflix Content Analysis - SQL Data Cleaning & Validation
-- ============================================================================
-- Run this AFTER loading data into the database.
-- Validates data integrity, checks for issues, and standardizes values.
--
-- Usage: \i sql/02_data_cleaning.sql
-- ============================================================================


-- ============================================================================
-- 1. ROW COUNT VALIDATION
-- Verify expected number of records were loaded
-- ============================================================================

-- Check total titles loaded (expected: ~7,777 after Python cleaning)
SELECT 
    'titles' AS table_name, 
    COUNT(*) AS row_count 
FROM titles;

-- Check all junction tables
SELECT 'people' AS table_name, COUNT(*) AS row_count FROM people
UNION ALL
SELECT 'title_directors', COUNT(*) FROM title_directors
UNION ALL
SELECT 'title_cast', COUNT(*) FROM title_cast
UNION ALL
SELECT 'countries', COUNT(*) FROM countries
UNION ALL
SELECT 'title_countries', COUNT(*) FROM title_countries
UNION ALL
SELECT 'genres', COUNT(*) FROM genres
UNION ALL
SELECT 'title_genres', COUNT(*) FROM title_genres
ORDER BY table_name;


-- ============================================================================
-- 2. NULL VALUE CHECK
-- Verify no unexpected nulls exist after cleaning
-- ============================================================================

-- Check for nulls in critical columns
SELECT
    COUNT(*) AS total_titles,
    COUNT(*) - COUNT(title) AS null_titles,
    COUNT(*) - COUNT(type) AS null_types,
    COUNT(*) - COUNT(release_year) AS null_release_years,
    COUNT(*) - COUNT(date_added) AS null_dates_added,
    COUNT(*) - COUNT(rating) AS null_ratings,
    COUNT(*) - COUNT(duration) AS null_durations
FROM titles;


-- ============================================================================
-- 3. DATA TYPE AND RANGE VALIDATION
-- Ensure values fall within expected ranges
-- ============================================================================

-- Check release year range (should be reasonable: 1925-2021)
SELECT 
    MIN(release_year) AS min_year,
    MAX(release_year) AS max_year,
    AVG(release_year)::INTEGER AS avg_year
FROM titles;

-- Check for invalid release years (before 1900 or in the future)
SELECT show_id, title, release_year
FROM titles
WHERE release_year < 1900 OR release_year > EXTRACT(YEAR FROM CURRENT_DATE)
LIMIT 10;

-- Check duration_value range for movies (should be positive, typically 1-600 min)
SELECT 
    MIN(duration_value) AS min_duration,
    MAX(duration_value) AS max_duration,
    AVG(duration_value)::INTEGER AS avg_duration
FROM titles
WHERE type = 'Movie';

-- Check duration_value range for TV shows (seasons, typically 1-20)
SELECT 
    MIN(duration_value) AS min_seasons,
    MAX(duration_value) AS max_seasons,
    AVG(duration_value)::NUMERIC(4,1) AS avg_seasons
FROM titles
WHERE type = 'TV Show';

-- Check for invalid duration values
SELECT show_id, title, type, duration, duration_value
FROM titles
WHERE duration_value IS NULL OR duration_value <= 0
LIMIT 10;


-- ============================================================================
-- 4. CONTENT TYPE VALIDATION
-- Verify only expected content types exist
-- ============================================================================

SELECT type, COUNT(*) AS count
FROM titles
GROUP BY type
ORDER BY count DESC;


-- ============================================================================
-- 5. RATING VALIDATION
-- Check for unexpected rating values
-- ============================================================================

SELECT rating, COUNT(*) AS count
FROM titles
GROUP BY rating
ORDER BY count DESC;


-- ============================================================================
-- 6. REFERENTIAL INTEGRITY CHECK
-- Ensure all foreign keys in junction tables reference valid records
-- ============================================================================

-- Check for orphaned records in title_directors
SELECT td.show_id, td.person_id
FROM title_directors td
LEFT JOIN titles t ON td.show_id = t.show_id
WHERE t.show_id IS NULL;

-- Check for orphaned records in title_cast
SELECT tc.show_id, tc.person_id
FROM title_cast tc
LEFT JOIN titles t ON tc.show_id = t.show_id
WHERE t.show_id IS NULL;

-- Check for orphaned records in title_countries
SELECT tcn.show_id, tcn.country_id
FROM title_countries tcn
LEFT JOIN titles t ON tcn.show_id = t.show_id
WHERE t.show_id IS NULL;

-- Check for orphaned records in title_genres
SELECT tg.show_id, tg.genre_id
FROM title_genres tg
LEFT JOIN titles t ON tg.show_id = t.show_id
WHERE t.show_id IS NULL;


-- ============================================================================
-- 7. DUPLICATE CHECK
-- Ensure no duplicate records exist
-- ============================================================================

-- Check for duplicate show_ids (should be 0 since it's a primary key)
SELECT show_id, COUNT(*) AS occurrences
FROM titles
GROUP BY show_id
HAVING COUNT(*) > 1;

-- Check for duplicate person entries
SELECT person_name, COUNT(*) AS occurrences
FROM people
GROUP BY person_name
HAVING COUNT(*) > 1;


-- ============================================================================
-- 8. TEXT STANDARDIZATION VERIFICATION
-- Check for leading/trailing whitespace issues
-- ============================================================================

-- Check titles with leading/trailing spaces
SELECT show_id, title
FROM titles
WHERE title != TRIM(title)
LIMIT 5;

-- Check for inconsistent casing in type column
SELECT DISTINCT type FROM titles;

-- Check for inconsistent casing in rating column
SELECT DISTINCT rating FROM titles ORDER BY rating;


-- ============================================================================
-- 9. DATE VALIDATION
-- Ensure date_added values are reasonable
-- ============================================================================

SELECT 
    MIN(date_added) AS earliest_addition,
    MAX(date_added) AS latest_addition
FROM titles;

-- Check for titles added before Netflix streaming began (2007)
SELECT show_id, title, date_added
FROM titles
WHERE date_added < '2007-01-01'
LIMIT 5;


-- ============================================================================
-- 10. DATA QUALITY SUMMARY
-- Overall quality scorecard
-- ============================================================================

SELECT 
    COUNT(*) AS total_records,
    COUNT(DISTINCT type) AS content_types,
    COUNT(DISTINCT rating) AS unique_ratings,
    MIN(release_year) AS earliest_release,
    MAX(release_year) AS latest_release,
    MIN(date_added) AS earliest_added,
    MAX(date_added) AS latest_added,
    COUNT(CASE WHEN type = 'Movie' THEN 1 END) AS movie_count,
    COUNT(CASE WHEN type = 'TV Show' THEN 1 END) AS tv_show_count
FROM titles;

SELECT 'Data validation complete!' AS status;
