select * from marketing_data


select 
avg(cast(response as int))* 100 as overall_res from marketing_data


SELEct education,Marital_Status,
    AVG(cast(Response as float)) * 100 AS response_rate
FROM marketing_data
GROUP BY Education, Marital_Status
ORDER BY response_rate DESC

SELECT * FROM marketing_data
WHERE RESPONSE <1 OR AcceptedCmp4 <1 or AcceptedCmp2 <1 or AcceptedCmp3 <1 or AcceptedCmp4 <1 or AcceptedCmp5 <1


/*The company’s marketing campaigns have a response rate below 10%, leading to ineffective 
targeting, wasted marketing spend, and low customer engagement. A data-driven approach is
needed to improve response rates by at least 15% through better segmentation, personalized offers, 
and optimized marketing channels*/


EXEC sp_rename 'marketing_data.response', 'AcceptedCmp6', 'COLUMN'

select COLUMN_NAME ,DATA_TYPE FROM INFORMATION_SCHEMA.COLUMNS
WHERE 

TABLE_NAME= 'marketing_data'   
and COLUMN_NAME ='AcceptedCmp1'

with sum_m as (
 SELECT SUM (CASE WHEN AcceptedCmp1 = 1 then 1 else 0 end ) as comp1, 
        sum (case when AcceptedCmp2 =1 then 1 else 0  end ) as comp2,
		 sum (case when AcceptedCmp3 =1 then 1 else 0  end ) as comp3,
		  sum (case when AcceptedCmp4 =1 then 1 else 0  end ) as comp4,
		   sum (case when AcceptedCmp5 =1 then 1 else 0  end ) as comp5,
		    sum (case when AcceptedCmp6 =1 then 1 else 0  end ) as comp6
			from marketing_data),
allrows as (
select count(*) as cnt from marketing_data),

percentage_comp as (

select (comp1 * 1.0)/cnt as comp1,(comp2* 1.0)/cnt as comp2,(comp3* 1.0)/cnt as comp3,(comp4* 1.0)/cnt as comp4,(comp5* 1.0)/cnt as comp5,(comp6 *1.0 )/cnt as comp6
from sum_m
cross join allrows)
  select AVG(comp1+comp2+comp3+comp4+comp5+comp6) as avg_percent from percentage_comp


  select * from marketing_data
  where AcceptedCmp6 =1 and AcceptedCmp1 = 0 and AcceptedCmp2= 0 
 and AcceptedCmp3= 0 and AcceptedCmp4=0 and AcceptedCmp5= 0
 
 
 create view most_Accepted as
  
  
  with cte as (
  select id,case when AcceptedCmp1 =1 and AcceptedCmp6=1 then ID else 0 end as comp1,
	     case when AcceptedCmp2 =1 and AcceptedCmp6=1 then ID else 0 end as comp2,
		 case when AcceptedCmp3 =1 and AcceptedCmp6=1 then ID else 0 end as comp3,
		 case when AcceptedCmp4 =1 and AcceptedCmp6=1 then ID else 0 end as comp4,
		 case when AcceptedCmp5 =1 and AcceptedCmp6=1 then ID else 0 end as comp5
			  
			  from marketing_data),
  accepted as (
  select * from cte 
  where comp1>0 or  comp2>0 or  comp3>0 or comp4>0 or  comp5>0),

  figure as (
 select id,comp,figure from accepted
  unpivot( figure for comp in (comp1,comp2,comp3,comp4,comp5)) as unpvt),
   figure2 as(
  select id,count(*) as figure
  from figure
  where figure>0
  group by ID)

select id
  from figure2
  where figure>=2



  --checking for % of customers that accepted more than 2 comp and accepted comp6
  select count(id)* 100.0 / (select count (id) from marketing_data where AcceptedCmp6 = 1)
  from most_Accepted
  
select * from marketing_data
  
  -- Test group: Customers who accepted campaign 6 but not enough other campaigns

