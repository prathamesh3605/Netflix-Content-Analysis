"""
Netflix Content Analysis - Data Cleaning Pipeline
==================================================
Automated data cleaning and transformation script for the Netflix titles dataset.
Loads raw CSV, performs quality checks, cleans data, creates derived columns,
and saves the processed dataset.

Usage:
    python src/data_cleaning.py

Input:  data/raw/netflix_titles.csv
Output: data/processed/netflix_cleaned.csv
"""

import pandas as pd
import numpy as np
import os
import time
from pathlib import Path


# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------
PROJECT_ROOT = Path(__file__).resolve().parent.parent
RAW_DATA_PATH = PROJECT_ROOT / "data" / "raw" / "netflix_titles.csv"
PROCESSED_DATA_PATH = PROJECT_ROOT / "data" / "processed" / "netflix_cleaned.csv"


# ---------------------------------------------------------------------------
# Step 1: Data Loading
# ---------------------------------------------------------------------------
def load_data(filepath: str) -> pd.DataFrame:
    """Load the raw Netflix dataset from CSV."""
    print("=" * 70)
    print("STEP 1: DATA LOADING")
    print("=" * 70)

    df = pd.read_csv(filepath)

    print(f"\n[FILE] Loaded: {filepath}")
    print(f"[DATA] Shape: {df.shape[0]} rows × {df.shape[1]} columns")
    print(f"\n[LIST] Columns: {list(df.columns)}")
    print(f"\n[TEXT] Data Types:\n{df.dtypes.to_string()}")
    print(f"\n[SEARCH] First 5 Rows:")
    print(df.head().to_string())

    return df


# ---------------------------------------------------------------------------
# Step 2: Data Quality Analysis
# ---------------------------------------------------------------------------
def analyze_quality(df: pd.DataFrame) -> None:
    """Perform comprehensive data quality checks and print a report."""
    print("\n" + "=" * 70)
    print("STEP 2: DATA QUALITY ANALYSIS")
    print("=" * 70)

    # Missing values
    missing = df.isnull().sum()
    missing_pct = (df.isnull().sum() / len(df) * 100).round(2)
    missing_report = pd.DataFrame({
        "Missing Count": missing,
        "Missing %": missing_pct
    })
    print(f"\n[X] Missing Values:\n{missing_report[missing_report['Missing Count'] > 0].to_string()}")

    # Duplicates
    dup_count = df.duplicated().sum()
    print(f"\n[CYCLE] Duplicate Rows: {dup_count}")

    # Unique values per column
    print(f"\n[NUM] Unique Values Per Column:")
    for col in df.columns:
        print(f"   {col}: {df[col].nunique()}")

    # Type distribution
    print(f"\n[MOVIE] Content Type Distribution:\n{df['type'].value_counts().to_string()}")

    # Rating distribution
    print(f"\n[STAR] Rating Distribution:\n{df['rating'].value_counts().to_string()}")

    # Release year range
    print(f"\n[DATE] Release Year Range: {df['release_year'].min()} – {df['release_year'].max()}")

    # Check for potential data issues
    print(f"\n[!]  Potential Issues:")

    # Check for whitespace issues in text columns
    text_cols = df.select_dtypes(include="object").columns
    for col in text_cols:
        ws_count = df[col].dropna().apply(lambda x: x != x.strip()).sum()
        if ws_count > 0:
            print(f"   - '{col}' has {ws_count} values with leading/trailing whitespace")

    # Check for inconsistent duration formats
    duration_samples = df["duration"].dropna().unique()[:10]
    print(f"   - Duration samples: {list(duration_samples)}")


