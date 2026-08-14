-- ============================================================================
-- Netflix Content Analysis - Business Questions
-- ============================================================================
-- 15 business questions with SQL queries, expected results, and
-- business interpretations. Each question is framed from the perspective
-- of a data analyst providing insights to stakeholders.
--
-- All queries use the normalized schema from 01_database_setup.sql.
-- ============================================================================


-- ============================================================================
-- QUESTION 1: Which type of content dominates Netflix?
-- ============================================================================
-- Business Context: Understanding the content mix helps Netflix decide
-- whether to invest more in movies or TV shows.

SELECT 
    type,
    COUNT(*) AS title_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS percentage
FROM titles
GROUP BY type
ORDER BY title_count DESC;

-- Expected Result:
-- | type    | title_count | percentage |
-- |---------|-------------|------------|
-- | Movie   | ~5,370      | ~69%       |
-- | TV Show | ~2,407      | ~31%       |
--
-- Business Interpretation:
-- Movies dominate Netflix's catalog at roughly 69% of all content.
-- However, TV Shows (31%) represent a substantial and growing segment.
-- Netflix may want to continue investing in TV Shows as they drive
-- higher engagement through multi-episode viewing sessions.


-- ============================================================================
-- QUESTION 2: Which countries contribute the most content?
-- ============================================================================
-- Business Context: Identifies Netflix's key content markets and
-- potential regions for expansion.

SELECT 
    c.country_name,
    COUNT(DISTINCT tc.show_id) AS title_count,
    ROUND(COUNT(DISTINCT tc.show_id) * 100.0 / (SELECT COUNT(*) FROM titles), 2) AS pct_of_total
FROM title_countries tc
INNER JOIN countries c ON tc.country_id = c.country_id
WHERE c.country_name != 'Unknown'
GROUP BY c.country_name
ORDER BY title_count DESC
LIMIT 10;

-- Business Interpretation:
-- The United States dominates content production, followed by India and
-- the United Kingdom. This reflects both Hollywood's global influence and
-- Netflix's strategic investment in Indian content (Bollywood + regional).
-- Countries like South Korea and Japan show Netflix's push into Asian markets.


-- ============================================================================
-- QUESTION 3: Which genres are most popular?
-- ============================================================================
-- Business Context: Helps content acquisition teams prioritize genre
-- investments and identifies gaps in the catalog.

SELECT 
    g.genre_name,
    COUNT(DISTINCT tg.show_id) AS title_count,
    ROUND(COUNT(DISTINCT tg.show_id) * 100.0 / (SELECT COUNT(*) FROM titles), 2) AS pct_of_catalog
FROM title_genres tg
INNER JOIN genres g ON tg.genre_id = g.genre_id
GROUP BY g.genre_name
ORDER BY title_count DESC
LIMIT 10;

-- Business Interpretation:
-- International Movies and Dramas are the largest genres, reflecting
-- Netflix's global content strategy. The high representation of
-- International content shows Netflix's commitment to non-English markets.


-- ============================================================================
-- QUESTION 4: How has Netflix content changed over time?
-- ============================================================================
-- Business Context: Track Netflix's content acquisition velocity and
-- identify acceleration/deceleration periods.

WITH yearly_content AS (
    SELECT 
        EXTRACT(YEAR FROM date_added)::INTEGER AS year_added,
        COUNT(*) AS titles_added,
        COUNT(CASE WHEN type = 'Movie' THEN 1 END) AS movies,
        COUNT(CASE WHEN type = 'TV Show' THEN 1 END) AS tv_shows
    FROM titles
    WHERE date_added IS NOT NULL
    GROUP BY EXTRACT(YEAR FROM date_added)
)
SELECT 
    year_added,
    titles_added,
    movies,
    tv_shows,
    LAG(titles_added) OVER (ORDER BY year_added) AS prev_year,
    ROUND(
        (titles_added - LAG(titles_added) OVER (ORDER BY year_added)) * 100.0 /
        NULLIF(LAG(titles_added) OVER (ORDER BY year_added), 0), 1
    ) AS yoy_growth_pct
