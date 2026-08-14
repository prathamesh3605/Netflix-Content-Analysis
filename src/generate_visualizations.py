"""
Netflix Content Analysis - Visualization Generator
===================================================
Generates all 10 visualizations for the project.
Run this script to create charts saved to the visualizations/ folder.

Usage: python src/generate_visualizations.py
"""

import pandas as pd
import numpy as np
import matplotlib
matplotlib.use('Agg')  # Non-interactive backend for saving files
import matplotlib.pyplot as plt
import matplotlib.ticker as ticker
import seaborn as sns
from pathlib import Path
import warnings
warnings.filterwarnings('ignore')

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------
PROJECT_ROOT = Path(__file__).resolve().parent.parent
DATA_PATH = PROJECT_ROOT / "data" / "processed" / "netflix_cleaned.csv"
VIZ_DIR = PROJECT_ROOT / "visualizations"
VIZ_DIR.mkdir(exist_ok=True)

# Netflix-inspired color palette
NETFLIX_RED = '#E50914'
NETFLIX_DARK = '#141414'
NETFLIX_GRAY = '#333333'
NETFLIX_LIGHT = '#B3B3B3'

# Custom color palette for charts
COLORS = ['#E50914', '#B20710', '#FF6B6B', '#FFA07A', '#FFD700',
          '#4ECDC4', '#45B7D1', '#96CEB4', '#DDA0DD', '#87CEEB',
          '#98D8C8', '#F7DC6F', '#BB8FCE', '#82E0AA', '#F8C471']

def setup_style():
    """Set up a professional dark theme inspired by Netflix."""
    plt.style.use('default')
    plt.rcParams.update({
        'figure.facecolor': NETFLIX_DARK,
        'axes.facecolor': '#1a1a2e',
        'axes.edgecolor': NETFLIX_LIGHT,
        'axes.labelcolor': 'white',
        'axes.titleweight': 'bold',
        'text.color': 'white',
        'xtick.color': NETFLIX_LIGHT,
        'ytick.color': NETFLIX_LIGHT,
        'grid.color': '#333355',
        'grid.alpha': 0.3,
        'font.family': 'sans-serif',
        'font.size': 11,
        'axes.titlesize': 14,
        'axes.labelsize': 12,
    })


def load_data():
    """Load the cleaned dataset."""
    df = pd.read_csv(DATA_PATH)
    df['date_added'] = pd.to_datetime(df['date_added'])
    print(f"Loaded {len(df)} records.")
    return df


# ============================================================================
# Visualization 1: Movies vs TV Shows (Donut Chart)
# ============================================================================
def viz_movies_vs_tvshows(df):
    """Donut chart showing Movie vs TV Show distribution."""
    fig, ax = plt.subplots(figsize=(8, 8))

    type_counts = df['type'].value_counts()
    colors_pie = [NETFLIX_RED, '#45B7D1']

    wedges, texts, autotexts = ax.pie(
        type_counts.values,
        labels=type_counts.index,
        colors=colors_pie,
        autopct='%1.1f%%',
        startangle=90,
        pctdistance=0.8,
        wedgeprops=dict(width=0.4, edgecolor=NETFLIX_DARK, linewidth=2),
        textprops={'fontsize': 14, 'fontweight': 'bold', 'color': 'white'}
    )
    for autotext in autotexts:
        autotext.set_fontsize(13)
        autotext.set_fontweight('bold')

    # Center text
    ax.text(0, 0, f'{len(df):,}\nTitles', ha='center', va='center',
            fontsize=18, fontweight='bold', color='white')

    ax.set_title('Netflix Content: Movies vs TV Shows', fontsize=16, pad=20)

    filepath = VIZ_DIR / '01_movies_vs_tvshows.png'
    fig.savefig(filepath, dpi=150, bbox_inches='tight', facecolor=fig.get_facecolor())
    plt.close()
    print(f"  Saved: {filepath.name}")


