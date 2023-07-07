CREATE DATABASE secondhand_car_market;
USE secondhand_car_market;


DROP TABLE IF EXISTS autos_cleaned_r;
CREATE TABLE autos_cleaned_r(
id INT,
brand VARCHAR (225),
model VARCHAR (225),
vehicle_name VARCHAR (225),
seller VARCHAR (225),
offerType VARCHAR (225),
price INT,
abtest VARCHAR (225),
vehicleType VARCHAR (225),
yearOfRegistration INT,
gearbox VARCHAR (225),
powerPS INT,
kilometer INT,
monthOfRegistration INT,
fuelType VARCHAR (225),
notRepairedDamage VARCHAR (225),
nrOfPictures INT,
postalCode INT,
dateCrawlednew DATE,
dateCreatednew DATE,
lastSeennew DATE);


# and import it
SHOW TABLES;
LOAD DATA LOCAL INFILE "C:/vladperesad/excel_project/used_cars/autos_cleaned_r.csv"
INTO TABLE autos_cleaned_r
FIELDS TERMINATED BY ','
LINES TERMINATED BY '\n'
IGNORE 1 ROWS 
(id,
brand,
model,
vehicle_name,
seller,
offerType,
price,
abtest,
vehicleType,
yearOfRegistration,
gearbox,
powerPS,
kilometer,
monthOfRegistration,
fuelType,
notRepairedDamage,
nrOfPictures,
postalCode,
dateCrawlednew,
dateCreatednew,
lastSeennew);

SET GLOBAL local_infile=1;
SHOW GLOBAL VARIABLES LIKE 'local_infile';

#take a look at the table structure
DESCRIBE autos;

SELECT
	*
FROM
	autos_cleaned_r
LIMIT 10;
    
        
#create a working copy of the table that contains only columns that are needed for the analysis

DROP TABLE IF EXISTS autos_work;
CREATE TABLE autos_work
SELECT
	id,
    brand,
    model,
    vehicle_name,
    vehicleType AS vehicle_type,
    gearbox,
    powerPS AS horsepower,
    seller,
    price,
    fuelType AS fuel_type,
    kilometer AS kilometrage,
    notRepairedDamage AS present_damage,
    yearOfRegistration AS reg_year,
    monthOfRegistration AS reg_mon,
    dateCreatednew AS date_created,
    dateCrawlednew AS date_crawled,
    lastSeennew AS last_seen
FROM
	autos_cleaned_r
WHERE
	brand IS NOT NULL;
    
    
   
#take a look at the data values to make sure they're fine

SELECT
	MAX(LENGTH(date_created)) AS date_created_max,
    MIN(LENGTH(date_created)) AS date_created_min,
    MAX(LENGTH(date_crawled)) AS date_crawled_max,
    MIN(LENGTH(date_crawled)) AS date_crawled_min,
    MAX(LENGTH(last_seen)) AS last_seen_max,
    MIN(LENGTH(last_seen)) AS last_seen_min
FROM
	autos_work;
    
#with given format the date should be YYYY-MM-DD which is 10 digits, anything less or more than that must be wrong

#pull up DISTINCT values in brand column to see if theres any mistakes

SELECT
	DISTINCT(brand)
FROM
	autos_work;

#everything seems to look fine except for shorter way to name volkswagen - vw in some cells  
    
UPDATE autos_work
SET brand = 'volkswagen'
WHERE brand = 'vw';
    
#pull up number of rows with empty values in column model

SELECT
	COUNT(id)
FROM
	autos_work
WHERE model = '';

#and get rid of them

DELETE FROM autos_work
WHERE
	model = '';

#repeat the same steps with vehicle type
    
SELECT
	DISTINCT(vehicle_type)
FROM
	autos_work;

SELECT
	COUNT(id)
FROM
	autos_work
WHERE
	vehicle_type = '' OR vehicle_type IS NULL;
    
