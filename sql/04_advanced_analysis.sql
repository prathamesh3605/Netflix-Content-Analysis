-- ============================================================================
-- Netflix Content Analysis - Advanced SQL Analysis
-- ============================================================================
-- This file demonstrates intermediate and advanced SQL skills:
--   - INNER JOIN, LEFT JOIN, multiple JOINs
--   - Subqueries
--   - Common Table Expressions (CTEs) using WITH
--   - Window Functions: ROW_NUMBER, RANK, DENSE_RANK, LAG, LEAD, SUM OVER, AVG OVER
--   - Multi-table JOINs (3+ tables)
--
-- Each query includes comments explaining what it does and why.
-- ============================================================================


-- ============================================================================
-- SECTION A: INTERMEDIATE SQL (JOINs, Subqueries, Aggregations)
-- ============================================================================


-- ============================================================================
-- Query 1: Top 10 Countries by Number of Titles
-- Skill: INNER JOIN between 3 tables
-- ============================================================================
-- We JOIN titles -> title_countries -> countries to find which countries
-- produce the most Netflix content.

SELECT 
    c.country_name,
    COUNT(DISTINCT tc.show_id) AS title_count
FROM title_countries tc
INNER JOIN countries c ON tc.country_id = c.country_id
WHERE c.country_name != 'Unknown'
GROUP BY c.country_name
ORDER BY title_count DESC
LIMIT 10;

-- Expected: United States leads significantly, followed by India, UK


-- ============================================================================
-- Query 2: Top 10 Genres by Number of Titles
-- Skill: INNER JOIN between 3 tables
-- ============================================================================
-- We JOIN titles -> title_genres -> genres to find the most popular genres.

SELECT 
    g.genre_name,
    COUNT(DISTINCT tg.show_id) AS title_count
FROM title_genres tg
INNER JOIN genres g ON tg.genre_id = g.genre_id
GROUP BY g.genre_name
ORDER BY title_count DESC
LIMIT 10;


-- ============================================================================
-- Query 3: Directors with the Highest Number of Titles
-- Skill: INNER JOIN, GROUP BY, HAVING
-- ============================================================================
-- JOIN titles -> title_directors -> people to find prolific directors.
-- HAVING filters out directors with fewer than 5 titles.

SELECT 
    p.person_name AS director,
    COUNT(DISTINCT td.show_id) AS title_count
FROM title_directors td
INNER JOIN people p ON td.person_id = p.person_id
WHERE p.person_name != 'Unknown'
GROUP BY p.person_name
HAVING COUNT(DISTINCT td.show_id) >= 5
ORDER BY title_count DESC
LIMIT 15;


-- ============================================================================
-- Query 4: Average Duration of Movies
-- Skill: JOIN, AVG, filtering
-- ============================================================================
-- Calculate average movie length, grouped by rating.

SELECT 
    t.rating,
    COUNT(*) AS movie_count,
    ROUND(AVG(t.duration_value), 1) AS avg_duration_min,
    MIN(t.duration_value) AS min_duration,
    MAX(t.duration_value) AS max_duration
FROM titles t
WHERE t.type = 'Movie' AND t.duration_unit = 'min'
GROUP BY t.rating
HAVING COUNT(*) >= 10
ORDER BY avg_duration_min DESC;


-- ============================================================================
-- Query 5: Movies vs TV Shows by Country (Top 15 Countries)
-- Skill: JOIN, CASE WHEN inside aggregate, subquery
-- ============================================================================
-- Shows the Movie/TV Show split for the top content-producing countries.

SELECT 
    c.country_name,
    COUNT(DISTINCT tc.show_id) AS total_titles,
    COUNT(DISTINCT CASE WHEN t.type = 'Movie' THEN tc.show_id END) AS movies,
    COUNT(DISTINCT CASE WHEN t.type = 'TV Show' THEN tc.show_id END) AS tv_shows,
    ROUND(
        COUNT(DISTINCT CASE WHEN t.type = 'Movie' THEN tc.show_id END) * 100.0 /
        NULLIF(COUNT(DISTINCT tc.show_id), 0), 1
    ) AS movie_pct
