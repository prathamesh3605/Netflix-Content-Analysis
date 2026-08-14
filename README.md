Netflix Content Analysis Using SQL
> **Analyzed 7,777 Netflix titles using CTEs, window functions, and multi-table JOINs; automated data cleaning and transformation with Pandas, significantly reducing preprocessing time through a fully reproducible pipeline.**
![Python](https://img.shields.io/badge/Python-3.x-blue?logo=python)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-15+-blue?logo=postgresql)
![Pandas](https://img.shields.io/badge/Pandas-2.0+-green?logo=pandas)
![Status](https://img.shields.io/badge/Status-Complete-brightgreen)
---
Overview
This project performs comprehensive analysis of Netflix's content catalog (7,777 Movies and TV Shows) using PostgreSQL for advanced SQL analysis and Python/Pandas for data cleaning, transformation, and visualization.
The project demonstrates practical data analytics skills including:
SQL: CTEs, window functions (RANK, LAG, LEAD, SUM OVER), multi-table JOINs, subqueries, CASE statements
Python: Automated data cleaning pipeline, Pandas DataFrames, Matplotlib/Seaborn visualization
Database Design: Normalized PostgreSQL schema with 8 tables and junction tables
Business Intelligence: 15 business questions with data-driven answers
Business Problem
Netflix needs to understand its content library to make data-driven decisions about:
Content acquisition and production strategy
Regional content preferences
Genre investment priorities
Audience targeting based on rating distribution
Year-over-year growth tracking
This analysis provides actionable insights by examining content distribution by type, country, genre, rating, and temporal trends.
Objectives
Clean and preprocess 7,787 raw records into analysis-ready data
Design a normalized PostgreSQL database schema
Answer 15+ business questions using SQL (basic through advanced)
Demonstrate advanced SQL skills: CTEs, window functions, multi-table JOINs
Create professional visualizations with Python
Build a fully automated, reproducible data pipeline
---
Dataset
Source: Netflix Movies and TV Shows Dataset (Kaggle, by Shivam Bansal)
Metric	Value
Total Records (raw)	7,787
Total Records (cleaned)	7,777
Columns (raw)	12
Columns (cleaned)	17
Movies	5,377 (69.1%)
TV Shows	2,400 (30.9%)
Release Year Range	1925 - 2021
Date Added Range	2008 - 2021
Column Descriptions
Column	Type	Description
show_id	str	Unique identifier (e.g., s1, s2)
type	str	"Movie" or "TV Show"
title	str	Title of the content
director	str	Director name(s), comma-separated
cast	str	Cast member names, comma-separated
country	str	Production country/countries
date_added	date	Date added to Netflix
release_year	int	Original release year
rating	str	Content rating (TV-MA, PG-13, etc.)
duration	str	Duration ("90 min" or "3 Seasons")
listed_in	str	Genre categories
description	str	Content description
Data Quality Issues Found
Issue	Count	Resolution
Missing director	2,389 (30.7%)	Filled with "Unknown"
Missing cast	718 (9.2%)	Filled with "Unknown"
Missing country	507 (6.5%)	Filled with "Unknown"
Missing date_added	10 (0.13%)	Rows dropped
Missing rating	7 (0.09%)	Filled with "Unrated"
Whitespace issues	89 values	Stripped in cleaning
Duplicates	0	None found
---
Technologies Used
Technology	Purpose
Python 3.x	Data processing, automation
Pandas	Data cleaning, transformation, analysis
NumPy	Numerical operations
Matplotlib	Data visualization
Seaborn	Statistical visualization
PostgreSQL	Relational database, SQL analysis
psycopg2	Python-PostgreSQL connectivity
SQLAlchemy	Database ORM/engine
Jupyter Notebook	Interactive analysis
---
Project Architecture
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
Database Schema
The project uses a normalized relational schema with 8 tables to demonstrate multi-table JOINs:
```
titles (show_id PK)
  |-- title_directors --> people (person_id PK)
  |-- title_cast -------> people (person_id PK)
  |-- title_countries --> countries (country_id PK)
  |-- title_genres -----> genres (genre_id PK)
```
Why normalize?
Eliminates redundant storage of repeated names
Enables clean multi-table JOINs (a key SQL skill)
Follows relational database best practices
Handles many-to-many relationships properly (e.g., a movie can have multiple genres)
Tables
Table	Description	Key Columns
`titles`	Core content data	show_id (PK), title, type, release_year
`people`	Directors and actors	person_id (PK), person_name
`title_directors`	Title-director links	show_id (FK), person_id (FK)
`title_cast`	Title-actor links	show_id (FK), person_id (FK)
`countries`	Country lookup	country_id (PK), country_name
`title_countries`	Title-country links	show_id (FK), country_id (FK)
`genres`	Genre lookup	genre_id (PK), genre_name
`title_genres`	Title-genre links	show_id (FK), genre_id (FK)
---
Data Cleaning
The automated pipeline (`src/data_cleaning.py`) performs:
Load raw CSV (7,787 rows)
Quality analysis: missing values, duplicates, data types, unique values
Missing value handling with documented strategies per column
Type conversion: `date_added` string to datetime
Text standardization: strip whitespace across 9 columns
Feature engineering: 5 derived columns (duration_value, duration_unit, year_added, month_added, month_name_added)
Export cleaned CSV (7,777 rows)
Run time: ~0.5 seconds (fully automated, reproducible)
---
SQL Analysis
Basic SQL (10 queries)
Demonstrates: `SELECT`, `WHERE`, `GROUP BY`, `HAVING`, `COUNT`, `AVG`, `MIN`, `MAX`, `CASE WHEN`
Advanced SQL Techniques
CTEs (Common Table Expressions)
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
Window Functions
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
Multi-table JOINs
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
Subqueries, CASE Statements, Aggregations
All demonstrated throughout 25+ total queries.
---
Python Analysis
The Pandas-based analysis (`src/analysis.py`) computes:
Key Performance Indicators
KPI	Value
Total Titles	7,777
Total Movies	5,377 (69.1%)

Total TV Shows	2,400 (30.9%)
Unique Countries	121
Unique Genres	42
Avg Movie Duration	99.3 min
Most Common Rating	TV-MA
Top Country	United States (3,290)
Top Genre	International Movies (2,437)
---
Visualizations
10 professional visualizations with Netflix-inspired dark theme:
#	Chart	Type
1	Movies vs TV Shows	Donut chart
2	Content growth over time	Line chart
3	Top 10 countries	Horizontal bar
4	Top 10 genres	Horizontal bar
5	Rating distribution	Bar chart
6	Movie duration distribution	Histogram
7	Release year distribution	Histogram
8	Top 10 directors	Horizontal bar
9	Year-over-year growth	Dual-axis bar + line
10	Country content by type	Stacked bar
---
Key Insights
Based on analysis of 7,777 Netflix titles:
Movies dominate the catalog at 69.1% (5,377 titles) vs TV Shows at 30.9% (2,400 titles)
United States is the top content producer with 3,290 titles, followed by India (990) and UK (721)
International Movies (2,437) and Dramas (2,106) are the most common genres
TV-MA is the most common rating (2,861 titles, ~37%), indicating Netflix primarily targets adult audiences
2016 saw 403% YoY growth in content additions - the year Netflix began its massive content expansion
2019 was the peak year with 2,153 titles added, before the 2020 pandemic slowdown
Average movie duration is 99.3 minutes (median: 98 min)
Netflix has content from 121 countries across 42 distinct genres
TV-MA + TV-14 together account for ~62% of all content (adult + teen)
Content additions dropped significantly in 2020-2021, likely due to COVID-19 production delays
---
How to Run
Prerequisites
Python 3.8+
PostgreSQL 12+ (optional - SQL files can be studied standalone)
Setup
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
Run the Data Pipeline
```bash
# Step 1: Clean the raw data
python src/data_cleaning.py

# Step 2: Run analysis (no PostgreSQL needed)
python src/analysis.py --analyze

# Step 3: Generate visualizations
python src/generate_visualizations.py
```
PostgreSQL Setup (Optional)
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
Jupyter Notebook
```bash
jupyter notebook notebooks/netflix_analysis.ipynb
```
---
License
This project is for educational and portfolio purposes. The Netflix dataset is publicly available on Kaggle.