#since the body isn't that important and we have about 30k rows of missing data im just going to ingnore these missing values,
#but will translate the body types into English

UPDATE autos_work
SET vehicle_type = 'compact_car'
WHERE vehicle_type =  'kleinwagen';

UPDATE autos_work
SET vehicle_type = 'station_wagon'
WHERE vehicle_type =  'kombi';
    
UPDATE autos_work
SET vehicle_type = 'other'
WHERE vehicle_type =  'andere';

UPDATE autos_work
SET vehicle_type = NULL
WHERE vehicle_type = '';

DELETE FROM autos_work
WHERE
	vehicle_type = '177';

    
#same with gearbox
SELECT
	DISTINCT(gearbox)
FROM
	autos_work;
    
UPDATE autos_work
SET gearbox = 'automatic'
WHERE gearbox = 'automatik';

UPDATE autos_work
SET gearbox = 'manual'
WHERE gearbox = 'manuell';

UPDATE autos_work
SET gearbox = NULL
WHERE gearbox = '';

#take a look at the horsepower values

SELECT
	MAX(horsepower),
    MIN(horsepower)
FROM
	autos_work;
    
#clearly it is highly inlikely that there is a civillian car that outputs 20000 BHP
#600 is the average maximum that civilian cars are capable of, so lets take a look of what vehicles are represented in the group 600+

SELECT
	brand,
    model,
    horsepower
FROM
	autos_work
WHERE
	horsepower > 600
ORDER BY 
	horsepower;
    
#while Audi RS6 is definitely capable of producing 750 hp, fiat brava with 1.6 is definitely not
#i am going to filter out records that have horsepower of above 600 hp AND brands that are not popular with producng high performance cars
#such as ('volkswagen','skoda','peugeot','ford','renault','opel','seat','citroen','fiat','mini','smart',
#'hyundai','volvo','kia','suzuki','dacia','daihatsu','daewoo','rover','saab','trabant','lada')


DELETE FROM
	autos_work
WHERE
	horsepower> 400 AND
    brand IN ('skoda','peugeot','renault','opel','seat','citroen','fiat','mini','smart',
'hyundai','volvo','kia','suzuki','dacia','daihatsu','daewoo','rover','saab','trabant','lada')
ORDER BY brand;


#the rest of the cars can be filtered out with the horsepower treshold of 850 horsepower

DELETE FROM
	autos_work
WHERE
	horsepower >850;
    
# lets make 10hp a bottom treshhold for cars and filter out everything thats lower than that
DELETE FROM
	autos_work
WHERE
	horsepower <10;
    
#take a look at the price range
SELECT
	MAX(price),
    MIN(price)
FROM
	autos_work;
    
# remove records with 0 
DELETE FROM
	autos_work
WHERE
	price = 0;
    
#in terms of upper limit, models and prices above 745000 don't make much sense (numbers like 911911, 123456 or 999999)
    

DELETE FROM
	autos_work
WHERE
	price > 745000;
    
SELECT
	*
FROM
	autos_work
WHERE
	price <1000
ORDER BY price;

#prices below 1000 are probably connected with the condition of the car (totalled, seriously damaged etc)
#get back to the prices when i'm done with the damage column

SELECT
	DISTINCT(present_damage)
FROM
	autos_work;
    
SELECT
	COUNT(id)
FROM
	autos_work
WHERE
	present_damage = '';
    
#46044 rows with missing value for damage, but since it is an important information and there is no way 
#i can derive it from other columns, i'll simply have to delete it 
#prior to that turn ja and nein into true and false

UPDATE autos_work
SET present_damage = '1'
WHERE present_damage = 'ja';

UPDATE autos_work
SET present_damage = '0'
WHERE present_damage = 'nein';
 
UPDATE autos_work
SET present_damage = NULL
WHERE present_damage = '';
 
ALTER TABLE autos_work
MODIFY present_damage TINYINT(1);

DELETE FROM autos_work
WHERE present_damage IS NULL;
    
