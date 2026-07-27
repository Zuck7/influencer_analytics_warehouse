-- ============================================================
-- SEED DATA: Realistic messy data simulating source system exports
-- Intentionally includes: inconsistent casing, mixed formats,
-- duplicates, nulls, and formatting issues
-- ============================================================

-- Brands (some duplicates, inconsistent formatting)
INSERT INTO raw.brands VALUES
('B001', 'Nike', 'Sportswear', 'US', '$5,000,000', 'campaigns@nike.com', '2024-01-15', '2026-01-10'),
('B002', 'Wayfair', 'Home & Furniture', 'US', '$3,200,000', 'marketing@wayfair.com', '2024-03-20', '2026-02-15'),
('B003', 'Unilever', 'Consumer Goods', 'UK', '4500000', 'digital@unilever.com', '2024-02-01', '2026-01-20'),
('B004', 'Southwest Airlines', 'Travel', 'US', '$2,800,000', 'social@southwest.com', '2024-06-10', '2026-03-01'),
('B005', 'Glossier', 'Beauty', 'US', '$1,500,000', 'influencer@glossier.com', '2024-04-15', '2025-12-20'),
('B006', 'nike', 'sportswear', 'US', '$5,000,000', 'campaigns@nike.com', '2024-01-15', '2026-01-10'),  -- duplicate
('B007', 'Lululemon', 'Athleisure', 'CA', '$2,100,000', 'partnerships@lululemon.com', '2024-07-01', '2026-04-15'),
('B008', 'Sephora', 'Beauty', 'FR', '3,800,000', NULL, '2024-05-12', '2026-02-28'),
('B009', 'Red Bull', 'Beverages', 'AT', '$4,200,000', 'content@redbull.com', '2024-08-20', '2026-05-10'),
('B010', 'Airbnb', 'Travel', 'US', '$6,000,000', 'creators@airbnb.com', '2024-09-01', '2026-06-01');

-- Creators (inconsistent platform names, mixed follower formats)
INSERT INTO raw.creators VALUES
('C001', 'fitlife_sarah', 'Sarah Johnson', 'Instagram', '1.2M', '3.5%', 'Fitness', 'US', 'sarah@fitlife.com', '2023-06-15'),
('C002', 'techreviewer_mike', 'Mike Chen', 'youtube', '850K', '4.2%', 'Technology', 'CA', 'mike@techreviews.com', '2023-08-20'),
('C003', 'wanderlust_emma', 'Emma Wilson', 'IG', '320K', '0.055', 'Travel', 'UK', 'emma@wanderlust.com', '2023-05-10'),
('C004', 'beautybyjas', 'Jasmine Lee', 'Instagram', '2.5M', '2.8%', 'Beauty', 'US', 'jas@beautybyjas.com', '2023-07-01'),
('C005', 'homestyle_alex', 'Alex Rivera', 'INSTAGRAM', '180K', '6.1%', 'Home Decor', 'US', 'alex@homestyle.com', '2023-09-15'),
('C006', 'foodie_raj', 'Raj Patel', 'TikTok', '950K', '5.3%', 'Food', 'CA', 'raj@foodieraj.com', '2023-04-20'),
('C007', 'adventure_tom', 'Tom Baker', 'YouTube', '1.8M', '3.1%', 'Outdoor', 'US', 'tom@adventuretom.com', '2023-10-05'),
('C008', 'skincare_nina', 'Nina Garcia', 'instagram', '420K', '4.8%', 'Beauty', 'US', NULL, '2023-11-12'),
('C009', 'fitlife_sarah', 'Sarah Johnson', 'Instagram', '1.2M', '3.5%', 'Fitness', 'US', 'sarah@fitlife.com', '2023-06-15'),  -- duplicate
('C010', 'lifestyle_maya', 'Maya Thompson', 'tiktok', '3200', '0.089', 'Lifestyle', 'CA', 'maya@lifestyle.com', '2024-01-08'),
('C011', 'gaming_leo', 'Leo Park', 'Twitch', '620K', '7.2%', 'Gaming', 'KR', 'leo@gamingleo.com', '2023-12-01'),
('C012', 'eco_living_sam', 'Sam Green', 'Instagram', '290K', '5.0%', 'Sustainability', 'US', 'sam@ecoliving.com', '2024-02-15');

