-- ============================================================
-- RAW LAYER: Ingestion tables for influencer marketing data
-- These tables mirror source system exports (messy, untyped)
-- ============================================================

DROP SCHEMA IF EXISTS raw CASCADE;
CREATE SCHEMA raw;

-- Raw brand/advertiser data (from CRM export)
CREATE TABLE raw.brands (
    id              TEXT,
    brand_name      TEXT,
    industry        TEXT,
    country         TEXT,
    annual_budget   TEXT,    -- messy: contains "$" and commas
    contact_email   TEXT,
    created_at      TEXT,
    updated_at      TEXT
);

-- Raw creator/influencer data (from platform API pulls)
CREATE TABLE raw.creators (
    id              TEXT,
    username        TEXT,
    display_name    TEXT,
    platform        TEXT,    -- messy: "Instagram", "instagram", "IG", etc.
    follower_count  TEXT,    -- messy: "1.2M", "50K", "3200"
    engagement_rate TEXT,    -- messy: "3.5%", "0.035", etc.
    category        TEXT,
    country         TEXT,
    email           TEXT,
    created_at      TEXT
);

-- Raw campaign data (from internal project management tool)
CREATE TABLE raw.campaigns (
    id              TEXT,
    campaign_name   TEXT,
    brand_id        TEXT,
    campaign_type   TEXT,    -- messy: "Awareness", "awareness", "AWARENESS"
    start_date      TEXT,
    end_date        TEXT,
    total_budget    TEXT,
    status          TEXT,
    created_at      TEXT
);

-- Raw performance metrics (daily pulls from social platform APIs)
CREATE TABLE raw.performance_metrics (
    id              TEXT,
    campaign_id     TEXT,
    creator_id      TEXT,
    platform        TEXT,
    metric_date     TEXT,
    impressions     TEXT,
    clicks          TEXT,
    likes           TEXT,
    comments        TEXT,
    shares          TEXT,
    conversions     TEXT,
    spend           TEXT,
    revenue         TEXT,
    post_url        TEXT,
    pulled_at       TEXT    -- when this data was extracted
);

-- Raw campaign-creator assignments
CREATE TABLE raw.campaign_creators (
    id              TEXT,
    campaign_id     TEXT,
    creator_id      TEXT,
    assigned_budget TEXT,
    content_type    TEXT,   -- "post", "reel", "story", "video"
    deliverables    TEXT,
    status          TEXT,
    created_at      TEXT
);

COMMENT ON SCHEMA raw IS 'Raw ingestion layer - unprocessed data from source systems';
COMMENT ON TABLE raw.brands IS 'Brand/advertiser data from CRM exports';
COMMENT ON TABLE raw.creators IS 'Creator/influencer profiles from platform API pulls';
COMMENT ON TABLE raw.campaigns IS 'Campaign metadata from internal project management';
COMMENT ON TABLE raw.performance_metrics IS 'Daily performance metrics from social platform APIs';
COMMENT ON TABLE raw.campaign_creators IS 'Campaign-to-creator assignment mappings';