# ---------------------------------------------------------------------------
# Step 3: Data Cleaning
# ---------------------------------------------------------------------------
def clean_data(df: pd.DataFrame) -> pd.DataFrame:
    """
    Clean the Netflix dataset with documented strategies for each issue.

    Missing Value Strategies:
    -------------------------
    - director (30.7% missing): Fill with "Unknown".
      Rationale: Nearly a third of titles lack director info. Dropping would
      lose too much data. "Unknown" is honest — we don't fabricate names.

    - cast (9.2% missing): Fill with "Unknown".
      Rationale: Some titles (especially documentaries/specials) may genuinely
      lack credited cast. "Unknown" preserves the row for other analyses.

    - country (6.5% missing): Fill with "Unknown".
      Rationale: Country data is important for geographic analysis but 507
      missing values are too many to drop. We mark them rather than guess.

    - date_added (10 missing): Drop these rows.
      Rationale: Only 10 out of 7,787 rows (~0.13%). The loss is negligible
      and we cannot reasonably impute when content was added to Netflix.

    - rating (7 missing): Fill with "Unrated".
      Rationale: "Unrated" is a standard industry designation for content
      without a formal rating classification.
    """
    print("\n" + "=" * 70)
    print("STEP 3: DATA CLEANING")
    print("=" * 70)

    initial_rows = len(df)

    # --- 3a. Handle missing values ---
    print("\n[TOOL] Handling missing values...")

    # director: fill with "Unknown" (30.7% missing — too many to drop)
    director_missing = df["director"].isnull().sum()
    df["director"] = df["director"].fillna("Unknown")
    print(f"   [OK] director: filled {director_missing} missing values with 'Unknown'")

    # cast: fill with "Unknown" (9.2% missing)
    cast_missing = df["cast"].isnull().sum()
    df["cast"] = df["cast"].fillna("Unknown")
    print(f"   [OK] cast: filled {cast_missing} missing values with 'Unknown'")

    # country: fill with "Unknown" (6.5% missing)
    country_missing = df["country"].isnull().sum()
    df["country"] = df["country"].fillna("Unknown")
    print(f"   [OK] country: filled {country_missing} missing values with 'Unknown'")

    # date_added: drop rows (only 10 — negligible loss)
    date_missing = df["date_added"].isnull().sum()
    df = df.dropna(subset=["date_added"])
    print(f"   [OK] date_added: dropped {date_missing} rows (negligible — {date_missing}/{initial_rows})")

    # rating: fill with "Unrated" (only 7 — standard industry convention)
    rating_missing = df["rating"].isnull().sum()
    df["rating"] = df["rating"].fillna("Unrated")
    print(f"   [OK] rating: filled {rating_missing} missing values with 'Unrated'")

    # --- 3b. Remove duplicates ---
    dup_count = df.duplicated().sum()
    if dup_count > 0:
        df = df.drop_duplicates()
        print(f"   [OK] Removed {dup_count} duplicate rows")
    else:
        print(f"   [OK] No duplicate rows found")

    # --- 3c. Convert date_added to datetime ---
    print("\n[TOOL] Converting data types...")
    df["date_added"] = df["date_added"].str.strip()
    df["date_added"] = pd.to_datetime(df["date_added"], format="mixed")
    print(f"   [OK] date_added converted to datetime")

    # --- 3d. Standardize text fields (strip whitespace) ---
    print("\n[TOOL] Standardizing text fields...")
    text_columns = ["type", "title", "director", "cast", "country",
                     "rating", "duration", "listed_in", "description"]
    for col in text_columns:
        df[col] = df[col].str.strip()
    print(f"   [OK] Stripped whitespace from {len(text_columns)} text columns")

    # --- 3e. Create derived columns ---
    print("\n[TOOL] Creating derived columns...")

    # Extract duration value and unit
    # Movies: "90 min" → 90, "min"
    # TV Shows: "2 Seasons" → 2, "Season"
    df["duration_value"] = df["duration"].str.extract(r"(\d+)").astype(float).astype("Int64")
    df["duration_unit"] = df["duration"].str.extract(r"(\D+)").squeeze()
    df["duration_unit"] = df["duration_unit"].str.strip()
    print(f"   [OK] Created duration_value and duration_unit")

    # Extract year and month from date_added
    df["year_added"] = df["date_added"].dt.year.astype("Int64")
    df["month_added"] = df["date_added"].dt.month.astype("Int64")
    df["month_name_added"] = df["date_added"].dt.month_name()
    print(f"   [OK] Created year_added, month_added, month_name_added")

    # --- 3f. Final validation ---
    print("\n" + "-" * 50)
    print("CLEANING SUMMARY")
    print("-" * 50)
    print(f"   Rows before cleaning: {initial_rows}")
    print(f"   Rows after cleaning:  {len(df)}")
    print(f"   Rows removed:         {initial_rows - len(df)}")
    print(f"   Missing values remaining: {df.isnull().sum().sum()}")
    print(f"   New columns added: duration_value, duration_unit, year_added, month_added, month_name_added")
    print(f"   Final shape: {df.shape}")

    return df