FROM title_countries tc
INNER JOIN countries c ON tc.country_id = c.country_id
INNER JOIN titles t ON tc.show_id = t.show_id
WHERE c.country_name != 'Unknown'
GROUP BY c.country_name
ORDER BY total_titles DESC
LIMIT 15;


-- ============================================================================
-- Query 6: Content Added Each Year (with Movie/Show Breakdown)
-- Skill: EXTRACT, GROUP BY, CASE WHEN
-- ============================================================================

SELECT 
    EXTRACT(YEAR FROM date_added) AS year_added,
    COUNT(*) AS total_added,
    COUNT(CASE WHEN type = 'Movie' THEN 1 END) AS movies_added,
    COUNT(CASE WHEN type = 'TV Show' THEN 1 END) AS shows_added
FROM titles
WHERE date_added IS NOT NULL
GROUP BY EXTRACT(YEAR FROM date_added)
ORDER BY year_added;


-- ============================================================================
-- Query 7: Content Distribution by Rating and Type
-- Skill: Multiple GROUP BY, CASE WHEN
-- ============================================================================

SELECT 
    rating,
    COUNT(*) AS total,
    COUNT(CASE WHEN type = 'Movie' THEN 1 END) AS movies,
    COUNT(CASE WHEN type = 'TV Show' THEN 1 END) AS tv_shows,
    ROUND(
        COUNT(CASE WHEN type = 'Movie' THEN 1 END) * 100.0 / COUNT(*), 1
    ) AS movie_pct
FROM titles
GROUP BY rating
ORDER BY total DESC;


-- ============================================================================
-- Query 8: Most Productive Release Years (Subquery)
-- Skill: Subquery in WHERE clause
-- ============================================================================
-- Find years where the number of releases exceeded the average.

SELECT 
    release_year,
    COUNT(*) AS title_count
FROM titles
GROUP BY release_year
HAVING COUNT(*) > (
    -- Subquery: calculate the average titles per year
    SELECT AVG(year_count)
    FROM (
        SELECT COUNT(*) AS year_count
        FROM titles
        GROUP BY release_year
    ) AS yearly_counts
)
ORDER BY title_count DESC;


-- ============================================================================
-- SECTION B: COMMON TABLE EXPRESSIONS (CTEs)
-- ============================================================================


-- ============================================================================
-- Query 9: Yearly Content Growth Using CTE
-- Skill: WITH (CTE), aggregation
-- ============================================================================
-- A CTE (Common Table Expression) is a temporary named result set that exists
-- only during query execution. Think of it as a "temporary view" that makes
-- complex queries easier to read and write.

WITH yearly_content AS (
    -- This CTE calculates the number of titles added each year
    SELECT 
        EXTRACT(YEAR FROM date_added) AS year_added,
        COUNT(*) AS titles_added
    FROM titles
    WHERE date_added IS NOT NULL
    GROUP BY EXTRACT(YEAR FROM date_added)
)
SELECT 
    year_added,
    titles_added,
    -- Calculate percentage of all content added that year
    ROUND(titles_added * 100.0 / SUM(titles_added) OVER(), 2) AS pct_of_total
FROM yearly_content
ORDER BY year_added;


-- ============================================================================
-- Query 10: Countries with Above-Average Content Count
-- Skill: CTE + Subquery comparison
-- ============================================================================
-- Find countries that produce more content than the average country.

WITH country_counts AS (
    SELECT 
        c.country_name,
        COUNT(DISTINCT tc.show_id) AS title_count
    FROM title_countries tc
    INNER JOIN countries c ON tc.country_id = c.country_id
    WHERE c.country_name != 'Unknown'
    GROUP BY c.country_name
),
avg_count AS (
    SELECT AVG(title_count) AS avg_titles
    FROM country_counts
)
SELECT 
    cc.country_name,
    cc.title_count,
    ROUND(ac.avg_titles, 1) AS avg_across_countries,
    ROUND(cc.title_count / ac.avg_titles, 1) AS times_above_avg
FROM country_counts cc
CROSS JOIN avg_count ac
WHERE cc.title_count > ac.avg_titles
ORDER BY cc.title_count DESC;


-- ============================================================================
-- Query 11: Top Genres - Movies vs TV Shows Comparison (CTE)
-- Skill: Multiple CTEs, FULL OUTER JOIN
-- ============================================================================
-- Compare genre popularity between Movies and TV Shows.

