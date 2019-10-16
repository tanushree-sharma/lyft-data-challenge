-- getting the number of rides that a driver has completed
SELECT driver_id, COUNT(ride_id) AS numRides
FROM tempdb.dbo.ride_ids
GROUP BY driver_id
ORDER BY numRides DESC;

-- check 
SELECT *
FROM tempdb.dbo.ride_timestamps
WHERE ride_id '034f2e614a2f9fc7f1c2f77647d1b981';

SELECT a.ride_id, a.ride_prime_time, b.timestamps
FROM tempdb.dbo.ride_ids a 
INNER JOIN tempdb.dbo.ride_timestamps b 
ON a.ride_id = b.ride_id
WHERE a.ride_prime_time > 0
ORDER BY a.ride_prime_time DESC;

SELECT DISTINCT ride_prime_time
FROM tempdb.dbo.ride_ids
ORDER BY ride_prime_time DESC;

DROP TABLE IF EXISTS tempdb.dbo.driverLifetimes;

-- creating a table with driver id, start date, and their latest ride
SELECT a.driver_id, a.driver_onboard_date, b.ride_id, MAX(c.timestamps) as LastRide
INTO tempdb.dbo.driverLifetimes -- name of the new table
FROM tempdb.dbo.driver_ids a 
LEFT JOIN tempdb.dbo.ride_ids b
ON a.driver_id = b.driver_id
LEFT JOIN tempdb.dbo.ride_timestamps c
ON b.ride_id = c.ride_id
GROUP BY a.driver_id, a.driver_onboard_date, b.ride_id;

-- dropping a table, need to do this everytime you re-run the create table script below
DROP TABLE IF EXISTS tempdb.dbo.driverLifetimesFinal;

-- getting the difference between each drivers latest ride and their start date
SELECT driver_id,
	(CASE -- case statement is like an if statement to say that if they don't have a latest ride date, make the date difference a 0
		WHEN (MAX(DATEDIFF(DAY, driver_onboard_date, LastRide))) IS NULL THEN 0
		ELSE (MAX(DATEDIFF(DAY, driver_onboard_date, LastRide)))
	END) AS diff
INTO tempdb.dbo.driverLifetimesFinal -- name of the new table
FROM tempdb.dbo.driverLifetimes
GROUP BY driver_id
ORDER BY diff DESC;

-- getting the average date difference, which was 49
SELECT AVG(diff)
FROM tempdb.dbo.driverLifetimesFinal;

DROP TABLE IF EXISTS tempdb.dbo.final_driver_lifetimes;

-- getting the lifetime rate by taking the date difference and dividing by the average date difference (49)
create table tempdb.dbo.final_driver_lifetimes(driver_id varchar(100),lifetime_rate decimal(10,3));
insert into tempdb.dbo.final_driver_lifetimes
SELECT driver_id, (diff/49.00)
FROM tempdb.dbo.driverLifetimesFinal;


-- changing the data type of a column
ALTER TABLE tempdb.dbo.driverLifetimesFinal
ALTER COLUMN diff DECIMAL(5,2);


select count(distinct driver_id) from tempdb.dbo.final_dist_value;
-- distance value


DROP TABLE IF EXISTS tempdb.dbo.temp_total_dist;

-- adds ride distance for each driver 
create table tempdb.dbo.temp_total_dist(driver_id varchar(100),total_ride_distance int);
insert into tempdb.dbo.temp_total_dist
select driver_id, sum(ride_distance) from tempdb.dbo.ride_ids group by driver_id;
-- some drivers have no rides so set their temp_total_dist to 0
-- gets all riders that are in driver_ids but not in temp_total_dist
-- add to temp_total_dist, setting total ride distance to 0
insert into tempdb.dbo.temp_total_dist
SELECT a.driver_id, 0 FROM tempdb.dbo.driver_ids AS a WHERE NOT EXISTS 
   (SELECT * FROM tempdb.dbo.temp_total_dist AS b WHERE b.driver_id = a.driver_id);

DROP TABLE IF EXISTS tempdb.dbo.temp_dist_date;

-- gets the 'now' time 
create table tempdb.dbo.temp_max_timestamp(max_timestamp date);
insert into tempdb.dbo.temp_max_timestamp
select MAX(timestamps) AS max_timestamp from tempdb.dbo.ride_timestamps;