SELECT id,sum(Income),Education,Marital_Status,Country--appears to have low income
FROM marketing_data
WHERE AcceptedCmp6 = 1
  AND (AcceptedCmp1*1.0 + AcceptedCmp2*1.0 + AcceptedCmp3*1.0 + AcceptedCmp4*1.0 + AcceptedCmp5*1.0 + AcceptedCmp6*1.0) <= 2 



   --checking for % of customers that accepted more than 2 comp and accepted comp6
  select count(id)* 100.0 / (select count (id) from marketing_data where AcceptedCmp6 = 1)
  from most_Accepted


  
select count(*)* 100.0 / (select count(*)  from most_Accepted )
  from  marketing_data ma 
where Recency <= 30 and id in (select id from most_Accepted)
---percentage of people that made orders in the past 30days
with total_no as (
select count(*) as cnt from most_Accepted mo
left join marketing_data  md on md.ID =mo.id
where Recency <= 30 and md.ID in (select md.ID from most_Accepted)),

no_accepted as (
select count(*) as cnt1 from most_Accepted)

select cnt *100.0 /  cnt1 
from total_no
cross join no_accepted



SELECT ma.id,Education,Marital_Status,
sum(Income)as total_income,  sum(NumDealsPurchases) as total_discount,
       sum(numwebpurchases) as total_webpurchase,
	   sum(NumCatalogPurchases) as total_catelog,
	   sum(NumStorePurchases) as total_storepurchase,
	   sum(NumWebVisitsMonth) as total_webvisit from most_Accepted ma
left join marketing_data  md  on ma.id = md.id
 group by ma.id,Education,Marital_Status
 order by total_income desc

 select sum(NumWebVisitsMonth)as cnt,sum(Income)as income,sum(NumStorePurchases)as store,
 sum(numwebpurchases) as webp from most_Accepted ma
 left join marketing_data  md on md.id = ma.id
where Recency <=30 

with cte as (
select * from marketing_data 
where id not in (select id from most_Accepted))

select avg(income)  from cte


create view RFM_WEB as 
---checking for income greater than the average income
with highest_income as (
select * from marketing_data
where income >
(select avg(income)  from marketing_data)),--------average income

----checking for recency for the last 30days
recency as(
select * from marketing_data
where recency  <= 30),

---checking RFM
frequency_webvisit as (--------frequency of webvisited
select * from marketing_data
where NumWebVisitsMonth >-----greater than average
(select avg(numwebvisitsmonth) from marketing_data )),

frequency_storepurhase as (--------------frequency of storepurchase
select * from marketing_data
where NumStorePurchases >(---greater than average
select avg(NumStorePurchases) from marketing_data))

select i.id from highest_income i
join recency r on i.id = r.id
join frequency_webvisit f on r.id = f.id
join frequency_storepurhase s on f.id =s.id


create view RFM_store as 
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


/*checking for behaviour of customers that had income greater than average,
recency for the last 30days,visted the web greater than the avereage,
and number of purchase instore greater than average*/
select * from RFM_WEB Rw
left join marketing_data md
ON Rw.id = md.ID

/*checking for behaviour of customers that had income lesser than average,
recency for mare than 30days,visted the store lesser than the avereage,
and number of purchase instore lesser than average*/
select * from RFM_store Rw
left join marketing_data md
ON Rw.id = md.ID



  

select * from marketing_data
where ID not in (select ID from RFM_WEB) 
and  ID not in (select id from RFM_WEB2)




select id,min(recency)as min from marketing_data
group by id
order by min desc




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
and AcceptedCmp6= 1 ),-----number of loyal and high value customers

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
select id from highest_income),---combining both highest purchase and highest income together 

added_customers as (
select id from union_id 
where id not in (select id from marketing_data
where AcceptedCmp6=1))-------number of new customers to be added to targeted customers


select m.ID from marketing_data m
where m.AcceptedCmp6 =1
union 
select id from added_customers ---total number of targeted pontential customers to accept next campaign















