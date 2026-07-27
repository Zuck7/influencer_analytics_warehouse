-- ============================================================
-- STAGING TRANSFORMATIONS: PL/pgSQL procedures to clean,
-- deduplicate, and type-cast raw data into staging tables
-- ============================================================

-- -----------------------------------------------
-- Helper function: Parse messy currency strings
-- Handles: "$5,000,000", "5000000", "$1,200", etc.
-- -----------------------------------------------
CREATE OR REPLACE FUNCTION staging.parse_currency(raw_value TEXT)
RETURNS NUMERIC AS $$
BEGIN
    IF raw_value IS NULL OR TRIM(raw_value) = '' THEN
        RETURN NULL;
    END IF;
    RETURN CAST(REPLACE(REPLACE(REPLACE(raw_value, '$', ''), ',', ''), ' ', '') AS NUMERIC);
EXCEPTION
    WHEN OTHERS THEN
        RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- -----------------------------------------------
-- Helper function: Parse follower count strings
-- Handles: "1.2M", "850K", "3200", etc.
-- -----------------------------------------------
CREATE OR REPLACE FUNCTION staging.parse_follower_count(raw_value TEXT)
RETURNS INT AS $$
DECLARE
    cleaned TEXT;
    multiplier NUMERIC := 1;
BEGIN
    IF raw_value IS NULL OR TRIM(raw_value) = '' THEN
        RETURN NULL;
    END IF;
    
    cleaned := UPPER(TRIM(raw_value));
    
    IF cleaned LIKE '%M' THEN
        multiplier := 1000000;
        cleaned := REPLACE(cleaned, 'M', '');
    ELSIF cleaned LIKE '%K' THEN
        multiplier := 1000;
        cleaned := REPLACE(cleaned, 'K', '');
    END IF;
    
    RETURN CAST(CAST(cleaned AS NUMERIC) * multiplier AS INT);
EXCEPTION
    WHEN OTHERS THEN
        RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- -----------------------------------------------
-- Helper function: Parse engagement rate
-- Handles: "3.5%", "0.035", etc.
-- -----------------------------------------------
CREATE OR REPLACE FUNCTION staging.parse_engagement_rate(raw_value TEXT)
RETURNS NUMERIC AS $$
DECLARE
    cleaned TEXT;
    result NUMERIC;
BEGIN
    IF raw_value IS NULL OR TRIM(raw_value) = '' THEN
        RETURN NULL;
    END IF;
    
    cleaned := TRIM(raw_value);
    
    IF cleaned LIKE '%\%%' THEN
        cleaned := REPLACE(cleaned, '%', '');
        result := CAST(cleaned AS NUMERIC) / 100;
    ELSE
        result := CAST(cleaned AS NUMERIC);
        -- If value > 1, assume it's a percentage not decimal
        IF result > 1 THEN
            result := result / 100;
        END IF;
    END IF;
    
    RETURN result;
EXCEPTION
    WHEN OTHERS THEN
        RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- -----------------------------------------------
-- Helper function: Standardize platform names
-- -----------------------------------------------
CREATE OR REPLACE FUNCTION staging.standardize_platform(raw_platform TEXT)
RETURNS VARCHAR AS $$
BEGIN
    CASE UPPER(TRIM(COALESCE(raw_platform, '')))
        WHEN 'INSTAGRAM' THEN RETURN 'Instagram';
        WHEN 'IG' THEN RETURN 'Instagram';
        WHEN 'YOUTUBE' THEN RETURN 'YouTube';
        WHEN 'YT' THEN RETURN 'YouTube';
        WHEN 'TIKTOK' THEN RETURN 'TikTok';
        WHEN 'TT' THEN RETURN 'TikTok';
        WHEN 'TWITCH' THEN RETURN 'Twitch';
        WHEN 'TWITTER' THEN RETURN 'Twitter';
        WHEN 'X' THEN RETURN 'Twitter';
        ELSE RETURN INITCAP(TRIM(raw_platform));
    END CASE;
END;
$$ LANGUAGE plpgsql;

-- -----------------------------------------------
-- Helper function: Classify creator tier by followers
-- -----------------------------------------------
CREATE OR REPLACE FUNCTION staging.classify_creator_tier(followers INT)
RETURNS VARCHAR AS $$
BEGIN
    IF followers IS NULL THEN RETURN 'Unknown';
    ELSIF followers < 10000 THEN RETURN 'Nano';
    ELSIF followers < 100000 THEN RETURN 'Micro';
    ELSIF followers < 500000 THEN RETURN 'Mid-Tier';
    ELSIF followers < 1000000 THEN RETURN 'Macro';
    ELSE RETURN 'Mega';
    END IF;
