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
  where figure>2


  with cte as(
  select id from marketing_data
  where AcceptedCmp6 =1 and id in ( select * from most_Accepted))

  --checking for % of customers that accepted more than 2 comp and accepted comp6
  select count(id)* 100.0 / (select count (id) from marketing_data where AcceptedCmp6 = 1)
  from most_Accepted
  
  
  