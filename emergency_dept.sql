show variables where variable_name like '%local%';

set global local_infile=ON;


DROP DATABASE IF EXISTS ca_emergency_dep;
CREATE DATABASE ca_emergency_dep;
USE ca_emergency_dep;

-- TEMP TABLE for initial data import
DROP TABLE IF EXISTS temp;
CREATE TABLE temp (
    hospital_id INT,
    hospital_name VARCHAR(255),
    county VARCHAR(255),
    hospital_system VARCHAR(255),
    year YEAR,
    ed_capacity VARCHAR(50),
    ownership VARCHAR(100),
    urban_rural_classification VARCHAR(50),
    is_teaching VARCHAR(50),
    health_condition VARCHAR(50),
    ed_encounter_total INT,
    ed_station_count INT,
    ed_visits_by_category INT,
    LATITUDE DECIMAL(10,6),
    LONGITUDE DECIMAL(10,6),
    in_primary_care_shortage VARCHAR(10),
    in_mental_health_shortage VARCHAR(10),
    visits_per_station FLOAT
);

-- LOAD CSV 
LOAD DATA LOCAL 
INFILE 'C:/Users/laure/OneDrive/Documents/cs3200/final_proj/emergency_dept.csv'
INTO TABLE temp
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' -- terminated by ';' in orig
IGNORE 1 ROWS; 

-- Checks
SELECT COUNT(*) FROM temp;

-- HOSPITALS TABLE
DROP TABLE IF EXISTS hospitals;

CREATE TABLE hospitals (
	hospital_id INT PRIMARY KEY,
    hospital_name VARCHAR(255),
    county VARCHAR(255),
    hospital_system VARCHAR(255),
    LATITUDE DECIMAL(10,6),
	LONGITUDE DECIMAL(10,6)
);

INSERT INTO hospitals (hospital_id,
    hospital_name,
    county,
    hospital_system,
    LONGITUDE,
    LATITUDE)
SELECT hospital_id, 
	MIN(hospital_name) AS hospital_name,
    MIN(county) AS county,
    MIN(hospital_system) AS hospital_system,
    MIN(LATITUDE) AS LATITUDE,
    MIN(LONGITUDE) AS LONGITUDE
FROM temp
GROUP BY hospital_id;

-- CHARACTERISTICS TABLE
DROP TABLE IF EXISTS characteristics;

CREATE TABLE characteristics (
	hospital_id INT PRIMARY KEY,
    ed_capacity VARCHAR(50),
    ownership VARCHAR(100),
    urban_rural_classification VARCHAR(50),
    is_teaching VARCHAR(50),
    FOREIGN KEY (hospital_id) REFERENCES hospitals(hospital_id)
);

INSERT INTO characteristics (hospital_id,
    ed_capacity,
    ownership,
    urban_rural_classification,
    is_teaching)
SELECT
	hospital_id,
    MIN(ed_capacity) AS ed_capacity,
    MIN(ownership) AS ownership,
    MIN(urban_rural_classification) AS urban_rural_classification,
    MIN(is_teaching) AS is_teaching
FROM temp
GROUP BY hospital_id;

SELECT *
FROM characteristics;

-- SHORTAGE DESIGNATIONS
DROP TABLE IF EXISTS shortage_designations;

CREATE TABLE shortage_designations (
	hospital_id INT PRIMARY KEY,
    in_primary_care_shortage VARCHAR(10),
    in_mental_health_shortage VARCHAR(10),
    FOREIGN KEY (hospital_id) REFERENCES hospitals(hospital_id)
);

INSERT INTO shortage_designations (hospital_id, in_primary_care_shortage, in_mental_health_shortage)
SELECT hospital_id,
	MIN(in_primary_care_shortage) AS in_primary_care_shortage,
    MIN(in_mental_health_shortage) AS in_mental_health_shortage
FROM TEMP
GROUP BY hospital_id;

SELECT * 
FROM shortage_designations;

DROP TABLE IF EXISTS visit_type;
CREATE TABLE visit_type (
	category_id INT AUTO_INCREMENT PRIMARY KEY,
    category_name VARCHAR(50) UNIQUE
);

INSERT INTO visit_type (category_name)
SELECT DISTINCT health_condition FROM temp;

SELECT *
FROM visit_type;

-- ED CAPACITY TABLE (per year)
DROP TABLE IF EXISTS ed_capacity;

CREATE TABLE ed_capacity (
	hospital_id INT,
    year YEAR,
    ed_station_count INT,
    PRIMARY KEY (hospital_id, year)
);
INSERT INTO ed_capacity (hospital_id, year, ed_station_count)
SELECT DISTINCT hospital_id, year, ed_station_count
FROM temp;

SELECT * FROM ed_capacity;

-- ED VISITS TABLE (per year per category)
DROP TABLE IF EXISTS ed_visits;
CREATE TABLE ed_visits (
	hospital_id INT,
    year YEAR,
    category_id INT,
    ed_encounter_total INT,
    ed_visits_by_category INT,
    visits_per_station FLOAT,
    PRIMARY KEY (hospital_id, year, category_id)
);

INSERT INTO ed_visits (hospital_id,
    year,
    category_id,
    ed_encounter_total,
    ed_visits_by_category,
    visits_per_station)
SELECT t.hospital_id, t.year, v.category_id, t.ed_encounter_total, t.ed_visits_by_category, t.visits_per_station
FROM temp t
JOIN visit_type v
	ON t.health_condition = v.category_name;
SELECT *
FROM ed_visits;

-- HOSPITAL-VISIT TYPE TABLE 
DROP TABLE IF EXISTS hospital_visit_type;

CREATE TABLE hospital_visit_type (
	hospital_id INT,
    category_id INT,
    PRIMARY KEY (hospital_id, category_id)
);
INSERT INTO hospital_visit_type (hospital_id, category_id)
SELECT DISTINCT t.hospital_id, v.category_id
FROM temp t
JOIN visit_type v
	ON t.health_condition = v.category_name;
    
SELECT * FROM hospital_visit_type;