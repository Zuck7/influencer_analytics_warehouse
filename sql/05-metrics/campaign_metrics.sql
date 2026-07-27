-- ============================================================
-- METRICS LAYER: Reusable views for analytics and reporting
-- These serve as the "metrics layer" similar to dbt metrics
-- ============================================================

-- -----------------------------------------------
-- Campaign Performance Summary
-- Aggregated at campaign level with KPIs
-- -----------------------------------------------
CREATE OR REPLACE VIEW warehouse.vw_campaign_summary AS
SELECT
    dc.campaign_name,
    dc.campaign_type,
    dc.status,
    db.brand_name,
    db.industry,
    dc.total_budget,
    dc.start_date,
    dc.end_date,
    dc.duration_days,
    COUNT(DISTINCT f.creator_key) AS creator_count,
    COUNT(DISTINCT f.date_key) AS active_days,
    SUM(f.impressions) AS total_impressions,
    SUM(f.clicks) AS total_clicks,
    SUM(f.conversions) AS total_conversions,
    SUM(f.spend) AS total_spend,
    SUM(f.revenue) AS total_revenue,
    -- Derived KPIs
    ROUND(SUM(f.clicks)::NUMERIC / NULLIF(SUM(f.impressions), 0) * 100, 2) AS avg_ctr_pct,
    ROUND(SUM(f.revenue) / NULLIF(SUM(f.spend), 0), 2) AS overall_roas,
    ROUND(SUM(f.spend) / NULLIF(SUM(f.impressions), 0) * 1000, 2) AS avg_cpm,
    ROUND(SUM(f.spend) / NULLIF(SUM(f.conversions), 0), 2) AS cost_per_conversion,
    SUM(f.engagement_total) AS total_engagement,
    ROUND(SUM(f.engagement_total)::NUMERIC / NULLIF(SUM(f.impressions), 0) * 100, 2) AS engagement_rate_pct
FROM warehouse.fact_campaign_performance f
JOIN warehouse.dim_campaign dc ON f.campaign_key = dc.campaign_key
JOIN warehouse.dim_brand db ON dc.brand_id = db.brand_id
GROUP BY dc.campaign_name, dc.campaign_type, dc.status, db.brand_name, db.industry,
         dc.total_budget, dc.start_date, dc.end_date, dc.duration_days;

-- -----------------------------------------------
-- Creator ROI Ranking
-- Which creators deliver the best return?
-- -----------------------------------------------
CREATE OR REPLACE VIEW warehouse.vw_creator_roi_ranking AS
SELECT
    dcr.display_name,
    dcr.username,
    dcr.primary_platform,
    dcr.creator_tier,
    dcr.follower_count,
    dcr.category,
    COUNT(DISTINCT f.campaign_key) AS campaigns_participated,
    SUM(f.impressions) AS total_impressions,
    SUM(f.conversions) AS total_conversions,
    SUM(f.spend) AS total_spend,
    SUM(f.revenue) AS total_revenue,
    ROUND(SUM(f.revenue) / NULLIF(SUM(f.spend), 0), 2) AS roas,
    ROUND(SUM(f.spend) / NULLIF(SUM(f.conversions), 0), 2) AS cost_per_conversion,
    SUM(f.engagement_total) AS total_engagement,
    ROUND(SUM(f.engagement_total)::NUMERIC / NULLIF(SUM(f.impressions), 0) * 100, 2) AS engagement_rate_pct,
    -- Rank by ROAS within tier
    RANK() OVER (
        PARTITION BY dcr.creator_tier
        ORDER BY SUM(f.revenue) / NULLIF(SUM(f.spend), 0) DESC
    ) AS roas_rank_in_tier,
    -- Overall revenue rank
    RANK() OVER (ORDER BY SUM(f.revenue) DESC) AS revenue_rank_overall
FROM warehouse.fact_campaign_performance f
JOIN warehouse.dim_creator dcr ON f.creator_key = dcr.creator_key
GROUP BY dcr.display_name, dcr.username, dcr.primary_platform,
         dcr.creator_tier, dcr.follower_count, dcr.category;

-- -----------------------------------------------
-- Platform Benchmarks
-- Compare performance across social platforms
-- -----------------------------------------------
CREATE OR REPLACE VIEW warehouse.vw_platform_benchmarks AS
SELECT
    dp.platform_name,
    dp.avg_cpm AS industry_benchmark_cpm,
    COUNT(DISTINCT f.campaign_key) AS campaigns,
    COUNT(DISTINCT f.creator_key) AS creators,
    SUM(f.impressions) AS total_impressions,
    ROUND(AVG(f.ctr) * 100, 3) AS avg_ctr_pct,
    ROUND(AVG(f.cpm), 2) AS actual_avg_cpm,
    ROUND(AVG(f.roas), 2) AS avg_roas,
    ROUND(AVG(f.engagement_total)::NUMERIC, 0) AS avg_engagement_per_post,
    -- Compare actual CPM to industry benchmark
    ROUND(AVG(f.cpm) - dp.avg_cpm, 2) AS cpm_vs_benchmark,
    CASE
        WHEN AVG(f.cpm) < dp.avg_cpm THEN 'Below Benchmark (Good)'
        WHEN AVG(f.cpm) < dp.avg_cpm * 1.2 THEN 'Near Benchmark'
        ELSE 'Above Benchmark (Review)'
    END AS cpm_assessment