-- Campaigns (inconsistent casing, some missing end dates)
INSERT INTO raw.campaigns VALUES
('CAM001', 'Summer Fitness Challenge 2025', 'B001', 'Awareness', '2025-06-01', '2025-08-31', '$250,000', 'completed', '2025-05-15'),
('CAM002', 'Home Refresh Spring', 'B002', 'conversion', '2025-03-15', '2025-05-15', '180000', 'completed', '2025-03-01'),
('CAM003', 'Clean Beauty Launch', 'B003', 'AWARENESS', '2025-09-01', '2025-11-30', '$320,000', 'completed', '2025-08-20'),
('CAM004', 'Holiday Travel Deals', 'B004', 'Conversion', '2025-11-15', '2025-12-31', '$200,000', 'completed', '2025-11-01'),
('CAM005', 'Glossier You Campaign', 'B005', 'engagement', '2025-10-01', '2025-12-15', '$150,000', 'completed', '2025-09-15'),
('CAM006', 'New Year Fitness 2026', 'B001', 'Awareness', '2026-01-01', '2026-03-31', '$300,000', 'active', '2025-12-15'),
('CAM007', 'Spring Home Makeover', 'B002', 'conversion', '2026-03-01', NULL, '$220,000', 'active', '2026-02-15'),
('CAM008', 'Lululemon Summer Run', 'B007', 'ENGAGEMENT', '2026-05-01', '2026-07-31', '280000', 'planned', '2026-04-01'),
('CAM009', 'Sephora Fall Glam', 'B008', 'awareness', '2026-09-01', '2026-11-30', '$350,000', 'planned', '2026-08-01'),
('CAM010', 'Red Bull Adventure Series', 'B009', 'Engagement', '2026-06-01', '2026-08-31', '$400,000', 'active', '2026-05-15');

-- Campaign-Creator Assignments
INSERT INTO raw.campaign_creators VALUES
('CC001', 'CAM001', 'C001', '$50,000', 'post', '3 posts, 5 stories', 'completed', '2025-05-20'),
('CC002', 'CAM001', 'C007', '$45,000', 'video', '2 videos', 'completed', '2025-05-20'),
('CC003', 'CAM002', 'C005', '$35,000', 'reel', '4 reels', 'completed', '2025-03-05'),
('CC004', 'CAM003', 'C004', '$80,000', 'post', '5 posts, 10 stories', 'completed', '2025-08-25'),
('CC005', 'CAM003', 'C008', '$40,000', 'reel', '3 reels', 'completed', '2025-08-25'),
('CC006', 'CAM004', 'C003', '$30,000', 'post', '3 posts', 'completed', '2025-11-05'),
('CC007', 'CAM005', 'C004', '$45,000', 'video', '2 videos, 4 stories', 'completed', '2025-09-20'),
('CC008', 'CAM006', 'C001', '$60,000', 'post', '4 posts, 8 stories', 'active', '2025-12-20'),
('CC009', 'CAM006', 'C007', '$55,000', 'video', '3 videos', 'active', '2025-12-20'),
('CC010', 'CAM007', 'C005', '$40,000', 'reel', '5 reels', 'active', '2026-02-20'),
('CC011', 'CAM008', 'C001', '$70,000', 'post', '5 posts, 10 stories', 'planned', '2026-04-05'),
('CC012', 'CAM010', 'C007', '$80,000', 'video', '4 videos', 'active', '2026-05-20'),
('CC013', 'CAM010', 'C006', '$60,000', 'reel', '6 reels', 'active', '2026-05-20');

