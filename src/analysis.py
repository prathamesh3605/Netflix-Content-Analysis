"""
Netflix Content Analysis - Analysis & Database Loading Script
=============================================================
This script provides:
  1. PostgreSQL database loading (normalized schema)
  2. Python-PostgreSQL integration examples
  3. Standalone Pandas-based analysis (works without PostgreSQL)

Usage:
    # Load data into PostgreSQL:
    python src/analysis.py --load-data

    # Run standalone analysis (no PostgreSQL needed):
    python src/analysis.py --analyze

    # Both:
    python src/analysis.py --load-data --analyze
"""

import pandas as pd
import numpy as np
import os
import sys
import argparse
from pathlib import Path

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------
PROJECT_ROOT = Path(__file__).resolve().parent.parent
CLEANED_DATA_PATH = PROJECT_ROOT / "data" / "processed" / "netflix_cleaned.csv"
VIZ_DIR = PROJECT_ROOT / "visualizations"

# PostgreSQL connection settings (modify as needed)
DB_CONFIG = {
    "host": "localhost",
    "port": 5432,
    "database": "netflix_analysis",
    "user": "postgres",
    "password": "your_password_here"  # Change this
}


# ============================================================================
# SECTION 1: PostgreSQL Data Loading
# ============================================================================

def get_db_connection():
    """
    Create a PostgreSQL connection using psycopg2.

    Pipeline:
        Python -> psycopg2 -> PostgreSQL -> SQL Query -> Results -> Pandas
    """
    try:
        import psycopg2
        conn = psycopg2.connect(**DB_CONFIG)
        print("[OK] Connected to PostgreSQL database: " + DB_CONFIG["database"])
        return conn
    except ImportError:
        print("[!] psycopg2 not installed. Install with: pip install psycopg2-binary")
        return None
    except Exception as e:
        print(f"[!] Could not connect to PostgreSQL: {e}")
        print("    Make sure PostgreSQL is running and DB_CONFIG is correct.")
        return None


def get_sqlalchemy_engine():
    """
    Create a SQLAlchemy engine for Pandas integration.
    SQLAlchemy provides a higher-level interface for database operations.
    """
    try:
        from sqlalchemy import create_engine
        connection_string = (
            f"postgresql://{DB_CONFIG['user']}:{DB_CONFIG['password']}"
            f"@{DB_CONFIG['host']}:{DB_CONFIG['port']}/{DB_CONFIG['database']}"
        )
        engine = create_engine(connection_string)
        print("[OK] SQLAlchemy engine created.")
        return engine
    except ImportError:
        print("[!] SQLAlchemy not installed. Install with: pip install sqlalchemy")
        return None
    except Exception as e:
        print(f"[!] Could not create SQLAlchemy engine: {e}")
        return None


