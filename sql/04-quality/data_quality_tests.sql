-- ============================================================
-- DATA QUALITY FRAMEWORK: Automated tests for validation
-- Mirrors dbt test patterns (not_null, unique, relationships,
-- accepted_values, and custom statistical tests)
-- ============================================================

DROP TABLE IF EXISTS warehouse.quality_test_results;

CREATE TABLE warehouse.quality_test_results (
    test_id         SERIAL PRIMARY KEY,
    test_name       VARCHAR(200) NOT NULL,
    test_type       VARCHAR(50),
    table_name      VARCHAR(100),
    column_name     VARCHAR(100),
    status          VARCHAR(10),  -- PASS / FAIL / WARN
    failures_count  INT DEFAULT 0,
    details         TEXT,
    tested_at       TIMESTAMP DEFAULT NOW()
);

-- -----------------------------------------------
-- Core test runner procedure
-- -----------------------------------------------
CREATE OR REPLACE PROCEDURE warehouse.run_quality_test(
    p_test_name VARCHAR,
    p_test_type VARCHAR,
    p_table_name VARCHAR,
    p_column_name VARCHAR,
    p_query TEXT,
    p_threshold INT DEFAULT 0
)
LANGUAGE plpgsql AS $$
DECLARE
    failure_count INT;
    test_status VARCHAR(10);
BEGIN
    EXECUTE p_query INTO failure_count;
    
    IF failure_count IS NULL THEN failure_count := 0; END IF;
    
    IF failure_count <= p_threshold THEN
        test_status := 'PASS';
    ELSIF failure_count <= p_threshold * 2 THEN
        test_status := 'WARN';
    ELSE
        test_status := 'FAIL';
    END IF;
    
    INSERT INTO warehouse.quality_test_results (
        test_name, test_type, table_name, column_name,
        status, failures_count, details
    ) VALUES (
        p_test_name, p_test_type, p_table_name, p_column_name,
        test_status, failure_count,
        'Found ' || failure_count || ' failures (threshold: ' || p_threshold || ')'
    );
    
    RAISE NOTICE '[%] % — % failures', test_status, p_test_name, failure_count;
END;
$$;

