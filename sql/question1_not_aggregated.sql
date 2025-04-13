CREATE OR REPLACE VIEW `kpler.question1_advanced`  AS (
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
)

SELECT * FROM mapped_arr_probability


)