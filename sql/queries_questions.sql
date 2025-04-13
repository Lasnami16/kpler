--Question 1:  Calculate active ARR by month and by team for 2023 and 2024. You can forecast the part that is not yet closed. 
CREATE OR REPLACE VIEW `kpler.question1`  AS (
--Generating a view for all probabilities combination
WITH forecast_probs AS (
  SELECT *
  FROM UNNEST([ 
    STRUCT('Contact' AS stage, 'New Business' AS prod_type, 0.1 AS probability),
    ('Contact', 'Crosssell', 0.2),
    ('Contact', 'Upsell', 0.4),
    ('Contact', 'Renew', 0.7),
    ('Contact', 'Downsell', 0.7),
    
    ('Demo', 'New Business', 0.2),
    ('Demo', 'Crosssell', 0.3),
    ('Demo', 'Upsell', 0.5),
    ('Demo', 'Renew', 0.8),
    ('Demo', 'Downsell', 0.8),
    
    ('Trial', 'New Business', 0.25),
    ('Trial', 'Crosssell', 0.4),
    ('Trial', 'Upsell', 0.55),
    ('Trial', 'Renew', 0.85),
    ('Trial', 'Downsell', 0.85),
    
    ('Nego', 'New Business', 0.5),
    ('Nego', 'Crosssell', 0.6),
    ('Nego', 'Upsell', 0.7)
  ])
),
--remove duplicates row
deals_not_duplicates AS (
    SELECT 
        DISTINCT * 
    FROM 
        `kpler.deals` 

),
-- Generate the series of months between the close_date and Renewal Date for each opportunity
month_series AS (
    SELECT
        opportunity_id,
        stage,
        prod_type,
        team,
        ARR_USD,
        close_date,
        renewal_date,
        -- Generate months between close_date and renewal_date
        ARRAY(
            SELECT AS STRUCT
                DATE_TRUNC(DATE_ADD(close_date, INTERVAL x MONTH), MONTH) AS active_month
            FROM UNNEST(GENERATE_ARRAY(0, DATE_DIFF(renewal_date, close_date, MONTH))) AS x
        ) AS active_months
    FROM 
        deals_not_duplicates   
),

-- UNNEST the months 
active_arr AS (

    SELECT
        opportunity_id,
        stage,
        prod_type,
        team,
        active_month.active_month AS active_month, 
        ARR_USD
        
    FROM 
        month_series CROSS JOIN UNNEST(active_months) AS active_month
    WHERE 
        active_month.active_month BETWEEN '2023-01-01' AND '2024-12-31'
),
--Mapping the arr with the corresponding prob from the created view
mapped_arr_probability AS (
    SELECT 
        a.*,
        CASE 
            WHEN a.stage LIKE 'Closed Won' THEN 1
            WHEN a.stage LIKE 'Closed Lost' THEN 0
            ELSE f.probability
        END AS probability
    FROM  
        active_arr a 
    LEFT JOIN forecast_probs f 
        ON a.prod_type = f.prod_type 
        AND a.stage = f.stage
),

calculated_forecast_arr AS (
    SELECT 
        opportunity_id,
        stage,
        prod_type,
        team,
        active_month, 
        ARR_USD * probability AS forecast_arr
    FROM 
       mapped_arr_probability

)


-- Sum ARR by team, year, and month
SELECT
    team,
    EXTRACT(YEAR FROM active_month) AS year, 
    EXTRACT(MONTH FROM active_month) AS month, 
    ROUND(SUM(forecast_arr),2) AS forecast_arr
FROM calculated_forecast_arr
GROUP BY team, year, month
ORDER BY team, year, month

)