FROM yearly_content
ORDER BY year_added;

-- Business Interpretation:
-- Netflix saw explosive content growth from 2015-2019, with the highest
-- absolute additions around 2019. The growth rate shows the transition
-- from a licensing model to a content production powerhouse.


-- ============================================================================
-- QUESTION 5: Which year had the highest number of releases?
-- ============================================================================
-- Business Context: Identify peak production/acquisition years.

SELECT 
    release_year,
    COUNT(*) AS title_count,
    COUNT(CASE WHEN type = 'Movie' THEN 1 END) AS movies,
    COUNT(CASE WHEN type = 'TV Show' THEN 1 END) AS tv_shows
FROM titles
GROUP BY release_year
ORDER BY title_count DESC
LIMIT 5;

-- Business Interpretation:
-- Recent years (2017-2020) show the highest release counts, confirming
-- Netflix's rapid content expansion strategy. This aligns with their
-- shift toward original content production.


-- ============================================================================
-- QUESTION 6: Which countries have the highest Movie-to-TV Show ratio?
-- ============================================================================
-- Business Context: Understand regional content preferences.
-- Some markets may prefer movies while others favor serialized TV content.

WITH country_type_counts AS (
    SELECT 
        c.country_name,
        COUNT(DISTINCT tc.show_id) AS total,
        COUNT(DISTINCT CASE WHEN t.type = 'Movie' THEN tc.show_id END) AS movies,
        COUNT(DISTINCT CASE WHEN t.type = 'TV Show' THEN tc.show_id END) AS tv_shows
    FROM title_countries tc
    INNER JOIN countries c ON tc.country_id = c.country_id
    INNER JOIN titles t ON tc.show_id = t.show_id
    WHERE c.country_name != 'Unknown'
    GROUP BY c.country_name
    HAVING COUNT(DISTINCT tc.show_id) >= 50  -- Only countries with significant catalog
)
SELECT 
    country_name,
    total,
    movies,
    tv_shows,
    ROUND(movies * 1.0 / NULLIF(tv_shows, 0), 2) AS movie_to_tv_ratio,
    ROUND(movies * 100.0 / total, 1) AS movie_pct
FROM country_type_counts
ORDER BY movie_to_tv_ratio DESC
LIMIT 10;

-- Business Interpretation:
-- Countries like India tend to have a higher Movie-to-TV ratio, reflecting
-- Bollywood's dominance. Countries like Japan and South Korea may show
-- more balanced ratios due to strong anime/drama TV production.


-- ============================================================================
-- QUESTION 7: What are the top 10 directors on Netflix?
-- ============================================================================
-- Business Context: Identify key creative partners and potential talent
-- for future collaborations.

SELECT 
    p.person_name AS director,
    COUNT(DISTINCT td.show_id) AS title_count,
    STRING_AGG(DISTINCT t.type, ', ') AS content_types,
    MIN(t.release_year) AS first_title_year,
    MAX(t.release_year) AS latest_title_year
FROM title_directors td
INNER JOIN people p ON td.person_id = p.person_id
INNER JOIN titles t ON td.show_id = t.show_id
WHERE p.person_name != 'Unknown'
GROUP BY p.person_name
ORDER BY title_count DESC
LIMIT 10;

-- Business Interpretation:
-- The most prolific directors on Netflix often work in specific niches
-- (e.g., stand-up comedy specials, international films). These directors
-- represent reliable content producers for the platform.


-- ============================================================================
-- QUESTION 8: What are the most common content ratings?
-- ============================================================================
-- Business Context: Understand the audience targeting of Netflix's catalog.
-- This affects advertising partnerships and parental controls strategy.

