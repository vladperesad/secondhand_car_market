SHOW DATABASES;
CREATE DATABASE excel_proj;
USE excel_proj;

#create an empty table with the following schema
DROP TABLE IF EXISTS autos;
CREATE TABLE autos(
id VARCHAR(225),	
dateCrawled VARCHAR(225),	
v_name VARCHAR(225),
seller VARCHAR(225),
offerType VARCHAR(225),
price VARCHAR(225),
abtest VARCHAR(225),
vehicleType VARCHAR(225),
yearOfRegistration VARCHAR(225),
gearbox VARCHAR(225),
powerPS VARCHAR(225),
model VARCHAR(225),
kilometer VARCHAR(225),
monthOfRegistration VARCHAR(225),
fuelType VARCHAR(225),
brand VARCHAR(225),
notRepairedDamage VARCHAR(225),
dateCreated VARCHAR(225),
nrOfPictures VARCHAR(225),
postalCode VARCHAR(225),
lastSeen VARCHAR(225));

# and import it
SHOW TABLES;
LOAD DATA LOCAL INFILE "C:/vladperesad/excel_project/used_cars/autos_w.csv"
INTO TABLE autos
FIELDS TERMINATED BY ','
LINES TERMINATED BY '\n'
IGNORE 1 ROWS 
(id,
dateCrawled,
v_name,
seller,
offerType,
price,
abtest,
vehicleType,
yearOfRegistration,
gearbox,
powerPS,
model,
kilometer,
monthOfRegistration,
fuelType,
brand,
notRepairedDamage,
dateCreated,
nrOfPictures,
postalCode,
lastSeen);

SET GLOBAL local_infile=1;
SHOW GLOBAL VARIABLES LIKE 'local_infile';

#take a look at the table structure
DESCRIBE autos;

SELECT
	*
FROM
	autos;
    
#create a working copy of the table that contains only columns that are needed for the analysis

DROP TABLE IF EXISTS autos_cleaned;
CREATE TABLE autos_cleaned
SELECT
	(id),
    brand,
    model,
    v_name AS vehicle_name,
    vehicleType AS vehicle_type,
    gearbox,
    powerPS AS power,
    seller,
    price,
    fuelType AS fuel,
    kilometer AS mileage,
    notRepairedDamage AS damage,
    yearOfRegistration AS reg_year,
    monthOfRegistration AS reg_mon,
    dateCreated AS date_created,
    dateCrawled AS date_crawled,
    lastSeen AS last_seen
FROM
	autos;
   
#take a look at the data values to make sure they're fine

SELECT
	MAX(LENGTH(date_created)) AS date_created_max,
    MIN(LENGTH(date_created)) AS date_created_min,
    MAX(LENGTH(date_crawled)) AS date_crawled_max,
    MIN(LENGTH(date_crawled)) AS date_crawled_min,
    MAX(LENGTH(last_seen)) AS last_seen_max,
    MIN(LENGTH(last_seen)) AS last_seen_min
FROM
	autos_cleaned;
    
    #with given format the date should be YYYY-MM-DD which is 10 digits, anything less or more than that must be wrong
    #let's take a look
    
SELECT
	date_created
FROM
	autos_cleaned
WHERE
	LENGTH(date_created) >10 OR LENGTH(date_created) <10;
   
DELETE FROM autos_cleaned
WHERE
	LENGTH(date_created) >10 OR LENGTH(date_created) <10;

#turn VARCHAR format to DATE
#create 3 new columns   

ALTER TABLE autos_cleaned
ADD COLUMN date_crawled_2 DATE AFTER date_crawled,
ADD COLUMN date_created_2 DATE AFTER date_created,
ADD COLUMN last_seen_2 DATE AFTER last_seen;

#insert data into them with the new format

UPDATE autos_cleaned
SET date_crawled_2 = STR_TO_DATE(date_crawled, '%Y-%m-%d');

UPDATE autos_cleaned
SET date_created_2 = STR_TO_DATE(date_created, '%Y-%m-%d');

UPDATE autos_cleaned
SET last_seen_2 = STR_TO_DATE(last_seen, '%Y-%m-%d');
   
   
SELECT
	*
FROM
	autos_cleaned;
    
#-------------------------------------------------
   
   

#count how many of those there are

SELECT
	date_created
FROM
	autos_cleaned
WHERE
	LENGTH(date_created) >10 OR LENGTH(date_created) <10;
    
#repeat the same thing with the other two

SELECT
	date_crawled
FROM
	autos_cleaned
WHERE
	LENGTH(date_crawled) >10 OR LENGTH(date_crawled) <10;
    
#109 rows of probably mispalced values
    
SELECT
	last_seen
FROM
	autos_cleaned
