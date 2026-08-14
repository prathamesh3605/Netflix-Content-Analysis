# Netflix Content Analysis Using SQL

> **Analyzed 7,777 Netflix titles using CTEs, window functions, and multi-table JOINs; automated data cleaning and transformation with Pandas, significantly reducing preprocessing time through a fully reproducible pipeline.**

![Python](https://img.shields.io/badge/Python-3.x-blue?logo=python)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-15+-blue?logo=postgresql)
![Pandas](https://img.shields.io/badge/Pandas-2.0+-green?logo=pandas)
![Status](https://img.shields.io/badge/Status-Complete-brightgreen)

---

## Overview

This project performs comprehensive analysis of Netflix's content catalog (7,777 Movies and TV Shows) using **PostgreSQL** for advanced SQL analysis and **Python/Pandas** for data cleaning, transformation, and visualization.

The project demonstrates practical data analytics skills including:
- **SQL**: CTEs, window functions (RANK, LAG, LEAD, SUM OVER), multi-table JOINs, subqueries, CASE statements
- **Python**: Automated data cleaning pipeline, Pandas DataFrames, Matplotlib/Seaborn visualization
- **Database Design**: Normalized PostgreSQL schema with 8 tables and junction tables
- **Business Intelligence**: 15 business questions with data-driven answers

## Business Problem

Netflix needs to understand its content library to make data-driven decisions about:
- Content acquisition and production strategy
- Regional content preferences
- Genre investment priorities
- Audience targeting based on rating distribution
- Year-over-year growth tracking

This analysis provides actionable insights by examining content distribution by type, country, genre, rating, and temporal trends.

## Objectives

1. Clean and preprocess 7,787 raw records into analysis-ready data
2. Design a normalized PostgreSQL database schema
3. Answer 15+ business questions using SQL (basic through advanced)
4. Demonstrate advanced SQL skills: CTEs, window functions, multi-table JOINs
5. Create professional visualizations with Python
6. Build a fully automated, reproducible data pipeline

---

## Dataset

**Source**: [Netflix Movies and TV Shows Dataset](https://www.kaggle.com/datasets/shivamb/netflix-shows) (Kaggle, by Shivam Bansal)

| Metric | Value |
|--------|-------|
| Total Records (raw) | 7,787 |
| Total Records (cleaned) | 7,777 |
| Columns (raw) | 12 |
| Columns (cleaned) | 17 |
| Movies | 5,377 (69.1%) |
| TV Shows | 2,400 (30.9%) |
| Release Year Range | 1925 - 2021 |
| Date Added Range | 2008 - 2021 |

### Column Descriptions

| Column | Type | Description |
|--------|------|-------------|
| show_id | str | Unique identifier (e.g., s1, s2) |
| type | str | "Movie" or "TV Show" |
| title | str | Title of the content |
| director | str | Director name(s), comma-separated |
| cast | str | Cast member names, comma-separated |
| country | str | Production country/countries |
| date_added | date | Date added to Netflix |
| release_year | int | Original release year |
| rating | str | Content rating (TV-MA, PG-13, etc.) |
| duration | str | Duration ("90 min" or "3 Seasons") |
| listed_in | str | Genre categories |
| description | str | Content description |

### Data Quality Issues Found

| Issue | Count | Resolution |
|-------|-------|------------|
| Missing director | 2,389 (30.7%) | Filled with "Unknown" |
| Missing cast | 718 (9.2%) | Filled with "Unknown" |
| Missing country | 507 (6.5%) | Filled with "Unknown" |
| Missing date_added | 10 (0.13%) | Rows dropped |
| Missing rating | 7 (0.09%) | Filled with "Unrated" |
| Whitespace issues | 89 values | Stripped in cleaning |
| Duplicates | 0 | None found |

---

## Technologies Used

| Technology | Purpose |
|-----------|---------|
| **Python 3.x** | Data processing, automation |
| **Pandas** | Data cleaning, transformation, analysis |
| **NumPy** | Numerical operations |
| **Matplotlib** | Data visualization |
| **Seaborn** | Statistical visualization |
| **PostgreSQL** | Relational database, SQL analysis |
| **psycopg2** | Python-PostgreSQL connectivity |
| **SQLAlchemy** | Database ORM/engine |
| **Jupyter Notebook** | Interactive analysis |

---

## Project Architecture

```
Netflix-Content-Analysis/
|
|-- data/
|   |-- raw/                       # Original dataset
|   |   |-- netflix_titles.csv     # 7,787 raw records
|   |-- processed/                 # Cleaned dataset
|       |-- netflix_cleaned.csv    # 7,777 cleaned records
|
|-- notebooks/
|   |-- netflix_analysis.ipynb     # Jupyter EDA notebook
|
|-- sql/
|   |-- 01_database_setup.sql      # PostgreSQL schema (8 tables)
|   |-- 02_data_cleaning.sql       # SQL data validation
|   |-- 03_basic_analysis.sql      # 10 basic SQL queries
|   |-- 04_advanced_analysis.sql   # 15+ advanced queries (CTEs, window functions)
|   |-- 05_business_questions.sql  # 15 business questions with answers
|
|-- src/
|   |-- data_cleaning.py           # Automated cleaning pipeline
|   |-- analysis.py                # Analysis & PostgreSQL integration
|   |-- generate_visualizations.py # Chart generation script
|
|-- visualizations/                # Generated charts (PNG)
|
|-- requirements.txt
|-- README.md
|-- .gitignore
```

---

## Database Schema

The project uses a **normalized relational schema** with 8 tables to demonstrate multi-table JOINs:

```
titles (show_id PK)
  |-- title_directors --> people (person_id PK)
  |-- title_cast -------> people (person_id PK)
  |-- title_countries --> countries (country_id PK)
  |-- title_genres -----> genres (genre_id PK)
```

**Why normalize?**
- Eliminates redundant storage of repeated names
- Enables clean multi-table JOINs (a key SQL skill)
- Follows relational database best practices
- Handles many-to-many relationships properly (e.g., a movie can have multiple genres)

### Tables

| Table | Description | Key Columns |
|-------|------------|-------------|
| `titles` | Core content data | show_id (PK), title, type, release_year |
| `people` | Directors and actors | person_id (PK), person_name |
| `title_directors` | Title-director links | show_id (FK), person_id (FK) |
| `title_cast` | Title-actor links | show_id (FK), person_id (FK) |
| `countries` | Country lookup | country_id (PK), country_name |
| `title_countries` | Title-country links | show_id (FK), country_id (FK) |
| `genres` | Genre lookup | genre_id (PK), genre_name |
| `title_genres` | Title-genre links | show_id (FK), genre_id (FK) |

---

## Data Cleaning

The automated pipeline (`src/data_cleaning.py`) performs:

1. **Load** raw CSV (7,787 rows)
2. **Quality analysis**: missing values, duplicates, data types, unique values
3. **Missing value handling** with documented strategies per column
4. **Type conversion**: `date_added` string to datetime
5. **Text standardization**: strip whitespace across 9 columns
6. **Feature engineering**: 5 derived columns (duration_value, duration_unit, year_added, month_added, month_name_added)
7. **Export** cleaned CSV (7,777 rows)

**Run time**: ~0.5 seconds (fully automated, reproducible)

---

## SQL Analysis

### Basic SQL (10 queries)
Demonstrates: `SELECT`, `WHERE`, `GROUP BY`, `HAVING`, `COUNT`, `AVG`, `MIN`, `MAX`, `CASE WHEN`

### Advanced SQL Techniques

#### CTEs (Common Table Expressions)
```sql
-- Example: Year-over-year content growth
WITH yearly_content AS (
    SELECT EXTRACT(YEAR FROM date_added) AS year_added,
           COUNT(*) AS titles_added
    FROM titles
    GROUP BY EXTRACT(YEAR FROM date_added)
)
SELECT year_added, titles_added,
       ROUND(titles_added * 100.0 / SUM(titles_added) OVER(), 2) AS pct_of_total
FROM yearly_content
ORDER BY year_added;
```

#### Window Functions
```sql
-- Example: Rank countries and calculate YoY growth with LAG
WITH yearly_additions AS (
    SELECT EXTRACT(YEAR FROM date_added)::INTEGER AS year_added,
           COUNT(*) AS titles_added
    FROM titles GROUP BY EXTRACT(YEAR FROM date_added)
)
SELECT year_added, titles_added,
       LAG(titles_added, 1) OVER (ORDER BY year_added) AS prev_year,
       ROUND(
           (titles_added - LAG(titles_added, 1) OVER (ORDER BY year_added)) * 100.0 /
           NULLIF(LAG(titles_added, 1) OVER (ORDER BY year_added), 0), 1
       ) AS growth_pct
FROM yearly_additions ORDER BY year_added;
```

Functions used: `ROW_NUMBER()`, `RANK()`, `DENSE_RANK()`, `LAG()`, `LEAD()`, `SUM() OVER()`, `AVG() OVER()`

#### Multi-table JOINs
```sql
-- Example: 5-table JOIN - Top genres by country
SELECT c.country_name, g.genre_name, COUNT(DISTINCT t.show_id) AS title_count
FROM titles t
INNER JOIN title_genres tg ON t.show_id = tg.show_id
INNER JOIN genres g ON tg.genre_id = g.genre_id
INNER JOIN title_countries tc ON t.show_id = tc.show_id
INNER JOIN countries c ON tc.country_id = c.country_id
GROUP BY c.country_name, g.genre_name
ORDER BY title_count DESC;
```

#### Subqueries, CASE Statements, Aggregations
All demonstrated throughout 25+ total queries.

---

## Python Analysis

The Pandas-based analysis (`src/analysis.py`) computes:

### Key Performance Indicators
| KPI | Value |
|-----|-------|
| Total Titles | 7,777 |
| Total Movies | 5,377 (69.1%) |
| Total TV Shows | 2,400 (30.9%) |
| Unique Countries | 121 |
| Unique Genres | 42 |
| Avg Movie Duration | 99.3 min |
| Most Common Rating | TV-MA |
| Top Country | United States (3,290) |
| Top Genre | International Movies (2,437) |

---

## Visualizations

10 professional visualizations with Netflix-inspired dark theme:

| # | Chart | Type |
|---|-------|------|
| 1 | Movies vs TV Shows | Donut chart |
| 2 | Content growth over time | Line chart |
| 3 | Top 10 countries | Horizontal bar |
| 4 | Top 10 genres | Horizontal bar |
| 5 | Rating distribution | Bar chart |
| 6 | Movie duration distribution | Histogram |
| 7 | Release year distribution | Histogram |
| 8 | Top 10 directors | Horizontal bar |
| 9 | Year-over-year growth | Dual-axis bar + line |
| 10 | Country content by type | Stacked bar |

---

## Key Insights

Based on analysis of 7,777 Netflix titles:

1. **Movies dominate** the catalog at 69.1% (5,377 titles) vs TV Shows at 30.9% (2,400 titles)
2. **United States** is the top content producer with 3,290 titles, followed by India (990) and UK (721)
3. **International Movies** (2,437) and **Dramas** (2,106) are the most common genres
4. **TV-MA** is the most common rating (2,861 titles, ~37%), indicating Netflix primarily targets adult audiences
5. **2016 saw 403% YoY growth** in content additions - the year Netflix began its massive content expansion
6. **2019 was the peak year** with 2,153 titles added, before the 2020 pandemic slowdown
7. Average movie duration is **99.3 minutes** (median: 98 min)
8. Netflix has content from **121 countries** across **42 distinct genres**
9. **TV-MA + TV-14** together account for ~62% of all content (adult + teen)
10. Content additions dropped significantly in 2020-2021, likely due to COVID-19 production delays

---

## How to Run

### Prerequisites
- Python 3.8+
- PostgreSQL 12+ (optional - SQL files can be studied standalone)

### Setup

```bash
# Clone the repository
git clone https://github.com/yourusername/Netflix-Content-Analysis.git
cd Netflix-Content-Analysis

# Create virtual environment
python -m venv venv

# Activate (Windows)
venv\Scripts\activate
# Activate (Mac/Linux)
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt
```

### Run the Data Pipeline

```bash
# Step 1: Clean the raw data
python src/data_cleaning.py

# Step 2: Run analysis (no PostgreSQL needed)
python src/analysis.py --analyze

# Step 3: Generate visualizations
python src/generate_visualizations.py
```

### PostgreSQL Setup (Optional)

```bash
# Create the database
psql -U postgres -c "CREATE DATABASE netflix_analysis;"

# Create the schema
psql -U postgres -d netflix_analysis -f sql/01_database_setup.sql

# Load data into PostgreSQL
# (Update DB_CONFIG in src/analysis.py with your credentials first)
python src/analysis.py --load-data

# Run SQL validation
psql -U postgres -d netflix_analysis -f sql/02_data_cleaning.sql

# Run SQL analysis
psql -U postgres -d netflix_analysis -f sql/03_basic_analysis.sql
psql -U postgres -d netflix_analysis -f sql/04_advanced_analysis.sql
psql -U postgres -d netflix_analysis -f sql/05_business_questions.sql
```

### Jupyter Notebook

```bash
jupyter notebook notebooks/netflix_analysis.ipynb
```

---

## Future Improvements

- **Power BI / Tableau Dashboard**: Interactive visualization dashboard
- **Automated ETL Pipeline**: Scheduled data refresh with Airflow
- **Cloud Database**: Deploy PostgreSQL on AWS RDS or Google Cloud SQL
- **Additional Datasets**: Combine with Netflix ratings, viewership, or revenue data
- **Sentiment Analysis**: Analyze content descriptions for trends
- **Recommendation Engine**: Build content similarity features

---

## Suggested Git Commits

```
1. Initial project setup and folder structure
2. Add Netflix dataset (raw CSV)
3. Implement automated data cleaning pipeline
4. Create PostgreSQL database schema (8 normalized tables)
5. Add basic SQL analysis queries (10 queries)
6. Add advanced SQL: CTEs and window functions
7. Add business questions with SQL solutions
8. Add Python EDA and analysis script
9. Add 10 professional visualizations
10. Complete project documentation and README
```

---

## Interview Preparation

### Q1: Why did you choose PostgreSQL?
**A:** PostgreSQL is the most popular open-source relational database used in production environments. It has excellent support for advanced SQL features like CTEs, window functions, and complex JOINs that I wanted to demonstrate. It's also what many companies use in their data stack.

### Q2: Why did you use Pandas for data cleaning?
**A:** Pandas is the standard Python library for tabular data manipulation. It allowed me to handle missing values, type conversions, and text standardization efficiently. The automated pipeline processes all 7,787 records in about 0.5 seconds, making it reproducible for any team member.

### Q3: What data cleaning steps did you perform?
**A:** I handled missing values (filled director/cast/country with "Unknown", dropped 10 rows with missing dates, used "Unrated" for 7 missing ratings), converted date strings to datetime, stripped whitespace from text fields, and created 5 derived columns (duration_value, duration_unit, year_added, month_added, month_name_added).

### Q4: What is a CTE and why did you use it?
**A:** A CTE (Common Table Expression) is a temporary named result set defined with the WITH keyword. It makes complex queries more readable by breaking them into logical steps. For example, I used a CTE to first calculate yearly content counts, then applied window functions to compute growth rates in the main query.

### Q5: Why did you use window functions?
**A:** Window functions let me perform calculations across related rows without collapsing them with GROUP BY. I used LAG() to compare each year's content with the previous year, ROW_NUMBER() to rank genres within each country, and SUM() OVER() to calculate cumulative growth.

### Q6: What is the difference between RANK() and DENSE_RANK()?
**A:** Both assign ranks based on values, but they handle ties differently. RANK() leaves gaps after ties (1, 2, 2, 4), while DENSE_RANK() doesn't (1, 2, 2, 3). I demonstrated both when ranking countries by content count.

### Q7: Why use LAG() instead of a self-join?
**A:** LAG() is more efficient and readable than a self-join for accessing previous row values. It avoids the overhead of joining a table to itself and clearly communicates the intent of "look at the previous row." I used it to calculate year-over-year growth percentages.

### Q8: Explain one multi-table JOIN from your project.
**A:** To find the top genre for each country, I joined 5 tables: titles -> title_genres -> genres (to get genre names) and titles -> title_countries -> countries (to get country names). The junction tables (title_genres, title_countries) connect the many-to-many relationships. I then used ROW_NUMBER() OVER (PARTITION BY country_name) to rank genres within each country.

### Q9: How did you handle missing values and why?
**A:** I used different strategies per column based on the data. For director (30.7% missing), I used "Unknown" because dropping would lose too much data. For date_added (0.13% missing, just 10 rows), I dropped those rows because the loss was negligible and dates can't be reasonably imputed. Each strategy was chosen based on the percentage missing and whether imputation would be honest.

### Q10: How did you remove duplicates?
**A:** I checked for duplicates using `df.duplicated().sum()` which found 0 duplicates in this dataset. If there had been any, I would have used `df.drop_duplicates()` keeping the first occurrence. In SQL, I would use ROW_NUMBER() OVER (PARTITION BY show_id ORDER BY date_added DESC) to identify and remove duplicates.

### Q11: How did you calculate year-over-year growth?
**A:** I used the LAG() window function: `LAG(titles_added, 1) OVER (ORDER BY year_added)` gets the previous year's count. Then I calculated growth percentage as: `(current - previous) * 100.0 / previous`. This showed that 2016 had the highest growth rate at 403%.

### Q12: How did you optimize SQL queries?
**A:** I created indexes on frequently filtered columns (type, release_year, rating, date_added) and demonstrated EXPLAIN ANALYZE to show query execution plans. For a dataset of ~7,777 rows, the performance difference is minimal, but these practices become critical at scale (100K+ rows).

### Q13: How did Python interact with PostgreSQL?
**A:** I used psycopg2 for direct database connections and SQLAlchemy for integration with Pandas. The workflow is: Python connects to PostgreSQL -> executes SQL query -> fetches results -> converts to Pandas DataFrame -> performs analysis/visualization. This is demonstrated in both analysis.py and the Jupyter notebook.

### Q14: What was the biggest data quality issue?
**A:** The director column had 30.7% missing values (2,389 out of 7,787). This is significant because it limits director-based analysis. I filled these with "Unknown" rather than dropping rows (which would have lost nearly a third of the data) or imputing fake names.

### Q15: What were your major business findings?
**A:** Movies dominate Netflix at 69% of content. The US produces the most content (3,290 titles), followed by India. TV-MA is the most common rating, showing Netflix targets adults. Content growth exploded from 2015-2019 (peaking at 2,153 titles in 2019), then slowed during COVID-19. International content is the largest genre category.

### Q16: How did you automate preprocessing?
**A:** I created `data_cleaning.py` - a reusable script that loads raw data, applies all cleaning steps, and exports the result in ~0.5 seconds. It's fully reproducible: any team member can run `python src/data_cleaning.py` to regenerate the cleaned dataset identically, eliminating manual spreadsheet work.

### Q17: How did you measure the preprocessing improvement?
**A:** The automated pipeline completes in approximately 0.5 seconds. Performing the same 9 steps manually (loading, inspecting, handling missing values across 5 columns, type conversion, text standardization across 9 columns for 7,777 rows, feature engineering, and export) would typically take 15-30 minutes of interactive work. The automation benefit also compounds with repeated runs.

### Q18: What would you improve if you had more time?
**A:** I would build an interactive Power BI or Tableau dashboard, add an automated ETL pipeline with Airflow for scheduled data refresh, deploy the database to a cloud service like AWS RDS, incorporate additional datasets (viewership, ratings scores), and add time-series forecasting for content growth trends.

---

## License

This project is for educational and portfolio purposes. The Netflix dataset is publicly available on Kaggle.