--************************************************ Question 2************************************************
--  Which combination of Service and Commodity Family added the most and which the least ARR in 2023?
Create OR REPLACE VIEW `kpler.question2`  AS(

--remove duplicates row
WITH deals_not_duplicates AS (
    SELECT 
        DISTINCT * 
    FROM 
        `kpler.deals` 

),
 combination AS (
    SELECT
        UPPER(TRIM(service)) AS service, 
        UPPER(TRIM(commodity_family)) AS commodity_family,
        ROUND(SUM(ARR_USD), 2) AS total_arr
    FROM
        deals_not_duplicates
    WHERE
        EXTRACT(YEAR FROM close_date) = 2023
    GROUP BY service, commodity_family
),

-- Most ARR combination
most_added AS (
SELECT
    'Most' AS added,
    service, 
    commodity_family,
    total_arr
FROM combination
ORDER BY total_arr DESC
LIMIT 1

),
-- Least ARR combination
least_added AS (
SELECT
    'Least' AS added,
    service, 
    commodity_family,
    total_arr
FROM combination
ORDER BY total_arr ASC
LIMIT 1

)

SELECT * FROM most_added 
UNION ALL
SELECT * FROM least_added 

)


--************************************************ Question 3************************************************

CREATE OR REPLACE VIEW `kpler.question3`  AS (
WITH forecast_probs AS (
  SELECT *
  FROM UNNEST([ 
    STRUCT('Contact' AS stage, 'New Business' AS prod_type, 0.1 AS probability),
    ('Contact', 'Crosssell', 0.2),
    ('Contact', 'Upsell', 0.4),
    ('Contact', 'Renew', 0.7),
    ('Contact', 'Downsell', 0.7),
    
    ('Demo', 'New Business', 0.2),
    ('Demo', 'Crosssell', 0.3),
    ('Demo', 'Upsell', 0.5),
    ('Demo', 'Renew', 0.8),
    ('Demo', 'Downsell', 0.8),
    
    ('Trial', 'New Business', 0.25),
    ('Trial', 'Crosssell', 0.4),
    ('Trial', 'Upsell', 0.55),
    ('Trial', 'Renew', 0.85),
    ('Trial', 'Downsell', 0.85),
    
    ('Nego', 'New Business', 0.5),
    ('Nego', 'Crosssell', 0.6),
    ('Nego', 'Upsell', 0.7)
  ])
),
--remove duplicates row
deals_not_duplicates AS (
    SELECT 
        DISTINCT * 
    FROM 
        `kpler.deals` 

),
-- Generate the series of months between the close_date and Renewal Date for each opportunity
month_series AS (
    SELECT
        account_id,
        opportunity_id,
        stage,
        prod_type,
        team,
        ARR_USD,
        close_date,
        renewal_date,
        -- Generate months between close_date and renewal_date
        ARRAY(
            SELECT AS STRUCT
                DATE_TRUNC(DATE_ADD(close_date, INTERVAL x MONTH), MONTH) AS active_month
            FROM UNNEST(GENERATE_ARRAY(0, DATE_DIFF(renewal_date, close_date, MONTH))) AS x
        ) AS active_months
    FROM 
        deals_not_duplicates   
),

-- UNNEST the months 
active_arr AS (

    SELECT
        account_id,
        opportunity_id,
        stage,
        prod_type,
        team,
        active_month.active_month AS active_month, 
        ARR_USD
        
    FROM 
        month_series CROSS JOIN UNNEST(active_months) AS active_month
    WHERE active_month.active_month BETWEEN '2023-01-01' AND '2024-12-31'
    -- if filtring the last tow years from the current year
    --WHERE active_month.active_month BETWEEN 
     -- DATE_FROM_UNIX_DATE(UNIX_DATE(DATE_SUB(DATE_TRUNC(CURRENT_DATE(), YEAR), INTERVAL 2 YEAR)))
  --AND  DATE_FROM_UNIX_DATE(UNIX_DATE(DATE_SUB(DATE_TRUNC(CURRENT_DATE(), YEAR), INTERVAL 1 DAY)))
),
--Mapping  arr with the corresponding prob from the created view
mapped_arr_probability AS (
    SELECT 
        a.*,
        EXTRACT(YEAR FROM active_month) AS year,
        EXTRACT(MONTH FROM active_month) AS month,
        CASE 
            WHEN a.stage LIKE 'Closed Won' THEN 1
            WHEN a.stage LIKE 'Closed Lost' THEN 0
            ELSE f.probability
        END AS probability
    FROM  
        active_arr a 
    LEFT JOIN forecast_probs f 
        ON a.prod_type = f.prod_type 
        AND a.stage = f.stage
),

account_counts_ARR AS (
    SELECT 
        year,
        month,
        count( DISTINCT account_id) as nb_clients,
        SUM(ARR_USD * probability) AS total_ARR
    FROM 
        mapped_arr_probability
    GROUP BY 
        year,month

)

SELECT 
    year,
    month,
    DATE(CONCAT(CAST(year AS STRING), '-', LPAD(CAST(month AS STRING), 2, '0'), '-01')) AS generated_date,
    safe_divide(total_ARR, nb_clients) AS avg_arr_per_client
FROM account_counts_ARR

)


