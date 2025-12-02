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
    latitude  DECIMAL(10,6),
    longitude DECIMAL(10,6),
    in_primary_care_shortage VARCHAR(10),
    in_mental_health_shortage VARCHAR(10),
    visits_per_station FLOAT
);

-- LOAD CSV 
LOAD DATA LOCAL 
INFILE '/Users/annatang/Downloads/ed.csv'
-- INFILE 'C:/Users/laure/OneDrive/Documents/cs3200/final_proj/emergency_dept.csv'
INTO TABLE temp
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' -- terminated by ';' in orig
IGNORE 1 ROWS; 

-- Checks
SELECT COUNT(*) FROM temp;

-- HOSPITALS TABLE
-- contains unique hospital-level information
-- uses ROW_NUMBER to avoid duplicates in the temp data
DROP TABLE IF EXISTS hospitals;

CREATE TABLE hospitals (
	hospital_id INT PRIMARY KEY,
    hospital_name VARCHAR(255),
    county VARCHAR(255),
    hospital_system VARCHAR(255),
    latitude DECIMAL(10, 3),
	longitude DECIMAL(10,3)
);

INSERT INTO hospitals (hospital_id, hospital_name, county, hospital_system, latitude, longitude)
SELECT hospital_id,
       hospital_name,
       county,
       hospital_system,
       ROUND(latitude, 3),
       ROUND(longitude, 3)
FROM (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY hospital_id ORDER BY hospital_name) AS rn
    FROM temp
) AS t
WHERE rn = 1;

-- CHARACTERISTICS TABLE
-- stores 1:1 attributes: capacity, ownership, rural/urban, teaching status
DROP TABLE IF EXISTS characteristics;

CREATE TABLE characteristics (
	hospital_id INT PRIMARY KEY,
    ed_capacity VARCHAR(50),
    ownership ENUM('Government', 'Investor Owned', 'Nonprofit'),
    urban_rural_classification ENUM('Urban', 'Rural', 'Frontier'),
    is_teaching TINYINT(1),
    FOREIGN KEY (hospital_id) REFERENCES hospitals(hospital_id)
);

INSERT INTO characteristics (
    hospital_id, ed_capacity, ownership, urban_rural_classification, is_teaching
)
SELECT hospital_id,
       ed_capacity,
       CASE
           WHEN LOWER(TRIM(ownership)) = 'government' THEN 'Government'
           WHEN LOWER(TRIM(ownership)) = 'investor owned' THEN 'Investor Owned'
           WHEN LOWER(TRIM(ownership)) = 'nonprofit' THEN 'Nonprofit'
           ELSE NULL
       END,
       CASE
           WHEN LOWER(TRIM(urban_rural_classification)) = 'urban' THEN 'Urban'
           WHEN LOWER(TRIM(urban_rural_classification)) = 'rural' THEN 'Rural'
           WHEN LOWER(TRIM(urban_rural_classification)) = 'frontier' THEN 'Frontier'
       END,
       CASE WHEN is_teaching = 'Teaching' THEN 1 ELSE 0 END
FROM (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY hospital_id ORDER BY hospital_id) AS rn
    FROM temp
) AS t
WHERE rn = 1;

SELECT *
FROM characteristics;

-- SHORTAGE DESIGNATIONS
-- maps shortage indicators into numeric 0/1 values
-- 1 IFF Yes
-- 0 IFF No or N/A
DROP TABLE IF EXISTS shortage_designations;

CREATE TABLE shortage_designations (
	hospital_id INT PRIMARY KEY,
    in_primary_care_shortage TINYINT(1),
    in_mental_health_shortage TINYINT(1),
    FOREIGN KEY (hospital_id) REFERENCES hospitals(hospital_id));

INSERT INTO shortage_designations (hospital_id, in_primary_care_shortage, in_mental_health_shortage)
SELECT hospital_id,
       CASE WHEN in_primary_care_shortage = 'Yes' THEN 1 ELSE 0 END,
       CASE WHEN in_mental_health_shortage = 'Yes' THEN 1 ELSE 0 END
FROM (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY hospital_id ORDER BY hospital_id) AS rn
    FROM temp
) t
WHERE rn = 1;

SELECT * 
FROM shortage_designations;

-- VISIT TYPE TABLE
-- list of unique ED visit categories (ex: Asthma, Active COVID-19, Mental Health etc.)
DROP TABLE IF EXISTS visit_type;
CREATE TABLE visit_type (
	category_id INT AUTO_INCREMENT PRIMARY KEY,
    category_name VARCHAR(50) UNIQUE
);

INSERT INTO visit_type (category_name)
SELECT DISTINCT health_condition FROM temp
WHERE health_condition != 'All ED Visits';

SELECT *
FROM visit_type;

-- ED CAPACITY TABLE (per year)
-- yearly ED station availability per hospital
DROP TABLE IF EXISTS ed_capacity;

CREATE TABLE ed_capacity (
	hospital_id INT,
    year YEAR,
    ed_station_count INT,
    PRIMARY KEY (hospital_id, year),
    FOREIGN KEY (hospital_id) REFERENCES hospitals(hospital_id));
    
INSERT INTO ed_capacity
SELECT DISTINCT hospital_id, year, ed_station_count
FROM temp;

SELECT * FROM ed_capacity;

-- ED VISITS TABLE (per year by category)
-- stores number of visits per year by category by hospital
DROP TABLE IF EXISTS ed_visits;

CREATE TABLE ed_visits (
    hospital_id INT,
    year YEAR,
    category_id INT,
    ed_visits_by_category INT,
    visits_per_station FLOAT,
    PRIMARY KEY (hospital_id, year, category_id),
    FOREIGN KEY (hospital_id) REFERENCES hospitals(hospital_id),
    FOREIGN KEY (category_id) REFERENCES visit_type(category_id)
);

INSERT INTO ed_visits
SELECT t.hospital_id,
       t.year,
       v.category_id,
       t.ed_visits_by_category,
       t.visits_per_station
FROM temp t
JOIN visit_type v ON t.health_condition = v.category_name
WHERE t.health_condition != 'All ED Visits';

SELECT *
FROM ed_visits;

-- HOSPITAL VISIT TYPE TABLE 
-- specifies which hospitals have seen what categories
DROP TABLE IF EXISTS hospital_visit_type;

CREATE TABLE hospital_visit_type (
    hospital_id INT,
    category_id INT,
    PRIMARY KEY (hospital_id, category_id),
    FOREIGN KEY (hospital_id) REFERENCES hospitals(hospital_id),
    FOREIGN KEY (category_id) REFERENCES visit_type(category_id)
);

INSERT INTO hospital_visit_type
SELECT DISTINCT t.hospital_id, v.category_id
FROM temp t
JOIN visit_type v ON t.health_condition = v.category_name;
    
SELECT * FROM hospital_visit_type;

-- TOTAL ED ENCOUNTERS
-- stores the total ED encounters
DROP TABLE IF EXISTS total_ed_encounters;

CREATE TABLE total_ed_encounters (
    hospital_id INT,
    year YEAR,
    total INT,
    PRIMARY KEY (hospital_id, year),
    FOREIGN KEY (hospital_id) REFERENCES hospitals(hospital_id)
);

INSERT INTO total_ed_encounters (hospital_id, year, total)
SELECT hospital_id,
       year,
       ed_encounter_total
FROM temp
WHERE health_condition = 'All ED Visits';

SELECT *
FROM total_ed_encounters;