END;
$$ LANGUAGE plpgsql;

-- ============================================================
-- MAIN TRANSFORMATION PROCEDURES
-- ============================================================

-- -----------------------------------------------
-- Load and clean brands (with deduplication)
-- -----------------------------------------------
CREATE OR REPLACE PROCEDURE staging.load_brands()
LANGUAGE plpgsql AS $$
DECLARE
    rows_loaded INT;
BEGIN
    TRUNCATE staging.brands;
    
    INSERT INTO staging.brands (
        brand_id, brand_name, industry, country,
        annual_budget, contact_email, created_at, updated_at
    )
    SELECT DISTINCT ON (UPPER(brand_name))
        CAST(REPLACE(id, 'B', '') AS INT),
        INITCAP(TRIM(brand_name)),
        INITCAP(TRIM(industry)),
        UPPER(TRIM(country)),
        staging.parse_currency(annual_budget),
        LOWER(TRIM(contact_email)),
        CAST(created_at AS TIMESTAMP),
        CAST(updated_at AS TIMESTAMP)
    FROM raw.brands
    WHERE brand_name IS NOT NULL
    ORDER BY UPPER(brand_name), updated_at DESC;
    
    GET DIAGNOSTICS rows_loaded = ROW_COUNT;
    RAISE NOTICE 'Brands loaded: % rows', rows_loaded;
END;
$$;

-- -----------------------------------------------
-- Load and clean creators (with dedup + tier)
-- -----------------------------------------------
CREATE OR REPLACE PROCEDURE staging.load_creators()
LANGUAGE plpgsql AS $$
DECLARE
    rows_loaded INT;
BEGIN
    TRUNCATE staging.creators;
    
    INSERT INTO staging.creators (
        creator_id, username, display_name, platform,
        follower_count, engagement_rate, category, country,
        email, creator_tier, created_at
    )
    SELECT DISTINCT ON (LOWER(username), staging.standardize_platform(platform))
        CAST(REPLACE(id, 'C', '') AS INT),
        LOWER(TRIM(username)),
        TRIM(display_name),
        staging.standardize_platform(platform),
        staging.parse_follower_count(follower_count),
        staging.parse_engagement_rate(engagement_rate),
        INITCAP(TRIM(category)),
        UPPER(TRIM(country)),
        LOWER(TRIM(email)),
        staging.classify_creator_tier(staging.parse_follower_count(follower_count)),
        CAST(created_at AS TIMESTAMP)
    FROM raw.creators
    WHERE username IS NOT NULL
    ORDER BY LOWER(username), staging.standardize_platform(platform), created_at DESC;
    
    GET DIAGNOSTICS rows_loaded = ROW_COUNT;
    RAISE NOTICE 'Creators loaded: % rows', rows_loaded;
END;
$$;

-- -----------------------------------------------
-- Load and clean campaigns
-- -----------------------------------------------
CREATE OR REPLACE PROCEDURE staging.load_campaigns()
LANGUAGE plpgsql AS $$
DECLARE
    rows_loaded INT;
BEGIN
    TRUNCATE staging.campaigns;
    
    INSERT INTO staging.campaigns (
        campaign_id, campaign_name, brand_id, campaign_type,
        start_date, end_date, total_budget, status, created_at
    )
    SELECT
        CAST(REPLACE(id, 'CAM', '') AS INT),
        TRIM(campaign_name),
        CAST(REPLACE(brand_id, 'B', '') AS INT),
        INITCAP(LOWER(TRIM(campaign_type))),
        CAST(start_date AS DATE),
        CAST(NULLIF(end_date, '') AS DATE),
        staging.parse_currency(total_budget),
        LOWER(TRIM(status)),
        CAST(created_at AS TIMESTAMP)
    FROM raw.campaigns
    WHERE campaign_name IS NOT NULL;
    
    GET DIAGNOSTICS rows_loaded = ROW_COUNT;
    RAISE NOTICE 'Campaigns loaded: % rows', rows_loaded;
END;
$$;