-- Performance Metrics (daily data with some messy values)
INSERT INTO raw.performance_metrics VALUES
('PM001', 'CAM001', 'C001', 'Instagram', '2025-06-15', '125000', '3200', '8500', '420', '180', '85', '$2,100', '$8,500', 'https://instagram.com/p/abc123', '2025-06-16 02:00:00'),
('PM002', 'CAM001', 'C001', 'Instagram', '2025-06-16', '98000', '2800', '7200', '380', '150', '72', '$1,800', '$7,200', 'https://instagram.com/p/abc124', '2025-06-17 02:00:00'),
('PM003', 'CAM001', 'C007', 'YouTube', '2025-06-15', '250000', '5500', '12000', '850', '420', '120', '$3,500', '$12,000', 'https://youtube.com/watch?v=xyz', '2025-06-16 02:00:00'),
('PM004', 'CAM001', 'C007', 'YouTube', '2025-06-20', '180000', '4200', '9800', '620', '310', '95', '$2,800', '$9,500', 'https://youtube.com/watch?v=xyz2', '2025-06-21 02:00:00'),
('PM005', 'CAM002', 'C005', 'Instagram', '2025-03-20', '45000', '1800', '3200', '180', '90', '45', '$900', '$4,500', 'https://instagram.com/p/def456', '2025-03-21 02:00:00'),
('PM006', 'CAM002', 'C005', 'Instagram', '2025-03-25', '52000', '2100', '3800', '210', '110', '52', '$1,050', '$5,200', 'https://instagram.com/p/def457', '2025-03-26 02:00:00'),
('PM007', 'CAM003', 'C004', 'Instagram', '2025-09-10', '380000', '8500', '22000', '1200', '580', '210', '$5,200', '$21,000', 'https://instagram.com/p/ghi789', '2025-09-11 02:00:00'),
('PM008', 'CAM003', 'C004', 'Instagram', '2025-09-15', '420000', '9200', '25000', '1400', '650', '245', '$5,800', '$24,500', 'https://instagram.com/p/ghi790', '2025-09-16 02:00:00'),
('PM009', 'CAM003', 'C008', 'Instagram', '2025-09-12', '85000', '2400', '5100', '280', '140', '62', '$1,200', '$6,200', 'https://instagram.com/p/jkl012', '2025-09-13 02:00:00'),
('PM010', 'CAM004', 'C003', 'Instagram', '2025-11-20', '68000', '1900', '4200', '230', '95', '38', '$950', '$3,800', 'https://instagram.com/p/mno345', '2025-11-21 02:00:00'),
('PM011', 'CAM005', 'C004', 'Instagram', '2025-10-08', '290000', '6800', '18000', '980', '450', '175', '$4,200', '$17,500', 'https://instagram.com/p/pqr678', '2025-10-09 02:00:00'),
('PM012', 'CAM006', 'C001', 'Instagram', '2026-01-10', '135000', '3500', '9200', '480', '200', '92', '$2,300', '$9,200', 'https://instagram.com/p/stu901', '2026-01-11 02:00:00'),
('PM013', 'CAM006', 'C001', 'Instagram', '2026-01-15', '142000', '3800', '9800', '510', '220', '98', '$2,500', '$9,800', 'https://instagram.com/p/stu902', '2026-01-16 02:00:00'),
('PM014', 'CAM006', 'C007', 'YouTube', '2026-01-12', '280000', '6200', '14000', '920', '480', '135', '$4,000', '$13,500', 'https://youtube.com/watch?v=abc', '2026-01-13 02:00:00'),
('PM015', 'CAM010', 'C007', 'YouTube', '2026-06-05', '310000', '7100', '16000', '1050', '520', '155', '$4,500', '$15,500', 'https://youtube.com/watch?v=def', '2026-06-06 02:00:00'),
('PM016', 'CAM010', 'C006', 'TikTok', '2026-06-05', '520000', '12000', '35000', '2200', '1800', '280', '$3,800', '$14,000', 'https://tiktok.com/@foodie/v1', '2026-06-06 02:00:00'),
('PM017', 'CAM010', 'C006', 'TikTok', '2026-06-10', '480000', '11000', '32000', '2000', '1650', '260', '$3,500', '$13,000', 'https://tiktok.com/@foodie/v2', '2026-06-11 02:00:00'),
-- Duplicate record to test dedup
('PM018', 'CAM001', 'C001', 'Instagram', '2025-06-15', '125000', '3200', '8500', '420', '180', '85', '$2,100', '$8,500', 'https://instagram.com/p/abc123', '2025-06-16 04:00:00'),
-- Record with NULL values
('PM019', 'CAM006', 'C001', 'Instagram', '2026-02-01', '110000', NULL, '7800', '390', NULL, '78', '$1,900', NULL, NULL, '2026-02-02 02:00:00');