WITH movie_genres AS (
    SELECT 
        g.genre_name,
        COUNT(DISTINCT tg.show_id) AS movie_count
    FROM title_genres tg
    INNER JOIN genres g ON tg.genre_id = g.genre_id
    INNER JOIN titles t ON tg.show_id = t.show_id
    WHERE t.type = 'Movie'
    GROUP BY g.genre_name
),
show_genres AS (
    SELECT 
        g.genre_name,
        COUNT(DISTINCT tg.show_id) AS show_count
    FROM title_genres tg
    INNER JOIN genres g ON tg.genre_id = g.genre_id
    INNER JOIN titles t ON tg.show_id = t.show_id
    WHERE t.type = 'TV Show'
    GROUP BY g.genre_name
)
SELECT 
    COALESCE(mg.genre_name, sg.genre_name) AS genre,
    COALESCE(mg.movie_count, 0) AS movies,
    COALESCE(sg.show_count, 0) AS tv_shows,
    COALESCE(mg.movie_count, 0) + COALESCE(sg.show_count, 0) AS total
FROM movie_genres mg
FULL OUTER JOIN show_genres sg ON mg.genre_name = sg.genre_name
ORDER BY total DESC
LIMIT 15;


-- ============================================================================
-- Query 12: Content Type Shift Over Time (CTE)
-- Skill: CTE with CASE WHEN aggregation
-- ============================================================================
-- Track how the Movie-to-TV-Show ratio has changed year over year.

WITH yearly_type AS (
    SELECT 
        EXTRACT(YEAR FROM date_added) AS year_added,
        COUNT(*) AS total,
        COUNT(CASE WHEN type = 'Movie' THEN 1 END) AS movies,
        COUNT(CASE WHEN type = 'TV Show' THEN 1 END) AS tv_shows
    FROM titles
    WHERE date_added IS NOT NULL
    GROUP BY EXTRACT(YEAR FROM date_added)
)
SELECT 
    year_added,
    total,
    movies,
    tv_shows,
    ROUND(movies * 100.0 / total, 1) AS movie_pct,
    ROUND(tv_shows * 100.0 / total, 1) AS show_pct
FROM yearly_type
WHERE total >= 10   -- Exclude early years with very few titles
ORDER BY year_added;


-- ============================================================================
-- SECTION C: WINDOW FUNCTIONS
-- ============================================================================
-- Window functions perform calculations across a set of rows that are
-- related to the current row. Unlike GROUP BY, they don't collapse rows.


-- ============================================================================
-- Query 13: Rank Countries by Content Count
-- Skill: RANK(), DENSE_RANK()
-- ============================================================================
-- RANK() leaves gaps after ties (1, 2, 2, 4)
-- DENSE_RANK() doesn't leave gaps (1, 2, 2, 3)

SELECT 
    c.country_name,
    COUNT(DISTINCT tc.show_id) AS title_count,
    RANK() OVER (ORDER BY COUNT(DISTINCT tc.show_id) DESC) AS rank_position,
    DENSE_RANK() OVER (ORDER BY COUNT(DISTINCT tc.show_id) DESC) AS dense_rank_position
FROM title_countries tc
INNER JOIN countries c ON tc.country_id = c.country_id
WHERE c.country_name != 'Unknown'
GROUP BY c.country_name
ORDER BY title_count DESC
LIMIT 20;


-- ============================================================================
-- Query 14: Rank Genres Within Each Country (Top 3 Genres per Country)
-- Skill: ROW_NUMBER() with PARTITION BY
-- ============================================================================
-- ROW_NUMBER assigns a unique sequential number within each partition.
-- PARTITION BY country_name creates a separate numbering for each country.
-- This is one of the most interview-relevant window function patterns.

WITH country_genre_counts AS (
    SELECT 
        c.country_name,
        g.genre_name,
        COUNT(DISTINCT tg.show_id) AS title_count
    FROM title_genres tg
    INNER JOIN genres g ON tg.genre_id = g.genre_id
    INNER JOIN title_countries tc ON tg.show_id = tc.show_id
    INNER JOIN countries c ON tc.country_id = c.country_id
    WHERE c.country_name != 'Unknown'
    GROUP BY c.country_name, g.genre_name
),
ranked AS (
    SELECT 
        country_name,
        genre_name,
        title_count,
        ROW_NUMBER() OVER (
            PARTITION BY country_name 
            ORDER BY title_count DESC
        ) AS genre_rank
    FROM country_genre_counts
)
SELECT 
    country_name,
    genre_name,
    title_count,
    genre_rank