-- -----------------------------------------------
-- Load and clean performance metrics (with dedup)
-- Uses window function to pick latest pull per day
-- -----------------------------------------------
CREATE OR REPLACE PROCEDURE staging.load_performance_metrics()
LANGUAGE plpgsql AS $$
DECLARE
    rows_loaded INT;
BEGIN
    TRUNCATE staging.performance_metrics;
    
    INSERT INTO staging.performance_metrics (
        metric_id, campaign_id, creator_id, platform,
        metric_date, impressions, clicks, likes, comments,
        shares, conversions, spend, revenue, post_url, pulled_at
    )
    SELECT
        metric_id,
        campaign_id,
        creator_id,
        platform,
        metric_date,
        impressions,
        COALESCE(clicks, 0),
        COALESCE(likes, 0),
        COALESCE(comments, 0),
        COALESCE(shares, 0),
        COALESCE(conversions, 0),
        COALESCE(spend, 0),
        COALESCE(revenue, 0),
        post_url,
        pulled_at
    FROM (
        SELECT
            CAST(REPLACE(id, 'PM', '') AS INT) AS metric_id,
            CAST(REPLACE(campaign_id, 'CAM', '') AS INT) AS campaign_id,
            CAST(REPLACE(creator_id, 'C', '') AS INT) AS creator_id,
            staging.standardize_platform(platform) AS platform,
            CAST(metric_date AS DATE) AS metric_date,
            CAST(NULLIF(impressions, '') AS INT) AS impressions,
            CAST(NULLIF(clicks, '') AS INT) AS clicks,
            CAST(NULLIF(likes, '') AS INT) AS likes,
            CAST(NULLIF(comments, '') AS INT) AS comments,
            CAST(NULLIF(shares, '') AS INT) AS shares,
            CAST(NULLIF(conversions, '') AS INT) AS conversions,
            staging.parse_currency(spend) AS spend,
            staging.parse_currency(revenue) AS revenue,
            post_url,
            CAST(pulled_at AS TIMESTAMP) AS pulled_at,
            ROW_NUMBER() OVER (
                PARTITION BY campaign_id, creator_id, metric_date, staging.standardize_platform(platform)
                ORDER BY CAST(pulled_at AS TIMESTAMP) DESC
            ) AS rn
        FROM raw.performance_metrics
        WHERE metric_date IS NOT NULL
    ) deduped
    WHERE rn = 1;
    
    GET DIAGNOSTICS rows_loaded = ROW_COUNT;
    RAISE NOTICE 'Performance metrics loaded: % rows', rows_loaded;
END;
$$;

-- -----------------------------------------------
-- Load campaign-creator assignments
-- -----------------------------------------------
CREATE OR REPLACE PROCEDURE staging.load_campaign_creators()
LANGUAGE plpgsql AS $$
DECLARE
    rows_loaded INT;
BEGIN
    TRUNCATE staging.campaign_creators;
    
    INSERT INTO staging.campaign_creators (
        assignment_id, campaign_id, creator_id,
        assigned_budget, content_type, deliverables,
        status, created_at
    )
    SELECT
        CAST(REPLACE(id, 'CC', '') AS INT),
        CAST(REPLACE(campaign_id, 'CAM', '') AS INT),
        CAST(REPLACE(creator_id, 'C', '') AS INT),
        staging.parse_currency(assigned_budget),
        LOWER(TRIM(content_type)),
        TRIM(deliverables),
        LOWER(TRIM(status)),
        CAST(created_at AS TIMESTAMP)
    FROM raw.campaign_creators;
    
    GET DIAGNOSTICS rows_loaded = ROW_COUNT;
    RAISE NOTICE 'Campaign-creator assignments loaded: % rows', rows_loaded;
END;
$$;

-- ============================================================
-- MASTER ORCHESTRATION: Run all staging transformations
-- ============================================================
CREATE OR REPLACE PROCEDURE staging.run_all_transformations()
LANGUAGE plpgsql AS $$
BEGIN
    RAISE NOTICE '=== Starting Staging Transformations ===';
    RAISE NOTICE 'Timestamp: %', NOW();
    
    CALL staging.load_brands();
    CALL staging.load_creators();
    CALL staging.load_campaigns();
    CALL staging.load_performance_metrics();
    CALL staging.load_campaign_creators();
    
    RAISE NOTICE '=== Staging Transformations Complete ===';
END;
$$;

-- Run it
CALL staging.run_all_transformations();