SELECT 
    rating,
    COUNT(*) AS title_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS percentage,
    SUM(COUNT(*)) OVER (ORDER BY COUNT(*) DESC) AS running_total,
    ROUND(
        SUM(COUNT(*)) OVER (ORDER BY COUNT(*) DESC) * 100.0 / SUM(COUNT(*)) OVER(), 2
    ) AS cumulative_pct
FROM titles
GROUP BY rating
ORDER BY title_count DESC;

-- Business Interpretation:
-- TV-MA (mature audiences) dominates the catalog, followed by TV-14.
-- Together, these two ratings likely cover 60%+ of all content,
-- indicating Netflix primarily targets adult and teen audiences.
-- Kids content (TV-Y, TV-G) is a smaller but important segment.


-- ============================================================================
-- QUESTION 9: Which genres are most common among TV Shows?
-- ============================================================================
-- Business Context: Guides TV Show production and licensing decisions.

SELECT 
    g.genre_name,
    COUNT(DISTINCT tg.show_id) AS show_count
FROM title_genres tg
INNER JOIN genres g ON tg.genre_id = g.genre_id
INNER JOIN titles t ON tg.show_id = t.show_id
WHERE t.type = 'TV Show'
GROUP BY g.genre_name
ORDER BY show_count DESC
LIMIT 10;

-- Business Interpretation:
-- International TV Shows and TV Dramas are the most common TV Show genres,
-- reflecting Netflix's investment in global serialized content.
-- Kids' TV is also a significant category, showing the family audience focus.


-- ============================================================================
-- QUESTION 10: Which genres are most common among Movies?
-- ============================================================================
-- Business Context: Guides movie production and acquisition decisions.

SELECT 
    g.genre_name,
    COUNT(DISTINCT tg.show_id) AS movie_count
FROM title_genres tg
INNER JOIN genres g ON tg.genre_id = g.genre_id
INNER JOIN titles t ON tg.show_id = t.show_id
WHERE t.type = 'Movie'
GROUP BY g.genre_name
ORDER BY movie_count DESC
LIMIT 10;

-- Business Interpretation:
-- International Movies and Dramas dominate the movie catalog.
-- Comedies and Action/Adventure are also strongly represented.
-- This diversity shows Netflix's broad appeal strategy across genres.


-- ============================================================================
-- QUESTION 11: Which countries have the most titles in each genre?
-- ============================================================================
-- Business Context: Understand regional genre strengths to guide
-- co-production strategies.

WITH country_genre AS (
    SELECT 
        c.country_name,
        g.genre_name,
        COUNT(DISTINCT t.show_id) AS title_count,
        ROW_NUMBER() OVER (
            PARTITION BY g.genre_name 
            ORDER BY COUNT(DISTINCT t.show_id) DESC
        ) AS country_rank
    FROM titles t
    INNER JOIN title_genres tg ON t.show_id = tg.show_id
    INNER JOIN genres g ON tg.genre_id = g.genre_id
    INNER JOIN title_countries tc ON t.show_id = tc.show_id
    INNER JOIN countries c ON tc.country_id = c.country_id
    WHERE c.country_name != 'Unknown'
    GROUP BY c.country_name, g.genre_name
)
SELECT 
    genre_name,
    country_name AS top_country,
    title_count
FROM country_genre
WHERE country_rank = 1
ORDER BY title_count DESC;

-- Business Interpretation:
-- The US dominates most genre categories. India leads in certain genre
-- areas, particularly Dramas and International content. Japan leads in
-- Anime. This data helps identify regional content strengths.


-- ============================================================================
-- QUESTION 12: What percentage of Netflix titles are Movies vs TV Shows?
-- ============================================================================
-- Business Context: High-level content mix KPI for executive reporting.

SELECT 
    type,
    COUNT(*) AS count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS percentage,
    ROUND(
        COUNT(*) * 1.0 / (SELECT COUNT(*) FROM titles WHERE type = 
            CASE WHEN type = 'Movie' THEN 'TV Show' ELSE 'Movie' END
        ), 2
    ) AS ratio_to_other
