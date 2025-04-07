
---INSIGHT----
--  STEP 1: Data Preview and Initial Exploration
SELECT * FROM marketing_data;
SELECT * FROM most_Accepted;

--  STEP 2: Check Overall Response Rate
SELECT AVG(CAST(response AS INT)) * 100 AS overall_response_rate FROM marketing_data;

--  STEP 3: Response Rate by Customer Demographics
SELECT Education, Marital_Status,
       AVG(CAST(Response AS FLOAT)) * 100 AS response_rate
FROM marketing_data
GROUP BY Education, Marital_Status
ORDER BY response_rate DESC;

--  STEP 4: Rename Response Column for Clarity
EXEC sp_rename 'marketing_data.response', 'AcceptedCmp6', 'COLUMN';

--  STEP 5: Check Column Data Types
SELECT COLUMN_NAME, DATA_TYPE 
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'marketing_data' AND COLUMN_NAME = 'AcceptedCmp1';

--  STEP 6: Campaign Acceptance Summary
WITH sum_m AS (
  SELECT SUM(CASE WHEN AcceptedCmp1 = 1 THEN 1 ELSE 0 END) AS comp1,
         SUM(CASE WHEN AcceptedCmp2 = 1 THEN 1 ELSE 0 END) AS comp2,
         SUM(CASE WHEN AcceptedCmp3 = 1 THEN 1 ELSE 0 END) AS comp3,
         SUM(CASE WHEN AcceptedCmp4 = 1 THEN 1 ELSE 0 END) AS comp4,
         SUM(CASE WHEN AcceptedCmp5 = 1 THEN 1 ELSE 0 END) AS comp5,
         SUM(CASE WHEN AcceptedCmp6 = 1 THEN 1 ELSE 0 END) AS comp6
  FROM marketing_data
),
allrows AS (
  SELECT COUNT(*) AS cnt FROM marketing_data
),
percentage_comp AS (
  SELECT (comp1 * 1.0)/cnt AS comp1,
         (comp2 * 1.0)/cnt AS comp2,
         (comp3 * 1.0)/cnt AS comp3,
         (comp4 * 1.0)/cnt AS comp4,
         (comp5 * 1.0)/cnt AS comp5,
         (comp6 * 1.0)/cnt AS comp6
  FROM sum_m
  CROSS JOIN allrows
)
SELECT AVG(comp1 + comp2 + comp3 + comp4 + comp5 + comp6) AS avg_percent 
FROM percentage_comp;

--  STEP 7: Identify Customers Responding Only to Campaign 6
SELECT * FROM marketing_data
WHERE AcceptedCmp6 = 1 AND 
      AcceptedCmp1 = 0 AND AcceptedCmp2 = 0 AND AcceptedCmp3 = 0 AND AcceptedCmp4 = 0 AND AcceptedCmp5 = 0;

--  STEP 8: Create View - Customers Who Accepted Campaign 6 and At Least 2 Others
CREATE VIEW most_Accepted AS
WITH cte AS (
    SELECT id,
           CASE WHEN AcceptedCmp1 = 1 AND AcceptedCmp6 = 1 THEN id ELSE 0 END AS comp1,
           CASE WHEN AcceptedCmp2 = 1 AND AcceptedCmp6 = 1 THEN id ELSE 0 END AS comp2,
           CASE WHEN AcceptedCmp3 = 1 AND AcceptedCmp6 = 1 THEN id ELSE 0 END AS comp3,
           CASE WHEN AcceptedCmp4 = 1 AND AcceptedCmp6 = 1 THEN id ELSE 0 END AS comp4,
           CASE WHEN AcceptedCmp5 = 1 AND AcceptedCmp6 = 1 THEN id ELSE 0 END AS comp5
    FROM marketing_data
),
accepted AS (
  SELECT * FROM cte 
  WHERE comp1 > 0 OR comp2 > 0 OR comp3 > 0 OR comp4 > 0 OR comp5 > 0
),
figure AS (
  SELECT id, comp, figure 
  FROM accepted
  UNPIVOT (figure FOR comp IN (comp1, comp2, comp3, comp4, comp5)) AS unpvt
),
figure2 AS (
  SELECT id, COUNT(*) AS figure
  FROM figure
  WHERE figure > 0
  GROUP BY id
)
SELECT id FROM figure2 WHERE figure >= 2;

--  STEP 9: Calculate % of Customers Who Accepted ≥2 Campaigns + Campaign 6
SELECT COUNT(id) * 100.0 / 
      (SELECT COUNT(id) FROM marketing_data WHERE AcceptedCmp6 = 1) 
FROM most_Accepted;

--  STEP 10: Test Group - Limited Campaign Engagement
SELECT id, SUM(Income), Education, Marital_Status, Country
FROM marketing_data
WHERE AcceptedCmp6 = 1 AND
      (AcceptedCmp1 + AcceptedCmp2 + AcceptedCmp3 + AcceptedCmp4 + AcceptedCmp5 + AcceptedCmp6) <= 2
GROUP BY id, Education, Marital_Status, Country;

