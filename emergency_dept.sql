show variables where variable_name like '%local%';

set global local_infile=ON;


DROP DATABASE IF EXISTS ca_emergency_dep;
CREATE DATABASE ca_emergency_dep;


USE ca_emergency_dep;

CREATE TABLE emergency_dept (
oshpd_id int,
FacilityName2 text,
CountyName text,
systemName text
);

LOAD DATA LOCAL 
INFILE '/Users/annatang/Downloads/ed.csv'
INTO TABLE emergency_dept
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' -- terminated by ';' in orig
IGNORE 1 ROWS;

SELECT * FROM emergency_dept;