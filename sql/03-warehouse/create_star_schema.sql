-- ============================================================
-- WAREHOUSE LAYER: Star Schema for Analytics
-- Optimized for analytical queries with denormalized dimensions
-- ============================================================

DROP SCHEMA IF EXISTS warehouse CASCADE;
CREATE SCHEMA warehouse;

-- -----------------------------------------------
-- DIMENSION: Date (generated for time-series analytics)
-- -----------------------------------------------
CREATE TABLE warehouse.dim_date (
    date_key        DATE PRIMARY KEY,
    day_of_week     VARCHAR(10),
    day_of_month    INT,
    week_of_year    INT,
    month_num       INT,
    month_name      VARCHAR(20),
    quarter         INT,
    year            INT,
    is_weekend      BOOLEAN,
    fiscal_quarter  VARCHAR(10)
);

-- Populate date dimension (2025-01-01 to 2027-12-31)
INSERT INTO warehouse.dim_date
SELECT
    d::DATE AS date_key,
    TO_CHAR(d, 'Day') AS day_of_week,
    EXTRACT(DAY FROM d)::INT AS day_of_month,
    EXTRACT(WEEK FROM d)::INT AS week_of_year,
    EXTRACT(MONTH FROM d)::INT AS month_num,
    TO_CHAR(d, 'Month') AS month_name,
    EXTRACT(QUARTER FROM d)::INT AS quarter,
    EXTRACT(YEAR FROM d)::INT AS year,
    EXTRACT(DOW FROM d) IN (0, 6) AS is_weekend,
    'Q' || EXTRACT(QUARTER FROM d)::TEXT || '-' || EXTRACT(YEAR FROM d)::TEXT AS fiscal_quarter
FROM GENERATE_SERIES('2025-01-01'::DATE, '2027-12-31'::DATE, '1 day'::INTERVAL) d;

-- -----------------------------------------------
-- DIMENSION: Platform
-- -----------------------------------------------
CREATE TABLE warehouse.dim_platform (
    platform_key    SERIAL PRIMARY KEY,
    platform_name   VARCHAR(50) NOT NULL UNIQUE,
    platform_type   VARCHAR(50),
    avg_cpm         NUMERIC(8, 2)  -- industry benchmark cost per mille
);

INSERT INTO warehouse.dim_platform (platform_name, platform_type, avg_cpm) VALUES
('Instagram', 'Image/Video', 7.50),
('YouTube', 'Long-form Video', 12.00),
('TikTok', 'Short-form Video', 5.00),
('Twitch', 'Live Streaming', 8.50),
('Twitter', 'Microblog', 6.00);

-- -----------------------------------------------
-- DIMENSION: Brand
-- -----------------------------------------------
CREATE TABLE warehouse.dim_brand (
    brand_key       SERIAL PRIMARY KEY,
    brand_id        INT UNIQUE NOT NULL,
    brand_name      VARCHAR(200) NOT NULL,
    industry        VARCHAR(100),
    country         VARCHAR(10),
    annual_budget   NUMERIC(15, 2),
    budget_tier     VARCHAR(20)  -- derived
);

-- -----------------------------------------------
-- DIMENSION: Creator
-- -----------------------------------------------
CREATE TABLE warehouse.dim_creator (
    creator_key     SERIAL PRIMARY KEY,
    creator_id      INT UNIQUE NOT NULL,
    username        VARCHAR(200) NOT NULL,
    display_name    VARCHAR(200),
    primary_platform VARCHAR(50),
    follower_count  INT,
    engagement_rate NUMERIC(6, 4),
    category        VARCHAR(100),
    country         VARCHAR(10),
    creator_tier    VARCHAR(20)
);

-- -----------------------------------------------
-- DIMENSION: Campaign
-- -----------------------------------------------
CREATE TABLE warehouse.dim_campaign (
    campaign_key    SERIAL PRIMARY KEY,
    campaign_id     INT UNIQUE NOT NULL,
    campaign_name   VARCHAR(300) NOT NULL,
    brand_id        INT,
    campaign_type   VARCHAR(50),
    start_date      DATE,
    end_date        DATE,
    total_budget    NUMERIC(15, 2),
    duration_days   INT,  -- derived
    status          VARCHAR(20)
);

-- -----------------------------------------------
-- FACT: Campaign Performance (grain: campaign-creator-date-platform)
-- -----------------------------------------------
CREATE TABLE warehouse.fact_campaign_performance (
    performance_key SERIAL PRIMARY KEY,
    campaign_key    INT REFERENCES warehouse.dim_campaign(campaign_key),
    creator_key     INT REFERENCES warehouse.dim_creator(creator_key),
    platform_key    INT REFERENCES warehouse.dim_platform(platform_key),
    date_key        DATE REFERENCES warehouse.dim_date(date_key),
    impressions     INT,
    clicks          INT,
    likes           INT,
    comments        INT,
    shares          INT,
    conversions     INT,
    spend           NUMERIC(12, 2),
    revenue         NUMERIC(12, 2),
    -- Derived metrics
    ctr             NUMERIC(8, 6),   -- click-through rate
    engagement_total INT,
    cost_per_click  NUMERIC(10, 4),
    roas            NUMERIC(10, 4),  -- return on ad spend
    cpm             NUMERIC(10, 4)   -- cost per mille
);

CREATE INDEX idx_fact_perf_campaign ON warehouse.fact_campaign_performance(campaign_key);
CREATE INDEX idx_fact_perf_creator ON warehouse.fact_campaign_performance(creator_key);
CREATE INDEX idx_fact_perf_date ON warehouse.fact_campaign_performance(date_key);
CREATE INDEX idx_fact_perf_platform ON warehouse.fact_campaign_performance(platform_key);

COMMENT ON SCHEMA warehouse IS 'Analytics warehouse - star schema optimized for reporting and BI';
COMMENT ON TABLE warehouse.fact_campaign_performance IS 'Grain: one row per campaign-creator-date-platform combination';