# ============================================================================
# Visualization 2: Content Added by Year (Line Chart)
# ============================================================================
def viz_content_by_year(df):
    """Line chart showing content additions over time."""
    fig, ax = plt.subplots(figsize=(12, 6))

    yearly = df.groupby(['year_added', 'type']).size().unstack(fill_value=0)

    if 'Movie' in yearly.columns:
        ax.plot(yearly.index, yearly['Movie'], 'o-', color=NETFLIX_RED,
                linewidth=2.5, markersize=7, label='Movies', zorder=5)
    if 'TV Show' in yearly.columns:
        ax.plot(yearly.index, yearly['TV Show'], 's-', color='#45B7D1',
                linewidth=2.5, markersize=7, label='TV Shows', zorder=5)

    # Total line
    total = yearly.sum(axis=1)
    ax.plot(yearly.index, total, 'D--', color='#FFD700',
            linewidth=1.5, markersize=5, label='Total', alpha=0.7, zorder=4)

    ax.fill_between(yearly.index, 0, total, alpha=0.05, color='white')

    ax.set_xlabel('Year Added to Netflix')
    ax.set_ylabel('Number of Titles')
    ax.set_title('Netflix Content Growth Over Time', fontsize=16, pad=15)
    ax.legend(framealpha=0.3, fontsize=11)
    ax.grid(True, alpha=0.2)
    ax.set_xlim(yearly.index.min() - 0.5, yearly.index.max() + 0.5)

    filepath = VIZ_DIR / '02_content_by_year.png'
    fig.savefig(filepath, dpi=150, bbox_inches='tight', facecolor=fig.get_facecolor())
    plt.close()
    print(f"  Saved: {filepath.name}")


# ============================================================================
# Visualization 3: Top 10 Countries (Horizontal Bar)
# ============================================================================
def viz_top_countries(df):
    """Horizontal bar chart of top 10 content-producing countries."""
    fig, ax = plt.subplots(figsize=(10, 7))

    countries = df['country'].str.split(', ').explode().str.strip()
    countries = countries[countries != 'Unknown']
    top_10 = countries.value_counts().head(10).sort_values()

    bars = ax.barh(top_10.index, top_10.values, color=COLORS[:10][::-1],
                   edgecolor='none', height=0.7)

    # Add value labels
    for bar, val in zip(bars, top_10.values):
        ax.text(val + 20, bar.get_y() + bar.get_height()/2,
                f'{val:,}', va='center', fontsize=11, color='white')

    ax.set_xlabel('Number of Titles')
    ax.set_title('Top 10 Countries by Netflix Content', fontsize=16, pad=15)
    ax.grid(axis='x', alpha=0.2)

    filepath = VIZ_DIR / '03_top_countries.png'
    fig.savefig(filepath, dpi=150, bbox_inches='tight', facecolor=fig.get_facecolor())
    plt.close()
    print(f"  Saved: {filepath.name}")


# ============================================================================
# Visualization 4: Top 10 Genres (Horizontal Bar)
# ============================================================================
def viz_top_genres(df):
    """Horizontal bar chart of top 10 genres."""
    fig, ax = plt.subplots(figsize=(10, 7))

    genres = df['listed_in'].str.split(', ').explode().str.strip()
    top_10 = genres.value_counts().head(10).sort_values()

    bars = ax.barh(top_10.index, top_10.values, color=COLORS[:10][::-1],
                   edgecolor='none', height=0.7)

    for bar, val in zip(bars, top_10.values):
        ax.text(val + 15, bar.get_y() + bar.get_height()/2,
                f'{val:,}', va='center', fontsize=11, color='white')

    ax.set_xlabel('Number of Titles')
    ax.set_title('Top 10 Genres on Netflix', fontsize=16, pad=15)
    ax.grid(axis='x', alpha=0.2)

    filepath = VIZ_DIR / '04_top_genres.png'
    fig.savefig(filepath, dpi=150, bbox_inches='tight', facecolor=fig.get_facecolor())
    plt.close()
    print(f"  Saved: {filepath.name}")


# ============================================================================
# Visualization 5: Rating Distribution (Bar Chart)
# ============================================================================
def viz_rating_distribution(df):
    """Bar chart of content rating distribution."""
    fig, ax = plt.subplots(figsize=(12, 6))

    ratings = df['rating'].value_counts().head(12)

    bars = ax.bar(range(len(ratings)), ratings.values,
                  color=[NETFLIX_RED if i < 3 else '#45B7D1' for i in range(len(ratings))],
                  edgecolor='none', width=0.7)

    ax.set_xticks(range(len(ratings)))
    ax.set_xticklabels(ratings.index, rotation=45, ha='right')

    for bar, val in zip(bars, ratings.values):
        ax.text(bar.get_x() + bar.get_width()/2, val + 15,
                str(val), ha='center', fontsize=10, color='white')

    ax.set_ylabel('Number of Titles')
    ax.set_title('Content Rating Distribution on Netflix', fontsize=16, pad=15)
    ax.grid(axis='y', alpha=0.2)

    filepath = VIZ_DIR / '05_rating_distribution.png'
    fig.savefig(filepath, dpi=150, bbox_inches='tight', facecolor=fig.get_facecolor())
    plt.close()
    print(f"  Saved: {filepath.name}")


