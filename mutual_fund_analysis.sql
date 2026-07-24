/* ============================================================
   MUTUAL FUND DATA ANALYSIS - SQL QUERIES
   Author: Shrusti Math
   Dataset: 1,000+ mutual funds across 15+ AMCs

   NOTE: Adjust table/column names below to match your actual
   dataset before running. Assumed schema:

   mutual_funds (
       fund_name      VARCHAR,
       amc            VARCHAR,   -- Asset Management Company
       category       VARCHAR,   -- e.g. Equity, Debt, Hybrid
       risk_level     VARCHAR,   -- e.g. Low, Moderate, High
       aum            DECIMAL,   -- Assets Under Management (₹)
       cagr           DECIMAL,   -- Compound Annual Growth Rate (%)
       return_1m      DECIMAL,
       return_1y      DECIMAL,
       return_3y      DECIMAL
   )
   ============================================================ */


-- 1. TOP-PERFORMING FUNDS BY CAGR AND RETURNS
-- Identifies the highest-performing funds overall
SELECT
    fund_name,
    amc,
    category,
    cagr,
    return_1y,
    return_3y
FROM mutual_funds
ORDER BY cagr DESC
LIMIT 10;


-- 2. RISK-RETURN ANALYSIS USING A COMPOSITE SCORE
-- Ranks funds by a simple composite of return vs risk exposure
SELECT
    fund_name,
    amc,
    risk_level,
    return_1y,
    return_3y,
    ROUND(
        (return_1y * 0.4 + return_3y * 0.6) -
        CASE risk_level
            WHEN 'High' THEN 5
            WHEN 'Moderate' THEN 2
            ELSE 0
        END,
    2) AS composite_score
FROM mutual_funds
ORDER BY composite_score DESC;


-- 3. FUND COMPARISON ACROSS RISK CATEGORIES
-- Average return and AUM by risk level
SELECT
    risk_level,
    COUNT(*)            AS fund_count,
    ROUND(AVG(return_1y), 2) AS avg_1y_return,
    ROUND(AVG(return_3y), 2) AS avg_3y_return,
    ROUND(SUM(aum), 2)  AS total_aum
FROM mutual_funds
GROUP BY risk_level
ORDER BY avg_3y_return DESC;


-- 4. AMC-WISE PERFORMANCE COMPARISON
-- Which AMCs consistently perform better across their fund lineup
SELECT
    amc,
    COUNT(*)                  AS num_funds,
    ROUND(AVG(cagr), 2)       AS avg_cagr,
    ROUND(SUM(aum), 2)        AS total_aum_managed
FROM mutual_funds
GROUP BY amc
ORDER BY avg_cagr DESC;


-- 5. CATEGORY-WISE AUM DISTRIBUTION
-- Which fund categories dominate total assets under management
SELECT
    category,
    COUNT(*)                       AS fund_count,
    ROUND(SUM(aum), 2)             AS category_aum,
    ROUND(SUM(aum) * 100.0 / (SELECT SUM(aum) FROM mutual_funds), 2) AS pct_of_total_aum
FROM mutual_funds
GROUP BY category
ORDER BY category_aum DESC;


-- 6. ANOMALY DETECTION
-- Flags funds with large AUM but weak/negative recent returns --
-- a mismatch worth investigating rather than a simple ranking
SELECT
    fund_name,
    amc,
    category,
    aum,
    return_1y
FROM mutual_funds
WHERE aum > (SELECT AVG(aum) FROM mutual_funds)
  AND return_1y < 0
ORDER BY aum DESC;


-- 7. RISK-ADJUSTED OUTLIERS
-- Low-risk funds underperforming their peers, and high-risk funds
-- that failed to deliver the return premium investors are paying for
SELECT
    fund_name,
    risk_level,
    return_3y,
    (SELECT AVG(return_3y) FROM mutual_funds m2 WHERE m2.risk_level = m1.risk_level) AS peer_avg_3y_return
FROM mutual_funds m1
WHERE return_3y < (SELECT AVG(return_3y) FROM mutual_funds m2 WHERE m2.risk_level = m1.risk_level) - 5
ORDER BY risk_level, return_3y ASC;