--  STEP 11: Engagement Within Last 30 Days
SELECT COUNT(*) * 100.0 / (SELECT COUNT(*) FROM most_Accepted)
FROM marketing_data
WHERE Recency <= 30 AND ID IN (SELECT id FROM most_Accepted);

--  STEP 12: Purchase Behavior of Loyal Customers
SELECT ma.id, Education, Marital_Status,
       SUM(Income) AS total_income,
       SUM(NumDealsPurchases) AS total_discount,
       SUM(NumWebPurchases) AS total_webpurchase,
       SUM(NumCatalogPurchases) AS total_catalog,
       SUM(NumStorePurchases) AS total_storepurchase,
       SUM(NumWebVisitsMonth) AS total_webvisit
FROM most_Accepted ma
LEFT JOIN marketing_data md ON ma.id = md.id
GROUP BY ma.id, Education, Marital_Status
ORDER BY total_income DESC;

--  STEP 13: RFM Segmentation - Web Shoppers
CREATE VIEW RFM_WEB AS
WITH highest_income AS (
  SELECT * FROM marketing_data
  WHERE Income > (SELECT AVG(Income) FROM marketing_data)
),
recency AS (
  SELECT * FROM marketing_data WHERE Recency <= 30
),
frequency_webvisit AS (
  SELECT * FROM marketing_data
  WHERE NumWebVisitsMonth > (SELECT AVG(NumWebVisitsMonth) FROM marketing_data)
),
frequency_storepurchase AS (
  SELECT * FROM marketing_data
  WHERE NumStorePurchases > (SELECT AVG(NumStorePurchases) FROM marketing_data)
)
SELECT i.id
FROM highest_income i
JOIN recency r ON i.id = r.id
JOIN frequency_webvisit f ON r.id = f.id
JOIN frequency_storepurchase s ON f.id = s.id;

--  STEP 14: RFM Segmentation - In-Store Shoppers
CREATE VIEW RFM_store AS
WITH highest_income AS (
  SELECT * FROM marketing_data
  WHERE Income < (SELECT AVG(Income) FROM marketing_data)
),
recency AS (
  SELECT * FROM marketing_data WHERE Recency >= 30
),
frequency_webvisit AS (
  SELECT * FROM marketing_data
  WHERE NumWebVisitsMonth < (SELECT AVG(NumWebVisitsMonth) FROM marketing_data)
),
frequency_storepurchase AS (
  SELECT * FROM marketing_data
  WHERE NumStorePurchases < (SELECT AVG(NumStorePurchases) FROM marketing_data)
)
SELECT i.id
FROM highest_income i
JOIN recency r ON i.id = r.id
JOIN frequency_webvisit f ON r.id = f.id
JOIN frequency_storepurchase s ON f.id = s.id;

--  STEP 15: Compare Customer Segments
SELECT * FROM RFM_WEB Rw
LEFT JOIN marketing_data md ON Rw.id = md.ID;

SELECT * FROM RFM_store Rw
LEFT JOIN marketing_data md ON Rw.id = md.ID;

--  STEP 16: Identify Non-RFM Customers
SELECT * FROM marketing_data
WHERE ID NOT IN (SELECT ID FROM RFM_WEB)
AND ID NOT IN (SELECT ID FROM RFM_store);

--  STEP 17: Recency Ranking
SELECT ID, MIN(Recency) AS min_recency
FROM marketing_data
GROUP BY ID
ORDER BY min_recency DESC;

-----MAIN QUERY TO SOLVE THE PROBLEM

create view main_query as 
select * from main_query
create view new_targets as 

-- Step 1: Aggregating RFM Data
WITH AggregatedData AS (
    SELECT 
        ID,
        MIN(Recency) AS Recency,
        SUM(NumStorePurchases + NumWebPurchases + NumCatalogPurchases) AS Frequency,
        SUM(MntWines + MntMeatProducts + MntFishProducts + MntSweetProducts + MntGoldProds) AS Monetary
    FROM marketing_data
    GROUP BY ID
), 

-- Step 2: Calculating Percentile Values for Binning
percentile_values AS (
    SELECT 
        DISTINCT 
        PERCENTILE_CONT(0.2) WITHIN GROUP (ORDER BY Monetary) OVER () AS p20_m,
        PERCENTILE_CONT(0.4) WITHIN GROUP (ORDER BY Monetary) OVER () AS p40_m,
        PERCENTILE_CONT(0.6) WITHIN GROUP (ORDER BY Monetary) OVER () AS p60_m,
        PERCENTILE_CONT(0.8) WITHIN GROUP (ORDER BY Monetary) OVER () AS p80_m,
        PERCENTILE_CONT(0.2) WITHIN GROUP (ORDER BY Frequency) OVER () AS p20_f,
        PERCENTILE_CONT(0.4) WITHIN GROUP (ORDER BY Frequency) OVER () AS p40_f,
        PERCENTILE_CONT(0.6) WITHIN GROUP (ORDER BY Frequency) OVER () AS p60_f,
        PERCENTILE_CONT(0.8) WITHIN GROUP (ORDER BY Frequency) OVER () AS p80_f,
        PERCENTILE_CONT(0.2) WITHIN GROUP (ORDER BY Recency) OVER () AS p20_r,
        PERCENTILE_CONT(0.4) WITHIN GROUP (ORDER BY Recency) OVER () AS p40_r,
        PERCENTILE_CONT(0.6) WITHIN GROUP (ORDER BY Recency) OVER () AS p60_r,
        PERCENTILE_CONT(0.8) WITHIN GROUP (ORDER BY Recency) OVER () AS p80_r
    FROM AggregatedData
),