# ============================================================================
# Visualization 6: Movie Duration Distribution (Histogram)
# ============================================================================
def viz_movie_duration(df):
    """Histogram of movie durations."""
    fig, ax = plt.subplots(figsize=(12, 6))

    movie_durations = df.loc[
        (df['type'] == 'Movie') & (df['duration_unit'] == 'min'), 'duration_value'
    ].dropna()

    ax.hist(movie_durations, bins=40, color=NETFLIX_RED, edgecolor=NETFLIX_DARK,
            alpha=0.85, linewidth=0.5)

    # Add mean and median lines
    mean_dur = movie_durations.mean()
    median_dur = movie_durations.median()
    ax.axvline(mean_dur, color='#FFD700', linestyle='--', linewidth=2,
               label=f'Mean: {mean_dur:.0f} min')
    ax.axvline(median_dur, color='#4ECDC4', linestyle='--', linewidth=2,
               label=f'Median: {median_dur:.0f} min')

    ax.set_xlabel('Duration (minutes)')
    ax.set_ylabel('Number of Movies')
    ax.set_title('Distribution of Movie Durations on Netflix', fontsize=16, pad=15)
    ax.legend(framealpha=0.3, fontsize=11)
    ax.grid(axis='y', alpha=0.2)

    filepath = VIZ_DIR / '06_movie_duration.png'
    fig.savefig(filepath, dpi=150, bbox_inches='tight', facecolor=fig.get_facecolor())
    plt.close()
    print(f"  Saved: {filepath.name}")


# ============================================================================
# Visualization 7: Release Year Distribution (Histogram)
# ============================================================================
def viz_release_year(df):
    """Histogram of release years."""
    fig, ax = plt.subplots(figsize=(12, 6))

    ax.hist(df['release_year'], bins=50, color='#45B7D1', edgecolor=NETFLIX_DARK,
            alpha=0.85, linewidth=0.5)

    ax.axvline(df['release_year'].median(), color=NETFLIX_RED, linestyle='--',
               linewidth=2, label=f'Median: {df["release_year"].median():.0f}')

    ax.set_xlabel('Release Year')
    ax.set_ylabel('Number of Titles')
    ax.set_title('Distribution of Release Years on Netflix', fontsize=16, pad=15)
    ax.legend(framealpha=0.3, fontsize=11)
    ax.grid(axis='y', alpha=0.2)

    filepath = VIZ_DIR / '07_release_year.png'
    fig.savefig(filepath, dpi=150, bbox_inches='tight', facecolor=fig.get_facecolor())
    plt.close()
    print(f"  Saved: {filepath.name}")


# ============================================================================
# Visualization 8: Top Directors (Horizontal Bar)
# ============================================================================
def viz_top_directors(df):
    """Horizontal bar chart of top 10 directors."""
    fig, ax = plt.subplots(figsize=(10, 7))

    directors = df['director'].str.split(', ').explode().str.strip()
    directors = directors[directors != 'Unknown']
    top_10 = directors.value_counts().head(10).sort_values()

    bars = ax.barh(top_10.index, top_10.values,
                   color=[NETFLIX_RED] + COLORS[1:10][::-1][:len(top_10)-1],
                   edgecolor='none', height=0.7)

    for bar, val in zip(bars, top_10.values):
        ax.text(val + 0.2, bar.get_y() + bar.get_height()/2,
                str(val), va='center', fontsize=11, color='white')

    ax.set_xlabel('Number of Titles')
    ax.set_title('Top 10 Directors on Netflix', fontsize=16, pad=15)
    ax.grid(axis='x', alpha=0.2)

    filepath = VIZ_DIR / '08_top_directors.png'
    fig.savefig(filepath, dpi=150, bbox_inches='tight', facecolor=fig.get_facecolor())
    plt.close()
    print(f"  Saved: {filepath.name}")


