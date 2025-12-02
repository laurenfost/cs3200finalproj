USE ca_emergency_dep;


-- which counties have the most hospitals
SELECT county, COUNT(*) AS num_hospitals
FROM hospitals
GROUP BY county
ORDER BY num_hospitals DESC
LIMIT 3;

-- which hospitals have the highest amount of average visits per station 
SELECT h.hospital_name, h.county, ROUND(AVG(v.visits_per_station), 2) AS 'avg_visits_per_station'
FROM ed_visits v
JOIN hospitals h ON h.hospital_id = v.hospital_id
GROUP BY h.hospital_id
ORDER BY avg_visits_per_station DESC
LIMIT 10;

-- which counties have the hospitals with the lowest # of visits/station
SELECT h.hospital_name, h.county, ROUND(AVG(v.visits_per_station), 2) AS 'avg_visits_per_station'
FROM ed_visits v
JOIN hospitals h ON h.hospital_id = v.hospital_id
GROUP BY h.hospital_id
ORDER BY avg_visits_per_station ASC
LIMIT 10;

-- compare avg # visits/station for rural, urban, and frontier hospitals 
SELECT c.urban_rural_classification, ROUND(AVG(v.visits_per_station), 2) AS 'avg_visits_per_station'
FROM characteristics c
JOIN ed_visits v ON v.hospital_id = c.hospital_id
GROUP BY c.urban_rural_classification;

-- is the avg # visits/station increasing, dec, or staying the same from 2021-2023
SELECT year, ROUND(AVG(visits_per_station), 2) AS 'avg_visits_per_station'
FROM ed_visits
GROUP BY year
ORDER BY year ASC;

-- did avg # visits/station for COVID cases change over 2021-2023
SELECT v.year, ROUND(AVG(v.visits_per_station), 2) AS 'avg_visits_per_station'
FROM ed_visits v
JOIN visit_type vt 
      ON vt.category_id = v.category_id
WHERE vt.category_name = 'Active COVID-19'
GROUP BY v.year
ORDER BY v.year;

-- do non-profit or government ran hopsitals have a higher avg # visits/station 
SELECT c.ownership, ROUND(AVG(v.visits_per_station), 2) AS 'avg_visits_per_station'
FROM characteristics c
JOIN ed_visits v ON v.hospital_id = c.hospital_id
GROUP BY c.ownership
ORDER BY avg_visits_per_station DESC;

-- top 5 health conditions with highest and lowest avg # visits/station 
SELECT vt.category_name, ROUND(AVG(v.visits_per_station), 2) AS 'avg_visits_per_station'
FROM ed_visits v
JOIN visit_type vt ON vt.category_id = v.category_id
GROUP BY vt.category_name
ORDER BY avg_visits_per_station DESC
LIMIT 5;

SELECT vt.category_name,
       ROUND(AVG(v.visits_per_station), 2) AS 'avg_visits_per_station'
FROM ed_visits v
JOIN visit_type vt ON vt.category_id = v.category_id
GROUP BY vt.category_name
ORDER BY avg_visits_per_station ASC
LIMIT 5;

-- compare avg # visits/station for primary care shortage areas and non shortage
SELECT s.in_mental_health_shortage AS mental_health_shortage_area,
       ROUND(AVG(v.visits_per_station), 2) AS 'avg_visits_per_station'
FROM shortage_designations s
JOIN ed_visits v ON v.hospital_id = s.hospital_id
GROUP BY s.in_mental_health_shortage;

-- compare avg # visits/station for mental health shortage areas and non shortage
SELECT s.in_primary_care_shortage,
       ROUND(AVG(v.visits_per_station), 2) AS 'avg_visits_per_station'
FROM shortage_designations s
JOIN ed_visits v ON v.hospital_id = s.hospital_id
GROUP BY s.in_primary_care_shortage;

-- which counties are both primary care shortage areas and mental health shortage areas
SELECT DISTINCT h.county
FROM shortage_designations s
JOIN hospitals h ON h.hospital_id = s.hospital_id
WHERE s.in_primary_care_shortage = 1 AND s.in_mental_health_shortage = 1
ORDER BY h.county;

-- largest average ED visit increase 
SELECT 
	DISTINCT(h.hospital_name),
    e.earliest_year,
    l.latest_year,
    e.total_earliest,
    l.total_latest,
    (l.total_latest - e.total_earliest) / (l.latest_year - e.earliest_year) AS 'avg_yearly_increase'
FROM hospitals h
JOIN (
	-- earliest year + total visits in that year 
    SELECT t.hospital_id,
		t.year AS earliest_year,
        (SELECT SUM(ed_visits_by_category)
			FROM ed_visits
            WHERE hospital_id = t.hospital_id
				AND year = t.year) AS 'total_earliest'
	FROM ed_visits t
    WHERE t.year = (
		SELECT MIN(year)
        FROM ed_visits
		WHERE hospital_id = t.hospital_id
        )
     ) AS e
  ON h.hospital_id = e.hospital_id
JOIN (
	-- latest year + total visits in that year
	SELECT t.hospital_id,
		t.year AS latest_year,
        (SELECT SUM(ed_visits_by_category)
			FROM ed_visits
			WHERE hospital_id = t.hospital_id
                  AND year = t.year) AS 'total_latest'
	FROM ed_visits t
	WHERE t.year = (
		SELECT MAX(year)
		FROM ed_visits
		WHERE hospital_id = t.hospital_id
		)
     ) AS l
     ON h.hospital_id = l.hospital_id
WHERE l.latest_year > e.earliest_year   
ORDER BY avg_yearly_increase DESC;

-- hospitals that weren't visited by AT LEAST one category visit 
SELECT 
	h.hospital_id,
    h.hospital_name,
    COUNT(v.category_id) AS 'num_missing'
FROM hospitals h
CROSS JOIN visit_type v
LEFT JOIN hospital_visit_type hvt
    ON hvt.hospital_id = h.hospital_id
		AND hvt.category_id = v.category_id
WHERE hvt.category_id IS NULL
GROUP BY h.hospital_id, h.hospital_name
ORDER BY num_missing DESC;

-- find total of ED visits that were uncategorized/unkown
SELECT 
    h.hospital_name,
    t.year,
    t.total AS total_visits,
    IFNULL(SUM(v.ed_visits_by_category), 0) AS 'categorized_visits',
    t.total - IFNULL(SUM(v.ed_visits_by_category), 0) AS 'unkown_visits'
FROM total_ed_encounters t
LEFT JOIN ed_visits v
    ON t.hospital_id = v.hospital_id
   AND t.year = v.year
JOIN hospitals h
    ON h.hospital_id = t.hospital_id
GROUP BY h.hospital_name, t.year, t.total
HAVING uncategorized_visits > 0
ORDER BY h.hospital_name, t.year;






