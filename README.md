# marketing-Overview

## Introduction

Marketers today must be sharp and strategic in order to reach their target audience in a digital and competitive environment. Currently, our campaign response rates are languishing below 10%, which means wasted marketing budgets, low customer engagement, and revenue opportunities lost. This situation represents a challenge as well as a huge opportunity. If we can take on this challenge in an anticipatory manner, we can transform it into an opportunity to generate meaningful business growth. Our overall plan is to improve performance through data driven campaign management. Our immediate goal is to increase response rates by at least 15%. 

## Initial analysis identified important customer segments showing promise
•	26.04% of customers placed an order in the past 30 days 

•	 1170 customers had above-average website visitation rates per month

•	970 customers exhibited a high level of in-store purchasing 

•	 334 accepted campaign 6

•	233 customers high-value & loyal customers (indicating we can add an estimated 28 customers with targeted campaigns) By optimizing targeting approaches, we will generate higher campaign performance and ROI. 

---

## Current Challenges

1.Low Engagement (less than 10%)  :  Our campaigns are not resonating with the appropriate audience.

2.Ineffective Targeting :No more broad based outreach that incurs wasted marketing spend.

3.Low Customer Engagement :Lack of personalization translates to lower overall conversions.

4.Lost High Value Opportunities :Underutilization of key segments (high-consuming, frequent buyers) is commonplace.

## Insights

• Customers accepted campaign 6 more than any other campaign

• 724 Customers made order in the last 30days 

• Average income 52,247 

• 1084 customer has income above average 

•  1170 customers visited the web in the last 30days

• 970 customers visited the store in the last 30days

• 87 customers accepted campaign 6 and more

---
### Data and some SQL Queries used: Dataset Cleaning & Preparation
this queries were used to get my analysis
````sql
---checking for income less than the average income
with highest_income as (
select * from marketing_data
where income <
(select avg(income)  from marketing_data)),--------average income

----checking for recency  for more than 30days 
recency as(
select * from marketing_data
where recency  >= 30),

---checking RFM
frequency_webvisit as (--------frequency of webvisited
select * from marketing_data
where NumWebVisitsMonth <--- less than the average
(select avg(numwebvisitsmonth) from marketing_data )),

frequency_storepurhase as (--------------frequency of storepurchase
select * from marketing_data
where NumStorePurchases <(---less than average
select avg(NumStorePurchases) from marketing_data))

select i.id from highest_income i
join recency r on i.id = r.id
join frequency_webvisit f on r.id = f.id
join frequency_storepurhase s on f.id =s.id

````
```sql
WITH AggregatedData AS (
    SELECT 
        ID,
        MIN(Recency) AS Recency,
        SUM(NumStorePurchases + NumWebPurchases + NumCatalogPurchases) AS Frequency,
        SUM(MntWines + MntMeatProducts + MntFishProducts + MntSweetProducts + MntGoldProds) AS Monetary
    FROM marketing_data
    GROUP BY ID----checking for RFM data
),

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
       FROM AggregatedData),-------grouping them in different bins
	   
rfm_segments AS (
SELECT a.ID, a.Recency, a.Frequency, a.Monetary,
CASE WHEN a.Monetary <= p.p20_m THEN 1
     WHEN a.Monetary <= p.p40_m THEN 2
     WHEN a.Monetary <= p.p60_m THEN 3
     WHEN a.Monetary <= p.p80_m THEN 4
     ELSE 5 END AS Monetary_Segment,
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
    CROSS JOIN percentile_values p),---Segmenting them base on RFM
score as (
	select id,Monetary_Segment+Frequency_Segment+Recency_Segment as score 
	from rfm_segments),

customer_segments as (
select id,
case  when score >=14 then 'High value customers'
      when score between 10 and 13 then 'Loyal customers'
	  else 'Average customers' end as customer_segment
from score),----segmenting customers base on values 

not_average_customers as (
select c.id from customer_segments c
join marketing_data m on c.ID= m.id
where customer_segment in ('loyal customers','high value customers')
 and AcceptedCmp6= 1),-----number of loyal and high value customers

accepted_more as (
select a.id from not_average_customers a
join most_Accepted m on a.id= m.id),---customers that accepted campaign 6 and more 

accepted_cmp6 as (
select id from not_average_customers
where id not in
(select id from most_Accepted)),---customres that didnt accept campaing 6 and more


 highest_purchase as (
select id,SUM(MntWines + MntMeatProducts + MntFishProducts + MntSweetProducts + MntGoldProds) AS Monetary
    FROM marketing_data 
	where recency <30----getting new customers to target base on highest purchase
	group by id 
	having SUM(MntWines + MntMeatProducts + MntFishProducts + MntSweetProducts + MntGoldProds)>2000
	),
highest_income as (
	select id,sum(income) as income from marketing_data
	group by id
	having  sum(income) >90000----getting new customers to target base on income above 90,00
	),
 union_id as (
select id from highest_purchase 
union 
select id from highest_income)---combining both highest purchase and highest income together 

--added_customers as (
select id from union_id 
where id not in (select id from marketing_data
where AcceptedCmp6=1)
````





---

### 📊 **Campaign Response Strategy Using RFM Analysis**

To drive at least a 15% increase in acceptance for the upcoming marketing campaign, I conducted an RFM (Recency, Frequency, and Monetary) analysis. This method allowed me to segment the customer base into four key categories:

- **Priority Customers**-– 87 customers who accepted Campaign 6 and at least one other campaign
  
- **High Value Customers**
  
- **Loyal Customers**
  
- **Average Customers**
  
From this segmentation, 334 customers who responded to Campaign 6 were identified. These individuals are likely to engage again in the upcoming campaign based on prior behavior.

To boost the projected response rate, I also identified additional high-potential customers by applying the following criteria:
- **Recent purchase within the last 30 days**
- **Income greater than $90,000**
  
This led to the identification of 28 more customers, increasing the total pool to 362 customers (334 + 28). The inclusion of these potential responders is expected to result in a projected response rate of 16.2%, surpassing the initial goal of 15%.

---

### **Dashboard**
![market-1](https://github.com/user-attachments/assets/73a1d880-bfd0-41f4-8f6a-ddf4c17a02b5)

---



### **Recommendations**

1.**Prioritize Priority Customers in Campaign Messaging**

Focus personalized and value-driven messages on the 87 Priority Customers, as they have demonstrated consistent engagement across multiple campaigns.

2.**Adopt the Expanded Targeting Strategy**

Target the full pool of 362 customers, combining past responders and new high-potential prospects, to optimize campaign reach and conversion.

3.**Monitor Campaign Performance in Real-Time**

Use campaign dashboards to track response rates, customer interactions, and conversion metrics to validate the segmentation approach.

4.**Regularly Refresh RFM Segmentation**

Update the RFM model periodically to reflect evolving customer behavior and improve predictive accuracy.


---

###  **Conclusion**
RFM analysis with behavior has successfully segmented the customer base for a more tailored approach to campaign strategy optimization. The segmentation discovered gives a distinct advantage to help strengthen brand loyalty through Priority Customers. The next campaign is expected to surpass the goal of a 15% response rate by attaining 16.2%. This is possible by targeting the combined group of 362 customers which includes Priority Customers and newly identified high potential prospects. With effective handling and monitoring of the strategy’s execution, there will be improved campaign performance and customer interaction.



---



  