FROM titles
GROUP BY type;

-- Business Interpretation:
-- Movies represent approximately 69% while TV Shows represent about 31%.
-- The Movie-to-TV-Show ratio is roughly 2.2:1.
-- This ratio has been shifting over time as Netflix invests more in
-- original TV series that drive subscriber retention.


-- ============================================================================
-- QUESTION 13: Which year showed the highest year-over-year growth?
-- ============================================================================
-- Business Context: Identify inflection points in Netflix's content strategy.

WITH yearly_additions AS (
    SELECT 
        EXTRACT(YEAR FROM date_added)::INTEGER AS year_added,
        COUNT(*) AS titles_added
    FROM titles
    WHERE date_added IS NOT NULL
    GROUP BY EXTRACT(YEAR FROM date_added)
),
growth AS (
    SELECT 
        year_added,
        titles_added,
        LAG(titles_added) OVER (ORDER BY year_added) AS prev_year_titles,
        titles_added - LAG(titles_added) OVER (ORDER BY year_added) AS absolute_growth,
        ROUND(
            (titles_added - LAG(titles_added) OVER (ORDER BY year_added)) * 100.0 /
            NULLIF(LAG(titles_added) OVER (ORDER BY year_added), 0), 1
        ) AS growth_pct
    FROM yearly_additions
)
SELECT *
FROM growth
WHERE prev_year_titles IS NOT NULL  -- Exclude first year (no comparison)
ORDER BY growth_pct DESC
LIMIT 5;

-- Business Interpretation:
-- The year with the highest percentage growth indicates when Netflix
-- most aggressively expanded its content library. Early years show
-- high growth rates (from a small base), while later years show the
-- absolute volume increase that built the catalog we see today.


-- ============================================================================
-- QUESTION 14: What are the top 3 genres in each major content-producing country?
-- ============================================================================
-- Business Context: Enables regional content strategy by showing what
-- genres each country specializes in.