FROM warehouse.fact_campaign_performance f
JOIN warehouse.dim_platform dp ON f.platform_key = dp.platform_key
GROUP BY dp.platform_name, dp.avg_cpm;

-- -----------------------------------------------
-- Campaign Monthly Trend
-- Time-series view for trend analysis
-- -----------------------------------------------
CREATE OR REPLACE VIEW warehouse.vw_campaign_monthly_trend AS
SELECT
    db.brand_name,
    dc.campaign_name,
    DATE_TRUNC('month', f.date_key)::DATE AS campaign_month,
    SUM(f.impressions) AS monthly_impressions,
    SUM(f.clicks) AS monthly_clicks,
    SUM(f.conversions) AS monthly_conversions,
    SUM(f.spend) AS monthly_spend,
    SUM(f.revenue) AS monthly_revenue,
    ROUND(SUM(f.revenue) / NULLIF(SUM(f.spend), 0), 2) AS monthly_roas,
    SUM(f.engagement_total) AS monthly_engagement,
    -- Month-over-month change using window functions
    LAG(SUM(f.revenue)) OVER (
        PARTITION BY dc.campaign_name ORDER BY DATE_TRUNC('month', f.date_key)
    ) AS prev_month_revenue,
    ROUND(
        (SUM(f.revenue) - LAG(SUM(f.revenue)) OVER (
            PARTITION BY dc.campaign_name ORDER BY DATE_TRUNC('month', f.date_key)
        )) / NULLIF(LAG(SUM(f.revenue)) OVER (
            PARTITION BY dc.campaign_name ORDER BY DATE_TRUNC('month', f.date_key)
        ), 0) * 100, 1
    ) AS revenue_mom_change_pct
FROM warehouse.fact_campaign_performance f
JOIN warehouse.dim_campaign dc ON f.campaign_key = dc.campaign_key
JOIN warehouse.dim_brand db ON dc.brand_id = db.brand_id
GROUP BY db.brand_name, dc.campaign_name, DATE_TRUNC('month', f.date_key);

-- -----------------------------------------------
-- Creator Tier Analysis
-- How do different tiers compare?
-- -----------------------------------------------
CREATE OR REPLACE VIEW warehouse.vw_creator_tier_analysis AS
SELECT
    dcr.creator_tier,
    COUNT(DISTINCT dcr.creator_key) AS creator_count,
    ROUND(AVG(dcr.follower_count)) AS avg_followers,
    ROUND(AVG(dcr.engagement_rate) * 100, 2) AS avg_engagement_rate_pct,
    SUM(f.impressions) AS total_impressions,
    SUM(f.spend) AS total_spend,
    SUM(f.revenue) AS total_revenue,
    ROUND(SUM(f.revenue) / NULLIF(SUM(f.spend), 0), 2) AS tier_roas,
    ROUND(SUM(f.spend) / NULLIF(SUM(f.conversions), 0), 2) AS tier_cost_per_conversion,
    ROUND(AVG(f.cpm), 2) AS tier_avg_cpm
FROM warehouse.fact_campaign_performance f
JOIN warehouse.dim_creator dcr ON f.creator_key = dcr.creator_key
GROUP BY dcr.creator_tier
ORDER BY tier_roas DESC;

-- -----------------------------------------------
-- Budget Utilization Analysis
-- Are campaigns spending their allocated budgets?
-- -----------------------------------------------
CREATE OR REPLACE VIEW warehouse.vw_budget_utilization AS
SELECT
    dc.campaign_name,
    db.brand_name,
    dc.total_budget,
    SUM(f.spend) AS actual_spend,
    ROUND(SUM(f.spend) / NULLIF(dc.total_budget, 0) * 100, 1) AS utilization_pct,
    dc.total_budget - SUM(f.spend) AS remaining_budget,
    SUM(f.revenue) AS total_revenue,
    ROUND(SUM(f.revenue) / NULLIF(dc.total_budget, 0) * 100, 1) AS revenue_to_budget_pct,
    CASE
        WHEN SUM(f.spend) / NULLIF(dc.total_budget, 0) > 0.9 THEN 'Fully Utilized'
        WHEN SUM(f.spend) / NULLIF(dc.total_budget, 0) > 0.5 THEN 'On Track'
        WHEN SUM(f.spend) / NULLIF(dc.total_budget, 0) > 0.2 THEN 'Under-Utilized'
        ELSE 'Significantly Under-Utilized'
    END AS utilization_status
FROM warehouse.fact_campaign_performance f
JOIN warehouse.dim_campaign dc ON f.campaign_key = dc.campaign_key
JOIN warehouse.dim_brand db ON dc.brand_id = db.brand_id
GROUP BY dc.campaign_name, db.brand_name, dc.total_budget;