# ---------------------------------------------------------------------------
# Step 4: Save Cleaned Data
# ---------------------------------------------------------------------------
def save_data(df: pd.DataFrame, filepath: str) -> None:
    """Save the cleaned DataFrame to CSV."""
    print("\n" + "=" * 70)
    print("STEP 4: SAVING CLEANED DATA")
    print("=" * 70)

    os.makedirs(os.path.dirname(filepath), exist_ok=True)
    df.to_csv(filepath, index=False)

    file_size_mb = os.path.getsize(filepath) / (1024 * 1024)
    print(f"\n[SAVE] Saved to: {filepath}")
    print(f"[PKG] File size: {file_size_mb:.2f} MB")
    print(f"[DATA] Final shape: {df.shape[0]} rows × {df.shape[1]} columns")


# ---------------------------------------------------------------------------
# Main Pipeline
# ---------------------------------------------------------------------------
def run_pipeline():
    """
    Execute the complete data cleaning pipeline.

    Measures total execution time to demonstrate automation efficiency.
    """
    print("\n" + "[MOVIE] " * 20)
    print("  NETFLIX DATA CLEANING PIPELINE")
    print("[MOVIE] " * 20)

    pipeline_start = time.time()

    # Step 1: Load
    df = load_data(RAW_DATA_PATH)

    # Step 2: Analyze quality
    analyze_quality(df)

    # Step 3: Clean
    df = clean_data(df)

    # Step 4: Save
    save_data(df, PROCESSED_DATA_PATH)

    pipeline_end = time.time()
    elapsed = pipeline_end - pipeline_start

    # --- Performance Summary ---
    print("\n" + "=" * 70)
    print("AUTOMATION PERFORMANCE")
    print("=" * 70)
    print(f"""
    [TIME]  Automated pipeline completed in {elapsed:.2f} seconds.

    This pipeline automates the following manual steps:
      1. Loading and inspecting the dataset
      2. Identifying missing values across 12 columns
      3. Applying column-specific imputation strategies
      4. Removing duplicates
      5. Converting date formats
      6. Standardizing text in 9 columns across {df.shape[0]}+ rows
      7. Engineering 5 derived columns
      8. Validating data quality
      9. Exporting cleaned dataset

    Performing these steps manually in a spreadsheet or interactively in
    a notebook typically takes 15–30 minutes of repetitive work per run.
    This script completes the same work in ~{elapsed:.1f} seconds and is
    fully reproducible — any team member can re-run it on updated data.

    Note: The automation benefit compounds with repeated runs (e.g., when
    the dataset is refreshed). Manual effort scales linearly; this script
    stays constant at ~{elapsed:.1f}s regardless of how many times it runs.
    """)

    return df


# ---------------------------------------------------------------------------
# Entry Point
# ---------------------------------------------------------------------------
if __name__ == "__main__":
    df = run_pipeline()
    print("[OK] Pipeline complete. Cleaned data is ready for analysis.")