def load_data_to_postgres(conn, df):
    """
    Load cleaned Netflix data into the normalized PostgreSQL schema.

    This function demonstrates how to parse multi-value columns (like
    'director', 'cast', 'country', 'listed_in') from a flat CSV and
    insert them into a properly normalized relational database.
    """
    cur = conn.cursor()

    print("\n" + "=" * 60)
    print("LOADING DATA INTO POSTGRESQL")
    print("=" * 60)

    # --- Load titles ---
    print("\n[1/5] Loading titles...")
    for _, row in df.iterrows():
        cur.execute("""
            INSERT INTO titles (show_id, title, type, release_year, date_added,
                              rating, duration, duration_value, duration_unit, description)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
            ON CONFLICT (show_id) DO NOTHING
        """, (
            row["show_id"], row["title"], row["type"], row["release_year"],
            row["date_added"] if pd.notna(row["date_added"]) else None,
            row["rating"], row["duration"],
            int(row["duration_value"]) if pd.notna(row["duration_value"]) else None,
            row["duration_unit"] if pd.notna(row["duration_unit"]) else None,
            row["description"]
        ))
    conn.commit()
    print(f"   Loaded {len(df)} titles.")

    # --- Parse and load people (directors + cast) ---
    print("[2/5] Loading people (directors & cast)...")
    all_people = set()

    for _, row in df.iterrows():
        # Parse directors
        if row["director"] != "Unknown":
            for person in str(row["director"]).split(","):
                all_people.add(person.strip())
        # Parse cast
        if row["cast"] != "Unknown":
            for person in str(row["cast"]).split(","):
                all_people.add(person.strip())

    for person_name in all_people:
        if person_name:
            cur.execute("""
                INSERT INTO people (person_name) VALUES (%s)
                ON CONFLICT (person_name) DO NOTHING
            """, (person_name,))
    conn.commit()
    print(f"   Loaded {len(all_people)} unique people.")

    # --- Load title_directors ---
    print("[3/5] Loading title_directors...")
    director_links = 0
    for _, row in df.iterrows():
        if row["director"] != "Unknown":
            for director in str(row["director"]).split(","):
                director = director.strip()
                if director:
                    cur.execute("""
                        INSERT INTO title_directors (show_id, person_id)
                        SELECT %s, person_id FROM people WHERE person_name = %s
                        ON CONFLICT DO NOTHING
                    """, (row["show_id"], director))
                    director_links += 1

    # Load title_cast
    print("       Loading title_cast...")
    cast_links = 0
    for _, row in df.iterrows():
        if row["cast"] != "Unknown":
            for actor in str(row["cast"]).split(","):
                actor = actor.strip()
                if actor:
                    cur.execute("""
                        INSERT INTO title_cast (show_id, person_id)
                        SELECT %s, person_id FROM people WHERE person_name = %s
                        ON CONFLICT DO NOTHING
                    """, (row["show_id"], actor))
                    cast_links += 1
    conn.commit()
    print(f"   Loaded {director_links} director links, {cast_links} cast links.")

    # --- Parse and load countries ---
    print("[4/5] Loading countries...")
    all_countries = set()
    for _, row in df.iterrows():
        if row["country"] != "Unknown":
            for country in str(row["country"]).split(","):
                all_countries.add(country.strip())

    for country_name in all_countries:
        if country_name:
            cur.execute("""
                INSERT INTO countries (country_name) VALUES (%s)
                ON CONFLICT (country_name) DO NOTHING
            """, (country_name,))
    conn.commit()

    # Load title_countries
    country_links = 0
    for _, row in df.iterrows():
        if row["country"] != "Unknown":
            for country in str(row["country"]).split(","):
                country = country.strip()
                if country:
                    cur.execute("""
                        INSERT INTO title_countries (show_id, country_id)
                        SELECT %s, country_id FROM countries WHERE country_name = %s
                        ON CONFLICT DO NOTHING
                    """, (row["show_id"], country))
                    country_links += 1
    conn.commit()
    print(f"   Loaded {len(all_countries)} countries, {country_links} country links.")

    # --- Parse and load genres ---
    print("[5/5] Loading genres...")
    all_genres = set()
    for _, row in df.iterrows():
        for genre in str(row["listed_in"]).split(","):
            all_genres.add(genre.strip())

    for genre_name in all_genres:
        if genre_name:
            cur.execute("""
                INSERT INTO genres (genre_name) VALUES (%s)
                ON CONFLICT (genre_name) DO NOTHING
            """, (genre_name,))
    conn.commit()

    # Load title_genres
    genre_links = 0
    for _, row in df.iterrows():
        for genre in str(row["listed_in"]).split(","):
            genre = genre.strip()
            if genre:
                cur.execute("""
                    INSERT INTO title_genres (show_id, genre_id)
                    SELECT %s, genre_id FROM genres WHERE genre_name = %s
                    ON CONFLICT DO NOTHING
                """, (row["show_id"], genre))
                genre_links += 1
    conn.commit()
    print(f"   Loaded {len(all_genres)} genres, {genre_links} genre links.")

    # --- Verification ---
    print("\n" + "-" * 40)
    print("LOAD VERIFICATION")
    print("-" * 40)
    tables = ["titles", "people", "title_directors", "title_cast",
              "countries", "title_countries", "genres", "title_genres"]
    for table in tables:
        cur.execute(f"SELECT COUNT(*) FROM {table}")
        count = cur.fetchone()[0]
        print(f"   {table}: {count} rows")

    cur.close()
    print("\n[OK] Data loading complete!")


