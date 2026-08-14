-- ============================================================================
-- Netflix Content Analysis - Basic SQL Analysis
-- ============================================================================
-- This file demonstrates fundamental SQL skills:
--   SELECT, WHERE, ORDER BY, GROUP BY, HAVING,
--   COUNT, AVG, MIN, MAX, CASE WHEN
--
-- All queries use the normalized schema from 01_database_setup.sql.
-- ============================================================================


-- ============================================================================
-- Query 1: Total Number of Netflix Titles
-- Skill: COUNT aggregate
-- ============================================================================
-- Purpose: Establish the total size of the Netflix catalog.

SELECT COUNT(*) AS total_titles
FROM titles;

-- Expected: ~7,777 titles


-- ============================================================================
-- Query 2: Number of Movies vs TV Shows
-- Skill: GROUP BY, COUNT
-- ============================================================================
-- Purpose: Understand the content type split on Netflix.

SELECT 
    type,
    COUNT(*) AS title_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS percentage
FROM titles
GROUP BY type
ORDER BY title_count DESC;

-- Expected: Movies ~69%, TV Shows ~31%


-- ============================================================================
-- Query 3: Most Common Content Ratings
-- Skill: GROUP BY, COUNT, ORDER BY, LIMIT
-- ============================================================================
-- Purpose: Identify which content ratings dominate the platform.

SELECT 
    rating,
    COUNT(*) AS title_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS percentage
FROM titles
GROUP BY rating
ORDER BY title_count DESC;

-- Expected: TV-MA is most common, followed by TV-14


-- ============================================================================
-- Query 4: Titles Released After 2015
-- Skill: WHERE (filtering), COUNT
-- ============================================================================
-- Purpose: How much recent content does Netflix have?

SELECT 
    COUNT(*) AS titles_after_2015,
    (SELECT COUNT(*) FROM titles) AS total_titles,
    ROUND(
        COUNT(*) * 100.0 / (SELECT COUNT(*) FROM titles), 2
    ) AS percentage
FROM titles
WHERE release_year > 2015;


-- ============================================================================
-- Query 5: Average, Min, and Max Release Year
-- Skill: AVG, MIN, MAX aggregate functions
-- ============================================================================
-- Purpose: Understand the age distribution of Netflix content.

SELECT 
    MIN(release_year) AS oldest_release,
    MAX(release_year) AS newest_release,
    ROUND(AVG(release_year), 0) AS avg_release_year,
    MAX(release_year) - MIN(release_year) AS year_span
FROM titles;


-- ============================================================================
-- Query 6: Number of Titles by Release Year
-- Skill: GROUP BY, COUNT, ORDER BY
-- ============================================================================
-- Purpose: See how content production has changed over time.

SELECT 
    release_year,
    COUNT(*) AS title_count
FROM titles
GROUP BY release_year
ORDER BY release_year DESC
LIMIT 20;


-- ============================================================================
-- Query 7: Rating Distribution Using CASE WHEN
-- Skill: CASE WHEN, GROUP BY
-- ============================================================================
-- Purpose: Categorize ratings into broader audience groups for easier analysis.
-- This demonstrates the CASE WHEN statement for conditional grouping.

SELECT 
    CASE 
        WHEN rating IN ('TV-MA', 'R', 'NC-17') THEN 'Adult (18+)'
        WHEN rating IN ('TV-14', 'PG-13') THEN 'Teen (13-17)'
        WHEN rating IN ('TV-PG', 'PG') THEN 'Older Kids (7-12)'
        WHEN rating IN ('TV-Y', 'TV-Y7', 'TV-Y7-FV', 'TV-G', 'G') THEN 'Kids (All Ages)'
        ELSE 'Other/Unrated'
    END AS audience_category,
    COUNT(*) AS title_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS percentage
FROM titles
GROUP BY audience_category
ORDER BY title_count DESC;

-- This query shows that most Netflix content targets adult audiences.


-- ============================================================================
-- Query 8: Movie Duration Statistics
-- Skill: AVG, MIN, MAX, WHERE, filtering
-- ============================================================================
-- Purpose: Analyze the length distribution of Netflix movies.

SELECT 
    COUNT(*) AS total_movies,
    MIN(duration_value) AS shortest_movie_min,
    MAX(duration_value) AS longest_movie_min,
    ROUND(AVG(duration_value), 1) AS avg_duration_min,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY duration_value) AS median_duration_min
FROM titles
WHERE type = 'Movie' AND duration_unit = 'min';


-- ============================================================================
-- Query 9: TV Show Season Statistics
-- Skill: AVG, MIN, MAX, WHERE
-- ============================================================================
-- Purpose: How long do Netflix TV shows typically run?

SELECT 
    COUNT(*) AS total_tv_shows,
    MIN(duration_value) AS min_seasons,
    MAX(duration_value) AS max_seasons,
    ROUND(AVG(duration_value), 1) AS avg_seasons
FROM titles
WHERE type = 'TV Show';


-- ============================================================================
-- Query 10: Titles Added Per Year (Content Growth)
-- Skill: EXTRACT, GROUP BY, ORDER BY, HAVING
-- ============================================================================
-- Purpose: Track Netflix's content acquisition over time.
-- HAVING filters out years with very few titles (noise).

SELECT 
    EXTRACT(YEAR FROM date_added) AS year_added,
    COUNT(*) AS titles_added,
    COUNT(CASE WHEN type = 'Movie' THEN 1 END) AS movies_added,
    COUNT(CASE WHEN type = 'TV Show' THEN 1 END) AS shows_added
FROM titles
WHERE date_added IS NOT NULL
GROUP BY EXTRACT(YEAR FROM date_added)
HAVING COUNT(*) >= 5    -- Exclude years with very few titles
ORDER BY year_added;

-- This shows Netflix's massive content ramp-up, especially 2016-2020.


SELECT 'Basic analysis complete!' AS status;