-- driverid, total ride distance and onboard date on one table
create table tempdb.dbo.temp_dist_date (driver_id varchar(100),total_ride_distance int,onboard_date date);
insert into tempdb.dbo.temp_dist_date 
SELECT tempdb.dbo.driver_ids.driver_id, tempdb.dbo.temp_total_dist.total_ride_distance, driver_onboard_date
FROM tempdb.dbo.driver_ids
INNER JOIN tempdb.dbo.temp_total_dist 
ON tempdb.dbo.driver_ids.driver_id = tempdb.dbo.temp_total_dist.driver_id;

-- makes sure that number of drivers in driver_ids matches drivers in temp_dist_date
SELECT COUNT(1)
FROM tempdb.dbo.temp_dist_date;

-- gets the 'now' time 
select MAX(timestamps) AS max_timestamp from tempdb.dbo.ride_timestamps;

DROP TABLE IF EXISTS tempdb.dbo.temp_dist_numerator;


create table tempdb.dbo.temp_dist_numerator(driver_id varchar(100),total_ride_distance int,date_diff int);

insert into tempdb.dbo.temp_dist_numerator
select driver_id, total_ride_distance, DATEDIFF(day, onboard_date, '2016-06-27')
from tempdb.dbo.temp_dist_date;
               		
-- get average from numerator 20544
select AVG(total_ride_distance/date_diff) AS avg_num from tempdb.dbo.temp_dist_numerator;

drop table if exists tempdb.dbo.final_dist_value;

-- FINAL TABLE
create table tempdb.dbo.final_dist_value(driver_id varchar(100),dist_value decimal(10,3));
insert into tempdb.dbo.final_dist_value
select driver_id, (total_ride_distance/date_diff)/20544
from tempdb.dbo.temp_dist_numerator;


-- prime time value

DROP TABLE IF EXISTS tempdb.dbo.temp_total_dist;

-- adds ride distance for each driver 
create table tempdb.dbo.temp_total_dist(driver_id varchar(100),total_ride_distance int);
insert into tempdb.dbo.temp_total_dist
select driver_id, sum(ride_distance) from tempdb.dbo.ride_ids group by driver_id;
-- some drivers have no rides so set their temp_total_dist to 0
-- gets all riders that are in driver_ids but not in temp_total_dist
-- add to temp_total_dist, setting total ride distance to 0
insert into tempdb.dbo.temp_total_dist
SELECT a.driver_id, 0 FROM tempdb.dbo.driver_ids AS a WHERE NOT EXISTS 
   (SELECT * FROM tempdb.dbo.temp_total_dist AS b WHERE b.driver_id = a.driver_id);
 
select count(1) from tempdb.dbo.temp_total_dist;


DROP TABLE IF EXISTS tempdb.dbo.temp_prime_tally;


create table tempdb.dbo.temp_prime_tally(driver_id varchar(100), twenty_five int, fifty int, seventy_five int, hundo int, one_fiddy int,
										two_hundo int, two_fiddy int, three_hundo int, three_fiddy int, four_hundo int, five_hundo int);

insert into tempdb.dbo.temp_prime_tally			
select driver_id,
    sum(case when ride_prime_time = 25 then 1 else 0 end) as twenty_five,
    sum(case when ride_prime_time = 50 then 1 else 0 end) as fifty,
    sum(case when ride_prime_time = 75 then 1 else 0 end) as seventy_five,
    sum(case when ride_prime_time = 100 then 1 else 0 end) as hundo,
    sum(case when ride_prime_time = 150 then 1 else 0 end) as one_fiddy,
    sum(case when ride_prime_time = 200 then 1 else 0 end) as two_hundo,
    sum(case when ride_prime_time = 250 then 1 else 0 end) as two_fiddy,
    sum(case when ride_prime_time = 300 then 1 else 0 end) as three_hundo,
    sum(case when ride_prime_time = 350 then 1 else 0 end) as three_fiddy,
    sum(case when ride_prime_time = 400 then 1 else 0 end) as four_hundo,
    sum(case when ride_prime_time = 500 then 1 else 0 end) as five_hundo
from tempdb.dbo.ride_ids
group by driver_id;


