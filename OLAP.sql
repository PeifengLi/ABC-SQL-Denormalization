CREATE DATABASE Datasets;

use Datasets;

-- create table - drop table MyCube
CREATE TABLE MyCube (Product varchar(10),ThisQuarter varchar(5),Region varchar(10),Sales real);

-- add records
INSERT INTO MyCube VALUES ('A','Q1','Europe',10);
INSERT INTO MyCube VALUES ('A','Q1','Europe',12);
INSERT INTO MyCube VALUES ('A','Q1','America',20);
INSERT INTO MyCube VALUES ('A','Q1','America',18);
INSERT INTO MyCube VALUES ('A','Q2','Europe',20);
INSERT INTO MyCube VALUES ('A','Q2','Europe',23);
INSERT INTO MyCube VALUES ('A','Q2','Europe',24);
INSERT INTO MyCube VALUES ('A','Q2','America',50);
INSERT INTO MyCube VALUES ('A','Q2','America',48);
INSERT INTO MyCube VALUES ('A','Q3','America',20);
INSERT INTO MyCube VALUES ('A','Q4','Europe',10);
INSERT INTO MyCube VALUES ('A','Q4','Europe',8);
INSERT INTO MyCube VALUES ('A','Q4','Europe',13);
INSERT INTO MyCube VALUES ('A','Q4','Europe',7);
INSERT INTO MyCube VALUES ('A','Q4','America',30);
INSERT INTO MyCube VALUES ('B','Q1','Europe',40);
INSERT INTO MyCube VALUES ('B','Q1','Europe',30);
INSERT INTO MyCube VALUES ('B','Q1','Europe',20);
INSERT INTO MyCube VALUES ('B','Q1','Europe',50);
INSERT INTO MyCube VALUES ('B','Q1','America',60);
INSERT INTO MyCube VALUES ('B','Q1','America',50);
INSERT INTO MyCube VALUES ('B','Q1','America',40);
INSERT INTO MyCube VALUES ('B','Q2','Europe',20);
INSERT INTO MyCube VALUES ('B','Q2','Europe',25);
INSERT INTO MyCube VALUES ('B','Q2','America',10);
INSERT INTO MyCube VALUES ('B','Q2','America',11);
INSERT INTO MyCube VALUES ('B','Q2','America',16);
INSERT INTO MyCube VALUES ('B','Q2','America',13);
INSERT INTO MyCube VALUES ('B','Q2','America',10);
INSERT INTO MyCube VALUES ('B','Q3','America',20);
INSERT INTO MyCube VALUES ('B','Q3','America',28);
INSERT INTO MyCube VALUES ('B','Q4','Europe',10);
INSERT INTO MyCube VALUES ('B','Q4','Europe',5);
INSERT INTO MyCube VALUES ('B','Q4','Europe',5);
INSERT INTO MyCube VALUES ('B','Q4','America',40);
INSERT INTO MyCube VALUES ('B','Q4','America',20);
INSERT INTO MyCube VALUES ('B','Q4','America',50);
INSERT INTO MyCube VALUES ('B','Q4','America',30);

--
select * from MyCube;


-- pivot query
select 
	* 
    from 
    MyCube PIVOT(SUM(Sales) FOR ThisQuarter IN (Q1,Q2,Q3,Q4)) AS P;

-- MySQL
SELECT Product, Region, SUM(CASE WHEN ThisQuarter = 'Q1' THEN Sales ELSE NULL END) AS Q1,
SUM(CASE WHEN ThisQuarter = 'Q2' THEN Sales END) AS Q2, 
SUM(CASE WHEN ThisQuarter = 'Q3' THEN Sales END) AS Q3,
SUM(CASE WHEN ThisQuarter = 'Q4' THEN Sales END) AS Q4
FROM MyCube
GROUP BY Product, Region;

SELECT Product, Region, ThisQuarter, SUM(Sales) a
FROM MyCube
GROUP BY Product, Region, ThisQuarter;

-- pivot query
select
	Region, Q1, Q2, Q3, Q4
from
	MyCube PIVOT(SUM(Sales) FOR ThisQuarter IN (Q1,Q2,Q3,Q4)) AS P;


-- pivot query with aggregate
SELECT Product, Region, Q1, Q2, Q3, Q4
FROM   
(SELECT Product, Region, ThisQuarter, Sales FROM MyCube) AS p  
PIVOT  
(sum(Sales) FOR ThisQuarter IN (Q1,Q2,Q3,Q4)) AS pvt  


-- pivot query with aggregate exclusing Region (DRILL DOWN and ROLL UP)
SELECT Product, Q1, Q2, Q3, Q4
FROM   
(SELECT Product, ThisQuarter, Sales FROM MyCube) AS p  
PIVOT  
(sum(Sales) FOR ThisQuarter IN (Q1,Q2,Q3,Q4)) AS pvt  


-- SLICING and DICING
SELECT 
	REGION, Q1, Q2, Q3, Q4
INTO
	#cube