def execute_sql_query(conn, query, description=""):
    """
    Execute a SQL query and return results as a Pandas DataFrame.

    This demonstrates the Python -> PostgreSQL -> Pandas workflow:
    1. Python sends SQL query to PostgreSQL via psycopg2
    2. PostgreSQL executes the query
    3. Results are fetched and converted to a Pandas DataFrame
    4. DataFrame is ready for analysis or visualization
    """
    if description:
        print(f"\n--- {description} ---")
    try:
        df_result = pd.read_sql_query(query, conn)
        print(f"   Returned {len(df_result)} rows")
        return df_result
    except Exception as e:
        print(f"   Error: {e}")
        return pd.DataFrame()


# ============================================================================
# SECTION 2: Standalone Pandas Analysis (No PostgreSQL Required)
# ============================================================================

def run_pandas_analysis(df):
    """
    Perform comprehensive analysis using Pandas (no database needed).
    This mirrors the SQL analysis but uses Python for computation.
    """
    print("\n" + "=" * 60)
    print("NETFLIX CONTENT ANALYSIS - PANDAS")
    print("=" * 60)

    # --- KPI Summary ---
    print("\n" + "-" * 40)
    print("KEY PERFORMANCE INDICATORS")
    print("-" * 40)

    total = len(df)
    movies = len(df[df["type"] == "Movie"])
    tv_shows = len(df[df["type"] == "TV Show"])
    movie_durations = df.loc[
        (df["type"] == "Movie") & (df["duration_unit"] == "min"), "duration_value"
    ]

    # Explode multi-value columns to count unique entries
    countries_exploded = df["country"].str.split(", ").explode().str.strip()
    unique_countries = countries_exploded[countries_exploded != "Unknown"].nunique()

    genres_exploded = df["listed_in"].str.split(", ").explode().str.strip()
    unique_genres = genres_exploded.nunique()

    kpis = {
        "Total Titles": total,
        "Total Movies": movies,
        "Total TV Shows": tv_shows,
        "Movie Percentage": f"{movies * 100 / total:.1f}%",
        "TV Show Percentage": f"{tv_shows * 100 / total:.1f}%",
        "Unique Countries": unique_countries,
        "Unique Genres": unique_genres,
        "Avg Movie Duration": f"{movie_durations.mean():.1f} min",
        "Median Movie Duration": f"{movie_durations.median():.0f} min",
        "Avg Release Year": f"{df['release_year'].mean():.0f}",
        "Most Common Rating": df["rating"].mode()[0],
    }

    for metric, value in kpis.items():
        print(f"   {metric}: {value}")

    # --- Top Countries ---
    print("\n" + "-" * 40)
    print("TOP 10 COUNTRIES")
    print("-" * 40)
    top_countries = (
        countries_exploded[countries_exploded != "Unknown"]
        .value_counts()
        .head(10)
    )
    for country, count in top_countries.items():
        print(f"   {country}: {count}")

    # --- Top Genres ---
    print("\n" + "-" * 40)
    print("TOP 10 GENRES")
    print("-" * 40)
    top_genres = genres_exploded.value_counts().head(10)
    for genre, count in top_genres.items():
        print(f"   {genre}: {count}")

    # --- Year-over-Year Growth ---
    print("\n" + "-" * 40)
    print("YEAR-OVER-YEAR CONTENT GROWTH")
    print("-" * 40)
    yearly = df.groupby("year_added").size().reset_index(name="titles_added")
    yearly = yearly.sort_values("year_added")
    yearly["prev_year"] = yearly["titles_added"].shift(1)
    yearly["growth_pct"] = (
        (yearly["titles_added"] - yearly["prev_year"]) / yearly["prev_year"] * 100
    ).round(1)
    yearly["cumulative"] = yearly["titles_added"].cumsum()

    print(f"   {'Year':<8} {'Added':<10} {'Growth %':<12} {'Cumulative':<12}")
    print(f"   {'-'*42}")
    for _, row in yearly.iterrows():
        growth = f"{row['growth_pct']}%" if pd.notna(row["growth_pct"]) else "N/A"
        print(f"   {int(row['year_added']):<8} {int(row['titles_added']):<10} "
              f"{growth:<12} {int(row['cumulative']):<12}")

    # --- Top Directors ---
    print("\n" + "-" * 40)
    print("TOP 10 DIRECTORS")
    print("-" * 40)
    directors_exploded = df["director"].str.split(", ").explode().str.strip()
    top_directors = (
        directors_exploded[directors_exploded != "Unknown"]
        .value_counts()
        .head(10)
    )
    for director, count in top_directors.items():
        print(f"   {director}: {count} titles")

    return {
        "kpis": kpis,
        "top_countries": top_countries,
        "top_genres": top_genres,
        "yearly": yearly,
        "top_directors": top_directors,
        "movie_durations": movie_durations,
    }


