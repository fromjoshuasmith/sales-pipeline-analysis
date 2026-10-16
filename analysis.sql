-- SQLite analysis added to make the published portfolio reproducible.
-- Original source checks remain in source-data-validation.sql.
-- Source rows are preserved. Normalization is applied through views.

CREATE TEMP VIEW clean_pipeline AS
SELECT opportunity_id, sales_agent,
       CASE WHEN product = 'GTXPro' THEN 'GTX Pro' ELSE product END AS product,
       account, deal_stage, engage_date, close_date,
       CAST(close_value AS REAL) AS close_value
FROM sales_pipeline;

CREATE TEMP VIEW clean_accounts AS
SELECT account,
       CASE WHEN sector = 'technolgy' THEN 'Technology'
            ELSE upper(substr(sector, 1, 1)) || substr(sector, 2) END AS sector
FROM accounts;

-- summary
SELECT COUNT(*) AS total_opportunities,
       SUM(CASE WHEN deal_stage = 'Won' THEN 1 ELSE 0 END) AS won_opportunities,
       SUM(CASE WHEN deal_stage = 'Lost' THEN 1 ELSE 0 END) AS lost_opportunities,
       SUM(CASE WHEN deal_stage IN ('Engaging','Prospecting') THEN 1 ELSE 0 END) AS open_opportunities,
       SUM(CASE WHEN deal_stage = 'Won' THEN close_value ELSE 0 END) AS won_revenue,
       100.0 * SUM(CASE WHEN deal_stage = 'Won' THEN 1 ELSE 0 END)
           / NULLIF(SUM(CASE WHEN deal_stage IN ('Won','Lost') THEN 1 ELSE 0 END),0) AS closed_win_rate_percent,
       AVG(CASE WHEN deal_stage IN ('Won','Lost')
                THEN julianday(close_date) - julianday(engage_date) END) AS avg_days_to_close,
       SUM(CASE WHEN deal_stage = 'Won' THEN close_value ELSE 0 END)
           / NULLIF(SUM(CASE WHEN deal_stage = 'Won' THEN 1 ELSE 0 END),0) AS avg_won_deal_size
FROM clean_pipeline;

-- revenue_by_region
SELECT st.regional_office, SUM(sp.close_value) AS revenue
FROM clean_pipeline sp
LEFT JOIN sales_teams st USING (sales_agent)
WHERE sp.deal_stage = 'Won'
GROUP BY st.regional_office
ORDER BY revenue DESC;

-- revenue_by_product
SELECT product, SUM(close_value) AS revenue
FROM clean_pipeline
WHERE deal_stage = 'Won'
GROUP BY product
ORDER BY revenue DESC;

-- revenue_by_quarter
SELECT substr(close_date,1,4) || ' Q' ||
       ((CAST(substr(close_date,6,2) AS INTEGER) + 2) / 3) AS quarter,
       SUM(close_value) AS revenue
FROM clean_pipeline
WHERE deal_stage = 'Won'
GROUP BY quarter
ORDER BY quarter;

-- open_pipeline_by_stage
SELECT sp.deal_stage, COUNT(*) AS opportunities,
       SUM(CAST(p.sales_price AS REAL)) AS list_price_value
FROM clean_pipeline sp
LEFT JOIN products p USING (product)
WHERE sp.deal_stage IN ('Engaging','Prospecting')
GROUP BY sp.deal_stage
ORDER BY sp.deal_stage;

-- weighted_pipeline
SELECT SUM(CAST(p.sales_price AS REAL) *
           CASE sp.deal_stage WHEN 'Prospecting' THEN 0.20
                              WHEN 'Engaging' THEN 0.50 ELSE 0 END)
       AS stage_weighted_value
FROM clean_pipeline sp
LEFT JOIN products p USING (product)
WHERE sp.deal_stage IN ('Engaging','Prospecting');

-- data_quality
SELECT 'duplicate_opportunity_ids' AS check_name,
       COUNT(*) - COUNT(DISTINCT opportunity_id) AS issue_count FROM clean_pipeline
UNION ALL
SELECT 'unmatched_products_after_cleanup', COUNT(*)
FROM clean_pipeline sp LEFT JOIN products p USING(product) WHERE p.product IS NULL
UNION ALL
SELECT 'unmatched_sales_agents', COUNT(*)
FROM clean_pipeline sp LEFT JOIN sales_teams st USING(sales_agent) WHERE st.sales_agent IS NULL
UNION ALL
SELECT 'unmatched_nonblank_accounts', COUNT(*)
FROM clean_pipeline sp LEFT JOIN accounts a USING(account)
WHERE sp.account IS NOT NULL AND a.account IS NULL
UNION ALL
SELECT 'missing_accounts', COUNT(*) FROM clean_pipeline WHERE account IS NULL
UNION ALL
SELECT 'close_before_engage_date', COUNT(*) FROM clean_pipeline
WHERE julianday(close_date) < julianday(engage_date)
UNION ALL
SELECT 'closed_without_dates_or_values', COUNT(*) FROM clean_pipeline
WHERE deal_stage IN ('Won','Lost')
  AND (close_date IS NULL OR engage_date IS NULL OR close_value IS NULL)
UNION ALL
SELECT 'duplicate_account_keys', COUNT(*) - COUNT(DISTINCT account) FROM accounts
UNION ALL
SELECT 'duplicate_product_keys', COUNT(*) - COUNT(DISTINCT product) FROM products
UNION ALL
SELECT 'duplicate_sales_agent_keys', COUNT(*) - COUNT(DISTINCT sales_agent) FROM sales_teams;
