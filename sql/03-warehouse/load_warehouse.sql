-- ============================================================
-- WAREHOUSE LOADING: PL/pgSQL procedures to populate
-- star schema from staging tables
-- ============================================================

-- -----------------------------------------------
-- Load dim_brand with derived budget tier
-- -----------------------------------------------
CREATE OR REPLACE PROCEDURE warehouse.load_dim_brand()
LANGUAGE plpgsql AS $$
DECLARE
    rows_loaded INT;
BEGIN
    DELETE FROM warehouse.dim_brand;
    
    INSERT INTO warehouse.dim_brand (brand_id, brand_name, industry, country, annual_budget, budget_tier)
    SELECT
        brand_id,
        brand_name,
        industry,
        country,
        annual_budget,
        CASE
            WHEN annual_budget >= 5000000 THEN 'Enterprise'
            WHEN annual_budget >= 2000000 THEN 'Mid-Market'
            WHEN annual_budget >= 500000 THEN 'Growth'
            ELSE 'Emerging'
        END AS budget_tier
    FROM staging.brands;
    
    GET DIAGNOSTICS rows_loaded = ROW_COUNT;
    RAISE NOTICE 'dim_brand loaded: % rows', rows_loaded;
END;
$$;

-- -----------------------------------------------
-- Load dim_creator
-- -----------------------------------------------
CREATE OR REPLACE PROCEDURE warehouse.load_dim_creator()
LANGUAGE plpgsql AS $$
DECLARE
    rows_loaded INT;
BEGIN
    DELETE FROM warehouse.dim_creator;
    
    INSERT INTO warehouse.dim_creator (
        creator_id, username, display_name, primary_platform,
        follower_count, engagement_rate, category, country, creator_tier
    )
    SELECT
        creator_id, username, display_name, platform,
        follower_count, engagement_rate, category, country, creator_tier
    FROM staging.creators;
    
    GET DIAGNOSTICS rows_loaded = ROW_COUNT;
    RAISE NOTICE 'dim_creator loaded: % rows', rows_loaded;
END;
$$;

-- -----------------------------------------------
-- Load dim_campaign with derived duration
-- -----------------------------------------------
CREATE OR REPLACE PROCEDURE warehouse.load_dim_campaign()
LANGUAGE plpgsql AS $$
DECLARE
    rows_loaded INT;
BEGIN
    DELETE FROM warehouse.dim_campaign;
    
    INSERT INTO warehouse.dim_campaign (
        campaign_id, campaign_name, brand_id, campaign_type,
        start_date, end_date, total_budget, duration_days, status
    )
    SELECT
        campaign_id,
        campaign_name,
        brand_id,
        campaign_type,
        start_date,
        end_date,
        total_budget,
        CASE
            WHEN end_date IS NOT NULL THEN (end_date - start_date)
            ELSE NULL
        END AS duration_days,
        status
    FROM staging.campaigns;
    
    GET DIAGNOSTICS rows_loaded = ROW_COUNT;
    RAISE NOTICE 'dim_campaign loaded: % rows', rows_loaded;
END;
$$;

-- -----------------------------------------------
-- Load fact_campaign_performance with derived metrics
-- Uses window functions for running calculations
-- -----------------------------------------------
CREATE OR REPLACE PROCEDURE warehouse.load_fact_performance()
LANGUAGE plpgsql AS $$
DECLARE
    rows_loaded INT;
BEGIN
    DELETE FROM warehouse.fact_campaign_performance;
    
    INSERT INTO warehouse.fact_campaign_performance (
        campaign_key, creator_key, platform_key, date_key,
        impressions, clicks, likes, comments, shares, conversions,
        spend, revenue, ctr, engagement_total, cost_per_click, roas, cpm
    )
    SELECT
        dc.campaign_key,
        dcr.creator_key,
        dp.platform_key,
        pm.metric_date,
        pm.impressions,
        pm.clicks,
        pm.likes,
        pm.comments,
        pm.shares,
        pm.conversions,
        pm.spend,
        pm.revenue,
        -- Derived: Click-through rate
        CASE WHEN pm.impressions > 0
            THEN ROUND(pm.clicks::NUMERIC / pm.impressions, 6)
            ELSE 0
        END AS ctr,
        -- Derived: Total engagement
        (pm.likes + pm.comments + pm.shares) AS engagement_total,
        -- Derived: Cost per click
        CASE WHEN pm.clicks > 0
            THEN ROUND(pm.spend / pm.clicks, 4)
            ELSE NULL
        END AS cost_per_click,
        -- Derived: Return on ad spend
        CASE WHEN pm.spend > 0
            THEN ROUND(pm.revenue / pm.spend, 4)
            ELSE NULL
        END AS roas,
        -- Derived: Cost per mille (thousand impressions)
        CASE WHEN pm.impressions > 0
            THEN ROUND((pm.spend / pm.impressions) * 1000, 4)
            ELSE NULL
        END AS cpm
    FROM staging.performance_metrics pm
    JOIN warehouse.dim_campaign dc ON dc.campaign_id = pm.campaign_id
    JOIN warehouse.dim_creator dcr ON dcr.creator_id = pm.creator_id
    JOIN warehouse.dim_platform dp ON dp.platform_name = pm.platform
    WHERE pm.impressions IS NOT NULL AND pm.impressions > 0;
    
    GET DIAGNOSTICS rows_loaded = ROW_COUNT;
    RAISE NOTICE 'fact_campaign_performance loaded: % rows', rows_loaded;
END;
$$;

-- ============================================================
-- MASTER ORCHESTRATION: Load entire warehouse
-- ============================================================
CREATE OR REPLACE PROCEDURE warehouse.load_all()
LANGUAGE plpgsql AS $$
BEGIN
    RAISE NOTICE '=== Starting Warehouse Load ===';
    RAISE NOTICE 'Timestamp: %', NOW();
    
    -- Load dimensions first (facts depend on them)
    CALL warehouse.load_dim_brand();
    CALL warehouse.load_dim_creator();
    CALL warehouse.load_dim_campaign();
    
    -- Then load facts
    CALL warehouse.load_fact_performance();
    
    RAISE NOTICE '=== Warehouse Load Complete ===';
END;
$$;

-- Run it
CALL warehouse.load_all();