FROM ranked
WHERE genre_rank <= 3
ORDER BY country_name, genre_rank;


-- ============================================================================
-- Query 15: Year-over-Year Growth with LAG()
-- Skill: LAG() window function
-- ============================================================================
-- LAG(column, offset) looks back 'offset' rows in the ordered result.
-- Here we compare each year's title count with the previous year's count.

WITH yearly_additions AS (
    SELECT 
        EXTRACT(YEAR FROM date_added)::INTEGER AS year_added,
        COUNT(*) AS titles_added
    FROM titles
    WHERE date_added IS NOT NULL
    GROUP BY EXTRACT(YEAR FROM date_added)
)
SELECT 
    year_added,
    titles_added,
    -- LAG looks at the previous row's value (1 row back)
    LAG(titles_added, 1) OVER (ORDER BY year_added) AS prev_year_titles,
    -- Calculate absolute growth
    titles_added - LAG(titles_added, 1) OVER (ORDER BY year_added) AS absolute_growth,
    -- Calculate percentage growth
    ROUND(
        (titles_added - LAG(titles_added, 1) OVER (ORDER BY year_added)) * 100.0 /
        NULLIF(LAG(titles_added, 1) OVER (ORDER BY year_added), 0),
        1
    ) AS growth_pct
FROM yearly_additions
ORDER BY year_added;


-- ============================================================================
-- Query 16: Cumulative Content Growth
-- Skill: SUM() OVER() - running total
-- ============================================================================
-- SUM() OVER (ORDER BY ...) creates a running cumulative total.
-- This shows how Netflix's total catalog has grown over time.