FROM   
	(SELECT REGION, [QUARTER], SALES FROM SALESTABLE) AS p  
	PIVOT  
	(SUM(SALES) FOR [QUARTER] IN (Q1,Q2,Q3,Q4)) AS pvt  

select * from #cube

--
select * from #cube where REGION='America'
select REGION, Q1 from #cube

--
select Q1 from #cube where REGION='America'

------------------------------------------------------------------------------------
------------------------------------------------------------------------------------

-- group by with cube
SELECT ThisQuarter, Region, Product, SUM(Sales)as TotalSales, GROUPING(ThisQuarter) AS 'Grouping' 
FROM MyCube
GROUP BY ThisQuarter, Region, Product with cube
ORDER BY 1,2,3

--
SELECT 
	case when GROUPING(ThisQuarter)=1 then isnull(ThisQuarter,'Total') else ThisQuarter end as ThisQuarter
	, case when GROUPING(Region)=1 then isnull(Region, 'Total') else Region end as Region
	, case when GROUPING(Product)=1 then isnull(Product, 'Total') else Product end as Product
	, SUM(Sales)as TotalSales
	, GROUPING(ThisQuarter) AS 'Q' 
	, GROUPING(Region) AS 'R' 
	, GROUPING(Product) AS 'P' 
FROM 
	MyCube
GROUP BY 
	ThisQuarter, Region, Product with cube
ORDER BY 
	1, 2, 3



-- group by with rollup
SELECT ThisQuarter, Region, Product, SUM(Sales)as TotalSales, GROUPING(ThisQuarter) AS 'Grouping' 
FROM MyCube
GROUP BY ThisQuarter, Region, Product with rollup
ORDER BY 1,2,3

--
SELECT 
	case when GROUPING(ThisQuarter)=1 then isnull(ThisQuarter,'Total') else ThisQuarter end as ThisQuarter
	, case when GROUPING(Region)=1 then isnull(Region, 'Total') else Region end as Region
	, case when GROUPING(Product)=1 then isnull(Product, 'Total') else Product end as Product
	, SUM(Sales)as TotalSales
	, GROUPING(ThisQuarter) AS 'Q' 
	, GROUPING(Region) AS 'R' 
	, GROUPING(Product) AS 'P' 
FROM 
	MyCube
GROUP BY 
	ThisQuarter, Region, Product with rollup
ORDER BY 
	1, 2, 3


-- group by grouping sets
SELECT ThisQuarter, Region, Product, SUM(Sales) as TotalSales
FROM MyCube
GROUP BY GROUPING SETS ((ThisQuarter), (Region), (Product))
ORDER BY 1,2,3

--
SELECT ThisQuarter, NULL as Region, SUM(Sales) as TotalSalesFROM MyCubeGROUP BY ThisQuarter
UNION ALL
SELECT NULL, Region, SUM(Sales)as TotalSales FROM MyCubeGROUP BY Region
ORDER BY 1,2


-- Ranking  
SELECT 
	Product, Region, ThisQuarter, Sales
	, RANK() OVER (ORDER BY Sales ASC) as RANK_SALES
	, DENSE_RANK() OVER (ORDER BY Sales ASC) as DENSE_RANK_SALES
	, PERCENT_RANK() OVER (ORDER BY Sales ASC) as PERC_RANK_SALES
	, CUME_DIST() OVER (ORDER BY Sales ASC) as CUM_DIST_SALES
FROM 
	MyCube
ORDER BY 
	RANK_SALES ASC


-- Windowing
SELECT 
	ThisQuarter, Region, Sales
	, AVG(Sales) OVER (PARTITION BY Region ORDER BY ThisQuarter) AS Sales_Avg
FROM 
	MyCube
ORDER BY 
	Region, ThisQuarter, Sales_Avg

-- Windowing
SELECT 
	ThisQuarter, Region, Sales
	, AVG(Sales) OVER (PARTITION BY Region ORDER BY ThisQuarter ROWS BETWEEN 2 PRECEDING AND 0 FOLLOWING) AS Sales_Avg
FROM 
	MyCube
ORDER BY 
	Region, ThisQuarter, Sales_Avg



-- PIVOT with CASE
select Product, Region, sum(Sales) as Sales_Total from MyCube group by Product, Region order by 1,2

--
select 
  Product
  ,sum(case when Region='Europe'then Sales else 0 end) as 'Europe'
  ,sum(case when Region='America'then Sales else 0 end) as 'America'
from 
	MyCube
group by 
	Product


-- pivot query
select 
	Product, Europe, America 
from 
	MyCube PIVOT(SUM(Sales) FOR Region IN (Europe,America)) AS P

--
SELECT Product, Europe, America
FROM   
(SELECT Product, Region, Sales FROM MyCube) AS p  
PIVOT  
(sum(Sales) FOR Region IN (Europe,America)) AS pvt  

USE ABC;
SELECT Order_Date, Product, Region, SUM(Sales) AS Sales,
GROUPING(Order_Date), GROUPING(Product), GROUPING(Region)
FROM cube2 c 
GROUP BY Order_Date, Product, Region;