WHERE
	last_seen IS NULL;
    
#all the rows returned although the date seems to have 10 digits

DROP TABLE IF EXISTS test;
CREATE TEMPORARY TABLE test
SELECT
	LTRIM(last_seen) AS last_seen
FROM
	autos_cleaned;
    
SELECT
	*
FROM
	test
WHERE
	last_seen_2 IS NULL;
    
ALTER TABLE test
ADD COLUMN last_seen_2 DATE AFTER last_seen;

UPDATE test
SET last_seen_2 = CAST(last_seen AS DATE);

   
   
   
   
   
   
   
   
   
   
# create a working copy of a table and use TRIM() to get rid of extra spaces seen in excel    
DROP TABLE IF EXISTS autos_cleaned;    
CREATE TABLE autos_cleaned
SELECT
TRIM(id) AS id,
TRIM(dateCrawled) AS date_crawled,
TRIM(v_name) AS vehicle,
TRIM(seller) AS seller,
TRIM(price) AS price,
TRIM(vehicleType) AS vehicle_type,
TRIM(yearOfRegistration) AS year_of_reg,
TRIM(gearbox) AS transmission,
TRIM(powerPS) AS power,
TRIM(model) AS model,
TRIM(kilometer) AS kilometrage,
TRIM(monthOfRegistration) AS month_of_reg,
TRIM(fuelType) AS fuel_type,
TRIM(brand) AS brand,
TRIM(notRepairedDamage) AS present_damage,
TRIM(dateCreated) AS date_created,
TRIM(lastSeen) AS last_seen
FROM
	autos;
    
# run a query to check that the table was created properly
SELECT
	*
FROM
	autos_cleaned;
#compare COUNT() of ids and COUNT() of UNIQUE ids to see if theres duplicates    
SELECT
	COUNT(id)
FROM
	autos_cleaned;

SELECT
	COUNT(DISTINCT(id))
FROM
	autos_cleaned;
    
#numbers are equal -> no duplicates;

#take a look at the dates all three columns have 3 different MAX lengths 
SELECT
    MAX(LENGTH(date_crawled)),
    MIN(LENGTH(date_crawled)),
    MAX(LENGTH(date_created)),
    MIN(LENGTH(date_created)),
    MAX(LENGTH(last_seen)),
    MIN(LENGTH(last_seen))
FROM
	autos_cleaned;
#let's pull em up

SELECT
	MAX(date_crawled),
    MAX(date_created),
    MAX(last_seen)
FROM
	autos_cleaned;

# turns out there are values present that should not be in this column    

#try and count how many rows content values that are not dates
SELECT
	COUNT(date_crawled)
FROM
	autos_cleaned
WHERE
	LENGTH(date_crawled) <15;
#3 for `date_crawled`

SELECT
	COUNT(date_created)
FROM
	autos_cleaned
WHERE
	LENGTH(date_created) <15;
#most likely there are the same 3 rows

SELECT
	COUNT(last_seen)
FROM
	autos_cleaned
WHERE
	LENGTH(last_seen) <15;
    
#let's get rid of these rows using DELETE() statement

DELETE FROM autos_cleaned
WHERE LENGTH(date_crawled) <15 OR LENGTH(date_created) <15 OR LENGTH(last_seen) <15;

#rerun the MIN() MAX() query to see if it is more consistent now
 SELECT
    MAX(LENGTH(date_crawled)),
    MIN(LENGTH(date_crawled)),
    MAX(LENGTH(date_created)),
    MIN(LENGTH(date_created)),
    MAX(LENGTH(last_seen)),
    MIN(LENGTH(last_seen))
FROM
	autos_cleaned;

#as we don't need time, we can simply remove it and turn the string into a DATE type 

#first add a few columns to the table
ALTER TABLE autos_cleaned
ADD COLUMN date_crawled_2 DATE AFTER date_crawled,
ADD COLUMN date_created_2 DATE AFTER date_created,
ADD COLUMN last_seen_2 DATE AFTER last_seen;

UPDATE autos_cleaned
SET date_crawled_2 = CAST(date_crawled AS DATE);

UPDATE autos_cleaned
SET date_created_2 = CAST(date_created AS DATE);

UPDATE autos_cleaned
SET last_seen_2 = STR_TO_DATE(last_seen, '%Y-%m-%d %k:%i');

SELECT
	last_seen
FROM
	autos_cleaned
WHERE
	last_seen is null;

SELECT
	date_crawled
FROM
	autos_cleaned
WHERE 
	date_crawled IS NULL;
    
SELECT
	dateCrawled
FROM
	autos
WHERE
	dateCrawled IS NULL;




SELECT
	CAST(date_crawled AS DATE),
    date_crawled
FROM
	autos_cleaned;