WITH yearly_additions AS (
    SELECT 
        EXTRACT(YEAR FROM date_added)::INTEGER AS year_added,
        COUNT(*) AS titles_added
    FROM titles
    WHERE date_added IS NOT NULL
    GROUP BY EXTRACT(YEAR FROM date_added)
)
SELECT 
    year_added,
    titles_added,
    -- Running total: sum all titles from the beginning up to current year
    SUM(titles_added) OVER (
        ORDER BY year_added
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_titles,
    -- Running percentage of total
    ROUND(
        SUM(titles_added) OVER (ORDER BY year_added) * 100.0 /
        SUM(titles_added) OVER (),
        1
    ) AS cumulative_pct
FROM yearly_additions
ORDER BY year_added;


-- ============================================================================
-- Query 17: Compare Current Year with Previous and Next Year
-- Skill: LAG() + LEAD()
-- ============================================================================
-- LEAD(column, offset) looks forward 'offset' rows.
-- Together with LAG, this gives a complete before/current/after view.

WITH yearly_additions AS (
    SELECT 
        EXTRACT(YEAR FROM date_added)::INTEGER AS year_added,
        COUNT(*) AS titles_added
    FROM titles
    WHERE date_added IS NOT NULL
    GROUP BY EXTRACT(YEAR FROM date_added)
)
SELECT 
    year_added,
    LAG(titles_added, 1) OVER (ORDER BY year_added) AS prev_year,
    titles_added AS current_year,
    LEAD(titles_added, 1) OVER (ORDER BY year_added) AS next_year,
    -- Is this year higher than both neighbors? (local peak)
    CASE 
        WHEN titles_added > COALESCE(LAG(titles_added, 1) OVER (ORDER BY year_added), 0)
         AND titles_added > COALESCE(LEAD(titles_added, 1) OVER (ORDER BY year_added), 0)
        THEN 'PEAK'
        ELSE ''
    END AS is_peak
FROM yearly_additions
ORDER BY year_added;


-- ============================================================================
-- Query 18: Top 3 Genres for Each Major Content-Producing Country
-- Skill: ROW_NUMBER() OVER (PARTITION BY ... ORDER BY ...), CTE
-- ============================================================================
-- This is a classic "Top N per group" pattern frequently asked in interviews.
-- We first identify major countries (>100 titles), then rank genres within each.

WITH major_countries AS (
    -- Step 1: Find countries with significant content (>100 titles)
    SELECT c.country_name
    FROM title_countries tc
    INNER JOIN countries c ON tc.country_id = c.country_id
    WHERE c.country_name != 'Unknown'
    GROUP BY c.country_name
    HAVING COUNT(DISTINCT tc.show_id) > 100
),
country_genre_counts AS (
    -- Step 2: Count titles per genre per major country
    SELECT 
        c.country_name,
        g.genre_name,
        COUNT(DISTINCT tg.show_id) AS title_count
    FROM title_genres tg
    INNER JOIN genres g ON tg.genre_id = g.genre_id
    INNER JOIN title_countries tc ON tg.show_id = tc.show_id
    INNER JOIN countries c ON tc.country_id = c.country_id
    WHERE c.country_name IN (SELECT country_name FROM major_countries)
    GROUP BY c.country_name, g.genre_name
),
ranked_genres AS (
    -- Step 3: Rank genres within each country
    SELECT 
        country_name,
        genre_name,
        title_count,
        ROW_NUMBER() OVER (
            PARTITION BY country_name 
            ORDER BY title_count DESC
        ) AS genre_rank
    FROM country_genre_counts
)
-- Step 4: Select only top 3 per country
SELECT 
    country_name,
    genre_rank,
    genre_name,
    title_count
FROM ranked_genres
WHERE genre_rank <= 3
ORDER BY country_name, genre_rank;


-- ============================================================================
-- Query 19: Running Average Movie Duration by Release Year
-- Skill: AVG() OVER() with window frame
-- ============================================================================
-- Shows how average movie length has evolved over recent years.

SELECT 
    release_year,
    COUNT(*) AS movie_count,
    ROUND(AVG(duration_value), 1) AS avg_duration,
    -- 3-year moving average for smoothing
    ROUND(
        AVG(AVG(duration_value)) OVER (
            ORDER BY release_year
            ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING
        ), 1
    ) AS moving_avg_3yr
FROM titles
WHERE type = 'Movie' AND duration_unit = 'min' AND release_year >= 2000
GROUP BY release_year
ORDER BY release_year;


-- ============================================================================
-- SECTION D: MULTI-TABLE JOINs (3+ Tables)
-- ============================================================================


-- ============================================================================
-- Query 20: Full Content Profile (Titles + Genres + Countries)
-- Skill: 3-table JOIN chain
-- ============================================================================
-- JOIN path: titles -> title_genres -> genres
--            titles -> title_countries -> countries
-- This demonstrates joining through junction tables.

SELECT 
    t.title,
    t.type,
    t.release_year,
    t.rating,
    g.genre_name,
    c.country_name
FROM titles t
INNER JOIN title_genres tg ON t.show_id = tg.show_id
INNER JOIN genres g ON tg.genre_id = g.genre_id
INNER JOIN title_countries tc ON t.show_id = tc.show_id
INNER JOIN countries c ON tc.country_id = c.country_id
WHERE t.release_year >= 2020
ORDER BY t.title
LIMIT 20;


-- ============================================================================
-- Query 21: Directors and Their Most Common Genres
-- Skill: 4-table JOIN, GROUP BY multiple columns
-- ============================================================================
-- JOIN path: people -> title_directors -> titles -> title_genres -> genres

SELECT 
    p.person_name AS director,
    g.genre_name,
    COUNT(DISTINCT t.show_id) AS title_count
FROM title_directors td
INNER JOIN people p ON td.person_id = p.person_id
INNER JOIN titles t ON td.show_id = t.show_id
INNER JOIN title_genres tg ON t.show_id = tg.show_id
INNER JOIN genres g ON tg.genre_id = g.genre_id
WHERE p.person_name != 'Unknown'
GROUP BY p.person_name, g.genre_name
HAVING COUNT(DISTINCT t.show_id) >= 3
ORDER BY title_count DESC
LIMIT 20;


-- ============================================================================
-- Query 22: Top Genres by Country with Ranking
-- Skill: 5-table JOIN path with window function
-- ============================================================================
-- JOIN path: titles -> title_genres -> genres (for genre info)
--            titles -> title_countries -> countries (for country info)
-- Then apply ROW_NUMBER to rank genres within each country.

WITH genre_by_country AS (
    SELECT 
        c.country_name,
        g.genre_name,
        COUNT(DISTINCT t.show_id) AS title_count,
        ROW_NUMBER() OVER (
            PARTITION BY c.country_name 
            ORDER BY COUNT(DISTINCT t.show_id) DESC
        ) AS rn
    FROM titles t
    INNER JOIN title_genres tg ON t.show_id = tg.show_id
    INNER JOIN genres g ON tg.genre_id = g.genre_id
    INNER JOIN title_countries tc ON t.show_id = tc.show_id
    INNER JOIN countries c ON tc.country_id = c.country_id
    WHERE c.country_name != 'Unknown'
    GROUP BY c.country_name, g.genre_name
)
SELECT 
    country_name,
    genre_name,
    title_count
FROM genre_by_country
WHERE rn = 1  -- Top genre per country
ORDER BY title_count DESC
LIMIT 15;


-- ============================================================================
-- SECTION E: PERFORMANCE ANALYSIS
-- ============================================================================


-- ============================================================================
-- Query 23: EXPLAIN Example - Understanding Query Plans
-- Skill: EXPLAIN, EXPLAIN ANALYZE
-- ============================================================================
-- EXPLAIN shows the query execution plan WITHOUT running the query.
-- EXPLAIN ANALYZE actually runs the query and shows real execution times.
-- 
-- This is critical for SQL optimization in production environments.

-- Show the execution plan for a country-based aggregation
EXPLAIN 
SELECT 
    c.country_name,
    COUNT(DISTINCT tc.show_id) AS title_count
FROM title_countries tc
INNER JOIN countries c ON tc.country_id = c.country_id
GROUP BY c.country_name
ORDER BY title_count DESC;

-- Show actual execution with timing
EXPLAIN ANALYZE
SELECT 
    c.country_name,
    COUNT(DISTINCT tc.show_id) AS title_count
FROM title_countries tc
INNER JOIN countries c ON tc.country_id = c.country_id
GROUP BY c.country_name
ORDER BY title_count DESC;


-- ============================================================================
-- Query 24: Index Impact Analysis
-- Skill: Index creation, EXPLAIN comparison
-- ============================================================================
-- Our indexes from 01_database_setup.sql improve queries that filter on:
--   - type (Movie/TV Show filtering)
--   - release_year (time-range queries)
--   - rating (rating-based grouping)
--   - date_added (chronological analysis)
--
-- Example: Compare a query on release_year with the index.

-- This query benefits from idx_titles_release_year
EXPLAIN ANALYZE
SELECT type, COUNT(*) 
FROM titles 
WHERE release_year BETWEEN 2015 AND 2020 
GROUP BY type;

-- Without the index, PostgreSQL would need to scan every row (Seq Scan).
-- With the index, it can use an Index Scan to quickly find matching rows.
-- 
-- Note: On small datasets (~7,777 rows), PostgreSQL may still choose a
-- sequential scan because the overhead of using an index isn't worth it.
-- The performance benefit becomes significant at 100K+ rows.


-- ============================================================================
-- Query 25: Rank Directors by Title Count (with Dense Rank)
-- Skill: DENSE_RANK(), CTE, multi-table JOIN
-- ============================================================================

WITH director_stats AS (
    SELECT 
        p.person_name AS director,
        COUNT(DISTINCT td.show_id) AS title_count,
        COUNT(DISTINCT CASE WHEN t.type = 'Movie' THEN t.show_id END) AS movies,
        COUNT(DISTINCT CASE WHEN t.type = 'TV Show' THEN t.show_id END) AS tv_shows,
        MIN(t.release_year) AS first_year,
        MAX(t.release_year) AS last_year
    FROM title_directors td
    INNER JOIN people p ON td.person_id = p.person_id
    INNER JOIN titles t ON td.show_id = t.show_id
    WHERE p.person_name != 'Unknown'
    GROUP BY p.person_name
)
SELECT 
    director,
    title_count,
    movies,
    tv_shows,
    first_year,
    last_year,
    DENSE_RANK() OVER (ORDER BY title_count DESC) AS director_rank
FROM director_stats
WHERE title_count >= 5
ORDER BY director_rank;


SELECT 'Advanced analysis complete!' AS status;