# ============================================================================
# SECTION 3: PostgreSQL Integration Examples
# ============================================================================

def demo_postgres_integration():
    """
    Demonstrate the Python -> PostgreSQL -> Pandas -> Analysis workflow.

    This shows how a data analyst might use Python to:
    1. Connect to a PostgreSQL database
    2. Execute SQL queries
    3. Load results into Pandas DataFrames
    4. Perform further analysis or visualization
    """
    conn = get_db_connection()
    if conn is None:
        print("[!] Skipping PostgreSQL demo (not connected).")
        return

    print("\n" + "=" * 60)
    print("PYTHON + POSTGRESQL INTEGRATION DEMO")
    print("=" * 60)

    # Example 1: Simple query
    df_types = execute_sql_query(conn, """
        SELECT type, COUNT(*) AS count
        FROM titles
        GROUP BY type
        ORDER BY count DESC
    """, "Content Type Distribution")
    if not df_types.empty:
        print(df_types.to_string(index=False))

    # Example 2: Multi-table JOIN query
    df_top_genres = execute_sql_query(conn, """
        SELECT g.genre_name, COUNT(DISTINCT tg.show_id) AS title_count
        FROM title_genres tg
        INNER JOIN genres g ON tg.genre_id = g.genre_id
        GROUP BY g.genre_name
        ORDER BY title_count DESC
        LIMIT 10
    """, "Top 10 Genres (via 3-table JOIN)")
    if not df_top_genres.empty:
        print(df_top_genres.to_string(index=False))

    # Example 3: Window function query
    df_growth = execute_sql_query(conn, """
        WITH yearly AS (
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
            SUM(titles_added) OVER (ORDER BY year_added) AS cumulative
        FROM yearly
        ORDER BY year_added
    """, "Cumulative Content Growth (Window Function)")
    if not df_growth.empty:
        print(df_growth.to_string(index=False))

    conn.close()
    print("\n[OK] PostgreSQL integration demo complete.")


# ============================================================================
# Main Entry Point
# ============================================================================

def main():
    parser = argparse.ArgumentParser(description="Netflix Content Analysis")
    parser.add_argument("--load-data", action="store_true",
                        help="Load cleaned data into PostgreSQL")
    parser.add_argument("--analyze", action="store_true",
                        help="Run standalone Pandas analysis")
    parser.add_argument("--demo-postgres", action="store_true",
                        help="Demo Python-PostgreSQL integration")
    args = parser.parse_args()

    # Default: run analysis if no flags provided
    if not any([args.load_data, args.analyze, args.demo_postgres]):
        args.analyze = True

    # Load cleaned dataset
    if not CLEANED_DATA_PATH.exists():
        print(f"[!] Cleaned data not found at {CLEANED_DATA_PATH}")
        print("    Run 'python src/data_cleaning.py' first.")
        sys.exit(1)

    df = pd.read_csv(CLEANED_DATA_PATH)
    print(f"[OK] Loaded cleaned dataset: {df.shape[0]} rows x {df.shape[1]} columns")

    # Load data into PostgreSQL
    if args.load_data:
        conn = get_db_connection()
        if conn:
            load_data_to_postgres(conn, df)
            conn.close()

    # Run standalone analysis
    if args.analyze:
        results = run_pandas_analysis(df)

    # Demo PostgreSQL integration
    if args.demo_postgres:
        demo_postgres_integration()


if __name__ == "__main__":
    main()
