# Influencer Marketing Analytics Data Warehouse

A SQL-based analytics data warehouse that transforms raw influencer marketing campaign data into clean, reliable, analytics-ready datasets using a **star schema** design with automated data quality validation.

## Architecture

```
Raw Data (CSV) → Staging Tables → PL/pgSQL Transformations → Star Schema (Facts + Dimensions) → Metrics Views
```

### Data Flow

```
┌─────────────┐     ┌──────────────┐     ┌─────────────────┐     ┌──────────────┐
│  RAW LAYER  │ ──► │ STAGING LAYER│ ──► │ WAREHOUSE LAYER │ ──► │ METRICS LAYER│
│ (Ingestion) │     │ (Cleaning)   │     │ (Star Schema)   │     │ (Analytics)  │
└─────────────┘     └──────────────┘     └─────────────────┘     └──────────────┘
                                                │
                                    ┌───────────┴───────────┐
                                    │  DATA QUALITY LAYER   │
                                    │  (Validation & Tests) │
                                    └───────────────────────┘
```

## Star Schema Design

### Fact Table
- `fact_campaign_performance` — One row per campaign-creator-day, containing impressions, clicks, conversions, spend, and revenue

### Dimension Tables
- `dim_brand` — Brand/advertiser information
- `dim_creator` — Influencer/creator profiles with platform and tier
- `dim_campaign` — Campaign metadata (name, type, date range, budget)
- `dim_platform` — Social media platform details
- `dim_date` — Date dimension for time-series analytics

## Project Structure

```
influencer-analytics-warehouse/
├── README.md
├── sql/
│   ├── 01-raw/           # Raw table DDL + sample data ingestion
│   ├── 02-staging/       # Cleaning, dedup, type casting
│   ├── 03-warehouse/     # Star schema DDL + transformation procedures
│   ├── 04-quality/       # Data quality tests (null checks, referential integrity, anomalies)
│   └── 05-metrics/       # Reusable views and materialized metrics
├── data/                 # Sample CSV data files
└── docs/                 # Data lineage and documentation
```

## How to Run

### PostgreSQL
```bash
# 1. Create database
createdb influencer_analytics

# 2. Run scripts in order
psql -d influencer_analytics -f sql/01-raw/create_raw_tables.sql
psql -d influencer_analytics -f sql/01-raw/seed_raw_data.sql
psql -d influencer_analytics -f sql/02-staging/create_staging_tables.sql
psql -d influencer_analytics -f sql/02-staging/transform_staging.sql
psql -d influencer_analytics -f sql/03-warehouse/create_dimensions.sql
psql -d influencer_analytics -f sql/03-warehouse/create_facts.sql
psql -d influencer_analytics -f sql/03-warehouse/load_warehouse.sql
psql -d influencer_analytics -f sql/04-quality/data_quality_tests.sql
psql -d influencer_analytics -f sql/05-metrics/campaign_metrics.sql
```

### Oracle SQL
The PL/pgSQL procedures can be adapted to PL/SQL with minor syntax changes (documented in each file).

## Key Features

- **Star Schema Design** — Optimized for analytical queries with denormalized dimension tables
- **Incremental Loading** — Transformation procedures support both full and incremental loads
- **Data Quality Framework** — Automated tests for nulls, duplicates, referential integrity, and statistical anomalies
- **Reusable Metrics** — Pre-built views for campaign ROI, creator performance, platform benchmarks, and trend analysis
- **Documentation** — Full data lineage from raw ingestion through final metrics

## Tech Stack

- PostgreSQL 14+ (also compatible with Oracle 19c+ with PL/SQL adaptation)
- PL/pgSQL stored procedures and functions
- Window functions, CTEs, recursive queries
- Materialized views for performance optimization

## Sample Analytics Queries

```sql
-- Top performing creators by ROI
SELECT * FROM vw_creator_roi_ranking WHERE campaign_month = '2026-01-01' LIMIT 10;

-- Campaign performance trend (monthly)
SELECT * FROM vw_campaign_monthly_trend WHERE brand_name = 'Nike';

-- Platform benchmark comparison
SELECT * FROM vw_platform_benchmarks;

-- Data quality summary
SELECT * FROM vw_quality_test_results WHERE status = 'FAIL';
```
