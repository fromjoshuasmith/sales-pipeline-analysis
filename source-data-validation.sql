/*
B2B Sales Pipeline Performance Dashboard
SQL Source Data Validation

This SQL file was used to validate the raw CRM source data before building the final Power BI dashboard. The checks confirm table row counts, deal stage distribution, missing values, relationship mismatches, KPI totals, win rate, closed won revenue, regional revenue, and product revenue.

One product naming mismatch was identified in the raw data: GTXPro. This was cleaned as GTX Pro in Power Query for the final Power BI model.
*/


-- 1. Record counts by table
SELECT 'accounts' AS table_name, COUNT(*) AS row_count
FROM accounts

UNION ALL

SELECT 'products' AS table_name, COUNT(*) AS row_count
FROM products

UNION ALL

SELECT 'sales_pipeline' AS table_name, COUNT(*) AS row_count
FROM sales_pipeline

UNION ALL

SELECT 'sales_teams' AS table_name, COUNT(*) AS row_count
FROM sales_teams;


-- 2. Deal stage distribution
SELECT 
    deal_stage,
    COUNT(*) AS opportunity_count
FROM sales_pipeline
GROUP BY deal_stage
ORDER BY opportunity_count DESC;


-- 3. Product values in Sales Pipeline
SELECT 
    product,
    COUNT(*) AS opportunity_count
FROM sales_pipeline
GROUP BY product
ORDER BY opportunity_count DESC;


-- 4. Check for products in Sales Pipeline that do not match Products table
SELECT DISTINCT 
    sp.product
FROM sales_pipeline sp
LEFT JOIN products p
    ON sp.product = p.product
WHERE p.product IS NULL;


-- 5. Check for sales agents in Sales Pipeline that do not match Sales Teams table
SELECT DISTINCT 
    sp.sales_agent
FROM sales_pipeline sp
LEFT JOIN sales_teams st
    ON sp.sales_agent = st.sales_agent
WHERE st.sales_agent IS NULL;


-- 6. Check for accounts in Sales Pipeline that do not match Accounts table
SELECT DISTINCT 
    sp.account
FROM sales_pipeline sp
LEFT JOIN accounts a
    ON sp.account = a.account
WHERE a.account IS NULL;


-- 7. Check for blank account values in Sales Pipeline
SELECT 
    COUNT(*) AS blank_account_count
FROM sales_pipeline
WHERE account IS NULL
   OR TRIM(account) = '';


-- 8. Check for blank close dates by deal stage
SELECT 
    deal_stage,
    COUNT(*) AS blank_close_date_count
FROM sales_pipeline
WHERE close_date IS NULL
   OR TRIM(close_date) = ''
GROUP BY deal_stage
ORDER BY blank_close_date_count DESC;


-- 9. Check for blank close values by deal stage
SELECT 
    deal_stage,
    COUNT(*) AS blank_close_value_count
FROM sales_pipeline
WHERE close_value IS NULL
   OR TRIM(close_value) = ''
GROUP BY deal_stage
ORDER BY blank_close_value_count DESC;


-- 10. Date range check
SELECT 
    MIN(engage_date) AS earliest_engage_date,
    MAX(engage_date) AS latest_engage_date,
    MIN(close_date) AS earliest_close_date,
    MAX(close_date) AS latest_close_date
FROM sales_pipeline;


-- 11. Closed won revenue validation
SELECT 
    SUM(close_value) AS closed_won_revenue
FROM sales_pipeline
WHERE deal_stage = 'Won';


-- 12. Opportunity counts used in Power BI KPIs
SELECT 
    COUNT(*) AS total_opportunities,
    SUM(CASE WHEN deal_stage = 'Won' THEN 1 ELSE 0 END) AS won_opportunities,
    SUM(CASE WHEN deal_stage = 'Lost' THEN 1 ELSE 0 END) AS lost_opportunities,
    SUM(CASE WHEN deal_stage NOT IN ('Won', 'Lost') THEN 1 ELSE 0 END) AS open_opportunities
FROM sales_pipeline;


-- 13. Win rate validation
SELECT 
    ROUND(
        CAST(SUM(CASE WHEN deal_stage = 'Won' THEN 1 ELSE 0 END) AS REAL) /
        NULLIF(
            SUM(CASE WHEN deal_stage IN ('Won', 'Lost') THEN 1 ELSE 0 END),
            0
        ) * 100,
        2
    ) AS win_rate_percentage
FROM sales_pipeline;


-- 14. Closed won revenue by regional office
SELECT 
    st.regional_office,
    SUM(sp.close_value) AS closed_won_revenue
FROM sales_pipeline sp
LEFT JOIN sales_teams st
    ON sp.sales_agent = st.sales_agent
WHERE sp.deal_stage = 'Won'
GROUP BY st.regional_office
ORDER BY closed_won_revenue DESC;


-- 15. Closed won revenue by raw product name
SELECT 
    sp.product,
    SUM(sp.close_value) AS closed_won_revenue
FROM sales_pipeline sp
WHERE sp.deal_stage = 'Won'
GROUP BY sp.product
ORDER BY closed_won_revenue DESC;


-- 16. Closed won revenue by product with raw product name cleanup
SELECT 
    CASE 
        WHEN sp.product = 'GTXPro' THEN 'GTX Pro'
        ELSE sp.product
    END AS cleaned_product,
    SUM(sp.close_value) AS closed_won_revenue
FROM sales_pipeline sp
WHERE sp.deal_stage = 'Won'
GROUP BY 
    CASE 
        WHEN sp.product = 'GTXPro' THEN 'GTX Pro'
        ELSE sp.product
    END
ORDER BY closed_won_revenue DESC;