WITH major_countries AS (
    SELECT c.country_name
    FROM title_countries tc
    INNER JOIN countries c ON tc.country_id = c.country_id
    WHERE c.country_name != 'Unknown'
    GROUP BY c.country_name
    HAVING COUNT(DISTINCT tc.show_id) >= 100
),
country_genre_counts AS (
    SELECT 
        c.country_name,
        g.genre_name,
        COUNT(DISTINCT t.show_id) AS title_count
    FROM titles t
    INNER JOIN title_genres tg ON t.show_id = tg.show_id
    INNER JOIN genres g ON tg.genre_id = g.genre_id
    INNER JOIN title_countries tc ON t.show_id = tc.show_id
    INNER JOIN countries c ON tc.country_id = c.country_id
    WHERE c.country_name IN (SELECT country_name FROM major_countries)
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
    MAX(CASE WHEN genre_rank = 1 THEN genre_name || ' (' || title_count || ')' END) AS top_1_genre,
    MAX(CASE WHEN genre_rank = 2 THEN genre_name || ' (' || title_count || ')' END) AS top_2_genre,
    MAX(CASE WHEN genre_rank = 3 THEN genre_name || ' (' || title_count || ')' END) AS top_3_genre
FROM ranked
WHERE genre_rank <= 3
GROUP BY country_name
ORDER BY country_name;

-- Business Interpretation:
-- Each country has distinct genre preferences. The US focuses on Dramas
-- and Comedies. India emphasizes International Movies and Dramas.
-- Japan highlights Anime. This guides regional content investment.


-- ============================================================================
-- QUESTION 15: Which directors have produced the most Netflix titles?
-- ============================================================================
-- Business Context: Identify key creative partners for long-term deals
-- and understand director productivity patterns.

WITH director_stats AS (
    SELECT 
        p.person_name AS director,
        COUNT(DISTINCT td.show_id) AS total_titles,
        COUNT(DISTINCT CASE WHEN t.type = 'Movie' THEN t.show_id END) AS movies,
        COUNT(DISTINCT CASE WHEN t.type = 'TV Show' THEN t.show_id END) AS tv_shows,
        STRING_AGG(DISTINCT t.rating, ', ' ORDER BY t.rating) AS ratings,
        MIN(t.release_year) AS career_start,
        MAX(t.release_year) AS latest_release,
        ROUND(AVG(
            CASE WHEN t.type = 'Movie' THEN t.duration_value END
        ), 0) AS avg_movie_duration
    FROM title_directors td
    INNER JOIN people p ON td.person_id = p.person_id
    INNER JOIN titles t ON td.show_id = t.show_id
    WHERE p.person_name != 'Unknown'
    GROUP BY p.person_name
    HAVING COUNT(DISTINCT td.show_id) >= 5
)
SELECT 
    director,
    total_titles,
    movies,
    tv_shows,
    ratings,
    career_start || '-' || latest_release AS active_period,
    COALESCE(avg_movie_duration || ' min', 'N/A') AS avg_movie_length,
    DENSE_RANK() OVER (ORDER BY total_titles DESC) AS rank
FROM director_stats
ORDER BY total_titles DESC
LIMIT 15;

-- Business Interpretation:
-- The most prolific Netflix directors often specialize in specific
-- content types (e.g., stand-up comedy, documentaries, or international
-- cinema). Directors with high title counts and consistent ratings
-- represent reliable content partners.


-- ============================================================================
-- ADVANCED KPIS DASHBOARD
-- ============================================================================
-- A comprehensive summary of key performance indicators for Netflix content.

SELECT 
    'Total Titles' AS metric, COUNT(*)::TEXT AS value FROM titles
UNION ALL
SELECT 'Total Movies', COUNT(*)::TEXT FROM titles WHERE type = 'Movie'
UNION ALL
SELECT 'Total TV Shows', COUNT(*)::TEXT FROM titles WHERE type = 'TV Show'
UNION ALL
SELECT 'Movie Percentage', ROUND(
    COUNT(CASE WHEN type = 'Movie' THEN 1 END) * 100.0 / COUNT(*), 2
)::TEXT || '%' FROM titles
UNION ALL
SELECT 'TV Show Percentage', ROUND(
    COUNT(CASE WHEN type = 'TV Show' THEN 1 END) * 100.0 / COUNT(*), 2
)::TEXT || '%' FROM titles
UNION ALL
SELECT 'Unique Countries', (
    SELECT COUNT(DISTINCT country_name)::TEXT FROM countries WHERE country_name != 'Unknown'
)
UNION ALL
SELECT 'Unique Genres', (SELECT COUNT(*)::TEXT FROM genres)
UNION ALL
SELECT 'Avg Movie Duration (min)', (
    SELECT ROUND(AVG(duration_value), 1)::TEXT
    FROM titles WHERE type = 'Movie' AND duration_unit = 'min'
)
UNION ALL
SELECT 'Avg Release Year', (SELECT ROUND(AVG(release_year), 0)::TEXT FROM titles)
UNION ALL
SELECT 'Most Common Rating', (
    SELECT rating FROM titles GROUP BY rating ORDER BY COUNT(*) DESC LIMIT 1
)
UNION ALL
SELECT 'Top Content Country', (
    SELECT c.country_name
    FROM title_countries tc
    INNER JOIN countries c ON tc.country_id = c.country_id
    WHERE c.country_name != 'Unknown'
    GROUP BY c.country_name
    ORDER BY COUNT(DISTINCT tc.show_id) DESC LIMIT 1
)
UNION ALL
SELECT 'Top Genre', (
    SELECT g.genre_name
    FROM title_genres tg
    INNER JOIN genres g ON tg.genre_id = g.genre_id
    GROUP BY g.genre_name
    ORDER BY COUNT(DISTINCT tg.show_id) DESC LIMIT 1
);


SELECT 'Business questions analysis complete!' AS status;
