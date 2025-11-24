USE ca_emergency_dep;


-- which counties have the most hospitals
SELECT county, COUNT(*) AS num_hospitals
FROM hospitals
GROUP BY county
ORDER BY num_hospitals DESC
LIMIT 3;

-- which hospitals have the highest amount of average visits per station 
SELECT h.hospital_name, h.county, ROUND(AVG(v.visits_per_station), 2) AS avg_visits_per_station
FROM ed_visits v
JOIN hospitals h ON h.hospital_id = v.hospital_id
GROUP BY h.hospital_id
ORDER BY avg_visits_per_station DESC
LIMIT 10;

-- which counties have the hospitals with the lowest # of visits/station
SELECT h.hospital_name, h.county, ROUND(AVG(v.visits_per_station), 2) AS avg_visits_per_station
FROM ed_visits v
JOIN hospitals h ON h.hospital_id = v.hospital_id
GROUP BY h.hospital_id
ORDER BY avg_visits_per_station ASC
LIMIT 10;

-- compare avg # visits/station for rural, urban, and frontier hospitals 
SELECT c.urban_rural_classification, ROUND(AVG(v.visits_per_station), 2) AS avg_visits_per_station
FROM characteristics c
JOIN ed_visits v ON v.hospital_id = c.hospital_id
GROUP BY c.urban_rural_classification;

-- is the avg # visits/station increasing, dec, or staying the same from 2021-2023
SELECT year, ROUND(AVG(visits_per_station), 2) AS avg_visits_per_station
FROM ed_visits
GROUP BY year
ORDER BY year ASC;

-- did avg # visits/station for COVID cases change over 2021-2023
SELECT v.year, ROUND(AVG(v.visits_per_station), 2) AS avg_visits_per_station
FROM ed_visits v
JOIN visit_type vt 
      ON vt.category_id = v.category_id
WHERE vt.category_name = 'Active COVID-19'
GROUP BY v.year
ORDER BY v.year;

-- do non-profit or government ran hopsitals have a higher avg # visits/station 
SELECT c.ownership, ROUND(AVG(v.visits_per_station), 2) AS avg_visits_per_station
FROM characteristics c
JOIN ed_visits v ON v.hospital_id = c.hospital_id
GROUP BY c.ownership
ORDER BY avg_visits_per_station DESC;

-- top 5 health conditions with best and worst avg # visits/station 
SELECT vt.category_name, ROUND(AVG(v.visits_per_station), 2) AS avg_visits_per_station
FROM ed_visits v
JOIN visit_type vt ON vt.category_id = v.category_id
GROUP BY vt.category_name
ORDER BY avg_visits_per_station DESC
LIMIT 5;

SELECT vt.category_name,
       ROUND(AVG(v.visits_per_station), 2) AS avg_visits_per_station
FROM ed_visits v
JOIN visit_type vt ON vt.category_id = v.category_id
GROUP BY vt.category_name
ORDER BY avg_visits_per_station ASC
LIMIT 5;

-- compare avg # visits/station for primary care shortage areas and non shortage
SELECT s.in_primary_care_shortage AS primary_care_shortage_area,
       ROUND(AVG(v.visits_per_station), 2) AS avg_visits_per_station
FROM shortage_designations s
JOIN ed_visits v ON v.hospital_id = s.hospital_id
GROUP BY s.in_primary_care_shortage;

-- compare avg # visits/station for mental health shortage areas and non shortage
SELECT s.in_mental_health_shortage AS mental_health_shortage_area,
       ROUND(AVG(v.visits_per_station), 2) AS avg_visits_per_station
FROM shortage_designations s
JOIN ed_visits v ON v.hospital_id = s.hospital_id
GROUP BY s.in_mental_health_shortage;

-- which counties are both primary care shortage areas and mental health shortage areas
SELECT DISTINCT h.county
FROM shortage_designations s
JOIN hospitals h ON h.hospital_id = s.hospital_id
WHERE s.in_primary_care_shortage = 'Yes' AND s.in_mental_health_shortage = 'Yes'
ORDER BY h.county;