-- some drivers have no rides so set their prime_tally to all 0
-- gets all riders that are in driver_ids but not in ride_ids
-- add to ride_ids, setting prime times to 0
insert into tempdb.dbo.temp_prime_tally	
SELECT a.driver_id, 0,0,0,0,0,0,0,0,0,0,0 FROM tempdb.dbo.driver_ids AS a WHERE NOT EXISTS 
   (SELECT * FROM tempdb.dbo.temp_prime_tally AS b WHERE b.driver_id = a.driver_id);

-- delete all drivers in prime_tally but not in driver_id
DELETE FROM tempdb.dbo.temp_prime_tally	WHERE driver_id in
	(SELECT distinct driver_id FROM tempdb.dbo.ride_ids AS a WHERE NOT EXISTS 
   (SELECT * FROM tempdb.dbo.driver_ids AS b WHERE a.driver_id = b.driver_id));
  
select count(1) from tempdb.dbo.temp_prime_tally;
 
SELECT * from tempdb.dbo.driver_ids where driver_id='234bb57cea53cfb13d8faf4a2900341a';
  
-- check to make sure above query is right	
SELECT COUNT(ride_id)
FROM tempdb.dbo.ride_ids
WHERE driver_id = '98a878a6fe557bf91236e6fc0413faba'
AND ride_prime_time = 50;

DROP TABLE IF EXISTS tempdb.dbo.temp_prime_weighted;

create table tempdb.dbo.temp_prime_weighted(driver_id varchar(100), prime_sum decimal(10,3));
insert into tempdb.dbo.temp_prime_weighted
select driver_id, 
		(CASE
		WHEN twenty_five+ fifty + seventy_five+ hundo + one_fiddy+ two_hundo+ two_fiddy + 
	   	three_hundo+ three_fiddy + four_hundo + five_hundo = 0 THEN 0
	   	ELSE ((twenty_five*(0.25) + fifty*(0.5) + seventy_five*(0.75) + hundo*(1) + one_fiddy*(1.5) + two_hundo*(2) + two_fiddy*(2.5) + 
	   	three_hundo*(3) + three_fiddy*(3.5) + four_hundo*(4) + five_hundo*(5))/(twenty_five+ fifty + seventy_five+ hundo + one_fiddy+ two_hundo+ two_fiddy + 
	   	three_hundo+ three_fiddy + four_hundo + five_hundo))
		END)
from tempdb.dbo.temp_prime_tally;

select * from tempdb.dbo.temp_prime_tally where driver_id= 'ffff51a71f2f185ec5e97d59dbcd7a78';
select count(*) from tempdb.dbo.final_dist_value;

-- get average weight 0.444940
select AVG(prime_sum) AS prime_sum from tempdb.dbo.temp_prime_weighted;

DROP TABLE IF EXISTS tempdb.dbo.final_prime_val;

-- FINAL TABLE
create table tempdb.dbo.final_prime_val(driver_id varchar(100),prime_value decimal(10,3));
insert into tempdb.dbo.final_prime_val
select driver_id, (prime_sum/0.444940)
from tempdb.dbo.temp_prime_weighted;

DROP TABLE IF EXISTS tempdb.dbo.final_lifetime_value;

-- MERGE TABLES
create table tempdb.dbo.final_lifetime_value(driver_id varchar(100),value decimal(10,3));
insert into tempdb.dbo.final_lifetime_value
select tempdb.dbo.final_driver_lifetimes.driver_id,
	(CASE
	when (tempdb.dbo.final_prime_val.prime_value + tempdb.dbo.final_dist_value.dist_value) = 0 then 0
	else
	tempdb.dbo.final_driver_lifetimes.lifetime_rate*(tempdb.dbo.final_prime_val.prime_value + tempdb.dbo.final_dist_value.dist_value)
	END)
from tempdb.dbo.final_driver_lifetimes
inner join tempdb.dbo.final_dist_value on tempdb.dbo.final_driver_lifetimes.driver_id = tempdb.dbo.final_dist_value.driver_id
inner join tempdb.dbo.final_prime_val on tempdb.dbo.final_driver_lifetimes.driver_id = tempdb.dbo.final_prime_val.driver_id;

select count(1) from tempdb.dbo.final_prime_val;


select * from tempdb.dbo.final_prime_val where driver_id = 'c12c2eb875879488e687111335a12805';


select min(value) from tempdb.dbo.final_lifetime_value;
select max(value) from tempdb.dbo.final_lifetime_value;