-- ============================================================
-- RUN ALL DATA QUALITY TESTS
-- ============================================================
CREATE OR REPLACE PROCEDURE warehouse.run_all_quality_tests()
LANGUAGE plpgsql AS $$
BEGIN
    -- Clear previous results
    TRUNCATE warehouse.quality_test_results;
    RAISE NOTICE '=== Running Data Quality Tests ===';
    
    -- ------------------------------------------
    -- NOT NULL TESTS
    -- ------------------------------------------
    CALL warehouse.run_quality_test(
        'dim_brand.brand_name not null', 'not_null', 'dim_brand', 'brand_name',
        'SELECT COUNT(*) FROM warehouse.dim_brand WHERE brand_name IS NULL'
    );
    
    CALL warehouse.run_quality_test(
        'dim_creator.username not null', 'not_null', 'dim_creator', 'username',
        'SELECT COUNT(*) FROM warehouse.dim_creator WHERE username IS NULL'
    );
    
    CALL warehouse.run_quality_test(
        'dim_campaign.campaign_name not null', 'not_null', 'dim_campaign', 'campaign_name',
        'SELECT COUNT(*) FROM warehouse.dim_campaign WHERE campaign_name IS NULL'
    );
    
    CALL warehouse.run_quality_test(
        'fact_performance.impressions not null', 'not_null', 'fact_campaign_performance', 'impressions',
        'SELECT COUNT(*) FROM warehouse.fact_campaign_performance WHERE impressions IS NULL'
    );
    
    -- ------------------------------------------
    -- UNIQUENESS TESTS
    -- ------------------------------------------
    CALL warehouse.run_quality_test(
        'dim_brand.brand_id unique', 'unique', 'dim_brand', 'brand_id',
        'SELECT COUNT(*) - COUNT(DISTINCT brand_id) FROM warehouse.dim_brand'
    );
    
    CALL warehouse.run_quality_test(
        'dim_creator.creator_id unique', 'unique', 'dim_creator', 'creator_id',
        'SELECT COUNT(*) - COUNT(DISTINCT creator_id) FROM warehouse.dim_creator'
    );
    
    CALL warehouse.run_quality_test(
        'dim_campaign.campaign_id unique', 'unique', 'dim_campaign', 'campaign_id',
        'SELECT COUNT(*) - COUNT(DISTINCT campaign_id) FROM warehouse.dim_campaign'
    );
    
    -- ------------------------------------------
    -- REFERENTIAL INTEGRITY TESTS
    -- ------------------------------------------
    CALL warehouse.run_quality_test(
        'fact_performance.campaign_key references dim_campaign', 'relationship',
        'fact_campaign_performance', 'campaign_key',
        'SELECT COUNT(*) FROM warehouse.fact_campaign_performance f 
         LEFT JOIN warehouse.dim_campaign d ON f.campaign_key = d.campaign_key 
         WHERE d.campaign_key IS NULL'
    );
    
    CALL warehouse.run_quality_test(
        'fact_performance.creator_key references dim_creator', 'relationship',
        'fact_campaign_performance', 'creator_key',
        'SELECT COUNT(*) FROM warehouse.fact_campaign_performance f 
         LEFT JOIN warehouse.dim_creator d ON f.creator_key = d.creator_key 
         WHERE d.creator_key IS NULL'
    );
    
    CALL warehouse.run_quality_test(
        'fact_performance.platform_key references dim_platform', 'relationship',
        'fact_campaign_performance', 'platform_key',
        'SELECT COUNT(*) FROM warehouse.fact_campaign_performance f 
         LEFT JOIN warehouse.dim_platform d ON f.platform_key = d.platform_key 
         WHERE d.platform_key IS NULL'
    );
    
    -- ------------------------------------------
    -- ACCEPTED VALUES TESTS
    -- ------------------------------------------
    CALL warehouse.run_quality_test(
        'dim_campaign.campaign_type accepted values', 'accepted_values',
        'dim_campaign', 'campaign_type',
        'SELECT COUNT(*) FROM warehouse.dim_campaign 
         WHERE campaign_type NOT IN (''Awareness'', ''Conversion'', ''Engagement'')'
    );
    
    CALL warehouse.run_quality_test(
        'dim_creator.creator_tier accepted values', 'accepted_values',
        'dim_creator', 'creator_tier',
        'SELECT COUNT(*) FROM warehouse.dim_creator 
         WHERE creator_tier NOT IN (''Nano'', ''Micro'', ''Mid-Tier'', ''Macro'', ''Mega'', ''Unknown'')'
    );
    
    -- ------------------------------------------
    -- RANGE / ANOMALY TESTS
    -- ------------------------------------------
    CALL warehouse.run_quality_test(
        'fact_performance.ctr within expected range (0-1)', 'range_check',
        'fact_campaign_performance', 'ctr',
        'SELECT COUNT(*) FROM warehouse.fact_campaign_performance WHERE ctr < 0 OR ctr > 1'
    );
    
    CALL warehouse.run_quality_test(
        'fact_performance.roas positive', 'range_check',
        'fact_campaign_performance', 'roas',
        'SELECT COUNT(*) FROM warehouse.fact_campaign_performance WHERE roas IS NOT NULL AND roas < 0'
    );
    
    CALL warehouse.run_quality_test(
        'fact_performance.spend not negative', 'range_check',
        'fact_campaign_performance', 'spend',
        'SELECT COUNT(*) FROM warehouse.fact_campaign_performance WHERE spend < 0'
    );
    
    -- ------------------------------------------
    -- STATISTICAL ANOMALY: Flag outlier impressions
    -- (more than 3 standard deviations from mean)
    -- ------------------------------------------
    CALL warehouse.run_quality_test(
        'fact_performance.impressions no extreme outliers', 'statistical',
        'fact_campaign_performance', 'impressions',
        'WITH stats AS (
            SELECT AVG(impressions) AS avg_imp, STDDEV(impressions) AS std_imp
            FROM warehouse.fact_campaign_performance
        )
        SELECT COUNT(*) FROM warehouse.fact_campaign_performance f, stats s
        WHERE f.impressions > s.avg_imp + 3 * s.std_imp
           OR f.impressions < s.avg_imp - 3 * s.std_imp',
        1  -- allow 1 outlier before failing
    );
    
    -- ------------------------------------------
    -- FRESHNESS TEST: Check data is recent
    -- ------------------------------------------
    CALL warehouse.run_quality_test(
        'fact_performance has data within last 90 days', 'freshness',
        'fact_campaign_performance', 'date_key',
        'SELECT CASE WHEN MAX(date_key) >= CURRENT_DATE - INTERVAL ''90 days'' THEN 0 ELSE 1 END
         FROM warehouse.fact_campaign_performance'
    );
    
    RAISE NOTICE '=== Data Quality Tests Complete ===';
END;
$$;

-- Run all tests
CALL warehouse.run_all_quality_tests();

-- -----------------------------------------------
-- View for test results summary
-- -----------------------------------------------
CREATE OR REPLACE VIEW warehouse.vw_quality_test_results AS
SELECT
    test_name,
    test_type,
    table_name,
    column_name,
    status,
    failures_count,
    details,
    tested_at
FROM warehouse.quality_test_results
ORDER BY
    CASE status WHEN 'FAIL' THEN 1 WHEN 'WARN' THEN 2 ELSE 3 END,
    tested_at DESC;

CREATE OR REPLACE VIEW warehouse.vw_quality_summary AS
SELECT
    status,
    COUNT(*) AS test_count,
    ROUND(COUNT(*)::NUMERIC / SUM(COUNT(*)) OVER () * 100, 1) AS pct
FROM warehouse.quality_test_results
GROUP BY status
ORDER BY CASE status WHEN 'FAIL' THEN 1 WHEN 'WARN' THEN 2 ELSE 3 END;