# ============================================================================
# Visualization 9: Year-over-Year Growth (Line + Bar)
# ============================================================================
def viz_yoy_growth(df):
    """Combined bar and line chart showing YoY content growth."""
    fig, ax1 = plt.subplots(figsize=(12, 6))

    yearly = df.groupby('year_added').size().reset_index(name='titles_added')
    yearly = yearly.sort_values('year_added')
    yearly['growth_pct'] = yearly['titles_added'].pct_change() * 100

    # Filter to meaningful years
    yearly = yearly[yearly['year_added'] >= 2013]

    # Bar chart for absolute numbers
    bars = ax1.bar(yearly['year_added'], yearly['titles_added'],
                   color=NETFLIX_RED, alpha=0.7, width=0.6, label='Titles Added')

    ax1.set_xlabel('Year')
    ax1.set_ylabel('Titles Added', color=NETFLIX_RED)
    ax1.tick_params(axis='y', labelcolor=NETFLIX_RED)

    # Line chart for growth percentage on secondary axis
    ax2 = ax1.twinx()
    valid_growth = yearly.dropna(subset=['growth_pct'])
    ax2.plot(valid_growth['year_added'], valid_growth['growth_pct'],
             'o-', color='#FFD700', linewidth=2.5, markersize=8,
             label='Growth %', zorder=5)
    ax2.set_ylabel('Year-over-Year Growth (%)', color='#FFD700')
    ax2.tick_params(axis='y', labelcolor='#FFD700')

    ax1.set_title('Netflix Content: Yearly Additions & Growth Rate',
                  fontsize=16, pad=15)

    # Combine legends
    lines1, labels1 = ax1.get_legend_handles_labels()
    lines2, labels2 = ax2.get_legend_handles_labels()
    ax1.legend(lines1 + lines2, labels1 + labels2, loc='upper left',
               framealpha=0.3, fontsize=11)

    ax1.grid(axis='y', alpha=0.15)

    filepath = VIZ_DIR / '09_yoy_growth.png'
    fig.savefig(filepath, dpi=150, bbox_inches='tight', facecolor=fig.get_facecolor())
    plt.close()
    print(f"  Saved: {filepath.name}")


# ============================================================================
# Visualization 10: Content by Country & Type (Stacked Bar)
# ============================================================================
def viz_country_content_type(df):
    """Stacked bar chart showing Movies vs TV Shows by top countries."""
    fig, ax = plt.subplots(figsize=(12, 7))

    # Explode countries
    df_exploded = df.assign(
        country=df['country'].str.split(', ')
    ).explode('country')
    df_exploded['country'] = df_exploded['country'].str.strip()
    df_exploded = df_exploded[df_exploded['country'] != 'Unknown']

    # Top 10 countries
    top_countries = list(df_exploded['country'].value_counts().head(10).index)

    # Use groupby + pivot to avoid duplicate index issues
    filtered = df_exploded[df_exploded['country'].isin(top_countries)]
    ct = filtered.groupby(['country', 'type']).size().reset_index(name='count')
    ct = ct.pivot(index='country', columns='type', values='count').fillna(0).astype(int)
    ct = ct.reindex(top_countries[::-1])  # Reverse for horizontal display

    ct.plot(kind='barh', stacked=True, ax=ax,
            color=[NETFLIX_RED, '#45B7D1'], edgecolor='none', width=0.7)

    ax.set_xlabel('Number of Titles')
    ax.set_title('Top 10 Countries: Movies vs TV Shows', fontsize=16, pad=15)
    ax.legend(framealpha=0.3, fontsize=11)
    ax.grid(axis='x', alpha=0.2)

    filepath = VIZ_DIR / '10_country_content_type.png'
    fig.savefig(filepath, dpi=150, bbox_inches='tight', facecolor=fig.get_facecolor())
    plt.close()
    print(f"  Saved: {filepath.name}")


# ============================================================================
# Main
# ============================================================================
def main():
    print("=" * 50)
    print("GENERATING NETFLIX VISUALIZATIONS")
    print("=" * 50)

    setup_style()
    df = load_data()

    print("\nCreating visualizations...")
    viz_movies_vs_tvshows(df)
    viz_content_by_year(df)
    viz_top_countries(df)
    viz_top_genres(df)
    viz_rating_distribution(df)
    viz_movie_duration(df)
    viz_release_year(df)
    viz_top_directors(df)
    viz_yoy_growth(df)
    viz_country_content_type(df)

    print(f"\nAll 10 visualizations saved to: {VIZ_DIR}")
    print("Done!")


if __name__ == "__main__":
    main()