#get back to prices

#looking at european websites with sencod hand cars revealed that prices for damaged cars tend to start from 300 euros up, 
#while for cars that don't have damage the prices start at arount 500 euros



DELETE FROM
	autos_work
WHERE
	price <300 AND present_damage = 1;
    
DELETE FROM
	autos_work
WHERE
	price <500 AND present_damage =0;

#seller

SELECT
	DISTINCT(seller)
FROM
	autos_work;
    
UPDATE autos_work
SET seller = 'private'
WHERE seller = 'privat';
    
UPDATE autos_work
SET seller = 'commercial'
WHERE seller = 'gewerblich';


#take a look at the fuel coulumn

SELECT
	DISTINCT(fuel_type)
FROM
	autos_work;
    
UPDATE autos_work 
SET fuel_type = 'gasoline'
WHERE fuel_type = 'benzin';

UPDATE autos_work
SET fuel_type = 'other'
WHERE fuel_type = 'andere';

UPDATE autos_work
SET fuel_type = 'electric'
WHERE fuel_type = 'elektro';

UPDATE autos_work
SET fuel_type = NULL
WHERE fuel_type = '';

#pull up min and max values in kilometrage column    
SELECT
	MIN(kilometrage),
    MAX(kilometrage)
FROM
	autos_work;
    
#the min and max values seem to make sense

#finally take a look at the year and month of registration

SELECT
	MAX(reg_year),
    MIN(reg_year)
FROM
	autos_work;
    
#while 1910 is technically possible, anything after 2019 is not 
#clean up any value larger than 2019 and take a closer look at cars before 1950

DELETE FROM autos_work
WHERE reg_year > 2016;

SELECT
	brand,
    model,
    vehicle_name,
    horsepower,
    reg_year
FROM
	autos_work
WHERE
	reg_year < 1930
ORDER BY reg_year;

#the only car that doesn't fit is a vw beetle with TDI angine that produces 90hp, not only because in 1910
#there wasn't such a thing as TDI, and hp of 90 was unheard of for 1.9 litre engine but also because first wv beetle was made in 1965 

DELETE FROM autos_work
WHERE reg_year <1928;

#let's look at the months avaliable 

SELECT
	DISTINCT(reg_mon)
FROM
	autos_work
ORDER BY 
	reg_mon;

#get rid of the 0 months

DELETE FROM
	autos_work
WHERE
	reg_mon = 0;
    
SELECT
	*
FROM
	autos_work;

#create a table that counts each brand

DROP TABLE IF EXISTS count_of_brand;
CREATE TABLE count_of_brand
SELECT
	brand,
    COUNT(brand) AS brand_count
FROM
	autos_work
GROUP BY brand
ORDER BY COUNT(brand) DESC;

    
#create a new column and put concatenated year and month in there

DROP TABLE IF EXISTS autos_cleaned_sql;
CREATE TABLE autos_cleaned_sql
SELECT
	id,
    aw.brand,
    model,
    vehicle_type,
    gearbox,
    horsepower,
    price,
    fuel_type,
    kilometrage,
    present_damage,
    CONCAT(reg_year,'-',reg_mon) AS reg_date,
    date_created,
    last_seen
FROM
	autos_work AS aw
    INNER JOIN count_of_brand AS cob ON aw.brand = cob.brand
WHERE
	brand_count >100;

UPDATE autos_cleaned_sql
SET reg_date = STR_TO_DATE(reg_date,'%Y-%m');

ALTER TABLE autos_cleaned_sql
CHANGE COLUMN reg_date date_reg DATE;

UPDATE autos_cleaned_sql
SET date_reg = date_format(date_reg,'%Y-%m-01');


SELECT
	*
FROM
	autos_cleaned_sql;
    

    
SELECT
	*,
	datediff(date_created,date_reg) AS car_age_days,
    datediff(last_seen,date_created) AS for_sale_days
    
FROM
	autos_cleaned_sql;