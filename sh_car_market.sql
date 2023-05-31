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
	LENGTH(date_created) <>10;
   
DELETE FROM autos_cleaned
WHERE
	LENGTH(date_created) <>10;

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
    
#get rid of the columns with original dates in VARHCAR

ALTER TABLE autos_cleaned
DROP COLUMN date_created,
DROP COLUMN date_crawled,
DROP COLUMN last_seen;

DESCRIBE
	autos_cleaned;
 
 #last 3 colums are DATE type (check)
    
#pull up DISTINCT values in brand column to see if theres any mistakes
    
SELECT
	DISTINCT(brand)
FROM
	autos_cleaned;

#do the same with the model column
    
SELECT
	DISTINCT(model)
FROM
	autos_cleaned;
    
#pull up number of rows with empty values in column model

SELECT
	COUNT(id)
FROM
	autos_cleaned
WHERE model = "";

#and get rid of them

DELETE FROM autos_cleaned
WHERE
	model = "";

#repeat the same steps with vehicle type
    
SELECT
	DISTINCT(vehicle_type)
FROM
	autos_cleaned;

SELECT
	COUNT(id)
FROM
	autos_cleaned
WHERE
	vehicle_type = "";
    
#since the body isn't that important and we have abou 30k rows of missing data im just going to ingnore these missing values,
#but will translate the body types into English

UPDATE autos_cleaned
SET vehicle_type = 'compact_car'
WHERE vehicle_type =  'kleinwagen';

UPDATE autos_cleaned
SET vehicle_type = 'station_wagon'
WHERE vehicle_type =  'kombi';
    
UPDATE autos_cleaned
SET vehicle_type = 'other'
WHERE vehicle_type =  'andere';

#check that the conversion worked out as intended
SELECT
	DISTINCT(vehicle_type)
FROM
	autos_cleaned;

#same with gearbox
SELECT
	DISTINCT(gearbox)
FROM
	autos_cleaned;
    
UPDATE autos_cleaned
SET gearbox = 'automatic'
WHERE gearbox = 'automatik';

UPDATE autos_cleaned
SET gearbox = 'manual'
WHERE gearbox = 'manuell';

#take a look at the horsepower values
#in order to do that we need first to turn strings into numerical values

ALTER TABLE autos_cleaned
MODIFY power INT;

SELECT
	MAX(power),
    MIN(power)
FROM
	autos_cleaned;
    
#clearly it is highly inlikely that there is a civillian car that outputs 20000 BHP
#600 is the average maximum that civilian cars are capable of, so lets take a look of what vehicles are represented in the group 600+

SELECT
	*
FROM
	autos_cleaned
WHERE
	power > 600
ORDER BY 
	power;
    
# while Audi RS6 is definitely capable of producing 750 hp, fiat brava with 1.6 is definitely not
# i am going to filter out records that have horsepower of above 600 hp AND brands that are not popular with producng high performance cars
# such as ('volkswagen''skoda''peugeot''ford''renault''opel''seat''citroen''fiat''mini''smart'
#'hyundai''volvo''kia''suzuki''dacia''daihatsu''daewoo''rover''saab''trabant''lada')


DELETE FROM
	autos_cleaned
WHERE
	power > 400 AND
    brand IN ('skoda','peugeot','renault','opel','seat','citroen','fiat','mini','smart',
'hyundai','volvo','kia','suzuki','dacia','daihatsu','daewoo','rover','saab','trabant','lada')
ORDER BY brand;


#the rest of the cars can be filtered out with the horsepower treshold of 850 horsepower

DELETE FROM
	autos_cleaned
WHERE
	power >850;
    
# lets make 10hp a bottom treshhold for cars and filter out everything thats lower than that
DELETE FROM
	autos_cleaned
WHERE
	power <10;
    
# let's turn columns id, price, mileage to INT type as well   

ALTER TABLE autos_cleaned
MODIFY id INT,
MODIFY price INT,
MODIFY mileage INT;

SELECT
	MAX(price),
    MIN(price)
FROM
	autos_cleaned;
    
	



#---