--************************************************ Question 4************************************************
CREATE OR REPLACE VIEW `kpler.question4`  AS (
WITH forecast_probs AS (
  SELECT *
  FROM UNNEST([ 
    STRUCT('Contact' AS stage, 'New Business' AS prod_type, 0.1 AS probability),
    ('Contact', 'Crosssell', 0.2),
    ('Contact', 'Upsell', 0.4),
    ('Contact', 'Renew', 0.7),
    ('Contact', 'Downsell', 0.7),
    
    ('Demo', 'New Business', 0.2),
    ('Demo', 'Crosssell', 0.3),
    ('Demo', 'Upsell', 0.5),
    ('Demo', 'Renew', 0.8),
    ('Demo', 'Downsell', 0.8),
    
    ('Trial', 'New Business', 0.25),
    ('Trial', 'Crosssell', 0.4),
    ('Trial', 'Upsell', 0.55),
    ('Trial', 'Renew', 0.85),
    ('Trial', 'Downsell', 0.85),
    
    ('Nego', 'New Business', 0.5),
    ('Nego', 'Crosssell', 0.6),
    ('Nego', 'Upsell', 0.7)
  ])
),
--remove duplicates row
deals_not_duplicates AS (
    SELECT 
        DISTINCT * 
    FROM 
        `kpler.deals` 

),
-- Generate the series of months between the close_date and Renewal Date for each opportunity
month_series AS (
    SELECT
        account_id,
        opportunity_id,
        stage,
        prod_type,
        team,
        ARR_USD,
        close_date,
        renewal_date,
        -- Generate months between close_date and renewal_date
        ARRAY(
            SELECT AS STRUCT
                DATE_TRUNC(DATE_ADD(close_date, INTERVAL x MONTH), MONTH) AS active_month
            FROM UNNEST(GENERATE_ARRAY(0, DATE_DIFF(renewal_date, close_date, MONTH))) AS x
        ) AS active_months
    FROM 
        deals_not_duplicates   
),

-- UNNEST the months 
active_arr AS (

    SELECT
        account_id,
        opportunity_id,
        stage,
        prod_type,
        team,
        active_month.active_month AS active_month, 
        ARR_USD
    FROM 
        month_series CROSS JOIN UNNEST(active_months) AS active_month
    WHERE active_month.active_month BETWEEN '2023-01-01' AND '2024-12-31'
    -- if filtring the last tow years from the current year
    --WHERE active_month.active_month BETWEEN 
     -- DATE_FROM_UNIX_DATE(UNIX_DATE(DATE_SUB(DATE_TRUNC(CURRENT_DATE(), YEAR), INTERVAL 2 YEAR)))
  --AND  DATE_FROM_UNIX_DATE(UNIX_DATE(DATE_SUB(DATE_TRUNC(CURRENT_DATE(), YEAR), INTERVAL 1 DAY)))
),
--Mapping  arr with the corresponding prob from the created view
mapped_arr_probability AS (
    SELECT 
        a.*,
        EXTRACT(YEAR FROM active_month) AS year,
        EXTRACT(MONTH FROM active_month) AS month,
        CASE 
            WHEN a.stage LIKE 'Closed Won' THEN 1
            WHEN a.stage LIKE 'Closed Lost' THEN 0
            ELSE f.probability
        END AS probability
    FROM  
        active_arr a 
    LEFT JOIN forecast_probs f 
        ON a.prod_type = f.prod_type 
        AND a.stage = f.stage
),

account_counts_ARR AS (
    SELECT 
        account_id,
        year,
        month,
        SUM(ARR_USD * probability) AS forecasted_ARR
    FROM 
        mapped_arr_probability
    GROUP BY 
        account_id,year,month

)

SELECT 
    account_id,
    DATE(CONCAT(CAST(year AS STRING), '-', LPAD(CAST(month AS STRING), 2, '0'), '-01')) AS generated_date,
    year,
    month,
    forecasted_ARR
FROM account_counts_ARR

)