-- Step 3: Segmenting Customers Based on RFM Values
rfm_segments AS (
    SELECT 
        a.ID, 
        a.Recency, 
        a.Frequency, 
        a.Monetary,
        CASE 
            WHEN a.Monetary <= p.p20_m THEN 1
            WHEN a.Monetary <= p.p40_m THEN 2
            WHEN a.Monetary <= p.p60_m THEN 3
            WHEN a.Monetary <= p.p80_m THEN 4
            ELSE 5 
        END AS Monetary_Segment,
        CASE 
            WHEN a.Frequency <= p.p20_f THEN 1
            WHEN a.Frequency <= p.p40_f THEN 2
            WHEN a.Frequency <= p.p60_f THEN 3
            WHEN a.Frequency <= p.p80_f THEN 4
            ELSE 5
        END AS Frequency_Segment,
        CASE 
            WHEN a.Recency <= p.p20_r THEN 5
            WHEN a.Recency <= p.p40_r THEN 4
            WHEN a.Recency <= p.p60_r THEN 3
            WHEN a.Recency <= p.p80_r THEN 2
            ELSE 1
        END AS Recency_Segment
    FROM AggregatedData a
    CROSS JOIN percentile_values p
),

-- Step 4: Calculating RFM Scores
score AS (
    SELECT 
        id,
        Monetary_Segment + Frequency_Segment + Recency_Segment AS score 
    FROM rfm_segments
),

-- Step 5: Classifying Customer Segments Based on RFM Scores
customer_segments AS (
    SELECT 
        id,
        CASE  
            WHEN score >= 14 THEN 'High value customers'
            WHEN score BETWEEN 10 AND 13 THEN 'Loyal customers'
            ELSE 'Average customers' 
        END AS customer_segment
    FROM score
),

-- Step 6: Identifying Loyal and High-Value Customers Who Accepted Campaign 6
not_average_customers AS (
    SELECT c.id 
    FROM customer_segments c
    JOIN marketing_data m ON c.ID = m.id
    WHERE customer_segment IN ('Loyal customers', 'High value customers')
    AND AcceptedCmp6 = 1
),

-- Step 7: Identifying Customers Who Accepted Campaign 6 and More
accepted_more AS (
    SELECT a.id 
    FROM not_average_customers a
    JOIN most_Accepted m ON a.id = m.id
),

-- Step 8: Identifying Customers Who Accepted Only Campaign 6
accepted_cmp6 AS (
    SELECT id 
    FROM not_average_customers
    WHERE id NOT IN (SELECT id FROM most_Accepted)
),

-- Step 9: Identifying Customers with High Purchase in the Last 30 Days
highest_purchase AS (
    SELECT 
        id, 
        SUM(MntWines + MntMeatProducts + MntFishProducts + MntSweetProducts + MntGoldProds) AS Monetary
    FROM marketing_data 
    WHERE Recency < 30
    GROUP BY id
    HAVING SUM(MntWines + MntMeatProducts + MntFishProducts + MntSweetProducts + MntGoldProds) > 2000
),

-- Step 10: Identifying Customers with Income Greater Than 90,000
highest_income AS (
    SELECT 
        id, 
        SUM(Income) AS Income 
    FROM marketing_data
    GROUP BY id
    HAVING SUM(Income) > 90000
),

-- Step 11: Combining High Purchase and High Income Customers
union_id AS (
    SELECT id FROM highest_purchase 
    UNION 
    SELECT id FROM highest_income
),

-- Step 12: Identifying New Customers to Add to the Targeted Campaign
added_customers AS (
    SELECT id 
    FROM union_id 
    WHERE id NOT IN (
        SELECT id FROM marketing_data WHERE AcceptedCmp6 = 1
    )
)

-- Step 13: Final Result: List of Customers to Be Added to the Targeted Campaign
SELECT id
FROM added_customers 
union
select id from marketing_data
where AcceptedCmp6=1

select * from new_targets

select sum(cast( AcceptedCmp1 as int)) as AcceptedCmp1  ,sum(cast( AcceptedCmp2 as int)) as AcceptedCmp2 ,
sum(cast( AcceptedCmp3 as int)) as AcceptedCmp3 ,sum(cast( AcceptedCmp4 as int)) as AcceptedCmp4 ,
sum(cast( AcceptedCmp5 as int)) as AcceptedCmp5,sum(cast( AcceptedCmp6 as int))as AcceptedCmp6 from marketing_data








