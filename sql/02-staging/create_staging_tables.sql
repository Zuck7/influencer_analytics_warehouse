-- ============================================================
-- STAGING LAYER: Cleaned, typed, and deduplicated tables
-- Intermediate layer between raw ingestion and warehouse
-- ============================================================

DROP SCHEMA IF EXISTS staging CASCADE;
CREATE SCHEMA staging;

CREATE TABLE staging.brands (
    brand_id        INT PRIMARY KEY,
    brand_name      VARCHAR(200) NOT NULL,
    industry        VARCHAR(100),
    country         VARCHAR(10),
    annual_budget   NUMERIC(15, 2),
    contact_email   VARCHAR(200),
    created_at      TIMESTAMP,
    updated_at      TIMESTAMP,
    loaded_at       TIMESTAMP DEFAULT NOW()
);

CREATE TABLE staging.creators (
    creator_id      INT PRIMARY KEY,
    username        VARCHAR(200) NOT NULL,
    display_name    VARCHAR(200),
    platform        VARCHAR(50),
    follower_count  INT,
    engagement_rate NUMERIC(6, 4),
    category        VARCHAR(100),
    country         VARCHAR(10),
    email           VARCHAR(200),
    creator_tier    VARCHAR(20),  -- derived: nano/micro/mid/macro/mega
    created_at      TIMESTAMP,
    loaded_at       TIMESTAMP DEFAULT NOW()
);

CREATE TABLE staging.campaigns (
    campaign_id     INT PRIMARY KEY,
    campaign_name   VARCHAR(300) NOT NULL,
    brand_id        INT,
    campaign_type   VARCHAR(50),
    start_date      DATE,
    end_date        DATE,
    total_budget    NUMERIC(15, 2),
    status          VARCHAR(20),
    created_at      TIMESTAMP,
    loaded_at       TIMESTAMP DEFAULT NOW()
);

CREATE TABLE staging.performance_metrics (
    metric_id       INT,
    campaign_id     INT,
    creator_id      INT,
    platform        VARCHAR(50),
    metric_date     DATE,
    impressions     INT,
    clicks          INT DEFAULT 0,
    likes           INT DEFAULT 0,
    comments        INT DEFAULT 0,
    shares          INT DEFAULT 0,
    conversions     INT DEFAULT 0,
    spend           NUMERIC(12, 2) DEFAULT 0,
    revenue         NUMERIC(12, 2) DEFAULT 0,
    post_url        TEXT,
    pulled_at       TIMESTAMP,
    loaded_at       TIMESTAMP DEFAULT NOW(),
    PRIMARY KEY (campaign_id, creator_id, metric_date, platform)
);

CREATE TABLE staging.campaign_creators (
    assignment_id   INT PRIMARY KEY,
    campaign_id     INT,
    creator_id      INT,
    assigned_budget NUMERIC(12, 2),
    content_type    VARCHAR(50),
    deliverables    TEXT,
    status          VARCHAR(20),
    created_at      TIMESTAMP,
    loaded_at       TIMESTAMP DEFAULT NOW()
);

COMMENT ON SCHEMA staging IS 'Staging layer - cleaned, typed, deduplicated data ready for warehouse loading';
