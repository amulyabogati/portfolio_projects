/****************************************************************************************************
	Apartment hunting for final session of MBA program.
	
	Skills used:
		> SQL fundamental: table creation, data manipulation, aggregation, grouping, and filtering.
		> SQL advanced: CTE, window function, temp tables, and join operations.
		> Data transformation: converting data types, formulas for calculation and conversions.
		> Statistical analysis: calculate averages, standard deviations, and random variables.
****************************************************************************************************/

/****************************************************************************************************
Step 1: Create tables
****************************************************************************************************/

CREATE TABLE IF NOT EXISTS uszips (
	zip_code VARCHAR(255) PRIMARY KEY
	,latitude DECIMAL(9,6)
	,longitude DECIMAL(9,6)
	,state_id VARCHAR(255)
	,population INT
	,density DECIMAL(9,1)
	,county_fips VARCHAR(255)
	,county_name VARCHAR(255)
);

CREATE TABLE IF NOT EXISTS fy24_fmrs (
	state_id VARCHAR(255)
	,county_name VARCHAR(255)
	,county_fips VARCHAR(255) PRIMARY KEY
	,bhk1_rent INT
);

/****************************************************************************************************
Step 2: Analyze zip code dataset
****************************************************************************************************/

SELECT
	COUNT(DISTINCT zip_code)
	FROM uszips
	WHERE state_id = 'CA';
--	33788 unique zip codes; 1802 zip codes in California

SELECT
	COUNT(DISTINCT county_name)
	FROM uszips
	WHERE state_id = 'CA';
-- all 58 counties from CA are present

SELECT
	DISTINCT(county_name)
	,AVG(density) OVER (PARTITION BY county_name )::INT AS county_density
	,AVG(density) OVER (PARTITION BY state_id)::INT AS state_density
	FROM uszips
	WHERE state_id = 'CA'
	ORDER BY county_density DESC;
-- orange county is rather densely populated compared to most CA counties
-- if possible, prioritize neighboring counties

/****************************************************************************************************
Step 3: Analyze rental dataset
****************************************************************************************************/

SELECT AVG(bhk1_rent) FROM fy24_fmrs;

SELECT
	state_id
	,AVG(bhk1_rent)::INT AS avg_rent
	,STDDEV(bhk1_rent)::INT AS std_rent
	FROM fy24_fmrs
	GROUP BY state_id
	ORDER BY avg_rent DESC;
-- CA has among highest average rent ($1488 v $866 (US avg))
-- but, std dev is also high, so look at opportunities for financially feasible places

SELECT
	county_name
	,bhk1_rent
	,AVG(bhk1_rent) OVER(PARTITION BY state_id)::INT AS state_avg
	FROM fy24_fmrs
	WHERE state_id = 'CA'
	ORDER BY bhk1_rent DESC;

/****************************************************************************************************
Step 4: Calculate distances
****************************************************************************************************/

/*
	find distance between given coordinates and university using great circle formula, steps:
	> convert coordinates to radians by multiplying the coordinates by pi/180
	> distance = 2r * arcsin(sqrt(sin^2((lat2 - lat1) / 2) + cos(lat1) * cos(lat2) * sin^2((lon2 - lon1) / 2)))
	> coordinates for Westciff University is 33.6856 N, 117.8481 W
	> radius of the earth is 6371 km
*/

-- function to convert coordinates in degrees to radians
CREATE OR REPLACE FUNCTION deg_to_rad(coords DECIMAL(9,6))
	RETURNS DECIMAL(9,6) AS $$
		BEGIN
			RETURN coords * PI() / 180;
		END;
	$$
	LANGUAGE PLPGSQL;

-- function to calculate Haversine distance from university
CREATE OR REPLACE FUNCTION calculate_distance(latitude DECIMAL(9,6), longitude DECIMAL(9M6))
	RETURNS DECIMAL(9,1) AS $$
		DECLARE
			lat1 DECIMAL(9,6);
			lat2 DECIMAL(9,6);
			long1 DECIMAL(9,6);
			long2 DECIMAL(9,6);
		BEGIN
			lat1 = deg_to_rad(33.6856);
			long1 = deg_to_rad(-117.8481);
			lat2 = deg_to_rad(latitude);
			long2 = deg_to_rad(longitude);
			RETURN (2 * 6371 * ASIN(SQRT(
				POWER(SIN((lat2 - lat1) / 2), 2)
				+ (COS(lat1) * COS(lat2) * POWER(SIN((long2 - long1) / 2), 2))
			)));
		END;
	$$
	LANGUAGE PLPGSQL;

/****************************************************************************************************
Step 5: Identify potential locations
****************************************************************************************************/

CREATE TEMP TABLE IF NOT EXISTS potential_locations AS(
	WITH primary_locations AS (
		SELECT
			zip_code
			,county_fips
			,county_name
			,density
			,ROUND(calculate_distance(latitude, longitude),1) AS distance
			FROM uszips
			WHERE (
				calculate_distance(latitude, longitude) < 45 -- commute time approx. within an hour
				AND density <> 0.0 -- uninhabited
			)
			ORDER BY distance
	)
		SELECT
			loc.zip_code
			,loc.county_name AS county
			,loc.density
			,loc.distance
			,fmr.bhk1_rent
			FROM primary_locations	AS loc
			LEFT JOIN fy24_fmrs		AS fmr
				ON loc.county_fips::INT = fmr.county_fips::INT
);

/****************************************************************************************************
Step 6: Final location analysis
****************************************************************************************************/

/*
	assuming rent is halved as amount is split between two roommates
	assuming monthly cost for food ($400), transport ($100), and misc ($200)
	assuming monthly salary ($1600) = $20/hour * 20 hours/week * 4 weeks/month
	assuming rent varies by up to 10% across zip codes from same county:
	> random returns values between 0 and 1
	> so, use equation: y = (2x - 1) / 10, to standardize it between -0.1 and 0.1
*/

CREATE OR REPLACE FUNCTION cost_randomness(monthly_cost INT)
	RETURNS INT AS $$
		DECLARE
			standardizer DECIMAL(9,8); 
		BEGIN
			standardizer = (2 * RANDOM() - 1) / 10;
			RETURN CAST(monthly_cost * (1 + standardizer) AS INT);
		END
	$$
	LANGUAGE PLPGSQL;

CREATE TEMP TABLE IF NOT EXISTS final_data AS (
	SELECT
		zip_code
		,county
		,density
		,distance
		,(20 * 20 * 4) AS salary
		,(cost_randomness(bhk1_rent) / 2) AS rent
		,cost_randomness(400) AS food
		,cost_randomness(100) AS transport
		,cost_randomness(200) AS misc
		FROM potential_locations
		ORDER BY distance
);

-- compute final balance based on given expenses
CREATE OR REPLACE VIEW final_locations AS
	SELECT
		zip_code
		,county
		,distance
		,density
		,(salary - (rent + food + transport + misc)) AS balance
		FROM final_data;

/****************************************************************************************************
Step 7: Analyze results
****************************************************************************************************/

SELECT
	*
	FROM final_locations
	WHERE balance >= 0
	ORDER BY
		balance DESC
		,distance
		,density;
-- locations, with zip code, "92883" and "92881" were ideal for apartment
-- these were affordable, nearby, and rather ligthly populated