--************************************************ Question 5************************************************
CREATE OR REPLACE VIEW `kpler.question5`  AS (
WITH forecast_probs AS (
  SELECT *
  FROM UNNEST([ 
    STRUCT('Contact' AS stage, 'New Business' AS prod_type, 0.1 AS probability),
    ('Contact', 'Crosssell', 0.2),
    ('Contact', 'Upsell', 0.4),
    ('Contact', 'Renew', 0.7),
    ('Contact', 'Downsell', 0.7),
    
    ('Demo', 'New Business', 0.2),
    ('Demo', 'Crosssell', 0.3),
    ('Demo', 'Upsell', 0.5),
    ('Demo', 'Renew', 0.8),
    ('Demo', 'Downsell', 0.8),
    
    ('Trial', 'New Business', 0.25),
    ('Trial', 'Crosssell', 0.4),
    ('Trial', 'Upsell', 0.55),
    ('Trial', 'Renew', 0.85),
    ('Trial', 'Downsell', 0.85),
    
    ('Nego', 'New Business', 0.5),
    ('Nego', 'Crosssell', 0.6),
    ('Nego', 'Upsell', 0.7)
  ])
),
--remove duplicates row
deals_not_duplicates AS (
    SELECT 
        DISTINCT * 
    FROM 
        `kpler.deals` 

),
-- Generate the series of months between the close_date and Renewal Date for each opportunity
month_series AS (
    SELECT
        account_id,
        opportunity_id,
        stage,
        prod_type,
        team,
        ARR_USD,
        delta_ARR_USD,
        close_date,
        renewal_date,
        -- Generate months between close_date and renewal_date
        ARRAY(
            SELECT AS STRUCT
                DATE_TRUNC(DATE_ADD(close_date, INTERVAL x MONTH), MONTH) AS active_month
            FROM UNNEST(GENERATE_ARRAY(0, DATE_DIFF(renewal_date, close_date, MONTH))) AS x
        ) AS active_months
    FROM 
        deals_not_duplicates   
),

-- UNNEST the months 
active_arr AS (

    SELECT
        account_id,
        opportunity_id,
        stage,
        prod_type,
        team,
        active_month.active_month AS active_month, 
        ARR_USD,
        delta_ARR_USD
    FROM 
        month_series CROSS JOIN UNNEST(active_months) AS active_month
    WHERE active_month.active_month BETWEEN '2023-01-01' AND '2024-12-31'
),

--Mapping  arr with the corresponding prob from the created view
mapped_arr_probability AS (
    SELECT 
        a.stage,
        a.prod_type,
        a.team,
        active_month,
        delta_ARR_USD,
        CASE 
            WHEN a.stage LIKE 'Closed Won' THEN 1
            WHEN a.stage LIKE 'Closed Lost' THEN 0
            ELSE f.probability
        END AS probability
    FROM  
        active_arr a 
    LEFT JOIN forecast_probs f 
        ON a.prod_type = f.prod_type 
        AND a.stage = f.stage
)
select * from mapped_arr_probability


)